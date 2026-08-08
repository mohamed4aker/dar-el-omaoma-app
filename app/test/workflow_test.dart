import 'package:dar_el_omouma/data/app_state.dart';
import 'package:dar_el_omouma/data/seed_data.dart';
import 'package:dar_el_omouma/domain/models/enums.dart';
import 'package:dar_el_omouma/domain/models/operations.dart';
import 'package:dar_el_omouma/domain/scheduling/booking_conflicts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState();
    state.signInAsPatient();
  });

  BookingDraft draftFor(String procedureId, DateTime start) {
    final procedure = Seed.procedureById(procedureId);
    return BookingDraft(
      theatreId: 'or-2',
      surgeonId: 'doc-ortho-1',
      patientId: Seed.demoPatient.id,
      procedure: procedure,
      classification: Seed.classificationById(procedure.classificationId),
      start: start,
    );
  }

  group('patient surgery request → approval (PROMPT.md 6.13.6)', () {
    test('submitting alerts every approver on push, WhatsApp and SMS', () {
      state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );

      final alerts = state.notifications
          .where((n) => n.audience == NotifyAudience.approvers)
          .toList();
      expect(
        alerts.map((n) => n.channel).toSet(),
        {NotifyChannel.push, NotifyChannel.whatsapp, NotifyChannel.sms},
      );
    });

    test('a request is never a confirmed booking', () {
      final before = state.cases.length;
      state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      expect(state.cases.length, before,
          reason: 'no theatre case may be created by a patient request');
      expect(state.pendingApprovals, hasLength(1));
    });

    test('the estimate the patient saw is stored verbatim', () {
      final request = state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-hip'),
        estimateSnapshot: '120,000 جنيه',
      );
      expect(request.estimatePriceSnapshot, '120,000 جنيه');
    });

    test('approving notifies the patient and clears the queue', () {
      final request = state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      state.decideSurgeryRequest(
        request.id,
        decision: SurgeryRequestStatus.approved,
        reason: 'تمت الموافقة',
      );

      expect(state.pendingApprovals, isEmpty);
      expect(
        state.notifications.any((n) =>
            n.audience == NotifyAudience.patient &&
            n.templateCode == 'surgery_request_decided'),
        isTrue,
      );
    });

    test('a rejection always carries a reason back to the patient', () {
      final request = state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      state.decideSurgeryRequest(
        request.id,
        decision: SurgeryRequestStatus.rejected,
        reason: 'مطلوب استكمال فحوصات',
      );

      final decided = state.surgeryRequests.single;
      expect(decided.status, SurgeryRequestStatus.rejected);
      expect(decided.decisionReason, isNotEmpty);
    });
  });

  group('approval SLA escalation', () {
    test('a fresh request is not overdue', () {
      state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      expect(state.escalateOverdueRequests(), 0);
    });

    test('an unactioned request escalates once the window passes', () {
      state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      final later = DateTime.now().add(const Duration(hours: 5));

      expect(state.escalateOverdueRequests(now: later), 1);
      expect(
        state.notifications
            .any((n) => n.templateCode == 'surgery_request_escalated'),
        isTrue,
      );
    });

    test('escalation is not repeated on the same request', () {
      state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      final later = DateTime.now().add(const Duration(hours: 5));
      state.escalateOverdueRequests(now: later);
      expect(state.escalateOverdueRequests(now: later), 0);
    });

    test('a decided request never escalates', () {
      final request = state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      state.decideSurgeryRequest(
        request.id,
        decision: SurgeryRequestStatus.approved,
      );
      final later = DateTime.now().add(const Duration(days: 3));
      expect(state.escalateOverdueRequests(now: later), 0);
    });
  });

  group('no protected health information leaves the app (PROMPT.md 12.4)', () {
    test('WhatsApp and SMS bodies never contain a patient name', () {
      state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      state.requestHomeCare(
        serviceId: 'hc-nursing',
        patientId: Seed.demoPatient.id,
        address: 'المعادي',
        preferredFrom: DateTime.now().add(const Duration(days: 1)),
        preferredTo: DateTime.now().add(const Duration(days: 1, hours: 2)),
      );
      state.requestBlood(
        bloodGroup: 'O+',
        component: 'دم كامل',
        units: 2,
        requiredBy: DateTime.now().add(const Duration(days: 2)),
      );

      final nameParts = Seed.demoPatient.fullName.split(' ');
      final external =
          state.notifications.where((n) => n.isExternalChannel).toList();

      expect(external, isNotEmpty, reason: 'the test must have something to check');
      for (final notification in external) {
        final text = '${notification.title} ${notification.body}';
        for (final part in nameParts) {
          expect(text.contains(part), isFalse,
              reason: 'leaked "$part" on ${notification.channel.name}');
        }
        expect(text.contains(Seed.demoPatient.mrn), isFalse);
        expect(notification.carriesPhi, isFalse);
      }
    });

    test('every external message names an approved template', () {
      state.submitSurgeryRequest(
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById('proc-carpal'),
        estimateSnapshot: '9,000 جنيه',
      );
      for (final n in state.notifications.where((n) => n.isExternalChannel)) {
        expect(n.templateCode, isNotEmpty);
      }
    });
  });

  group('doctor direct booking (PROMPT.md 6.13.5)', () {
    test('a clear slot books immediately, with no approval step', () {
      final start = Seed.at(3, 9);
      final outcome = state.bookTheatreCase(
        draft: draftFor('proc-carpal', start),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      expect(outcome, isA<BookingAccepted>());
      expect(state.pendingApprovals, isEmpty);
    });

    test('a conflicting slot is refused without an override', () {
      final start = Seed.at(4, 9);
      state.bookTheatreCase(
        draft: draftFor('proc-carpal', start),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      final second = state.bookTheatreCase(
        draft: draftFor('proc-carpal', start),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      expect(second, isA<BookingRejected>());
      expect(
        (second as BookingRejected).check.hasConflict(ConflictType.theatreBusy),
        isTrue,
      );
    });

    test('an override writes the booking and alerts the medical director', () {
      final start = Seed.at(5, 9);
      state.bookTheatreCase(
        draft: draftFor('proc-carpal', start),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      final forced = state.bookTheatreCase(
        draft: draftFor('proc-carpal', start),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
        overrideReason: 'حالة عاجلة بقرار المدير الطبي',
      );
      expect(forced, isA<BookingAccepted>());
      expect(
        state.notifications
            .any((n) => n.templateCode == 'booking_conflict_overridden'),
        isTrue,
      );
    });
  });

  group('visiting-expert programme (PROMPT.md 6.15)', () {
    test('an unlicensed expert is never published to patients', () {
      final published = state.publishableCampaigns().map((c) => c.id).toSet();
      expect(published, contains('camp-1'));
      expect(published, isNot(contains('camp-2')),
          reason: 'camp-2 has no licence reference');
    });

    test('doctor-added and self-registered patients share one pipeline', () {
      state.addToCampaign(
        campaignId: 'camp-1',
        patient: Seed.demoPatient,
        addedByDoctor: false,
      );
      state.addToCampaign(
        campaignId: 'camp-1',
        patient: Seed.theatrePatients[1],
        addedByDoctor: true,
      );

      final pipeline = state.campaignPipeline('camp-1');
      expect(pipeline, hasLength(2));
      expect(pipeline.where((p) => p.addedByDoctor), hasLength(1));
    });

    test('interest alone does not count towards the cohort', () {
      final campaign = Seed.campaigns.firstWhere((c) => c.id == 'camp-1');
      final before = state.confirmedCohort(campaign);

      final entry = state.addToCampaign(
        campaignId: 'camp-1',
        patient: Seed.demoPatient,
        addedByDoctor: false,
      );
      expect(state.confirmedCohort(campaign), before);

      state.advanceCampaignPatient(entry.id, VisitingStage.shortlisted);
      expect(state.confirmedCohort(campaign), before + 1);
    });

    test('a cohort below the threshold warns the coordinator', () {
      state.addToCampaign(
        campaignId: 'camp-1',
        patient: Seed.demoPatient,
        addedByDoctor: false,
      );
      expect(
        state.notifications
            .any((n) => n.templateCode == 'campaign_cohort_at_risk'),
        isTrue,
      );
    });
  });

  group('home care (PROMPT.md 6.4)', () {
    test('a request is tracked and free to cancel before dispatch', () {
      final request = state.requestHomeCare(
        serviceId: 'hc-nursing',
        patientId: Seed.demoPatient.id,
        address: 'المعادي، القاهرة',
        preferredFrom: DateTime.now().add(const Duration(days: 1)),
        preferredTo: DateTime.now().add(const Duration(days: 1, hours: 2)),
      );
      expect(request.status, HomeCareStatus.submitted);
      expect(request.isCancellableFreeOfCharge, isTrue);

      state.advanceHomeCare(request.id, HomeCareStatus.enRoute);
      expect(
        state.homeCareRequests.single.isCancellableFreeOfCharge,
        isFalse,
        reason: 'free cancellation ends once the team is dispatched',
      );
    });
  });

  group('blood bank donor eligibility', () {
    test('a donor with no recorded donation is eligible', () {
      const donor = DonorProfile(
        bloodGroup: 'O+',
        lastDonation: null,
        acceptsAppeals: true,
      );
      expect(donor.isEligibleAt(DateTime.now()), isTrue);
      expect(donor.nextEligibleDate, isNull);
    });

    test('a recent donor is not eligible until the interval elapses', () {
      final donor = DonorProfile(
        bloodGroup: 'O+',
        lastDonation: DateTime.now().subtract(const Duration(days: 30)),
        acceptsAppeals: false,
      );
      expect(donor.isEligibleAt(DateTime.now()), isFalse);
      expect(
        donor.isEligibleAt(DateTime.now().add(const Duration(days: 61))),
        isTrue,
      );
    });
  });
}

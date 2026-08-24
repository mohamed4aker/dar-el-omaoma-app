import 'package:dar_el_omouma/data/app_state.dart';
import 'package:dar_el_omouma/data/seed_data.dart';
import 'package:dar_el_omouma/domain/models/catalog.dart';
import 'package:dar_el_omouma/domain/models/enums.dart';
import 'package:dar_el_omouma/domain/models/governance.dart';
import 'package:dar_el_omouma/domain/models/operations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Doctor-initiated requests, central scheduling, doctor capacity, schedule
/// changes and payment options.
void main() {
  late AppState state;
  late int doctorCount;
  late int clinicCount;

  setUp(() {
    state = AppState();
    state.signInAsAdmin();
    doctorCount = Seed.doctors.length;
    clinicCount = Seed.clinics.length;
  });

  tearDown(() {
    Seed.doctors.removeRange(doctorCount, Seed.doctors.length);
    Seed.clinics.removeRange(clinicCount, Seed.clinics.length);
  });

  group('doctor requests a theatre, admin allocates it', () {
    test('a doctor request is not a booking', () {
      final before = state.cases.length;
      state.submitDoctorSurgeryRequest(
        doctorId: 'doc-ortho-1',
        patient: Seed.demoPatient,
        procedure: Seed.procedureById('proc-acl'),
      );
      expect(state.cases.length, before);
      expect(state.pendingApprovals, hasLength(1));
      expect(state.pendingApprovals.single.isFromDoctor, isTrue);
    });

    test('the request alerts the schedulers on every channel', () {
      state.submitDoctorSurgeryRequest(
        doctorId: 'doc-ortho-1',
        patient: Seed.demoPatient,
        procedure: Seed.procedureById('proc-acl'),
        clinicalNote: 'حالة شبه عاجلة',
      );
      final alerts = state.notifications
          .where((n) => n.templateCode == 'doctor_theatre_request');
      expect(alerts.map((n) => n.channel).toSet(), {
        NotifyChannel.push,
        NotifyChannel.whatsapp,
        NotifyChannel.sms,
      });
    });

    test('scheduling creates the case and notifies the requesting surgeon',
        () {
      final request = state.submitDoctorSurgeryRequest(
        doctorId: 'doc-ortho-1',
        patient: Seed.demoPatient,
        procedure: Seed.procedureById('proc-carpal'),
      );

      final outcome = state.scheduleRequest(
        requestId: request.id,
        theatreId: 'or-2',
        surgeonId: 'doc-ortho-1',
        start: Seed.at(4, 9),
        price: 11000,
      );

      expect(outcome, isA<BookingAccepted>());

      final scheduled = state.surgeryRequests.single;
      expect(scheduled.status, SurgeryRequestStatus.scheduled);
      expect(scheduled.scheduledTheatreId, 'or-2');
      expect(scheduled.confirmedPrice, 11000);
      expect(scheduled.scheduledCaseId, isNotNull);

      final toSurgeon = state.notifications.where(
          (n) => n.audience == NotifyAudience.surgeon &&
              n.templateCode == 'theatre_request_scheduled');
      expect(toSurgeon, hasLength(1));
      // The surgeon asked, so the confirmation must carry what they got.
      expect(toSurgeon.single.body, contains('OR-2'));
      expect(toSurgeon.single.body, contains('11000'));
    });

    test('the patient is told the date too', () {
      final request = state.submitDoctorSurgeryRequest(
        doctorId: 'doc-ortho-1',
        patient: Seed.demoPatient,
        procedure: Seed.procedureById('proc-carpal'),
      );
      state.scheduleRequest(
        requestId: request.id,
        theatreId: 'or-2',
        surgeonId: 'doc-ortho-1',
        start: Seed.at(5, 9),
        price: 11000,
      );
      expect(
        state.notifications.any((n) =>
            n.audience == NotifyAudience.patient &&
            n.templateCode == 'surgery_scheduled'),
        isTrue,
      );
    });

    test('scheduling into an occupied theatre is refused', () {
      final request = state.submitDoctorSurgeryRequest(
        doctorId: 'doc-neuro-1',
        patient: Seed.theatrePatients[2],
        procedure: Seed.procedureById('proc-disc'),
      );
      // case-1 already holds or-1 from 09:00 today.
      final outcome = state.scheduleRequest(
        requestId: request.id,
        theatreId: 'or-1',
        surgeonId: 'doc-neuro-1',
        start: Seed.at(0, 9, 30),
        price: 90000,
      );
      expect(outcome, isA<BookingRejected>());
      expect(state.surgeryRequests.single.status,
          isNot(SurgeryRequestStatus.scheduled));
    });
  });

  group('hospital policy decides how doctors book', () {
    test('direct booking is on by default', () {
      expect(state.policy.doctorsBookTheatreDirectly, isTrue);
    });

    test('switching the policy is recorded in the audit log', () {
      state.updatePolicy(
          state.policy.copyWith(doctorsBookTheatreDirectly: false));
      expect(state.policy.doctorsBookTheatreDirectly, isFalse);
      expect(
        state.auditLog.any((e) => e.entity == 'policy'),
        isTrue,
      );
    });
  });

  group('doctor shifts and capacity', () {
    Doctor buildDoctor({required int maxPatients, int weekday = 7}) {
      final id = state.upsertDoctor(
        name: const Label('د. تجربة', 'Dr Test'),
        title: const Label('استشاري', 'Consultant'),
        specialty: const Label('باطنة', 'Internal'),
        seniority: 3,
        shifts: [
          DoctorShift(
            weekday: weekday,
            startsAt: 10 * 60,
            endsAt: 14 * 60,
            maxPatients: maxPatients,
          ),
        ],
      );
      return Seed.doctorById(id);
    }

    DateTime nextWeekday(int weekday) {
      var day = DateTime.now().add(const Duration(days: 1));
      while (day.weekday != weekday) {
        day = day.add(const Duration(days: 1));
      }
      return DateTime(day.year, day.month, day.day);
    }

    test('the cap divides the window into that many slots', () {
      final doctor = buildDoctor(maxPatients: 8);
      final clinicId = state.upsertClinic(
        name: const Label('عيادة تجربة', 'Test clinic'),
        consultationFee: 300,
        followUpFee: 150,
        doctorIds: [doctor.id],
        workingDays: const [DateTime.sunday],
      );
      final clinic = Seed.clinics.firstWhere((c) => c.id == clinicId);
      final day = nextWeekday(DateTime.sunday);

      // Four hours split eight ways is a 30-minute slot.
      expect(doctor.shiftOn(DateTime.sunday)!.slotMinutes(20), 30);
      expect(state.clinicSlots(clinic, day), hasLength(8));
    });

    test('an uncapped shift falls back to the clinic slot length', () {
      final doctor = buildDoctor(maxPatients: 0);
      final clinicId = state.upsertClinic(
        name: const Label('عيادة', 'Clinic'),
        consultationFee: 300,
        followUpFee: 150,
        doctorIds: [doctor.id],
        workingDays: const [DateTime.sunday],
      );
      final clinic = Seed.clinics.firstWhere((c) => c.id == clinicId);
      final day = nextWeekday(DateTime.sunday);
      // Four hours at the 20-minute default.
      expect(state.clinicSlots(clinic, day), hasLength(12));
      expect(state.remainingCapacity(doctor, day), isNull);
    });

    test('a doctor is offered no slots on a day they do not work', () {
      final doctor = buildDoctor(maxPatients: 6, weekday: DateTime.sunday);
      final clinicId = state.upsertClinic(
        name: const Label('عيادة', 'Clinic'),
        consultationFee: 300,
        followUpFee: 150,
        doctorIds: [doctor.id],
        workingDays: const [DateTime.sunday, DateTime.monday],
      );
      final clinic = Seed.clinics.firstWhere((c) => c.id == clinicId);
      expect(doctor.worksOn(DateTime.monday), isFalse);
      expect(state.clinicSlots(clinic, nextWeekday(DateTime.monday)), isEmpty);
    });

    test('capacity falls as patients book, and closes at the cap', () {
      final doctor = buildDoctor(maxPatients: 2);
      final clinicId = state.upsertClinic(
        name: const Label('عيادة', 'Clinic'),
        consultationFee: 300,
        followUpFee: 150,
        doctorIds: [doctor.id],
        workingDays: const [DateTime.sunday],
      );
      final clinic = Seed.clinics.firstWhere((c) => c.id == clinicId);
      final day = nextWeekday(DateTime.sunday);

      expect(state.remainingCapacity(doctor, day), 2);

      for (var i = 0; i < 2; i++) {
        final slots = state.clinicSlots(clinic, day);
        expect(slots, isNotEmpty);
        state.bookClinicAppointment(
          patientId: 'pat-${i + 1}',
          clinicId: clinic.id,
          doctorId: doctor.id,
          start: slots.first,
        );
      }

      expect(state.remainingCapacity(doctor, day), 0);
      expect(state.clinicSlots(clinic, day), isEmpty,
          reason: 'the cap is reached, so nothing more is offered');
    });

    test('weekly capacity sums the caps, and is 0 when any shift is uncapped',
        () {
      const capped = Doctor(
        id: 'x',
        name: Label('د'),
        title: Label('ت'),
        specialty: Label('ت'),
        seniority: 3,
        shifts: [
          DoctorShift(weekday: 6, startsAt: 600, endsAt: 840, maxPatients: 10),
          DoctorShift(weekday: 7, startsAt: 600, endsAt: 840, maxPatients: 8),
        ],
      );
      expect(capped.weeklyCapacity, 18);

      const mixed = Doctor(
        id: 'y',
        name: Label('د'),
        title: Label('ت'),
        specialty: Label('ت'),
        seniority: 3,
        shifts: [
          DoctorShift(weekday: 6, startsAt: 600, endsAt: 840, maxPatients: 10),
          DoctorShift(weekday: 7, startsAt: 600, endsAt: 840),
        ],
      );
      expect(mixed.weeklyCapacity, 0);
    });
  });

  group('schedule changes reach the patient (not the reception desk)', () {
    test('closing a clinic day identifies the bookings it breaks', () {
      final doctorId = state.upsertDoctor(
        name: const Label('د. تجربة', 'Dr Test'),
        title: const Label('استشاري', 'Consultant'),
        specialty: const Label('باطنة', 'Internal'),
        seniority: 3,
        shifts: const [
          DoctorShift(
              weekday: DateTime.sunday,
              startsAt: 600,
              endsAt: 840,
              maxPatients: 6),
        ],
      );
      final clinicId = state.upsertClinic(
        name: const Label('عيادة', 'Clinic'),
        consultationFee: 300,
        followUpFee: 150,
        doctorIds: [doctorId],
        workingDays: const [DateTime.sunday],
      );
      final clinic = Seed.clinics.firstWhere((c) => c.id == clinicId);

      var day = DateTime.now().add(const Duration(days: 1));
      while (day.weekday != DateTime.sunday) {
        day = day.add(const Duration(days: 1));
      }
      final slot = state.clinicSlots(clinic, day).first;
      state.bookClinicAppointment(
        patientId: Seed.demoPatient.id,
        clinicId: clinicId,
        doctorId: doctorId,
        start: slot,
      );

      final broken = state.appointmentsBrokenBy(
        clinicId: clinicId,
        newWorkingDays: const [DateTime.monday],
      );
      expect(broken, hasLength(1));

      final cancelled = state.cancelBrokenAppointments(broken);
      expect(cancelled, 1);
      expect(
        state.appointments
            .firstWhere((a) => a.id == broken.first.id)
            .cancelReason,
        CancellationReason.scheduleChanged,
      );
      // The patient is told, rather than finding out on arrival.
      expect(
        state.notifications.any((n) =>
            n.audience == NotifyAudience.patient &&
            n.templateCode == 'appointment_cancelled'),
        isTrue,
      );
    });

    test('an unaffected booking is left alone', () {
      final broken = state.appointmentsBrokenBy(
        clinicId: 'clinic-obgyn',
        newWorkingDays: const [6, 7, 1, 2, 3, 4],
      );
      expect(broken, isEmpty);
    });
  });

  group('payment is an option, never a gate', () {
    test('the default policy takes no money in the app', () {
      const clinic = Clinic(
        id: 'c',
        name: Label('عيادة'),
        consultationFee: 500,
        followUpFee: 250,
        doctorIds: ['d'],
        workingDays: [7],
      );
      expect(clinic.paymentPolicy, PaymentPolicy.payAtReception);
      expect(clinic.paymentPolicy.allowsOnlinePayment, isFalse);
      expect(clinic.paymentPolicy.requiresDeposit, isFalse);
    });

    test('a booking with no payment still succeeds and records the balance',
        () {
      final appointment = state.bookClinicAppointment(
        patientId: Seed.demoPatient.id,
        clinicId: 'clinic-obgyn',
        doctorId: 'doc-obgyn-1',
        start: Seed.at(6, 11),
      );
      expect(appointment.depositPaid, 0);
      expect(appointment.fee, 500);
      expect(appointment.balanceDue, 500);
      expect(appointment.reference, isNotEmpty);
    });

    test('a deposit reduces the balance but is not required to book', () {
      final appointment = state.bookClinicAppointment(
        patientId: Seed.demoPatient.id,
        clinicId: 'clinic-obgyn',
        doctorId: 'doc-obgyn-1',
        start: Seed.at(7, 11),
        depositPaid: 200,
      );
      expect(appointment.depositPaid, 200);
      expect(appointment.balanceDue, 300);
    });

    test('deposit policy is configurable per clinic', () {
      final id = state.upsertClinic(
        name: const Label('عيادة محدودة', 'Limited clinic'),
        consultationFee: 800,
        followUpFee: 400,
        doctorIds: const ['doc-ortho-1'],
        workingDays: const [7],
        paymentPolicy: PaymentPolicy.depositRequired,
        depositAmount: 250,
      );
      final clinic = Seed.clinics.firstWhere((c) => c.id == id);
      expect(clinic.paymentPolicy.requiresDeposit, isTrue);
      expect(clinic.depositAmount, 250);
    });
  });

  group('users, roles and the audit log', () {
    test('a user may hold several roles and gets the union of permissions',
        () {
      const user = StaffUser(
        id: 'u',
        name: 'د. أحمد',
        phone: '+20100',
        roles: {UserRole.doctor, UserRole.surgeryApprover},
      );
      expect(user.can((r) => r.canBookTheatreDirectly), isTrue);
      expect(user.can((r) => r.canApproveSurgery), isTrue);
      expect(user.can((r) => r.canManageUsers), isFalse);
    });

    test('a disabled account holds no permissions at all', () {
      const user = StaffUser(
        id: 'u',
        name: 'أ. سلمى',
        phone: '+20100',
        roles: {UserRole.admin},
        isActive: false,
      );
      expect(user.can((r) => r.canManageCatalogue), isFalse);
    });

    test('thin approval coverage is detected when a holder is disabled', () {
      // The seed ships with two holders — the administrator and a consultant
      // who also approves — which is the minimum the rule requires.
      expect(state.holdersOf((r) => r.canApproveSurgery), 2);
      expect(state.approvalCoverageIsThin, isFalse);

      // Take one of them off duty and the hospital is one absence away from
      // stalling every patient request.
      state.setStaffActive('usr-2', false);
      expect(state.approvalCoverageIsThin, isTrue);

      state.upsertStaff(
        name: 'د. منى فاروق',
        phone: '+201009998887',
        roles: {UserRole.surgeryApprover},
      );
      expect(state.approvalCoverageIsThin, isFalse);
    });

    test('catalogue edits are written to the audit log', () {
      state.upsertProcedure(
        code: 'AUD-1',
        name: const Label('عملية للتدقيق', 'Audited procedure'),
        classificationId: 'cls-minor',
        typicalDuration: const Duration(minutes: 30),
        requiredTheatreType: TheatreType.minorProcedures,
        price: 5000,
      );
      final entry = state.auditLog.first;
      expect(entry.entity, 'procedure');
      expect(entry.action, 'created');
      expect(entry.actor, 'الأدمن');
      expect(entry.detail, contains('عملية للتدقيق'));

      Seed.procedures.removeLast();
    });

    test('the audit log is newest first', () {
      state.updatePolicy(
          state.policy.copyWith(doctorsBookTheatreDirectly: false));
      state.updatePolicy(
          state.policy.copyWith(doctorsBookTheatreDirectly: true));
      expect(state.auditLog.length, greaterThanOrEqualTo(2));
      expect(
        state.auditLog.first.at.isBefore(state.auditLog.last.at),
        isFalse,
      );
    });
  });
}

import 'package:dar_el_omouma/data/app_state.dart';
import 'package:dar_el_omouma/data/seed_data.dart';
import 'package:dar_el_omouma/domain/models/catalog.dart';
import 'package:dar_el_omouma/domain/models/enums.dart';
import 'package:dar_el_omouma/domain/models/time_range.dart';
import 'package:dar_el_omouma/domain/scheduling/booking_conflicts.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

/// Admin catalogue maintenance (PROMPT.md §14).
///
/// The seed lists are process-wide, so each test restores what it changed.
void main() {
  late AppState state;
  late int classificationCount;
  late int procedureCount;
  late int clinicCount;
  late int doctorCount;
  late int theatreCount;
  late int offerCount;
  late int tipCount;

  setUp(() {
    state = AppState();
    classificationCount = Seed.classifications.length;
    procedureCount = Seed.procedures.length;
    clinicCount = Seed.clinics.length;
    doctorCount = Seed.doctors.length;
    theatreCount = Seed.theatres.length;
    offerCount = Seed.offers.length;
    tipCount = Seed.tips.length;
  });

  tearDown(() {
    Seed.classifications.removeRange(
        classificationCount, Seed.classifications.length);
    Seed.procedures.removeRange(procedureCount, Seed.procedures.length);
    Seed.clinics.removeRange(clinicCount, Seed.clinics.length);
    Seed.doctors.removeRange(doctorCount, Seed.doctors.length);
    Seed.theatres.removeRange(theatreCount, Seed.theatres.length);
    Seed.offers.removeRange(offerCount, Seed.offers.length);
    Seed.tips.removeRange(tipCount, Seed.tips.length);
  });

  String addClassification({String name = 'جراحة يوم واحد'}) =>
      state.upsertClassification(
        code: 'daycase',
        name: Label(name, 'Day case'),
        colour: const Color(0xFF7C3AED),
        defaultDuration: const Duration(minutes: 60),
        defaultTurnover: const Duration(minutes: 20),
        priceMin: 8000,
        priceMax: 20000,
        requiredSeniority: 2,
        defaultAnaesthesia: const Label('نصفي', 'Spinal'),
        defaultBloodUnits: 0,
      );

  group('classifications are data, not code (PROMPT.md 6.13.2)', () {
    test('a new classification is immediately available for booking', () {
      final id = addClassification();

      expect(Seed.classifications.map((c) => c.id), contains(id));
      expect(Seed.classificationById(id).name.ar, 'جراحة يوم واحد');

      // Usable in a booking straight away — no release, no code change.
      final procedureId = state.upsertProcedure(
        code: 'DC-1',
        name: const Label('عملية يوم واحد', 'Day procedure'),
        classificationId: id,
        typicalDuration: const Duration(minutes: 45),
        requiredTheatreType: TheatreType.minorProcedures,
        price: 12000,
      );
      final procedure = Seed.procedureById(procedureId);

      final outcome = state.bookTheatreCase(
        draft: BookingDraft(
          theatreId: 'or-4',
          surgeonId: 'doc-uro-1',
          patientId: Seed.demoPatient.id,
          procedure: procedure,
          classification: Seed.classificationById(id),
          start: Seed.at(6, 10),
        ),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      expect(outcome, isA<BookingAccepted>());
      expect(
        (outcome as BookingAccepted).surgeryCase.classificationId,
        id,
      );
    });

    test('editing keeps the same id rather than creating a duplicate', () {
      final id = addClassification();
      final before = Seed.classifications.length;

      state.upsertClassification(
        id: id,
        code: 'daycase',
        name: const Label('يوم واحد', 'Day case'),
        colour: const Color(0xFF0891B2),
        defaultDuration: const Duration(minutes: 75),
        defaultTurnover: const Duration(minutes: 25),
        priceMin: 9000,
        priceMax: 22000,
        requiredSeniority: 3,
        defaultAnaesthesia: const Label('كلي', 'General'),
        defaultBloodUnits: 1,
      );

      expect(Seed.classifications.length, before);
      final updated = Seed.classificationById(id);
      expect(updated.name.ar, 'يوم واحد');
      expect(updated.defaultDuration, const Duration(minutes: 75));
      expect(updated.requiredSeniority, 3);
    });

    test('deactivating hides it from new work but keeps history resolvable',
        () {
      final id = addClassification();
      state.setClassificationActive(id, false);

      expect(Seed.classificationById(id).isActive, isFalse);
      expect(
        Seed.classifications.where((c) => c.isActive).map((c) => c.id),
        isNot(contains(id)),
      );
      // Never deleted: a past case referencing it must still resolve.
      expect(() => Seed.classificationById(id), returnsNormally);
    });

    test('a classification in use by a scheduled case is reported as such',
        () {
      expect(state.classificationInUse('cls-major'), isTrue);
      expect(state.classificationInUse(addClassification()), isFalse);
    });

    test("the classification's defaults drive the booking duration", () {
      final id = addClassification();
      final classification = Seed.classificationById(id);
      final procedureId = state.upsertProcedure(
        code: 'DC-2',
        name: const Label('عملية', 'Procedure'),
        classificationId: id,
        typicalDuration: const Duration(minutes: 45),
        requiredTheatreType: TheatreType.general,
        price: 10000,
      );

      final draft = BookingDraft(
        theatreId: 'or-1',
        surgeonId: 'doc-ortho-1',
        patientId: Seed.demoPatient.id,
        procedure: Seed.procedureById(procedureId),
        classification: classification,
        start: Seed.at(7, 10),
      );
      expect(draft.effectiveDuration, const Duration(minutes: 45));
      expect(draft.effectiveTurnover, classification.defaultTurnover);
    });
  });

  group('procedures, clinics and doctors', () {
    test('a new procedure appears in the patient-requestable catalogue', () {
      final id = state.upsertProcedure(
        code: 'GEN-LC',
        name: const Label('استئصال المرارة', 'Cholecystectomy'),
        classificationId: 'cls-major',
        typicalDuration: const Duration(minutes: 90),
        requiredTheatreType: TheatreType.general,
        price: 40000,
      );
      final requestable =
          Seed.procedures.where((p) => p.patientRequestable).map((p) => p.id);
      expect(requestable, contains(id));
    });

    test('a procedure closed to patients stays available to doctors', () {
      final id = state.upsertProcedure(
        code: 'GEN-X',
        name: const Label('عملية داخلية', 'Internal procedure'),
        classificationId: 'cls-major',
        typicalDuration: const Duration(minutes: 60),
        requiredTheatreType: TheatreType.general,
        price: 30000,
        patientRequestable: false,
      );
      expect(
        Seed.procedures.where((p) => p.patientRequestable).map((p) => p.id),
        isNot(contains(id)),
      );
      expect(Seed.procedureById(id).name.ar, 'عملية داخلية');
    });

    test('a doctor added by the admin can be booked as a surgeon', () {
      final doctorId = state.upsertDoctor(
        name: const Label('د. طارق سمير', 'Dr Tarek Samir'),
        title: const Label('استشاري', 'Consultant'),
        specialty: const Label('جراحة عامة', 'General surgery'),
        seniority: 4,
      );
      expect(() => Seed.doctorById(doctorId), returnsNormally);

      final outcome = state.bookTheatreCase(
        draft: BookingDraft(
          theatreId: 'or-2',
          surgeonId: doctorId,
          patientId: Seed.demoPatient.id,
          procedure: Seed.procedureById('proc-carpal'),
          classification: Seed.classificationById('cls-minor'),
          start: Seed.at(8, 10),
        ),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      expect(outcome, isA<BookingAccepted>());
    });

    test('a new clinic offers slots on its configured working days', () {
      final doctorId = state.upsertDoctor(
        name: const Label('د. سلمى', 'Dr Salma'),
        title: const Label('أخصائي', 'Specialist'),
        specialty: const Label('جلدية', 'Dermatology'),
        seniority: 2,
      );
      final clinicId = state.upsertClinic(
        name: const Label('عيادة الجلدية', 'Dermatology clinic'),
        consultationFee: 400,
        followUpFee: 200,
        doctorIds: [doctorId],
        workingDays: const [DateTime.sunday],
        centreId: null,
      );
      final clinic = Seed.clinics.firstWhere((c) => c.id == clinicId);

      // Find the next Sunday that is not today, so generated slots are future.
      var day = DateTime.now().add(const Duration(days: 1));
      while (day.weekday != DateTime.sunday) {
        day = day.add(const Duration(days: 1));
      }

      expect(state.clinicSlots(clinic, day), isNotEmpty);
      expect(
        state.clinicSlots(clinic, day.add(const Duration(days: 1))),
        isEmpty,
        reason: 'Monday is not a working day for this clinic',
      );
    });
  });

  group('theatres', () {
    test('a new theatre is immediately bookable', () {
      final id = state.upsertTheatre(
        code: 'OR-9',
        name: const Label('غرفة 9', 'Theatre 9'),
        type: TheatreType.general,
        opensAt: 8 * 60,
        closesAt: 20 * 60,
      );
      final outcome = state.bookTheatreCase(
        draft: BookingDraft(
          theatreId: id,
          surgeonId: 'doc-ortho-1',
          patientId: Seed.demoPatient.id,
          procedure: Seed.procedureById('proc-acl'),
          classification: Seed.classificationById('cls-major'),
          start: Seed.at(9, 9),
        ),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      expect(outcome, isA<BookingAccepted>());
    });

    test('a theatre taken out of service cannot be booked', () {
      final id = state.upsertTheatre(
        code: 'OR-10',
        name: const Label('غرفة 10', 'Theatre 10'),
        type: TheatreType.general,
        opensAt: 8 * 60,
        closesAt: 20 * 60,
        isActive: false,
      );
      final outcome = state.bookTheatreCase(
        draft: BookingDraft(
          theatreId: id,
          surgeonId: 'doc-ortho-1',
          patientId: Seed.demoPatient.id,
          procedure: Seed.procedureById('proc-acl'),
          classification: Seed.classificationById('cls-major'),
          start: Seed.at(10, 9),
        ),
        patient: Seed.demoPatient,
        origin: BookingOrigin.doctorDirect,
      );
      expect(outcome, isA<BookingRejected>());
      expect(
        (outcome as BookingRejected)
            .check
            .hasConflict(ConflictType.theatreBlocked),
        isTrue,
      );
    });

    test('blocking a theatre surfaces the bookings caught inside the window',
        () {
      // case-1 runs 09:00–11:00 today in or-1.
      final affected = state.blockTheatre(
        theatreId: 'or-1',
        range: TimeRange(Seed.at(0, 8), Seed.at(0, 13)),
        reason: 'صيانة طارئة',
      );
      expect(affected.map((c) => c.id), contains('case-1'));
    });
  });

  group('content', () {
    test('an offer published by the admin reaches the catalogue', () {
      state.upsertOffer(
        title: const Label('باقة الشتاء', 'Winter package'),
        description: const Label('وصف', 'Description'),
        priceBefore: 2000,
        priceAfter: 1400,
        validUntil: DateTime.now().add(const Duration(days: 30)),
      );
      final added = Seed.offers.last;
      expect(added.title.ar, 'باقة الشتاء');
      expect(added.discountPercent, 30);
    });

    test('a medical tip without a named reviewer is refused', () {
      expect(
        () => state.upsertTip(
          category: const Label('عام', 'General'),
          body: const Label('نص', 'Body'),
          reviewerName: '   ',
        ),
        throwsArgumentError,
      );
      expect(Seed.tips.length, tipCount);
    });

    test('a reviewed tip is published with its reviewer and date', () {
      state.upsertTip(
        category: const Label('تغذية', 'Nutrition'),
        body: const Label('اشرب ماء كفاية', 'Drink enough water'),
        reviewerName: '  د. هبة مصطفى  ',
      );
      final added = Seed.tips.last;
      expect(added.reviewerName, 'د. هبة مصطفى');
      expect(added.reviewedAt.isAfter(
          DateTime.now().subtract(const Duration(minutes: 1))), isTrue);
    });
  });

  group('bilingual labels', () {
    test('English falls back to Arabic when not supplied', () {
      const label = Label('أشعة مقطعية');
      expect(label.en, 'أشعة مقطعية');
      expect(label('en'), 'أشعة مقطعية');
    });

    test('English is used when supplied', () {
      const label = Label('أشعة مقطعية', 'CT scan');
      expect(label('en'), 'CT scan');
      expect(label('ar'), 'أشعة مقطعية');
    });
  });
}

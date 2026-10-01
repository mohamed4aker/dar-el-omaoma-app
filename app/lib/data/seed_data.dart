import 'package:flutter/material.dart' show Color;

import '../domain/models/catalog.dart';
import '../domain/models/content.dart';
import 'codec.dart';

/// The hospital's catalogue, as the app currently holds it.
///
/// On first launch these lists are filled from
/// `assets/seed/hospital_data.json` — the hospital's own clinic timetable and
/// laboratory price list, converted by `tools/import_hospital_data.py`. From
/// then on they are whatever the administration has made them, saved on the
/// device by [AppState].
///
/// Nothing in here is invented: there are no sample doctors, patients or
/// bookings. A catalogue the hospital has not supplied (theatres, procedures,
/// specialty centres, radiology) starts empty, and the screens that depend on
/// it stay hidden from patients until the administration adds something.
abstract final class Seed {
  static DateTime get today => _midnight(DateTime.now());

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime at(int dayOffset, int hour, [int minute = 0]) =>
      today.add(Duration(days: dayOffset, hours: hour, minutes: minute));

  // ---------------------------------------------------------------- hospital

  /// The hospital's main line (design deck, slide 8).
  static const emergencyPhone = '01013009936';
  static const whatsappPhone = '01013009936';

  /// The laboratory's booking line, from its printed offers.
  static const labPhone = '01004034910';

  // -------------------------------------------------------- classifications

  /// The four classifications the hospital asked for (صغرى / متوسطة / كبرى /
  /// ذات مهارة). The administration renames, adds and retires them; the app
  /// never switches on these ids.
  static List<OperationClassification> defaultClassifications() => [
        OperationClassification(
          id: 'cls-minor',
          code: 'minor',
          name: const Label('صغرى', 'Minor'),
          sortOrder: 1,
          colour: const Color(0xFF0E9F6E),
          defaultDuration: const Duration(minutes: 45),
          defaultTurnover: const Duration(minutes: 20),
          priceMin: 0,
          priceMax: 0,
          requiredSeniority: 1,
          defaultAnaesthesia: const Label('موضعي', 'Local'),
          defaultBloodUnits: 0,
        ),
        OperationClassification(
          id: 'cls-intermediate',
          code: 'intermediate',
          name: const Label('متوسطة', 'Intermediate'),
          sortOrder: 2,
          colour: const Color(0xFF2563EB),
          defaultDuration: const Duration(minutes: 90),
          defaultTurnover: const Duration(minutes: 30),
          priceMin: 0,
          priceMax: 0,
          requiredSeniority: 2,
          defaultAnaesthesia: const Label('نصفي', 'Spinal'),
          defaultBloodUnits: 1,
        ),
        OperationClassification(
          id: 'cls-major',
          code: 'major',
          name: const Label('كبرى', 'Major'),
          sortOrder: 3,
          colour: const Color(0xFFD97706),
          defaultDuration: const Duration(minutes: 150),
          defaultTurnover: const Duration(minutes: 45),
          priceMin: 0,
          priceMax: 0,
          requiredSeniority: 3,
          defaultAnaesthesia: const Label('كلي', 'General'),
          defaultBloodUnits: 2,
        ),
        OperationClassification(
          id: 'cls-specialised',
          code: 'specialised',
          name: const Label('ذات مهارة', 'Specialised'),
          sortOrder: 4,
          colour: const Color(0xFFD23A73),
          defaultDuration: const Duration(minutes: 240),
          defaultTurnover: const Duration(minutes: 60),
          priceMin: 0,
          priceMax: 0,
          requiredSeniority: 4,
          defaultAnaesthesia: const Label('كلي', 'General'),
          defaultBloodUnits: 4,
        ),
      ];

  static final List<OperationClassification> classifications =
      defaultClassifications();

  static OperationClassification classificationById(String id) =>
      classifications.firstWhere((c) => c.id == id,
          orElse: () => classifications.isNotEmpty
              ? classifications.first
              : defaultClassifications().first);

  // ------------------------------------------------------------- catalogues

  static final List<Doctor> doctors = [];
  static final List<Clinic> clinics = [];
  static final List<OperatingTheatre> theatres = [];
  static final List<Procedure> procedures = [];
  static final List<SpecialtyCentre> centres = [];
  static final List<RadiologyStudy> radiology = [];
  static final List<LabTest> labTests = [];
  static final List<LabPackage> labPackages = [];
  static final List<HomeCareService> homeCareServices = [];
  static final List<MedicalTip> tips = [];
  static final List<Offer> offers = [];
  static final List<VisitingCampaign> campaigns = [];

  /// A doctor removed after a booking was made still has to render on that
  /// booking, so lookups never throw.
  static Doctor doctorById(String id) => doctors.firstWhere(
        (d) => d.id == id,
        orElse: () => Doctor(
          id: id,
          name: const Label('طبيب غير متاح', 'Doctor unavailable'),
          title: const Label(''),
          specialty: const Label(''),
          seniority: 1,
        ),
      );

  static Clinic? clinicById(String id) {
    for (final c in clinics) {
      if (c.id == id) return c;
    }
    return null;
  }

  static OperatingTheatre theatreById(String id) =>
      theatres.firstWhere((t) => t.id == id);

  static Procedure procedureById(String id) =>
      procedures.firstWhere((p) => p.id == id);

  static LabTest? labTestById(String id) {
    for (final t in labTests) {
      if (t.id == id) return t;
    }
    return null;
  }

  static LabPackage? labPackageById(String id) {
    for (final p in labPackages) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Clinics a doctor sits in.
  static List<Clinic> clinicsOf(String doctorId) =>
      clinics.where((c) => c.doctorIds.contains(doctorId)).toList();

  // ---------------------------------------------------------- serialisation

  /// Replaces the whole catalogue from a saved or bundled document.
  static void loadFrom(Map<String, dynamic> doc) {
    void fill<T>(List<T> target, String key,
        T Function(Map<String, dynamic>) read) {
      if (!doc.containsKey(key)) return;
      target
        ..clear()
        ..addAll(Codec.list(doc[key], read));
    }

    fill(doctors, 'doctors', Codec.toDoctor);
    fill(clinics, 'clinics', Codec.toClinic);
    fill(labTests, 'labTests', Codec.toLabTest);
    fill(labPackages, 'labPackages', Codec.toLabPackage);
    fill(theatres, 'theatres', Codec.toTheatre);
    fill(procedures, 'procedures', Codec.toProcedure);
    fill(tips, 'tips', Codec.toTip);
    fill(offers, 'offers', Codec.toOffer);
    if (doc['classifications'] is List &&
        (doc['classifications'] as List).isNotEmpty) {
      fill(classifications, 'classifications', Codec.toClassification);
    }
  }

  static Map<String, dynamic> toJson() => {
        'doctors': doctors.map(Codec.doctor).toList(),
        'clinics': clinics.map(Codec.clinic).toList(),
        'labTests': labTests.map(Codec.labTest).toList(),
        'labPackages': labPackages.map(Codec.labPackage).toList(),
        'theatres': theatres.map(Codec.theatre).toList(),
        'procedures': procedures.map(Codec.procedure).toList(),
        'tips': tips.map(Codec.tip).toList(),
        'offers': offers.map(Codec.offer).toList(),
        'classifications': classifications.map(Codec.classification).toList(),
      };

  /// Empties every catalogue. Used before loading, and by tests.
  static void clear() {
    for (final list in <List<Object>>[
      doctors, clinics, theatres, procedures, centres, radiology, labTests,
      labPackages, homeCareServices, tips, offers, campaigns,
    ]) {
      list.clear();
    }
    classifications
      ..clear()
      ..addAll(defaultClassifications());
  }
}

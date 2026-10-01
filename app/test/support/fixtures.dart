import 'package:dar_el_omouma/data/app_state.dart';
import 'package:dar_el_omouma/data/seed_data.dart';
import 'package:dar_el_omouma/domain/models/booking.dart';
import 'package:dar_el_omouma/domain/models/catalog.dart';
import 'package:dar_el_omouma/domain/models/content.dart';
import 'package:dar_el_omouma/domain/models/enums.dart';
import 'package:dar_el_omouma/domain/models/patient.dart';
import 'package:dar_el_omouma/domain/models/time_range.dart';
import 'package:flutter/material.dart' show Color;

/// A small, known hospital for tests: five doctors, five clinics, four
/// theatres, seven procedures and three registered patients.
///
/// This used to be the app's demo data. The app now ships only the hospital's
/// real catalogue, so the fixture lives here, where predictable ids and
/// shapes are what the tests need.
abstract final class Fixtures {
  static DateTime at(int dayOffset, int hour, [int minute = 0]) =>
      Seed.at(dayOffset, hour, minute);

  static final _allWeek = [
    for (var d = 1; d <= 7; d++)
      DoctorShift(weekday: d, startsAt: 10 * 60, endsAt: 14 * 60),
  ];

  /// Replaces the catalogue and fills [state] with patients, theatre cases,
  /// blocks and two appointments.
  static void install(AppState state) {
    Seed.clear();
    Seed.doctors.addAll(doctors);
    Seed.clinics.addAll(clinics);
    Seed.theatres.addAll(theatres);
    Seed.procedures.addAll(procedures);
    Seed.centres.addAll(centres);
    Seed.campaigns.addAll(campaigns);
    state.debugInstall(
      patients: theatrePatients,
      cases: cases(),
      blocks: theatreBlocks(),
      appointments: appointments(),
    );
  }

  static final List<Doctor> doctors = [
    Doctor(
      id: 'doc-ortho-1',
      name: Label('د. أحمد سليم', 'Dr Ahmed Selim'),
      title: Label('استشاري', 'Consultant'),
      specialty: Label('جراحة العظام', 'Orthopaedic surgery'),
      seniority: 4,
      centreId: 'centre-surgery',
      shifts: _allWeek,
    ),
    Doctor(
      id: 'doc-neuro-1',
      name: Label('د. منى فاروق', 'Dr Mona Farouk'),
      title: Label('استشاري', 'Consultant'),
      specialty: Label('جراحة المخ والأعصاب', 'Neurosurgery'),
      seniority: 4,
      centreId: 'centre-surgery',
      shifts: _allWeek,
    ),
    Doctor(
      id: 'doc-uro-1',
      name: Label('د. كريم عبد الله', 'Dr Kareem Abdallah'),
      title: Label('أخصائي أول', 'Senior specialist'),
      specialty: Label('جراحة المسالك البولية', 'Urology'),
      seniority: 2,
      centreId: 'centre-surgery',
      shifts: _allWeek,
    ),
    Doctor(
      id: 'doc-obgyn-1',
      name: Label('د. هبة مصطفى', 'Dr Heba Mostafa'),
      title: Label('استشاري', 'Consultant'),
      specialty: Label('النساء والتوليد', 'Obstetrics & gynaecology'),
      seniority: 4,
      shifts: _allWeek,
    ),
    Doctor(
      id: 'doc-peds-1',
      name: Label('د. ياسمين حسن', 'Dr Yasmin Hassan'),
      title: Label('أخصائي', 'Specialist'),
      specialty: Label('طب الأطفال', 'Paediatrics'),
      seniority: 2,
      shifts: _allWeek,
    ),
  ];

  static final List<Clinic> clinics = [
    const Clinic(
      slotMinutes: 20,
      id: 'clinic-ortho',
      name: Label('عيادة جراحة العظام', 'Orthopaedic surgery clinic'),
      consultationFee: 500,
      followUpFee: 250,
      doctorIds: ['doc-ortho-1'],
      workingDays: [6, 7, 1, 2, 3],
      centreId: 'centre-surgery',
    ),
    const Clinic(
      id: 'clinic-neuro',
      name: Label('عيادة المخ والأعصاب', 'Neurosurgery clinic'),
      consultationFee: 600,
      followUpFee: 300,
      doctorIds: ['doc-neuro-1'],
      workingDays: [7, 2, 4],
      centreId: 'centre-surgery',
    ),
    const Clinic(
      id: 'clinic-uro',
      name: Label('عيادة المسالك البولية', 'Urology clinic'),
      consultationFee: 450,
      followUpFee: 220,
      doctorIds: ['doc-uro-1'],
      workingDays: [6, 1, 3],
      centreId: 'centre-surgery',
    ),
    const Clinic(
      id: 'clinic-obgyn',
      name: Label('عيادة النساء والتوليد', 'Obstetrics & gynaecology clinic'),
      consultationFee: 500,
      followUpFee: 250,
      doctorIds: ['doc-obgyn-1'],
      workingDays: [1, 2, 3, 4, 5, 6, 7],
      slotMinutes: 20,
    ),
    const Clinic(
      id: 'clinic-peds',
      name: Label('عيادة الأطفال', 'Paediatrics clinic'),
      consultationFee: 400,
      followUpFee: 200,
      doctorIds: ['doc-peds-1'],
      workingDays: [6, 7, 1, 2, 3],
    ),
  ];

  static final List<OperatingTheatre> theatres = [
    const OperatingTheatre(
      id: 'or-1',
      code: 'OR-1',
      name: Label('غرفة عمليات 1', 'Theatre 1'),
      type: TheatreType.general,
      opensAt: 8 * 60,
      closesAt: 20 * 60,
    ),
    const OperatingTheatre(
      id: 'or-2',
      code: 'OR-2',
      name: Label('غرفة عمليات 2', 'Theatre 2'),
      type: TheatreType.general,
      opensAt: 8 * 60,
      closesAt: 18 * 60,
    ),
    const OperatingTheatre(
      id: 'or-3',
      code: 'OR-3',
      name: Label('غرفة الولادة', 'Obstetric theatre'),
      type: TheatreType.obstetric,
      opensAt: 0,
      closesAt: 24 * 60,
    ),
    const OperatingTheatre(
      id: 'or-4',
      code: 'OR-4',
      name: Label('غرفة العمليات الصغرى', 'Minor procedures'),
      type: TheatreType.minorProcedures,
      opensAt: 9 * 60,
      closesAt: 17 * 60,
    ),
  ];

  static final List<Procedure> procedures = [
    const Procedure(
      id: 'proc-acl',
      code: 'ORT-ACL',
      name: Label('إصلاح الرباط الصليبي', 'ACL reconstruction'),
      classificationId: 'cls-major',
      typicalDuration: Duration(minutes: 150),
      requiredTheatreType: TheatreType.general,
      price: 55000,
      centreId: 'centre-surgery',
      requiredEquipment: ['arthroscopy-tower'],
    ),
    const Procedure(
      id: 'proc-hip',
      code: 'ORT-THR',
      name: Label('استبدال مفصل الورك', 'Total hip replacement'),
      classificationId: 'cls-specialised',
      typicalDuration: Duration(minutes: 210),
      requiredTheatreType: TheatreType.general,
      price: 120000,
      centreId: 'centre-surgery',
      requiredEquipment: ['ortho-set-a'],
    ),
    const Procedure(
      id: 'proc-carpal',
      code: 'ORT-CTR',
      name: Label('تسليك العصب الأوسط', 'Carpal tunnel release'),
      classificationId: 'cls-minor',
      typicalDuration: Duration(minutes: 40),
      requiredTheatreType: TheatreType.minorProcedures,
      price: 9000,
      centreId: 'centre-surgery',
    ),
    const Procedure(
      id: 'proc-disc',
      code: 'NEU-DSC',
      name: Label('استئصال غضروف قطني', 'Lumbar discectomy'),
      classificationId: 'cls-specialised',
      typicalDuration: Duration(minutes: 180),
      requiredTheatreType: TheatreType.general,
      price: 95000,
      centreId: 'centre-surgery',
      requiredEquipment: ['neuro-microscope'],
    ),
    const Procedure(
      id: 'proc-tur',
      code: 'URO-TUR',
      name: Label('منظار البروستاتا', 'TURP'),
      classificationId: 'cls-major',
      typicalDuration: Duration(minutes: 120),
      requiredTheatreType: TheatreType.general,
      price: 45000,
      centreId: 'centre-surgery',
      requiredEquipment: ['endoscopy-stack'],
    ),
    const Procedure(
      id: 'proc-stone',
      code: 'URO-URS',
      name: Label('منظار الحالب', 'Ureteroscopy'),
      classificationId: 'cls-intermediate',
      typicalDuration: Duration(minutes: 75),
      requiredTheatreType: TheatreType.general,
      price: 28000,
      centreId: 'centre-surgery',
      requiredEquipment: ['endoscopy-stack'],
    ),
    const Procedure(
      id: 'proc-cs',
      code: 'OBS-CS',
      name: Label('ولادة قيصرية', 'Caesarean section'),
      classificationId: 'cls-major',
      typicalDuration: Duration(minutes: 60),
      requiredTheatreType: TheatreType.obstetric,
      price: 35000,
    ),
  ];

  static final List<SpecialtyCentre> centres = [
    const SpecialtyCentre(
      id: 'centre-surgery',
      slug: 'surgery',
      name: Label('مركز جراحات دار الأمومة', 'Dar El Omouma Surgery Centre'),
      description: Label(
        'مركز متخصص في جراحات المخ والأعصاب والمسالك البولية والعظام، بفريق استشاري وغرف عمليات مجهزة.',
        'A centre specialising in neurosurgery, urology and orthopaedic surgery, with a consultant team and equipped theatres.',
      ),
      specialties: [
        Label('جراحة المخ والأعصاب', 'Neurosurgery'),
        Label('جراحة المسالك البولية', 'Urology'),
        Label('جراحة العظام', 'Orthopaedic surgery'),
      ],
      accent: Color(0xFF0B2E5C),
    ),
  ];

  static final Patient demoPatient = Patient(
    id: 'pat-1',
    mrn: 'DO-104882',
    fullName: 'سارة محمود عبد الرحمن حسين',
    phoneE164: '+201013009936',
    dateOfBirth: DateTime(1995, 4, 12),
    isMale: false,
    email: 'sara@example.com',
    bloodGroup: 'O+',
    allergies: ['بنسلين'],
    chronicConditions: [],
    pregnancy: Pregnancy(
      lastMenstrualPeriod: DateTime.now().subtract(const Duration(days: 168)),
    ),
  );

  static final List<Patient> theatrePatients = [
    demoPatient,
    Patient(
      id: 'pat-2',
      mrn: 'DO-104901',
      fullName: 'محمد إبراهيم سيد علي',
      phoneE164: '+201004455667',
      dateOfBirth: DateTime(1978, 9, 3),
      isMale: true,
      bloodGroup: 'A+',
    ),
    Patient(
      id: 'pat-3',
      mrn: 'DO-104933',
      fullName: 'فاطمة عادل كامل زكي',
      phoneE164: '+201122334455',
      dateOfBirth: DateTime(1962, 1, 25),
      isMale: false,
      bloodGroup: 'B-',
    ),
  ];

  static List<SurgeryCase> cases() => [
        SurgeryCase(
          id: 'case-1',
          patientId: 'pat-2',
          patientDisplayName: 'محمد إ. س.',
          procedureId: 'proc-tur',
          classificationId: 'cls-major',
          theatreId: 'or-1',
          surgeonId: 'doc-uro-1',
          range: TimeRange(at(0, 9), at(0, 11)),
          turnover: const Duration(minutes: 45),
          origin: BookingOrigin.doctorDirect,
          equipment: const ['endoscopy-stack'],
        ),
        SurgeryCase(
          id: 'case-2',
          patientId: 'pat-3',
          patientDisplayName: 'فاطمة ع. ك.',
          procedureId: 'proc-hip',
          classificationId: 'cls-specialised',
          theatreId: 'or-2',
          surgeonId: 'doc-ortho-1',
          range: TimeRange(at(0, 8, 30), at(0, 12)),
          turnover: const Duration(minutes: 60),
          origin: BookingOrigin.doctorDirect,
          equipment: const ['ortho-set-a'],
        ),
        SurgeryCase(
          id: 'case-3',
          patientId: 'pat-2',
          patientDisplayName: 'محمد إ. س.',
          procedureId: 'proc-disc',
          classificationId: 'cls-specialised',
          theatreId: 'or-1',
          surgeonId: 'doc-neuro-1',
          range: TimeRange(at(1, 8), at(1, 11)),
          turnover: const Duration(minutes: 60),
          origin: BookingOrigin.patientRequest,
          equipment: const ['neuro-microscope'],
        ),
      ];

  static List<TheatreBlock> theatreBlocks() => [
        TheatreBlock(
          theatreId: 'or-4',
          range: TimeRange(at(0, 13), at(0, 17)),
          reason: 'صيانة دورية',
        ),
      ];

  static List<Appointment> appointments() => [
        Appointment(
          id: 'appt-1',
          patientId: 'pat-1',
          doctorId: 'doc-obgyn-1',
          clinicId: 'clinic-obgyn',
          range: TimeRange(at(2, 10), at(2, 10, 20)),
        ),
        Appointment(
          id: 'appt-2',
          patientId: 'pat-3',
          doctorId: 'doc-ortho-1',
          clinicId: 'clinic-ortho',
          range: TimeRange(at(0, 14), at(0, 17)),
        ),
      ];

  static final List<VisitingCampaign> campaigns = [
    VisitingCampaign(
      id: 'camp-1',
      expertName: 'Prof. Andreas Richter',
      expertCountry: const Label('ألمانيا', 'Germany'),
      expertInstitution: const Label(
        'مستشفى شاريتيه الجامعي — برلين',
        'Charité University Hospital, Berlin',
      ),
      expertBio: const Label(
        'استشاري جراحة العمود الفقري بخبرة تزيد عن 20 عامًا في جراحات المناظير الدقيقة.',
        'Spinal surgery consultant with over 20 years of experience in minimally invasive techniques.',
      ),
      specialty: const Label('جراحة العمود الفقري', 'Spinal surgery'),
      hostDoctorId: 'doc-neuro-1',
      arrivesAt: DateTime.now().add(const Duration(days: 38)),
      departsAt: DateTime.now().add(const Duration(days: 45)),
      capacity: 12,
      registered: 7,
      minimumViableCohort: 8,
      procedureIds: const ['proc-disc'],
      licenceReference: 'EMS-VP-2026-0417',
      licenceValidUntil: DateTime.now().add(const Duration(days: 120)),
    ),
    VisitingCampaign(
      id: 'camp-2',
      expertName: 'Dr Samir Haddad',
      expertCountry: const Label('الأردن', 'Jordan'),
      expertInstitution: const Label(
        'المركز التخصصي للمسالك البولية',
        'Specialist Urology Centre',
      ),
      expertBio: const Label(
        'استشاري مناظير المسالك البولية وجراحات الحصوات.',
        'Consultant in endourology and stone surgery.',
      ),
      specialty: const Label('المسالك البولية', 'Urology'),
      hostDoctorId: 'doc-uro-1',
      arrivesAt: DateTime.now().add(const Duration(days: 70)),
      departsAt: DateTime.now().add(const Duration(days: 75)),
      capacity: 10,
      registered: 2,
      minimumViableCohort: 6,
      procedureIds: const ['proc-stone', 'proc-tur'],
      // Deliberately unlicensed: exercises the publication gate in
      // VisitingCampaign.isPublishableAt (PROMPT.md 6.15.4).
      licenceReference: null,
      licenceValidUntil: null,
    ),
  ];
}

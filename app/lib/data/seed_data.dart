import 'package:flutter/material.dart' show Color;

import '../domain/models/booking.dart';
import '../domain/models/catalog.dart';
import '../domain/models/content.dart';
import '../domain/models/enums.dart';
import '../domain/models/patient.dart';
import '../domain/models/time_range.dart';

/// Seed content.
///
/// Everything marked "from the deck" is taken verbatim from the client's
/// design deck (`D.O.H_APP.pptx`) — see `docs/SOURCE-COVERAGE.md`. Everything
/// else is representative placeholder data pending the hospital's real
/// catalogues (PROMPT.md section 19, question 2).
///
/// In production every list here is served by the API and authored in the
/// admin console. Nothing in this file may become a hard-coded assumption in
/// the UI layer.
abstract final class Seed {
  static final DateTime today = _midnight(DateTime.now());

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime at(int dayOffset, int hour, [int minute = 0]) =>
      today.add(Duration(days: dayOffset, hours: hour, minutes: minute));

  // ---------------------------------------------------------------- hospital

  /// From the deck, slide 8.
  static const emergencyPhone = '01013009936';
  static const whatsappPhone = '01013009936';

  // -------------------------------------------------------- classifications

  /// The client's four classifications (PROMPT.md 6.13.2). Admin-managed in
  /// production — this list is a seed, not an enumeration.
  static final List<OperationClassification> classifications = [
    OperationClassification(
      id: 'cls-minor',
      code: 'minor',
      name: const Label('صغرى', 'Minor'),
      sortOrder: 1,
      colour: const Color(0xFF0E9F6E),
      defaultDuration: const Duration(minutes: 45),
      defaultTurnover: const Duration(minutes: 20),
      priceMin: 4000,
      priceMax: 12000,
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
      priceMin: 12000,
      priceMax: 30000,
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
      priceMin: 30000,
      priceMax: 80000,
      requiredSeniority: 3,
      defaultAnaesthesia: const Label('كلي', 'General'),
      defaultBloodUnits: 2,
    ),
    OperationClassification(
      id: 'cls-specialised',
      code: 'specialised',
      name: const Label('ذات مهارة', 'Specialised'),
      sortOrder: 4,
      colour: const Color(0xFFE4327E),
      defaultDuration: const Duration(minutes: 240),
      defaultTurnover: const Duration(minutes: 60),
      priceMin: 80000,
      priceMax: 250000,
      requiredSeniority: 4,
      defaultAnaesthesia: const Label('كلي', 'General'),
      defaultBloodUnits: 4,
    ),
  ];

  static OperationClassification classificationById(String id) =>
      classifications.firstWhere((c) => c.id == id);

  // ------------------------------------------------------------------ people

  static final List<Doctor> doctors = [
    const Doctor(
      id: 'doc-ortho-1',
      name: Label('د. أحمد سليم', 'Dr Ahmed Selim'),
      title: Label('استشاري', 'Consultant'),
      specialty: Label('جراحة العظام', 'Orthopaedic surgery'),
      seniority: 4,
      centreId: 'centre-surgery',
    ),
    const Doctor(
      id: 'doc-neuro-1',
      name: Label('د. منى فاروق', 'Dr Mona Farouk'),
      title: Label('استشاري', 'Consultant'),
      specialty: Label('جراحة المخ والأعصاب', 'Neurosurgery'),
      seniority: 4,
      centreId: 'centre-surgery',
    ),
    const Doctor(
      id: 'doc-uro-1',
      name: Label('د. كريم عبد الله', 'Dr Kareem Abdallah'),
      title: Label('أخصائي أول', 'Senior specialist'),
      specialty: Label('جراحة المسالك البولية', 'Urology'),
      seniority: 2,
      centreId: 'centre-surgery',
    ),
    const Doctor(
      id: 'doc-obgyn-1',
      name: Label('د. هبة مصطفى', 'Dr Heba Mostafa'),
      title: Label('استشاري', 'Consultant'),
      specialty: Label('النساء والتوليد', 'Obstetrics & gynaecology'),
      seniority: 4,
    ),
    const Doctor(
      id: 'doc-peds-1',
      name: Label('د. ياسمين حسن', 'Dr Yasmin Hassan'),
      title: Label('أخصائي', 'Specialist'),
      specialty: Label('طب الأطفال', 'Paediatrics'),
      seniority: 2,
    ),
  ];

  static Doctor doctorById(String id) =>
      doctors.firstWhere((d) => d.id == id);

  // ----------------------------------------------------------------- clinics

  /// Orthopaedic Surgery is the worked example named in the deck (slide 5).
  static final List<Clinic> clinics = [
    const Clinic(
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
      workingDays: [6, 7, 1, 2, 3, 4],
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

  // ---------------------------------------------------------------- theatres

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

  static OperatingTheatre theatreById(String id) =>
      theatres.firstWhere((t) => t.id == id);

  // -------------------------------------------------------------- procedures

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

  static Procedure procedureById(String id) =>
      procedures.firstWhere((p) => p.id == id);

  // ----------------------------------------------------------------- centres

  /// The client's "مركز جراحات دار الأمومة" — the first instance of the
  /// generic centre framework, not a special case (PROMPT.md 6.14).
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

  // ----------------------------------------------------------------- patients

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

  // ---------------------------------------------------------- theatre state

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

  // ---------------------------------------------------------------- catalogues

  /// From the deck, slide 6: تليفزيونية / عادية / مقطعية.
  static final List<RadiologyStudy> radiology = [
    const RadiologyStudy(
      id: 'rad-us-abd',
      modality: RadiologyModality.ultrasound,
      name: Label('أشعة تليفزيونية على البطن', 'Abdominal ultrasound'),
      price: 600,
      preparation: Label(
        'الصيام 6 ساعات قبل الفحص.',
        'Fast for 6 hours before the scan.',
      ),
    ),
    const RadiologyStudy(
      id: 'rad-us-obs',
      modality: RadiologyModality.ultrasound,
      name: Label('سونار حمل', 'Obstetric ultrasound'),
      price: 700,
      preparation: Label(
        'شرب كمية وفيرة من الماء وعدم التبول قبل الفحص.',
        'Drink plenty of water and do not empty the bladder before the scan.',
      ),
    ),
    const RadiologyStudy(
      id: 'rad-xr-chest',
      modality: RadiologyModality.xray,
      name: Label('أشعة عادية على الصدر', 'Chest X-ray'),
      price: 350,
      preparation: Label(
        'لا يوجد تحضير خاص. برجاء إبلاغنا في حالة الحمل.',
        'No special preparation. Please tell us if you may be pregnant.',
      ),
    ),
    const RadiologyStudy(
      id: 'rad-ct-brain',
      modality: RadiologyModality.ct,
      name: Label('أشعة مقطعية على المخ', 'CT brain'),
      price: 2500,
      preparation: Label(
        'الصيام 4 ساعات في حالة استخدام الصبغة، وإبلاغنا بأي حساسية.',
        'Fast for 4 hours if contrast is used, and tell us about any allergy.',
      ),
    ),
  ];

  static final List<LabTest> labTests = [
    const LabTest(
      id: 'lab-cbc',
      name: Label('صورة دم كاملة', 'Complete blood count'),
      price: 180,
      sample: Label('دم', 'Blood'),
      turnaround: Label('نفس اليوم', 'Same day'),
    ),
    const LabTest(
      id: 'lab-hba1c',
      name: Label('السكر التراكمي', 'HbA1c'),
      price: 260,
      sample: Label('دم', 'Blood'),
      turnaround: Label('24 ساعة', '24 hours'),
    ),
    const LabTest(
      id: 'lab-tsh',
      name: Label('وظائف الغدة الدرقية', 'Thyroid function'),
      price: 450,
      sample: Label('دم', 'Blood'),
      turnaround: Label('24 ساعة', '24 hours'),
    ),
    const LabTest(
      id: 'lab-vitd',
      name: Label('فيتامين د', 'Vitamin D'),
      price: 520,
      sample: Label('دم', 'Blood'),
      turnaround: Label('48 ساعة', '48 hours'),
    ),
    const LabTest(
      id: 'lab-preg',
      name: Label('تحليل حمل رقمي', 'Quantitative beta hCG'),
      price: 300,
      sample: Label('دم', 'Blood'),
      turnaround: Label('نفس اليوم', 'Same day'),
    ),
  ];

  static final List<HomeCareService> homeCareServices = [
    const HomeCareService(
      id: 'hc-nursing',
      name: Label('زيارة تمريض منزلي', 'Home nursing visit'),
      description: Label(
        'تمريض معتمد لتغيير الغيار وإعطاء الحقن ومتابعة العلامات الحيوية.',
        'Qualified nursing for dressings, injections and vital-sign monitoring.',
      ),
      price: 450,
      duration: Label('حتى ساعتين', 'Up to 2 hours'),
    ),
    const HomeCareService(
      id: 'hc-sample',
      name: Label('سحب عينة من المنزل', 'Home sample collection'),
      description: Label(
        'فريق المعمل يزورك في المنزل لسحب العينات المطلوبة.',
        'A laboratory team visits your home to collect the required samples.',
      ),
      price: 200,
      duration: Label('حتى 30 دقيقة', 'Up to 30 minutes'),
    ),
    const HomeCareService(
      id: 'hc-postnatal',
      name: Label('رعاية الأم والمولود', 'Mother and baby care'),
      description: Label(
        'متابعة ما بعد الولادة للأم والمولود مع إرشادات الرضاعة.',
        'Post-natal follow-up for mother and newborn, with feeding guidance.',
      ),
      price: 700,
      duration: Label('حتى 3 ساعات', 'Up to 3 hours'),
    ),
    const HomeCareService(
      id: 'hc-physio',
      name: Label('علاج طبيعي منزلي', 'Home physiotherapy'),
      description: Label(
        'جلسات تأهيل بعد العمليات والإصابات في المنزل.',
        'Rehabilitation sessions after surgery or injury, at home.',
      ),
      price: 500,
      duration: Label('جلسة 45 دقيقة', '45-minute session'),
    ),
  ];

  // ------------------------------------------------------------------ content

  /// The five tips supplied verbatim in the deck, slide 11.
  static final List<MedicalTip> tips = [
    MedicalTip(
      id: 'tip-1',
      category: const Label('عام', 'General'),
      body: const Label(
        'المضادات الحيوية تعالج العدوى البكتيرية وليس الفيروسية، لذلك لا تعالج الأنفلونزا لأنها عدوى فيروسية.',
        'Antibiotics treat bacterial, not viral, infections — so they do not treat influenza, which is viral.',
      ),
      reviewerName: 'د. هبة مصطفى',
      reviewedAt: DateTime(2026, 7, 1),
    ),
    MedicalTip(
      id: 'tip-2',
      category: const Label('تغذية', 'Nutrition'),
      body: const Label(
        'سمك السلمون يحتوي على كمية عالية من أوميجا 3.',
        'Salmon is a rich source of omega-3.',
      ),
      reviewerName: 'د. هبة مصطفى',
      reviewedAt: DateTime(2026, 7, 1),
    ),
    MedicalTip(
      id: 'tip-3',
      category: const Label('أمومة', 'Maternity'),
      body: const Label(
        'الكالسيوم يلعب دورًا هامًا في نمو العظام وتجلط الدم.',
        'Calcium plays an important role in bone growth and blood clotting.',
      ),
      reviewerName: 'د. هبة مصطفى',
      reviewedAt: DateTime(2026, 7, 1),
    ),
    MedicalTip(
      id: 'tip-4',
      category: const Label('قلب', 'Cardiac'),
      body: const Label(
        'التدخين من الأسباب الرئيسية لأمراض القلب.',
        'Smoking is a leading cause of heart disease.',
      ),
      reviewerName: 'د. هبة مصطفى',
      reviewedAt: DateTime(2026, 7, 1),
    ),
    MedicalTip(
      id: 'tip-5',
      category: const Label('جلدية', 'Dermatology'),
      body: const Label(
        'لا تستخدم الماء الساخن لغسيل الوجه.',
        'Do not wash your face with hot water.',
      ),
      reviewerName: 'د. هبة مصطفى',
      reviewedAt: DateTime(2026, 7, 1),
    ),
  ];

  /// Offers and the three awareness days named in the deck, slide 10.
  static final List<Offer> offers = [
    Offer(
      id: 'off-1',
      title: const Label('باقة متابعة الحمل', 'Antenatal package'),
      description: const Label(
        'أربع زيارات متابعة مع سونار وتحاليل أساسية.',
        'Four follow-up visits with ultrasound and basic laboratory tests.',
      ),
      priceBefore: 4200,
      priceAfter: 2900,
      validUntil: DateTime.now().add(const Duration(days: 45)),
    ),
    Offer(
      id: 'off-2',
      title: const Label('باقة تحاليل شاملة', 'Full check-up panel'),
      description: const Label(
        'صورة دم كاملة وسكر تراكمي ووظائف كبد وكلى وغدة درقية.',
        'CBC, HbA1c, liver and kidney function, and thyroid profile.',
      ),
      priceBefore: 1800,
      priceAfter: 1150,
      validUntil: DateTime.now().add(const Duration(days: 20)),
    ),
    Offer(
      id: 'evt-1',
      title: const Label('اليوم العالمي للسرطان', 'World Cancer Day'),
      description: const Label(
        'كشف مبكر مجاني وندوة توعية بالمستشفى.',
        'Free early-detection screening and an awareness seminar at the hospital.',
      ),
      priceBefore: 0,
      priceAfter: 0,
      validUntil: DateTime(DateTime.now().year + 1, 2, 4),
      isEvent: true,
    ),
    Offer(
      id: 'evt-2',
      title: const Label('اليوم العالمي للمرأة', "International Women's Day"),
      description: const Label(
        'خصم على باقات صحة المرأة طوال الشهر.',
        "Discounts on women's health packages throughout the month.",
      ),
      priceBefore: 0,
      priceAfter: 0,
      validUntil: DateTime(DateTime.now().year + 1, 3, 8),
      isEvent: true,
    ),
    Offer(
      id: 'evt-3',
      title: const Label('اليوم العالمي للطفل', "World Children's Day"),
      description: const Label(
        'كشف أطفال مجاني وحملة تطعيمات.',
        'Free paediatric consultations and a vaccination campaign.',
      ),
      priceBefore: 0,
      priceAfter: 0,
      validUntil: DateTime(DateTime.now().year + 1, 11, 20),
      isEvent: true,
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

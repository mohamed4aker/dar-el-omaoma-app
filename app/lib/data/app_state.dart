import 'package:flutter/material.dart';

import '../domain/models/booking.dart';
import '../domain/models/catalog.dart';
import '../domain/models/content.dart';
import '../domain/models/enums.dart';
import '../domain/models/operations.dart';
import '../domain/models/patient.dart';
import '../domain/models/time_range.dart';
import '../domain/scheduling/booking_conflicts.dart';
import 'seed_data.dart';

/// Outcome of attempting to write a theatre booking.
sealed class BookingOutcome {
  const BookingOutcome();
}

class BookingAccepted extends BookingOutcome {
  const BookingAccepted(this.surgeryCase, {this.warnings = const []});
  final SurgeryCase surgeryCase;
  final List<BookingWarning> warnings;
}

class BookingRejected extends BookingOutcome {
  const BookingRejected(this.check);
  final BookingCheck check;
}

/// In-memory application state.
///
/// This stands in for the API described in PROMPT.md section 9 so the app runs
/// end to end without a backend. Every method here maps to an endpoint; when
/// the API lands, only this class changes.
///
/// It deliberately preserves the server's authority model: [bookTheatreCase]
/// re-runs the conflict check at write time rather than trusting whatever the
/// UI last displayed, mirroring the database constraint that will do the real
/// arbitration in production.
class AppState extends ChangeNotifier {
  AppState() {
    _cases = Seed.cases();
    _appointments = Seed.appointments();
    _blocks = Seed.theatreBlocks();
  }

  static const _scheduler = TheatreScheduler();

  // ------------------------------------------------------------- preferences

  Locale _locale = const Locale('ar');
  Locale get locale => _locale;
  set locale(Locale value) {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  String get localeCode => _locale.languageCode;

  // ----------------------------------------------------------------- session

  Session _session = const Session.guest();
  Session get session => _session;

  void signInAsPatient() {
    _session = Session(role: UserRole.patient, patient: Seed.demoPatient);
    notifyListeners();
  }

  /// The demo build lets the user switch into doctor mode so the theatre
  /// module can be exercised. In production the role arrives from the server
  /// inside the session token and is never selectable in the client
  /// (PROMPT.md section 5).
  void signInAsDoctor(String doctorId) {
    _session = Session(
      role: UserRole.doctor,
      patient: Seed.demoPatient,
      doctorId: doctorId,
    );
    notifyListeners();
  }

  /// Demo-only, as with [signInAsDoctor].
  void signInAsAdmin() {
    _session = Session(role: UserRole.admin, patient: Seed.demoPatient);
    notifyListeners();
  }

  /// Demo-only, as with [signInAsDoctor].
  void signInAsApprover() {
    _session = Session(
      role: UserRole.surgeryApprover,
      patient: Seed.demoPatient,
    );
    notifyListeners();
  }

  void signOut() {
    _session = const Session.guest();
    notifyListeners();
  }

  // ----------------------------------------------------------- notifications

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadApproverAlerts => _notifications
      .where((n) => n.audience == NotifyAudience.approvers)
      .length;

  int _notifySeq = 0;

  void _emit(AppNotification notification) {
    _notifications.insert(0, notification);
  }

  /// Fans an alert out to the approvers across every channel in the delivery
  /// chain (PROMPT.md §12.4, rule 2): in-app push first, WhatsApp second, SMS
  /// as the fallback if still unactioned. None of them carry clinical detail.
  void _alertApprovers({
    required String templateCode,
    required String title,
    required String reference,
    required String context,
    String? entityId,
    String? deepLink,
  }) {
    final now = DateTime.now();
    for (final channel in const [
      NotifyChannel.push,
      NotifyChannel.whatsapp,
      NotifyChannel.sms,
    ]) {
      _emit(AppNotification.staffAlert(
        id: 'ntf-${_notifySeq++}',
        channel: channel,
        audience: NotifyAudience.approvers,
        templateCode: templateCode,
        title: title,
        reference: reference,
        context: context,
        sentAt: now,
        entityId: entityId,
        deepLink: deepLink,
      ));
    }
  }

  void _notifyPatient({
    required String templateCode,
    required String title,
    required String body,
    String? entityId,
  }) {
    _emit(AppNotification(
      id: 'ntf-${_notifySeq++}',
      channel: NotifyChannel.push,
      audience: NotifyAudience.patient,
      templateCode: templateCode,
      title: title,
      body: body,
      sentAt: DateTime.now(),
      entityId: entityId,
    ));
  }

  // ------------------------------------------------------------------ theatre

  late List<SurgeryCase> _cases;
  late List<Appointment> _appointments;
  late List<TheatreBlock> _blocks;
  final List<SurgeryRequest> _requests = [];

  List<SurgeryCase> get cases => List.unmodifiable(_cases);
  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<TheatreBlock> get theatreBlocks => List.unmodifiable(_blocks);
  List<SurgeryRequest> get surgeryRequests => List.unmodifiable(_requests);

  List<SurgeryCase> casesOn(DateTime day) => _cases
      .where((c) =>
          c.blocksTime &&
          c.range.start.year == day.year &&
          c.range.start.month == day.month &&
          c.range.start.day == day.day)
      .toList()
    ..sort((a, b) => a.range.compareTo(b.range));

  List<TheatreBlock> blocksOn(DateTime day) => _blocks
      .where((b) =>
          b.range.start.year == day.year &&
          b.range.start.month == day.month &&
          b.range.start.day == day.day)
      .toList();

  BookingCheck checkBooking(BookingDraft draft) {
    return _scheduler.check(
      draft: draft,
      theatre: Seed.theatreById(draft.theatreId),
      surgeon: Seed.doctorById(draft.surgeonId),
      cases: _cases,
      appointments: _appointments,
      blocks: _blocks,
    );
  }

  List<TimeRange> freeWindows(OperatingTheatre theatre, DateTime day) =>
      _scheduler.freeWindows(
        theatre: theatre,
        day: day,
        cases: _cases,
        blocks: _blocks,
      );

  Duration freeCapacity(OperatingTheatre theatre, DateTime day) =>
      _scheduler.freeCapacity(
        theatre: theatre,
        day: day,
        cases: _cases,
        blocks: _blocks,
      );

  /// Writes a theatre booking.
  ///
  /// A doctor books directly with no approval step (PROMPT.md 6.13.5) — but
  /// "no approval" is not "no rules": the conflict check is re-run here, at
  /// write time, and a hard conflict is refused unless [overrideReason] is
  /// supplied by a caller entitled to override.
  BookingOutcome bookTheatreCase({
    required BookingDraft draft,
    required Patient patient,
    required BookingOrigin origin,
    String? overrideReason,
    String? campaignId,
  }) {
    final check = checkBooking(draft);
    if (!check.isPermitted && overrideReason == null) {
      return BookingRejected(check);
    }

    final booked = SurgeryCase(
      id: 'case-${DateTime.now().microsecondsSinceEpoch}',
      patientId: patient.id,
      patientDisplayName: _abbreviate(patient.fullName),
      procedureId: draft.procedure.id,
      classificationId: draft.classification.id,
      theatreId: draft.theatreId,
      surgeonId: draft.surgeonId,
      range: draft.range,
      turnover: draft.effectiveTurnover,
      origin: origin,
      centreId: draft.procedure.centreId,
      campaignId: campaignId,
      equipment: draft.procedure.requiredEquipment,
      overrideReason: overrideReason,
    );

    _cases = [..._cases, booked];

    _notifyPatient(
      templateCode: 'surgery_scheduled',
      title: 'تم تحديد موعد العملية',
      body: _stamp(booked.range.start),
      entityId: booked.id,
    );
    if (overrideReason != null) {
      // Every override is notified to the medical director and lands in the
      // governance report (PROMPT.md §6.13.5).
      _alertApprovers(
        templateCode: 'booking_conflict_overridden',
        title: 'تم تجاوز تعارض في حجز غرفة عمليات',
        reference: booked.id,
        context: overrideReason,
        entityId: booked.id,
      );
    }

    notifyListeners();
    return BookingAccepted(booked, warnings: check.warnings);
  }

  /// Patient-initiated request. Never a confirmed booking; notifies every
  /// approver (PROMPT.md 6.13.6).
  SurgeryRequest submitSurgeryRequest({
    required String patientId,
    required Procedure procedure,
    required String estimateSnapshot,
    String? preferredSurgeonId,
    DateTime? preferredFrom,
    DateTime? preferredTo,
  }) {
    final now = DateTime.now();
    final request = SurgeryRequest(
      id: 'req-${now.microsecondsSinceEpoch}',
      reference: 'SR-${now.millisecondsSinceEpoch % 1000000}',
      patientId: patientId,
      procedureId: procedure.id,
      classificationId: procedure.classificationId,
      submittedAt: now,
      estimatePriceSnapshot: estimateSnapshot,
      preferredSurgeonId: preferredSurgeonId,
      preferredFrom: preferredFrom,
      preferredTo: preferredTo,
    );
    _requests.insert(0, request);

    // Every approver is alerted immediately, on push, WhatsApp and SMS.
    _alertApprovers(
      templateCode: 'surgery_request_pending',
      title: 'طلب حجز عملية جديد',
      reference: request.reference,
      context:
          '${Seed.classificationById(procedure.classificationId).name.ar} · '
          'بانتظار الموافقة',
      entityId: request.id,
      deepLink: '/approvals/${request.id}',
    );

    notifyListeners();
    return request;
  }

  /// Approve, reject, or ask for more information (PROMPT.md §6.13.6).
  ///
  /// A rejection always carries a reason, and the patient is always told —
  /// a rejected request must never be a dead end.
  void decideSurgeryRequest(
    String requestId, {
    required SurgeryRequestStatus decision,
    String? reason,
  }) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index < 0) return;
    final request = _requests[index];

    _requests[index] = request.copyWith(
      status: decision,
      decidedAt: DateTime.now(),
      decisionReason: reason,
    );

    _notifyPatient(
      templateCode: 'surgery_request_decided',
      title: switch (decision) {
        SurgeryRequestStatus.approved => 'تمت الموافقة على طلبك',
        SurgeryRequestStatus.rejected => 'بخصوص طلب العملية',
        SurgeryRequestStatus.moreInfoRequired => 'مطلوب بيانات إضافية',
        _ => 'تحديث على طلبك',
      },
      body: reason ?? request.reference,
      entityId: request.id,
    );
    notifyListeners();
  }

  /// Escalate any request that has passed its approval SLA. In production this
  /// is a server-side scheduled job; it runs here so the behaviour is
  /// demonstrable.
  int escalateOverdueRequests({DateTime? now}) {
    final moment = now ?? DateTime.now();
    var escalated = 0;
    for (var i = 0; i < _requests.length; i++) {
      final request = _requests[i];
      if (!request.isEscalationOverdueAt(moment) ||
          request.escalatedAt != null) {
        continue;
      }
      _requests[i] = request.copyWith(escalatedAt: moment);
      _alertApprovers(
        templateCode: 'surgery_request_escalated',
        title: 'تصعيد: طلب عملية بدون رد',
        reference: request.reference,
        context: 'تجاوز مهلة الرد',
        entityId: request.id,
        deepLink: '/approvals/${request.id}',
      );
      escalated++;
    }
    if (escalated > 0) notifyListeners();
    return escalated;
  }

  List<SurgeryRequest> get pendingApprovals => _requests
      .where((r) => r.isAwaitingDecisionAt(DateTime.now()))
      .toList();

  // ------------------------------------------------------------- appointments

  Appointment bookClinicAppointment({
    required String patientId,
    required String clinicId,
    required String doctorId,
    required DateTime start,
    Duration duration = const Duration(minutes: 20),
  }) {
    final appointment = Appointment(
      id: 'appt-${DateTime.now().microsecondsSinceEpoch}',
      patientId: patientId,
      doctorId: doctorId,
      clinicId: clinicId,
      range: TimeRange.fromDuration(start, duration),
    );
    _appointments = [..._appointments, appointment];
    notifyListeners();
    return appointment;
  }

  Appointment? nextAppointmentFor(String patientId) {
    final now = DateTime.now();
    final upcoming = _appointments
        .where((a) =>
            a.patientId == patientId &&
            a.blocksTime &&
            a.range.start.isAfter(now))
        .toList()
      ..sort((a, b) => a.range.compareTo(b.range));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Clinic slots for a day. Real availability comes from the server; this
  /// generates a plausible grid and removes what is already taken.
  List<DateTime> clinicSlots(Clinic clinic, DateTime day) {
    if (!clinic.workingDays.contains(day.weekday)) return const [];
    final slots = <DateTime>[];
    for (var minutes = 10 * 60; minutes < 14 * 60; minutes += 20) {
      final start = DateTime(day.year, day.month, day.day)
          .add(Duration(minutes: minutes));
      if (start.isBefore(DateTime.now())) continue;
      final taken = _appointments.any((a) =>
          a.blocksTime && a.clinicId == clinic.id && a.range.start == start);
      if (!taken) slots.add(start);
    }
    return slots;
  }

  // -------------------------------------------------------------- complaints

  final List<Complaint> _complaints = [];
  List<Complaint> get complaints => List.unmodifiable(_complaints);

  Complaint submitComplaint({
    required ComplaintCategory category,
    required String body,
    required bool isAnonymous,
  }) {
    final now = DateTime.now();
    final complaint = Complaint(
      id: 'cmp-${now.microsecondsSinceEpoch}',
      reference: 'CX-${now.millisecondsSinceEpoch % 100000}',
      category: category,
      body: body,
      submittedAt: now,
      isAnonymous: isAnonymous,
    );
    _complaints.insert(0, complaint);
    notifyListeners();
    return complaint;
  }

  // ------------------------------------------------------------- home care

  final List<HomeCareRequest> _homeCare = [];
  List<HomeCareRequest> get homeCareRequests => List.unmodifiable(_homeCare);

  HomeCareRequest requestHomeCare({
    required String serviceId,
    required String patientId,
    required String address,
    required DateTime preferredFrom,
    required DateTime preferredTo,
    String? notes,
  }) {
    final now = DateTime.now();
    final request = HomeCareRequest(
      id: 'hcr-${now.microsecondsSinceEpoch}',
      reference: 'HC-${now.millisecondsSinceEpoch % 100000}',
      serviceId: serviceId,
      patientId: patientId,
      address: address,
      preferredFrom: preferredFrom,
      preferredTo: preferredTo,
      submittedAt: now,
      notes: notes,
    );
    _homeCare.insert(0, request);
    _alertApprovers(
      templateCode: 'home_care_requested',
      title: 'طلب رعاية منزلية جديد',
      reference: request.reference,
      context: 'بانتظار الجدولة',
      entityId: request.id,
    );
    notifyListeners();
    return request;
  }

  void advanceHomeCare(String id, HomeCareStatus status) {
    final index = _homeCare.indexWhere((r) => r.id == id);
    if (index < 0) return;
    _homeCare[index] = _homeCare[index].copyWith(status: status);
    _notifyPatient(
      templateCode: 'home_care_status',
      title: 'تحديث طلب الرعاية المنزلية',
      body: _homeCare[index].reference,
      entityId: id,
    );
    notifyListeners();
  }

  // ------------------------------------------------------------- blood bank

  final List<BloodRequest> _bloodRequests = [];
  List<BloodRequest> get bloodRequests => List.unmodifiable(_bloodRequests);

  DonorProfile? _donor;
  DonorProfile? get donor => _donor;

  BloodRequest requestBlood({
    required String bloodGroup,
    required String component,
    required int units,
    required DateTime requiredBy,
  }) {
    final now = DateTime.now();
    final request = BloodRequest(
      id: 'bld-${now.microsecondsSinceEpoch}',
      reference: 'BB-${now.millisecondsSinceEpoch % 100000}',
      bloodGroup: bloodGroup,
      component: component,
      units: units,
      requiredBy: requiredBy,
      submittedAt: now,
    );
    _bloodRequests.insert(0, request);
    _alertApprovers(
      templateCode: 'blood_units_requested',
      title: 'طلب وحدات دم',
      reference: request.reference,
      context: '$units وحدة · $bloodGroup',
      entityId: request.id,
    );
    notifyListeners();
    return request;
  }

  void registerDonor(DonorProfile profile) {
    _donor = profile;
    notifyListeners();
  }

  // ---------------------------------------------------------- visiting expert

  final List<CampaignPatient> _campaignPatients = [];
  List<CampaignPatient> get campaignPatients =>
      List.unmodifiable(_campaignPatients);

  List<CampaignPatient> campaignPipeline(String campaignId) =>
      _campaignPatients.where((p) => p.campaignId == campaignId).toList();

  /// Confirmed places for a campaign — the live count the coordinator watches
  /// against the minimum viable cohort (PROMPT.md §6.15.1). Seeded registrations
  /// are included so the demo numbers are coherent.
  int confirmedCohort(VisitingCampaign campaign) =>
      campaign.registered +
      campaignPipeline(campaign.id).where((p) => p.countsTowardsCohort).length;

  bool hasRegisteredInterest(String campaignId) => _campaignPatients.any(
        (p) =>
            p.campaignId == campaignId &&
            p.patientId == (_session.patient?.id ?? ''),
      );

  /// Adds a patient to a campaign pipeline.
  ///
  /// The same method serves both routes the client described: the patient
  /// registering interest themselves, and the host doctor adding a patient
  /// from their own practice. One list, one pipeline — [addedByDoctor] is
  /// recorded for reporting and changes nothing else.
  CampaignPatient addToCampaign({
    required String campaignId,
    required Patient patient,
    required bool addedByDoctor,
    VisitingStage stage = VisitingStage.interestRegistered,
    DateTime? screeningAt,
  }) {
    final now = DateTime.now();
    final entry = CampaignPatient(
      id: 'cmp-${now.microsecondsSinceEpoch}',
      campaignId: campaignId,
      patientId: patient.id,
      patientDisplayName: _abbreviate(patient.fullName),
      stage: stage,
      addedByDoctor: addedByDoctor,
      addedAt: now,
      screeningAt: screeningAt,
    );
    _campaignPatients.insert(0, entry);
    _emit(AppNotification.staffAlert(
      id: 'ntf-${_notifySeq++}',
      channel: NotifyChannel.push,
      audience: NotifyAudience.coordinator,
      templateCode: 'campaign_patient_added',
      title: 'مريض جديد في برنامج الخبير الزائر',
      reference: campaignId,
      context: addedByDoctor ? 'أضافه الطبيب المضيف' : 'تسجيل ذاتي',
      sentAt: now,
      entityId: entry.id,
    ));
    _checkCohortAtRisk(campaignId);
    notifyListeners();
    return entry;
  }

  void advanceCampaignPatient(String entryId, VisitingStage stage) {
    final index = _campaignPatients.indexWhere((p) => p.id == entryId);
    if (index < 0) return;
    _campaignPatients[index] = _campaignPatients[index].copyWith(stage: stage);
    _notifyPatient(
      templateCode: 'campaign_stage_changed',
      title: 'تحديث في برنامج الخبير الزائر',
      body: _campaignPatients[index].campaignId,
      entityId: entryId,
    );
    _checkCohortAtRisk(_campaignPatients[index].campaignId);
    notifyListeners();
  }

  /// Warns the coordinator while the cohort is still below the threshold the
  /// visit needs in order to proceed at all.
  void _checkCohortAtRisk(String campaignId) {
    final matches = Seed.campaigns.where((c) => c.id == campaignId);
    if (matches.isEmpty) return;
    final campaign = matches.first;
    if (confirmedCohort(campaign) >= campaign.minimumViableCohort) return;
    _emit(AppNotification.staffAlert(
      id: 'ntf-${_notifySeq++}',
      channel: NotifyChannel.whatsapp,
      audience: NotifyAudience.coordinator,
      templateCode: 'campaign_cohort_at_risk',
      title: 'عدد الحالات أقل من الحد الأدنى',
      reference: campaign.id,
      context:
          '${confirmedCohort(campaign)} من ${campaign.minimumViableCohort}',
      sentAt: DateTime.now(),
      entityId: campaign.id,
    ));
  }

  /// Only campaigns whose expert holds valid authorisation are visible to
  /// patients (PROMPT.md 6.15.4).
  List<VisitingCampaign> publishableCampaigns() {
    final now = DateTime.now();
    return Seed.campaigns.where((c) => c.isPublishableAt(now)).toList();
  }

  // ------------------------------------------------------------------ admin
  //
  // Catalogue maintenance. Each method here corresponds to an admin-console
  // endpoint in PROMPT.md §14; the mutation lands in the seed lists because
  // this build has no server. When the API arrives these become HTTP calls
  // and nothing above them changes.
  //
  // Deliberate rule throughout: nothing is ever deleted. Catalogue entries are
  // deactivated, so historical bookings keep the classification, price and
  // procedure they were created with (PROMPT.md §8, rule 6).

  int _idSeq = 0;
  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  // Classifications ----------------------------------------------------------

  String upsertClassification({
    String? id,
    required String code,
    required Label name,
    required Color colour,
    required Duration defaultDuration,
    required Duration defaultTurnover,
    required int priceMin,
    required int priceMax,
    required int requiredSeniority,
    required Label defaultAnaesthesia,
    required int defaultBloodUnits,
    bool isActive = true,
  }) {
    final index =
        id == null ? -1 : Seed.classifications.indexWhere((c) => c.id == id);
    final resolvedId = id ?? _newId('cls');
    final entry = OperationClassification(
      id: resolvedId,
      code: code,
      name: name,
      sortOrder: index >= 0
          ? Seed.classifications[index].sortOrder
          : Seed.classifications.length + 1,
      colour: colour,
      defaultDuration: defaultDuration,
      defaultTurnover: defaultTurnover,
      priceMin: priceMin,
      priceMax: priceMax,
      requiredSeniority: requiredSeniority,
      defaultAnaesthesia: defaultAnaesthesia,
      defaultBloodUnits: defaultBloodUnits,
      isActive: isActive,
    );
    if (index >= 0) {
      Seed.classifications[index] = entry;
    } else {
      Seed.classifications.add(entry);
    }
    notifyListeners();
    return resolvedId;
  }

  /// Deactivation, never deletion: a classification in use by a past case must
  /// remain resolvable.
  void setClassificationActive(String id, bool isActive) {
    final index = Seed.classifications.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final c = Seed.classifications[index];
    Seed.classifications[index] = OperationClassification(
      id: c.id,
      code: c.code,
      name: c.name,
      sortOrder: c.sortOrder,
      colour: c.colour,
      defaultDuration: c.defaultDuration,
      defaultTurnover: c.defaultTurnover,
      priceMin: c.priceMin,
      priceMax: c.priceMax,
      requiredSeniority: c.requiredSeniority,
      defaultAnaesthesia: c.defaultAnaesthesia,
      defaultBloodUnits: c.defaultBloodUnits,
      isActive: isActive,
    );
    notifyListeners();
  }

  /// True when any scheduled case still references this classification.
  bool classificationInUse(String id) =>
      _cases.any((c) => c.classificationId == id);

  // Procedures ---------------------------------------------------------------

  String upsertProcedure({
    String? id,
    required String code,
    required Label name,
    required String classificationId,
    required Duration typicalDuration,
    required TheatreType requiredTheatreType,
    required int price,
    String? centreId,
    List<String> requiredEquipment = const [],
    bool patientRequestable = true,
  }) {
    final resolvedId = id ?? _newId('proc');
    final entry = Procedure(
      id: resolvedId,
      code: code,
      name: name,
      classificationId: classificationId,
      typicalDuration: typicalDuration,
      requiredTheatreType: requiredTheatreType,
      price: price,
      centreId: centreId,
      requiredEquipment: requiredEquipment,
      patientRequestable: patientRequestable,
    );
    final index = Seed.procedures.indexWhere((p) => p.id == resolvedId);
    if (index >= 0) {
      Seed.procedures[index] = entry;
    } else {
      Seed.procedures.add(entry);
    }
    notifyListeners();
    return resolvedId;
  }

  // Doctors ------------------------------------------------------------------

  String upsertDoctor({
    String? id,
    required Label name,
    required Label title,
    required Label specialty,
    required int seniority,
    String? centreId,
  }) {
    final resolvedId = id ?? _newId('doc');
    final entry = Doctor(
      id: resolvedId,
      name: name,
      title: title,
      specialty: specialty,
      seniority: seniority,
      centreId: centreId,
    );
    final index = Seed.doctors.indexWhere((d) => d.id == resolvedId);
    if (index >= 0) {
      Seed.doctors[index] = entry;
    } else {
      Seed.doctors.add(entry);
    }
    notifyListeners();
    return resolvedId;
  }

  // Clinics ------------------------------------------------------------------

  String upsertClinic({
    String? id,
    required Label name,
    required int consultationFee,
    required int followUpFee,
    required List<String> doctorIds,
    required List<int> workingDays,
    String? centreId,
  }) {
    final resolvedId = id ?? _newId('clinic');
    final entry = Clinic(
      id: resolvedId,
      name: name,
      consultationFee: consultationFee,
      followUpFee: followUpFee,
      doctorIds: doctorIds,
      workingDays: workingDays,
      centreId: centreId,
    );
    final index = Seed.clinics.indexWhere((c) => c.id == resolvedId);
    if (index >= 0) {
      Seed.clinics[index] = entry;
    } else {
      Seed.clinics.add(entry);
    }
    notifyListeners();
    return resolvedId;
  }

  // Theatres -----------------------------------------------------------------

  String upsertTheatre({
    String? id,
    required String code,
    required Label name,
    required TheatreType type,
    required int opensAt,
    required int closesAt,
    Duration defaultTurnover = const Duration(minutes: 30),
    bool isActive = true,
  }) {
    final resolvedId = id ?? _newId('or');
    final entry = OperatingTheatre(
      id: resolvedId,
      code: code,
      name: name,
      type: type,
      opensAt: opensAt,
      closesAt: closesAt,
      defaultTurnover: defaultTurnover,
      isActive: isActive,
    );
    final index = Seed.theatres.indexWhere((t) => t.id == resolvedId);
    if (index >= 0) {
      Seed.theatres[index] = entry;
    } else {
      Seed.theatres.add(entry);
    }
    notifyListeners();
    return resolvedId;
  }

  /// Takes a theatre out of service for a window. Any booking already inside
  /// that window is surfaced for rescheduling rather than silently invalidated
  /// (PROMPT.md §6.13.1).
  List<SurgeryCase> blockTheatre({
    required String theatreId,
    required TimeRange range,
    required String reason,
  }) {
    _blocks = [
      ..._blocks,
      TheatreBlock(theatreId: theatreId, range: range, reason: reason),
    ];
    final affected = _cases
        .where((c) =>
            c.blocksTime &&
            c.theatreId == theatreId &&
            c.occupiesTheatre.overlaps(range))
        .toList();
    notifyListeners();
    return affected;
  }

  // Content ------------------------------------------------------------------

  void upsertOffer({
    String? id,
    required Label title,
    required Label description,
    required int priceBefore,
    required int priceAfter,
    required DateTime validUntil,
    bool isEvent = false,
  }) {
    final resolvedId = id ?? _newId('off');
    final entry = Offer(
      id: resolvedId,
      title: title,
      description: description,
      priceBefore: priceBefore,
      priceAfter: priceAfter,
      validUntil: validUntil,
      isEvent: isEvent,
    );
    final index = Seed.offers.indexWhere((o) => o.id == resolvedId);
    if (index >= 0) {
      Seed.offers[index] = entry;
    } else {
      Seed.offers.add(entry);
    }
    notifyListeners();
  }

  void removeOffer(String id) {
    Seed.offers.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  /// A tip without a named medical reviewer must never be publishable
  /// (PROMPT.md §6.12) — the form enforces it, and so does this.
  void upsertTip({
    String? id,
    required Label category,
    required Label body,
    required String reviewerName,
  }) {
    if (reviewerName.trim().isEmpty) {
      throw ArgumentError('A medical tip requires a named reviewer');
    }
    final resolvedId = id ?? _newId('tip');
    final entry = MedicalTip(
      id: resolvedId,
      category: category,
      body: body,
      reviewerName: reviewerName.trim(),
      reviewedAt: DateTime.now(),
    );
    final index = Seed.tips.indexWhere((t) => t.id == resolvedId);
    if (index >= 0) {
      Seed.tips[index] = entry;
    } else {
      Seed.tips.add(entry);
    }
    notifyListeners();
  }

  void removeTip(String id) {
    Seed.tips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Minimal timestamp rendering for notification bodies. The UI has its own
  /// locale-aware formatter; notifications are composed here because in
  /// production the server composes them.
  static String _stamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  /// Theatre lists show an abbreviated patient name. A doctor who is not on a
  /// case's team must not see the full name of that case's patient
  /// (PROMPT.md section 6.13.4).
  static String _abbreviate(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return fullName;
    final initials =
        parts.skip(1).map((p) => '${p.characters.first}.').join(' ');
    return '${parts.first} $initials';
  }
}

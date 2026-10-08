import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../core/validation/national_id.dart';
import '../domain/models/booking.dart';
import '../domain/models/catalog.dart';
import '../domain/models/content.dart';
import '../domain/models/enums.dart';
import '../domain/models/governance.dart';
import '../domain/models/operations.dart';
import '../domain/models/patient.dart';
import '../domain/models/time_range.dart';
import '../domain/scheduling/booking_conflicts.dart';
import 'codec.dart';
import 'seed_data.dart';
import 'storage.dart';

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

/// Outcome of registering a patient.
enum RegistrationResult { created, nationalIdInvalid, alreadyRegistered }

/// Outcome of booking a clinic appointment.
sealed class AppointmentOutcome {
  const AppointmentOutcome();
}

class AppointmentBooked extends AppointmentOutcome {
  const AppointmentBooked(this.appointment);
  final Appointment appointment;
}

/// The slot was taken, or the doctor's day filled up, after the patient
/// opened the screen.
class AppointmentSlotGone extends AppointmentOutcome {
  const AppointmentSlotGone();
}

/// The patient already holds a booking with this doctor on this day.
class AppointmentDuplicate extends AppointmentOutcome {
  const AppointmentDuplicate(this.existing);
  final Appointment existing;
}

/// Application state, saved on the device.
///
/// Every method here maps to an endpoint of the API described in PROMPT.md
/// section 9; when a shared server is connected, only this class changes.
///
/// It deliberately preserves the server's authority model: bookings re-check
/// availability at write time rather than trusting whatever the screen last
/// displayed, mirroring the database constraint that does the real
/// arbitration once there is a server.
class AppState extends ChangeNotifier {
  AppState({StorageBackend? storage}) : _storage = storage ?? MemoryStorage();

  static const _scheduler = TheatreScheduler();

  // --------------------------------------------------------------- storage

  final StorageBackend _storage;
  bool _loaded = false;
  bool _saveQueued = false;

  /// Version of the bundled catalogue this device was last seeded from.
  int _dataVersion = 0;

  /// Once the administration edits the catalogue, a newer bundled catalogue
  /// in an app update must not overwrite their work.
  bool _catalogueEdited = false;

  bool get isLoaded => _loaded;

  /// Loads saved data, or seeds from the hospital's bundled catalogue on the
  /// first launch.
  Future<void> load({required Map<String, dynamic> bundled}) async {
    Map<String, dynamic>? saved;
    try {
      final raw = await _storage.read();
      if (raw != null && raw.isNotEmpty) {
        saved = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } on FormatException {
      saved = null; // A corrupt save is replaced rather than crashing.
    }

    final bundledVersion = Codec.toInt(bundled['dataVersion'], 1);
    Seed.clear();
    if (saved == null) {
      Seed.loadFrom(bundled);
      _dataVersion = bundledVersion;
      _ensureAdminAccount();
    } else {
      _restore(saved);
      final catalogue = saved['catalogue'] is Map
          ? Map<String, dynamic>.from(saved['catalogue'] as Map)
          : null;
      if (catalogue != null) {
        // Name what earlier bookings booked while their catalogue is loaded,
        // so replacing the catalogue below cannot orphan them.
        Seed.loadFrom(catalogue);
        _snapshotLabBookingNames();
        Seed.clear();
      }
      final upgrade = !_catalogueEdited && bundledVersion > _dataVersion;
      // The bundled catalogue first, then the saved one over it: a list this
      // device has never saved (a department added in an update) still
      // arrives, while everything the administration has edited is kept.
      Seed.loadFrom(bundled);
      if (!upgrade && catalogue != null) {
        // A department saved empty is one this device never had data for.
        catalogue.removeWhere((key, value) =>
            value is List &&
            value.isEmpty &&
            bundled[key] is List &&
            (bundled[key] as List).isNotEmpty);
        Seed.loadFrom(catalogue);
      }
      if (upgrade) _dataVersion = bundledVersion;
      _ensureAdminAccount();
      _resumeSession(saved['session']);
    }
    _loaded = true;
    super.notifyListeners();
    await _flush();
  }

  /// Every change is followed by a save. Saves are coalesced, so a burst of
  /// changes in one frame writes once.
  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_loaded || _saveQueued) return;
    _saveQueued = true;
    scheduleMicrotask(() {
      _saveQueued = false;
      unawaited(_flush());
    });
  }

  Future<void> _flush() => _storage.write(jsonEncode(toJson()));

  Map<String, dynamic> toJson() => {
        'v': 1,
        'dataVersion': _dataVersion,
        'catalogueEdited': _catalogueEdited,
        'catalogue': Seed.toJson(),
        'patients': _patients.map(Codec.patient).toList(),
        'staff': _staff.map(Codec.staff).toList(),
        'appointments': _appointments.map(Codec.appointment).toList(),
        'labBookings': _labBookings.map(Codec.labBooking).toList(),
        'complaints': _complaints.map(Codec.complaint).toList(),
        'cases': _cases.map(Codec.surgeryCase).toList(),
        'blocks': _blocks.map(Codec.block).toList(),
        'requests': _requests.map(Codec.surgeryRequest).toList(),
        'audits': _audits.take(1000).map(Codec.audit).toList(),
        'notifications':
            _notifications.take(300).map(Codec.notification).toList(),
        'policy': Codec.policy(_policy),
        'prefs': {
          'locale': _locale.languageCode,
          'theme': _themeMode.name,
        },
        'session': {
          'patientId': _session.isStaff ? null : _session.patient?.id,
          'staffId': _session.staffId,
        },
      };

  void _restore(Map<String, dynamic> doc) {
    _dataVersion = Codec.toInt(doc['dataVersion']);
    _catalogueEdited = (doc['catalogueEdited'] as bool?) ?? false;
    _patients
      ..clear()
      ..addAll(Codec.list(doc['patients'], Codec.toPatient));
    _staff
      ..clear()
      ..addAll(Codec.list(doc['staff'], Codec.toStaff));
    _appointments = Codec.list(doc['appointments'], Codec.toAppointment);
    _labBookings
      ..clear()
      ..addAll(Codec.list(doc['labBookings'], Codec.toLabBooking));
    _complaints
      ..clear()
      ..addAll(Codec.list(doc['complaints'], Codec.toComplaint));
    _cases = Codec.list(doc['cases'], Codec.toSurgeryCase);
    _blocks = Codec.list(doc['blocks'], Codec.toBlock);
    _requests
      ..clear()
      ..addAll(Codec.list(doc['requests'], Codec.toSurgeryRequest));
    _audits
      ..clear()
      ..addAll(Codec.list(doc['audits'], Codec.toAudit));
    _notifications
      ..clear()
      ..addAll(Codec.list(doc['notifications'], Codec.toNotification));
    _notifySeq = _notifications.length;
    _policy = Codec.toPolicy(doc['policy']);
    final prefs = doc['prefs'];
    if (prefs is Map) {
      _locale = Locale((prefs['locale'] as String?) ?? 'ar');
      _themeMode = Codec.toEnum(
          ThemeMode.values, prefs['theme'], ThemeMode.system);
    }
  }

  void _resumeSession(Object? json) {
    if (json is! Map) return;
    final staffId = json['staffId'] as String?;
    final patientId = json['patientId'] as String?;
    if (staffId != null) {
      final user = staffById(staffId);
      if (user != null && user.isActive) _session = _sessionFor(user);
    } else if (patientId != null) {
      final patient = patientById(patientId);
      if (patient != null) {
        _session = Session(role: UserRole.patient, patient: patient);
      }
    }
  }

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

  // Patients ------------------------------------------------------------------

  final List<Patient> _patients = [];
  List<Patient> get patients => List.unmodifiable(_patients);

  Patient? patientById(String id) {
    for (final p in _patients) {
      if (p.id == id) return p;
    }
    return null;
  }

  Patient? patientByNationalId(String nationalId) {
    final wanted = NationalId.normalise(nationalId);
    for (final p in _patients) {
      if (p.nationalId == wanted) return p;
    }
    return null;
  }

  /// Creates a patient account and signs it in.
  ///
  /// The National ID is the identity: date of birth, sex and governorate come
  /// from it rather than being typed, and it can only be registered once.
  RegistrationResult registerPatient({
    required String fullName,
    required String nationalId,
    required String phone,
    String? email,
    String? companyName,
    String? googleEmail,
    bool signIn = true,
  }) {
    final parsed = NationalId.parse(nationalId);
    final info = parsed.info;
    if (!parsed.isValid || info == null) {
      return RegistrationResult.nationalIdInvalid;
    }
    final normalised = NationalId.normalise(nationalId);
    if (patientByNationalId(normalised) != null) {
      return RegistrationResult.alreadyRegistered;
    }
    final now = DateTime.now();
    final patient = Patient(
      id: _newId('pat'),
      mrn: 'DO-${(now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
      fullName: fullName.trim().replaceAll(RegExp(r'\s+'), ' '),
      phoneE164: PhoneNumber.toE164(phone) ?? NationalId.normalise(phone),
      dateOfBirth: info.dateOfBirth,
      isMale: info.isMale,
      email: (email == null || email.trim().isEmpty) ? null : email.trim(),
      companyName: (companyName == null || companyName.trim().isEmpty)
          ? null
          : companyName.trim(),
      nationalId: normalised,
      governorate: info.governorateAr,
      createdAt: now,
      googleEmail: googleEmail,
    );
    _patients.add(patient);
    _lastRegistered = patient;
    // Reception registering a caller stays signed in as reception.
    if (signIn) _session = Session(role: UserRole.patient, patient: patient);
    _audit('created', 'patient', patient.id, detail: patient.mrn);
    notifyListeners();
    return RegistrationResult.created;
  }

  Patient? _lastRegistered;

  /// The patient most recently created by [registerPatient].
  Patient? get lastRegistered => _lastRegistered;

  /// Finds patients by name, National ID, phone or file number.
  List<Patient> searchPatients(String query) {
    final q = NationalId.normalise(query);
    final text = query.trim();
    if (text.isEmpty) return List.of(_patients.reversed);
    return _patients.reversed.where((p) {
      if (q.isNotEmpty &&
          ((p.nationalId ?? '').contains(q) ||
              p.phoneLocal.contains(q) ||
              p.mrn.contains(q))) {
        return true;
      }
      return p.fullName.contains(text) || p.mrn.contains(text.toUpperCase());
    }).toList();
  }

  /// A returning patient signs in with their National ID and the mobile
  /// number they registered with — two things only they should know together.
  bool signInPatient({required String nationalId, required String phone}) {
    final patient = patientByNationalId(nationalId);
    if (patient == null) return false;
    if (patient.phoneE164 != PhoneNumber.toE164(phone)) return false;
    _session = Session(role: UserRole.patient, patient: patient);
    notifyListeners();
    return true;
  }

  // Staff -----------------------------------------------------------------------

  /// The account the hospital receives the app with. Its password must be
  /// changed on first use; the admin console nags until it is.
  static const defaultAdminUsername = 'admin';
  static const defaultAdminPassword = 'admin123';

  void _ensureAdminAccount() {
    if (_staff.any((u) => u.roles.contains(UserRole.admin))) return;
    const id = 'usr-admin';
    _staff.add(StaffUser(
      id: id,
      name: 'مدير النظام',
      phone: '',
      roles: const {UserRole.admin},
      username: defaultAdminUsername,
      passwordHash: hashPassword(id, defaultAdminPassword),
    ));
  }

  /// Salted with the account id, so two accounts with the same password do
  /// not share a hash.
  static String hashPassword(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  bool get adminUsesDefaultPassword => _staff.any((u) =>
      u.username == defaultAdminUsername &&
      u.passwordHash == hashPassword(u.id, defaultAdminPassword));

  StaffUser? staffById(String id) {
    for (final u in _staff) {
      if (u.id == id) return u;
    }
    return null;
  }

  Session _sessionFor(StaffUser user) => Session(
        role: user.primaryRole,
        doctorId: user.doctorId,
        staffId: user.id,
        staffName: user.name,
      );

  StaffUser? get currentStaff =>
      _session.staffId == null ? null : staffById(_session.staffId!);

  /// Signs a member of staff in. Inactive accounts are refused.
  bool signInStaff({required String username, required String password}) {
    final wanted = username.trim().toLowerCase();
    for (final user in _staff) {
      if (user.username.toLowerCase() != wanted || !user.isActive) continue;
      if (user.passwordHash != hashPassword(user.id, password)) return false;
      _session = _sessionFor(user);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Changes the signed-in member of staff's password.
  bool changeOwnPassword({required String current, required String next}) {
    final user = currentStaff;
    if (user == null) return false;
    if (user.passwordHash != hashPassword(user.id, current)) return false;
    final index = _staff.indexWhere((u) => u.id == user.id);
    _staff[index] =
        user.copyWith(passwordHash: hashPassword(user.id, next));
    _audit('updated', 'password', user.id);
    notifyListeners();
    return true;
  }

  /// Test support only: put known records in place without going through
  /// the screens.
  @visibleForTesting
  void debugInstall({
    List<Patient> patients = const [],
    List<SurgeryCase> cases = const [],
    List<TheatreBlock> blocks = const [],
    List<Appointment> appointments = const [],
  }) {
    _patients
      ..clear()
      ..addAll(patients);
    _cases = [...cases];
    _blocks = [...blocks];
    _appointments = [...appointments];
    _ensureAdminAccount();
  }

  /// Test support only: sign in as a role without credentials.
  @visibleForTesting
  void signInAsPatient([Patient? patient]) {
    final who = patient ?? (_patients.isEmpty ? null : _patients.first);
    _session = Session(role: UserRole.patient, patient: who);
    notifyListeners();
  }

  @visibleForTesting
  void signInAsDoctor(String doctorId) {
    _session = Session(
      role: UserRole.doctor,
      doctorId: doctorId,
      staffId: 'test-doctor',
      staffName: Seed.doctorById(doctorId).name.ar,
    );
    notifyListeners();
  }

  @visibleForTesting
  void signInAsAdmin() {
    _session = const Session(
        role: UserRole.admin, staffId: 'test-admin', staffName: 'الأدمن');
    notifyListeners();
  }

  @visibleForTesting
  void signInAsApprover() {
    _session = const Session(
        role: UserRole.surgeryApprover,
        staffId: 'test-approver',
        staffName: 'الموافق');
    notifyListeners();
  }

  void signOut() {
    _session = const Session.guest();
    notifyListeners();
  }

  // ----------------------------------------------------------- notifications

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// What the signed-in person should see: a patient their own messages,
  /// staff the staff alerts.
  List<AppNotification> get myNotifications {
    final session = _session;
    if (session.isStaff) {
      return _notifications
          .where((n) =>
              n.audience != NotifyAudience.patient &&
              (n.audience != NotifyAudience.surgeon ||
                  n.recipientId == null ||
                  n.recipientId == session.doctorId))
          .toList();
    }
    final patient = session.patient;
    if (patient == null) return const [];
    return _notifications
        .where((n) =>
            n.audience == NotifyAudience.patient &&
            n.recipientId == patient.id)
        .toList();
  }

  int get unreadApproverAlerts => _notifications
      .where((n) => n.audience == NotifyAudience.approvers)
      .length;

  int _notifySeq = 0;

  void _emit(AppNotification notification) {
    _notifications.insert(0, notification);
  }

  /// Alerts the staff inside the app. The message carries a reference and
  /// no clinical detail, so it is already in the form WhatsApp and SMS need
  /// (PROMPT.md §12.4, rule 1) — those channels are added when the hospital's
  /// WhatsApp Business and SMS accounts are connected; nothing is claimed to
  /// have been sent on them before then.
  void _alertApprovers({
    required String templateCode,
    required String title,
    required String reference,
    required String context,
    String? entityId,
    String? deepLink,
  }) {
    _emit(AppNotification.staffAlert(
      id: 'ntf-${_notifySeq++}',
      channel: NotifyChannel.inApp,
      audience: NotifyAudience.approvers,
      templateCode: templateCode,
      title: title,
      reference: reference,
      context: context,
      sentAt: DateTime.now(),
      entityId: entityId,
      deepLink: deepLink,
    ));
  }

  void _notifyPatient({
    required String? patientId,
    required String templateCode,
    required String title,
    required String body,
    String? entityId,
  }) {
    if (patientId == null) return;
    _emit(AppNotification(
      id: 'ntf-${_notifySeq++}',
      channel: NotifyChannel.inApp,
      audience: NotifyAudience.patient,
      templateCode: templateCode,
      title: title,
      body: body,
      sentAt: DateTime.now(),
      entityId: entityId,
      recipientId: patientId,
    ));
  }

  // ------------------------------------------------------------------ theatre

  List<SurgeryCase> _cases = [];
  List<Appointment> _appointments = [];
  List<TheatreBlock> _blocks = [];
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
      patientId: patient.id,
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
      patientId: request.patientId,
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

  /// Requests awaiting a theatre, a time and a price.
  List<SurgeryRequest> get awaitingScheduling => _requests
      .where((r) => r.status == SurgeryRequestStatus.approved)
      .toList();

  List<SurgeryRequest> requestsByDoctor(String doctorId) => _requests
      .where((r) => r.requestedByDoctorId == doctorId)
      .toList();

  /// A surgeon asks the administration for a slot.
  ///
  /// Unlike a patient request this is not a clinical question — the surgeon
  /// has already decided the case. What the administration allocates is the
  /// theatre, the time and the price.
  SurgeryRequest submitDoctorSurgeryRequest({
    required String doctorId,
    required Patient patient,
    required Procedure procedure,
    String? clinicalNote,
    DateTime? preferredFrom,
    DateTime? preferredTo,
  }) {
    final now = DateTime.now();
    final request = SurgeryRequest(
      id: 'req-${now.microsecondsSinceEpoch}',
      reference: 'DR-${now.millisecondsSinceEpoch % 1000000}',
      patientId: patient.id,
      procedureId: procedure.id,
      classificationId: procedure.classificationId,
      submittedAt: now,
      estimatePriceSnapshot: '${procedure.price}',
      origin: RequestOrigin.doctor,
      requestedByDoctorId: doctorId,
      clinicalNote: clinicalNote,
      preferredSurgeonId: doctorId,
      preferredFrom: preferredFrom,
      preferredTo: preferredTo,
    );
    _requests.insert(0, request);
    _alertApprovers(
      templateCode: 'doctor_theatre_request',
      title: 'طلب حجز غرفة عمليات من طبيب',
      reference: request.reference,
      context:
          '${Seed.classificationById(procedure.classificationId).name.ar} · '
          'بانتظار تحديد الموعد',
      entityId: request.id,
      deepLink: '/approvals/${request.id}',
    );
    _audit('created', 'surgery_request', request.id,
        detail: '${request.reference} · طلب طبيب');
    notifyListeners();
    return request;
  }

  /// The administration allocates a theatre, a time and a price, and confirms.
  ///
  /// On success the request becomes a real theatre case and the requesting
  /// surgeon is notified with the full detail — which is the point of the
  /// whole flow: the surgeon asked, and now knows exactly what they got.
  BookingOutcome scheduleRequest({
    required String requestId,
    required String theatreId,
    required String surgeonId,
    required DateTime start,
    required int price,
    Duration? duration,
    String? overrideReason,
  }) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index < 0) {
      return const BookingRejected(BookingCheck.clear());
    }
    final request = _requests[index];
    final procedure = Seed.procedureById(request.procedureId);
    final classification =
        Seed.classificationById(request.classificationId);
    final patient = patientById(request.patientId);
    if (patient == null) {
      return const BookingRejected(BookingCheck.clear());
    }

    final draft = BookingDraft(
      theatreId: theatreId,
      surgeonId: surgeonId,
      patientId: request.patientId,
      procedure: procedure,
      classification: classification,
      start: start,
      duration: duration,
    );

    final outcome = bookTheatreCase(
      draft: draft,
      patient: patient,
      origin: request.isFromDoctor
          ? BookingOrigin.doctorRequest
          : BookingOrigin.patientRequest,
      overrideReason: overrideReason,
    );

    if (outcome is! BookingAccepted) return outcome;

    _requests[index] = request.copyWith(
      status: SurgeryRequestStatus.scheduled,
      scheduledCaseId: outcome.surgeryCase.id,
      scheduledTheatreId: theatreId,
      scheduledStart: start,
      confirmedPrice: price,
      decidedAt: DateTime.now(),
    );

    final theatre = Seed.theatreById(theatreId);
    final detail = '${procedure.name.ar} · ${theatre.code} · '
        '${_stamp(start)} · $price ${'جنيه'}';

    // The surgeon who asked gets the full confirmation.
    if (request.requestedByDoctorId != null) {
      _emit(AppNotification(
        id: 'ntf-${_notifySeq++}',
        channel: NotifyChannel.inApp,
        audience: NotifyAudience.surgeon,
        recipientId: request.requestedByDoctorId,
        templateCode: 'theatre_request_scheduled',
        title: 'تم تأكيد حجز غرفة العمليات',
        body: detail,
        sentAt: DateTime.now(),
        entityId: request.id,
        deepLink: '/theatre',
      ));
    }

    _notifyPatient(
      patientId: request.patientId,
      templateCode: 'surgery_scheduled',
      title: 'تم تحديد موعد عمليتك',
      body: '${theatre.code} · ${_stamp(start)}',
      entityId: request.id,
    );

    _audit('scheduled', 'surgery_request', request.id, detail: detail);
    notifyListeners();
    return outcome;
  }

  // ------------------------------------------------------------- appointments

  /// Books a clinic appointment with a specific doctor.
  ///
  /// Availability is re-checked here, at write time: between the patient
  /// opening the screen and tapping the slot, someone else may have taken it
  /// or filled the doctor's day. Payment never gates the booking:
  /// [depositPaid] is zero unless a payment gateway took money.
  AppointmentOutcome bookClinicAppointment({
    required String patientId,
    required String clinicId,
    required String doctorId,
    required DateTime start,
    Duration? duration,
    int depositPaid = 0,
  }) {
    final now = DateTime.now();
    final clinic = Seed.clinicById(clinicId);
    if (clinic == null) return const AppointmentSlotGone();
    final doctor = Seed.doctorById(doctorId);

    final day = DateTime(start.year, start.month, start.day);
    if (!clinicSlots(clinic, day, doctorId: doctorId).contains(start)) {
      return const AppointmentSlotGone();
    }
    for (final a in _appointments) {
      if (a.blocksTime &&
          a.patientId == patientId &&
          a.doctorId == doctorId &&
          _isSameDay(a.range.start, start)) {
        return AppointmentDuplicate(a);
      }
    }

    final shift = doctor.shiftOn(start.weekday);
    final minutes = shift?.slotMinutes(clinic.slotMinutes) ?? clinic.slotMinutes;
    final appointment = Appointment(
      id: _newId('appt'),
      patientId: patientId,
      doctorId: doctorId,
      clinicId: clinicId,
      range: TimeRange.fromDuration(
          start, duration ?? Duration(minutes: minutes)),
      reference: 'AP-${(now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
      fee: clinic.consultationFee,
      depositPaid: depositPaid,
      createdAt: now,
    );
    _appointments = [..._appointments, appointment];
    _alertApprovers(
      templateCode: 'appointment_booked',
      title: 'حجز عيادة جديد',
      reference: appointment.reference,
      context: '${clinic.name.ar} · ${doctor.name.ar} · ${_stamp(start)}',
      entityId: appointment.id,
      deepLink: '/admin/bookings',
    );
    _notifyPatient(
      patientId: patientId,
      templateCode: 'appointment_confirmed',
      title: 'تم تأكيد حجزك',
      body: '${clinic.name.ar} · ${doctor.name.ar} · ${_stamp(start)}',
      entityId: appointment.id,
    );
    _audit('created', 'appointment', appointment.id,
        detail: '${appointment.reference} · ${clinic.name.ar} · ${_stamp(start)}');
    notifyListeners();
    return AppointmentBooked(appointment);
  }

  /// Cancels an appointment and tells the patient why.
  void cancelAppointment(
    String appointmentId, {
    required CancellationReason reason,
    String? note,
  }) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index < 0) return;
    final cancelled =
        _appointments[index].cancelledBecause(reason, note: note);
    _appointments = [..._appointments]..[index] = cancelled;
    final byPatient = reason == CancellationReason.patientRequested;
    if (!byPatient) {
      _notifyPatient(
        patientId: cancelled.patientId,
        templateCode: 'appointment_cancelled',
        title: 'تم إلغاء موعدك',
        body: note ?? cancelled.reference,
        entityId: cancelled.id,
      );
    } else {
      _alertApprovers(
        templateCode: 'appointment_cancelled_by_patient',
        title: 'إلغاء حجز من المريض',
        reference: cancelled.reference,
        context: _stamp(cancelled.range.start),
        entityId: cancelled.id,
        deepLink: '/admin/bookings',
      );
    }
    _audit('cancelled', 'appointment', cancelled.id, detail: reason.name);
    notifyListeners();
  }

  /// Reception marks the visit: attended, or did not come.
  void setAppointmentStatus(String appointmentId, AppointmentStatus status) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index < 0) return;
    _appointments = [..._appointments]
      ..[index] = _appointments[index].withStatus(status);
    _audit(status.name, 'appointment', appointmentId);
    notifyListeners();
  }

  /// Whether the patient may still cancel this appointment themselves.
  bool patientCanCancel(Appointment a) =>
      a.blocksTime &&
      a.range.start
          .subtract(_policy.clinicCancellationCutoff)
          .isAfter(DateTime.now());

  /// Appointments that a proposed schedule would break.
  ///
  /// Called before the change is saved, so the administrator sees the cost of
  /// the edit rather than discovering it from angry patients.
  List<Appointment> appointmentsBrokenBy({
    required String clinicId,
    required List<int> newWorkingDays,
    String? doctorId,
    List<DoctorShift>? newShifts,
  }) {
    final now = DateTime.now();
    return _appointments.where((a) {
      if (!a.blocksTime || !a.range.start.isAfter(now)) return false;
      if (a.clinicId != clinicId && a.doctorId != doctorId) return false;

      if (a.clinicId == clinicId &&
          !newWorkingDays.contains(a.range.start.weekday)) {
        return true;
      }
      if (doctorId != null && a.doctorId == doctorId && newShifts != null) {
        final shift = newShifts
            .where((sh) => sh.weekday == a.range.start.weekday)
            .toList();
        if (shift.isEmpty) return true;
        final minutes = a.range.start.hour * 60 + a.range.start.minute;
        if (minutes < shift.first.startsAt || minutes >= shift.first.endsAt) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Cancels every appointment a schedule change invalidates and notifies each
  /// patient that the times moved and they may rebook.
  int cancelBrokenAppointments(List<Appointment> broken) {
    if (broken.isEmpty) return 0;
    for (final appointment in broken) {
      cancelAppointment(
        appointment.id,
        reason: CancellationReason.scheduleChanged,
        note: _policy.notifyPatientsOnScheduleChange
            ? 'تم تعديل مواعيد العيادة. برجاء اختيار موعد جديد من التطبيق.'
            : null,
      );
    }
    return broken.length;
  }

  List<Appointment> appointmentsFor(String patientId) => _appointments
      .where((a) => a.patientId == patientId)
      .toList()
    ..sort((a, b) => b.range.start.compareTo(a.range.start));

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

  /// Bookable slots for a clinic on a day.
  ///
  /// Three things must agree before a slot exists: the clinic opens that day,
  /// a doctor of that clinic is on shift, and the doctor's cap for that shift
  /// has not been reached. The cap also decides how long each slot is — a
  /// doctor who takes 12 patients in a four-hour clinic gets 20-minute slots.
  List<DateTime> clinicSlots(Clinic clinic, DateTime day, {String? doctorId}) {
    if (!clinic.workingDays.contains(day.weekday)) return const [];

    final doctors = clinic.doctorIds
        .where((id) => doctorId == null || id == doctorId)
        .map(Seed.doctorById)
        .where((d) => d.isBookableOnline)
        .toList();
    if (doctors.isEmpty) return const [];

    final slots = <DateTime>{};
    final now = DateTime.now();

    for (final doctor in doctors) {
      // The doctor's own working window decides: no window on this weekday
      // means they are not in. A doctor with no windows at all (by
      // appointment, own patients only) is not booked online.
      final shift = doctor.shiftOn(day.weekday);
      if (shift == null || !shift.isValid) continue;
      final startsAt = shift.startsAt;
      final endsAt = shift.endsAt;
      final step = shift.slotMinutes(clinic.slotMinutes);

      final bookedForDoctor = _appointments
          .where((a) =>
              a.blocksTime &&
              a.doctorId == doctor.id &&
              _isSameDay(a.range.start, day))
          .length;
      final cap = shift.maxPatients;
      if (cap > 0 && bookedForDoctor >= cap) continue;

      var offered = 0;
      for (var minutes = startsAt; minutes + step <= endsAt; minutes += step) {
        if (cap > 0 && bookedForDoctor + offered >= cap) break;
        final start = DateTime(day.year, day.month, day.day)
            .add(Duration(minutes: minutes));
        if (start.isBefore(now)) continue;
        final taken = _appointments.any((a) =>
            a.blocksTime &&
            a.doctorId == doctor.id &&
            a.range.start == start);
        if (taken) continue;
        slots.add(start);
        offered++;
      }
    }

    final ordered = slots.toList()..sort();
    return ordered;
  }

  /// Remaining capacity for a doctor on a day. `null` means uncapped.
  int? remainingCapacity(Doctor doctor, DateTime day) {
    final shift = doctor.shiftOn(day.weekday);
    if (shift == null || shift.maxPatients <= 0) return null;
    final booked = _appointments
        .where((a) =>
            a.blocksTime &&
            a.doctorId == doctor.id &&
            _isSameDay(a.range.start, day))
        .length;
    return (shift.maxPatients - booked).clamp(0, shift.maxPatients);
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
      id: _newId('cmp'),
      reference: 'CX-${now.millisecondsSinceEpoch % 100000}',
      category: category,
      body: body,
      submittedAt: now,
      isAnonymous: isAnonymous,
      patientId: isAnonymous ? null : _session.patient?.id,
    );
    _complaints.insert(0, complaint);
    _alertApprovers(
      templateCode: 'complaint_received',
      title: 'شكوى جديدة',
      reference: complaint.reference,
      context: 'بانتظار الرد',
      entityId: complaint.id,
      deepLink: '/admin/complaints',
    );
    notifyListeners();
    return complaint;
  }

  /// Answers and closes a complaint. The patient is told, unless they chose
  /// to stay anonymous.
  void resolveComplaint(String id, String response) {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _complaints[index] = _complaints[index].resolvedWith(response, DateTime.now());
    _notifyPatient(
      patientId: _complaints[index].patientId,
      templateCode: 'complaint_resolved',
      title: 'رد على شكواك ${_complaints[index].reference}',
      body: response,
      entityId: id,
    );
    _audit('resolved', 'complaint', id);
    notifyListeners();
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
      patientId: _homeCare[index].patientId,
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
      patientId: _campaignPatients[index].patientId,
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

  // ------------------------------------------- policy, users and audit log

  HospitalPolicy _policy = const HospitalPolicy();
  HospitalPolicy get policy => _policy;

  void updatePolicy(HospitalPolicy value) {
    _policy = value;
    _audit('updated', 'policy', null,
        detail: 'حجز الأطباء المباشر: '
            '${value.doctorsBookTheatreDirectly ? "مفعّل" : "موقوف"}');
    notifyListeners();
  }

  final List<AuditEntry> _audits = [];

  /// Newest first. Append-only — nothing here is ever edited or removed.
  List<AuditEntry> get auditLog => List.unmodifiable(_audits);

  static const _catalogueEntities = {
    'classification', 'procedure', 'doctor', 'clinic', 'theatre',
    'lab_test', 'lab_package', 'offer', 'tip', 'price_item',
    'surgery_package',
  };

  void _audit(String action, String entity, String? entityId,
      {String? detail}) {
    if (_catalogueEntities.contains(entity)) _catalogueEdited = true;
    _audits.insert(
      0,
      AuditEntry(
        id: 'aud-${DateTime.now().microsecondsSinceEpoch}-${_audits.length}',
        actor: _actorName,
        action: action,
        entity: entity,
        entityId: entityId,
        at: DateTime.now(),
        detail: detail,
      ),
    );
  }

  String get _actorName {
    final name = _session.staffName;
    if (name != null && name.isNotEmpty) return name;
    return switch (_session.role) {
      UserRole.admin => 'الأدمن',
      UserRole.surgeryApprover => 'الموافق',
      UserRole.orScheduler => 'منسق العمليات',
      UserRole.reception => 'الاستقبال',
      UserRole.doctor => _session.doctorId == null
          ? 'طبيب'
          : Seed.doctorById(_session.doctorId!).name.ar,
      UserRole.patient => _session.patient?.fullName ?? 'مريض',
      UserRole.guest => 'زائر',
    };
  }

  final List<StaffUser> _staff = [];

  List<StaffUser> get staff => List.unmodifiable(_staff);

  bool usernameTaken(String username, {String? exceptId}) => _staff.any((u) =>
      u.id != exceptId &&
      u.username.toLowerCase() == username.trim().toLowerCase());

  /// Creates or edits a staff account. [password] is only applied when given,
  /// so editing someone's roles does not reset their password.
  String upsertStaff({
    String? id,
    required String name,
    required String phone,
    required Set<UserRole> roles,
    String? doctorId,
    bool isActive = true,
    String? username,
    String? password,
  }) {
    final resolvedId = id ?? _newId('usr');
    final existing = staffById(resolvedId);
    final user = StaffUser(
      id: resolvedId,
      name: name,
      phone: phone,
      roles: roles,
      doctorId: doctorId,
      isActive: isActive,
      username: (username ?? existing?.username ?? '').trim(),
      passwordHash: (password != null && password.isNotEmpty)
          ? hashPassword(resolvedId, password)
          : (existing?.passwordHash ?? ''),
    );
    final index = _staff.indexWhere((u) => u.id == resolvedId);
    if (index >= 0) {
      _staff[index] = user;
    } else {
      _staff.add(user);
    }
    _audit(id == null ? 'created' : 'updated', 'user', resolvedId,
        detail: '$name · ${roles.map((r) => r.name).join(", ")}');
    notifyListeners();
    return resolvedId;
  }

  void setStaffActive(String id, bool isActive) {
    final index = _staff.indexWhere((u) => u.id == id);
    if (index < 0) return;
    _staff[index] = _staff[index].copyWith(isActive: isActive);
    _audit(isActive ? 'enabled' : 'disabled', 'user', id);
    notifyListeners();
  }

  /// Every approval permission needs at least two holders, so nobody's leave
  /// can stall a patient's request (PROMPT.md §3.3, rule 3).
  int holdersOf(bool Function(UserRole) permission) =>
      _staff.where((u) => u.can(permission)).length;

  bool get approvalCoverageIsThin =>
      holdersOf((r) => r.canApproveSurgery) < 2;

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
    int theatreFee = 0,
    int overtimeFee = 0,
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
      theatreFee: theatreFee,
      overtimeFee: overtimeFee,
      isActive: isActive,
    );
    if (index >= 0) {
      Seed.classifications[index] = entry;
    } else {
      Seed.classifications.add(entry);
    }
    _audit(id == null ? 'created' : 'updated', 'classification', resolvedId,
        detail: name.ar);
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
    _audit(isActive ? 'enabled' : 'deactivated', 'classification', id,
        detail: c.name.ar);
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
    _audit(id == null ? 'created' : 'updated', 'procedure', resolvedId,
        detail: name.ar);
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
    List<DoctorShift> shifts = const [],
    String? scheduleNote,
    List<String>? clinicIds,
  }) {
    final resolvedId = id ?? _newId('doc');
    final existing = id == null ? null : Seed.doctors.where((d) => d.id == id);
    final entry = Doctor(
      id: resolvedId,
      name: name,
      title: title,
      specialty: specialty,
      seniority: seniority,
      centreId: centreId,
      shifts: shifts,
      // Null keeps the current note; an empty string clears it.
      scheduleNote: scheduleNote == null
          ? ((existing != null && existing.isNotEmpty)
              ? existing.first.scheduleNote
              : null)
          : (scheduleNote.isEmpty ? null : scheduleNote),
    );
    // Which clinics list this doctor, when the form says.
    if (clinicIds != null) {
      for (var i = 0; i < Seed.clinics.length; i++) {
        final c = Seed.clinics[i];
        final listed = c.doctorIds.contains(resolvedId);
        final wanted = clinicIds.contains(c.id);
        if (listed == wanted) continue;
        Seed.clinics[i] = _clinicWith(c,
            doctorIds: wanted
                ? [...c.doctorIds, resolvedId]
                : c.doctorIds.where((d) => d != resolvedId).toList());
      }
    }
    final index = Seed.doctors.indexWhere((d) => d.id == resolvedId);
    if (index >= 0) {
      Seed.doctors[index] = entry;
    } else {
      Seed.doctors.add(entry);
    }
    // A clinic is open on any day one of its doctors works. Without this, a
    // new working day for a doctor would silently produce no slots.
    for (var i = 0; i < Seed.clinics.length; i++) {
      final c = Seed.clinics[i];
      if (!c.doctorIds.contains(resolvedId)) continue;
      final days = {...c.workingDays, ...shifts.map((sh) => sh.weekday)}
          .toList()
        ..sort();
      if (days.length != c.workingDays.length) {
        Seed.clinics[i] = _clinicWith(c, workingDays: days);
      }
    }
    _audit(id == null ? 'created' : 'updated', 'doctor', resolvedId,
        detail: name.ar);
    notifyListeners();
    return resolvedId;
  }

  // Clinics ------------------------------------------------------------------

  static Clinic _clinicWith(Clinic c,
          {List<String>? doctorIds, List<int>? workingDays}) =>
      Clinic(
        id: c.id,
        name: c.name,
        note: c.note,
        consultationFee: c.consultationFee,
        followUpFee: c.followUpFee,
        doctorIds: doctorIds ?? c.doctorIds,
        workingDays: workingDays ?? c.workingDays,
        centreId: c.centreId,
        icon: c.icon,
        paymentPolicy: c.paymentPolicy,
        depositAmount: c.depositAmount,
        slotMinutes: c.slotMinutes,
      );

  String upsertClinic({
    String? id,
    required Label name,
    required int consultationFee,
    required int followUpFee,
    required List<String> doctorIds,
    required List<int> workingDays,
    String? centreId,
    PaymentPolicy paymentPolicy = PaymentPolicy.payAtReception,
    int depositAmount = 0,
    String? note,
    int? slotMinutes,
  }) {
    final resolvedId = id ?? _newId('clinic');
    final previous = Seed.clinicById(resolvedId);
    final entry = Clinic(
      id: resolvedId,
      name: name,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      consultationFee: consultationFee,
      followUpFee: followUpFee,
      doctorIds: doctorIds,
      workingDays: workingDays,
      centreId: centreId,
      paymentPolicy: paymentPolicy,
      depositAmount: depositAmount,
      slotMinutes: slotMinutes ?? previous?.slotMinutes ?? 15,
    );
    final index = Seed.clinics.indexWhere((c) => c.id == resolvedId);
    if (index >= 0) {
      Seed.clinics[index] = entry;
    } else {
      Seed.clinics.add(entry);
    }
    _audit(id == null ? 'created' : 'updated', 'clinic', resolvedId,
        detail: name.ar);
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
    _audit(id == null ? 'created' : 'updated', 'theatre', resolvedId,
        detail: name.ar);
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

  // Laboratory ---------------------------------------------------------------

  final List<LabBooking> _labBookings = [];
  List<LabBooking> get labBookings => List.unmodifiable(_labBookings);

  List<LabBooking> labBookingsFor(String patientId) => _labBookings
      .where((b) => b.patientId == patientId)
      .toList()
    ..sort((a, b) => b.visitAt.compareTo(a.visitAt));

  /// Prices a basket at today's prices.
  int labTotal({List<String> testIds = const [], List<String> packageIds = const []}) {
    var total = 0;
    for (final id in testIds) {
      total += Seed.labTestById(id)?.price ?? 0;
    }
    for (final id in packageIds) {
      total += Seed.labPackageById(id)?.price ?? 0;
    }
    return total;
  }

  void _snapshotLabBookingNames() {
    for (var i = 0; i < _labBookings.length; i++) {
      final b = _labBookings[i];
      if (b.itemNames.isNotEmpty) continue;
      _labBookings[i] = b.copyWith(itemNames: _labItemNames(b));
    }
  }

  List<String> _labItemNames(LabBooking b) => [
        for (final id in b.packageIds)
          if (Seed.labPackageById(id) case final p?) p.name.ar,
        for (final id in b.testIds)
          if (b.isRadiology)
            if (Seed.priceItemById(id) case final i?) i.name.ar else id
          else if (Seed.labTestById(id) case final t?)
            t.name.ar
          else
            id,
      ];

  /// Books a laboratory visit. The total is frozen at today's prices.
  LabBooking bookLab({
    required String patientId,
    required DateTime visitAt,
    List<String> testIds = const [],
    List<String> packageIds = const [],
  }) {
    if (testIds.isEmpty && packageIds.isEmpty) {
      throw ArgumentError('A lab booking needs at least one test or package');
    }
    final now = DateTime.now();
    final draft = LabBooking(
      id: _newId('lab'),
      reference: 'LB-${(now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
      patientId: patientId,
      visitAt: visitAt,
      testIds: List.unmodifiable(testIds),
      packageIds: List.unmodifiable(packageIds),
      total: labTotal(testIds: testIds, packageIds: packageIds),
      createdAt: now,
    );
    final booking = draft.copyWith(itemNames: _labItemNames(draft));
    _labBookings.insert(0, booking);
    final items = testIds.length + packageIds.length;
    _alertApprovers(
      templateCode: 'lab_booked',
      title: 'حجز معمل جديد',
      reference: booking.reference,
      context: '$items ${items == 1 ? 'بند' : 'بنود'} · ${_stamp(visitAt)}',
      entityId: booking.id,
      deepLink: '/admin/bookings',
    );
    _notifyPatient(
      patientId: patientId,
      templateCode: 'lab_booking_confirmed',
      title: 'تم تأكيد حجز المعمل',
      body: '${booking.reference} · ${_stamp(visitAt)}',
      entityId: booking.id,
    );
    _audit('created', 'lab_booking', booking.id, detail: booking.reference);
    notifyListeners();
    return booking;
  }

  /// Prices radiology studies (price-list item ids) at today's prices.
  int radiologyTotal(List<String> itemIds) {
    var total = 0;
    for (final id in itemIds) {
      total += Seed.priceItemById(id)?.price ?? 0;
    }
    return total;
  }

  /// Books a radiology visit. Like the lab, the department takes patients in
  /// arrival order, so the time orders the queue; the total is frozen.
  LabBooking bookRadiology({
    required String patientId,
    required DateTime visitAt,
    required List<String> itemIds,
  }) {
    if (itemIds.isEmpty) {
      throw ArgumentError('A radiology booking needs at least one study');
    }
    final now = DateTime.now();
    final draft = LabBooking(
      id: _newId('rad'),
      reference: 'RD-${(now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
      patientId: patientId,
      visitAt: visitAt,
      testIds: List.unmodifiable(itemIds),
      packageIds: const [],
      total: radiologyTotal(itemIds),
      createdAt: now,
      service: LabBooking.radiologyService,
    );
    final booking = draft.copyWith(itemNames: _labItemNames(draft));
    _labBookings.insert(0, booking);
    _alertApprovers(
      templateCode: 'radiology_booked',
      title: 'حجز أشعة جديد',
      reference: booking.reference,
      context: '${booking.itemNames.join('، ')} · ${_stamp(visitAt)}',
      entityId: booking.id,
      deepLink: '/admin/bookings',
    );
    _notifyPatient(
      patientId: patientId,
      templateCode: 'radiology_booking_confirmed',
      title: 'تم تأكيد حجز الأشعة',
      body: '${booking.reference} · ${_stamp(visitAt)}',
      entityId: booking.id,
    );
    _audit('created', 'lab_booking', booking.id, detail: booking.reference);
    notifyListeners();
    return booking;
  }

  void setLabBookingStatus(String id, AppointmentStatus status,
      {CancellationReason? reason}) {
    final index = _labBookings.indexWhere((b) => b.id == id);
    if (index < 0) return;
    _labBookings[index] =
        _labBookings[index].copyWith(status: status, cancelReason: reason);
    if (status == AppointmentStatus.cancelled &&
        reason != CancellationReason.patientRequested) {
      _notifyPatient(
        patientId: _labBookings[index].patientId,
        templateCode: 'lab_booking_cancelled',
        title: 'تم إلغاء حجز المعمل',
        body: _labBookings[index].reference,
        entityId: id,
      );
    }
    _audit(status.name, 'lab_booking', id);
    notifyListeners();
  }

  String upsertLabTest({
    String? id,
    required Label name,
    required Label category,
    required int price,
    String code = '',
    bool isActive = true,
  }) {
    final resolvedId = id ?? _newId('lab');
    final entry = LabTest(
      id: resolvedId,
      code: code,
      name: name,
      category: category,
      price: price,
      isActive: isActive,
    );
    final index = Seed.labTests.indexWhere((t) => t.id == resolvedId);
    if (index >= 0) {
      Seed.labTests[index] = entry;
    } else {
      Seed.labTests.add(entry);
    }
    _audit(id == null ? 'created' : 'updated', 'lab_test', resolvedId,
        detail: '${name.ar} · $price');
    notifyListeners();
    return resolvedId;
  }

  String upsertLabPackage({
    String? id,
    required Label name,
    required List<String> tests,
    required int price,
    int priceBefore = 0,
    Label? preparation,
    bool isActive = true,
  }) {
    final resolvedId = id ?? _newId('pkg');
    final entry = LabPackage(
      id: resolvedId,
      name: name,
      tests: tests,
      price: price,
      priceBefore: priceBefore,
      preparation: preparation,
      isActive: isActive,
    );
    final index = Seed.labPackages.indexWhere((p) => p.id == resolvedId);
    if (index >= 0) {
      Seed.labPackages[index] = entry;
    } else {
      Seed.labPackages.add(entry);
    }
    _audit(id == null ? 'created' : 'updated', 'lab_package', resolvedId,
        detail: '${name.ar} · $price');
    notifyListeners();
    return resolvedId;
  }

  // Price list ---------------------------------------------------------------

  /// Adds or edits one line of a department's price list.
  String upsertPriceItem({
    required String sectionId,
    String? id,
    required String name,
    required int price,
    String? note,
    bool isActive = true,
  }) {
    final si = Seed.priceSections.indexWhere((s) => s.id == sectionId);
    if (si < 0) throw ArgumentError('Unknown price section $sectionId');
    final section = Seed.priceSections[si];
    final items = [...section.items];
    final index = id == null ? -1 : items.indexWhere((i) => i.id == id);
    final resolvedId = index >= 0 ? id! : _newId('itm');
    final entry = PriceItem(
      id: resolvedId,
      name: Label(name),
      price: price,
      code: index >= 0 ? items[index].code : '',
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      isActive: isActive,
    );
    if (index >= 0) {
      items[index] = entry;
    } else {
      items.add(entry);
    }
    Seed.priceSections[si] = section.withItems(items);
    _audit(index >= 0 ? 'updated' : 'created', 'price_item', resolvedId,
        detail: '${section.title.ar} · $name · $price');
    notifyListeners();
    return resolvedId;
  }

  /// Replaces an operation's room prices. [prices] is [SurgeryTier] → one
  /// price (or null) per room.
  void updateSurgeryPackagePrices(
      String id, Map<String, List<int?>> prices) {
    final index = Seed.surgeryPackages.indexWhere((p) => p.id == id);
    if (index < 0) return;
    Seed.surgeryPackages[index] =
        Seed.surgeryPackages[index].withPrices(prices);
    _audit('updated', 'surgery_package', id,
        detail: Seed.surgeryPackages[index].name.ar);
    notifyListeners();
  }

  // Bookings, as reception sees them -------------------------------------------

  /// Every booking on the books — clinic and laboratory — newest visit first.
  List<BookingRow> allBookings() {
    final rows = <BookingRow>[
      for (final a in _appointments) BookingRow.clinic(a),
      for (final b in _labBookings) BookingRow.lab(b),
    ]..sort((x, y) => y.at.compareTo(x.at));
    return rows;
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

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

/// One line in reception's booking list: a clinic appointment or a lab visit.
class BookingRow {
  BookingRow.clinic(Appointment this.appointment)
      : lab = null,
        id = appointment.id,
        reference = appointment.reference,
        patientId = appointment.patientId,
        at = appointment.range.start,
        status = appointment.status,
        createdAt = appointment.createdAt;

  BookingRow.lab(LabBooking this.lab)
      : appointment = null,
        id = lab.id,
        reference = lab.reference,
        patientId = lab.patientId,
        at = lab.visitAt,
        status = lab.status,
        createdAt = lab.createdAt;

  final Appointment? appointment;
  final LabBooking? lab;
  final String id;
  final String reference;
  final String patientId;
  final DateTime at;
  final AppointmentStatus status;
  final DateTime? createdAt;

  bool get isLab => lab != null;
}

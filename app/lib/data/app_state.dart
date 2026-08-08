import 'package:flutter/material.dart';

import '../domain/models/booking.dart';
import '../domain/models/catalog.dart';
import '../domain/models/content.dart';
import '../domain/models/enums.dart';
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

  void signOut() {
    _session = const Session.guest();
    notifyListeners();
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
    notifyListeners();
    return request;
  }

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

  // ---------------------------------------------------------- visiting expert

  final Set<String> _campaignInterest = {};
  bool hasRegisteredInterest(String campaignId) =>
      _campaignInterest.contains(campaignId);

  void registerCampaignInterest(String campaignId) {
    _campaignInterest.add(campaignId);
    notifyListeners();
  }

  /// Only campaigns whose expert holds valid authorisation are visible to
  /// patients (PROMPT.md 6.15.4).
  List<VisitingCampaign> publishableCampaigns() {
    final now = DateTime.now();
    return Seed.campaigns.where((c) => c.isPublishableAt(now)).toList();
  }

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

import 'enums.dart';
import 'time_range.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.clinicId,
    required this.range,
    this.status = AppointmentStatus.confirmed,
    this.reference = '',
    this.fee = 0,
    this.depositPaid = 0,
    this.cancelReason,
    this.cancelNote,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String clinicId;
  final TimeRange range;

  /// When the patient made the booking.
  final DateTime? createdAt;
  final AppointmentStatus status;
  final String reference;
  final int fee;

  /// Money already taken to hold the slot. Zero is the normal case — the
  /// hospital's rule is that booking is never blocked by payment.
  final int depositPaid;
  final CancellationReason? cancelReason;
  final String? cancelNote;

  bool get blocksTime => status == AppointmentStatus.confirmed;

  int get balanceDue => (fee - depositPaid).clamp(0, fee);

  Appointment cancelledBecause(CancellationReason reason, {String? note}) =>
      Appointment(
        id: id,
        patientId: patientId,
        doctorId: doctorId,
        clinicId: clinicId,
        range: range,
        status: AppointmentStatus.cancelled,
        reference: reference,
        fee: fee,
        depositPaid: depositPaid,
        cancelReason: reason,
        cancelNote: note,
        createdAt: createdAt,
      );

  Appointment withStatus(AppointmentStatus value) => Appointment(
        id: id,
        patientId: patientId,
        doctorId: doctorId,
        clinicId: clinicId,
        range: range,
        status: value,
        reference: reference,
        fee: fee,
        depositPaid: depositPaid,
        cancelReason: cancelReason,
        cancelNote: cancelNote,
        createdAt: createdAt,
      );
}

/// A laboratory visit: individual tests, offer packages, or both.
///
/// The lab takes walk-ins, so the time is the patient's intended arrival —
/// it orders the queue rather than reserving a slot.
class LabBooking {
  const LabBooking({
    required this.id,
    required this.reference,
    required this.patientId,
    required this.visitAt,
    required this.testIds,
    required this.packageIds,
    required this.total,
    required this.createdAt,
    this.status = AppointmentStatus.confirmed,
    this.cancelReason,
  });

  final String id;
  final String reference;
  final String patientId;
  final DateTime visitAt;
  final List<String> testIds;
  final List<String> packageIds;

  /// Price at the moment of booking. Later price changes do not alter it.
  final int total;
  final DateTime createdAt;
  final AppointmentStatus status;
  final CancellationReason? cancelReason;

  bool get isActive => status == AppointmentStatus.confirmed;

  LabBooking copyWith({
    AppointmentStatus? status,
    CancellationReason? cancelReason,
  }) =>
      LabBooking(
        id: id,
        reference: reference,
        patientId: patientId,
        visitAt: visitAt,
        testIds: testIds,
        packageIds: packageIds,
        total: total,
        createdAt: createdAt,
        status: status ?? this.status,
        cancelReason: cancelReason ?? this.cancelReason,
      );
}

/// A scheduled operation.
///
/// [occupiesTheatre] is the range the theatre is actually unavailable for: the
/// procedure itself plus the turnover (cleaning and preparation) that follows
/// it. Scheduling against [range] alone is the classic way to produce a
/// schedule that cannot physically be delivered.
class SurgeryCase {
  const SurgeryCase({
    required this.id,
    required this.patientId,
    required this.patientDisplayName,
    required this.procedureId,
    required this.classificationId,
    required this.theatreId,
    required this.surgeonId,
    required this.range,
    required this.turnover,
    required this.origin,
    this.status = CaseStatus.scheduled,
    this.centreId,
    this.campaignId,
    this.equipment = const [],
    this.overrideReason,
  });

  final String id;
  final String patientId;
  final String patientDisplayName;
  final String procedureId;
  final String classificationId;
  final String theatreId;
  final String surgeonId;
  final TimeRange range;
  final Duration turnover;
  final BookingOrigin origin;
  final CaseStatus status;
  final String? centreId;
  final String? campaignId;
  final List<String> equipment;
  final String? overrideReason;

  TimeRange get occupiesTheatre => range.extendedBy(turnover);

  bool get blocksTime =>
      status != CaseStatus.cancelled && status != CaseStatus.postponed;
}

/// Maintenance or administrative block on a theatre.
class TheatreBlock {
  const TheatreBlock({
    required this.theatreId,
    required this.range,
    required this.reason,
  });

  final String theatreId;
  final TimeRange range;
  final String reason;
}

/// A patient-initiated surgery request. Never a confirmed booking
/// (PROMPT.md section 6.13.6).
class SurgeryRequest {
  const SurgeryRequest({
    required this.id,
    required this.reference,
    required this.patientId,
    required this.procedureId,
    required this.classificationId,
    required this.submittedAt,
    required this.estimatePriceSnapshot,
    this.origin = RequestOrigin.patient,
    this.requestedByDoctorId,
    this.clinicalNote,
    this.scheduledTheatreId,
    this.scheduledStart,
    this.confirmedPrice,
    this.preferredSurgeonId,
    this.preferredFrom,
    this.preferredTo,
    this.status = SurgeryRequestStatus.submitted,
    this.decidedAt,
    this.decisionReason,
    this.escalatedAt,
    this.scheduledCaseId,
  });

  final String id;
  final String reference;
  final String patientId;
  final String procedureId;
  final String classificationId;
  final DateTime submittedAt;

  /// The estimate exactly as the patient saw it, immutable thereafter
  /// (PROMPT.md section 6.13.7).
  final String estimatePriceSnapshot;

  /// Whether the patient asked for the operation or the surgeon asked for a
  /// slot. The administration reviews the first clinically and the second
  /// operationally, so the inbox treats them differently.
  final RequestOrigin origin;
  final String? requestedByDoctorId;

  /// The surgeon's note to the scheduler — urgency, equipment, constraints.
  final String? clinicalNote;

  /// Filled in by the administration when the request is scheduled: the
  /// theatre, the time and the price the hospital has committed to.
  final String? scheduledTheatreId;
  final DateTime? scheduledStart;
  final int? confirmedPrice;

  final String? preferredSurgeonId;
  final DateTime? preferredFrom;
  final DateTime? preferredTo;
  final SurgeryRequestStatus status;
  final DateTime? decidedAt;
  final String? decisionReason;
  final DateTime? escalatedAt;
  final String? scheduledCaseId;

  bool get isFromDoctor => origin == RequestOrigin.doctor;

  /// Approval service-level target (PROMPT.md section 6.13.6): first
  /// escalation after four working hours.
  static const Duration escalationWindow = Duration(hours: 4);

  DateTime get escalationDueAt => submittedAt.add(escalationWindow);

  bool isAwaitingDecisionAt(DateTime now) =>
      status == SurgeryRequestStatus.submitted ||
      status == SurgeryRequestStatus.underReview;

  bool isEscalationOverdueAt(DateTime now) =>
      isAwaitingDecisionAt(now) && now.isAfter(escalationDueAt);

  SurgeryRequest copyWith({
    SurgeryRequestStatus? status,
    DateTime? decidedAt,
    String? decisionReason,
    DateTime? escalatedAt,
    String? scheduledCaseId,
    String? scheduledTheatreId,
    DateTime? scheduledStart,
    int? confirmedPrice,
  }) {
    return SurgeryRequest(
      id: id,
      reference: reference,
      patientId: patientId,
      procedureId: procedureId,
      classificationId: classificationId,
      submittedAt: submittedAt,
      estimatePriceSnapshot: estimatePriceSnapshot,
      origin: origin,
      requestedByDoctorId: requestedByDoctorId,
      clinicalNote: clinicalNote,
      scheduledTheatreId: scheduledTheatreId ?? this.scheduledTheatreId,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      confirmedPrice: confirmedPrice ?? this.confirmedPrice,
      preferredSurgeonId: preferredSurgeonId,
      preferredFrom: preferredFrom,
      preferredTo: preferredTo,
      status: status ?? this.status,
      decidedAt: decidedAt ?? this.decidedAt,
      decisionReason: decisionReason ?? this.decisionReason,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      scheduledCaseId: scheduledCaseId ?? this.scheduledCaseId,
    );
  }
}

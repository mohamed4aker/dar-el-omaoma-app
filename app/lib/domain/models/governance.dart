import 'enums.dart';

/// Hospital-wide policy, owned by the administrator.
///
/// These are the switches that decide how the hospital runs, rather than what
/// it offers. They live in data for the same reason classifications do: the
/// hospital's answer changes, and changing it must not need a release.
class HospitalPolicy {
  const HospitalPolicy({
    this.doctorsBookTheatreDirectly = true,
    this.approvalWindow = const Duration(hours: 4),
    this.clinicCancellationCutoff = const Duration(hours: 4),
    this.notifyPatientsOnScheduleChange = true,
    this.defaultPaymentPolicy = PaymentPolicy.payAtReception,
  });

  /// The client asked for both behaviours at different times, and both are
  /// legitimate: a hospital that trusts its surgeons lets them take a slot,
  /// and one with scarce theatre time routes every case through scheduling.
  ///
  /// When true, a doctor books a theatre outright (subject to the conflict
  /// rules). When false, the doctor raises a request and the administration
  /// allocates the theatre, time and price.
  final bool doctorsBookTheatreDirectly;

  /// How long a surgery request may sit before it escalates.
  final Duration approvalWindow;

  /// How close to an appointment a patient may still cancel it.
  final Duration clinicCancellationCutoff;

  /// Whether changing a clinic's or a doctor's schedule notifies the patients
  /// whose bookings it invalidates. Turning this off is a bad idea and the
  /// settings screen says so.
  final bool notifyPatientsOnScheduleChange;

  final PaymentPolicy defaultPaymentPolicy;

  HospitalPolicy copyWith({
    bool? doctorsBookTheatreDirectly,
    Duration? approvalWindow,
    Duration? clinicCancellationCutoff,
    bool? notifyPatientsOnScheduleChange,
    PaymentPolicy? defaultPaymentPolicy,
  }) =>
      HospitalPolicy(
        doctorsBookTheatreDirectly:
            doctorsBookTheatreDirectly ?? this.doctorsBookTheatreDirectly,
        approvalWindow: approvalWindow ?? this.approvalWindow,
        clinicCancellationCutoff:
            clinicCancellationCutoff ?? this.clinicCancellationCutoff,
        notifyPatientsOnScheduleChange: notifyPatientsOnScheduleChange ??
            this.notifyPatientsOnScheduleChange,
        defaultPaymentPolicy:
            defaultPaymentPolicy ?? this.defaultPaymentPolicy,
      );
}

/// A staff account.
///
/// Roles are assigned here rather than being a property of a person, so the
/// same human can hold several (a surgeon who also approves requests).
class StaffUser {
  const StaffUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.roles,
    this.doctorId,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String phone;
  final Set<UserRole> roles;

  /// Set when this account is also a practising doctor, linking the login to
  /// the schedule and the theatre list.
  final String? doctorId;
  final bool isActive;

  /// Permissions are the union across roles, and the most permissive wins
  /// (PROMPT.md §3.3, rule 5).
  bool can(bool Function(UserRole) permission) =>
      isActive && roles.any(permission);

  StaffUser copyWith({
    String? name,
    String? phone,
    Set<UserRole>? roles,
    String? doctorId,
    bool? isActive,
  }) =>
      StaffUser(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        roles: roles ?? this.roles,
        doctorId: doctorId ?? this.doctorId,
        isActive: isActive ?? this.isActive,
      );
}

/// One line in the audit log.
///
/// Every catalogue edit, policy change, permission grant and clinical
/// decision writes one. It is append-only: entries are never edited or
/// removed (PROMPT.md §11.1, control 6).
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.actor,
    required this.action,
    required this.entity,
    required this.at,
    this.entityId,
    this.detail,
  });

  final String id;
  final String actor;

  /// A short verb: created, updated, deactivated, approved, rejected,
  /// scheduled, cancelled, granted.
  final String action;

  /// What was acted on: classification, procedure, clinic, doctor, theatre,
  /// policy, role, appointment, surgery_request.
  final String entity;
  final String? entityId;
  final DateTime at;
  final String? detail;
}

/// Roles, per PROMPT.md section 3.2.
enum UserRole { guest, patient, doctor, orScheduler, surgeryApprover, admin }

extension UserRoleX on UserRole {
  bool get canBookTheatreDirectly => switch (this) {
        UserRole.doctor || UserRole.orScheduler || UserRole.admin => true,
        _ => false,
      };

  bool get canOverrideConflict => switch (this) {
        UserRole.orScheduler || UserRole.surgeryApprover || UserRole.admin =>
          true,
        _ => false,
      };

  bool get canApproveSurgery => switch (this) {
        UserRole.surgeryApprover || UserRole.admin => true,
        _ => false,
      };

  /// Allocating a theatre, a time and a price to an approved request.
  bool get canScheduleSurgery => switch (this) {
        UserRole.orScheduler || UserRole.surgeryApprover || UserRole.admin =>
          true,
        _ => false,
      };

  /// Editing catalogues, policies, users and roles.
  bool get canManageCatalogue => this == UserRole.admin;

  bool get canManageUsers => this == UserRole.admin;

  bool get canViewAuditLog => this == UserRole.admin;
}

/// Booking origin — used to distinguish doctor-direct bookings (no approval)
/// from patient requests (approval required). PROMPT.md 6.13.5 / 6.13.6.
enum BookingOrigin { doctorDirect, patientRequest, doctorRequest, staff }

/// Who raised a surgery request.
///
/// A patient request is a clinical ask ("can I have this operation?"). A
/// doctor request is a scheduling ask ("I need a theatre for this case") —
/// the clinical decision is already the doctor's, so the administration is
/// allocating a slot, a theatre and a price rather than judging the case.
enum RequestOrigin { patient, doctor }

/// How a booking is paid for.
///
/// Booking must never be blocked by payment (the hospital's rule): the
/// default is to settle at reception, and anything else is opt-in.
enum PaymentPolicy {
  /// Book now, pay at the reception desk. No money changes hands in the app.
  payAtReception,

  /// Pay at reception, or optionally pay in the app to save time.
  optionalOnline,

  /// A deposit is required to hold the slot — used where a doctor has a
  /// limited number of cases and no-shows are costly.
  depositRequired,
}

extension PaymentPolicyX on PaymentPolicy {
  bool get requiresDeposit => this == PaymentPolicy.depositRequired;
  bool get allowsOnlinePayment => this != PaymentPolicy.payAtReception;
}

/// Why a booking was cancelled. Coded, never free text alone, so the
/// cancellation report is answerable (PROMPT.md §6.13.8).
enum CancellationReason {
  scheduleChanged,
  doctorUnavailable,
  theatreUnavailable,
  patientRequested,
  clinicClosed,
  other,
}

enum SurgeryRequestStatus {
  submitted,
  underReview,
  approved,
  scheduled,
  rejected,
  moreInfoRequired,
  cancelled,
}

enum CaseStatus {
  scheduled,
  preOpReady,
  inTheatre,
  inRecovery,
  completed,
  postponed,
  cancelled,
}

enum SlotState { free, booked, provisional, turnover, blocked }

enum TheatreType { general, obstetric, minorProcedures, endoscopy }

enum ResultStatus { ordered, sampleCollected, inProgress, ready, withheld }

enum RadiologyModality { ultrasound, xray, ct }

enum VisitingStage {
  interestRegistered,
  screeningBooked,
  screened,
  shortlisted,
  surgeryScheduled,
  waitlisted,
  notEligible,
  completed,
}

enum ComplaintCategory {
  appointment,
  clinicalCare,
  nursing,
  cleanliness,
  billing,
  staffConduct,
  facilities,
  other,
}

enum AppointmentStatus { confirmed, cancelled, completed, noShow }

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
}

/// Booking origin — used to distinguish doctor-direct bookings (no approval)
/// from patient requests (approval required). PROMPT.md 6.13.5 / 6.13.6.
enum BookingOrigin { doctorDirect, patientRequest, staff }

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

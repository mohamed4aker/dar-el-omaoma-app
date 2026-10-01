import 'enums.dart';

class Patient {
  const Patient({
    required this.id,
    required this.mrn,
    required this.fullName,
    required this.phoneE164,
    required this.dateOfBirth,
    required this.isMale,
    this.email,
    this.companyName,
    this.bloodGroup,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.pregnancy,
    this.nationalId,
    this.governorate,
    this.createdAt,
    this.googleEmail,
  });

  final String id;
  final String mrn;
  final String fullName;
  final String phoneE164;
  final DateTime dateOfBirth;
  final bool isMale;

  /// The 14-digit Egyptian National ID; the patient's identity in this app.
  final String? nationalId;

  /// Derived from the National ID at registration.
  final String? governorate;
  final DateTime? createdAt;

  /// Set when the account was created with Google sign-in.
  final String? googleEmail;

  /// Whole years, as at [now].
  int ageAt(DateTime now) {
    var years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  /// Local display form of the stored E.164 number: +201012345678 → 01012345678.
  String get phoneLocal =>
      phoneE164.startsWith('+20') ? '0${phoneE164.substring(3)}' : phoneE164;
  final String? email;
  final String? companyName;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final Pregnancy? pregnancy;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
}

/// Maternity view of the medical file (PROMPT.md section 6.6).
class Pregnancy {
  const Pregnancy({required this.lastMenstrualPeriod});

  final DateTime lastMenstrualPeriod;

  /// Naegele's rule: LMP + 280 days.
  DateTime get expectedDeliveryDate =>
      lastMenstrualPeriod.add(const Duration(days: 280));

  Duration gestationAt(DateTime now) => now.difference(lastMenstrualPeriod);

  int gestationalWeeksAt(DateTime now) => gestationAt(now).inDays ~/ 7;

  int gestationalDaysRemainderAt(DateTime now) => gestationAt(now).inDays % 7;
}

class Session {
  const Session({
    required this.role,
    this.patient,
    this.doctorId,
    this.staffId,
    this.staffName,
  });

  const Session.guest()
      : role = UserRole.guest,
        patient = null,
        doctorId = null,
        staffId = null,
        staffName = null;

  final UserRole role;
  final Patient? patient;
  final String? doctorId;

  /// Set when a member of staff is signed in.
  final String? staffId;
  final String? staffName;

  bool get isStaff => staffId != null;

  bool get isGuest => role == UserRole.guest;
  bool get isDoctor => role == UserRole.doctor;
  bool get isSignedIn => role != UserRole.guest;
}

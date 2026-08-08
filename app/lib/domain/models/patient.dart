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
  });

  final String id;
  final String mrn;
  final String fullName;
  final String phoneE164;
  final DateTime dateOfBirth;
  final bool isMale;
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
  const Session({required this.role, this.patient, this.doctorId});

  const Session.guest() : role = UserRole.guest, patient = null, doctorId = null;

  final UserRole role;
  final Patient? patient;
  final String? doctorId;

  bool get isGuest => role == UserRole.guest;
  bool get isDoctor => role == UserRole.doctor;
  bool get isSignedIn => role != UserRole.guest;
}

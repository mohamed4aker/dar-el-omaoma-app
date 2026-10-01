import 'dart:convert';
import 'dart:io';

import 'package:dar_el_omouma/data/app_state.dart';
import 'package:dar_el_omouma/data/seed_data.dart';
import 'package:dar_el_omouma/data/storage.dart';
import 'package:dar_el_omouma/domain/models/catalog.dart';
import 'package:dar_el_omouma/domain/models/enums.dart';
import 'package:dar_el_omouma/domain/models/operations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app as the hospital receives it: its own catalogue, saved on the
/// device, with real accounts and bookings.
void main() {
  late Map<String, dynamic> bundled;

  setUpAll(() {
    bundled = Map<String, dynamic>.from(
        jsonDecode(File('assets/seed/hospital_data.json').readAsStringSync())
            as Map);
  });

  // Valid National IDs: born 1995-04-12 in Cairo (01), female (even 13th
  // digit); and born 1988-11-02 in Alexandria (02), male.
  const womanId = '29504120100248';
  const manId = '28811020200157';

  Future<AppState> fresh([MemoryStorage? storage]) async {
    final state = AppState(storage: storage ?? MemoryStorage());
    await state.load(bundled: bundled);
    return state;
  }

  DateTime nextWeekday(int weekday) {
    var d = Seed.today.add(const Duration(days: 1));
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  group("the hospital's catalogue", () {
    test('ships its clinics, doctors, lab tests and offers', () async {
      await fresh();
      expect(Seed.clinics, hasLength(43));
      expect(Seed.doctors, hasLength(155));
      expect(Seed.labTests.length, greaterThan(400));
      expect(Seed.labPackages, hasLength(14));
      expect(Seed.theatres, isEmpty, reason: 'no invented theatres');
      expect(Seed.procedures, isEmpty, reason: 'no invented procedures');
    });

    test('every clinic lists doctors that exist', () async {
      await fresh();
      final ids = {for (final d in Seed.doctors) d.id};
      for (final clinic in Seed.clinics) {
        expect(clinic.doctorIds, isNotEmpty, reason: clinic.name.ar);
        for (final id in clinic.doctorIds) {
          expect(ids, contains(id), reason: '${clinic.name.ar} → $id');
        }
      }
    });

    test('every doctor with working hours can be booked on those days',
        () async {
      final state = await fresh();
      var checked = 0;
      for (final doctor in Seed.doctors.where((d) => d.isBookableOnline)) {
        final clinic = Seed.clinicsOf(doctor.id).first;
        final shift = doctor.shifts.first;
        final slots = state.clinicSlots(clinic, nextWeekday(shift.weekday),
            doctorId: doctor.id);
        expect(slots, isNotEmpty, reason: '${doctor.name.ar} in ${clinic.name.ar}');
        checked++;
      }
      expect(checked, greaterThan(140));
    });

    test('a doctor who only sees their own patients is not bookable online',
        () async {
      await fresh();
      final ownOnly = Seed.doctors
          .where((d) => (d.scheduleNote ?? '').contains('يتم'))
          .toList();
      expect(ownOnly, isNotEmpty);
      expect(ownOnly.every((d) => !d.isBookableOnline), isTrue);
    });

    test('the timetable keeps the hospital wording', () async {
      await fresh();
      final waleed = Seed.doctors.firstWhere((d) => d.name.ar.contains('وليد علام'));
      expect(waleed.scheduleNote, contains('12 ظهراً'));
      expect(waleed.shiftOn(DateTime.saturday)!.startsAt, 12 * 60);
      expect(waleed.worksOn(DateTime.tuesday), isFalse);
    });

    test('a range written right to left is read in the right order', () async {
      await fresh();
      // "الاثنين 8:7 مساءً" means 7 to 8 pm.
      final safaa = Seed.doctors.firstWhere((d) => d.name.ar.contains('صفاء بشير'));
      final monday = safaa.shiftOn(DateTime.monday)!;
      expect(monday.startsAt, 19 * 60);
      expect(monday.endsAt, 20 * 60);
    });
  });

  group('patients register with their National ID', () {
    test('date of birth and sex come from the ID', () async {
      final state = await fresh();
      final result = state.registerPatient(
        fullName: 'سارة محمود عبد الرحمن حسين',
        nationalId: womanId,
        phone: '01012345678',
      );
      expect(result, RegistrationResult.created);
      final p = state.session.patient!;
      expect(p.dateOfBirth, DateTime(1995, 4, 12));
      expect(p.isMale, isFalse);
      expect(p.nationalId, womanId);
      expect(p.phoneLocal, '01012345678');
    });

    test('a National ID is registered once', () async {
      final state = await fresh();
      state.registerPatient(
          fullName: 'سارة محمود عبد الرحمن حسين',
          nationalId: womanId,
          phone: '01012345678');
      expect(
        state.registerPatient(
            fullName: 'أي اسم رباعي هنا',
            nationalId: womanId,
            phone: '01099999999'),
        RegistrationResult.alreadyRegistered,
      );
    });

    test('signing back in needs the ID and the same mobile', () async {
      final state = await fresh();
      state.registerPatient(
          fullName: 'سارة محمود عبد الرحمن حسين',
          nationalId: womanId,
          phone: '01012345678');
      state.signOut();
      expect(
          state.signInPatient(nationalId: womanId, phone: '01099999999'), isFalse);
      expect(state.session.isGuest, isTrue);
      expect(
          state.signInPatient(nationalId: womanId, phone: '01012345678'), isTrue);
      expect(state.session.patient!.nationalId, womanId);
    });

    test('reception can register a caller without switching account', () async {
      final state = await fresh();
      expect(state.signInStaff(username: 'admin', password: 'admin123'), isTrue);
      state.registerPatient(
          fullName: 'محمد إبراهيم سيد علي',
          nationalId: manId,
          phone: '01112345678',
          signIn: false);
      expect(state.session.isStaff, isTrue);
      expect(state.lastRegistered!.isMale, isTrue);
    });
  });

  group('staff accounts', () {
    test('the hospital receives one admin account, flagged until changed',
        () async {
      final state = await fresh();
      expect(state.signInStaff(username: 'admin', password: 'wrong'), isFalse);
      expect(state.signInStaff(username: 'ADMIN', password: 'admin123'), isTrue);
      expect(state.session.role, UserRole.admin);
      expect(state.adminUsesDefaultPassword, isTrue);
      expect(state.changeOwnPassword(current: 'admin123', next: 'n3w-pass'),
          isTrue);
      expect(state.adminUsesDefaultPassword, isFalse);
      state.signOut();
      expect(state.signInStaff(username: 'admin', password: 'admin123'), isFalse);
      expect(state.signInStaff(username: 'admin', password: 'n3w-pass'), isTrue);
    });

    test('a disabled account cannot sign in, and passwords are not stored',
        () async {
      final storage = MemoryStorage();
      final state = await fresh(storage);
      final id = state.upsertStaff(
        name: 'استقبال 1',
        phone: '',
        roles: {UserRole.reception},
        username: 'desk1',
        password: 'desk-pass',
      );
      expect(state.signInStaff(username: 'desk1', password: 'desk-pass'), isTrue);
      expect(state.session.role, UserRole.reception);
      state.setStaffActive(id, false);
      state.signOut();
      expect(state.signInStaff(username: 'desk1', password: 'desk-pass'), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(storage.document, isNot(contains('desk-pass')));
    });
  });

  group('clinic booking', () {
    late AppState state;
    late Doctor doctor;
    late Clinic clinic;
    late DateTime slot;

    setUp(() async {
      state = await fresh();
      doctor = Seed.doctors.firstWhere((d) => d.isBookableOnline);
      clinic = Seed.clinicsOf(doctor.id).first;
      slot = state
          .clinicSlots(clinic, nextWeekday(doctor.shifts.first.weekday),
              doctorId: doctor.id)
          .first;
      state.registerPatient(
          fullName: 'سارة محمود عبد الرحمن حسين',
          nationalId: womanId,
          phone: '01012345678');
    });

    test('books the chosen doctor, not the first doctor of the clinic', () {
      final outcome = state.bookClinicAppointment(
        patientId: state.session.patient!.id,
        clinicId: clinic.id,
        doctorId: doctor.id,
        start: slot,
      );
      expect(outcome, isA<AppointmentBooked>());
      expect((outcome as AppointmentBooked).appointment.doctorId, doctor.id);
    });

    test('a slot taken in the meantime is refused at write time', () {
      final first = state.session.patient!.id;
      state.bookClinicAppointment(
          patientId: first, clinicId: clinic.id, doctorId: doctor.id, start: slot);
      state.registerPatient(
          fullName: 'محمد إبراهيم سيد علي',
          nationalId: manId,
          phone: '01112345678');
      final second = state.bookClinicAppointment(
        patientId: state.session.patient!.id,
        clinicId: clinic.id,
        doctorId: doctor.id,
        start: slot,
      );
      expect(second, isA<AppointmentSlotGone>());
    });

    test('one patient, one booking per doctor per day', () {
      final id = state.session.patient!.id;
      state.bookClinicAppointment(
          patientId: id, clinicId: clinic.id, doctorId: doctor.id, start: slot);
      final later = state
          .clinicSlots(clinic, slot, doctorId: doctor.id)
          .first;
      expect(
        state.bookClinicAppointment(
            patientId: id, clinicId: clinic.id, doctorId: doctor.id, start: later),
        isA<AppointmentDuplicate>(),
      );
    });

    test('reception is told, and sees the booking with the patient', () {
      state.bookClinicAppointment(
        patientId: state.session.patient!.id,
        clinicId: clinic.id,
        doctorId: doctor.id,
        start: slot,
      );
      expect(
        state.notifications.any((n) =>
            n.templateCode == 'appointment_booked' &&
            n.audience == NotifyAudience.approvers),
        isTrue,
      );
      final row = state.allBookings().single;
      expect(state.patientById(row.patientId)!.nationalId, womanId);
    });

    test("a patient sees only their own notifications", () {
      final sara = state.session.patient!;
      state.bookClinicAppointment(
          patientId: sara.id, clinicId: clinic.id, doctorId: doctor.id, start: slot);
      state.registerPatient(
          fullName: 'محمد إبراهيم سيد علي',
          nationalId: manId,
          phone: '01112345678');
      expect(state.myNotifications, isEmpty,
          reason: "Sara's confirmation must not show on Mohamed's account");
      state.signInPatient(nationalId: womanId, phone: '01012345678');
      expect(state.myNotifications, isNotEmpty);
      expect(state.myNotifications.every((n) => n.recipientId == sara.id), isTrue);
    });
  });

  group('laboratory booking', () {
    test('the total is frozen at the price on the day of booking', () async {
      final state = await fresh();
      state.registerPatient(
          fullName: 'سارة محمود عبد الرحمن حسين',
          nationalId: womanId,
          phone: '01012345678');
      final pkg = Seed.labPackages.first;
      final test = Seed.labTests.first;
      final booking = state.bookLab(
        patientId: state.session.patient!.id,
        visitAt: Seed.at(1, 9),
        packageIds: [pkg.id],
        testIds: [test.id],
      );
      expect(booking.total, pkg.price + test.price);

      state.signInAsAdmin();
      state.upsertLabTest(
          id: test.id, name: test.name, category: test.category, price: test.price + 100);
      expect(state.labBookings.single.total, pkg.price + test.price);
      expect(state.allBookings().single.isLab, isTrue);
    });
  });

  group('everything is saved on the device', () {
    test('patients, bookings and the session survive a restart', () async {
      final storage = MemoryStorage();
      final first = await fresh(storage);
      first.registerPatient(
          fullName: 'سارة محمود عبد الرحمن حسين',
          nationalId: womanId,
          phone: '01012345678');
      final doctor = Seed.doctors.firstWhere((d) => d.isBookableOnline);
      final clinic = Seed.clinicsOf(doctor.id).first;
      final slot = first
          .clinicSlots(clinic, nextWeekday(doctor.shifts.first.weekday),
              doctorId: doctor.id)
          .first;
      first.bookClinicAppointment(
          patientId: first.session.patient!.id,
          clinicId: clinic.id,
          doctorId: doctor.id,
          start: slot);
      await Future<void>.delayed(Duration.zero);

      final second = await fresh(storage);
      expect(second.patients, hasLength(1));
      expect(second.session.patient?.nationalId, womanId,
          reason: 'still signed in after reopening the app');
      expect(second.appointments.single.range.start, slot);
      expect(second.clinicSlots(clinic, slot, doctorId: doctor.id),
          isNot(contains(slot)),
          reason: 'the booked slot stays taken');
    });

    test("the administration's edits survive, and an app update keeps them",
        () async {
      final storage = MemoryStorage();
      final first = await fresh(storage);
      first.signInStaff(username: 'admin', password: 'admin123');
      final test = Seed.labTests.first;
      first.upsertLabTest(
          id: test.id, name: test.name, category: test.category, price: 9999);
      await Future<void>.delayed(Duration.zero);

      // A newer catalogue arrives with an app update.
      final updated = {...bundled, 'dataVersion': 99};
      final second = AppState(storage: storage);
      await second.load(bundled: updated);
      expect(Seed.labTestById(test.id)!.price, 9999,
          reason: 'edited catalogues are never overwritten by an update');
    });

    test('an untouched catalogue is refreshed by an app update', () async {
      final storage = MemoryStorage();
      await fresh(storage);
      final updated = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(bundled)) as Map)
        ..['dataVersion'] = 99;
      ((updated['labTests'] as List).first as Map)['price'] = 4321;
      final second = AppState(storage: storage);
      await second.load(bundled: updated);
      expect(Seed.labTests.first.price, 4321);
    });

    test('a corrupt save starts again from the bundled catalogue', () async {
      final state = await fresh(MemoryStorage('{not json'));
      expect(state.isLoaded, isTrue);
      expect(Seed.clinics, hasLength(43));
    });
  });

  group('the doctor form keeps clinics in step', () {
    test("a new working day opens the doctor's clinics that day", () async {
      final state = await fresh();
      state.signInAsAdmin();
      final doctor = Seed.doctors.firstWhere((d) => d.isBookableOnline);
      final clinic = Seed.clinicsOf(doctor.id).first;
      final missing = [1, 2, 3, 4, 5, 6, 7]
          .firstWhere((d) => !clinic.workingDays.contains(d));
      state.upsertDoctor(
        id: doctor.id,
        name: doctor.name,
        title: doctor.title,
        specialty: doctor.specialty,
        seniority: doctor.seniority,
        shifts: [
          ...doctor.shifts,
          DoctorShift(weekday: missing, startsAt: 600, endsAt: 720),
        ],
      );
      expect(Seed.clinicById(clinic.id)!.workingDays, contains(missing));
      expect(
          state.clinicSlots(Seed.clinicById(clinic.id)!, nextWeekday(missing),
              doctorId: doctor.id),
          isNotEmpty);
    });
  });
}

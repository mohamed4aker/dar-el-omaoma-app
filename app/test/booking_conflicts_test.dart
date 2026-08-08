import 'package:dar_el_omouma/domain/models/booking.dart';
import 'package:dar_el_omouma/domain/models/catalog.dart';
import 'package:dar_el_omouma/domain/models/enums.dart';
import 'package:dar_el_omouma/domain/models/time_range.dart';
import 'package:dar_el_omouma/domain/scheduling/booking_conflicts.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

/// Theatre booking rules (PROMPT.md 6.13.5).
void main() {
  final day = DateTime(2026, 9, 1);
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  const theatre = OperatingTheatre(
    id: 'or-1',
    code: 'OR-1',
    name: Label('غرفة 1', 'Theatre 1'),
    type: TheatreType.general,
    opensAt: 8 * 60,
    closesAt: 20 * 60,
  );

  const minorTheatre = OperatingTheatre(
    id: 'or-4',
    code: 'OR-4',
    name: Label('صغرى', 'Minor'),
    type: TheatreType.minorProcedures,
    opensAt: 9 * 60,
    closesAt: 17 * 60,
  );

  final major = OperationClassification(
    id: 'cls-major',
    code: 'major',
    name: const Label('كبرى', 'Major'),
    sortOrder: 3,
    colour: const Color(0xFFD97706),
    defaultDuration: const Duration(minutes: 120),
    defaultTurnover: const Duration(minutes: 45),
    priceMin: 30000,
    priceMax: 80000,
    requiredSeniority: 3,
    defaultAnaesthesia: const Label('كلي', 'General'),
    defaultBloodUnits: 2,
  );

  const procedure = Procedure(
    id: 'proc-a',
    code: 'A',
    name: Label('عملية أ', 'Procedure A'),
    classificationId: 'cls-major',
    typicalDuration: Duration(minutes: 120),
    requiredTheatreType: TheatreType.general,
    price: 45000,
    requiredEquipment: ['scope'],
  );

  const senior = Doctor(
    id: 'doc-1',
    name: Label('د. أ', 'Dr A'),
    title: Label('استشاري', 'Consultant'),
    specialty: Label('عظام', 'Ortho'),
    seniority: 4,
  );

  const junior = Doctor(
    id: 'doc-2',
    name: Label('د. ب', 'Dr B'),
    title: Label('أخصائي', 'Specialist'),
    specialty: Label('عظام', 'Ortho'),
    seniority: 1,
  );

  const scheduler = TheatreScheduler();

  BookingDraft draft({
    DateTime? start,
    String theatreId = 'or-1',
    String surgeonId = 'doc-1',
    String patientId = 'pat-1',
  }) =>
      BookingDraft(
        theatreId: theatreId,
        surgeonId: surgeonId,
        patientId: patientId,
        procedure: procedure,
        classification: major,
        start: start ?? at(9),
      );

  SurgeryCase existing({
    String id = 'case-1',
    String theatreId = 'or-1',
    String surgeonId = 'doc-9',
    String patientId = 'pat-9',
    required DateTime start,
    required DateTime end,
    Duration turnover = const Duration(minutes: 45),
    List<String> equipment = const [],
    CaseStatus status = CaseStatus.scheduled,
  }) =>
      SurgeryCase(
        id: id,
        patientId: patientId,
        patientDisplayName: 'X',
        procedureId: 'proc-a',
        classificationId: 'cls-major',
        theatreId: theatreId,
        surgeonId: surgeonId,
        range: TimeRange(start, end),
        turnover: turnover,
        origin: BookingOrigin.doctorDirect,
        equipment: equipment,
        status: status,
      );

  BookingCheck run({
    BookingDraft? d,
    OperatingTheatre? t,
    Doctor? surgeon,
    List<SurgeryCase> cases = const [],
    List<Appointment> appointments = const [],
    List<TheatreBlock> blocks = const [],
  }) =>
      scheduler.check(
        draft: d ?? draft(),
        theatre: t ?? theatre,
        surgeon: surgeon ?? senior,
        cases: cases,
        appointments: appointments,
        blocks: blocks,
      );

  group('TimeRange', () {
    test('is half-open, so back-to-back ranges do not overlap', () {
      final first = TimeRange(at(9), at(10));
      final second = TimeRange(at(10), at(11));
      expect(first.overlaps(second), isFalse);
      expect(second.overlaps(first), isFalse);
    });

    test('detects partial and full containment', () {
      final base = TimeRange(at(9), at(12));
      expect(base.overlaps(TimeRange(at(11), at(13))), isTrue);
      expect(base.overlaps(TimeRange(at(10), at(11))), isTrue);
      expect(base.overlaps(TimeRange(at(8), at(13))), isTrue);
    });

    test('rejects a non-positive duration', () {
      expect(() => TimeRange(at(10), at(10)), throwsArgumentError);
      expect(() => TimeRange(at(11), at(10)), throwsArgumentError);
    });
  });

  group('hard conflicts', () {
    test('an empty schedule permits the booking', () {
      final check = run();
      expect(check.isPermitted, isTrue);
      expect(check.conflicts, isEmpty);
    });

    test('a booked theatre blocks the slot', () {
      final check = run(
        cases: [existing(start: at(8, 30), end: at(10))],
      );
      expect(check.isPermitted, isFalse);
      expect(check.hasConflict(ConflictType.theatreBusy), isTrue);
    });

    test('turnover time is part of theatre occupancy', () {
      // Previous case ends at 09:00 but holds the theatre until 09:45.
      // A booking at 09:00 must be refused.
      final check = run(
        d: draft(start: at(9)),
        cases: [
          existing(
            start: at(7),
            end: at(9),
            turnover: const Duration(minutes: 45),
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.theatreBusy), isTrue,
          reason: 'the theatre is in turnover until 09:45');
    });

    test('a booking after turnover ends is permitted', () {
      final check = run(
        d: draft(start: at(9, 45)),
        cases: [
          existing(
            start: at(7),
            end: at(9),
            turnover: const Duration(minutes: 45),
          ),
        ],
      );
      expect(check.isPermitted, isTrue);
    });

    test('another theatre is unaffected', () {
      final check = run(
        cases: [existing(theatreId: 'or-2', start: at(8, 30), end: at(11))],
      );
      expect(check.isPermitted, isTrue);
    });

    test('the surgeon cannot be in two theatres at once', () {
      final check = run(
        cases: [
          existing(
            theatreId: 'or-2',
            surgeonId: 'doc-1',
            start: at(9, 30),
            end: at(11),
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.surgeonBusy), isTrue);
    });

    test('the surgeon is free during another case turnover', () {
      final check = run(
        d: draft(start: at(11)),
        cases: [
          existing(
            theatreId: 'or-2',
            surgeonId: 'doc-1',
            start: at(9),
            end: at(11),
            turnover: const Duration(minutes: 45),
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.surgeonBusy), isFalse);
    });

    test("a surgeon's clinic session blocks theatre time", () {
      final check = run(
        appointments: [
          Appointment(
            id: 'appt-1',
            patientId: 'pat-77',
            doctorId: 'doc-1',
            clinicId: 'clinic-1',
            range: TimeRange(at(9, 30), at(12)),
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.surgeonBusy), isTrue);
    });

    test('a cancelled clinic appointment does not block', () {
      final check = run(
        appointments: [
          Appointment(
            id: 'appt-1',
            patientId: 'pat-77',
            doctorId: 'doc-1',
            clinicId: 'clinic-1',
            range: TimeRange(at(9, 30), at(12)),
            status: AppointmentStatus.cancelled,
          ),
        ],
      );
      expect(check.isPermitted, isTrue);
    });

    test('the patient cannot be booked twice', () {
      final check = run(
        cases: [
          existing(
            theatreId: 'or-2',
            patientId: 'pat-1',
            start: at(9, 30),
            end: at(11),
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.patientBusy), isTrue);
    });

    test('committed equipment blocks the booking', () {
      final check = run(
        cases: [
          existing(
            theatreId: 'or-2',
            start: at(9, 30),
            end: at(11),
            equipment: ['scope'],
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.equipmentBusy), isTrue);
    });

    test('unrelated equipment does not block', () {
      final check = run(
        cases: [
          existing(
            theatreId: 'or-2',
            start: at(9, 30),
            end: at(11),
            equipment: ['drill'],
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.equipmentBusy), isFalse);
    });

    test('a maintenance block closes the theatre', () {
      final check = run(
        blocks: [
          TheatreBlock(
            theatreId: 'or-1',
            range: TimeRange(at(8), at(13)),
            reason: 'صيانة',
          ),
        ],
      );
      expect(check.hasConflict(ConflictType.theatreBlocked), isTrue);
    });

    test('cancelled and postponed cases release their slot', () {
      for (final status in [CaseStatus.cancelled, CaseStatus.postponed]) {
        final check = run(
          cases: [existing(start: at(8, 30), end: at(11), status: status)],
        );
        expect(check.isPermitted, isTrue, reason: status.name);
      }
    });

    test('rescheduling a case does not conflict with itself', () {
      final self = existing(id: 'case-self', start: at(9), end: at(11));
      final check = scheduler.check(
        draft: BookingDraft(
          theatreId: 'or-1',
          surgeonId: 'doc-1',
          patientId: 'pat-1',
          procedure: procedure,
          classification: major,
          start: at(9, 30),
          excludeCaseId: 'case-self',
        ),
        theatre: theatre,
        surgeon: senior,
        cases: [self],
        appointments: const [],
        blocks: const [],
      );
      expect(check.isPermitted, isTrue);
    });

    test('one message per conflict reason, not one per clashing case', () {
      final check = run(
        cases: [
          existing(id: 'a', start: at(8, 30), end: at(9, 30)),
          existing(id: 'b', start: at(9, 30), end: at(10, 30)),
          existing(id: 'c', start: at(10, 30), end: at(11, 30)),
        ],
      );
      expect(
        check.conflicts.where((c) => c.type == ConflictType.theatreBusy).length,
        1,
      );
    });
  });

  group('soft conflicts (warnings, may proceed with a reason)', () {
    test('theatre type mismatch warns but does not block', () {
      final check = run(d: draft(theatreId: 'or-4'), t: minorTheatre);
      expect(check.isPermitted, isTrue);
      expect(
        check.warnings.map((w) => w.type),
        contains(WarningType.theatreTypeMismatch),
      );
    });

    test('a surgeon below the required seniority warns', () {
      final check = run(d: draft(surgeonId: 'doc-2'), surgeon: junior);
      expect(check.isPermitted, isTrue);
      expect(
        check.warnings.map((w) => w.type),
        contains(WarningType.seniorityBelowRequirement),
      );
    });

    test('a booking outside operating hours warns', () {
      final check = run(d: draft(start: at(19, 30)));
      expect(check.isPermitted, isTrue);
      expect(
        check.warnings.map((w) => w.type),
        contains(WarningType.outsideOperatingHours),
      );
    });

    test('a booking inside operating hours does not warn about hours', () {
      final check = run(d: draft(start: at(10)));
      expect(
        check.warnings.map((w) => w.type),
        isNot(contains(WarningType.outsideOperatingHours)),
      );
    });
  });

  group('free windows', () {
    test('an empty day is one window spanning the working hours', () {
      final windows = scheduler.freeWindows(
        theatre: theatre,
        day: day,
        cases: const [],
        blocks: const [],
      );
      expect(windows, hasLength(1));
      expect(windows.single.start, at(8));
      expect(windows.single.end, at(20));
    });

    test('a case splits the day and its turnover is excluded', () {
      final windows = scheduler.freeWindows(
        theatre: theatre,
        day: day,
        cases: [
          existing(
            start: at(10),
            end: at(12),
            turnover: const Duration(minutes: 45),
          ),
        ],
        blocks: const [],
      );
      expect(windows, hasLength(2));
      expect(windows.first, TimeRange(at(8), at(10)));
      expect(windows.last, TimeRange(at(12, 45), at(20)));
    });

    test('overlapping busy periods are merged, not double-counted', () {
      final windows = scheduler.freeWindows(
        theatre: theatre,
        day: day,
        cases: [
          existing(id: 'a', start: at(10), end: at(12), turnover: Duration.zero),
          existing(id: 'b', start: at(11), end: at(13), turnover: Duration.zero),
        ],
        blocks: const [],
      );
      expect(windows, hasLength(2));
      expect(windows.last.start, at(13));
    });

    test('gaps below the usable minimum are not offered', () {
      final windows = scheduler.freeWindows(
        theatre: theatre,
        day: day,
        cases: [
          existing(
            id: 'a',
            start: at(8),
            end: at(9),
            turnover: Duration.zero,
          ),
          existing(
            id: 'b',
            start: at(9, 15),
            end: at(20),
            turnover: Duration.zero,
          ),
        ],
        blocks: const [],
        minimumUsable: const Duration(minutes: 30),
      );
      expect(windows, isEmpty, reason: 'the only gap is 15 minutes');
    });

    test('free capacity sums the windows', () {
      final capacity = scheduler.freeCapacity(
        theatre: theatre,
        day: day,
        cases: [
          existing(
            start: at(10),
            end: at(12),
            turnover: const Duration(minutes: 45),
          ),
        ],
        blocks: const [],
      );
      // 12 working hours less 2h45m occupied.
      expect(capacity, const Duration(hours: 9, minutes: 15));
    });

    test('a maintenance block removes capacity', () {
      final capacity = scheduler.freeCapacity(
        theatre: theatre,
        day: day,
        cases: const [],
        blocks: [
          TheatreBlock(
            theatreId: 'or-1',
            range: TimeRange(at(13), at(17)),
            reason: 'صيانة',
          ),
        ],
      );
      expect(capacity, const Duration(hours: 8));
    });
  });
}

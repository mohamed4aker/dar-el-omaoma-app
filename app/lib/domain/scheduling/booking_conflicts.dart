import '../models/booking.dart';
import '../models/catalog.dart';
import '../models/time_range.dart';

/// Hard conflicts. A booking carrying any of these is rejected outright and may
/// proceed only through an audited override by a user holding that permission
/// (PROMPT.md section 6.13.5).
enum ConflictType {
  theatreBusy,
  surgeonBusy,
  patientBusy,
  equipmentBusy,
  theatreBlocked,
}

/// Soft conflicts. The booking may proceed, but the user must supply a reason
/// and the relevant party is notified.
enum WarningType {
  theatreTypeMismatch,
  seniorityBelowRequirement,
  outsideOperatingHours,
}

class BookingConflict {
  const BookingConflict(this.type, {this.withCaseId, this.withRange});
  final ConflictType type;
  final String? withCaseId;
  final TimeRange? withRange;

  @override
  String toString() => 'BookingConflict(${type.name}, case: $withCaseId)';
}

class BookingWarning {
  const BookingWarning(this.type);
  final WarningType type;

  @override
  String toString() => 'BookingWarning(${type.name})';
}

/// The result of evaluating a proposed theatre booking.
class BookingCheck {
  const BookingCheck({required this.conflicts, required this.warnings});

  const BookingCheck.clear() : conflicts = const [], warnings = const [];

  final List<BookingConflict> conflicts;
  final List<BookingWarning> warnings;

  /// True when the booking may be written without an override.
  bool get isPermitted => conflicts.isEmpty;

  bool get hasWarnings => warnings.isNotEmpty;

  bool hasConflict(ConflictType type) =>
      conflicts.any((c) => c.type == type);
}

/// A proposed booking, before it is written.
class BookingDraft {
  const BookingDraft({
    required this.theatreId,
    required this.surgeonId,
    required this.patientId,
    required this.procedure,
    required this.classification,
    required this.start,
    this.duration,
    this.turnover,
    this.excludeCaseId,
  });

  final String theatreId;
  final String surgeonId;
  final String patientId;
  final Procedure procedure;
  final OperationClassification classification;
  final DateTime start;

  /// Falls back to the procedure's typical duration, then the classification
  /// default (PROMPT.md section 6.13.2).
  final Duration? duration;
  final Duration? turnover;

  /// Set when rescheduling an existing case, so the case does not conflict
  /// with itself.
  final String? excludeCaseId;

  Duration get effectiveDuration =>
      duration ?? procedure.typicalDuration;

  Duration get effectiveTurnover =>
      turnover ?? classification.defaultTurnover;

  TimeRange get range => TimeRange.fromDuration(start, effectiveDuration);

  /// Theatre occupancy includes turnover.
  TimeRange get theatreRange => range.extendedBy(effectiveTurnover);
}

/// Pure, dependency-free evaluation of theatre booking conflicts.
///
/// **This class is a user-experience aid, not the enforcement point.** The
/// authoritative check is a database exclusion constraint on the server
/// (PROMPT.md section 8, rule 5). Two surgeons confirming the same slot in the
/// same second is an expected event; only the database can arbitrate it. The
/// client runs this first so the second surgeon sees the clash before tapping
/// confirm, and handles the server's 409 when it happens anyway.
class TheatreScheduler {
  const TheatreScheduler();

  BookingCheck check({
    required BookingDraft draft,
    required OperatingTheatre theatre,
    required Doctor surgeon,
    required List<SurgeryCase> cases,
    required List<Appointment> appointments,
    required List<TheatreBlock> blocks,
  }) {
    final conflicts = <BookingConflict>[];
    final warnings = <BookingWarning>[];

    final theatreRange = draft.theatreRange;
    final clinicalRange = draft.range;

    final relevantCases = cases.where(
      (c) => c.blocksTime && c.id != draft.excludeCaseId,
    );

    for (final other in relevantCases) {
      // Theatre: compare occupancy to occupancy so turnover is respected on
      // both sides of the pair.
      if (other.theatreId == draft.theatreId &&
          other.occupiesTheatre.overlaps(theatreRange)) {
        conflicts.add(BookingConflict(
          ConflictType.theatreBusy,
          withCaseId: other.id,
          withRange: other.occupiesTheatre,
        ));
      }

      // Surgeon: the surgeon is free during turnover, so compare the
      // clinical ranges only.
      if (other.surgeonId == draft.surgeonId &&
          other.range.overlaps(clinicalRange)) {
        conflicts.add(BookingConflict(
          ConflictType.surgeonBusy,
          withCaseId: other.id,
          withRange: other.range,
        ));
      }

      if (other.patientId == draft.patientId &&
          other.range.overlaps(clinicalRange)) {
        conflicts.add(BookingConflict(
          ConflictType.patientBusy,
          withCaseId: other.id,
          withRange: other.range,
        ));
      }

      if (draft.procedure.requiredEquipment.isNotEmpty &&
          other.range.overlaps(clinicalRange) &&
          other.equipment.any(draft.procedure.requiredEquipment.contains)) {
        conflicts.add(BookingConflict(
          ConflictType.equipmentBusy,
          withCaseId: other.id,
          withRange: other.range,
        ));
      }
    }

    // A surgeon's clinic session blocks theatre time just as another case does
    // (PROMPT.md section 6.13.5).
    for (final appointment in appointments) {
      if (!appointment.blocksTime) continue;
      if (appointment.doctorId == draft.surgeonId &&
          appointment.range.overlaps(clinicalRange)) {
        conflicts.add(BookingConflict(
          ConflictType.surgeonBusy,
          withRange: appointment.range,
        ));
      }
      if (appointment.patientId == draft.patientId &&
          appointment.range.overlaps(clinicalRange)) {
        conflicts.add(BookingConflict(
          ConflictType.patientBusy,
          withRange: appointment.range,
        ));
      }
    }

    for (final block in blocks) {
      if (block.theatreId == draft.theatreId &&
          block.range.overlaps(theatreRange)) {
        conflicts.add(BookingConflict(
          ConflictType.theatreBlocked,
          withRange: block.range,
        ));
      }
    }

    if (!theatre.isActive) {
      conflicts.add(const BookingConflict(ConflictType.theatreBlocked));
    }

    // Soft conflicts.
    if (theatre.type != draft.procedure.requiredTheatreType) {
      warnings.add(const BookingWarning(WarningType.theatreTypeMismatch));
    }
    if (surgeon.seniority < draft.classification.requiredSeniority) {
      warnings.add(const BookingWarning(WarningType.seniorityBelowRequirement));
    }
    if (!_withinOperatingHours(theatre, theatreRange)) {
      warnings.add(const BookingWarning(WarningType.outsideOperatingHours));
    }

    return BookingCheck(
      conflicts: _deduplicate(conflicts),
      warnings: warnings,
    );
  }

  /// Free windows for one theatre on one day, for the availability grid
  /// (PROMPT.md section 6.13.4). Returned in chronological order.
  List<TimeRange> freeWindows({
    required OperatingTheatre theatre,
    required DateTime day,
    required List<SurgeryCase> cases,
    required List<TheatreBlock> blocks,
    Duration minimumUsable = const Duration(minutes: 30),
  }) {
    final dayStart = DateTime(day.year, day.month, day.day)
        .add(Duration(minutes: theatre.opensAt));
    final dayEnd = DateTime(day.year, day.month, day.day)
        .add(Duration(minutes: theatre.closesAt));
    if (!dayEnd.isAfter(dayStart)) return const [];

    final occupied = <TimeRange>[
      for (final c in cases)
        if (c.blocksTime && c.theatreId == theatre.id) c.occupiesTheatre,
      for (final b in blocks)
        if (b.theatreId == theatre.id) b.range,
    ]..sort();

    final free = <TimeRange>[];
    var cursor = dayStart;

    for (final busy in occupied) {
      if (!busy.end.isAfter(dayStart) || !busy.start.isBefore(dayEnd)) {
        continue; // Outside the working day entirely.
      }
      final busyStart = busy.start.isBefore(dayStart) ? dayStart : busy.start;
      if (busyStart.isAfter(cursor)) {
        final gap = TimeRange(cursor, busyStart);
        if (gap.duration >= minimumUsable) free.add(gap);
      }
      if (busy.end.isAfter(cursor)) {
        cursor = busy.end.isAfter(dayEnd) ? dayEnd : busy.end;
      }
    }

    if (cursor.isBefore(dayEnd)) {
      final tail = TimeRange(cursor, dayEnd);
      if (tail.duration >= minimumUsable) free.add(tail);
    }
    return free;
  }

  /// Total free time in a theatre on a day — the per-theatre summary figure
  /// required by PROMPT.md section 6.13.4.
  Duration freeCapacity({
    required OperatingTheatre theatre,
    required DateTime day,
    required List<SurgeryCase> cases,
    required List<TheatreBlock> blocks,
  }) {
    return freeWindows(
      theatre: theatre,
      day: day,
      cases: cases,
      blocks: blocks,
      minimumUsable: Duration.zero,
    ).fold(Duration.zero, (total, w) => total + w.duration);
  }

  bool _withinOperatingHours(OperatingTheatre theatre, TimeRange range) {
    final startMinutes = range.start.hour * 60 + range.start.minute;
    final endMinutes = range.end.hour * 60 + range.end.minute;
    final sameDay = range.start.day == range.end.day;
    return sameDay &&
        startMinutes >= theatre.opensAt &&
        endMinutes <= theatre.closesAt;
  }

  /// Collapses repeats of the same conflict type so the user sees one clear
  /// message per reason rather than one per clashing case.
  List<BookingConflict> _deduplicate(List<BookingConflict> conflicts) {
    final seen = <ConflictType>{};
    final result = <BookingConflict>[];
    for (final conflict in conflicts) {
      if (seen.add(conflict.type)) result.add(conflict);
    }
    return result;
  }
}

/// A half-open time interval `[start, end)`.
///
/// Half-open is deliberate: a case ending at 10:00 and one starting at 10:00
/// do not overlap. Treating the interval as closed would reject every
/// back-to-back theatre booking in the hospital.
class TimeRange implements Comparable<TimeRange> {
  TimeRange(this.start, this.end) {
    if (!end.isAfter(start)) {
      throw ArgumentError('TimeRange end ($end) must be after start ($start)');
    }
  }

  TimeRange.fromDuration(this.start, Duration duration)
      : end = start.add(duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError('TimeRange duration must be positive');
    }
  }

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  bool overlaps(TimeRange other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  /// Extends the end by [d] — used to append theatre turnover time.
  TimeRange extendedBy(Duration d) => TimeRange(start, end.add(d));

  @override
  int compareTo(TimeRange other) => start.compareTo(other.start);

  @override
  String toString() => '${start.toIso8601String()} → ${end.toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      other is TimeRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/catalog.dart';

/// Editor for a doctor's weekly shifts.
///
/// A shift is what actually produces bookable slots: the day, the window, and
/// the cap. The cap also sets the slot length — a doctor taking 12 patients in
/// a four-hour clinic gets 20-minute slots, which is the number the hospital
/// really means when it says "twelve cases".
class ShiftEditor extends StatelessWidget {
  const ShiftEditor({
    required this.shifts,
    required this.onChanged,
    super.key,
  });

  final List<DoctorShift> shifts;
  final ValueChanged<List<DoctorShift>> onChanged;

  static const _order = [6, 7, 1, 2, 3, 4, 5]; // Saturday-first.

  static String _dayName(int weekday, AppStrings s) {
    const ar = {
      1: 'الإثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس',
      5: 'الجمعة', 6: 'السبت', 7: 'الأحد',
    };
    const en = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday',
      5: 'Friday', 6: 'Saturday', 7: 'Sunday',
    };
    return (s.localeName == 'en' ? en : ar)[weekday]!;
  }

  DoctorShift? _shiftFor(int weekday) {
    for (final shift in shifts) {
      if (shift.weekday == weekday) return shift;
    }
    return null;
  }

  void _replace(int weekday, DoctorShift? shift) {
    final updated = shifts.where((sh) => sh.weekday != weekday).toList();
    if (shift != null) updated.add(shift);
    updated.sort((a, b) => a.weekday.compareTo(b.weekday));
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final capacity = shifts.fold<int>(
      0,
      (total, sh) => sh.maxPatients <= 0 ? total : total + sh.maxPatients,
    );
    final anyUncapped = shifts.any((sh) => sh.maxPatients <= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final weekday in _order)
          _DayRow(
            weekday: weekday,
            name: _dayName(weekday, s),
            shift: _shiftFor(weekday),
            onToggle: (on) => _replace(
              weekday,
              on
                  ? DoctorShift(
                      weekday: weekday,
                      startsAt: 10 * 60,
                      endsAt: 14 * 60,
                      maxPatients: 12,
                    )
                  : null,
            ),
            onChanged: (shift) => _replace(weekday, shift),
          ),
        if (shifts.isNotEmpty) ...[
          const SizedBox(height: Gap.md),
          InfoNote(
            anyUncapped
                ? s.adminNoCap
                : '${s.adminWeeklyCapacity}: $capacity',
            icon: Icons.groups_outlined,
            color: AppColors.navy,
          ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.weekday,
    required this.name,
    required this.shift,
    required this.onToggle,
    required this.onChanged,
  });

  final int weekday;
  final String name;
  final DoctorShift? shift;
  final ValueChanged<bool> onToggle;
  final ValueChanged<DoctorShift> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final active = shift != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: AppCard(
        padding: const EdgeInsets.all(Gap.md),
        borderColor: active
            ? AppColors.navy.withValues(alpha: 0.4)
            : Theme.of(context).colorScheme.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (!active)
                  Text(s.adminNoShift,
                      style: Theme.of(context).textTheme.labelSmall),
                Switch(value: active, onChanged: onToggle),
              ],
            ),
            if (active) ...[
              const Divider(height: Gap.lg),
              Row(
                children: [
                  Expanded(
                    child: _TimeStepper(
                      label: s.adminShiftFrom,
                      minutes: shift!.startsAt,
                      onChanged: (v) => onChanged(DoctorShift(
                        weekday: weekday,
                        startsAt: v,
                        endsAt: shift!.endsAt,
                        maxPatients: shift!.maxPatients,
                      )),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: _TimeStepper(
                      label: s.adminShiftTo,
                      minutes: shift!.endsAt,
                      onChanged: (v) => onChanged(DoctorShift(
                        weekday: weekday,
                        startsAt: shift!.startsAt,
                        endsAt: v,
                        maxPatients: shift!.maxPatients,
                      )),
                    ),
                  ),
                ],
              ),
              if (!shift!.isValid) ...[
                const SizedBox(height: Gap.sm),
                InfoNote(s.adminHoursInvalid, color: AppColors.danger),
              ],
              const SizedBox(height: Gap.md),
              Text(
                '${s.adminMaxPatients}: '
                '${shift!.maxPatients == 0 ? s.adminNoCap : shift!.maxPatients}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Slider(
                value: shift!.maxPatients.toDouble(),
                min: 0,
                max: 40,
                divisions: 40,
                label: shift!.maxPatients == 0
                    ? s.adminNoCap
                    : '${shift!.maxPatients}',
                onChanged: (v) => onChanged(DoctorShift(
                  weekday: weekday,
                  startsAt: shift!.startsAt,
                  endsAt: shift!.endsAt,
                  maxPatients: v.round(),
                )),
              ),
              if (shift!.isValid)
                Text(
                  '${s.adminSlotLength}: '
                  '${Fmt.duration(Duration(minutes: shift!.slotMinutes(20)), s)}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.success),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Row(
          children: [
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: minutes >= 30 ? () => onChanged(minutes - 30) : null,
              icon: const Icon(Icons.remove, size: 18),
            ),
            Expanded(
              child: Text(
                '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
                '${(minutes % 60).toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: minutes <= 24 * 60 - 30
                  ? () => onChanged(minutes + 30)
                  : null,
              icon: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

/// Confirms a schedule edit that would break existing bookings.
///
/// The administrator sees the number of patients affected *before* saving —
/// discovering it afterwards means the patients discover it first.
Future<bool?> confirmScheduleImpact(BuildContext context, int count) {
  final s = context.s;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.event_busy_outlined,
          color: AppColors.danger, size: 36),
      title: Text('${s.adminAffectedBookings}: $count'),
      content: Text(
        s.adminAffectedWarning,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: Text(s.adminSaveAnyway),
        ),
      ],
    ),
  );
}

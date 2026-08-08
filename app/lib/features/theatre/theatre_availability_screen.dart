import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/time_range.dart';
import 'theatre_booking_sheet.dart';

/// The theatre availability grid — "الفاضي والمحجوز" (PROMPT.md 6.13.4).
///
/// Theatres run down the axis, time across it. Each block is colour-coded by
/// state and by operation classification, and every block also carries a text
/// label: colour is never the only signal.
class TheatreAvailabilityScreen extends StatefulWidget {
  const TheatreAvailabilityScreen({super.key});

  @override
  State<TheatreAvailabilityScreen> createState() =>
      _TheatreAvailabilityScreenState();
}

class _TheatreAvailabilityScreenState extends State<TheatreAvailabilityScreen> {
  late DateTime _day = Seed.today;
  String? _classificationFilter;

  static const _startHour = 7;
  static const _endHour = 21;
  static const _pixelsPerHour = 92.0;
  static const _rowHeight = 78.0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final session = state.session;

    final cases = state.casesOn(_day).where((c) {
      if (_classificationFilter == null) return true;
      return c.classificationId == _classificationFilter;
    }).toList();
    final blocks = state.blocksOn(_day);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.theatreAvailability),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              _DayStrip(
                selected: _day,
                onSelect: (d) => setState(() => _day = d),
              ),
              _ClassificationFilter(
                selected: _classificationFilter,
                onSelect: (id) => setState(() => _classificationFilter = id),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const _Legend(),
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Gap.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HourRuler(
                        startHour: _startHour,
                        endHour: _endHour,
                        pixelsPerHour: _pixelsPerHour,
                      ),
                      for (final theatre in Seed.theatres)
                        _TheatreRow(
                          theatre: theatre,
                          day: _day,
                          cases: cases
                              .where((c) => c.theatreId == theatre.id)
                              .toList(),
                          blocks: blocks
                              .where((b) => b.theatreId == theatre.id)
                              .toList(),
                          freeCapacity: state.freeCapacity(theatre, _day),
                          startHour: _startHour,
                          endHour: _endHour,
                          pixelsPerHour: _pixelsPerHour,
                          rowHeight: _rowHeight,
                          onTapFree: session.role.canBookTheatreDirectly
                              ? (start) => _openBooking(theatre, start)
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: session.role.canBookTheatreDirectly
          ? FloatingActionButton.extended(
              onPressed: () => _openBooking(Seed.theatres.first, null),
              icon: const Icon(Icons.add),
              label: Text(s.theatreBookDirect),
              backgroundColor: AppColors.pink,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Future<void> _openBooking(OperatingTheatre theatre, DateTime? start) async {
    await showTheatreBookingSheet(
      context,
      theatre: theatre,
      day: _day,
      initialStart: start,
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selected, required this.onSelect});

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        itemCount: 14,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
        itemBuilder: (context, index) {
          final day = Seed.today.add(Duration(days: index));
          final isSelected = Fmt.isSameDay(day, selected);
          return GestureDetector(
            onTap: () => onSelect(day),
            child: Container(
              width: 66,
              padding: const EdgeInsets.symmetric(vertical: Gap.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.input),
                border: Border.all(
                  color: isSelected
                      ? AppColors.navy
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    index == 0 ? s.theatreToday : Fmt.weekday(day, s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                  Text(
                    Fmt.shortDate(day, s),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClassificationFilter extends StatelessWidget {
  const _ClassificationFilter({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: Gap.sm),
            child: FilterChip(
              label: Text(s.commonAll),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          // Classifications come from data, never from a hard-coded enum
          // (PROMPT.md 6.13.2).
          for (final c in Seed.classifications.where((c) => c.isActive))
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Gap.sm),
              child: FilterChip(
                avatar: CircleAvatar(backgroundColor: c.colour, radius: 6),
                label: Text(c.name(s.localeName)),
                selected: selected == c.id,
                onSelected: (_) => onSelect(selected == c.id ? null : c.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
      color: Theme.of(context).colorScheme.surface,
      child: Wrap(
        spacing: Gap.lg,
        runSpacing: Gap.xs,
        children: [
          _LegendItem(color: AppColors.success, label: s.theatreFree),
          _LegendItem(color: AppColors.navy, label: s.theatreBooked),
          _LegendItem(color: AppColors.warning, label: s.theatreProvisional),
          _LegendItem(color: AppColors.muted, label: s.theatreTurnover),
          _LegendItem(color: AppColors.danger, label: s.theatreBlocked),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: Gap.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _HourRuler extends StatelessWidget {
  const _HourRuler({
    required this.startHour,
    required this.endHour,
    required this.pixelsPerHour,
  });

  final int startHour;
  final int endHour;
  final double pixelsPerHour;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: _TheatreRow.labelWidth),
        for (var hour = startHour; hour < endHour; hour++)
          SizedBox(
            width: pixelsPerHour,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.sm),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
      ],
    );
  }
}

class _TheatreRow extends StatelessWidget {
  const _TheatreRow({
    required this.theatre,
    required this.day,
    required this.cases,
    required this.blocks,
    required this.freeCapacity,
    required this.startHour,
    required this.endHour,
    required this.pixelsPerHour,
    required this.rowHeight,
    required this.onTapFree,
  });

  static const labelWidth = 132.0;

  final OperatingTheatre theatre;
  final DateTime day;
  final List<SurgeryCase> cases;
  final List<TheatreBlock> blocks;
  final Duration freeCapacity;
  final int startHour;
  final int endHour;
  final double pixelsPerHour;
  final double rowHeight;
  final ValueChanged<DateTime>? onTapFree;

  double _xFor(DateTime moment) {
    final minutes =
        (moment.hour * 60 + moment.minute) - (startHour * 60);
    return (minutes / 60) * pixelsPerHour;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final gridWidth = (endHour - startHour) * pixelsPerHour;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      height: rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(theatre.name(s.localeName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  // Per-theatre free-capacity summary, so a surgeon can find a
                  // free day without scanning the grid (PROMPT.md 6.13.4).
                  Text(
                    '${Fmt.duration(freeCapacity, s)} ${s.theatreFreeHours}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: gridWidth,
            height: rowHeight,
            child: Stack(
              children: [
                for (var hour = startHour; hour < endHour; hour++)
                  PositionedDirectional(
                    start: (hour - startHour) * pixelsPerHour,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: pixelsPerHour,
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          end: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: onTapFree == null
                          ? null
                          : Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onTapFree!(
                                  DateTime(day.year, day.month, day.day, hour),
                                ),
                              ),
                            ),
                    ),
                  ),
                for (final block in blocks)
                  _Block(
                    start: _xFor(block.range.start),
                    width: _widthFor(block.range),
                    color: AppColors.danger,
                    label: s.theatreBlocked,
                    sublabel: block.reason,
                  ),
                for (final c in cases) ...[
                  _Block(
                    start: _xFor(c.range.start),
                    width: _widthFor(c.range),
                    color: c.origin == BookingOrigin.patientRequest
                        ? AppColors.warning
                        : AppColors.navy,
                    accent: Seed.classificationById(c.classificationId).colour,
                    label: Seed.procedureById(c.procedureId).name(s.localeName),
                    sublabel:
                        '${Seed.doctorById(c.surgeonId).name(s.localeName)} · '
                        '${Fmt.timeRange(c.range.start, c.range.end)}',
                  ),
                  _Block(
                    start: _xFor(c.range.end),
                    width: (c.turnover.inMinutes / 60) * pixelsPerHour,
                    color: AppColors.muted,
                    label: s.theatreTurnover,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _widthFor(TimeRange range) =>
      (range.duration.inMinutes / 60) * pixelsPerHour;
}

class _Block extends StatelessWidget {
  const _Block({
    required this.start,
    required this.width,
    required this.color,
    required this.label,
    this.sublabel,
    this.accent,
    this.dense = false,
  });

  final double start;
  final double width;
  final Color color;
  final String label;
  final String? sublabel;
  final Color? accent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (width <= 0) return const SizedBox.shrink();
    return PositionedDirectional(
      start: start,
      top: 4,
      bottom: 4,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dense ? 0.18 : 0.16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (accent != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

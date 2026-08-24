import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/enums.dart';
import '../../domain/scheduling/booking_conflicts.dart';

Future<void> showScheduleSheet(BuildContext context, SurgeryRequest request) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ScheduleSheet(request: request),
  );
}

/// The administration allocates a theatre, a time and a price to a request,
/// then confirms.
///
/// The same conflict engine that governs a doctor's direct booking governs
/// this one — allocating centrally does not exempt the schedule from being
/// physically deliverable.
class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.request});
  final SurgeryRequest request;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late String _theatreId = Seed.theatres.first.id;
  late String _surgeonId =
      widget.request.preferredSurgeonId ?? Seed.doctors.first.id;
  late DateTime _day = widget.request.preferredFrom ??
      DateTime.now().add(const Duration(days: 1));
  int _hour = 9;
  int _minute = 0;
  late final _price = TextEditingController(
      text: '${Seed.procedureById(widget.request.procedureId).price}');
  final _overrideReason = TextEditingController();
  bool _showOverride = false;

  @override
  void dispose() {
    _price.dispose();
    _overrideReason.dispose();
    super.dispose();
  }

  DateTime get _start =>
      DateTime(_day.year, _day.month, _day.day, _hour, _minute);

  BookingDraft get _draft {
    final procedure = Seed.procedureById(widget.request.procedureId);
    return BookingDraft(
      theatreId: _theatreId,
      surgeonId: _surgeonId,
      patientId: widget.request.patientId,
      procedure: procedure,
      classification:
          Seed.classificationById(widget.request.classificationId),
      start: _start,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final procedure = Seed.procedureById(widget.request.procedureId);
    final classification =
        Seed.classificationById(widget.request.classificationId);
    final check = state.checkBooking(_draft);
    final blocked = !check.isPermitted;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(Gap.xl),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.scheduleTitle,
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),

          AppCard(
            borderColor: classification.colour.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(procedure.name(s.localeName),
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    StatusChip(classification.name(s.localeName),
                        color: classification.colour),
                  ],
                ),
                const SizedBox(height: Gap.sm),
                Text('${s.complaintsReference}: ${widget.request.reference}',
                    style: Theme.of(context).textTheme.bodySmall),
                if (widget.request.isFromDoctor &&
                    widget.request.requestedByDoctorId != null)
                  Text(
                    '${s.scheduleRequestedBy}: '
                    '${Seed.doctorById(widget.request.requestedByDoctorId!).name(s.localeName)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (widget.request.clinicalNote != null) ...[
                  const SizedBox(height: Gap.sm),
                  InfoNote(widget.request.clinicalNote!,
                      icon: Icons.sticky_note_2_outlined),
                ],
                if (widget.request.preferredFrom != null) ...[
                  const SizedBox(height: Gap.sm),
                  Text(
                    '${s.surgeryPreferredDates}: '
                    '${Fmt.date(widget.request.preferredFrom!, s)}'
                    '${widget.request.preferredTo != null ? " → ${Fmt.date(widget.request.preferredTo!, s)}" : ""}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),

          _label(context, s.theatreTitle),
          DropdownButtonFormField<String>(
            initialValue: _theatreId,
            isExpanded: true,
            items: [
              for (final t in Seed.theatres.where((t) => t.isActive))
                DropdownMenuItem(
                  value: t.id,
                  child: Text('${t.code} — ${t.name(s.localeName)}'),
                ),
            ],
            onChanged: (id) => setState(() => _theatreId = id ?? _theatreId),
          ),
          const SizedBox(height: Gap.lg),

          _label(context, s.clinicChooseDoctor),
          DropdownButtonFormField<String>(
            initialValue: _surgeonId,
            isExpanded: true,
            items: [
              for (final d in Seed.doctors)
                DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    '${d.name(s.localeName)} — ${d.title(s.localeName)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) => setState(() => _surgeonId = id ?? _surgeonId),
          ),
          const SizedBox(height: Gap.lg),

          _label(context, s.scheduleDate),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _day,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 180)),
              );
              if (picked != null) setState(() => _day = picked);
            },
            icon: const Icon(Icons.event_outlined),
            label: Text('${Fmt.weekday(_day, s)} ${Fmt.date(_day, s)}'),
          ),
          const SizedBox(height: Gap.lg),

          _label(context, s.scheduleTime),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (var hour = 7; hour < 21; hour++)
                for (final minute in const [0, 30])
                  ChoiceChip(
                    label: Text('${hour.toString().padLeft(2, '0')}:'
                        '${minute.toString().padLeft(2, '0')}'),
                    selected: _hour == hour && _minute == minute,
                    onSelected: (_) => setState(() {
                      _hour = hour;
                      _minute = minute;
                    }),
                  ),
            ],
          ),
          const SizedBox(height: Gap.lg),

          _label(context, s.scheduleConfirmedPrice),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              suffixText: s.commonEgp,
              helperText: s.scheduleConfirmedPriceHelp,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Gap.lg),

          AppCard(
            child: Column(
              children: [
                _summary(context, s.surgeryDuration,
                    Fmt.duration(_draft.effectiveDuration, s)),
                _summary(context, s.theatreTurnover,
                    Fmt.duration(_draft.effectiveTurnover, s)),
                _summary(context, s.clinicChooseSlot,
                    Fmt.timeRange(_draft.range.start, _draft.range.end)),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),

          _ConflictPanel(check: check),

          if (blocked && state.session.role.canOverrideConflict) ...[
            const SizedBox(height: Gap.lg),
            SwitchListTile(
              value: _showOverride,
              onChanged: (v) => setState(() => _showOverride = v),
              contentPadding: EdgeInsets.zero,
              title: Text(s.theatreOverride,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (_showOverride)
              TextField(
                controller: _overrideReason,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration:
                    InputDecoration(labelText: s.theatreOverrideReason),
              ),
          ],

          const SizedBox(height: Gap.xl),
          FilledButton(
            onPressed: _canConfirm(check) ? () => _confirm(state) : null,
            style: FilledButton.styleFrom(
              backgroundColor: blocked ? AppColors.danger : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(s.scheduleConfirm),
          ),
          const SizedBox(height: Gap.sm),
          Text(s.scheduleNotifiesDoctor,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  bool _canConfirm(BookingCheck check) {
    if (_price.text.trim().isEmpty) return false;
    if (check.isPermitted) return true;
    return _showOverride && _overrideReason.text.trim().length >= 5;
  }

  void _confirm(AppState state) {
    final s = context.s;
    final outcome = state.scheduleRequest(
      requestId: widget.request.id,
      theatreId: _theatreId,
      surgeonId: _surgeonId,
      start: _start,
      price: int.tryParse(_price.text.trim()) ?? 0,
      overrideReason: _showOverride && _overrideReason.text.trim().isNotEmpty
          ? _overrideReason.text.trim()
          : null,
    );

    switch (outcome) {
      case BookingAccepted():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(s.scheduleDone),
          ),
        );
      case BookingRejected():
        // The re-check at write time disagreed with the sheet — rebuild so the
        // fresh conflict is what the user sees.
        setState(() {});
    }
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _summary(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(label, style: Theme.of(context).textTheme.bodySmall)),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}

class _ConflictPanel extends StatelessWidget {
  const _ConflictPanel({required this.check});
  final BookingCheck check;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (check.isPermitted && !check.hasWarnings) {
      return InfoNote(
        s.localeName == 'en' ? 'No conflicts found.' : 'لا توجد تعارضات.',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final conflict in check.conflicts)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: InfoNote(
              switch (conflict.type) {
                ConflictType.theatreBusy => s.theatreConflictTheatre,
                ConflictType.surgeonBusy => s.theatreConflictSurgeon,
                ConflictType.patientBusy => s.theatreConflictPatient,
                ConflictType.equipmentBusy => s.theatreConflictEquipment,
                ConflictType.theatreBlocked => s.theatreConflictBlocked,
              },
              icon: Icons.block,
              color: AppColors.danger,
            ),
          ),
        for (final warning in check.warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: InfoNote(
              switch (warning.type) {
                WarningType.theatreTypeMismatch => s.theatreWarnTheatreType,
                WarningType.seniorityBelowRequirement => s.theatreWarnSeniority,
                WarningType.outsideOperatingHours => s.theatreWarnOutsideHours,
              },
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
            ),
          ),
      ],
    );
  }
}

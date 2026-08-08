import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/patient.dart';
import '../../domain/scheduling/booking_conflicts.dart';

Future<void> showTheatreBookingSheet(
  BuildContext context, {
  required OperatingTheatre theatre,
  required DateTime day,
  DateTime? initialStart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TheatreBookingSheet(
      theatre: theatre,
      day: day,
      initialStart: initialStart,
    ),
  );
}

/// Direct theatre booking by a doctor (PROMPT.md 6.13.5).
///
/// There is no approval step here, by design. What there *is* is enforcement:
/// the conflict check runs on every change, hard conflicts disable the confirm
/// button outright, and proceeding anyway demands the override permission plus
/// a written reason.
class _TheatreBookingSheet extends StatefulWidget {
  const _TheatreBookingSheet({
    required this.theatre,
    required this.day,
    this.initialStart,
  });

  final OperatingTheatre theatre;
  final DateTime day;
  final DateTime? initialStart;

  @override
  State<_TheatreBookingSheet> createState() => _TheatreBookingSheetState();
}

class _TheatreBookingSheetState extends State<_TheatreBookingSheet> {
  late OperatingTheatre _theatre = widget.theatre;
  late DateTime _start = widget.initialStart ??
      DateTime(widget.day.year, widget.day.month, widget.day.day, 9);
  Procedure? _procedure;
  Patient? _patient;
  String? _surgeonId;
  final _overrideReason = TextEditingController();
  bool _showOverride = false;

  @override
  void initState() {
    super.initState();
    _surgeonId = context.read<AppState>().session.doctorId ??
        Seed.doctors.first.id;
  }

  @override
  void dispose() {
    _overrideReason.dispose();
    super.dispose();
  }

  BookingDraft? _draft() {
    final procedure = _procedure;
    final patient = _patient;
    final surgeonId = _surgeonId;
    if (procedure == null || patient == null || surgeonId == null) return null;
    return BookingDraft(
      theatreId: _theatre.id,
      surgeonId: surgeonId,
      patientId: patient.id,
      procedure: procedure,
      classification: Seed.classificationById(procedure.classificationId),
      start: _start,
    );
  }

  void _confirm() {
    final draft = _draft();
    final patient = _patient;
    if (draft == null || patient == null) return;

    final state = context.read<AppState>();
    final outcome = state.bookTheatreCase(
      draft: draft,
      patient: patient,
      origin: BookingOrigin.doctorDirect,
      overrideReason:
          _showOverride && _overrideReason.text.trim().isNotEmpty
              ? _overrideReason.text.trim()
              : null,
    );

    final s = context.s;
    switch (outcome) {
      case BookingAccepted(:final warnings):
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              warnings.isEmpty
                  ? s.theatreBookedOk
                  : '${s.theatreBookedOk} · ${warnings.length} ${s.localeName == 'en' ? 'warning(s) recorded' : 'تنبيه مسجّل'}',
            ),
          ),
        );
      case BookingRejected():
        // The re-check at write time disagreed with what the sheet last
        // rendered — the slot was taken in the meantime. Rebuild so the user
        // sees the fresh conflict rather than a generic failure.
        setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final draft = _draft();
    final check = draft == null ? null : state.checkBooking(draft);
    final blocked = check != null && !check.isPermitted;
    final canOverride = state.session.role.canOverrideConflict;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.6,
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(Gap.xl),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.theatreBookDirect,
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          InfoNote(s.theatreNoApprovalNeeded, icon: Icons.bolt_outlined,
              color: AppColors.success),
          const SizedBox(height: Gap.xl),

          _FieldLabel(s.theatreTitle),
          DropdownButtonFormField<String>(
            initialValue: _theatre.id,
            items: [
              for (final t in Seed.theatres)
                DropdownMenuItem(
                  value: t.id,
                  child: Text('${t.code} — ${t.name(s.localeName)}'),
                ),
            ],
            onChanged: (id) => setState(
                () => _theatre = Seed.theatres.firstWhere((t) => t.id == id)),
          ),
          const SizedBox(height: Gap.lg),

          _FieldLabel(s.theatreSelectProcedure),
          DropdownButtonFormField<String>(
            initialValue: _procedure?.id,
            isExpanded: true,
            hint: Text(s.theatreSelectProcedure),
            items: [
              for (final p in Seed.procedures)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name(s.localeName),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => setState(
                () => _procedure = Seed.procedures.firstWhere((p) => p.id == id)),
          ),
          if (_procedure != null) ...[
            const SizedBox(height: Gap.md),
            _ClassificationSummary(procedure: _procedure!),
          ],
          const SizedBox(height: Gap.lg),

          _FieldLabel(s.clinicChooseDoctor),
          DropdownButtonFormField<String>(
            initialValue: _surgeonId,
            isExpanded: true,
            items: [
              for (final d in Seed.doctors)
                DropdownMenuItem(
                  value: d.id,
                  child: Text('${d.name(s.localeName)} — ${d.title(s.localeName)}',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => setState(() => _surgeonId = id),
          ),
          const SizedBox(height: Gap.lg),

          _FieldLabel(s.theatreSelectPatient),
          DropdownButtonFormField<String>(
            initialValue: _patient?.id,
            isExpanded: true,
            hint: Text(s.theatreSelectPatient),
            items: [
              for (final p in Seed.theatrePatients)
                DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.fullName} — ${p.mrn}',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => setState(() =>
                _patient = Seed.theatrePatients.firstWhere((p) => p.id == id)),
          ),
          const SizedBox(height: Gap.lg),

          _FieldLabel('${s.clinicChooseSlot} — ${Fmt.date(_start, s)}'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (var hour = 7; hour < 21; hour++)
                for (final minute in const [0, 30])
                  ChoiceChip(
                    label: Text(
                      '${hour.toString().padLeft(2, '0')}:'
                      '${minute.toString().padLeft(2, '0')}',
                    ),
                    selected:
                        _start.hour == hour && _start.minute == minute,
                    onSelected: (_) => setState(() => _start = DateTime(
                          widget.day.year,
                          widget.day.month,
                          widget.day.day,
                          hour,
                          minute,
                        )),
                  ),
            ],
          ),
          const SizedBox(height: Gap.xl),

          if (draft != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Summary(
                    label: s.surgeryDuration,
                    value: Fmt.duration(draft.effectiveDuration, s),
                  ),
                  _Summary(
                    label: s.theatreTurnover,
                    value: Fmt.duration(draft.effectiveTurnover, s),
                  ),
                  _Summary(
                    label: s.clinicChooseSlot,
                    value: Fmt.timeRange(
                        draft.range.start, draft.range.end),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
          ],

          if (check != null) _ConflictPanel(check: check),

          if (blocked && canOverride) ...[
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
            onPressed: _canConfirm(check) ? _confirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: blocked ? AppColors.danger : AppColors.pink,
              foregroundColor: Colors.white,
            ),
            child: Text(s.theatreConfirmBooking),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  bool _canConfirm(BookingCheck? check) {
    if (_draft() == null || check == null) return false;
    if (check.isPermitted) return true;
    // A hard conflict may only proceed through an audited override.
    return _showOverride && _overrideReason.text.trim().length >= 5;
  }
}

class _ClassificationSummary extends StatelessWidget {
  const _ClassificationSummary({required this.procedure});

  final Procedure procedure;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Seed.classificationById(procedure.classificationId);
    return AppCard(
      borderColor: c.colour.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(Gap.md),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: c.colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.surgeryClassification}: ${c.name(s.localeName)}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${Fmt.duration(c.defaultDuration, s)} · '
                  '${c.defaultAnaesthesia(s.localeName)} · '
                  '${c.defaultBloodUnits} ${s.localeName == 'en' ? 'blood unit(s)' : 'وحدة دم'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
              _conflictMessage(conflict, s),
              icon: Icons.block,
              color: AppColors.danger,
            ),
          ),
        for (final warning in check.warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: InfoNote(
              _warningMessage(warning, s),
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
            ),
          ),
      ],
    );
  }

  String _conflictMessage(BookingConflict conflict, AppStrings s) {
    final base = switch (conflict.type) {
      ConflictType.theatreBusy => s.theatreConflictTheatre,
      ConflictType.surgeonBusy => s.theatreConflictSurgeon,
      ConflictType.patientBusy => s.theatreConflictPatient,
      ConflictType.equipmentBusy => s.theatreConflictEquipment,
      ConflictType.theatreBlocked => s.theatreConflictBlocked,
    };
    final range = conflict.withRange;
    if (range == null) return base;
    return '$base (${Fmt.timeRange(range.start, range.end)})';
  }

  String _warningMessage(BookingWarning warning, AppStrings s) =>
      switch (warning.type) {
        WarningType.theatreTypeMismatch => s.theatreWarnTheatreType,
        WarningType.seniorityBelowRequirement => s.theatreWarnSeniority,
        WarningType.outsideOperatingHours => s.theatreWarnOutsideHours,
      };
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodySmall)),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}

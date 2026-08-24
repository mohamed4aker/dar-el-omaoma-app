import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/patient.dart';

/// A surgeon asks the administration for a theatre slot.
///
/// This is the alternative to booking directly, and which one a doctor sees is
/// decided by [HospitalPolicy.doctorsBookTheatreDirectly] — the hospital's
/// call, not the app's. The clinical decision is already the surgeon's; what
/// the administration allocates is the theatre, the time and the price.
class DoctorRequestScreen extends StatefulWidget {
  const DoctorRequestScreen({super.key});

  @override
  State<DoctorRequestScreen> createState() => _DoctorRequestScreenState();
}

class _DoctorRequestScreenState extends State<DoctorRequestScreen> {
  Procedure? _procedure;
  Patient? _patient;
  DateTimeRange? _preferred;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final doctorId = state.session.doctorId;
    final mine = doctorId == null
        ? const <SurgeryRequest>[]
        : state.requestsByDoctor(doctorId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.doctorRequestTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: s.doctorRequestNew),
              Tab(text: '${s.surgeryMyRequests} (${mine.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _form(context, state, doctorId),
            if (mine.isEmpty)
              EmptyState(
                message: s.surgeryNoRequests,
                icon: Icons.assignment_outlined,
              )
            else
              ListView(
                padding: const EdgeInsets.all(Gap.lg),
                children: [
                  for (final request in mine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.md),
                      child: _RequestCard(request: request),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AppState state, String? doctorId) {
    final s = context.s;
    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        InfoNote(s.doctorRequestNote, icon: Icons.schedule_send_outlined),
        const SizedBox(height: Gap.lg),

        Text(s.theatreSelectProcedure,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Gap.sm),
        DropdownButtonFormField<String>(
          initialValue: _procedure?.id,
          isExpanded: true,
          hint: Text(s.theatreSelectProcedure),
          items: [
            for (final p in Seed.procedures)
              DropdownMenuItem(
                value: p.id,
                child:
                    Text(p.name(s.localeName), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (id) => setState(
              () => _procedure = Seed.procedures.firstWhere((p) => p.id == id)),
        ),
        if (_procedure != null) ...[
          const SizedBox(height: Gap.md),
          Builder(builder: (context) {
            final c = Seed.classificationById(_procedure!.classificationId);
            return AppCard(
              borderColor: c.colour.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(Gap.md),
              child: Row(
                children: [
                  StatusChip(c.name(s.localeName), color: c.colour),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      '${Fmt.duration(_procedure!.typicalDuration, s)} · '
                      '${Fmt.money(_procedure!.price, s)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: Gap.lg),

        Text(s.theatreSelectPatient,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Gap.sm),
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

        Text('${s.surgeryPreferredDates} — ${s.commonOptional}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Gap.sm),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final range = await showDateRangePicker(
              context: context,
              firstDate: now,
              lastDate: now.add(const Duration(days: 120)),
            );
            if (range != null) setState(() => _preferred = range);
          },
          icon: const Icon(Icons.date_range_outlined),
          label: Text(_preferred == null
              ? s.clinicChooseSlot
              : '${Fmt.date(_preferred!.start, s)} → '
                  '${Fmt.date(_preferred!.end, s)}'),
        ),
        const SizedBox(height: Gap.lg),

        TextField(
          controller: _note,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: s.doctorRequestNoteLabel,
            helperText: s.doctorRequestNoteHelp,
          ),
        ),
        const SizedBox(height: Gap.xl),

        FilledButton(
          onPressed: (_procedure != null && _patient != null && doctorId != null)
              ? () => _submit(state, doctorId)
              : null,
          child: Text(s.doctorRequestSend),
        ),
        const SizedBox(height: Gap.xl),
      ],
    );
  }

  Future<void> _submit(AppState state, String doctorId) async {
    final s = context.s;
    final request = state.submitDoctorSurgeryRequest(
      doctorId: doctorId,
      patient: _patient!,
      procedure: _procedure!,
      clinicalNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
      preferredFrom: _preferred?.start,
      preferredTo: _preferred?.end,
    );
    if (!mounted) return;
    setState(() {
      _procedure = null;
      _patient = null;
      _preferred = null;
      _note.clear();
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined,
            color: AppColors.success, size: 40),
        title: Text(s.doctorRequestSent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.doctorRequestSentBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: Gap.md),
            SelectableText('${s.complaintsReference}: ${request.reference}',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.commonClose),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final SurgeryRequest request;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final procedure = Seed.procedureById(request.procedureId);
    final scheduled = request.status == SurgeryRequestStatus.scheduled;

    return AppCard(
      borderColor: scheduled
          ? AppColors.success.withValues(alpha: 0.6)
          : Theme.of(context).colorScheme.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(procedure.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(
                scheduled ? s.statusScheduled : s.statusUnderReview,
                color: scheduled ? AppColors.success : AppColors.warning,
                icon: scheduled ? Icons.event_available : Icons.schedule,
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text('${s.complaintsReference}: ${request.reference}',
              style: Theme.of(context).textTheme.bodySmall),

          // Once scheduled, the surgeon sees exactly what was allocated.
          if (scheduled && request.scheduledStart != null) ...[
            const Divider(height: Gap.xl),
            _Line(
              icon: Icons.meeting_room_outlined,
              label: s.theatreTitle,
              value: Seed.theatreById(request.scheduledTheatreId!).code,
            ),
            _Line(
              icon: Icons.event_outlined,
              label: s.clinicChooseSlot,
              value: '${Fmt.date(request.scheduledStart!, s)} · '
                  '${Fmt.time(request.scheduledStart!)}',
            ),
            if (request.confirmedPrice != null)
              _Line(
                icon: Icons.payments_outlined,
                label: s.adminPrice,
                value: Fmt.money(request.confirmedPrice!, s),
              ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: Gap.sm),
            Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';

/// Patient surgery request (PROMPT.md 6.13.6).
class SurgeryRequestScreen extends StatefulWidget {
  const SurgeryRequestScreen({required this.procedureId, super.key});

  final String procedureId;

  @override
  State<SurgeryRequestScreen> createState() => _SurgeryRequestScreenState();
}

class _SurgeryRequestScreenState extends State<SurgeryRequestScreen> {
  String? _preferredSurgeonId;
  DateTimeRange? _preferred;
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final procedure = Seed.procedureById(widget.procedureId);
    final classification =
        Seed.classificationById(procedure.classificationId);
    final surgeons = Seed.doctors
        .where((d) => d.centreId == procedure.centreId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.surgeryRequestNew)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            borderColor: classification.colour.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(procedure.name(s.localeName),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Gap.sm),
                Row(
                  children: [
                    StatusChip(classification.name(s.localeName),
                        color: classification.colour),
                    const SizedBox(width: Gap.sm),
                    Text(
                      Fmt.duration(procedure.typicalDuration, s),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),

          // The estimate the patient sees is stored with the request, so a
          // later dispute is resolved against what was actually displayed.
          SectionHeader(s.surgeryEstimate),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PriceText(procedure.price, currency: s.commonEgp),
                const SizedBox(height: Gap.xs),
                Text(
                  '${s.surgeryClassification} '
                  '${Fmt.moneyRange(classification.priceMin, classification.priceMax, s)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Gap.md),
                InfoNote(s.surgeryEstimateNote, color: AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),

          SectionHeader('${s.surgeryPreferredSurgeon} — ${s.commonOptional}'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final doctor in surgeons)
                ChoiceChip(
                  label: Text(doctor.name(s.localeName)),
                  selected: _preferredSurgeonId == doctor.id,
                  onSelected: (v) => setState(
                      () => _preferredSurgeonId = v ? doctor.id : null),
                ),
            ],
          ),
          const SizedBox(height: Gap.lg),

          SectionHeader('${s.surgeryPreferredDates} — ${s.commonOptional}'),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              _preferred == null
                  ? s.clinicChooseSlot
                  : '${Fmt.date(_preferred!.start, s)} → '
                      '${Fmt.date(_preferred!.end, s)}',
            ),
          ),
          const SizedBox(height: Gap.xl),

          CheckboxListTile(
            value: _acknowledged,
            onChanged: (v) => setState(() => _acknowledged = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(s.surgeryRequestAck,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: Gap.lg),
          FilledButton(
            onPressed: _acknowledged ? _submit : null,
            child: Text(s.surgeryRequestNew),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (range != null) setState(() => _preferred = range);
  }

  Future<void> _submit() async {
    final s = context.s;
    final state = context.read<AppState>();
    final patient = state.session.patient;
    if (patient == null) {
      context.push('/login');
      return;
    }
    final procedure = Seed.procedureById(widget.procedureId);
    final request = state.submitSurgeryRequest(
      patientId: patient.id,
      procedure: procedure,
      estimateSnapshot: Fmt.money(procedure.price, s),
      preferredSurgeonId: _preferredSurgeonId,
      preferredFrom: _preferred?.start,
      preferredTo: _preferred?.end,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined,
            color: AppColors.success, size: 40),
        title: Text(s.surgeryRequestSubmitted),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.surgeryRequestSubmittedBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: Gap.md),
            SelectableText(
              '${s.complaintsReference}: ${request.reference}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
    if (mounted) context.pop();
  }
}

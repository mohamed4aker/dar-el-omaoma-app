import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../domain/models/operations.dart';

const _bloodGroups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

/// Deck slide 7: خدمات بنك الدم (PROMPT.md §6.9).
class BloodBankScreen extends StatelessWidget {
  const BloodBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.bloodBankTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: s.bloodBankRequest),
              Tab(text: s.bloodBankDonate),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_RequestTab(), _DonateTab()],
        ),
      ),
    );
  }
}

class _RequestTab extends StatefulWidget {
  const _RequestTab();

  @override
  State<_RequestTab> createState() => _RequestTabState();
}

class _RequestTabState extends State<_RequestTab> {
  String _group = 'O+';
  String _component = 'whole';
  int _units = 1;
  DateTime _requiredBy = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();

    final components = s.localeName == 'en'
        ? const {
            'whole': 'Whole blood',
            'rbc': 'Packed red cells',
            'platelets': 'Platelets',
            'plasma': 'Plasma',
          }
        : const {
            'whole': 'دم كامل',
            'rbc': 'كرات دم حمراء',
            'platelets': 'صفائح دموية',
            'plasma': 'بلازما',
          };

    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        SectionHeader(s.bloodGroup),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final group in _bloodGroups)
              ChoiceChip(
                label: Text(group, textDirection: TextDirection.ltr),
                selected: _group == group,
                onSelected: (_) => setState(() => _group = group),
              ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        SectionHeader(s.bloodComponent),
        DropdownButtonFormField<String>(
          initialValue: _component,
          items: [
            for (final entry in components.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (v) => setState(() => _component = v ?? _component),
        ),
        const SizedBox(height: Gap.lg),
        SectionHeader(s.bloodUnits),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed:
                  _units > 1 ? () => setState(() => _units--) : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                '$_units',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton.filledTonal(
              onPressed:
                  _units < 10 ? () => setState(() => _units++) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        SectionHeader(s.bloodRequiredBy),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _requiredBy,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
            );
            if (picked != null) setState(() => _requiredBy = picked);
          },
          icon: const Icon(Icons.event_outlined),
          label: Text(Fmt.date(_requiredBy, s)),
        ),
        const SizedBox(height: Gap.xl),
        FilledButton(
          onPressed: () async {
            final request = state.requestBlood(
              bloodGroup: _group,
              component: components[_component]!,
              units: _units,
              requiredBy: _requiredBy,
            );
            if (!context.mounted) return;
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                icon: const Icon(Icons.bloodtype,
                    color: AppColors.danger, size: 40),
                title: Text(s.bloodSubmitted),
                content: SelectableText(
                  '${s.complaintsReference}: ${request.reference}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.commonClose),
                  ),
                ],
              ),
            );
          },
          child: Text(s.bloodBankRequest),
        ),
        if (state.bloodRequests.isNotEmpty) ...[
          const SizedBox(height: Gap.xxl),
          SectionHeader(s.homeCareMyRequests),
          for (final request in state.bloodRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                child: Row(
                  children: [
                    StatusChip(request.bloodGroup, color: AppColors.danger),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${request.units} × ${request.component}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${request.reference} · '
                            '${Fmt.date(request.requiredBy, s)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _DonateTab extends StatefulWidget {
  const _DonateTab();

  @override
  State<_DonateTab> createState() => _DonateTabState();
}

class _DonateTabState extends State<_DonateTab> {
  String _group = 'O+';
  DateTime? _lastDonation;
  bool _acceptsAppeals = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final saved = state.donor;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        if (saved != null) ...[
          AppCard(
            borderColor: AppColors.success.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(saved.bloodGroup, color: AppColors.danger),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Text(s.bloodRegistered,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                if (saved.isEligibleAt(now))
                  InfoNote(s.bloodEligibleNow,
                      icon: Icons.check_circle_outline,
                      color: AppColors.success)
                else
                  InfoNote(
                    '${s.bloodNextEligible}: '
                    '${Fmt.date(saved.nextEligibleDate!, s)}',
                    icon: Icons.schedule,
                    color: AppColors.warning,
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
        ],
        SectionHeader(s.bloodGroup),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final group in _bloodGroups)
              ChoiceChip(
                label: Text(group, textDirection: TextDirection.ltr),
                selected: _group == group,
                onSelected: (_) => setState(() => _group = group),
              ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        SectionHeader(s.bloodLastDonation),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _lastDonation ??
                  DateTime.now().subtract(const Duration(days: 120)),
              firstDate: DateTime.now().subtract(const Duration(days: 1460)),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _lastDonation = picked);
          },
          icon: const Icon(Icons.event_outlined),
          label: Text(_lastDonation == null
              ? s.commonOptional
              : Fmt.date(_lastDonation!, s)),
        ),
        const SizedBox(height: Gap.lg),
        // Appeals target blood group and eligibility only, and only with the
        // donor's own opt-in (PROMPT.md §6.9).
        SwitchListTile(
          value: _acceptsAppeals,
          onChanged: (v) => setState(() => _acceptsAppeals = v),
          contentPadding: EdgeInsets.zero,
          title: Text(s.bloodAcceptAppeals,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: Gap.lg),
        FilledButton(
          onPressed: () {
            state.registerDonor(DonorProfile(
              bloodGroup: _group,
              lastDonation: _lastDonation,
              acceptsAppeals: _acceptsAppeals,
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.success,
                content: Text(s.bloodRegistered),
              ),
            );
          },
          child: Text(s.bloodBankDonate),
        ),
      ],
    );
  }
}

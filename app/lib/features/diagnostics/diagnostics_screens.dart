import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common.dart';
import '../../data/seed_data.dart';
import '../../domain/models/enums.dart';

/// Deck slide 6: أشعة تليفزيونية / عادية / مقطعية، الأسعار والمواعيد.
class RadiologyScreen extends StatefulWidget {
  const RadiologyScreen({super.key});

  @override
  State<RadiologyScreen> createState() => _RadiologyScreenState();
}

class _RadiologyScreenState extends State<RadiologyScreen> {
  RadiologyModality? _modality;

  String _modalityLabel(RadiologyModality m, AppStrings s) =>
      switch ((m, s.localeName)) {
        (RadiologyModality.ultrasound, 'en') => 'Ultrasound',
        (RadiologyModality.ultrasound, _) => 'أشعة تليفزيونية',
        (RadiologyModality.xray, 'en') => 'X-ray',
        (RadiologyModality.xray, _) => 'أشعة عادية',
        (RadiologyModality.ct, 'en') => 'CT',
        (RadiologyModality.ct, _) => 'أشعة مقطعية',
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final studies = Seed.radiology
        .where((r) => _modality == null || r.modality == _modality)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.radiologyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          SectionHeader(s.radiologyChooseType),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              ChoiceChip(
                label: Text(s.commonAll),
                selected: _modality == null,
                onSelected: (_) => setState(() => _modality = null),
              ),
              for (final m in RadiologyModality.values)
                ChoiceChip(
                  label: Text(_modalityLabel(m, s)),
                  selected: _modality == m,
                  onSelected: (v) =>
                      setState(() => _modality = v ? m : null),
                ),
            ],
          ),
          const SizedBox(height: Gap.xl),
          SectionHeader(s.radiologyPrices),
          for (final study in studies)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                onTap: () => _showPreparation(context, study.name(s.localeName),
                    study.preparation(s.localeName)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(study.name(s.localeName),
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ),
                        PriceText(study.price, currency: s.commonEgp),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: AppColors.muted),
                        const SizedBox(width: Gap.xs),
                        Expanded(
                          child: Text(
                            s.radiologyPreparation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Preparation instructions must be acknowledged before a radiology booking
  /// is confirmed (PROMPT.md 6.8).
  void _showPreparation(BuildContext context, String title, String body) {
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Gap.lg),
            InfoNote(body, color: AppColors.warning),
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.radiologyAcknowledgePrep),
            ),
            const SizedBox(height: Gap.sm),
          ],
        ),
      ),
    );
  }
}

/// Deck slide 7: أسعار التحاليل، نتائج التحاليل، العروض، خدمات بنك الدم.
class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.labTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: s.labPrices),
              Tab(text: s.labResults),
              Tab(text: s.bloodBankTitle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                for (final test in Seed.labTests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(test.name(s.localeName),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              PriceText(test.price, currency: s.commonEgp),
                            ],
                          ),
                          const SizedBox(height: Gap.sm),
                          Text(
                            '${s.labSample}: ${test.sample(s.localeName)} · '
                            '${s.labTurnaround}: ${test.turnaround(s.localeName)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const _ResultsTab(),
            ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                AppCard(
                  onTap: () {},
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bloodtype_outlined,
                        color: AppColors.danger),
                    title: Text(s.bloodBankRequest),
                  ),
                ),
                const SizedBox(height: Gap.md),
                AppCard(
                  onTap: () {},
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.volunteer_activism_outlined,
                        color: AppColors.pink),
                    title: Text(s.bloodBankDonate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(Seed.labTests.first.name(s.localeName),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  StatusChip(s.resultReady,
                      color: AppColors.success,
                      icon: Icons.check_circle_outline),
                ],
              ),
              const SizedBox(height: Gap.md),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined),
                label: Text(s.fileDocuments),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        // The critical-result gate: a result flagged critical is not released
        // to the patient until a clinician acknowledges it. This behaviour is
        // mandatory (PROMPT.md 6.9).
        AppCard(
          borderColor: AppColors.warning.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(Seed.labTests[1].name(s.localeName),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  StatusChip(s.resultWithheld,
                      color: AppColors.warning, icon: Icons.lock_outline),
                ],
              ),
              const SizedBox(height: Gap.md),
              InfoNote(s.resultWithheldBody, color: AppColors.warning),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Text(Seed.labTests[2].name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(s.resultPending,
                  color: AppColors.muted, icon: Icons.hourglass_empty),
            ],
          ),
        ),
      ],
    );
  }
}

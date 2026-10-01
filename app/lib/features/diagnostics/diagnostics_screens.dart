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

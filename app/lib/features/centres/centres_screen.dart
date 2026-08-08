import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/seed_data.dart';

/// Specialty centres (PROMPT.md 6.14).
///
/// The Surgery Centre is rendered by the same generic code as any future
/// centre — there is no branch anywhere in this file that names it.
class CentresScreen extends StatelessWidget {
  const CentresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.centresTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          for (final centre in Seed.centres.where((c) => c.isPublished))
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                onTap: () => context.push('/centres/${centre.id}'),
                borderColor: centre.accent.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(centre.name(s.localeName),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: Gap.sm),
                    Text(centre.description(s.localeName),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: Gap.md),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        for (final specialty in centre.specialties)
                          StatusChip(specialty(s.localeName),
                              color: centre.accent),
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
}

class CentreDetailScreen extends StatelessWidget {
  const CentreDetailScreen({required this.centreId, super.key});

  final String centreId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final centre = Seed.centres.firstWhere((c) => c.id == centreId);
    final clinics =
        Seed.clinics.where((c) => c.centreId == centreId).toList();
    final procedures =
        Seed.procedures.where((p) => p.centreId == centreId).toList();

    return Scaffold(
      appBar: AppBar(title: Text(centre.name(s.localeName))),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          Text(centre.description(s.localeName),
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: Gap.lg),
          SectionHeader(s.centreSpecialties),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final specialty in centre.specialties)
                StatusChip(specialty(s.localeName), color: centre.accent),
            ],
          ),
          const SizedBox(height: Gap.xl),
          SectionHeader(s.centreClinics),
          for (final clinic in clinics)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                onTap: () => context.push('/clinics/${clinic.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(clinic.name(s.localeName),
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Text(Fmt.money(clinic.consultationFee, s),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: Gap.sm),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Gap.lg),
          SectionHeader(s.centreProcedures),
          for (final procedure in procedures)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                onTap: () => context.push('/surgery/request/${procedure.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(procedure.name(s.localeName),
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    StatusChip(
                      Seed.classificationById(procedure.classificationId)
                          .name(s.localeName),
                      color: Seed.classificationById(procedure.classificationId)
                          .colour,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

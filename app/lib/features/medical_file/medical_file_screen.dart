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

/// Deck slide 4, with the maternity view from PROMPT.md 6.6.
class MedicalFileScreen extends StatelessWidget {
  const MedicalFileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final patient = state.session.patient;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.fileTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                message: s.guestBannerBody,
                icon: Icons.lock_outline,
              ),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: Text(s.moreSignIn),
              ),
            ],
          ),
        ),
      );
    }

    final pregnancy = patient.pregnancy;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(s.fileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.fullName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text('${s.homeMrn} ${patient.mrn}',
                    style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: Gap.xl),
                _Row(
                    label: s.fileBloodGroup,
                    value: patient.bloodGroup ?? '—'),
                _Row(
                  label: s.fileAllergies,
                  value: patient.allergies.isEmpty
                      ? '—'
                      : patient.allergies.join('، '),
                  emphasise: patient.allergies.isNotEmpty,
                ),
                _Row(
                  label: s.fileChronic,
                  value: patient.chronicConditions.isEmpty
                      ? '—'
                      : patient.chronicConditions.join('، '),
                ),
                _Row(
                    label: s.registerDob,
                    value: Fmt.date(patient.dateOfBirth, s)),
              ],
            ),
          ),
          if (pregnancy != null) ...[
            const SizedBox(height: Gap.lg),
            SectionHeader(s.fileMaternity),
            AppCard(
              borderColor: AppColors.pink.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.child_friendly_outlined,
                          color: AppColors.pink),
                      const SizedBox(width: Gap.sm),
                      Text(
                        '${s.fileGestationalAge}: '
                        '${pregnancy.gestationalWeeksAt(now)} '
                        '${s.localeName == 'en' ? 'weeks' : 'أسبوع'} '
                        '+ ${pregnancy.gestationalDaysRemainderAt(now)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  LinearProgressIndicator(
                    value: (pregnancy.gestationalWeeksAt(now) / 40)
                        .clamp(0.0, 1.0),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(Radii.pill),
                    color: AppColors.pink,
                    backgroundColor: AppColors.pinkTint,
                  ),
                  const SizedBox(height: Gap.md),
                  Text(
                    '${s.fileEdd}: '
                    '${Fmt.date(pregnancy.expectedDeliveryDate, s)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Gap.lg),
          SectionHeader(s.fileVisits),
          for (final appointment in state.appointments
              .where((a) => a.patientId == patient.id))
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Seed.clinics
                                .firstWhere((c) => c.id == appointment.clinicId)
                                .name(s.localeName),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${Fmt.date(appointment.range.start, s)} · '
                            '${Fmt.time(appointment.range.start)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Gap.lg),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(s.fileExport),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: emphasise ? AppColors.danger : null,
                    fontWeight: emphasise ? FontWeight.w700 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

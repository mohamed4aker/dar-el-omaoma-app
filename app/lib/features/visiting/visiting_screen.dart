import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/content.dart';

/// Visiting-experts programme (PROMPT.md 6.15).
///
/// Only campaigns whose expert holds valid authorisation to practise are
/// listed. The gate lives in [VisitingCampaign.isPublishableAt] and is applied
/// in [AppState.publishableCampaigns]; this screen never bypasses it.
class VisitingScreen extends StatelessWidget {
  const VisitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final campaigns = state.publishableCampaigns();

    return Scaffold(
      appBar: AppBar(title: Text(s.visitingTitle)),
      body: campaigns.isEmpty
          ? EmptyState(
              message: s.commonNoResults,
              icon: Icons.flight_takeoff_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                for (final campaign in campaigns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.lg),
                    child: _CampaignCard(campaign: campaign),
                  ),
              ],
            ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});

  final VisitingCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final host = Seed.doctorById(campaign.hostDoctorId);
    final registered = state.hasRegisteredInterest(campaign.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.navyTint,
                child: Icon(Icons.person_outline,
                    color: AppColors.navy, size: 28),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.expertName,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      '${campaign.expertInstitution(s.localeName)} · '
                      '${campaign.expertCountry(s.localeName)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(campaign.expertBio(s.localeName),
              style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: Gap.xl),
          _Row(
            icon: Icons.medical_information_outlined,
            label: s.centreSpecialties,
            value: campaign.specialty(s.localeName),
          ),
          _Row(
            icon: Icons.person_pin_outlined,
            label: s.visitingHost,
            value: host.name(s.localeName),
          ),
          _Row(
            icon: Icons.date_range_outlined,
            label: s.visitingWindow,
            value: '${Fmt.date(campaign.arrivesAt, s)} → '
                '${Fmt.date(campaign.departsAt, s)}',
          ),
          _Row(
            icon: Icons.event_seat_outlined,
            label: s.visitingSeats,
            value: '${campaign.seatsRemaining} / ${campaign.capacity}',
          ),
          const SizedBox(height: Gap.md),
          // Minimum viable cohort: the visit does not proceed below it, and
          // the coordinator tracks it live (PROMPT.md 6.15.1).
          if (!campaign.meetsMinimumCohort)
            InfoNote(
              s.localeName == 'en'
                  ? 'Confirmed places: ${campaign.registered} of ${campaign.minimumViableCohort} needed for the visit to proceed.'
                  : 'المسجّلون ${campaign.registered} من ${campaign.minimumViableCohort} المطلوبين لتأكيد الزيارة.',
              icon: Icons.groups_outlined,
              color: AppColors.warning,
            ),
          const SizedBox(height: Gap.lg),
          if (registered)
            InfoNote(
              s.visitingInterestDone,
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        context.read<AppState>().registerCampaignInterest(
                              campaign.id,
                            ),
                    child: Text(s.visitingRegisterInterest),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

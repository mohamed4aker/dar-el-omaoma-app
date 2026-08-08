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
import '../../domain/models/content.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/operations.dart';
import '../../domain/models/patient.dart';

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
          // the coordinator watches the count live (PROMPT.md 6.15.1).
          Builder(builder: (context) {
            final confirmed = state.confirmedCohort(campaign);
            final met = confirmed >= campaign.minimumViableCohort;
            return InfoNote(
              '${s.visitingCohortLive}: $confirmed / '
              '${campaign.minimumViableCohort}',
              icon: met ? Icons.groups : Icons.groups_outlined,
              color: met ? AppColors.success : AppColors.warning,
            );
          }),
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
                    onPressed: () => _register(context, addedByDoctor: false),
                    child: Text(s.visitingRegisterInterest),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _register(
                      context,
                      addedByDoctor: false,
                      withScreening: true,
                    ),
                    child: Text(s.visitingBookScreening),
                  ),
                ),
              ],
            ),

          // The host doctor gathers a cohort from their own practice. Same
          // pipeline, same list — only the origin differs (PROMPT.md 6.15.2).
          if (state.session.isDoctor &&
              state.session.doctorId == campaign.hostDoctorId) ...[
            const SizedBox(height: Gap.md),
            OutlinedButton.icon(
              onPressed: () => _addPatientAsDoctor(context),
              icon: const Icon(Icons.person_add_alt),
              label: Text(s.visitingAddPatient),
            ),
          ],

          Builder(builder: (context) {
            final pipeline = state.campaignPipeline(campaign.id);
            if (pipeline.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Gap.lg),
                Text(s.visitingPipeline,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Gap.sm),
                for (final entry in pipeline)
                  _PipelineRow(entry: entry),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _register(
    BuildContext context, {
    required bool addedByDoctor,
    bool withScreening = false,
  }) {
    final state = context.read<AppState>();
    final patient = state.session.patient;
    if (patient == null) {
      context.push('/login');
      return;
    }
    state.addToCampaign(
      campaignId: campaign.id,
      patient: patient,
      addedByDoctor: addedByDoctor,
      stage: withScreening
          ? VisitingStage.screeningBooked
          : VisitingStage.interestRegistered,
      screeningAt: withScreening
          ? DateTime.now().add(const Duration(days: 3))
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(withScreening
            ? context.s.visitingScreeningBooked
            : context.s.visitingInterestDone),
      ),
    );
  }

  Future<void> _addPatientAsDoctor(BuildContext context) async {
    final s = context.s;
    final state = context.read<AppState>();
    final picked = await showModalBottomSheet<Patient>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Text(s.theatreSelectPatient,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final patient in Seed.theatrePatients)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(patient.fullName),
                subtitle: Text(patient.mrn),
                onTap: () => Navigator.of(context).pop(patient),
              ),
            const SizedBox(height: Gap.lg),
          ],
        ),
      ),
    );
    if (picked == null) return;
    state.addToCampaign(
      campaignId: campaign.id,
      patient: picked,
      addedByDoctor: true,
      stage: VisitingStage.screeningBooked,
      screeningAt: DateTime.now().add(const Duration(days: 2)),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({required this.entry});

  final CampaignPatient entry;

  static const _ladder = [
    VisitingStage.interestRegistered,
    VisitingStage.screeningBooked,
    VisitingStage.screened,
    VisitingStage.shortlisted,
    VisitingStage.surgeryScheduled,
    VisitingStage.completed,
  ];

  String _stageLabel(VisitingStage stage, AppStrings s) => switch (stage) {
        VisitingStage.interestRegistered => s.visitingStageInterest,
        VisitingStage.screeningBooked => s.visitingStageScreening,
        VisitingStage.screened =>
          s.localeName == 'en' ? 'Screened' : 'تم الفرز',
        VisitingStage.shortlisted => s.visitingStageShortlisted,
        VisitingStage.surgeryScheduled => s.visitingStageScheduled,
        VisitingStage.waitlisted => s.visitingStageWaitlisted,
        VisitingStage.notEligible =>
          s.localeName == 'en' ? 'Not eligible' : 'غير مؤهل',
        VisitingStage.completed => s.statusCompleted,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.read<AppState>();
    final index = _ladder.indexOf(entry.stage);
    final next =
        index >= 0 && index < _ladder.length - 1 ? _ladder[index + 1] : null;

    return Padding(
      padding: const EdgeInsets.only(top: Gap.sm),
      child: AppCard(
        padding: const EdgeInsets.all(Gap.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.patientDisplayName,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    entry.addedByDoctor
                        ? s.visitingAddedByDoctor
                        : s.visitingSelfRegistered,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            StatusChip(
              _stageLabel(entry.stage, s),
              color: entry.countsTowardsCohort
                  ? AppColors.success
                  : AppColors.navy,
            ),
            if (next != null)
              IconButton(
                tooltip: s.visitingAdvance,
                onPressed: () =>
                    state.advanceCampaignPatient(entry.id, next),
                icon: const Icon(Icons.arrow_forward),
              ),
          ],
        ),
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

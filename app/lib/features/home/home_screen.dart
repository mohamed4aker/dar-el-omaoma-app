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
import '../contact/emergency_action.dart';

/// Deck slide 3.
///
/// The client's four tiles are kept exactly as specified: الرعاية المنزلية،
/// الشكاوى، نصائح طبية، العروض. Everything else on this screen is additive.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final session = state.session;
    final patient = session.patient;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.appName, style: const TextStyle(fontSize: 18)),
            Text(
              s.tagline,
              style: const TextStyle(fontSize: 11, color: AppColors.pink),
            ),
          ],
        ),
        actions: [
          Badge(
            isLabelVisible: state.notifications.isNotEmpty,
            label: Text('${state.notifications.length}'),
            child: IconButton(
              tooltip: s.moreNotifications,
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none),
            ),
          ),
          const EmergencyAction(),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xxl),
        children: [
          if (session.isGuest)
            const _GuestBanner()
          else if (patient != null)
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.navyTint,
                    child: Text(
                      patient.firstName.characters.first,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.homeGreeting}، ${patient.firstName}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('${s.homeMrn} ${patient.mrn}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Gap.lg),
          if (patient != null) ...[
            Builder(
              builder: (context) {
                final next = state.nextAppointmentFor(patient.id);
                if (next == null) return const SizedBox.shrink();
                final clinic = Seed.clinics
                    .firstWhere((c) => c.id == next.clinicId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: Gap.lg),
                  child: AppCard(
                    borderColor: AppColors.pink.withValues(alpha: 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event, size: 18,
                                color: AppColors.pink),
                            const SizedBox(width: Gap.sm),
                            Text(
                              s.homeNextAppointment,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.pink,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Gap.sm),
                        Text(clinic.name(s.localeName),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: Gap.xs),
                        Text(
                          '${Fmt.weekday(next.range.start, s)} '
                          '${Fmt.date(next.range.start, s)} · '
                          '${Fmt.time(next.range.start)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          SectionHeader(s.homeQuickServices),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: Gap.md,
            mainAxisSpacing: Gap.md,
            childAspectRatio: 1.15,
            children: [
              FeatureTile(
                label: s.homeCare,
                icon: Icons.home_work_outlined,
                color: AppColors.navy,
                onTap: () => context.push('/home-care'),
              ),
              FeatureTile(
                label: s.homeComplaints,
                icon: Icons.feedback_outlined,
                color: AppColors.warning,
                onTap: () => context.push('/complaints'),
              ),
              FeatureTile(
                label: s.homeTips,
                icon: Icons.lightbulb_outline,
                color: AppColors.success,
                onTap: () => context.push('/tips'),
              ),
              FeatureTile(
                label: s.homeOffers,
                icon: Icons.local_offer_outlined,
                color: AppColors.pink,
                onTap: () => context.push('/offers'),
              ),
            ],
          ),
          const SizedBox(height: Gap.xl),
          SectionHeader(s.servicesTitle),
          _ServiceRow(
            icon: Icons.local_hospital_outlined,
            label: s.serviceClinics,
            onTap: () => context.push('/clinics'),
          ),
          _ServiceRow(
            icon: Icons.monitor_heart_outlined,
            label: s.serviceRadiology,
            onTap: () => context.push('/radiology'),
          ),
          _ServiceRow(
            icon: Icons.biotech_outlined,
            label: s.serviceLab,
            onTap: () => context.push('/lab'),
          ),
          _ServiceRow(
            icon: Icons.healing_outlined,
            label: s.serviceSurgery,
            onTap: () => context.push('/surgery'),
          ),
          _ServiceRow(
            icon: Icons.apartment_outlined,
            label: s.serviceCentres,
            onTap: () => context.push('/centres'),
          ),
          _ServiceRow(
            icon: Icons.flight_takeoff_outlined,
            label: s.serviceVisitingExperts,
            onTap: () => context.push('/visiting'),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.lg, vertical: Gap.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.navyTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.navy),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AppCard(
      borderColor: AppColors.warning.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.guestBannerTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.xs),
          Text(s.guestBannerBody,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Gap.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: () => context.push('/login'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, kMinTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
              ),
              child: Text(s.guestBannerAction),
            ),
          ),
        ],
      ),
    );
  }
}

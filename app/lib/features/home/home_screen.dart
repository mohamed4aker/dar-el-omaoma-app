import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../contact/emergency_action.dart';

/// Deck slide 3, built around what the hospital actually offers in the app:
/// clinic booking, the laboratory and its offers, and the patient's own
/// bookings. Sections whose catalogue is empty do not appear.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final session = state.session;
    final patient = session.patient;
    final unread = state.myNotifications.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Gap.lg,
        title: Row(
          children: [
            const BrandMark(size: 36),
            const SizedBox(width: Gap.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('دار الأمومة', 'Dar El Omouma'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
                Text(s.tagline,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary)),
              ],
            ),
          ],
        ),
        actions: [
          if (!session.isGuest)
            Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
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
          if (session.isStaff)
            _StaffCard(name: session.staffName ?? '')
          else if (session.isGuest)
            const _GuestBanner()
          else if (patient != null)
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryTint,
                    child: Text(
                      patient.firstName.characters.first,
                      style: const TextStyle(
                        color: AppColors.primary,
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
          if (patient != null && !session.isStaff)
            Builder(builder: (context) {
              final next = state.nextAppointmentFor(patient.id);
              if (next == null) return const SizedBox.shrink();
              final clinic = Seed.clinicById(next.clinicId);
              final doctor = Seed.doctorById(next.doctorId);
              return Padding(
                padding: const EdgeInsets.only(bottom: Gap.lg),
                child: AppCard(
                  onTap: () => context.push('/bookings'),
                  borderColor: AppColors.accent.withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event,
                              size: 18, color: AppColors.accent),
                          const SizedBox(width: Gap.sm),
                          Text(
                            s.homeNextAppointment,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      Text(doctor.name(s.localeName),
                          style: Theme.of(context).textTheme.titleMedium),
                      if (clinic != null)
                        Text(clinic.name(s.localeName),
                            style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: Gap.xs),
                      Text(
                        '${Fmt.weekday(next.range.start, s)} '
                        '${Fmt.date(next.range.start, s)} · '
                        '${Fmt.clock(next.range.start, s)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: Gap.md,
            mainAxisSpacing: Gap.md,
            childAspectRatio: 1.25,
            children: [
              FeatureTile(
                label: context.tr('احجز في عيادة', 'Book a clinic'),
                icon: Icons.local_hospital_outlined,
                color: AppColors.primary,
                onTap: () => context.push('/clinics'),
              ),
              FeatureTile(
                label: context.tr('المعمل والتحاليل', 'Lab & tests'),
                icon: Icons.biotech_outlined,
                color: AppColors.accent,
                onTap: () => context.push('/lab'),
              ),
              if (session.isStaff)
                FeatureTile(
                  label: context.tr('الحجوزات', 'Bookings'),
                  icon: Icons.event_note_outlined,
                  color: AppColors.success,
                  onTap: () => context.push('/admin/bookings'),
                )
              else
                FeatureTile(
                  label: s.bookingsTitle,
                  icon: Icons.event_note_outlined,
                  color: AppColors.success,
                  onTap: () => context.push('/bookings'),
                ),
              FeatureTile(
                label: s.contactTitle,
                icon: Icons.call_outlined,
                color: AppColors.warning,
                onTap: () => context.push('/contact'),
              ),
            ],
          ),
          if (Seed.labPackages.any((p) => p.isActive)) ...[
            const SizedBox(height: Gap.xl),
            Row(
              children: [
                Expanded(
                    child: SectionHeader(
                        context.tr('عروض المعمل', 'Lab offers'))),
                TextButton(
                  onPressed: () => context.push('/lab'),
                  child: Text(context.tr('الكل', 'All')),
                ),
              ],
            ),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Seed.labPackages.where((p) => p.isActive).length,
                separatorBuilder: (_, _) => const SizedBox(width: Gap.md),
                itemBuilder: (context, i) {
                  final p = Seed.labPackages.where((p) => p.isActive).toList()[i];
                  return SizedBox(
                    width: 220,
                    child: AppCard(
                      onTap: () => context.push('/lab'),
                      borderColor: AppColors.brandPink.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name(s.localeName),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall),
                          const Spacer(),
                          Text(Fmt.money(p.price, s),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.primary)),
                          if (p.priceBefore > p.price)
                            Text(
                              '${context.tr('بدلًا من', 'instead of')} ${Fmt.money(p.priceBefore, s)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      decoration: TextDecoration.lineThrough),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: Gap.xl),
          SectionHeader(context.tr('خدمات أخرى', 'More services')),
          ..._otherServices(context),
        ],
      ),
    );
  }

  List<Widget> _otherServices(BuildContext context) {
    final s = context.s;
    return [
      if (Seed.procedures.any((p) => p.patientRequestable))
        _ServiceRow(
          icon: Icons.healing_outlined,
          label: s.serviceSurgery,
          onTap: () => context.push('/surgery'),
        ),
      if (Seed.radiology.isNotEmpty)
        _ServiceRow(
          icon: Icons.monitor_heart_outlined,
          label: s.serviceRadiology,
          onTap: () => context.push('/radiology'),
        ),
      if (Seed.tips.isNotEmpty)
        _ServiceRow(
          icon: Icons.lightbulb_outline,
          label: s.homeTips,
          onTap: () => context.push('/tips'),
        ),
      if (Seed.offers.isNotEmpty)
        _ServiceRow(
          icon: Icons.local_offer_outlined,
          label: s.homeOffers,
          onTap: () => context.push('/offers'),
        ),
      _ServiceRow(
        icon: Icons.feedback_outlined,
        label: s.homeComplaints,
        onTap: () => context.push('/complaints'),
      ),
    ];
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
        padding:
            const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.accent.withValues(alpha: 0.45),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: AppColors.accent, size: 32),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  context.tr('داخل كموظف — الحجوزات اللي بتعملها بتبقى باسم المريض اللي تختاره.',
                      'Signed in as staff — bookings you make are for the patient you choose.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
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
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.guestBannerTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.xs),
          Text(s.guestBannerBody,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              FilledButton(
                onPressed: () => context.push('/register'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                  padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
                ),
                child: Text(s.welcomeRegister),
              ),
              const SizedBox(width: Gap.sm),
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(s.guestBannerAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

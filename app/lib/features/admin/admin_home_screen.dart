import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../more/more_screen.dart' show showChangePasswordDialog;

/// Admin console home (PROMPT.md §14).
///
/// Lives inside the same application, revealed by the `admin` role. The
/// layout adapts: a single column on a phone, a wider grid on a desktop
/// browser, which is where this section is actually used day to day.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000 ? 4 : (width >= 640 ? 3 : 2);
    // Wider tiles get shorter, or a desktop browser shows a grid of mostly
    // empty cards.
    final aspectRatio = switch (columns) {
      4 => 1.6,
      3 => 1.35,
      _ => 1.05,
    };

    final today = Seed.today;
    final todaysBookings = state
        .allBookings()
        .where((r) =>
            r.at.year == today.year &&
            r.at.month == today.month &&
            r.at.day == today.day)
        .length;

    final groups = <(String, List<_Section>)>[
      (
        context.tr('الاستقبال', 'Reception'),
        [
          _Section(
            icon: Icons.event_note_outlined,
            label: context.tr('حجوزات اليوم', "Today's bookings"),
            count: todaysBookings,
            colour: AppColors.primary,
            route: '/admin/bookings',
          ),
          _Section(
            icon: Icons.people_alt_outlined,
            label: context.tr('المرضى', 'Patients'),
            count: state.patients.length,
            colour: AppColors.accent,
            route: '/admin/patients',
          ),
          _Section(
            icon: Icons.feedback_outlined,
            label: context.tr('شكاوى مفتوحة', 'Open complaints'),
            count: state.complaints.where((c) => !c.isResolved).length,
            colour: AppColors.warning,
            route: '/admin/complaints',
          ),
          _Section(
            icon: Icons.notifications_none,
            label: s.moreNotifications,
            count: state.myNotifications.length,
            colour: AppColors.muted,
            route: '/notifications',
          ),
        ],
      ),
      (
        context.tr('بيانات المستشفى', 'Hospital data'),
        [
          _Section(
            icon: Icons.local_hospital_outlined,
            label: s.adminClinics,
            count: Seed.clinics.length,
            colour: AppColors.primary,
            route: '/admin/clinics',
          ),
          _Section(
            icon: Icons.badge_outlined,
            label: s.adminDoctors,
            count: Seed.doctors.length,
            colour: AppColors.success,
            route: '/admin/doctors',
          ),
          _Section(
            icon: Icons.biotech_outlined,
            label: context.tr('التحاليل والأسعار', 'Lab tests & prices'),
            count: Seed.labTests.where((t) => t.isActive).length,
            colour: AppColors.accent,
            route: '/admin/lab-tests',
          ),
          _Section(
            icon: Icons.local_offer_outlined,
            label: context.tr('عروض المعمل', 'Lab offers'),
            count: Seed.labPackages.where((p) => p.isActive).length,
            colour: AppColors.primary,
            route: '/admin/lab-packages',
          ),
          _Section(
            icon: Icons.campaign_outlined,
            label: s.adminOffers,
            count: Seed.offers.length,
            colour: AppColors.accent,
            route: '/admin/offers',
          ),
          _Section(
            icon: Icons.lightbulb_outline,
            label: s.adminTips,
            count: Seed.tips.length,
            colour: AppColors.success,
            route: '/admin/tips',
          ),
        ],
      ),
      (
        context.tr('العمليات', 'Operating theatres'),
        [
          _Section(
            icon: Icons.meeting_room_outlined,
            label: s.adminTheatres,
            count: Seed.theatres.length,
            colour: AppColors.warning,
            route: '/admin/theatres',
          ),
          _Section(
            icon: Icons.healing_outlined,
            label: s.adminProcedures,
            count: Seed.procedures.length,
            colour: AppColors.primary,
            route: '/admin/procedures',
          ),
          _Section(
            icon: Icons.category_outlined,
            label: s.adminClassifications,
            count: Seed.classifications.where((c) => c.isActive).length,
            colour: AppColors.accent,
            route: '/admin/classifications',
          ),
          _Section(
            icon: Icons.fact_check_outlined,
            label: s.approvalsTitle,
            count: state.pendingApprovals.length,
            colour: AppColors.danger,
            route: '/approvals',
          ),
          _Section(
            icon: Icons.event_available_outlined,
            label: s.theatreAvailability,
            count: state.casesOn(Seed.today).length,
            colour: AppColors.primary,
            route: '/theatre',
          ),
        ],
      ),
      (
        context.tr('الإدارة', 'Administration'),
        [
          _Section(
            icon: Icons.manage_accounts_outlined,
            label: s.adminUsers,
            count: state.staff.where((u) => u.isActive).length,
            colour: AppColors.primary,
            route: '/admin/users',
          ),
          _Section(
            icon: Icons.tune,
            label: s.adminPolicy,
            count: state.policy.doctorsBookTheatreDirectly ? 1 : 0,
            colour: AppColors.accent,
            route: '/admin/policy',
          ),
          _Section(
            icon: Icons.history,
            label: s.adminAudit,
            count: state.auditLog.length,
            colour: AppColors.muted,
            route: '/admin/audit',
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.adminConsole, style: const TextStyle(fontSize: 18)),
            Text(state.session.staffName ?? s.appName,
                style: const TextStyle(fontSize: 11, color: AppColors.accent)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          if (state.adminUsesDefaultPassword) ...[
            AppCard(
              borderColor: AppColors.danger.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(context.tr(
                        'حساب الأدمن لسه بكلمة المرور الافتراضية. غيّرها دلوقتي.',
                        'The admin account still uses the default password. Change it now.')),
                  ),
                  TextButton(
                    onPressed: () => showChangePasswordDialog(context),
                    child: Text(context.tr('تغيير', 'Change')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
          ],
          InfoNote(s.adminHomeNote, icon: Icons.admin_panel_settings_outlined),
          for (final (title, sections) in groups) ...[
            const SizedBox(height: Gap.xl),
            SectionHeader(title),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: Gap.md,
              mainAxisSpacing: Gap.md,
              childAspectRatio: aspectRatio,
              children: [
                for (final section in sections) _SectionTile(section: section),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Section {
  const _Section({
    required this.icon,
    required this.label,
    required this.count,
    required this.colour,
    required this.route,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color colour;
  final String route;
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(section.route),
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: section.colour.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(section.icon, color: section.colour, size: 22),
          ),
          const Spacer(),
          Text(
            '${section.count}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: section.colour,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            section.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

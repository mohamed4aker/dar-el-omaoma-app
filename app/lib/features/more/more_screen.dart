import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/launch.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../auth/welcome_screen.dart' show DeveloperInfo;

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(s.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          _Group(
            title: s.moreLanguage,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ar', label: Text('العربية')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {state.localeCode},
              onSelectionChanged: (set) =>
                  state.locale = Locale(set.first),
            ),
          ),
          _Group(
            title: s.moreAppearance,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                    value: ThemeMode.system, label: Text(s.themeSystem)),
                ButtonSegment(
                    value: ThemeMode.light, label: Text(s.themeLight)),
                ButtonSegment(
                    value: ThemeMode.dark, label: Text(s.themeDark)),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (set) => state.themeMode = set.first,
            ),
          ),
          const SizedBox(height: Gap.lg),
          if (state.session.patient != null && !state.session.isStaff)
            _Tile(
              icon: Icons.event_note_outlined,
              label: s.bookingsTitle,
              onTap: () => context.push('/bookings'),
            ),
          if (state.session.isSignedIn)
            _Tile(
              icon: Icons.notifications_outlined,
              label: s.moreNotifications,
              onTap: () => context.push('/notifications'),
            ),
          _Tile(
            icon: Icons.call_outlined,
            label: s.contactTitle,
            onTap: () => context.push('/contact'),
          ),
          if (state.session.isStaff)
            _Tile(
              icon: Icons.password_outlined,
              label: context.tr('تغيير كلمة المرور', 'Change password'),
              onTap: () => showChangePasswordDialog(context),
            ),
          _Tile(
            icon: Icons.info_outline,
            label: s.moreAbout,
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: Gap.lg),
          if (state.session.isSignedIn)
            OutlinedButton.icon(
              onPressed: () {
                state.signOut();
                context.go('/welcome');
              },
              icon: const Icon(Icons.logout),
              label: Text(s.moreSignOut),
            )
          else ...[
            FilledButton(
              onPressed: () => context.push('/login'),
              child: Text(s.moreSignIn),
            ),
            const SizedBox(height: Gap.sm),
            TextButton.icon(
              onPressed: () => context.push('/staff-login'),
              icon: const Icon(Icons.badge_outlined),
              label: Text(context.tr('دخول الموظفين', 'Staff sign-in')),
            ),
          ],
          const SizedBox(height: Gap.xl),
          const DeveloperCard(),
        ],
      ),
    );
  }
}

/// Who built the app and how to reach them for support.
class DeveloperCard extends StatelessWidget {
  const DeveloperCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('تصميم وتطوير التطبيق', 'Designed and developed by'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Gap.xs),
          Text('${DeveloperInfo.companyName} — ${DeveloperInfo.engineer}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.accent)),
          Text(DeveloperInfo.supportPhone,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Launch.call(context, DeveloperInfo.supportPhone),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text(context.tr('اتصال', 'Call')),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Launch.whatsapp(
                      context, DeveloperInfo.supportPhone,
                      text: context.tr('السلام عليكم، بخصوص تطبيق مستشفى دار الأمومة',
                          'Hello, about the Dar El Omouma app')),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: Text(context.tr('واتساب', 'WhatsApp')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// About screen — the primary developer-attribution placement
/// (PROMPT.md section 2.5).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.moreAbout)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            child: Column(
              children: [
                const BrandLockup(markSize: 96),
                const SizedBox(height: Gap.md),
                Text(s.tagline,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.accent)),
                const SizedBox(height: Gap.sm),
                Text('v1.1.0',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          const DeveloperCard(),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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
            Icon(icon, color: AppColors.primary),
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

/// Changes the signed-in staff member's password.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final current = TextEditingController();
  final next = TextEditingController();
  final repeat = TextEditingController();
  String? error;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.tr('تغيير كلمة المرور', 'Change password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: context.tr('كلمة المرور الحالية', 'Current password')),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: next,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: context.tr('كلمة المرور الجديدة (6 حروف على الأقل)',
                      'New password (at least 6 characters)')),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: repeat,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: context.tr('أعد كتابتها', 'Repeat it')),
            ),
            if (error != null) ...[
              const SizedBox(height: Gap.md),
              Text(error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.s.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              if (next.text.length < 6) {
                setState(() => error = context.tr(
                    'كلمة المرور قصيرة.', 'Password is too short.'));
                return;
              }
              if (next.text != repeat.text) {
                setState(() => error = context.tr(
                    'كلمتا المرور غير متطابقتين.', 'Passwords do not match.'));
                return;
              }
              final ok = context.read<AppState>().changeOwnPassword(
                  current: current.text, next: next.text);
              if (!ok) {
                setState(() => error = context.tr(
                    'كلمة المرور الحالية غير صحيحة.',
                    'Current password is wrong.'));
                return;
              }
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(context.tr(
                      'تم تغيير كلمة المرور', 'Password changed'))));
            },
            child: Text(context.tr('حفظ', 'Save')),
          ),
        ],
      ),
    ),
  );
}

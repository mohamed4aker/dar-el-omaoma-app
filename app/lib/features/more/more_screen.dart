import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
          _Tile(
            icon: Icons.call_outlined,
            label: s.contactTitle,
            onTap: () => context.push('/contact'),
          ),
          _Tile(
            icon: Icons.notifications_outlined,
            label: s.moreNotifications,
            onTap: () {},
          ),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            label: s.morePrivacy,
            onTap: () {},
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
          else
            FilledButton(
              onPressed: () => context.push('/login'),
              child: Text(s.moreSignIn),
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
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.navyTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pink, width: 2),
                  ),
                  child: const Icon(Icons.pregnant_woman_outlined,
                      size: 38, color: AppColors.navy),
                ),
                const SizedBox(height: Gap.md),
                Text(s.appName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(s.tagline,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.pink)),
                const SizedBox(height: Gap.sm),
                Text('v0.1.0',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.aboutDevelopedBy,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: Gap.xs),
                Text(DeveloperInfo.companyName,
                    style: Theme.of(context).textTheme.titleLarge),
                const Divider(height: Gap.xl),
                _Line(
                  icon: Icons.language,
                  value: DeveloperInfo.website,
                  onTap: () {},
                ),
                _Line(
                  icon: Icons.support_agent_outlined,
                  value: DeveloperInfo.supportPhone,
                  onTap: () {},
                ),
                _Line(
                  icon: Icons.mail_outline,
                  value: DeveloperInfo.supportEmail,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.value, required this.onTap});

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.sm),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(value,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
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
            Icon(icon, color: AppColors.navy),
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

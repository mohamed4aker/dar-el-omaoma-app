import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/app_state.dart';

/// Deck slide 1: brand, "تسجيل دخول", "إنشاء حساب", plus the guest route.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.navyDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.xl),
            child: Column(
              children: [
                const Spacer(),
                const _BrandMark(),
                const SizedBox(height: Gap.xl),
                Text(
                  s.brandLine,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  s.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.push('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(s.welcomeLogin),
                ),
                const SizedBox(height: Gap.md),
                OutlinedButton(
                  onPressed: () => context.push('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: Text(s.welcomeRegister),
                ),
                const SizedBox(height: Gap.sm),
                TextButton(
                  onPressed: () {
                    context.read<AppState>().signOut();
                    context.go('/home');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.85),
                    minimumSize: const Size.fromHeight(kMinTouchTarget),
                  ),
                  child: Text(s.welcomeGuest),
                ),
                const SizedBox(height: Gap.sm),
                // Developer attribution, login footer placement.
                // PROMPT.md section 2.5.
                TextButton(
                  onPressed: () => context.push('/about'),
                  child: Text(
                    '${s.aboutDevelopedBy} ${DeveloperInfo.companyName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    // Placeholder for the official vector mark, which must replace this before
    // production (PROMPT.md section 2.2).
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pink, width: 3),
      ),
      child: const Icon(
        Icons.pregnant_woman_outlined,
        size: 56,
        color: Colors.white,
      ),
    );
  }
}

/// Developer attribution content (PROMPT.md section 2.5).
///
/// Replace these values with the real company details. They are centralised
/// here so attribution appears identically everywhere it is permitted, and
/// nowhere it is not.
abstract final class DeveloperInfo {
  static const companyName = 'Your Company Name';
  static const website = 'https://example.com';
  static const supportPhone = '+20 100 000 0000';
  static const supportEmail = 'support@example.com';
}

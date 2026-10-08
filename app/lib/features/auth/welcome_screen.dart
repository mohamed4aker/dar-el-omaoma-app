import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/brand.dart';
import '../../data/app_state.dart';

/// Deck slide 1: brand, "تسجيل دخول", "إنشاء حساب", plus the guest route.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            children: [
              const Spacer(),
              const BrandLockup(markSize: 132),
              const SizedBox(height: Gap.lg),
              Text(
                s.tagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.push('/register'),
                child: Text(s.welcomeRegister),
              ),
              const SizedBox(height: Gap.md),
              OutlinedButton(
                onPressed: () => context.push('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: Text(s.welcomeLogin),
              ),
              const SizedBox(height: Gap.sm),
              TextButton(
                onPressed: () {
                  context.read<AppState>().signOut();
                  context.go('/home');
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(kMinTouchTarget),
                ),
                child: Text(s.welcomeGuest),
              ),
              const SizedBox(height: Gap.sm),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/staff-login'),
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: Text(context.tr('دخول الموظفين', 'Staff sign-in')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                  ),
                  // Developer attribution, login footer placement.
                  // PROMPT.md section 2.5.
                  TextButton(
                    onPressed: () => context.push('/about'),
                    child: Text(
                      '${s.aboutDevelopedBy} ${DeveloperInfo.companyName} — '
                      '${DeveloperInfo.engineer} — ${DeveloperInfo.supportPhone}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Developer attribution (PROMPT.md section 2.5): one line on this screen,
/// and a card with call and WhatsApp in "More" and "About".
abstract final class DeveloperInfo {
  static const companyName = 'MAS';
  static const engineer = 'م. محمد أحمد شاكر';
  static const website = '';
  static const supportPhone = '01068287355';
  static const supportEmail = '';
}

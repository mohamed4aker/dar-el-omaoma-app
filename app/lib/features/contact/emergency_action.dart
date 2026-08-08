import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common.dart';
import '../../data/seed_data.dart';

/// Persistent emergency action, reachable from every Home-tab screen
/// (PROMPT.md section 5).
class EmergencyAction extends StatelessWidget {
  const EmergencyAction({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return TextButton.icon(
      onPressed: () => showEmergencySheet(context),
      icon: const Icon(Icons.emergency_outlined, size: 18),
      label: Text(s.emergencyCall),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.danger,
        minimumSize: const Size(0, kMinTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: Gap.md),
      ),
    );
  }
}

Future<void> showEmergencySheet(BuildContext context) {
  final s = AppStrings.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.emergencyTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Gap.lg),
          AppCard(
            borderColor: AppColors.danger.withValues(alpha: 0.5),
            child: Column(
              children: [
                const Icon(Icons.phone_in_talk,
                    size: 36, color: AppColors.danger),
                const SizedBox(height: Gap.md),
                const Text(
                  Seed.emergencyPhone,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          FilledButton.icon(
            onPressed: () {
              // Production: launch tel: via url_launcher. Kept as a no-op in
              // this build so the demo never dials a real number.
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.call),
            label: Text(s.contactCall),
          ),
          const SizedBox(height: Gap.md),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.local_shipping_outlined),
            label: Text(s.contactAmbulance),
          ),
          const SizedBox(height: Gap.lg),
          InfoNote(s.contactAmbulanceNote, color: AppColors.warning),
          const SizedBox(height: Gap.sm),
        ],
      ),
    ),
  );
}

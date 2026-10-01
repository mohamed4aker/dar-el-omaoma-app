import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/launch.dart';
import '../../core/widgets/common.dart';
import '../../data/seed_data.dart';
import 'emergency_action.dart';

/// Deck slide 8.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.contactTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            onTap: () => showEmergencySheet(context),
            borderColor: AppColors.danger.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.emergency, color: AppColors.danger, size: 30),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.emergencyTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Text(
                        Seed.emergencyPhone,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          _Channel(
            icon: Icons.call_outlined,
            label: s.contactCall,
            value: Seed.emergencyPhone,
            onTap: () => Launch.call(context, Seed.emergencyPhone),
          ),
          _Channel(
            icon: Icons.chat_outlined,
            label: s.contactWhatsapp,
            value: Seed.whatsappPhone,
            onTap: () => Launch.whatsapp(context, Seed.whatsappPhone),
          ),
          _Channel(
            icon: Icons.biotech_outlined,
            label: context.tr('المعمل — للحجز والاستفسار',
                'Laboratory — bookings and enquiries'),
            value: Seed.labPhone,
            onTap: () => Launch.call(context, Seed.labPhone),
          ),
          _Channel(
            icon: Icons.location_on_outlined,
            label: s.contactDirections,
            value: s.localeName == 'en'
                ? 'Dar El Omouma Hospital'
                : 'مستشفى دار الأمومة',
            onTap: () => Launch.url(context,
                'https://www.google.com/maps/search/?api=1&query=%D9%85%D8%B3%D8%AA%D8%B4%D9%81%D9%89+%D8%AF%D8%A7%D8%B1+%D8%A7%D9%84%D8%A3%D9%85%D9%88%D9%85%D8%A9'),
          ),
        ],
      ),
    );
  }
}

class _Channel extends StatelessWidget {
  const _Channel({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(value,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

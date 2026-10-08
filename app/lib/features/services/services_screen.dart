import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/catalog.dart';
import 'hospital_services.dart';

/// Every department, then the hospital's other patient-facing pages.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    final more = <(IconData, String, String)>[
      if (Seed.hasPrices(PriceService.outpatient))
        (Icons.receipt_long_outlined,
            context.tr('أسعار الكشوفات والإجراءات', 'Clinic procedure prices'),
            '/prices/${PriceService.outpatient}'),
      if (Seed.centres.any((c) => c.isPublished))
        (Icons.apartment_outlined, s.serviceCentres, '/centres'),
      if (Seed.offers.isNotEmpty)
        (Icons.local_offer_outlined, s.homeOffers, '/offers'),
      if (Seed.tips.isNotEmpty) (Icons.lightbulb_outline, s.homeTips, '/tips'),
      (Icons.feedback_outlined, s.homeComplaints, '/complaints'),
      (Icons.call_outlined, s.contactTitle, '/contact'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.servicesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          const ServicesGrid(),
          const SizedBox(height: Gap.lg),
          for (final (icon, label, route) in more)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: AppCard(
                onTap: () => context.push(route),
                padding: const EdgeInsets.symmetric(
                    horizontal: Gap.lg, vertical: Gap.md),
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
            ),
        ],
      ),
    );
  }
}

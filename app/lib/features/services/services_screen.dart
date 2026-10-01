import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';

/// Every patient-facing service. A service appears once the hospital has
/// something in it: an empty "Radiology" tile is worse than none.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    final items = <(IconData, String, String, Color)>[
      (Icons.local_hospital_outlined, s.serviceClinics, '/clinics',
          AppColors.primary),
      (Icons.biotech_outlined, context.tr('المعمل والتحاليل', 'Lab & tests'),
          '/lab', AppColors.accent),
      if (Seed.radiology.isNotEmpty)
        (Icons.monitor_heart_outlined, s.serviceRadiology, '/radiology',
            AppColors.primary),
      if (Seed.procedures.any((p) => p.patientRequestable))
        (Icons.healing_outlined, s.serviceSurgery, '/surgery',
            AppColors.warning),
      if (Seed.centres.any((c) => c.isPublished))
        (Icons.apartment_outlined, s.serviceCentres, '/centres',
            AppColors.accent),
      if (Seed.campaigns.isNotEmpty)
        (Icons.flight_takeoff_outlined, s.serviceVisitingExperts, '/visiting',
            AppColors.primary),
      if (Seed.homeCareServices.isNotEmpty)
        (Icons.home_work_outlined, s.homeCare, '/home-care', AppColors.success),
      if (Seed.offers.isNotEmpty)
        (Icons.local_offer_outlined, s.homeOffers, '/offers', AppColors.accent),
      if (Seed.tips.isNotEmpty)
        (Icons.lightbulb_outline, s.homeTips, '/tips', AppColors.success),
      (Icons.feedback_outlined, s.homeComplaints, '/complaints',
          AppColors.warning),
      (Icons.call_outlined, s.contactTitle, '/contact', AppColors.primary),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.servicesTitle)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(Gap.lg),
        crossAxisSpacing: Gap.md,
        mainAxisSpacing: Gap.md,
        childAspectRatio: 1.1,
        children: [
          for (final (icon, label, route, color) in items)
            FeatureTile(
              icon: icon,
              label: label,
              color: color,
              onTap: () => context.push(route),
            ),
        ],
      ),
    );
  }
}

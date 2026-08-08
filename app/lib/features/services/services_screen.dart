import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = <(IconData, String, String, Color)>[
      (Icons.local_hospital_outlined, s.serviceClinics, '/clinics',
          AppColors.navy),
      (Icons.monitor_heart_outlined, s.serviceRadiology, '/radiology',
          AppColors.pink),
      (Icons.biotech_outlined, s.serviceLab, '/lab', AppColors.success),
      (Icons.healing_outlined, s.serviceSurgery, '/surgery',
          AppColors.warning),
      (Icons.apartment_outlined, s.serviceCentres, '/centres',
          AppColors.navy),
      (Icons.flight_takeoff_outlined, s.serviceVisitingExperts, '/visiting',
          AppColors.pink),
      (Icons.home_work_outlined, s.homeCare, '/home-care', AppColors.success),
      (Icons.local_offer_outlined, s.homeOffers, '/offers', AppColors.pink),
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

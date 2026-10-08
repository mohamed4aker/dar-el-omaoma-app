import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/launch.dart';
import '../../data/seed_data.dart';
import '../../domain/models/catalog.dart';

/// One of the hospital's departments as the patient meets it on the home
/// screen.
///
/// A department the app holds data for opens its screen. One it does not
/// (yet) — the blood bank, say — opens a WhatsApp chat with the hospital,
/// with the question already typed, rather than an empty page.
class HospitalService {
  const HospitalService({
    required this.ar,
    required this.en,
    required this.icon,
    required this.color,
    this.route,
  });

  final String ar;
  final String en;
  final IconData icon;
  final Color color;

  /// Null when there is nothing to show: the tile opens WhatsApp.
  final String? route;

  bool get opensWhatsapp => route == null;

  String label(BuildContext context) => context.tr(ar, en);

  void open(BuildContext context) {
    final r = route;
    if (r != null) {
      context.push(r);
    } else {
      askOnWhatsapp(context, ar);
    }
  }
}

/// Opens the hospital's services WhatsApp with an enquiry about [topic].
Future<void> askOnWhatsapp(BuildContext context, String topic) =>
    Launch.whatsapp(
      context,
      Seed.servicesWhatsapp,
      text: 'السلام عليكم، عايز أستفسر عن $topic في مستشفى دار الأمومة.',
    );

/// The departments, in the order the hospital lists them.
List<HospitalService> hospitalServices() {
  String? ifPrices(String service, String route) =>
      Seed.hasPrices(service) ? route : null;

  return [
    HospitalService(
      ar: 'العيادات الخارجية',
      en: 'Outpatient clinics',
      icon: Icons.local_hospital_outlined,
      color: AppColors.primary,
      route: Seed.clinics.isNotEmpty ? '/clinics' : null,
    ),
    HospitalService(
      ar: 'الأشعة',
      en: 'Radiology',
      icon: Icons.monitor_heart_outlined,
      color: AppColors.accent,
      route: ifPrices(PriceService.radiology, '/radiology'),
    ),
    HospitalService(
      ar: 'العلاج الطبيعي',
      en: 'Physiotherapy',
      icon: Icons.accessibility_new_outlined,
      color: AppColors.success,
      route: ifPrices(PriceService.physio, '/prices/${PriceService.physio}'),
    ),
    HospitalService(
      ar: 'التحاليل',
      en: 'Laboratory',
      icon: Icons.biotech_outlined,
      color: AppColors.primary,
      route: Seed.labTests.isNotEmpty || Seed.labPackages.isNotEmpty
          ? '/lab'
          : null,
    ),
    const HospitalService(
      ar: 'بنك الدم',
      en: 'Blood bank',
      icon: Icons.bloodtype_outlined,
      color: AppColors.danger,
    ),
    HospitalService(
      ar: 'القسم الداخلي',
      en: 'Inpatient',
      icon: Icons.bed_outlined,
      color: AppColors.accent,
      route:
          ifPrices(PriceService.inpatient, '/prices/${PriceService.inpatient}'),
    ),
    HospitalService(
      ar: 'الطوارئ',
      en: 'Emergency',
      icon: Icons.emergency_outlined,
      color: AppColors.danger,
      route:
          ifPrices(PriceService.emergency, '/prices/${PriceService.emergency}'),
    ),
    HospitalService(
      ar: 'الإسعاف',
      en: 'Ambulance',
      icon: Icons.airport_shuttle_outlined,
      color: AppColors.warning,
      route:
          ifPrices(PriceService.ambulance, '/prices/${PriceService.ambulance}'),
    ),
    HospitalService(
      ar: 'الرعاية المنزلية',
      en: 'Home care',
      icon: Icons.home_work_outlined,
      color: AppColors.success,
      route: ifPrices(PriceService.homecare, '/prices/${PriceService.homecare}'),
    ),
    HospitalService(
      ar: 'برنامج الخبراء الزائرين',
      en: 'Visiting experts',
      icon: Icons.flight_land_outlined,
      color: AppColors.primary,
      route: Seed.campaigns.isNotEmpty ? '/visiting' : null,
    ),
    HospitalService(
      ar: 'العمليات',
      en: 'Surgery',
      icon: Icons.healing_outlined,
      color: AppColors.warning,
      route: Seed.surgeryPackages.any((p) => p.isActive)
          ? '/surgery-prices'
          : null,
    ),
  ];
}

/// The departments as a grid of tiles, three to a row.
class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final services = hospitalServices();
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 520 ? 4 : 3;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: Gap.sm,
        mainAxisSpacing: Gap.sm,
        childAspectRatio: 0.92,
        children: [
          for (final s in services) ServiceTile(service: s),
        ],
      );
    });
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({required this.service, super.key});

  final HospitalService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => service.open(context),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Gap.xs, Gap.md, Gap.xs, Gap.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: service.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(service.icon, color: service.color, size: 26),
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    service.label(context),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                  ),
                ],
              ),
            ),
            if (service.opensWhatsapp)
              PositionedDirectional(
                top: Gap.xs,
                end: Gap.xs,
                child: Tooltip(
                  message: context.tr('استفسر على واتساب', 'Ask on WhatsApp'),
                  child: const Icon(Icons.chat_outlined,
                      size: 16, color: AppColors.success),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

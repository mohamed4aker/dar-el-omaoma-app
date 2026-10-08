import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/catalog.dart';
import '../clinics/clinics_screen.dart' show foldArabic;
import '../services/hospital_services.dart' show askOnWhatsapp;

/// What a price includes, by [SurgeryTier].
String surgeryTierLabel(BuildContext context, String tier) => switch (tier) {
      SurgeryTier.specialist =>
        context.tr('شامل أتعاب جراح أخصائي', 'With a specialist surgeon'),
      SurgeryTier.consultant =>
        context.tr('شامل أتعاب جراح استشاري', 'With a consultant surgeon'),
      _ => context.tr('المستشفى فقط (بدون أتعاب الجراح)',
          'Hospital only (surgeon paid separately)'),
    };

/// The hospital's all-inclusive operation prices ("الصفقات الشاملة"): pick
/// the specialty and the room, and see what the operation costs.
class SurgeryPricesScreen extends StatefulWidget {
  const SurgeryPricesScreen({super.key});

  @override
  State<SurgeryPricesScreen> createState() => _SurgeryPricesScreenState();
}

class _SurgeryPricesScreenState extends State<SurgeryPricesScreen> {
  final _query = TextEditingController();
  String? _specialty;
  String _room = 'ثلاثي';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final all = Seed.surgeryPackages.where((p) => p.isActive).toList();
    final specialties = <String>{for (final p in all) p.specialty.ar}.toList();
    final specialty = _specialty ?? specialties.firstOrNull;
    final q = foldArabic(_query.text.trim());

    // Searching looks across every specialty; browsing shows one.
    final shown = all
        .where((p) => q.isEmpty
            ? p.specialty.ar == specialty
            : foldArabic(p.name.ar).contains(q))
        .toList();
    final rooms = <String>{
      for (final p in shown)
        for (final r in p.rooms) r,
    }.toList();
    final room = rooms.contains(_room) ? _room : rooms.firstOrNull ?? _room;

    final rows = <Object>[];
    String? lastCategory;
    for (final p in shown) {
      final heading = q.isEmpty ? p.category.ar : p.specialty.ar;
      if (heading.isNotEmpty && heading != lastCategory) rows.add(heading);
      lastCategory = heading;
      rows.add(p);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('أسعار العمليات', 'Surgery prices')),
        actions: [
          IconButton(
            tooltip: context.tr('استفسر على واتساب', 'Ask on WhatsApp'),
            onPressed: () => askOnWhatsapp(context, 'أسعار العمليات'),
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
            sliver: SliverList.list(children: [
              InfoNote(
                context.tr(
                    'السعر شامل الإقامة وغرفة العمليات حسب نوع الغرفة اللي تختارها. اختار التخصص ونوع الغرفة.',
                    'Prices include the stay and the theatre, by the room you choose.'),
                icon: Icons.healing_outlined,
                color: AppColors.accent,
              ),
              const SizedBox(height: Gap.md),
              TextField(
                controller: _query,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: context.tr('ابحث باسم العملية (مثال: قيصرية)',
                      'Search operations'),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ]),
          ),
          if (q.isEmpty)
            SliverToBoxAdapter(
              child: _ChipRow(
                label: context.tr('التخصص', 'Specialty'),
                options: specialties,
                selected: specialty,
                onSelect: (v) => setState(() => _specialty = v),
              ),
            ),
          if (rooms.isNotEmpty)
            SliverToBoxAdapter(
              child: _ChipRow(
                label: context.tr('نوع الغرفة', 'Room'),
                options: rooms,
                selected: room,
                onSelect: (v) => setState(() => _room = v),
              ),
            ),
          if (rows.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                message: context.tr('مفيش عمليات مطابقة', 'No matching operations'),
                icon: Icons.search_off,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
              sliver: SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final row = rows[i];
                  if (row is String) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: Gap.lg, bottom: Gap.sm),
                      child: Text(row,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.accent)),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: _PackageCard(
                        package: row as SurgeryPackage, room: room),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(Gap.lg),
            sliver: SliverList.list(children: [
              if (Seed.hasPrices(PriceService.surgery))
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/prices/${PriceService.surgery}'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(kMinTouchTarget)),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(context.tr('رسوم الأجهزة والإضافات',
                      'Equipment and extra charges')),
                ),
              const SizedBox(height: Gap.md),
              Text(
                context.tr(
                    'الأسعار من لائحة أسعار المستشفى بالجنيه المصري، وممكن تتغير. السعر النهائي بيتأكد بعد الكشف.',
                    'Prices are from the hospital price list, in EGP, and may change. The final price is confirmed after examination.'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              children: [
                for (final o in options)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                    child: ChoiceChip(
                      label: Text(o),
                      selected: o == selected,
                      onSelected: (_) => onSelect(o),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.room});

  final SurgeryPackage package;
  final String room;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final roomIndex = package.rooms.indexOf(room);
    final lines = [
      for (final tier in SurgeryTier.all)
        if (package.priceFor(tier, roomIndex) case final price?)
          (tier, price),
    ];
    return AppCard(
      onTap: package.hasPrices ? () => _showAllRooms(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(package.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (package.classification.isNotEmpty)
                StatusChip(package.classification, color: AppColors.accent),
            ],
          ),
          if (package.note != null) ...[
            const SizedBox(height: Gap.xs),
            Text(package.note!(s.localeName),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.warning)),
          ],
          const SizedBox(height: Gap.sm),
          if (lines.isNotEmpty)
            for (final (tier, price) in lines)
              Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(surgeryTierLabel(context, tier),
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Text(Fmt.money(price, s),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              )
          else if (package.hasPrices)
            Text(
              context.tr('مفيش سعر للغرفة دي — اضغط تشوف باقي الغرف',
                  'No price for this room — tap for other rooms'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: Gap.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => askOnWhatsapp(
                  context, 'عملية ${package.name.ar} (${package.specialty.ar})'),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: Text(package.hasPrices
                  ? context.tr('احجز أو استفسر', 'Book or ask')
                  : context.tr('اسأل عن السعر', 'Ask for the price')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllRooms(BuildContext context) {
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(Gap.lg),
          children: [
            Text(package.name(s.localeName),
                style: Theme.of(context).textTheme.titleLarge),
            Text('${package.specialty(s.localeName)} · ${package.classification}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Gap.lg),
            for (final tier in SurgeryTier.all)
              if (package.prices[tier]?.any((p) => p != null) ?? false) ...[
                Text(surgeryTierLabel(context, tier),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.accent)),
                const SizedBox(height: Gap.xs),
                for (var i = 0; i < package.rooms.length; i++)
                  if (package.priceFor(tier, i) case final price?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(package.rooms[i])),
                          Text(Fmt.money(price, s),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                const Divider(height: Gap.xl),
              ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
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
import '../prices/surgery_prices_screen.dart' show surgeryTierLabel;
import 'admin_widgets.dart';

String _serviceName(BuildContext context, String service) => switch (service) {
      PriceService.outpatient =>
        context.tr('العيادات الخارجية — إجراءات', 'Outpatient procedures'),
      PriceService.radiology => context.tr('الأشعة', 'Radiology'),
      PriceService.physio => context.tr('العلاج الطبيعي', 'Physiotherapy'),
      PriceService.inpatient => context.tr('القسم الداخلي', 'Inpatient'),
      PriceService.emergency => context.tr('الطوارئ', 'Emergency'),
      PriceService.ambulance => context.tr('الإسعاف', 'Ambulance'),
      PriceService.homecare => context.tr('الرعاية المنزلية', 'Home care'),
      PriceService.surgery => context.tr('رسوم العمليات', 'Theatre charges'),
      _ => service,
    };

/// Every department's price list, section by section.
class AdminPriceListsScreen extends StatelessWidget {
  const AdminPriceListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    final services = <String>{for (final sec in Seed.priceSections) sec.service};
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('لائحة الأسعار', 'Price list'))),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          InfoNote(
            context.tr(
                'أي تعديل هنا بيظهر للمرضى فورًا في صفحة القسم. البند المقفول بيختفي من القايمة.',
                'Changes show to patients straight away. A disabled line is hidden.'),
            icon: Icons.receipt_long_outlined,
          ),
          for (final service in services) ...[
            AdminSectionLabel(_serviceName(context, service)),
            for (final sec
                in Seed.priceSections.where((x) => x.service == service))
              AdminRow(
                title: sec.title(s.localeName),
                subtitle: context.tr('${sec.items.length} بند',
                    '${sec.items.length} lines'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AdminPriceSectionScreen(sectionId: sec.id),
                )),
              ),
          ],
        ],
      ),
    );
  }
}

class AdminPriceSectionScreen extends StatefulWidget {
  const AdminPriceSectionScreen({required this.sectionId, super.key});

  final String sectionId;

  @override
  State<AdminPriceSectionScreen> createState() =>
      _AdminPriceSectionScreenState();
}

class _AdminPriceSectionScreenState extends State<AdminPriceSectionScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    final section =
        Seed.priceSections.firstWhere((x) => x.id == widget.sectionId);
    final q = foldArabic(_query.text.trim());
    final items = section.items
        .where((i) => q.isEmpty || foldArabic(i.name.ar).contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(section.title(s.localeName))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, section, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('بند جديد', 'New line')),
      ),
      body: Column(
        children: [
          if (section.items.length > 8)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
              child: TextField(
                controller: _query,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: context.tr('ابحث', 'Search'),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 96),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return AdminRow(
                  title: item.name(s.localeName),
                  subtitle: [
                    if (item.code.isNotEmpty) item.code,
                    if (item.note != null) item.note!,
                  ].join(' · '),
                  dimmed: !item.isActive,
                  trailing: Padding(
                    padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                    child: Text(Fmt.money(item.price, s),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  onTap: () => _edit(context, section, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
      BuildContext context, PriceSection section, PriceItem? existing) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PriceItemForm(section: section, existing: existing),
    );
  }
}

class _PriceItemForm extends StatefulWidget {
  const _PriceItemForm({required this.section, this.existing});

  final PriceSection section;
  final PriceItem? existing;

  @override
  State<_PriceItemForm> createState() => _PriceItemFormState();
}

class _PriceItemFormState extends State<_PriceItemForm> {
  late final _name = TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _price =
      TextEditingController(text: '${widget.existing?.price ?? ''}');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late bool _active = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_name, _price, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormSheet(
      title: widget.existing == null
          ? context.tr('بند جديد', 'New line')
          : context.tr('تعديل البند', 'Edit line'),
      saveEnabled: _name.text.trim().isNotEmpty &&
          int.tryParse(_price.text.trim()) != null,
      onSave: () {
        context.read<AppState>().upsertPriceItem(
              sectionId: widget.section.id,
              id: widget.existing?.id,
              name: _name.text.trim(),
              price: int.parse(_price.text.trim()),
              note: _note.text,
              isActive: _active,
            );
        Navigator.of(context).pop();
      },
      children: [
        AdminField(
          controller: _name,
          label: context.tr('الاسم', 'Name'),
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _price,
          label: context.tr('السعر (جنيه)', 'Price (EGP)'),
          digitsOnly: true,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _note,
          label: context.tr('ملاحظة (اختياري)', 'Note (optional)'),
          maxLines: 2,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _active,
          onChanged: (v) => setState(() => _active = v),
          title: Text(context.tr('ظاهر للمرضى', 'Visible to patients')),
        ),
      ],
    );
  }
}

/// The all-inclusive operation prices, editable room by room.
class AdminSurgeryPackagesScreen extends StatefulWidget {
  const AdminSurgeryPackagesScreen({super.key});

  @override
  State<AdminSurgeryPackagesScreen> createState() =>
      _AdminSurgeryPackagesScreenState();
}

class _AdminSurgeryPackagesScreenState
    extends State<AdminSurgeryPackagesScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    final q = foldArabic(_query.text.trim());
    final packages = Seed.surgeryPackages
        .where((p) =>
            q.isEmpty ||
            foldArabic(p.name.ar).contains(q) ||
            foldArabic(p.specialty.ar).contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(context.tr('أسعار العمليات الشاملة', 'Surgery packages'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('اسم العملية أو التخصص',
                    'Operation or specialty'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 96),
              itemCount: packages.length,
              itemBuilder: (context, i) {
                final p = packages[i];
                final from = p.from;
                return AdminRow(
                  title: p.name(s.localeName),
                  subtitle: '${p.specialty(s.localeName)}'
                      '${p.classification.isEmpty ? '' : ' · ${p.classification}'}',
                  trailing: Padding(
                    padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                    child: Text(
                      from == null
                          ? context.tr('بدون سعر', 'No price')
                          : '${context.tr('من', 'from')} ${Fmt.money(from, s)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: from == null
                              ? AppColors.warning
                              : AppColors.primary),
                    ),
                  ),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => _SurgeryPackageForm(package: p),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SurgeryPackageForm extends StatefulWidget {
  const _SurgeryPackageForm({required this.package});

  final SurgeryPackage package;

  @override
  State<_SurgeryPackageForm> createState() => _SurgeryPackageFormState();
}

class _SurgeryPackageFormState extends State<_SurgeryPackageForm> {
  late final Map<String, List<TextEditingController>> _fields = {
    for (final tier in SurgeryTier.all)
      tier: [
        for (var i = 0; i < widget.package.rooms.length; i++)
          TextEditingController(
              text: '${widget.package.priceFor(tier, i) ?? ''}'),
      ],
  };

  @override
  void dispose() {
    for (final row in _fields.values) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.package;
    return AdminFormSheet(
      title: p.name.ar,
      saveEnabled: true,
      onSave: () {
        final prices = <String, List<int?>>{};
        for (final MapEntry(key: tier, value: row) in _fields.entries) {
          final values = [
            for (final c in row)
              (int.tryParse(c.text.trim()) ?? 0) > 0
                  ? int.parse(c.text.trim())
                  : null,
          ];
          if (values.any((v) => v != null)) prices[tier] = values;
        }
        context.read<AppState>().updateSurgeryPackagePrices(p.id, prices);
        Navigator.of(context).pop();
      },
      children: [
        InfoNote(
          context.tr('سيب الخانة فاضية لو الغرفة دي مش متاحة للعملية. لو مفيش ولا سعر، المريض بيشوف «اسأل عن السعر».',
              'Leave a room empty if it is not offered. With no prices at all, patients see "ask for the price".'),
          icon: Icons.info_outline,
        ),
        for (final tier in SurgeryTier.all) ...[
          AdminSectionLabel(surgeryTierLabel(context, tier)),
          Wrap(
            spacing: Gap.md,
            children: [
              for (var i = 0; i < p.rooms.length; i++)
                SizedBox(
                  width: 140,
                  child: AdminField(
                    controller: _fields[tier]![i],
                    label: p.rooms[i],
                    digitsOnly: true,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

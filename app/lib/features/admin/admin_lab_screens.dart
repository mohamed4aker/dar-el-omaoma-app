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
import 'admin_widgets.dart';

/// The laboratory's price list. 400+ tests, so searchable and lazily built.
class AdminLabTestsScreen extends StatefulWidget {
  const AdminLabTestsScreen({super.key});

  @override
  State<AdminLabTestsScreen> createState() => _AdminLabTestsScreenState();
}

class _AdminLabTestsScreenState extends State<AdminLabTestsScreen> {
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
    final tests = Seed.labTests
        .where((t) =>
            q.isEmpty ||
            foldArabic(t.name(s.localeName)).contains(q) ||
            foldArabic(t.category(s.localeName)).contains(q) ||
            t.code.toLowerCase() == q)
        .toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(context.tr('التحاليل والأسعار', 'Lab tests & prices'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('تحليل جديد', 'New test')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('اسم التحليل، القسم أو الكود',
                    'Test name, category or code'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, 96),
              itemCount: tests.length,
              itemBuilder: (context, i) {
                final t = tests[i];
                return AdminRow(
                  title: t.name(s.localeName),
                  subtitle: '${t.category(s.localeName)}'
                      '${t.code.isEmpty ? '' : ' · ${t.code}'}',
                  dimmed: !t.isActive,
                  trailing: Padding(
                    padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                    child: Text(Fmt.money(t.price, s),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  onTap: () => _edit(context, t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, LabTest? existing) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LabTestForm(existing: existing),
    );
  }
}

class _LabTestForm extends StatefulWidget {
  const _LabTestForm({this.existing});

  final LabTest? existing;

  @override
  State<_LabTestForm> createState() => _LabTestFormState();
}

class _LabTestFormState extends State<_LabTestForm> {
  late final _name = TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _category =
      TextEditingController(text: widget.existing?.category.ar ?? '');
  late final _price =
      TextEditingController(text: '${widget.existing?.price ?? ''}');
  late final _code = TextEditingController(text: widget.existing?.code ?? '');
  late bool _active = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_name, _category, _price, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = {for (final t in Seed.labTests) t.category.ar}.toList()
      ..sort();
    return AdminFormSheet(
      title: widget.existing == null
          ? context.tr('تحليل جديد', 'New test')
          : context.tr('تعديل التحليل', 'Edit test'),
      saveEnabled: _name.text.trim().isNotEmpty &&
          int.tryParse(_price.text.trim()) != null,
      onSave: () {
        final category = _category.text.trim().isEmpty
            ? 'تحاليل عامة'
            : _category.text.trim();
        final existingCategory = Seed.labTests
            .where((t) => t.category.ar == category)
            .map((t) => t.category)
            .firstOrNull;
        context.read<AppState>().upsertLabTest(
              id: widget.existing?.id,
              name: Label(_name.text.trim(), _name.text.trim()),
              category: existingCategory ?? Label(category),
              price: int.parse(_price.text.trim()),
              code: _code.text.trim(),
              isActive: _active,
            );
        Navigator.of(context).pop();
      },
      children: [
        AdminField(
          controller: _name,
          label: context.tr('اسم التحليل', 'Test name'),
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _price,
          label: context.tr('السعر (جنيه)', 'Price (EGP)'),
          digitsOnly: true,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _category,
          label: context.tr('القسم', 'Category'),
          helper: categories.take(8).join('، '),
        ),
        AdminField(
          controller: _code,
          label: context.tr('الكود (اختياري)', 'Code (optional)'),
          textDirection: TextDirection.ltr,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _active,
          onChanged: (v) => setState(() => _active = v),
          title: Text(context.tr('متاح للحجز', 'Available to book')),
          subtitle: Text(context.tr(
              'لو قفلته، يختفي من قايمة المرضى ويفضل في الحجوزات القديمة.',
              'When off, patients no longer see it; past bookings keep it.')),
        ),
      ],
    );
  }
}

/// The laboratory's offers (its printed packages).
class AdminLabPackagesScreen extends StatelessWidget {
  const AdminLabPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    return AdminListScaffold(
      title: context.tr('عروض المعمل', 'Lab offers'),
      addLabel: context.tr('عرض جديد', 'New offer'),
      onAdd: () => _edit(context, null),
      note: InfoNote(
        context.tr('العرض بيظهر للمرضى في الصفحة الرئيسية وفي المعمل، ويتحجز زي أي تحليل.',
            'Offers show on the home screen and in the lab, and are booked like any test.'),
        icon: Icons.local_offer_outlined,
      ),
      children: [
        for (final p in Seed.labPackages)
          AdminRow(
            title: p.name(s.localeName),
            subtitle: p.tests.join(' · '),
            dimmed: !p.isActive,
            trailing: Padding(
              padding: const EdgeInsetsDirectional.only(end: Gap.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.money(p.price, s),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  if (p.priceBefore > p.price)
                    Text(Fmt.money(p.priceBefore, s),
                        style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.muted)),
                ],
              ),
            ),
            onTap: () => _edit(context, p),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, LabPackage? existing) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LabPackageForm(existing: existing),
    );
  }
}

class _LabPackageForm extends StatefulWidget {
  const _LabPackageForm({this.existing});

  final LabPackage? existing;

  @override
  State<_LabPackageForm> createState() => _LabPackageFormState();
}

class _LabPackageFormState extends State<_LabPackageForm> {
  late final _name = TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _tests =
      TextEditingController(text: widget.existing?.tests.join(' - ') ?? '');
  late final _price =
      TextEditingController(text: '${widget.existing?.price ?? ''}');
  late final _before = TextEditingController(
      text: (widget.existing?.priceBefore ?? 0) > 0
          ? '${widget.existing!.priceBefore}'
          : '');
  late final _prep =
      TextEditingController(text: widget.existing?.preparation?.ar ?? '');
  late bool _active = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_name, _tests, _price, _before, _prep]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormSheet(
      title: widget.existing == null
          ? context.tr('عرض جديد', 'New offer')
          : context.tr('تعديل العرض', 'Edit offer'),
      saveEnabled: _name.text.trim().isNotEmpty &&
          int.tryParse(_price.text.trim()) != null,
      onSave: () {
        final tests = _tests.text
            .split(RegExp(r'\s*[-،,\n]\s*'))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        context.read<AppState>().upsertLabPackage(
              id: widget.existing?.id,
              name: Label(_name.text.trim(), widget.existing?.name.en),
              tests: tests,
              price: int.parse(_price.text.trim()),
              priceBefore: int.tryParse(_before.text.trim()) ?? 0,
              preparation:
                  _prep.text.trim().isEmpty ? null : Label(_prep.text.trim()),
              isActive: _active,
            );
        Navigator.of(context).pop();
      },
      children: [
        AdminField(
          controller: _name,
          label: context.tr('اسم العرض', 'Offer name'),
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _tests,
          label: context.tr('التحاليل', 'Tests'),
          helper: context.tr('افصل بينهم بشرطة: CBC - TSH - Ferritin',
              'Separate with dashes: CBC - TSH - Ferritin'),
          maxLines: 3,
          textDirection: TextDirection.ltr,
        ),
        Row(
          children: [
            Expanded(
              child: AdminField(
                controller: _price,
                label: context.tr('سعر العرض', 'Offer price'),
                digitsOnly: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: AdminField(
                controller: _before,
                label: context.tr('بدلًا من (اختياري)', 'Instead of (optional)'),
                digitsOnly: true,
              ),
            ),
          ],
        ),
        AdminField(
          controller: _prep,
          label: context.tr('التحضير (اختياري)', 'Preparation (optional)'),
          hint: context.tr('مثال: صيام 10 ساعات', 'e.g. fast for 10 hours'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _active,
          onChanged: (v) => setState(() => _active = v),
          title: Text(context.tr('العرض ظاهر للمرضى', 'Visible to patients')),
        ),
      ],
    );
  }
}

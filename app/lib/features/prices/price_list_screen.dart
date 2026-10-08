import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/utils/launch.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/catalog.dart';
import '../bookings/patient_picker.dart';
import '../clinics/clinics_screen.dart' show foldArabic;
import '../lab/lab_screen.dart' show VisitTimeSheet;
import '../services/hospital_services.dart' show askOnWhatsapp;

/// What each department's page says and offers, beyond its prices.
class _Department {
  const _Department(this.ar, this.en, this.icon, this.color);

  final String ar;
  final String en;
  final IconData icon;
  final Color color;
}

const _departments = {
  PriceService.outpatient: _Department('أسعار الكشوفات والإجراءات',
      'Clinic procedures', Icons.local_hospital_outlined, AppColors.primary),
  PriceService.radiology: _Department(
      'الأشعة', 'Radiology', Icons.monitor_heart_outlined, AppColors.accent),
  PriceService.physio: _Department('العلاج الطبيعي', 'Physiotherapy',
      Icons.accessibility_new_outlined, AppColors.success),
  PriceService.inpatient: _Department(
      'القسم الداخلي', 'Inpatient', Icons.bed_outlined, AppColors.accent),
  PriceService.emergency: _Department(
      'الطوارئ', 'Emergency', Icons.emergency_outlined, AppColors.danger),
  PriceService.ambulance: _Department('الإسعاف', 'Ambulance',
      Icons.airport_shuttle_outlined, AppColors.warning),
  PriceService.homecare: _Department('الرعاية المنزلية', 'Home care',
      Icons.home_work_outlined, AppColors.success),
  PriceService.surgery: _Department('رسوم العمليات', 'Theatre charges',
      Icons.healing_outlined, AppColors.warning),
};

/// A department's price list, searchable and grouped as the hospital groups
/// it. Radiology is bookable: studies go into a basket like lab tests.
class PriceListScreen extends StatefulWidget {
  const PriceListScreen({required this.service, super.key});

  final String service;

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final _query = TextEditingController();
  final Set<String> _basket = {};
  String? _sectionId;

  bool get _bookable => widget.service == PriceService.radiology;

  _Department get _dept =>
      _departments[widget.service] ??
      const _Department('الأسعار', 'Prices', Icons.receipt_long_outlined,
          AppColors.primary);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final sections = Seed.sectionsFor(widget.service);
    final q = foldArabic(_query.text.trim());
    final itemCount =
        sections.fold<int>(0, (n, sec) => n + sec.items.length);

    // Flattened: a header row per section, then its matching items.
    final rows = <Object>[];
    for (final sec in sections) {
      if (_sectionId != null && sec.id != _sectionId) continue;
      final items = sec.items.where((i) =>
          i.isActive &&
          (q.isEmpty ||
              foldArabic(i.name.ar).contains(q) ||
              i.code.toLowerCase() == q));
      if (items.isEmpty) continue;
      rows
        ..add(sec)
        ..addAll(items);
    }

    final total = state.radiologyTotal(_basket.toList());

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_dept.ar, _dept.en)),
        actions: [
          IconButton(
            tooltip: context.tr('استفسر على واتساب', 'Ask on WhatsApp'),
            onPressed: () => askOnWhatsapp(context, _dept.ar),
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _basket.isEmpty
          ? null
          : _BasketBar(
              count: _basket.length,
              total: Fmt.money(total, s),
              onBook: _book,
            ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
            sliver: SliverList.list(children: [
              ..._actions(context),
              if (itemCount > 12) ...[
                const SizedBox(height: Gap.md),
                TextField(
                  controller: _query,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: _bookable
                        ? context.tr('ابحث باسم الفحص (مثال: CT Brain)',
                            'Search studies (e.g. CT Brain)')
                        : context.tr('ابحث في القائمة', 'Search the list'),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ]),
          ),
          if (sections.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                      Gap.lg, Gap.sm, Gap.lg, 0),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                      child: ChoiceChip(
                        label: Text(context.tr('الكل', 'All')),
                        selected: _sectionId == null,
                        onSelected: (_) => setState(() => _sectionId = null),
                      ),
                    ),
                    for (final sec in sections)
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.only(end: Gap.sm),
                        child: ChoiceChip(
                          label: Text(sec.title(s.localeName)),
                          selected: _sectionId == sec.id,
                          onSelected: (_) => setState(() => _sectionId =
                              _sectionId == sec.id ? null : sec.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (rows.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                message: context.tr('مفيش نتائج مطابقة', 'No matches'),
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
                  if (row is PriceSection) {
                    return _SectionHeading(section: row);
                  }
                  final item = row as PriceItem;
                  return _ItemRow(
                    item: item,
                    selected: _basket.contains(item.id),
                    onToggle: _bookable
                        ? () => setState(() => _basket.contains(item.id)
                            ? _basket.remove(item.id)
                            : _basket.add(item.id))
                        : null,
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(Gap.lg),
            sliver: SliverToBoxAdapter(
              child: Text(
                context.tr(
                    'الأسعار من لائحة أسعار المستشفى بالجنيه المصري، وممكن تتغير. السعر النهائي بيتأكد في الاستقبال.',
                    'Prices are from the hospital price list, in EGP, and may change. Reception confirms the final price.'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The department's own calls to action, above its prices.
  List<Widget> _actions(BuildContext context) {
    final buttons = <Widget>[];
    void add(Widget w) => buttons.add(Padding(
          padding: const EdgeInsets.only(bottom: Gap.sm),
          child: w,
        ));

    Widget filled(String label, IconData icon, Color color, VoidCallback go) =>
        FilledButton.icon(
          onPressed: go,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size.fromHeight(kMinTouchTarget + 4),
          ),
          icon: Icon(icon),
          label: Text(label),
        );

    Widget outlined(String label, IconData icon, VoidCallback go) =>
        OutlinedButton.icon(
          onPressed: go,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(kMinTouchTarget),
          ),
          icon: Icon(icon),
          label: Text(label),
        );

    final whatsapp = outlined(
      context.tr('استفسر أو احجز على واتساب', 'Ask or book on WhatsApp'),
      Icons.chat_outlined,
      () => askOnWhatsapp(context, _dept.ar),
    );

    switch (widget.service) {
      case PriceService.radiology:
        buttons.add(InfoNote(
          context.tr(
              'اختار الفحوصات اللي محتاجها واحجز ميعاد وصولك. الدفع عند الوصول.',
              'Tick the studies you need and book when you will arrive. Pay on arrival.'),
          icon: Icons.monitor_heart_outlined,
          color: AppColors.accent,
        ));
      case PriceService.physio:
        final clinic = Seed.clinicNamed('العلاج الطبيعي');
        if (clinic != null) {
          add(filled(
            context.tr('احجز كشف مع أخصائي علاج طبيعي', 'Book a physiotherapist'),
            Icons.event_available,
            AppColors.primary,
            () => context.push('/clinics/${clinic.id}'),
          ));
        }
        add(whatsapp);
      case PriceService.emergency:
        add(filled(
          context.tr('اتصل بالطوارئ', 'Call the emergency department'),
          Icons.call,
          AppColors.danger,
          () => Launch.call(context, Seed.emergencyPhone),
        ));
      case PriceService.ambulance:
        add(filled(
          context.tr('اطلب الإسعاف — اتصل الآن', 'Call for an ambulance'),
          Icons.call,
          AppColors.danger,
          () => Launch.call(context, Seed.emergencyPhone),
        ));
        add(whatsapp);
      case PriceService.homecare:
        add(filled(
          context.tr('احجز زيارة منزلية على واتساب', 'Book a home visit on WhatsApp'),
          Icons.chat_outlined,
          AppColors.success,
          () => askOnWhatsapp(context, 'زيارة رعاية منزلية'),
        ));
      case PriceService.inpatient:
        add(whatsapp);
      case PriceService.outpatient:
        add(filled(
          context.tr('احجز كشف في عيادة', 'Book a clinic visit'),
          Icons.event_available,
          AppColors.primary,
          () => context.push('/clinics'),
        ));
      default:
        add(whatsapp);
    }
    return buttons;
  }

  Future<void> _book() async {
    final patient = await resolveBookingPatient(context);
    if (patient == null || !mounted) return;
    final visitAt = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const VisitTimeSheet(),
    );
    if (visitAt == null || !mounted) return;

    final state = context.read<AppState>();
    final booking = state.bookRadiology(
      patientId: patient.id,
      visitAt: visitAt,
      itemIds: _basket.toList(),
    );
    setState(_basket.clear);
    if (!mounted) return;
    final s = context.s;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 44),
        title: Text(context.tr('تم حجز الأشعة', 'Radiology booked')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${Fmt.weekday(visitAt, s)} ${Fmt.date(visitAt, s)} · ${Fmt.clock(visitAt, s)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Gap.sm),
            Text('${context.tr('الإجمالي', 'Total')}: ${Fmt.money(booking.total, s)}'),
            const SizedBox(height: Gap.md),
            Text('${context.tr('رقم الحجز', 'Booking number')}: ${booking.reference}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Gap.sm),
            Text(
              context.tr('الدفع عند الوصول. لو الفحص محتاج تحضير، قسم الأشعة هيبلغك.',
                  'Pay on arrival. Radiology will tell you about any preparation.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.commonClose),
          ),
          if (!state.session.isStaff)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/bookings');
              },
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(s.bookingsTitle),
            ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.section});

  final PriceSection section;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title(s.localeName),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.accent)),
          if (section.note != null) ...[
            const SizedBox(height: Gap.xs),
            Text(section.note!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Latin names (most imaging studies) read left to right even in Arabic.
bool _isLatin(String text) =>
    RegExp(r'^[\s(]*[A-Za-z0-9]').hasMatch(text);

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.selected,
    this.onToggle,
  });

  final PriceItem item;
  final bool selected;

  /// Null when the list is for reading only.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final name = item.name(s.localeName);
    final price = Text(Fmt.money(item.price, s),
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.primary));
    // Latin names keep their own reading order but line up with the
    // Arabic ones, at the start of the row.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final title = Text(
      name,
      textDirection: _isLatin(name) ? TextDirection.ltr : null,
      textAlign: rtl ? TextAlign.right : TextAlign.left,
    );
    final subtitle = item.note == null
        ? null
        : Text(item.note!, style: Theme.of(context).textTheme.bodySmall);

    final tile = onToggle == null
        ? ListTile(
            contentPadding: EdgeInsets.zero,
            title: title,
            subtitle: subtitle,
            trailing: price,
          )
        : CheckboxListTile(
            value: selected,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (_) => onToggle!(),
            title: title,
            subtitle: subtitle,
            secondary: price,
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: tile,
    );
  }
}

class _BasketBar extends StatelessWidget {
  const _BasketBar({
    required this.count,
    required this.total,
    required this.onBook,
  });

  final int count;
  final String total;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('$count ${count == 1 ? 'فحص' : 'فحوصات'}',
                        '$count stud${count == 1 ? 'y' : 'ies'}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(total,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, kMinTouchTarget + 4),
                padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
              ),
              icon: const Icon(Icons.event_available),
              label: Text(context.tr('احجز', 'Book')),
            ),
          ],
        ),
      ),
    );
  }
}

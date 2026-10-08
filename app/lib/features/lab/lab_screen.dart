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

/// The laboratory: its printed offers and its full price list, both bookable.
///
/// A patient ticks packages and tests into a basket, sees the total at
/// today's prices, and picks when they will come. The lab takes walk-ins, so
/// the time orders the queue rather than reserving a machine.
class LabScreen extends StatefulWidget {
  const LabScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final Set<String> _tests = {};
  final Set<String> _packages = {};
  final _query = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final count = _tests.length + _packages.length;
    final total = state.labTotal(
        testIds: _tests.toList(), packageIds: _packages.toList());

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('المعمل', 'Laboratory')),
          actions: [
            IconButton(
              tooltip: context.tr('اتصل بالمعمل', 'Call the lab'),
              onPressed: () => Launch.call(context, Seed.labPhone),
              icon: const Icon(Icons.call_outlined),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: context.tr('العروض', 'Offers')),
              Tab(text: context.tr('كل التحاليل', 'All tests')),
            ],
          ),
        ),
        body: TabBarView(
          children: [_offers(context), _allTests(context)],
        ),
        bottomNavigationBar: count == 0
            ? null
            : SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                      Gap.lg, Gap.md, Gap.lg, Gap.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                        top: BorderSide(
                            color: Theme.of(context).colorScheme.outline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('$count ${count == 1 ? 'بند' : 'بنود'}',
                                  '$count item${count == 1 ? '' : 's'}'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(Fmt.money(total, context.s),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _book,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, kMinTouchTarget + 4),
                          padding:
                              const EdgeInsets.symmetric(horizontal: Gap.xl),
                        ),
                        icon: const Icon(Icons.event_available),
                        label: Text(context.tr('احجز', 'Book')),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _offers(BuildContext context) {
    final s = context.s;
    final packages = Seed.labPackages.where((p) => p.isActive).toList();
    if (packages.isEmpty) {
      return EmptyState(
          message: context.tr('مفيش عروض حاليًا', 'No offers right now'),
          icon: Icons.local_offer_outlined);
    }
    return ListView(
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        InfoNote(
          context.tr('احجز داخل المعمل بالدور الأرضي، أو من هنا واختار ميعاد وصولك.',
              'Book at the ground-floor lab, or here and choose when you will arrive.'),
          icon: Icons.biotech_outlined,
          color: AppColors.accent,
        ),
        const SizedBox(height: Gap.lg),
        for (final p in packages)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: _PackageCard(
              package: p,
              selected: _packages.contains(p.id),
              onToggle: () => setState(() => _packages.contains(p.id)
                  ? _packages.remove(p.id)
                  : _packages.add(p.id)),
              money: (v) => Fmt.money(v, s),
            ),
          ),
      ],
    );
  }

  Widget _allTests(BuildContext context) {
    final s = context.s;
    final q = foldArabic(_query.text.trim());
    final active = Seed.labTests.where((t) => t.isActive).toList();
    final categories = <String>{for (final t in active) t.category(s.localeName)}
        .toList();
    final shown = active.where((t) {
      if (_category != null && t.category(s.localeName) != _category) {
        return false;
      }
      if (q.isEmpty) return true;
      return foldArabic(t.name(s.localeName)).contains(q) ||
          foldArabic(t.name.en).contains(q) ||
          t.code.toLowerCase() == q;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.sm),
          child: TextField(
            controller: _query,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: context.tr('ابحث باسم التحليل (مثال: CBC)',
                  'Search tests (e.g. CBC)'),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                child: ChoiceChip(
                  label: Text(context.tr('الكل', 'All')),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              for (final c in categories)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(
                        () => _category = _category == c ? null : c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? EmptyState(
                  message: context.tr('مفيش تحاليل مطابقة', 'No matching tests'),
                  icon: Icons.search_off)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = shown[i];
                    final selected = _tests.contains(t.id);
                    return CheckboxListTile(
                      value: selected,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => setState(() =>
                          selected ? _tests.remove(t.id) : _tests.add(t.id)),
                      title: Text(t.name(s.localeName),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start),
                      subtitle: Text(t.category(s.localeName),
                          style: Theme.of(context).textTheme.bodySmall),
                      secondary: Text(Fmt.money(t.price, s),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _book() async {
    final patient = await resolveBookingPatient(context);
    if (patient == null || !mounted) return;

    final visitAt = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => VisitTimeSheet(
        preparation: [
          for (final id in _packages)
            if (Seed.labPackageById(id)?.preparation != null)
              Seed.labPackageById(id)!.preparation!(context.s.localeName),
        ],
      ),
    );
    if (visitAt == null || !mounted) return;

    final state = context.read<AppState>();
    final booking = state.bookLab(
      patientId: patient.id,
      visitAt: visitAt,
      testIds: _tests.toList(),
      packageIds: _packages.toList(),
    );
    setState(() {
      _tests.clear();
      _packages.clear();
    });
    if (!mounted) return;
    final s = context.s;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 44),
        title: Text(context.tr('تم حجز المعمل', 'Lab visit booked')),
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
              context.tr('المعمل بالدور الأرضي. الدفع عند الوصول.',
                  'The lab is on the ground floor. Pay on arrival.'),
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

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.selected,
    required this.onToggle,
    required this.money,
  });

  final LabPackage package;
  final bool selected;
  final VoidCallback onToggle;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final prep = package.preparation;
    return AppCard(
      onTap: onToggle,
      borderColor: selected ? AppColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(package.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.add_circle_outline,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            package.tests.join(' · '),
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (prep != null) ...[
            const SizedBox(height: Gap.sm),
            StatusChip(prep(s.localeName), color: AppColors.warning),
          ],
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Text(money(package.price),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.primary)),
              const SizedBox(width: Gap.md),
              if (package.priceBefore > package.price)
                Text(
                  '${context.tr('بدلًا من', 'instead of')} ${money(package.priceBefore)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Day and arrival time for a walk-in department (the lab, radiology).
class VisitTimeSheet extends StatefulWidget {
  const VisitTimeSheet({this.preparation = const [], super.key});

  final List<String> preparation;

  @override
  State<VisitTimeSheet> createState() => _VisitTimeSheetState();
}

class _VisitTimeSheetState extends State<VisitTimeSheet> {
  late DateTime _day = _firstDay();
  DateTime? _time;

  /// The published booking hours.
  static const _opens = 8;
  static const _closes = 21;

  static DateTime _firstDay() {
    final now = DateTime.now();
    final today = Seed.today;
    return now.hour >= _closes ? today.add(const Duration(days: 1)) : today;
  }

  List<DateTime> _times(DateTime day) {
    final now = DateTime.now();
    return [
      for (var h = _opens; h <= _closes; h++)
        for (final m in const [0, 30])
          if (!(h == _closes && m > 0))
            DateTime(day.year, day.month, day.day, h, m),
    ].where((t) => t.isAfter(now)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final days = [
      for (var i = 0; i < 14; i++) _firstDay().add(Duration(days: i)),
    ];
    final times = _times(_day);

    return Padding(
      padding: const EdgeInsets.all(Gap.lg),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('هتيجي امتى؟', 'When will you come?'),
                style: Theme.of(context).textTheme.titleLarge),
            if (widget.preparation.isNotEmpty) ...[
              const SizedBox(height: Gap.md),
              InfoNote(
                '${context.tr('تحضير', 'Preparation')}: ${widget.preparation.toSet().join('، ')}',
                icon: Icons.info_outline,
                color: AppColors.warning,
              ),
            ],
            const SizedBox(height: Gap.md),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
                itemBuilder: (context, i) {
                  final d = days[i];
                  final selected = Fmt.isSameDay(d, _day);
                  return ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Fmt.weekday(d, s), style: const TextStyle(fontSize: 11)),
                        Text(Fmt.shortDate(d, s)),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _day = d;
                      _time = null;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: Gap.md),
            Expanded(
              child: times.isEmpty
                  ? EmptyState(message: s.clinicNoSlots, icon: Icons.event_busy)
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: Gap.sm,
                        runSpacing: Gap.sm,
                        children: [
                          for (final t in times)
                            ChoiceChip(
                              label: Text(Fmt.clock(t, s)),
                              selected: _time == t,
                              onSelected: (_) => setState(() => _time = t),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: Gap.md),
            FilledButton(
              onPressed: _time == null
                  ? null
                  : () => Navigator.of(context).pop(_time),
              child: Text(context.tr('تأكيد الحجز', 'Confirm booking')),
            ),
          ],
        ),
      ),
    );
  }
}

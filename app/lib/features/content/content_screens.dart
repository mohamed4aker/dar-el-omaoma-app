import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/enums.dart';

/// Deck slide 10: العروض and the three awareness days.
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final offers = Seed.offers.where((o) => !o.isEvent).toList();
    final events = Seed.offers.where((o) => o.isEvent).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.offersTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          for (final offer in offers)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                borderColor: AppColors.pink.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(offer.title(s.localeName),
                              style:
                                  Theme.of(context).textTheme.titleLarge),
                        ),
                        StatusChip('-${offer.discountPercent}%',
                            color: AppColors.pink),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(offer.description(s.localeName),
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: Gap.md),
                    Row(
                      children: [
                        PriceText(offer.priceBefore,
                            currency: s.commonEgp, strikethrough: true),
                        const SizedBox(width: Gap.md),
                        PriceText(offer.priceAfter, currency: s.commonEgp),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(
                      '${s.offersValidUntil} ${Fmt.date(offer.validUntil, s)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Gap.lg),
          SectionHeader(s.offersEvents),
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.event_available_outlined,
                        color: AppColors.navy),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title(s.localeName),
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          Text(event.description(s.localeName),
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Deck slide 11: the five categories and the five tips, verbatim.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final categories = {
      for (final tip in Seed.tips) tip.category.ar: tip.category,
    };
    final tips = Seed.tips
        .where((t) => _category == null || t.category.ar == _category)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.tipsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          InfoNote(s.tipsDisclaimer, icon: Icons.health_and_safety_outlined),
          const SizedBox(height: Gap.lg),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              ChoiceChip(
                label: Text(s.commonAll),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final entry in categories.entries)
                ChoiceChip(
                  label: Text(entry.value(s.localeName)),
                  selected: _category == entry.key,
                  onSelected: (v) =>
                      setState(() => _category = v ? entry.key : null),
                ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(tip.category(s.localeName),
                        color: AppColors.success),
                    const SizedBox(height: Gap.md),
                    Text(tip.body(s.localeName),
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: Gap.md),
                    // Every published tip carries a named medical reviewer and
                    // a review date (PROMPT.md 6.12).
                    Text(
                      '${s.tipsReviewedBy}: ${tip.reviewerName} · '
                      '${Fmt.date(tip.reviewedAt, s)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Deck slide 3 tile: الرعاية المنزلية.
class HomeCareScreen extends StatelessWidget {
  const HomeCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.homeCareTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          for (final service in Seed.homeCareServices)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(service.name(s.localeName),
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ),
                        PriceText(service.price, currency: s.commonEgp),
                      ],
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(service.description(s.localeName),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: Gap.md),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 14, color: AppColors.muted),
                        const SizedBox(width: Gap.xs),
                        Text(service.duration(s.localeName),
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, kMinTouchTarget),
                            padding: const EdgeInsets.symmetric(
                                horizontal: Gap.xl),
                          ),
                          child: Text(s.homeCareRequest),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Deck slide 3 tile: الشكاوى.
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  ComplaintCategory _category = ComplaintCategory.appointment;
  final _body = TextEditingController();
  bool _anonymous = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  String _categoryLabel(ComplaintCategory c, AppStrings s) {
    const ar = {
      ComplaintCategory.appointment: 'المواعيد',
      ComplaintCategory.clinicalCare: 'الرعاية الطبية',
      ComplaintCategory.nursing: 'التمريض',
      ComplaintCategory.cleanliness: 'النظافة',
      ComplaintCategory.billing: 'الحسابات',
      ComplaintCategory.staffConduct: 'سلوك الموظفين',
      ComplaintCategory.facilities: 'المرافق',
      ComplaintCategory.other: 'أخرى',
    };
    const en = {
      ComplaintCategory.appointment: 'Appointments',
      ComplaintCategory.clinicalCare: 'Clinical care',
      ComplaintCategory.nursing: 'Nursing',
      ComplaintCategory.cleanliness: 'Cleanliness',
      ComplaintCategory.billing: 'Billing',
      ComplaintCategory.staffConduct: 'Staff conduct',
      ComplaintCategory.facilities: 'Facilities',
      ComplaintCategory.other: 'Other',
    };
    return (s.localeName == 'en' ? en : ar)[c]!;
  }

  Future<void> _submit() async {
    final s = context.s;
    if (_body.text.trim().length < 10) return;
    final complaint = context.read<AppState>().submitComplaint(
          category: _category,
          body: _body.text.trim(),
          isAnonymous: _anonymous,
        );
    _body.clear();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle,
            color: AppColors.success, size: 40),
        title: Text(s.complaintsSubmit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!complaint.isAnonymous)
              SelectableText(
                '${s.complaintsReference}: ${complaint.reference}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: Gap.md),
            Text(s.complaintsSla,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final complaints = context.watch<AppState>().complaints;

    return Scaffold(
      appBar: AppBar(title: Text(s.complaintsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          SectionHeader(s.complaintsNew),
          DropdownButtonFormField<ComplaintCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: s.complaintsCategory),
            items: [
              for (final c in ComplaintCategory.values)
                DropdownMenuItem(value: c, child: Text(_categoryLabel(c, s))),
            ],
            onChanged: (c) => setState(() => _category = c ?? _category),
          ),
          const SizedBox(height: Gap.lg),
          TextField(
            controller: _body,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: s.complaintsBody),
          ),
          const SizedBox(height: Gap.md),
          SwitchListTile(
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
            contentPadding: EdgeInsets.zero,
            title: Text(s.complaintsAnonymous,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          // Stated clearly before submission, not after (PROMPT.md 6.5).
          if (_anonymous)
            InfoNote(s.complaintsAnonymousNote, color: AppColors.warning),
          const SizedBox(height: Gap.lg),
          FilledButton(
            onPressed: _body.text.trim().length >= 10 ? _submit : null,
            child: Text(s.complaintsSubmit),
          ),
          if (complaints.isNotEmpty) ...[
            const SizedBox(height: Gap.xxl),
            SectionHeader(s.complaintsTitle),
            for (final complaint in complaints)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _categoryLabel(complaint.category, s),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          StatusChip(
                            complaint.isAnonymous
                                ? s.complaintsAnonymous
                                : complaint.reference,
                            color: AppColors.navy,
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      Text(complaint.body,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

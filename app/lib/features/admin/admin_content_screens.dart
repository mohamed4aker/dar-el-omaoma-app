import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/content.dart';
import 'admin_widgets.dart';

/// Offers and awareness events (PROMPT.md §6.11).
///
/// Content is authored here and published without an app release — that rule
/// is why the patient screens read every offer from data rather than code.
class OffersAdminScreen extends StatelessWidget {
  const OffersAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();

    return AdminListScaffold(
      title: s.adminOffers,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      note: InfoNote(s.adminNoReleaseNeeded, icon: Icons.cloud_done_outlined),
      children: [
        for (final offer in Seed.offers)
          AdminRow(
            title: offer.title(s.localeName),
            subtitle: offer.isEvent
                ? '${s.offersEvents} · ${Fmt.date(offer.validUntil, s)}'
                : '${Fmt.money(offer.priceBefore, s)} → '
                    '${Fmt.money(offer.priceAfter, s)} · '
                    '${Fmt.date(offer.validUntil, s)}',
            trailing: IconButton(
              tooltip: s.adminDelete,
              onPressed: () => _confirmDelete(
                context,
                offer.title(s.localeName),
                () => state.removeOffer(offer.id),
              ),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
            onTap: () => _openForm(context, offer),
          ),
      ],
    );
  }

  void _openForm(BuildContext context, Offer? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OfferForm(existing: existing),
    );
  }
}

class _OfferForm extends StatefulWidget {
  const _OfferForm({this.existing});
  final Offer? existing;

  @override
  State<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends State<_OfferForm> {
  late final _titleAr =
      TextEditingController(text: widget.existing?.title.ar ?? '');
  late final _titleEn =
      TextEditingController(text: widget.existing?.title.en ?? '');
  late final _bodyAr =
      TextEditingController(text: widget.existing?.description.ar ?? '');
  late final _bodyEn =
      TextEditingController(text: widget.existing?.description.en ?? '');
  late final _before =
      TextEditingController(text: '${widget.existing?.priceBefore ?? 0}');
  late final _after =
      TextEditingController(text: '${widget.existing?.priceAfter ?? 0}');
  late DateTime _validUntil = widget.existing?.validUntil ??
      DateTime.now().add(const Duration(days: 30));
  late bool _isEvent = widget.existing?.isEvent ?? false;

  @override
  void dispose() {
    for (final c in [_titleAr, _titleEn, _bodyAr, _bodyEn, _before, _after]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AdminFormSheet(
      title: widget.existing == null ? s.adminNewOffer : s.adminEditOffer,
      saveEnabled: _titleAr.text.trim().isNotEmpty,
      onSave: _save,
      children: [
        SwitchListTile(
          value: _isEvent,
          onChanged: (v) => setState(() => _isEvent = v),
          contentPadding: EdgeInsets.zero,
          title: Text(s.adminIsEvent,
              style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(s.adminIsEventNote,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: Gap.lg),
        BilingualFields(
          arController: _titleAr,
          enController: _titleEn,
          label: s.adminTitle,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _bodyAr,
          label: '${s.adminDescription} (عربي)',
          maxLines: 3,
        ),
        AdminField(
          controller: _bodyEn,
          label: '${s.adminDescription} (English) — ${s.commonOptional}',
          maxLines: 3,
          textDirection: TextDirection.ltr,
        ),
        if (!_isEvent)
          Row(
            children: [
              Expanded(
                child: AdminField(
                  controller: _before,
                  label: '${s.offersBefore} (${s.commonEgp})',
                  digitsOnly: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: AdminField(
                  controller: _after,
                  label: '${s.offersAfter} (${s.commonEgp})',
                  digitsOnly: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        AdminSectionLabel(s.offersValidUntil),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _validUntil,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (picked != null) setState(() => _validUntil = picked);
          },
          icon: const Icon(Icons.event_outlined),
          label: Text(Fmt.date(_validUntil, s)),
        ),
      ],
    );
  }

  void _save() {
    context.read<AppState>().upsertOffer(
          id: widget.existing?.id,
          title: BilingualFields.toLabel(_titleAr, _titleEn),
          description: BilingualFields.toLabel(_bodyAr, _bodyEn),
          priceBefore: _isEvent ? 0 : parseIntOr(_before.text, 0),
          priceAfter: _isEvent ? 0 : parseIntOr(_after.text, 0),
          validUntil: _validUntil,
          isEvent: _isEvent,
        );
    Navigator.of(context).pop();
  }
}

/// Medical tips (PROMPT.md §6.12).
///
/// The reviewer field is not optional: content without a named medical
/// reviewer must never reach a patient, so the save button stays disabled
/// until it is filled, and [AppState.upsertTip] refuses it as well.
class TipsAdminScreen extends StatelessWidget {
  const TipsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();

    return AdminListScaffold(
      title: s.adminTips,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      note: InfoNote(s.adminReviewerRequired,
          icon: Icons.verified_user_outlined, color: AppColors.warning),
      children: [
        for (final tip in Seed.tips)
          AdminRow(
            title: tip.body(s.localeName),
            subtitle: '${tip.category(s.localeName)} · '
                '${s.tipsReviewedBy}: ${tip.reviewerName}',
            trailing: IconButton(
              tooltip: s.adminDelete,
              onPressed: () => _confirmDelete(
                context,
                tip.category(s.localeName),
                () => state.removeTip(tip.id),
              ),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
            onTap: () => _openForm(context, tip),
          ),
      ],
    );
  }

  void _openForm(BuildContext context, MedicalTip? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TipForm(existing: existing),
    );
  }
}

class _TipForm extends StatefulWidget {
  const _TipForm({this.existing});
  final MedicalTip? existing;

  @override
  State<_TipForm> createState() => _TipFormState();
}

class _TipFormState extends State<_TipForm> {
  late final _categoryAr =
      TextEditingController(text: widget.existing?.category.ar ?? '');
  late final _categoryEn =
      TextEditingController(text: widget.existing?.category.en ?? '');
  late final _bodyAr =
      TextEditingController(text: widget.existing?.body.ar ?? '');
  late final _bodyEn =
      TextEditingController(text: widget.existing?.body.en ?? '');
  late final _reviewer =
      TextEditingController(text: widget.existing?.reviewerName ?? '');

  @override
  void dispose() {
    for (final c in [
      _categoryAr, _categoryEn, _bodyAr, _bodyEn, _reviewer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final existingCategories = {
      for (final tip in Seed.tips) tip.category.ar: tip.category,
    };

    return AdminFormSheet(
      title: widget.existing == null ? s.adminNewTip : s.adminEditTip,
      saveEnabled: _bodyAr.text.trim().isNotEmpty &&
          _categoryAr.text.trim().isNotEmpty &&
          _reviewer.text.trim().isNotEmpty,
      onSave: _save,
      children: [
        AdminSectionLabel(s.adminCategory),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final entry in existingCategories.entries)
              ActionChip(
                label: Text(entry.value(s.localeName)),
                onPressed: () => setState(() {
                  _categoryAr.text = entry.value.ar;
                  _categoryEn.text = entry.value.en;
                }),
              ),
          ],
        ),
        const SizedBox(height: Gap.md),
        BilingualFields(
          arController: _categoryAr,
          enController: _categoryEn,
          label: s.adminCategory,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _bodyAr,
          label: '${s.adminTipBody} (عربي)',
          maxLines: 4,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _bodyEn,
          label: '${s.adminTipBody} (English) — ${s.commonOptional}',
          maxLines: 4,
          textDirection: TextDirection.ltr,
        ),
        AdminField(
          controller: _reviewer,
          label: s.adminReviewerName,
          helper: s.adminReviewerRequired,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  void _save() {
    context.read<AppState>().upsertTip(
          id: widget.existing?.id,
          category: BilingualFields.toLabel(_categoryAr, _categoryEn),
          body: BilingualFields.toLabel(_bodyAr, _bodyEn),
          reviewerName: _reviewer.text,
        );
    Navigator.of(context).pop();
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  String what,
  VoidCallback onConfirm,
) async {
  final s = context.s;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_outlined,
          color: AppColors.danger, size: 36),
      title: Text(s.adminDeleteConfirm),
      content: Text(what, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: Text(s.adminDelete),
        ),
      ],
    ),
  );
  if (confirmed ?? false) onConfirm();
}

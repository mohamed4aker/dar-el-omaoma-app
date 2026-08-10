import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/catalog.dart';

/// Shared pieces of the admin console.
///
/// The admin section lives inside the same app and the same codebase. It is
/// revealed by the server-issued `admin` role and is laid out for a wide
/// screen, since in practice it is used in a browser on a desk (PROMPT.md §14).

/// A form sheet with a title, a scrolling body and a save action.
class AdminFormSheet extends StatelessWidget {
  const AdminFormSheet({
    required this.title,
    required this.children,
    required this.onSave,
    this.saveEnabled = true,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final bool saveEnabled;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.md, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(Gap.xl),
              children: children,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saveEnabled ? onSave : null,
                  child: Text(s.commonSave),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled text field with consistent spacing.
class AdminField extends StatelessWidget {
  const AdminField({
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.keyboardType,
    this.maxLines = 1,
    this.digitsOnly = false,
    this.textDirection,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool digitsOnly;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: TextField(
        controller: controller,
        keyboardType:
            keyboardType ?? (digitsOnly ? TextInputType.number : null),
        maxLines: maxLines,
        textDirection: textDirection,
        onChanged: onChanged,
        inputFormatters:
            digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
        ),
      ),
    );
  }
}

/// Arabic + English name pair. Arabic is required; English falls back to it.
class BilingualFields extends StatelessWidget {
  const BilingualFields({
    required this.arController,
    required this.enController,
    required this.label,
    this.onChanged,
    super.key,
  });

  final TextEditingController arController;
  final TextEditingController enController;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        AdminField(
          controller: arController,
          label: '$label (عربي)',
          onChanged: onChanged,
        ),
        AdminField(
          controller: enController,
          label: '$label (English) — ${s.commonOptional}',
          textDirection: TextDirection.ltr,
          helper: s.adminEnglishFallback,
        ),
      ],
    );
  }

  static Label toLabel(
      TextEditingController ar, TextEditingController en) {
    final english = en.text.trim();
    return Label(ar.text.trim(), english.isEmpty ? null : english);
  }
}

class AdminSectionLabel extends StatelessWidget {
  const AdminSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// Colour picker limited to a curated set, so the availability grid never
/// ends up with two classifications in indistinguishable colours.
class ColourPicker extends StatelessWidget {
  const ColourPicker({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  static const options = [
    Color(0xFF0E9F6E),
    Color(0xFF2563EB),
    Color(0xFFD97706),
    Color(0xFFE4327E),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFDC2626),
    Color(0xFF475569),
  ];

  final Color selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Wrap(
        spacing: Gap.md,
        runSpacing: Gap.md,
        children: [
          for (final colour in options)
            GestureDetector(
              onTap: () => onSelect(colour),
              child: Container(
                width: kMinTouchTarget,
                height: kMinTouchTarget,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colour == selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: colour == selected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Weekday selector. ISO numbering: 1 = Monday … 7 = Sunday.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final List<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    const order = [6, 7, 1, 2, 3, 4, 5]; // Saturday-first, as Egypt reads it.
    final names = s.localeName == 'en'
        ? const {
            1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu',
            5: 'Fri', 6: 'Sat', 7: 'Sun',
          }
        : const {
            1: 'الإثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس',
            5: 'الجمعة', 6: 'السبت', 7: 'الأحد',
          };

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Wrap(
        spacing: Gap.sm,
        runSpacing: Gap.sm,
        children: [
          for (final day in order)
            FilterChip(
              label: Text(names[day]!),
              selected: selected.contains(day),
              onSelected: (_) => onToggle(day),
            ),
        ],
      ),
    );
  }
}

/// Row in an admin list: title, subtitle, trailing status, tap to edit.
class AdminRow extends StatelessWidget {
  const AdminRow({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.leading,
    this.trailing,
    this.dimmed = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Gap.md),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.card),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              padding: const EdgeInsets.all(Gap.lg),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: Gap.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  ?trailing,
                  if (onTap != null)
                    const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold for an admin list screen with a single "add" action.
class AdminListScaffold extends StatelessWidget {
  const AdminListScaffold({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.children,
    this.note,
    super.key,
  });

  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final List<Widget> children;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 96),
        children: [
          if (note != null) ...[note!, const SizedBox(height: Gap.lg)],
          ...children,
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(addLabel),
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
      ),
    );
  }
}

int parseIntOr(String text, int fallback) =>
    int.tryParse(text.trim()) ?? fallback;

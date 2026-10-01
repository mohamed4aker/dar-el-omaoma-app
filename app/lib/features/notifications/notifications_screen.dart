import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../domain/models/operations.dart';

/// Outbound notification log (PROMPT.md §12.3–12.4).
///
/// Every send is recorded with its channel, template and delivery status, so
/// "the doctor says he was never told" is an answerable question. This screen
/// is the mobile view of that log; in production it also lives in the admin
/// console.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = context.watch<AppState>().myNotifications;

    return Scaffold(
      appBar: AppBar(title: Text(s.moreNotifications)),
      body: items.isEmpty
          ? EmptyState(
              message: s.notificationsEmpty,
              icon: Icons.notifications_none,
            )
          : ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: _NotificationCard(item: item),
                  ),
              ],
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final link = item.deepLink;

    return AppCard(
      onTap: link == null || !link.startsWith('/admin')
          ? null
          : () => context.push(link),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_outlined, color: AppColors.primary),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Gap.xs),
                Text(item.body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: Gap.xs),
                Text(
                  '${Fmt.date(item.sentAt, s)} · ${Fmt.clock(item.sentAt, s)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

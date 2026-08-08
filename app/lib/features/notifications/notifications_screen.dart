import 'package:flutter/material.dart';
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
    final items = context.watch<AppState>().notifications;

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
                InfoNote(s.notificationsNoPhi,
                    icon: Icons.privacy_tip_outlined),
                const SizedBox(height: Gap.lg),
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
    final (label, colour, icon) = switch (item.channel) {
      NotifyChannel.push => (s.channelPush, AppColors.navy, Icons.notifications),
      NotifyChannel.whatsapp => (s.channelWhatsapp, AppColors.success, Icons.chat),
      NotifyChannel.sms => (s.channelSms, AppColors.warning, Icons.sms),
      NotifyChannel.inApp => (s.channelInApp, AppColors.pink, Icons.apps),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(label, color: colour, icon: icon),
              const Spacer(),
              Text(Fmt.time(item.sentAt),
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.xs),
          Text(item.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              Icon(Icons.code, size: 13, color: AppColors.muted),
              const SizedBox(width: Gap.xs),
              Expanded(
                child: Text(
                  item.templateCode,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (item.isExternalChannel)
                Text(s.channelTemplateApproved,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}

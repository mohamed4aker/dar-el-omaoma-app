import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/enums.dart';
import 'schedule_sheet.dart';

/// Surgery approvals inbox (PROMPT.md §6.13.6).
///
/// The approver decides from one screen: the request, its classification,
/// the estimate the patient saw, and the SLA clock. Rejection requires a
/// reason, and the patient is always routed onward to a consultation clinic —
/// a rejected request is never a dead end.
class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final pending = state.pendingApprovals;
    final decided = state.surgeryRequests
        .where((r) => !r.isAwaitingDecisionAt(DateTime.now()))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.approvalsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: '${s.approvalsPending} (${pending.length})'),
              Tab(text: '${s.approvalsDecided} (${decided.length})'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: s.approvalsRunEscalation,
              onPressed: () {
                final count = state.escalateOverdueRequests();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${s.approvalsEscalated}: $count'),
                  ),
                );
              },
              icon: const Icon(Icons.priority_high),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            if (pending.isEmpty)
              EmptyState(
                message: s.approvalsEmpty,
                icon: Icons.inbox_outlined,
              )
            else
              ListView(
                padding: const EdgeInsets.all(Gap.lg),
                children: [
                  for (final request in pending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.md),
                      child: _ApprovalCard(request: request),
                    ),
                ],
              ),
            if (decided.isEmpty)
              EmptyState(message: s.commonNoResults)
            else
              ListView(
                padding: const EdgeInsets.all(Gap.lg),
                children: [
                  for (final request in decided)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.md),
                      child: _DecidedCard(request: request),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.request});

  final SurgeryRequest request;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.read<AppState>();
    final procedure = Seed.procedureById(request.procedureId);
    final classification = Seed.classificationById(request.classificationId);
    final now = DateTime.now();
    final overdue = request.isEscalationOverdueAt(now);
    final remaining = request.escalationDueAt.difference(now);

    return AppCard(
      borderColor: overdue
          ? AppColors.danger.withValues(alpha: 0.6)
          : Theme.of(context).colorScheme.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(procedure.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(classification.name(s.localeName),
                  color: classification.colour),
            ],
          ),
          const SizedBox(height: Gap.xs),
          StatusChip(
            request.isFromDoctor ? s.requestFromDoctor : s.requestFromPatient,
            color: request.isFromDoctor ? AppColors.navy : AppColors.pink,
            icon: request.isFromDoctor
                ? Icons.medical_services_outlined
                : Icons.person_outline,
          ),
          const SizedBox(height: Gap.sm),
          Text('${s.complaintsReference}: ${request.reference}',
              style: Theme.of(context).textTheme.bodySmall),
          Text('${s.surgeryEstimate}: ${request.estimatePriceSnapshot}',
              style: Theme.of(context).textTheme.bodySmall),
          if (request.preferredSurgeonId != null)
            Text(
              '${s.surgeryPreferredSurgeon}: '
              '${Seed.doctorById(request.preferredSurgeonId!).name(s.localeName)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: Gap.md),

          // The SLA clock is the point of this screen. An approver who cannot
          // see the deadline will not meet it.
          InfoNote(
            overdue
                ? s.approvalsOverdue
                : '${s.approvalsDueIn} ${Fmt.duration(remaining, s)}',
            icon: overdue ? Icons.priority_high : Icons.timer_outlined,
            color: overdue ? AppColors.danger : AppColors.warning,
          ),
          const SizedBox(height: Gap.lg),

          // A doctor request needs a slot, not a clinical verdict — so the
          // primary action is to schedule it, not to approve it.
          if (request.isFromDoctor)
            FilledButton.icon(
              onPressed: () => showScheduleSheet(context, request),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(s.scheduleAction),
            )
          else
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => state.decideSurgeryRequest(
                    request.id,
                    decision: SurgeryRequestStatus.approved,
                    reason: s.approvalsApprovedNote,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(s.approvalsApprove),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, request),
                  child: Text(s.approvalsReject),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          TextButton(
            onPressed: () => state.decideSurgeryRequest(
              request.id,
              decision: SurgeryRequestStatus.moreInfoRequired,
              reason: s.approvalsMoreInfoNote,
            ),
            child: Text(s.approvalsMoreInfo),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context, SurgeryRequest request) async {
    final s = context.s;
    final state = context.read<AppState>();
    String? selected;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.approvalsRejectReason),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final reason in s.approvalsRejectReasons)
                RadioListTile<String>(
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: selected,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => selected = v),
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.commonCancel),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(context).pop(selected),
              child: Text(s.approvalsReject),
            ),
          ],
        ),
      ),
    );

    if (reason == null) return;
    state.decideSurgeryRequest(
      request.id,
      decision: SurgeryRequestStatus.rejected,
      reason: reason,
    );
  }
}

class _DecidedCard extends StatelessWidget {
  const _DecidedCard({required this.request});

  final SurgeryRequest request;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final procedure = Seed.procedureById(request.procedureId);
    final approved = request.status == SurgeryRequestStatus.approved ||
        request.status == SurgeryRequestStatus.scheduled;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(procedure.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(
                approved ? s.statusApproved : s.statusRejected,
                color: approved ? AppColors.success : AppColors.danger,
                icon: approved
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(request.reference,
              style: Theme.of(context).textTheme.bodySmall),
          if (request.decisionReason != null) ...[
            const SizedBox(height: Gap.sm),
            Text(request.decisionReason!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

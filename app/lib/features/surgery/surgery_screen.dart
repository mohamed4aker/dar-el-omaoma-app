import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/enums.dart';

/// Patient-facing surgery module (PROMPT.md 6.13.6–6.13.7).
///
/// A patient *requests* a surgery; it is never a confirmed booking. The screen
/// is explicit about that distinction so nobody arrives at the hospital
/// believing they have a theatre slot.
class SurgeryScreen extends StatelessWidget {
  const SurgeryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final requests = state.surgeryRequests;
    final requestable =
        Seed.procedures.where((p) => p.patientRequestable).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.surgeryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: s.surgeryCatalogue),
              Tab(text: '${s.surgeryMyRequests} (${requests.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                InfoNote(
                  s.localeName == 'en'
                      ? 'Surgery bookings are reviewed by the medical administration before confirmation.'
                      : 'حجز العمليات يخضع لمراجعة الإدارة الطبية قبل التأكيد.',
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(height: Gap.lg),
                for (final procedure in requestable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: _ProcedureCard(procedure: procedure),
                  ),
              ],
            ),
            requests.isEmpty
                ? EmptyState(
                    message: s.surgeryNoRequests,
                    icon: Icons.assignment_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.all(Gap.lg),
                    children: [
                      for (final request in requests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Gap.md),
                          child: _RequestCard(request: request),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _ProcedureCard extends StatelessWidget {
  const _ProcedureCard({required this.procedure});

  final Procedure procedure;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Seed.classificationById(procedure.classificationId);
    return AppCard(
      onTap: () => context.push('/surgery/request/${procedure.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(procedure.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(c.name(s.localeName), color: c.colour),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            '${s.surgeryDuration}: ${Fmt.duration(procedure.typicalDuration, s)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              Expanded(
                child: Text(s.surgeryEstimate,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              PriceText(procedure.price, currency: s.commonEgp),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final SurgeryRequest request;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final procedure = Seed.procedureById(request.procedureId);
    final overdue = request.isEscalationOverdueAt(DateTime.now());

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
                _statusLabel(request.status, s),
                color: _statusColor(request.status),
                icon: _statusIcon(request.status),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text('${s.complaintsReference}: ${request.reference}',
              style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${Fmt.date(request.submittedAt, s)} · '
            '${Fmt.time(request.submittedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Gap.sm),
          Text('${s.surgeryEstimate}: ${request.estimatePriceSnapshot}',
              style: Theme.of(context).textTheme.bodySmall),
          if (overdue) ...[
            const SizedBox(height: Gap.md),
            // Surfaced to the patient as reassurance, not as an internal
            // metric: the escalation itself is an admin-console workflow
            // (PROMPT.md 6.13.6).
            InfoNote(
              s.localeName == 'en'
                  ? 'Escalated to the medical director for a decision.'
                  : 'تم تصعيد الطلب للإدارة الطبية لسرعة الرد.',
              icon: Icons.priority_high,
              color: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(SurgeryRequestStatus status, AppStrings s) =>
      switch (status) {
        SurgeryRequestStatus.submitted => s.statusSubmitted,
        SurgeryRequestStatus.underReview => s.statusUnderReview,
        SurgeryRequestStatus.approved => s.statusApproved,
        SurgeryRequestStatus.scheduled => s.statusScheduled,
        SurgeryRequestStatus.rejected => s.statusRejected,
        SurgeryRequestStatus.moreInfoRequired => s.statusMoreInfo,
        SurgeryRequestStatus.cancelled => s.statusCancelled,
      };

  static Color _statusColor(SurgeryRequestStatus status) => switch (status) {
        SurgeryRequestStatus.approved ||
        SurgeryRequestStatus.scheduled =>
          AppColors.success,
        SurgeryRequestStatus.rejected ||
        SurgeryRequestStatus.cancelled =>
          AppColors.danger,
        SurgeryRequestStatus.moreInfoRequired => AppColors.warning,
        _ => AppColors.navy,
      };

  static IconData _statusIcon(SurgeryRequestStatus status) => switch (status) {
        SurgeryRequestStatus.approved ||
        SurgeryRequestStatus.scheduled =>
          Icons.check_circle_outline,
        SurgeryRequestStatus.rejected ||
        SurgeryRequestStatus.cancelled =>
          Icons.cancel_outlined,
        SurgeryRequestStatus.moreInfoRequired => Icons.help_outline,
        _ => Icons.schedule,
      };
}

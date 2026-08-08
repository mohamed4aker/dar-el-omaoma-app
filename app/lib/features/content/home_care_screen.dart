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
import '../../domain/models/catalog.dart';
import '../../domain/models/operations.dart';

/// Deck slide 3 tile: الرعاية المنزلية, with the request workflow from
/// PROMPT.md §6.4.
class HomeCareScreen extends StatelessWidget {
  const HomeCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final requests = context.watch<AppState>().homeCareRequests;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.homeCareTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: s.servicesTitle),
              Tab(text: '${s.homeCareMyRequests} (${requests.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                for (final service in Seed.homeCareServices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: _ServiceCard(service: service),
                  ),
              ],
            ),
            requests.isEmpty
                ? EmptyState(
                    message: s.commonNoResults,
                    icon: Icons.home_work_outlined,
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

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final HomeCareService service;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(service.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
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
              const Icon(Icons.schedule, size: 14, color: AppColors.muted),
              const SizedBox(width: Gap.xs),
              Text(service.duration(s.localeName),
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              FilledButton(
                onPressed: () => _openRequest(context, service),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                  padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
                ),
                child: Text(s.homeCareRequest),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openRequest(
      BuildContext context, HomeCareService service) async {
    final state = context.read<AppState>();
    if (state.session.patient == null) {
      context.push('/login');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RequestSheet(service: service),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.service});

  final HomeCareService service;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _address = TextEditingController();
  final _notes = TextEditingController();
  DateTime _day = DateTime.now().add(const Duration(days: 1));
  int _fromHour = 10;

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final from = DateTime(_day.year, _day.month, _day.day, _fromHour);
    final to = from.add(const Duration(hours: 2));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(Gap.xl),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.service.name(s.localeName),
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          TextField(
            controller: _address,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: s.homeCareAddress,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(s.homeCareWindow,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Gap.sm),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
              itemBuilder: (context, index) {
                final day =
                    DateTime.now().add(Duration(days: index + 1));
                final selected = Fmt.isSameDay(day, _day);
                return GestureDetector(
                  onTap: () => setState(() => _day = day),
                  child: Container(
                    width: 72,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.navy : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.input),
                      border: Border.all(
                        color: selected
                            ? AppColors.navy
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(Fmt.weekday(day, s),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white70
                                  : AppColors.muted,
                            )),
                        Text(Fmt.shortDate(day, s),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: Gap.md),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final hour in const [8, 10, 12, 14, 16, 18])
                ChoiceChip(
                  label: Text(
                    '${hour.toString().padLeft(2, '0')}:00 – '
                    '${(hour + 2).toString().padLeft(2, '0')}:00',
                  ),
                  selected: _fromHour == hour,
                  onSelected: (_) => setState(() => _fromHour = hour),
                ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '${s.homeCareNotes} — ${s.commonOptional}',
            ),
          ),
          const SizedBox(height: Gap.lg),
          InfoNote(s.homeCareFreeCancel, color: AppColors.success),
          const SizedBox(height: Gap.xl),
          FilledButton(
            onPressed: _address.text.trim().length < 8
                ? null
                : () => _submit(from, to),
            child: Text(s.homeCareRequest),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  Future<void> _submit(DateTime from, DateTime to) async {
    final s = context.s;
    final state = context.read<AppState>();
    final patient = state.session.patient!;
    final request = state.requestHomeCare(
      serviceId: widget.service.id,
      patientId: patient.id,
      address: _address.text.trim(),
      preferredFrom: from,
      preferredTo: to,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle,
            color: AppColors.success, size: 40),
        title: Text(s.homeCareSubmitted),
        content: SelectableText(
          '${s.complaintsReference}: ${request.reference}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
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
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final HomeCareRequest request;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.read<AppState>();
    final service =
        Seed.homeCareServices.firstWhere((x) => x.id == request.serviceId);

    final (label, colour) = switch (request.status) {
      HomeCareStatus.submitted => (s.statusSubmitted, AppColors.navy),
      HomeCareStatus.scheduled => (s.statusScheduled, AppColors.navy),
      HomeCareStatus.enRoute => (
          s.localeName == 'en' ? 'On the way' : 'الفريق في الطريق',
          AppColors.warning
        ),
      HomeCareStatus.inProgress => (
          s.localeName == 'en' ? 'In progress' : 'جارية',
          AppColors.warning
        ),
      HomeCareStatus.completed => (s.statusCompleted, AppColors.success),
      HomeCareStatus.cancelled => (s.statusCancelled, AppColors.danger),
    };

    // The status ladder is advanced by the coordinator in the admin console.
    // Exposed here so the flow is demonstrable end to end.
    const ladder = [
      HomeCareStatus.submitted,
      HomeCareStatus.scheduled,
      HomeCareStatus.enRoute,
      HomeCareStatus.inProgress,
      HomeCareStatus.completed,
    ];
    final index = ladder.indexOf(request.status);
    final next = index >= 0 && index < ladder.length - 1
        ? ladder[index + 1]
        : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(service.name(s.localeName),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(label, color: colour),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text('${s.complaintsReference}: ${request.reference}',
              style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${Fmt.date(request.preferredFrom, s)} · '
            '${Fmt.timeRange(request.preferredFrom, request.preferredTo)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(request.address,
              style: Theme.of(context).textTheme.bodySmall),
          if (next != null) ...[
            const SizedBox(height: Gap.md),
            OutlinedButton(
              onPressed: () => state.advanceHomeCare(request.id, next),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, kMinTouchTarget),
              ),
              child: Text(s.visitingAdvance),
            ),
          ],
        ],
      ),
    );
  }
}

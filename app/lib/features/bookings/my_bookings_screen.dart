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
import '../../domain/models/enums.dart';

/// The patient's own bookings, clinic and laboratory, upcoming first.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final patient = state.session.patient;
    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.bookingsTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(message: s.guestBannerBody, icon: Icons.lock_outline),
              FilledButton(
                onPressed: () => context.push('/login'),
                style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                child: Text(s.moreSignIn),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final rows = state
        .allBookings()
        .where((r) => r.patientId == patient.id)
        .toList();
    final upcoming = rows
        .where((r) => r.status == AppointmentStatus.confirmed && r.at.isAfter(now))
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final past = rows.where((r) => !upcoming.contains(r)).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.bookingsTitle),
          bottom: TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: '${s.bookingsUpcoming} (${upcoming.length})'),
              Tab(text: s.bookingsPast),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(context, upcoming, allowCancel: true),
            _list(context, past, allowCancel: false),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<BookingRow> rows,
      {required bool allowCancel}) {
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(message: context.s.bookingsEmpty, icon: Icons.event_note),
            if (allowCancel)
              FilledButton.icon(
                onPressed: () => context.push('/clinics'),
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                icon: const Icon(Icons.add),
                label: Text(context.tr('احجز في عيادة', 'Book a clinic')),
              ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(Gap.lg),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
      itemBuilder: (context, i) =>
          BookingCard(row: rows[i], allowCancel: allowCancel),
    );
  }
}

/// One booking, as the patient sees it.
class BookingCard extends StatelessWidget {
  const BookingCard({required this.row, this.allowCancel = false, super.key});

  final BookingRow row;
  final bool allowCancel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.read<AppState>();
    final a = row.appointment;
    final lab = row.lab;

    final String title;
    final String subtitle;
    if (a != null) {
      title = Seed.clinicById(a.clinicId)?.name(s.localeName) ??
          context.tr('عيادة', 'Clinic');
      subtitle = Seed.doctorById(a.doctorId).name(s.localeName);
    } else {
      title = context.tr('المعمل', 'Laboratory');
      subtitle = labItemsSummary(context, lab!);
    }

    final canCancel = allowCancel &&
        row.status == AppointmentStatus.confirmed &&
        (a == null || state.patientCanCancel(a));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(a != null ? Icons.local_hospital_outlined : Icons.biotech_outlined,
                  color: AppColors.primary),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              bookingStatusChip(context, row.status),
            ],
          ),
          const SizedBox(height: Gap.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Gap.sm),
          Text(
            '${Fmt.weekday(row.at, s)} ${Fmt.date(row.at, s)} · ${Fmt.clock(row.at, s)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: Gap.xs),
          Text('${context.tr('رقم الحجز', 'Booking no.')} ${row.reference}'
              '${lab != null ? ' · ${Fmt.money(lab.total, s)}' : ''}',
              style: Theme.of(context).textTheme.bodySmall),
          if (a?.cancelNote != null && row.status == AppointmentStatus.cancelled) ...[
            const SizedBox(height: Gap.sm),
            InfoNote(a!.cancelNote!, color: AppColors.warning),
          ],
          if (canCancel) ...[
            const SizedBox(height: Gap.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _cancel(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.event_busy_outlined),
                label: Text(context.tr('إلغاء الحجز', 'Cancel booking')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(context.tr('إلغاء الحجز؟', 'Cancel this booking?')),
        content: Text(context.tr('الميعاد هيتفتح لمريض تاني.',
            'The time will be released to another patient.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(context.tr('رجوع', 'Back'))),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger, minimumSize: const Size(0, 44)),
            child: Text(context.tr('إلغاء الحجز', 'Cancel booking')),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final state = context.read<AppState>();
    if (row.appointment != null) {
      state.cancelAppointment(row.id,
          reason: CancellationReason.patientRequested);
    } else {
      state.setLabBookingStatus(row.id, AppointmentStatus.cancelled,
          reason: CancellationReason.patientRequested);
    }
  }
}

String labItemsSummary(BuildContext context, LabBooking b) {
  final s = context.s;
  final names = [
    for (final id in b.packageIds)
      Seed.labPackageById(id)?.name(s.localeName) ?? id,
    for (final id in b.testIds) Seed.labTestById(id)?.name(s.localeName) ?? id,
  ];
  if (names.length <= 3) return names.join('، ');
  return '${names.take(3).join('، ')} ${context.tr('و${names.length - 3} أخرى', '+${names.length - 3} more')}';
}

Widget bookingStatusChip(BuildContext context, AppointmentStatus status) {
  final s = context.s;
  return switch (status) {
    AppointmentStatus.confirmed =>
      StatusChip(context.tr('مؤكد', 'Confirmed'), color: AppColors.success),
    AppointmentStatus.completed =>
      StatusChip(context.tr('تم الحضور', 'Attended'), color: AppColors.accent),
    AppointmentStatus.noShow =>
      StatusChip(context.tr('لم يحضر', 'No-show'), color: AppColors.warning),
    AppointmentStatus.cancelled =>
      StatusChip(s.statusCancelled, color: AppColors.danger),
  };
}

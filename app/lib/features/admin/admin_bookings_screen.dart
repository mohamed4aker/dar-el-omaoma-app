import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/utils/launch.dart';
import '../../core/validation/national_id.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/content.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/patient.dart';
import '../bookings/my_bookings_screen.dart'
    show bookingStatusChip, labItemsSummary;

enum _Range { today, upcoming, all }

enum _Kind { all, clinic, lab }

/// Reception's view of every booking: who, with whom, when, and the patient's
/// full details — National ID, mobile, age, sex — one tap from a phone call.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({this.doctorId, super.key});

  /// When set, the list is that doctor's own — what a doctor sees under
  /// "عيادتي".
  final String? doctorId;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  _Range _range = _Range.today;
  _Kind _kind = _Kind.all;
  late String? _doctorId = widget.doctorId;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(BookingRow r, Patient? p) {
    final q = _query.text.trim();
    if (q.isEmpty) return true;
    final digits = NationalId.normalise(q);
    if (r.reference.toLowerCase().contains(q.toLowerCase())) return true;
    if (p == null) return false;
    if (p.fullName.contains(q)) return true;
    if (digits.length >= 3 &&
        ((p.nationalId ?? '').contains(digits) || p.phoneLocal.contains(digits))) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final today = Seed.today;
    final tomorrow = today.add(const Duration(days: 1));
    final now = DateTime.now();

    var rows = state.allBookings().where((r) {
      switch (_range) {
        case _Range.today:
          if (r.at.isBefore(today) || !r.at.isBefore(tomorrow)) return false;
        case _Range.upcoming:
          if (r.at.isBefore(now) || r.status != AppointmentStatus.confirmed) {
            return false;
          }
        case _Range.all:
          break;
      }
      if (_kind == _Kind.clinic && r.isLab) return false;
      if (_kind == _Kind.lab && !r.isLab) return false;
      if (_doctorId != null && r.appointment?.doctorId != _doctorId) return false;
      return _matches(r, state.patientById(r.patientId));
    }).toList();
    if (_range != _Range.all) rows.sort((a, b) => a.at.compareTo(b.at));

    final doctorIds = {
      for (final r in state.allBookings())
        if (r.appointment != null) r.appointment!.doctorId,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorId != null
            ? context.tr('عيادتي', 'My clinic')
            : context.tr('الحجوزات', 'Bookings')),
        actions: [
          if (widget.doctorId != null && Seed.theatres.isNotEmpty)
            TextButton.icon(
              onPressed: () => context.push('/theatre'),
              icon: const Icon(Icons.meeting_room_outlined),
              label: Text(context.tr('غرف العمليات', 'Theatres')),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('اسم المريض، رقم قومي، موبايل أو رقم حجز',
                    'Patient name, National ID, mobile or booking no.'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg, vertical: Gap.md),
            child: Row(
              children: [
                for (final (r, label) in [
                  (_Range.today, context.tr('اليوم', 'Today')),
                  (_Range.upcoming, context.tr('القادمة', 'Upcoming')),
                  (_Range.all, context.tr('الكل', 'All')),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _range == r,
                      onSelected: (_) => setState(() => _range = r),
                    ),
                  ),
                const SizedBox(width: Gap.md),
                for (final (k, label) in [
                  (_Kind.all, context.tr('عيادات ومعمل', 'Clinics & lab')),
                  (_Kind.clinic, context.tr('عيادات', 'Clinics')),
                  (_Kind.lab, context.tr('معمل', 'Lab')),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Gap.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                  ),
              ],
            ),
          ),
          if (doctorIds.isNotEmpty &&
              _kind != _Kind.lab &&
              widget.doctorId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
              child: DropdownButtonFormField<String?>(
                initialValue: _doctorId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('الطبيب', 'Doctor'),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('كل الأطباء', 'All doctors'))),
                  for (final id in doctorIds)
                    DropdownMenuItem(
                        value: id,
                        child: Text(Seed.doctorById(id).name(s.localeName))),
                ],
                onChanged: (v) => setState(() => _doctorId = v),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.tr('${rows.length} حجز', '${rows.length} bookings'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(
                    message: context.tr('مفيش حجوزات', 'No bookings'),
                    icon: Icons.event_note_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.all(Gap.lg),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
                    itemBuilder: (context, i) => _AdminBookingCard(row: rows[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  const _AdminBookingCard({required this.row});

  final BookingRow row;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.read<AppState>();
    final patient = state.patientById(row.patientId);
    final a = row.appointment;
    final what = a != null
        ? '${Seed.doctorById(a.doctorId).name(s.localeName)} — '
            '${Seed.clinicById(a.clinicId)?.name(s.localeName) ?? ''}'
        : '${context.tr('المعمل', 'Lab')}: ${labItemsSummary(context, row.lab!)}';

    return AppCard(
      onTap: () => showBookingDetail(context, row),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(Fmt.clock(row.at, s),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.primary)),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  '${Fmt.weekday(row.at, s)} ${Fmt.shortDate(row.at, s)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              bookingStatusChip(context, row.status),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(patient?.fullName ?? context.tr('مريض محذوف', 'Unknown patient'),
              style: Theme.of(context).textTheme.titleMedium),
          if (patient != null)
            Text(
              '${patient.phoneLocal} · ${patientAgeSex(context, patient)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: Gap.xs),
          Text(what, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Gap.xs),
          Text('${context.tr('رقم الحجز', 'Booking no.')} ${row.reference}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

String patientAgeSex(BuildContext context, Patient p) {
  final age = p.ageAt(DateTime.now());
  final sex = p.isMale
      ? context.tr('ذكر', 'Male')
      : context.tr('أنثى', 'Female');
  return context.tr('$age سنة · $sex', '$age y · $sex');
}

/// Everything about one booking and the patient behind it, with the
/// reception actions: attended, no-show, cancel, call.
Future<void> showBookingDetail(BuildContext context, BookingRow row) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _BookingDetailSheet(row: row),
  );
}

class _BookingDetailSheet extends StatelessWidget {
  const _BookingDetailSheet({required this.row});

  final BookingRow row;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    // Re-read: the status may have changed while the sheet is open.
    final current = state.allBookings().firstWhere((r) => r.id == row.id,
        orElse: () => row);
    final patient = state.patientById(current.patientId);
    final a = current.appointment;
    final lab = current.lab;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.tr('تفاصيل الحجز', 'Booking details'),
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              bookingStatusChip(context, current.status),
            ],
          ),
          const SizedBox(height: Gap.lg),
          _Group(title: context.tr('الحجز', 'Booking'), rows: [
            (context.tr('رقم الحجز', 'Booking no.'), current.reference),
            (context.tr('النوع', 'Type'),
                a != null ? context.tr('كشف عيادة', 'Clinic visit') : context.tr('معمل', 'Laboratory')),
            if (a != null) ...[
              (context.tr('العيادة', 'Clinic'),
                  Seed.clinicById(a.clinicId)?.name(s.localeName) ?? '—'),
              (context.tr('الطبيب', 'Doctor'),
                  Seed.doctorById(a.doctorId).name(s.localeName)),
            ],
            (context.tr('الميعاد', 'When'),
                '${Fmt.weekday(current.at, s)} ${Fmt.date(current.at, s)} · ${Fmt.clock(current.at, s)}'),
            if (a != null && a.fee > 0)
              (context.tr('سعر الكشف', 'Fee'), Fmt.money(a.fee, s)),
            if (lab != null) ...[
              (context.tr('المطلوب', 'Requested'), labItemsSummary(context, lab)),
              (context.tr('الإجمالي', 'Total'), Fmt.money(lab.total, s)),
            ],
            (context.tr('الدفع', 'Payment'),
                context.tr('في الاستقبال', 'At reception')),
            if (current.createdAt != null)
              (context.tr('اتحجز في', 'Booked on'),
                  '${Fmt.date(current.createdAt!, s)} · ${Fmt.clock(current.createdAt!, s)}'),
            if (a?.cancelNote != null) (context.tr('ملاحظة', 'Note'), a!.cancelNote!),
          ]),
          if (lab != null) ...[
            const SizedBox(height: Gap.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final id in lab.packageIds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: Text(
                        '• ${Seed.labPackageById(id)?.name(s.localeName) ?? id}'
                        ' — ${Seed.labPackageById(id)?.tests.join(', ') ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  for (final id in lab.testIds)
                    Text('• ${Seed.labTestById(id)?.name(s.localeName) ?? id}',
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
          const SizedBox(height: Gap.lg),
          if (patient != null)
            PatientDetailsCard(patient: patient)
          else
            InfoNote(context.tr('بيانات المريض غير موجودة', 'Patient record missing'),
                color: AppColors.warning),
          const SizedBox(height: Gap.lg),
          if (current.status == AppointmentStatus.confirmed) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _set(context, current, AppointmentStatus.completed),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                    icon: const Icon(Icons.how_to_reg_outlined),
                    label: Text(context.tr('حضر', 'Attended')),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _set(context, current, AppointmentStatus.noShow),
                    icon: const Icon(Icons.person_off_outlined),
                    label: Text(context.tr('لم يحضر', 'No-show')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            OutlinedButton.icon(
              onPressed: () => _cancel(context, current),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(context.tr('إلغاء الحجز وإبلاغ المريض',
                  'Cancel and notify the patient')),
            ),
          ],
        ],
      ),
    );
  }

  void _set(BuildContext context, BookingRow r, AppointmentStatus status) {
    final state = context.read<AppState>();
    if (r.isLab) {
      state.setLabBookingStatus(r.id, status);
    } else {
      state.setAppointmentStatus(r.id, status);
    }
  }

  Future<void> _cancel(BuildContext context, BookingRow r) async {
    final reasons = <(CancellationReason, String)>[
      (CancellationReason.doctorUnavailable,
          context.tr('اعتذار الطبيب', 'Doctor unavailable')),
      (CancellationReason.clinicClosed,
          context.tr('العيادة مغلقة', 'Clinic closed')),
      (CancellationReason.patientRequested,
          context.tr('بطلب المريض', 'Patient asked')),
      (CancellationReason.other, context.tr('سبب آخر', 'Other')),
    ];
    final reason = await showDialog<CancellationReason>(
      context: context,
      builder: (d) => SimpleDialog(
        title: Text(context.tr('سبب الإلغاء', 'Reason')),
        children: [
          for (final (value, label) in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.of(d).pop(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                child: Text(label),
              ),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    final state = context.read<AppState>();
    if (r.isLab) {
      state.setLabBookingStatus(r.id, AppointmentStatus.cancelled, reason: reason);
    } else {
      state.cancelAppointment(r.id,
          reason: reason,
          note: context.tr('تم إلغاء موعدك من المستشفى. برجاء حجز موعد جديد من التطبيق.',
              'The hospital cancelled your appointment. Please book a new one in the app.'));
    }
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.primary)),
          const SizedBox(height: Gap.sm),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(label,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(
                    child: Text(value,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The patient's full record, as reception needs it.
class PatientDetailsCard extends StatelessWidget {
  const PatientDetailsCard({required this.patient, super.key});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(title: context.tr('بيانات المريض', 'Patient'), rows: [
          (context.tr('الاسم', 'Name'), patient.fullName),
          (context.tr('رقم الملف', 'File no.'), patient.mrn),
          (s.registerNationalId, patient.nationalId ?? '—'),
          (s.registerPhone, patient.phoneLocal),
          (context.tr('السن والنوع', 'Age & sex'), patientAgeSex(context, patient)),
          (s.registerDob, Fmt.date(patient.dateOfBirth, s)),
          if (patient.governorate != null)
            (s.registerGovernorate, patient.governorate!),
          if (patient.email != null) (s.registerEmail, patient.email!),
          if (patient.companyName != null)
            (s.registerCompany, patient.companyName!),
          if (patient.createdAt != null)
            (context.tr('سجّل في', 'Registered'),
                Fmt.date(patient.createdAt!, s)),
        ]),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Launch.call(context, patient.phoneLocal),
                icon: const Icon(Icons.call_outlined),
                label: Text(context.tr('اتصال', 'Call')),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Launch.whatsapp(context, patient.phoneLocal),
                icon: const Icon(Icons.chat_outlined),
                label: Text(context.tr('واتساب', 'WhatsApp')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Every registered patient, searchable.
class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = state.searchPatients(_query.text);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('المرضى', 'Patients'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.tr('اسم، رقم قومي، موبايل أو رقم ملف',
                    'Name, National ID, mobile or file no.'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    message: context.tr('مفيش مرضى مسجلين لسه', 'No patients yet'),
                    icon: Icons.people_outline)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = results[i];
                      final count = state
                          .allBookings()
                          .where((r) => r.patientId == p.id)
                          .length;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryTint,
                          child: Text(p.firstName.characters.first,
                              style: const TextStyle(color: AppColors.primary)),
                        ),
                        title: Text(p.fullName),
                        subtitle: Text(
                            '${p.phoneLocal} · ${patientAgeSex(context, p)} · '
                            '${context.tr('$count حجز', '$count bookings')}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin/patients/${p.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AdminPatientDetailScreen extends StatelessWidget {
  const AdminPatientDetailScreen({required this.patientId, super.key});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final patient = state.patientById(patientId);
    if (patient == null) {
      return Scaffold(
          appBar: AppBar(),
          body: EmptyState(
              message: context.tr('المريض غير موجود', 'Patient not found')));
    }
    final rows = state.allBookings().where((r) => r.patientId == patientId).toList();
    return Scaffold(
      appBar: AppBar(title: Text(patient.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          PatientDetailsCard(patient: patient),
          const SizedBox(height: Gap.xl),
          SectionHeader(context.tr('الحجوزات', 'Bookings')),
          if (rows.isEmpty)
            EmptyState(message: context.s.bookingsEmpty, icon: Icons.event_note)
          else
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: _AdminBookingCard(row: r),
              ),
        ],
      ),
    );
  }
}

/// Complaints, open first, answered from here.
class AdminComplaintsScreen extends StatelessWidget {
  const AdminComplaintsScreen({super.key});

  static String categoryLabel(BuildContext context, ComplaintCategory c) =>
      switch (c) {
        ComplaintCategory.appointment => context.tr('المواعيد', 'Appointments'),
        ComplaintCategory.clinicalCare => context.tr('الرعاية الطبية', 'Clinical care'),
        ComplaintCategory.nursing => context.tr('التمريض', 'Nursing'),
        ComplaintCategory.cleanliness => context.tr('النظافة', 'Cleanliness'),
        ComplaintCategory.billing => context.tr('الحسابات', 'Billing'),
        ComplaintCategory.staffConduct => context.tr('سلوك الموظفين', 'Staff conduct'),
        ComplaintCategory.facilities => context.tr('المرافق', 'Facilities'),
        ComplaintCategory.other => context.tr('أخرى', 'Other'),
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final list = [...state.complaints]
      ..sort((a, b) {
        if (a.isResolved != b.isResolved) return a.isResolved ? 1 : -1;
        return b.submittedAt.compareTo(a.submittedAt);
      });
    return Scaffold(
      appBar: AppBar(title: Text(s.complaintsTitle)),
      body: list.isEmpty
          ? EmptyState(
              message: context.tr('مفيش شكاوى', 'No complaints'),
              icon: Icons.feedback_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(Gap.lg),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: Gap.md),
              itemBuilder: (context, i) {
                final c = list[i];
                final patient =
                    c.patientId == null ? null : state.patientById(c.patientId!);
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                                '${c.reference} · ${categoryLabel(context, c.category)}',
                                style: Theme.of(context).textTheme.titleSmall),
                          ),
                          StatusChip(
                            c.isResolved
                                ? context.tr('تم الرد', 'Answered')
                                : context.tr('مفتوحة', 'Open'),
                            color: c.isResolved ? AppColors.success : AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      Text(c.body),
                      const SizedBox(height: Gap.sm),
                      Text(
                        '${patient?.fullName ?? context.tr('بدون اسم', 'Anonymous')} · '
                        '${Fmt.date(c.submittedAt, s)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (c.response != null) ...[
                        const SizedBox(height: Gap.sm),
                        InfoNote(c.response!, icon: Icons.reply, color: AppColors.success),
                      ],
                      if (!c.isResolved) ...[
                        const SizedBox(height: Gap.md),
                        Row(
                          children: [
                            if (patient != null)
                              TextButton.icon(
                                onPressed: () => Launch.call(context, patient.phoneLocal),
                                icon: const Icon(Icons.call_outlined),
                                label: Text(context.tr('اتصال', 'Call')),
                              ),
                            const Spacer(),
                            FilledButton(
                              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                              onPressed: () => _respond(context, c),
                              child: Text(context.tr('رد وإغلاق', 'Reply & close')),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _respond(BuildContext context, Complaint c) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(context.tr('الرد على الشكوى', 'Reply')),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
              hintText: context.tr('اكتب الرد اللي هيوصل للمريض',
                  'Write the reply the patient will see')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(),
              child: Text(context.s.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(d).pop(controller.text.trim()),
            child: Text(context.tr('إرسال', 'Send')),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    context.read<AppState>().resolveComplaint(c.id, text);
  }
}

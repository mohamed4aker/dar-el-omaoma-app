import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/utils/launch.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/catalog.dart';
import '../bookings/patient_picker.dart';

/// Deck slide 5: اختر عيادة → اختر الطبيب → احجز.
///
/// With 40+ clinics and 150 doctors, the list is searchable by clinic and by
/// doctor: most patients arrive knowing the doctor's name, not the clinic.
class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    final q = foldArabic(_query.text.trim());

    final clinics = q.isEmpty
        ? Seed.clinics
        : Seed.clinics
            .where((c) => foldArabic(c.name(s.localeName)).contains(q))
            .toList();
    final doctors = q.length < 2
        ? const <Doctor>[]
        : Seed.doctors
            .where((d) =>
                foldArabic(d.name(s.localeName)).contains(q) &&
                Seed.clinicsOf(d.id).isNotEmpty)
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.clinicsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          TextField(
            controller: _query,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: context.tr('ابحث باسم العيادة أو الطبيب',
                  'Search by clinic or doctor'),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.tr('مسح', 'Clear'),
                      onPressed: () => setState(_query.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Gap.lg),
          if (doctors.isNotEmpty) ...[
            SectionHeader(context.tr('الأطباء', 'Doctors')),
            for (final d in doctors)
              for (final c in Seed.clinicsOf(d.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.md),
                  child: _DoctorCard(clinic: c, doctor: d, showClinic: true),
                ),
            const SizedBox(height: Gap.md),
          ],
          if (clinics.isNotEmpty) SectionHeader(s.clinicsChoose),
          for (final clinic in clinics)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                onTap: () => context.push('/clinics/${clinic.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_outlined,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clinic.name(s.localeName),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: Gap.xs),
                          Wrap(
                            spacing: Gap.sm,
                            runSpacing: Gap.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                doctorCount(context, clinic.doctorIds.length),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (clinic.note != null)
                                StatusChip(clinic.note!,
                                    color: AppColors.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          if (clinics.isEmpty && doctors.isEmpty)
            EmptyState(
              message: context.tr('مفيش نتايج', 'No results'),
              icon: Icons.search_off,
            ),
        ],
      ),
    );
  }
}

/// Spelling-insensitive Arabic matching: أ/إ/آ → ا, ة → ه, ى → ي.
String foldArabic(String text) => text
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase();

/// "طبيب واحد" / "طبيبان" / "5 أطباء" / "12 طبيب".
String doctorCount(BuildContext context, int n) {
  if (context.s.localeName == 'en') return '$n ${n == 1 ? 'doctor' : 'doctors'}';
  if (n == 1) return 'طبيب واحد';
  if (n == 2) return 'طبيبان';
  if (n <= 10) return '$n أطباء';
  return '$n طبيب';
}

/// A clinic and its doctors, each with their timetable and a booking button.
class ClinicDetailScreen extends StatelessWidget {
  const ClinicDetailScreen({required this.clinicId, super.key});

  final String clinicId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();
    final clinic = Seed.clinicById(clinicId);
    if (clinic == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
            message: context.tr('العيادة غير متاحة', 'Clinic unavailable')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(clinic.name(s.localeName))),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(s.clinicConsultationFee,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    if (clinic.consultationFee > 0)
                      PriceText(clinic.consultationFee, currency: s.commonEgp)
                    else
                      Text(context.tr('يُحدد في الاستقبال', 'Set at reception'),
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                if (clinic.note != null) ...[
                  const SizedBox(height: Gap.sm),
                  StatusChip(clinic.note!, color: AppColors.warning),
                ],
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
          SectionHeader(s.clinicChooseDoctor),
          for (final id in clinic.doctorIds)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: _DoctorCard(clinic: clinic, doctor: Seed.doctorById(id)),
            ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.clinic,
    required this.doctor,
    this.showClinic = false,
  });

  final Clinic clinic;
  final Doctor doctor;
  final bool showClinic;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final title = doctor.title(s.localeName);
    final specialty = doctor.specialty(s.localeName);
    final subtitle = [
      if (title.isNotEmpty) title,
      if (specialty.isNotEmpty) specialty,
    ].join(' · ');
    final shifts = [...doctor.shifts]
      ..sort((a, b) => weekOrder(a.weekday).compareTo(weekOrder(b.weekday)));
    final note = doctor.scheduleNote;
    // The hospital's own wording is shown whenever it says something the
    // day chips cannot: own patients only, by appointment, two sessions.
    final showNote = note != null &&
        (!doctor.isBookableOnline || note.contains('فقط'));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryTint,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.name(s.localeName),
                        style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    if (showClinic)
                      Text(clinic.name(s.localeName),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.accent)),
                  ],
                ),
              ),
            ],
          ),
          if (shifts.isNotEmpty) ...[
            const SizedBox(height: Gap.md),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final sh in shifts)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Gap.sm, vertical: Gap.xs),
                    decoration: BoxDecoration(
                      color: AppColors.accentTint,
                      borderRadius: BorderRadius.circular(Radii.input),
                    ),
                    child: Text(
                      '${Fmt.weekdayName(sh.weekday, s)} '
                      '${Fmt.minutesClock(sh.startsAt, s)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.accentDark),
                    ),
                  ),
              ],
            ),
          ],
          if (showNote) ...[
            const SizedBox(height: Gap.md),
            Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: Gap.md),
          if (doctor.isBookableOnline)
            FilledButton.icon(
              onPressed: () =>
                  context.push('/clinics/${clinic.id}/doctor/${doctor.id}'),
              icon: const Icon(Icons.event_available),
              label: Text(context.tr('احجز مع الدكتور', 'Book with this doctor')),
            )
          else
            OutlinedButton.icon(
              onPressed: () => Launch.call(context, Seed.emergencyPhone),
              icon: const Icon(Icons.call_outlined),
              label: Text(context.tr('الحجز بالتليفون', 'Book by phone')),
            ),
        ],
      ),
    );
  }
}

/// Saturday first: the Egyptian working week.
int weekOrder(int isoWeekday) => (isoWeekday + 1) % 7;

/// Choose a day and a time with one doctor.
class DoctorBookingScreen extends StatefulWidget {
  const DoctorBookingScreen({
    required this.clinicId,
    required this.doctorId,
    super.key,
  });

  final String clinicId;
  final String doctorId;

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  DateTime? _day;
  bool _busy = false;

  static const _horizon = 28;

  List<DateTime> _workingDays(Doctor doctor) {
    final today = Seed.today;
    return [
      for (var i = 0; i < _horizon; i++)
        if (doctor.worksOn(today.add(Duration(days: i)).weekday))
          today.add(Duration(days: i)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final clinic = Seed.clinicById(widget.clinicId);
    final doctor = Seed.doctorById(widget.doctorId);
    if (clinic == null || !doctor.isBookableOnline) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
            message: context.tr('الحجز غير متاح', 'Booking unavailable')),
      );
    }

    final days = _workingDays(doctor);
    // First day that still has a slot, so the screen never opens on a full
    // or already-finished day.
    _day ??= days.firstWhere(
      (d) => state.clinicSlots(clinic, d, doctorId: doctor.id).isNotEmpty,
      orElse: () => days.isEmpty ? Seed.today : days.first,
    );
    final day = _day!;
    final slots = state.clinicSlots(clinic, day, doctorId: doctor.id);
    final remaining = state.remainingCapacity(doctor, day);

    return Scaffold(
      appBar: AppBar(title: Text(doctor.name(s.localeName))),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryTint,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name(s.localeName),
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(clinic.name(s.localeName),
                          style: Theme.of(context).textTheme.bodySmall),
                      if (doctor.title(s.localeName).isNotEmpty)
                        Text(doctor.title(s.localeName),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
          SectionHeader(context.tr('اختر اليوم', 'Choose a day')),
          SizedBox(
            height: 66,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
              itemBuilder: (context, i) {
                final d = days[i];
                final selected = Fmt.isSameDay(d, day);
                final full =
                    state.clinicSlots(clinic, d, doctorId: doctor.id).isEmpty;
                return InkWell(
                  borderRadius: BorderRadius.circular(Radii.input),
                  onTap: () => setState(() => _day = d),
                  child: Container(
                    width: 76,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : null,
                      borderRadius: BorderRadius.circular(Radii.input),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Fmt.weekday(d, s),
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white70 : AppColors.muted,
                          ),
                        ),
                        Text(
                          Fmt.shortDate(d, s),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: full && !selected
                                ? TextDecoration.lineThrough
                                : null,
                            color: selected
                                ? Colors.white
                                : full
                                    ? AppColors.muted
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: Gap.lg),
          if (remaining != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: InfoNote(
                remaining == 0
                    ? s.capacityFull
                    : '$remaining ${s.capacityRemaining}',
                icon: remaining == 0
                    ? Icons.event_busy_outlined
                    : Icons.groups_outlined,
                color: remaining == 0 ? AppColors.danger : AppColors.success,
              ),
            ),
          SectionHeader(context.tr('اختر الميعاد', 'Choose a time')),
          if (slots.isEmpty)
            EmptyState(message: s.clinicNoSlots, icon: Icons.event_busy)
          else
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final slot in slots)
                  OutlinedButton(
                    onPressed:
                        _busy ? null : () => _book(clinic, doctor, slot),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, kMinTouchTarget),
                      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                    ),
                    child: Text(Fmt.clock(slot, s)),
                  ),
              ],
            ),
          const SizedBox(height: Gap.xl),
          InfoNote(
            context.tr(
                'الحجز بيتأكد فورًا. الدفع في الاستقبال، ومفيش دفع مسبق.',
                'Bookings are confirmed immediately. Payment is at reception; nothing is paid in advance.'),
            icon: Icons.bolt_outlined,
            color: AppColors.success,
          ),
          if (doctor.scheduleNote != null) ...[
            const SizedBox(height: Gap.md),
            InfoNote(
              '${context.tr('مواعيد الطبيب حسب المستشفى', "The hospital's timetable for this doctor")}:\n'
              '${doctor.scheduleNote}',
              icon: Icons.schedule,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _book(Clinic clinic, Doctor doctor, DateTime slot) async {
    final s = context.s;
    final patient = await resolveBookingPatient(context);
    if (patient == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('تأكيد الحجز', 'Confirm booking')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(Icons.person_outline, patient.fullName),
            _line(Icons.local_hospital_outlined, clinic.name(s.localeName)),
            _line(Icons.medical_services_outlined, doctor.name(s.localeName)),
            _line(Icons.event, '${Fmt.weekday(slot, s)} ${Fmt.date(slot, s)}'),
            _line(Icons.schedule, Fmt.clock(slot, s)),
            if (clinic.consultationFee > 0)
              _line(Icons.payments_outlined,
                  '${Fmt.money(clinic.consultationFee, s)} — ${context.tr('في الاستقبال', 'at reception')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(context.tr('تأكيد', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final state = context.read<AppState>();
    final outcome = state.bookClinicAppointment(
      patientId: patient.id,
      clinicId: clinic.id,
      doctorId: doctor.id,
      start: slot,
    );
    setState(() => _busy = false);
    if (!mounted) return;

    switch (outcome) {
      case AppointmentBooked(:final appointment):
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.check_circle,
                color: AppColors.success, size: 44),
            title: Text(s.bookingConfirmedTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${doctor.name(s.localeName)}\n'
                  '${Fmt.weekday(slot, s)} ${Fmt.date(slot, s)} · ${Fmt.clock(slot, s)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: Gap.md),
                Text(
                    '${context.tr('رقم الحجز', 'Booking number')}: ${appointment.reference}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Gap.sm),
                Text(
                  context.tr('احضر قبل الميعاد بربع ساعة ومعاك البطاقة.',
                      'Please arrive 15 minutes early with your ID card.'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(s.commonClose),
              ),
              if (!state.session.isStaff)
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.push('/bookings');
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: Text(s.bookingsTitle),
                ),
            ],
          ),
        );
      case AppointmentSlotGone():
        _snack(context.tr('الميعاد ده اتحجز حالًا، اختار ميعاد تاني.',
            'That time was just taken — please pick another.'));
      case AppointmentDuplicate():
        _snack(context.tr('فيه حجز بالفعل مع نفس الطبيب في نفس اليوم.',
            'There is already a booking with this doctor on this day.'));
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.sm),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: Gap.sm),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

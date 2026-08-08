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

/// Deck slide 5: اختر عيادة → احجز الآن.
class ClinicsScreen extends StatelessWidget {
  const ClinicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.clinicsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          SectionHeader(s.clinicsChoose),
          for (final clinic in Seed.clinics)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: AppCard(
                onTap: () => context.push('/clinics/${clinic.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clinic.name(s.localeName),
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: Gap.xs),
                          Text(
                            '${s.clinicConsultationFee}: '
                            '${Fmt.money(clinic.consultationFee, s)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ClinicDetailScreen extends StatefulWidget {
  const ClinicDetailScreen({required this.clinicId, super.key});

  final String clinicId;

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  DateTime _day = Seed.today;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final clinic = Seed.clinics.firstWhere((c) => c.id == widget.clinicId);
    final slots = state.clinicSlots(clinic, _day);

    return Scaffold(
      appBar: AppBar(title: Text(clinic.name(s.localeName))),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: _Fee(
                    label: s.clinicConsultationFee,
                    amount: clinic.consultationFee,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Theme.of(context).colorScheme.outline,
                ),
                Expanded(
                  child: _Fee(
                    label: s.clinicFollowUpFee,
                    amount: clinic.followUpFee,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.xl),
          SectionHeader(s.clinicChooseDoctor),
          for (final id in clinic.doctorIds)
            Builder(builder: (context) {
              final doctor = Seed.doctorById(id);
              return Padding(
                padding: const EdgeInsets.only(bottom: Gap.md),
                child: AppCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.navyTint,
                        child: Icon(Icons.person, color: AppColors.navy),
                      ),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctor.name(s.localeName),
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${doctor.title(s.localeName)} · '
                              '${doctor.specialty(s.localeName)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: Gap.lg),
          SectionHeader(s.clinicChooseSlot),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
              itemBuilder: (context, index) {
                final day = Seed.today.add(Duration(days: index));
                final selected = Fmt.isSameDay(day, _day);
                final open = clinic.workingDays.contains(day.weekday);
                return GestureDetector(
                  onTap: () => setState(() => _day = day),
                  child: Container(
                    width: 70,
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
                        Text(
                          Fmt.weekday(day, s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white70
                                : open
                                    ? AppColors.muted
                                    : AppColors.muted
                                        .withValues(alpha: 0.4),
                          ),
                        ),
                        Text(
                          Fmt.shortDate(day, s),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
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
          if (slots.isEmpty)
            EmptyState(message: s.clinicNoSlots, icon: Icons.event_busy)
          else
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final slot in slots)
                  OutlinedButton(
                    onPressed: () => _book(clinic, slot),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, kMinTouchTarget),
                      padding:
                          const EdgeInsets.symmetric(horizontal: Gap.lg),
                    ),
                    child: Text(Fmt.time(slot)),
                  ),
              ],
            ),
          const SizedBox(height: Gap.xl),
          // Clinic booking is immediate for patients; only theatre bookings
          // require approval (PROMPT.md 6.13.6).
          InfoNote(
            s.localeName == 'en'
                ? 'Clinic appointments are confirmed immediately.'
                : 'حجز العيادة يتم فورًا بدون انتظار موافقة.',
            icon: Icons.bolt_outlined,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Future<void> _book(Clinic clinic, DateTime slot) async {
    final s = context.s;
    final state = context.read<AppState>();
    final patient = state.session.patient;
    if (patient == null) {
      context.push('/login');
      return;
    }
    state.bookClinicAppointment(
      patientId: patient.id,
      clinicId: clinic.id,
      doctorId: clinic.doctorIds.first,
      start: slot,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle,
            color: AppColors.success, size: 40),
        title: Text(s.bookingConfirmedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${clinic.name(s.localeName)}\n'
              '${Fmt.weekday(slot, s)} ${Fmt.date(slot, s)} · ${Fmt.time(slot)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Gap.md),
            Text(s.bookingConfirmedBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Gap.md),
            StatusChip(s.bookingPayAtReception, color: AppColors.warning),
          ],
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

class _Fee extends StatelessWidget {
  const _Fee({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Gap.xs),
        PriceText(amount, currency: s.commonEgp),
      ],
    );
  }
}

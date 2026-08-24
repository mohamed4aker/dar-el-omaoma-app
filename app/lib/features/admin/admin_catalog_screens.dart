import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/enums.dart';
import 'admin_governance_screens.dart' show paymentPolicyLabel, paymentPolicyNote;
import 'shift_editor.dart';
import 'admin_widgets.dart';

// ---------------------------------------------------------- classifications

/// Operation classifications — صغرى / متوسطة / كبرى / ذات مهارة.
///
/// This screen is the reason the classification is modelled as data rather
/// than an enum (PROMPT.md §6.13.2): the administrator adds, renames,
/// recolours and deactivates them here, and the booking sheet, availability
/// grid and reports pick the change up immediately, with no release.
class ClassificationsAdminScreen extends StatelessWidget {
  const ClassificationsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final items = [...Seed.classifications]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return AdminListScaffold(
      title: s.adminClassifications,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      note: InfoNote(s.adminClassificationsNote,
          icon: Icons.auto_awesome_outlined),
      children: [
        for (final c in items)
          AdminRow(
            title: c.name(s.localeName),
            subtitle: '${Fmt.duration(c.defaultDuration, s)} · '
                '${s.theatreTurnover} ${Fmt.duration(c.defaultTurnover, s)} · '
                '${Fmt.moneyRange(c.priceMin, c.priceMax, s)}',
            dimmed: !c.isActive,
            leading: Container(
              width: 18,
              height: 18,
              decoration:
                  BoxDecoration(color: c.colour, shape: BoxShape.circle),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!c.isActive)
                  StatusChip(s.adminInactive, color: AppColors.muted),
                Switch(
                  value: c.isActive,
                  onChanged: (v) =>
                      state.setClassificationActive(c.id, v),
                ),
              ],
            ),
            onTap: () => _openForm(context, c),
          ),
      ],
    );
  }

  void _openForm(BuildContext context, OperationClassification? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ClassificationForm(existing: existing),
    );
  }
}

class _ClassificationForm extends StatefulWidget {
  const _ClassificationForm({this.existing});
  final OperationClassification? existing;

  @override
  State<_ClassificationForm> createState() => _ClassificationFormState();
}

class _ClassificationFormState extends State<_ClassificationForm> {
  late final _nameAr =
      TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _nameEn =
      TextEditingController(text: widget.existing?.name.en ?? '');
  late final _code = TextEditingController(text: widget.existing?.code ?? '');
  late final _duration = TextEditingController(
      text: '${widget.existing?.defaultDuration.inMinutes ?? 90}');
  late final _turnover = TextEditingController(
      text: '${widget.existing?.defaultTurnover.inMinutes ?? 30}');
  late final _priceMin =
      TextEditingController(text: '${widget.existing?.priceMin ?? 10000}');
  late final _priceMax =
      TextEditingController(text: '${widget.existing?.priceMax ?? 40000}');
  late final _anaesthesiaAr = TextEditingController(
      text: widget.existing?.defaultAnaesthesia.ar ?? 'كلي');
  late final _anaesthesiaEn = TextEditingController(
      text: widget.existing?.defaultAnaesthesia.en ?? '');
  late Color _colour = widget.existing?.colour ?? ColourPicker.options.first;
  late int _seniority = widget.existing?.requiredSeniority ?? 2;
  late int _bloodUnits = widget.existing?.defaultBloodUnits ?? 0;

  @override
  void dispose() {
    for (final c in [
      _nameAr, _nameEn, _code, _duration, _turnover,
      _priceMin, _priceMax, _anaesthesiaAr, _anaesthesiaEn,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AdminFormSheet(
      title: widget.existing == null
          ? s.adminNewClassification
          : s.adminEditClassification,
      saveEnabled: _nameAr.text.trim().isNotEmpty,
      onSave: _save,
      children: [
        BilingualFields(
          arController: _nameAr,
          enController: _nameEn,
          label: s.adminName,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _code,
          label: s.adminCode,
          hint: 'major',
          textDirection: TextDirection.ltr,
        ),
        AdminSectionLabel(s.adminColour),
        ColourPicker(
          selected: _colour,
          onSelect: (c) => setState(() => _colour = c),
        ),
        AdminSectionLabel(s.adminSchedulingDefaults),
        InfoNote(s.adminDefaultsNote, icon: Icons.info_outline),
        const SizedBox(height: Gap.lg),
        Row(
          children: [
            Expanded(
              child: AdminField(
                controller: _duration,
                label: '${s.surgeryDuration} (${s.commonMinutes})',
                digitsOnly: true,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: AdminField(
                controller: _turnover,
                label: '${s.theatreTurnover} (${s.commonMinutes})',
                digitsOnly: true,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: AdminField(
                controller: _priceMin,
                label: '${s.adminPriceFrom} (${s.commonEgp})',
                digitsOnly: true,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: AdminField(
                controller: _priceMax,
                label: '${s.adminPriceTo} (${s.commonEgp})',
                digitsOnly: true,
              ),
            ),
          ],
        ),
        BilingualFields(
          arController: _anaesthesiaAr,
          enController: _anaesthesiaEn,
          label: s.adminAnaesthesia,
        ),
        AdminSectionLabel(s.adminRequiredSeniority),
        InfoNote(s.adminSeniorityNote, icon: Icons.badge_outlined),
        const SizedBox(height: Gap.md),
        Slider(
          value: _seniority.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_seniority',
          onChanged: (v) => setState(() => _seniority = v.round()),
        ),
        AdminSectionLabel('${s.adminBloodUnits}: $_bloodUnits'),
        InfoNote(s.adminBloodNote, icon: Icons.bloodtype_outlined),
        const SizedBox(height: Gap.md),
        Slider(
          value: _bloodUnits.toDouble(),
          min: 0,
          max: 8,
          divisions: 8,
          label: '$_bloodUnits',
          onChanged: (v) => setState(() => _bloodUnits = v.round()),
        ),
      ],
    );
  }

  void _save() {
    context.read<AppState>().upsertClassification(
          id: widget.existing?.id,
          code: _code.text.trim().isEmpty
              ? _nameAr.text.trim()
              : _code.text.trim(),
          name: BilingualFields.toLabel(_nameAr, _nameEn),
          colour: _colour,
          defaultDuration: Duration(minutes: parseIntOr(_duration.text, 90)),
          defaultTurnover: Duration(minutes: parseIntOr(_turnover.text, 30)),
          priceMin: parseIntOr(_priceMin.text, 0),
          priceMax: parseIntOr(_priceMax.text, 0),
          requiredSeniority: _seniority,
          defaultAnaesthesia:
              BilingualFields.toLabel(_anaesthesiaAr, _anaesthesiaEn),
          defaultBloodUnits: _bloodUnits,
          isActive: widget.existing?.isActive ?? true,
        );
    Navigator.of(context).pop();
  }
}

// ------------------------------------------------------------- procedures

class ProceduresAdminScreen extends StatelessWidget {
  const ProceduresAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();

    return AdminListScaffold(
      title: s.adminProcedures,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      children: [
        for (final p in Seed.procedures)
          Builder(builder: (context) {
            final c = Seed.classificationById(p.classificationId);
            return AdminRow(
              title: p.name(s.localeName),
              subtitle: '${p.code} · ${Fmt.duration(p.typicalDuration, s)} · '
                  '${Fmt.money(p.price, s)}',
              leading: Container(
                width: 18,
                height: 18,
                decoration:
                    BoxDecoration(color: c.colour, shape: BoxShape.circle),
              ),
              trailing: StatusChip(c.name(s.localeName), color: c.colour),
              onTap: () => _openForm(context, p),
            );
          }),
      ],
    );
  }

  void _openForm(BuildContext context, Procedure? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProcedureForm(existing: existing),
    );
  }
}

class _ProcedureForm extends StatefulWidget {
  const _ProcedureForm({this.existing});
  final Procedure? existing;

  @override
  State<_ProcedureForm> createState() => _ProcedureFormState();
}

class _ProcedureFormState extends State<_ProcedureForm> {
  late final _nameAr =
      TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _nameEn =
      TextEditingController(text: widget.existing?.name.en ?? '');
  late final _code = TextEditingController(text: widget.existing?.code ?? '');
  late final _price =
      TextEditingController(text: '${widget.existing?.price ?? 0}');
  late final _duration = TextEditingController(
      text: '${widget.existing?.typicalDuration.inMinutes ?? 90}');

  late String _classificationId = widget.existing?.classificationId ??
      Seed.classifications.firstWhere((c) => c.isActive).id;
  late TheatreType _theatreType =
      widget.existing?.requiredTheatreType ?? TheatreType.general;
  late String? _centreId = widget.existing?.centreId;
  late bool _patientRequestable = widget.existing?.patientRequestable ?? true;

  @override
  void dispose() {
    for (final c in [_nameAr, _nameEn, _code, _price, _duration]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Selecting a classification pre-fills duration from its default, so the
  /// administrator is not retyping what the classification already knows.
  void _applyClassificationDefaults(String id) {
    final c = Seed.classificationById(id);
    setState(() {
      _classificationId = id;
      if (widget.existing == null) {
        _duration.text = '${c.defaultDuration.inMinutes}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AdminFormSheet(
      title: widget.existing == null
          ? s.adminNewProcedure
          : s.adminEditProcedure,
      saveEnabled: _nameAr.text.trim().isNotEmpty,
      onSave: _save,
      children: [
        BilingualFields(
          arController: _nameAr,
          enController: _nameEn,
          label: s.adminName,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _code,
          label: s.adminCode,
          hint: 'ORT-ACL',
          textDirection: TextDirection.ltr,
        ),
        AdminSectionLabel(s.surgeryClassification),
        DropdownButtonFormField<String>(
          initialValue: _classificationId,
          isExpanded: true,
          items: [
            for (final c in Seed.classifications.where((c) => c.isActive))
              DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: c.colour, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: Gap.sm),
                    Text(c.name(s.localeName)),
                  ],
                ),
              ),
          ],
          onChanged: (id) =>
              id == null ? null : _applyClassificationDefaults(id),
        ),
        const SizedBox(height: Gap.lg),
        Row(
          children: [
            Expanded(
              child: AdminField(
                controller: _duration,
                label: '${s.surgeryDuration} (${s.commonMinutes})',
                digitsOnly: true,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: AdminField(
                controller: _price,
                label: '${s.adminPrice} (${s.commonEgp})',
                digitsOnly: true,
              ),
            ),
          ],
        ),
        AdminSectionLabel(s.adminTheatreType),
        DropdownButtonFormField<TheatreType>(
          initialValue: _theatreType,
          isExpanded: true,
          items: [
            for (final t in TheatreType.values)
              DropdownMenuItem(value: t, child: Text(theatreTypeLabel(t, s))),
          ],
          onChanged: (t) => setState(() => _theatreType = t ?? _theatreType),
        ),
        const SizedBox(height: Gap.lg),
        AdminSectionLabel(s.adminCentre),
        DropdownButtonFormField<String?>(
          initialValue: _centreId,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: null, child: Text(s.adminNoCentre)),
            for (final centre in Seed.centres)
              DropdownMenuItem(
                  value: centre.id, child: Text(centre.name(s.localeName))),
          ],
          onChanged: (id) => setState(() => _centreId = id),
        ),
        const SizedBox(height: Gap.lg),
        SwitchListTile(
          value: _patientRequestable,
          onChanged: (v) => setState(() => _patientRequestable = v),
          contentPadding: EdgeInsets.zero,
          title: Text(s.adminPatientRequestable,
              style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(s.adminPatientRequestableNote,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  void _save() {
    context.read<AppState>().upsertProcedure(
          id: widget.existing?.id,
          code: _code.text.trim().isEmpty ? 'PROC' : _code.text.trim(),
          name: BilingualFields.toLabel(_nameAr, _nameEn),
          classificationId: _classificationId,
          typicalDuration: Duration(minutes: parseIntOr(_duration.text, 90)),
          requiredTheatreType: _theatreType,
          price: parseIntOr(_price.text, 0),
          centreId: _centreId,
          requiredEquipment: widget.existing?.requiredEquipment ?? const [],
          patientRequestable: _patientRequestable,
        );
    Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------- clinics

class ClinicsAdminScreen extends StatelessWidget {
  const ClinicsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();

    return AdminListScaffold(
      title: s.adminClinics,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      children: [
        for (final clinic in Seed.clinics)
          AdminRow(
            title: clinic.name(s.localeName),
            subtitle: '${s.clinicConsultationFee} '
                '${Fmt.money(clinic.consultationFee, s)} · '
                '${clinic.doctorIds.length} ${s.adminDoctorsCount}',
            onTap: () => _openForm(context, clinic),
          ),
      ],
    );
  }

  void _openForm(BuildContext context, Clinic? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ClinicForm(existing: existing),
    );
  }
}

class _ClinicForm extends StatefulWidget {
  const _ClinicForm({this.existing});
  final Clinic? existing;

  @override
  State<_ClinicForm> createState() => _ClinicFormState();
}

class _ClinicFormState extends State<_ClinicForm> {
  late final _nameAr =
      TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _nameEn =
      TextEditingController(text: widget.existing?.name.en ?? '');
  late final _fee = TextEditingController(
      text: '${widget.existing?.consultationFee ?? 500}');
  late final _followUp =
      TextEditingController(text: '${widget.existing?.followUpFee ?? 250}');
  late final List<int> _days = [...?widget.existing?.workingDays];
  late final List<String> _doctorIds = [...?widget.existing?.doctorIds];
  late String? _centreId = widget.existing?.centreId;
  late PaymentPolicy _payment =
      widget.existing?.paymentPolicy ?? PaymentPolicy.payAtReception;
  late final _deposit =
      TextEditingController(text: '${widget.existing?.depositAmount ?? 0}');

  @override
  void dispose() {
    for (final c in [_nameAr, _nameEn, _fee, _followUp, _deposit]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AdminFormSheet(
      title: widget.existing == null ? s.adminNewClinic : s.adminEditClinic,
      saveEnabled: _nameAr.text.trim().isNotEmpty &&
          _doctorIds.isNotEmpty &&
          _days.isNotEmpty,
      onSave: _save,
      children: [
        BilingualFields(
          arController: _nameAr,
          enController: _nameEn,
          label: s.adminName,
          onChanged: (_) => setState(() {}),
        ),
        Row(
          children: [
            Expanded(
              child: AdminField(
                controller: _fee,
                label: '${s.clinicConsultationFee} (${s.commonEgp})',
                digitsOnly: true,
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: AdminField(
                controller: _followUp,
                label: '${s.clinicFollowUpFee} (${s.commonEgp})',
                digitsOnly: true,
              ),
            ),
          ],
        ),
        AdminSectionLabel(s.adminWorkingDays),
        WeekdayPicker(
          selected: _days,
          onToggle: (day) => setState(() {
            _days.contains(day) ? _days.remove(day) : _days.add(day);
          }),
        ),
        AdminSectionLabel(s.adminDoctors),
        if (Seed.doctors.isEmpty)
          InfoNote(s.adminAddDoctorFirst, color: AppColors.warning)
        else
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final doctor in Seed.doctors)
                FilterChip(
                  label: Text(doctor.name(s.localeName)),
                  selected: _doctorIds.contains(doctor.id),
                  onSelected: (_) => setState(() {
                    _doctorIds.contains(doctor.id)
                        ? _doctorIds.remove(doctor.id)
                        : _doctorIds.add(doctor.id);
                  }),
                ),
            ],
          ),
        const SizedBox(height: Gap.lg),
        AdminSectionLabel(s.adminCentre),
        DropdownButtonFormField<String?>(
          initialValue: _centreId,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: null, child: Text(s.adminNoCentre)),
            for (final centre in Seed.centres)
              DropdownMenuItem(
                  value: centre.id, child: Text(centre.name(s.localeName))),
          ],
          onChanged: (id) => setState(() => _centreId = id),
        ),
        const SizedBox(height: Gap.xl),

        // Payment never blocks a booking. This only decides whether the app
        // offers to take money, and whether a deposit holds the slot.
        AdminSectionLabel(s.adminPaymentPolicy),
        for (final option in PaymentPolicy.values)
          RadioListTile<PaymentPolicy>(
            value: option,
            // ignore: deprecated_member_use
            groupValue: _payment,
            // ignore: deprecated_member_use
            onChanged: (v) => setState(() => _payment = v ?? _payment),
            contentPadding: EdgeInsets.zero,
            title: Text(paymentPolicyLabel(option, s),
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(paymentPolicyNote(option, s),
                style: Theme.of(context).textTheme.bodySmall),
          ),
        if (_payment.requiresDeposit) ...[
          const SizedBox(height: Gap.md),
          AdminField(
            controller: _deposit,
            label: '${s.adminDepositAmount} (${s.commonEgp})',
            digitsOnly: true,
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final existing = widget.existing;

    if (existing != null) {
      final broken = state.appointmentsBrokenBy(
        clinicId: existing.id,
        newWorkingDays: _days,
      );
      if (broken.isNotEmpty) {
        final proceed = await confirmScheduleImpact(context, broken.length);
        if (proceed != true) return;
        state.cancelBrokenAppointments(broken);
      }
    }

    if (!mounted) return;
    state.upsertClinic(
      id: existing?.id,
      name: BilingualFields.toLabel(_nameAr, _nameEn),
      consultationFee: parseIntOr(_fee.text, 0),
      followUpFee: parseIntOr(_followUp.text, 0),
      doctorIds: _doctorIds,
      workingDays: _days,
      centreId: _centreId,
      paymentPolicy: _payment,
      depositAmount: parseIntOr(_deposit.text, 0),
    );
    if (mounted) Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------- doctors

class DoctorsAdminScreen extends StatelessWidget {
  const DoctorsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();

    return AdminListScaffold(
      title: s.adminDoctors,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      note: InfoNote(s.adminSeniorityNote, icon: Icons.badge_outlined),
      children: [
        for (final doctor in Seed.doctors)
          AdminRow(
            title: doctor.name(s.localeName),
            subtitle: '${doctor.title(s.localeName)} · '
                '${doctor.specialty(s.localeName)}'
                '${doctor.shifts.isEmpty ? "" : " · ${doctor.shifts.length} ${s.adminWorkingDays}"}'
                '${doctor.weeklyCapacity == 0 ? "" : " · ${doctor.weeklyCapacity} ${s.adminDoctorsCount}"}',
            leading: const CircleAvatar(
              backgroundColor: AppColors.navyTint,
              child: Icon(Icons.person_outline, color: AppColors.navy),
            ),
            trailing: StatusChip('${s.adminSeniority} ${doctor.seniority}',
                color: AppColors.navy),
            onTap: () => _openForm(context, doctor),
          ),
      ],
    );
  }

  void _openForm(BuildContext context, Doctor? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DoctorForm(existing: existing),
    );
  }
}

class _DoctorForm extends StatefulWidget {
  const _DoctorForm({this.existing});
  final Doctor? existing;

  @override
  State<_DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<_DoctorForm> {
  late final _nameAr =
      TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _nameEn =
      TextEditingController(text: widget.existing?.name.en ?? '');
  late final _titleAr =
      TextEditingController(text: widget.existing?.title.ar ?? 'استشاري');
  late final _titleEn =
      TextEditingController(text: widget.existing?.title.en ?? '');
  late final _specialtyAr =
      TextEditingController(text: widget.existing?.specialty.ar ?? '');
  late final _specialtyEn =
      TextEditingController(text: widget.existing?.specialty.en ?? '');
  late int _seniority = widget.existing?.seniority ?? 3;
  late String? _centreId = widget.existing?.centreId;
  late final List<DoctorShift> _shifts = [...?widget.existing?.shifts];

  @override
  void dispose() {
    for (final c in [
      _nameAr, _nameEn, _titleAr, _titleEn, _specialtyAr, _specialtyEn,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AdminFormSheet(
      title: widget.existing == null ? s.adminNewDoctor : s.adminEditDoctor,
      saveEnabled: _nameAr.text.trim().isNotEmpty,
      onSave: _save,
      children: [
        BilingualFields(
          arController: _nameAr,
          enController: _nameEn,
          label: s.adminName,
          onChanged: (_) => setState(() {}),
        ),
        BilingualFields(
          arController: _titleAr,
          enController: _titleEn,
          label: s.adminDoctorTitle,
        ),
        BilingualFields(
          arController: _specialtyAr,
          enController: _specialtyEn,
          label: s.adminSpecialty,
        ),
        AdminSectionLabel('${s.adminSeniority}: $_seniority'),
        InfoNote(s.adminSeniorityNote, icon: Icons.info_outline),
        const SizedBox(height: Gap.md),
        Slider(
          value: _seniority.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_seniority',
          onChanged: (v) => setState(() => _seniority = v.round()),
        ),
        AdminSectionLabel(s.adminCentre),
        DropdownButtonFormField<String?>(
          initialValue: _centreId,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: null, child: Text(s.adminNoCentre)),
            for (final centre in Seed.centres)
              DropdownMenuItem(
                  value: centre.id, child: Text(centre.name(s.localeName))),
          ],
          onChanged: (id) => setState(() => _centreId = id),
        ),
        const SizedBox(height: Gap.xl),

        // Working hours and capacity: this is what actually generates the
        // slots a patient can book.
        AdminSectionLabel(s.adminShifts),
        InfoNote(s.adminShiftsNote, icon: Icons.schedule_outlined),
        const SizedBox(height: Gap.md),
        ShiftEditor(
          shifts: _shifts,
          onChanged: (updated) => setState(() {
            _shifts
              ..clear()
              ..addAll(updated);
          }),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final existing = widget.existing;

    // Changing a doctor's hours can invalidate bookings already made. Show
    // the cost before saving, never after.
    if (existing != null) {
      final broken = <dynamic>[];
      for (final clinic
          in Seed.clinics.where((c) => c.doctorIds.contains(existing.id))) {
        broken.addAll(state.appointmentsBrokenBy(
          clinicId: clinic.id,
          newWorkingDays: clinic.workingDays,
          doctorId: existing.id,
          newShifts: _shifts,
        ));
      }
      final unique = {for (final a in broken) a.id: a}.values.toList();
      if (unique.isNotEmpty) {
        final proceed = await confirmScheduleImpact(context, unique.length);
        if (proceed != true) return;
        state.cancelBrokenAppointments(unique.cast());
      }
    }

    if (!mounted) return;
    state.upsertDoctor(
      id: existing?.id,
      name: BilingualFields.toLabel(_nameAr, _nameEn),
      title: BilingualFields.toLabel(_titleAr, _titleEn),
      specialty: BilingualFields.toLabel(_specialtyAr, _specialtyEn),
      seniority: _seniority,
      centreId: _centreId,
      shifts: _shifts,
    );
    if (mounted) Navigator.of(context).pop();
  }
}

// --------------------------------------------------------------- theatres

class TheatresAdminScreen extends StatelessWidget {
  const TheatresAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    context.watch<AppState>();

    return AdminListScaffold(
      title: s.adminTheatres,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      children: [
        for (final theatre in Seed.theatres)
          AdminRow(
            title: '${theatre.code} — ${theatre.name(s.localeName)}',
            subtitle: '${theatreTypeLabel(theatre.type, s)} · '
                '${_hhmm(theatre.opensAt)} – ${_hhmm(theatre.closesAt)}',
            dimmed: !theatre.isActive,
            trailing: theatre.isActive
                ? null
                : StatusChip(s.theatreBlocked, color: AppColors.danger),
            onTap: () => _openForm(context, theatre),
          ),
      ],
    );
  }

  static String _hhmm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  void _openForm(BuildContext context, OperatingTheatre? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TheatreForm(existing: existing),
    );
  }
}

class _TheatreForm extends StatefulWidget {
  const _TheatreForm({this.existing});
  final OperatingTheatre? existing;

  @override
  State<_TheatreForm> createState() => _TheatreFormState();
}

class _TheatreFormState extends State<_TheatreForm> {
  late final _code =
      TextEditingController(text: widget.existing?.code ?? 'OR-');
  late final _nameAr =
      TextEditingController(text: widget.existing?.name.ar ?? '');
  late final _nameEn =
      TextEditingController(text: widget.existing?.name.en ?? '');
  late TheatreType _type = widget.existing?.type ?? TheatreType.general;
  late int _opensAt = widget.existing?.opensAt ?? 8 * 60;
  late int _closesAt = widget.existing?.closesAt ?? 20 * 60;
  late bool _isActive = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    for (final c in [_code, _nameAr, _nameEn]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AdminFormSheet(
      title:
          widget.existing == null ? s.adminNewTheatre : s.adminEditTheatre,
      saveEnabled: _nameAr.text.trim().isNotEmpty && _closesAt > _opensAt,
      onSave: _save,
      children: [
        AdminField(
          controller: _code,
          label: s.adminCode,
          textDirection: TextDirection.ltr,
        ),
        BilingualFields(
          arController: _nameAr,
          enController: _nameEn,
          label: s.adminName,
          onChanged: (_) => setState(() {}),
        ),
        AdminSectionLabel(s.adminTheatreType),
        DropdownButtonFormField<TheatreType>(
          initialValue: _type,
          isExpanded: true,
          items: [
            for (final t in TheatreType.values)
              DropdownMenuItem(value: t, child: Text(theatreTypeLabel(t, s))),
          ],
          onChanged: (t) => setState(() => _type = t ?? _type),
        ),
        const SizedBox(height: Gap.lg),
        AdminSectionLabel(s.adminOperatingHours),
        Row(
          children: [
            Expanded(
              child: _HourStepper(
                label: s.commonFrom,
                minutes: _opensAt,
                onChanged: (v) => setState(() => _opensAt = v),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: _HourStepper(
                label: s.commonTo,
                minutes: _closesAt,
                onChanged: (v) => setState(() => _closesAt = v),
              ),
            ),
          ],
        ),
        if (_closesAt <= _opensAt) ...[
          const SizedBox(height: Gap.md),
          InfoNote(s.adminHoursInvalid, color: AppColors.danger),
        ],
        const SizedBox(height: Gap.lg),
        SwitchListTile(
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
          contentPadding: EdgeInsets.zero,
          title: Text(s.adminTheatreActive,
              style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(s.adminTheatreActiveNote,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  void _save() {
    context.read<AppState>().upsertTheatre(
          id: widget.existing?.id,
          code: _code.text.trim(),
          name: BilingualFields.toLabel(_nameAr, _nameEn),
          type: _type,
          opensAt: _opensAt,
          closesAt: _closesAt,
          isActive: _isActive,
        );
    Navigator.of(context).pop();
  }
}

class _HourStepper extends StatelessWidget {
  const _HourStepper({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: Gap.xs),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed:
                  minutes >= 30 ? () => onChanged(minutes - 30) : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
                '${(minutes % 60).toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton.filledTonal(
              onPressed: minutes <= 24 * 60 - 30
                  ? () => onChanged(minutes + 30)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

String theatreTypeLabel(TheatreType type, AppStrings s) =>
    switch ((type, s.localeName)) {
      (TheatreType.general, 'en') => 'General',
      (TheatreType.general, _) => 'عامة',
      (TheatreType.obstetric, 'en') => 'Obstetric',
      (TheatreType.obstetric, _) => 'ولادة',
      (TheatreType.minorProcedures, 'en') => 'Minor procedures',
      (TheatreType.minorProcedures, _) => 'عمليات صغرى',
      (TheatreType.endoscopy, 'en') => 'Endoscopy',
      (TheatreType.endoscopy, _) => 'مناظير',
    };

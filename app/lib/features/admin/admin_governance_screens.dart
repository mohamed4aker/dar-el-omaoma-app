import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/governance.dart';
import 'admin_widgets.dart';

/// Hospital-wide policy (PROMPT.md §14).
///
/// The switches here decide how the hospital runs. The most consequential is
/// the first: whether a surgeon takes a theatre slot themselves or asks the
/// administration for one. Both are legitimate, and it is the hospital's call.
class PolicyAdminScreen extends StatelessWidget {
  const PolicyAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final policy = state.policy;

    return Scaffold(
      appBar: AppBar(title: Text(s.adminPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          AppCard(
            borderColor: AppColors.pink.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: policy.doctorsBookTheatreDirectly,
                  onChanged: (v) => state.updatePolicy(
                      policy.copyWith(doctorsBookTheatreDirectly: v)),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.policyDirectBooking,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                InfoNote(
                  policy.doctorsBookTheatreDirectly
                      ? s.policyDirectBookingOn
                      : s.policyDirectBookingOff,
                  icon: policy.doctorsBookTheatreDirectly
                      ? Icons.bolt_outlined
                      : Icons.schedule_send_outlined,
                  color: policy.doctorsBookTheatreDirectly
                      ? AppColors.success
                      : AppColors.navy,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),

          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: policy.notifyPatientsOnScheduleChange,
                  onChanged: (v) => state.updatePolicy(
                      policy.copyWith(notifyPatientsOnScheduleChange: v)),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.policyNotifyOnChange,
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(s.policyNotifyOnChangeNote,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                if (!policy.notifyPatientsOnScheduleChange)
                  InfoNote(s.policyNotifyOffWarning,
                      icon: Icons.warning_amber_outlined,
                      color: AppColors.danger),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),

          SectionHeader(s.policyApprovalWindow),
          _HoursStepper(
            hours: policy.approvalWindow.inHours,
            min: 1,
            max: 48,
            onChanged: (h) => state.updatePolicy(
                policy.copyWith(approvalWindow: Duration(hours: h))),
          ),
          const SizedBox(height: Gap.sm),
          InfoNote(s.policyApprovalWindowNote, icon: Icons.timer_outlined),
          const SizedBox(height: Gap.lg),

          SectionHeader(s.policyCancellationCutoff),
          _HoursStepper(
            hours: policy.clinicCancellationCutoff.inHours,
            min: 0,
            max: 72,
            onChanged: (h) => state.updatePolicy(policy.copyWith(
                clinicCancellationCutoff: Duration(hours: h))),
          ),
          const SizedBox(height: Gap.sm),
          InfoNote(s.policyCancellationNote, icon: Icons.event_busy_outlined),
          const SizedBox(height: Gap.lg),

          SectionHeader(s.policyDefaultPayment),
          for (final option in PaymentPolicy.values)
            RadioListTile<PaymentPolicy>(
              value: option,
              // ignore: deprecated_member_use
              groupValue: policy.defaultPaymentPolicy,
              // ignore: deprecated_member_use
              onChanged: (v) => v == null
                  ? null
                  : state.updatePolicy(
                      policy.copyWith(defaultPaymentPolicy: v)),
              contentPadding: EdgeInsets.zero,
              title: Text(paymentPolicyLabel(option, s),
                  style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(paymentPolicyNote(option, s),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _HoursStepper extends StatelessWidget {
  const _HoursStepper({
    required this.hours,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int hours;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: hours > min ? () => onChanged(hours - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Expanded(
          child: Text(
            Fmt.duration(Duration(hours: hours), s),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        IconButton.filledTonal(
          onPressed: hours < max ? () => onChanged(hours + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- users

/// Users and roles (PROMPT.md §3.3).
///
/// Roles are containers for permissions, and a person may hold several — a
/// surgeon who also approves requests is one account with two roles, not two
/// accounts.
class UsersAdminScreen extends StatelessWidget {
  const UsersAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();

    return AdminListScaffold(
      title: s.adminUsers,
      addLabel: s.adminAdd,
      onAdd: () => _openForm(context, null),
      note: state.approvalCoverageIsThin
          // Every approval permission needs a second holder, or one person's
          // leave stalls every patient request.
          ? InfoNote(s.adminApprovalCoverageThin,
              icon: Icons.warning_amber_outlined, color: AppColors.danger)
          : InfoNote(s.adminRolesNote, icon: Icons.shield_outlined),
      children: [
        for (final user in state.staff)
          AdminRow(
            title: user.name,
            subtitle: user.roles.map((r) => roleLabel(r, s)).join(' · '),
            dimmed: !user.isActive,
            leading: CircleAvatar(
              backgroundColor: AppColors.navyTint,
              child: Text(
                user.name.characters.first,
                style: const TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.w700),
              ),
            ),
            trailing: Switch(
              value: user.isActive,
              onChanged: (v) => state.setStaffActive(user.id, v),
            ),
            onTap: () => _openForm(context, user),
          ),
      ],
    );
  }

  void _openForm(BuildContext context, StaffUser? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UserForm(existing: existing),
    );
  }
}

class _UserForm extends StatefulWidget {
  const _UserForm({this.existing});
  final StaffUser? existing;

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final Set<UserRole> _roles = {...?widget.existing?.roles};
  late String? _doctorId = widget.existing?.doctorId;

  static const _assignable = [
    UserRole.admin,
    UserRole.surgeryApprover,
    UserRole.orScheduler,
    UserRole.doctor,
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AdminFormSheet(
      title: widget.existing == null ? s.adminNewUser : s.adminEditUser,
      saveEnabled: _name.text.trim().isNotEmpty && _roles.isNotEmpty,
      onSave: _save,
      children: [
        AdminField(
          controller: _name,
          label: s.adminName,
          onChanged: (_) => setState(() {}),
        ),
        AdminField(
          controller: _phone,
          label: s.registerPhone,
          textDirection: TextDirection.ltr,
        ),
        AdminSectionLabel(s.adminRoles),
        for (final role in _assignable)
          CheckboxListTile(
            value: _roles.contains(role),
            onChanged: (v) => setState(() {
              (v ?? false) ? _roles.add(role) : _roles.remove(role);
              if (role == UserRole.doctor && !_roles.contains(role)) {
                _doctorId = null;
              }
            }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(roleLabel(role, s),
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(rolePermissions(role, s),
                style: Theme.of(context).textTheme.bodySmall),
          ),
        if (_roles.contains(UserRole.doctor)) ...[
          const SizedBox(height: Gap.lg),
          AdminSectionLabel(s.adminLinkedDoctor),
          InfoNote(s.adminLinkedDoctorNote, icon: Icons.link),
          const SizedBox(height: Gap.md),
          DropdownButtonFormField<String?>(
            initialValue: _doctorId,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: null, child: Text(s.commonNoResults)),
              for (final doctor in Seed.doctors)
                DropdownMenuItem(
                    value: doctor.id, child: Text(doctor.name(s.localeName))),
            ],
            onChanged: (id) => setState(() => _doctorId = id),
          ),
        ],
      ],
    );
  }

  void _save() {
    context.read<AppState>().upsertStaff(
          id: widget.existing?.id,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          roles: _roles,
          doctorId: _doctorId,
          isActive: widget.existing?.isActive ?? true,
        );
    Navigator.of(context).pop();
  }
}

// --------------------------------------------------------------- audit log

/// The audit log (PROMPT.md §11.1, control 6).
///
/// Append-only, and shown newest first. This is what makes "who changed that
/// price?" an answerable question rather than an argument.
class AuditAdminScreen extends StatelessWidget {
  const AuditAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final entries = context.watch<AppState>().auditLog;

    return Scaffold(
      appBar: AppBar(title: Text(s.adminAudit)),
      body: entries.isEmpty
          ? EmptyState(message: s.adminAuditEmpty, icon: Icons.history)
          : ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                InfoNote(s.adminAuditNote, icon: Icons.lock_outline),
                const SizedBox(height: Gap.lg),
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: AppCard(
                      padding: const EdgeInsets.all(Gap.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_iconFor(entry.action),
                              size: 18, color: _colourFor(entry.action)),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.actor} · '
                                  '${auditAction(entry.action, s)} '
                                  '${auditEntity(entry.entity, s)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                if (entry.detail != null)
                                  Text(entry.detail!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                Text(
                                  '${Fmt.date(entry.at, s)} · '
                                  '${Fmt.time(entry.at)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  static IconData _iconFor(String action) => switch (action) {
        'created' => Icons.add_circle_outline,
        'updated' => Icons.edit_outlined,
        'deactivated' || 'disabled' => Icons.block,
        'enabled' => Icons.check_circle_outline,
        'cancelled' => Icons.event_busy_outlined,
        'scheduled' => Icons.event_available_outlined,
        _ => Icons.circle_outlined,
      };

  static Color _colourFor(String action) => switch (action) {
        'created' || 'enabled' || 'scheduled' => AppColors.success,
        'cancelled' || 'deactivated' || 'disabled' => AppColors.danger,
        'updated' => AppColors.warning,
        _ => AppColors.muted,
      };
}

// --------------------------------------------------------------- labels

String roleLabel(UserRole role, AppStrings s) =>
    switch ((role, s.localeName)) {
      (UserRole.admin, 'en') => 'Administrator',
      (UserRole.admin, _) => 'أدمن',
      (UserRole.surgeryApprover, 'en') => 'Surgery approver',
      (UserRole.surgeryApprover, _) => 'موافق العمليات',
      (UserRole.orScheduler, 'en') => 'Theatre scheduler',
      (UserRole.orScheduler, _) => 'منسق غرف العمليات',
      (UserRole.doctor, 'en') => 'Doctor',
      (UserRole.doctor, _) => 'طبيب',
      (UserRole.patient, 'en') => 'Patient',
      (UserRole.patient, _) => 'مريض',
      (UserRole.guest, 'en') => 'Guest',
      (UserRole.guest, _) => 'زائر',
    };

String rolePermissions(UserRole role, AppStrings s) {
  final permissions = <String>[
    if (role.canManageCatalogue) s.permManageCatalogue,
    if (role.canManageUsers) s.permManageUsers,
    if (role.canApproveSurgery) s.permApprove,
    if (role.canScheduleSurgery) s.permSchedule,
    if (role.canBookTheatreDirectly) s.permBookDirect,
    if (role.canOverrideConflict) s.permOverride,
    if (role.canViewAuditLog) s.permAudit,
  ];
  return permissions.isEmpty ? '—' : permissions.join(' · ');
}

String paymentPolicyLabel(PaymentPolicy p, AppStrings s) =>
    switch ((p, s.localeName)) {
      (PaymentPolicy.payAtReception, 'en') => 'Pay at reception',
      (PaymentPolicy.payAtReception, _) => 'الدفع في الاستقبال',
      (PaymentPolicy.optionalOnline, 'en') => 'Optional online payment',
      (PaymentPolicy.optionalOnline, _) => 'الدفع أونلاين اختياري',
      (PaymentPolicy.depositRequired, 'en') => 'Deposit required',
      (PaymentPolicy.depositRequired, _) => 'عربون مطلوب',
    };

String paymentPolicyNote(PaymentPolicy p, AppStrings s) =>
    switch ((p, s.localeName)) {
      (PaymentPolicy.payAtReception, 'en') =>
        'Booking is free. No money is taken in the app.',
      (PaymentPolicy.payAtReception, _) =>
        'الحجز مجاني ومفيش أي دفع في التطبيق.',
      (PaymentPolicy.optionalOnline, 'en') =>
        'Booking stays free; the patient may pay early to save time.',
      (PaymentPolicy.optionalOnline, _) =>
        'الحجز يفضل مجاني، والمريض يقدر يدفع بدري لو حب.',
      (PaymentPolicy.depositRequired, 'en') =>
        'A deposit holds the slot. Use where a doctor has few places.',
      (PaymentPolicy.depositRequired, _) =>
        'عربون بيحجز المكان. استخدمها لما يكون عدد حالات الطبيب محدود.',
    };

String auditAction(String action, AppStrings s) {
  if (s.localeName == 'en') return action;
  return switch (action) {
    'created' => 'أضاف',
    'updated' => 'عدّل',
    'deactivated' => 'أوقف',
    'enabled' => 'فعّل',
    'disabled' => 'أوقف',
    'cancelled' => 'ألغى',
    'scheduled' => 'حدّد موعد',
    _ => action,
  };
}

String auditEntity(String entity, AppStrings s) {
  if (s.localeName == 'en') return entity.replaceAll('_', ' ');
  return switch (entity) {
    'classification' => 'تصنيف',
    'procedure' => 'عملية',
    'clinic' => 'عيادة',
    'doctor' => 'طبيب',
    'theatre' => 'غرفة عمليات',
    'appointment' => 'موعد',
    'surgery_request' => 'طلب عملية',
    'policy' => 'سياسة',
    'user' => 'مستخدم',
    'offer' => 'عرض',
    'tip' => 'نصيحة',
    _ => entity,
  };
}

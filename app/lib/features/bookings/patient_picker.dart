import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/validation/national_id.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../domain/models/patient.dart';

/// Who a booking is for.
///
/// A signed-in patient books for themselves. A guest is sent to sign in.
/// Reception, signed in as staff, picks the caller from the registered
/// patients or registers them on the spot — the phone-booking workflow.
Future<Patient?> resolveBookingPatient(BuildContext context) async {
  final state = context.read<AppState>();
  final session = state.session;
  if (session.isStaff) {
    return showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PatientPickerSheet(),
    );
  }
  final patient = session.patient;
  if (patient != null) return patient;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 36),
      title: Text(context.tr('سجّل الأول عشان تحجز', 'Sign in to book')),
      content: Text(context.tr(
          'الحجز محتاج حساب بالرقم القومي، عشان المستشفى تعرف الحجز ده لمين.',
          'Booking needs an account with your National ID, so the hospital knows who it is for.')),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.push('/login');
          },
          child: Text(context.s.loginTitle),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.push('/register');
          },
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(context.s.welcomeRegister),
        ),
      ],
    ),
  );
  return null;
}

class _PatientPickerSheet extends StatefulWidget {
  const _PatientPickerSheet();

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  final _query = TextEditingController();
  bool _creating = false;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    _name.dispose();
    _nationalId.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _create() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = context.read<AppState>();
    final result = state.registerPatient(
      fullName: _name.text,
      nationalId: _nationalId.text,
      phone: _phone.text,
      signIn: false,
    );
    switch (result) {
      case RegistrationResult.created:
        Navigator.of(context).pop(state.lastRegistered);
      case RegistrationResult.alreadyRegistered:
        final existing = state.patientByNationalId(_nationalId.text);
        Navigator.of(context).pop(existing);
      case RegistrationResult.nationalIdInvalid:
        setState(() => _error = context.s.errorNationalIdInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = context.watch<AppState>();
    final results = state.searchPatients(_query.text).take(50).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: Gap.lg,
        right: Gap.lg,
        top: Gap.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Gap.lg,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: _creating ? _form(s) : _list(s, results),
      ),
    );
  }

  Widget _list(AppStrings s, List<Patient> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('الحجز لمين؟', 'Who is this booking for?'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Gap.md),
        TextField(
          controller: _query,
          autofocus: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: context.tr('اسم، رقم قومي، موبايل أو رقم ملف',
                'Name, National ID, mobile or file number'),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Gap.md),
        OutlinedButton.icon(
          onPressed: () => setState(() => _creating = true),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(context.tr('مريض جديد', 'New patient')),
        ),
        const SizedBox(height: Gap.md),
        Expanded(
          child: results.isEmpty
              ? EmptyState(
                  message: context.tr('مفيش مرضى مطابقين', 'No matching patients'),
                  icon: Icons.person_search_outlined,
                )
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = results[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryTint,
                        child: Text(p.firstName.characters.first,
                            style: const TextStyle(color: AppColors.primary)),
                      ),
                      title: Text(p.fullName),
                      subtitle: Text(
                        '${p.nationalId ?? ''} · ${p.phoneLocal}',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.end,
                      ),
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _form(AppStrings s) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _creating = false),
                icon: const BackButtonIcon(),
              ),
              Text(context.tr('مريض جديد', 'New patient'),
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: Gap.md),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: s.registerFullName),
            validator: (v) =>
                NameValidator.hasFourParts(v ?? '') ? null : s.errorNameFourParts,
          ),
          const SizedBox(height: Gap.md),
          TextFormField(
            controller: _nationalId,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [LengthLimitingTextInputFormatter(14)],
            decoration: InputDecoration(labelText: s.registerNationalId, counterText: ''),
            validator: (v) =>
                NationalId.parse(v ?? '').isValid ? null : s.errorNationalIdInvalid,
          ),
          const SizedBox(height: Gap.md),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: InputDecoration(labelText: s.registerPhone, counterText: ''),
            validator: (v) => PhoneNumber.isValid(v ?? '') ? null : s.errorPhoneInvalid,
          ),
          if (_error != null) ...[
            const SizedBox(height: Gap.md),
            InfoNote(_error!, color: AppColors.danger, icon: Icons.error_outline),
          ],
          const SizedBox(height: Gap.xl),
          FilledButton(
            onPressed: _create,
            child: Text(context.tr('حفظ ومتابعة الحجز', 'Save and continue')),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../core/validation/national_id.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';

/// Deck slide 2. Every field the client specified, plus the validation and
/// consent requirements from PROMPT.md section 6.2.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();

  NationalIdInfo? _derived;
  bool _acceptedTerms = false;
  bool _acceptedMarketing = false;
  bool _termsError = false;

  @override
  void initState() {
    super.initState();
    _nationalId.addListener(_onNationalIdChanged);
  }

  @override
  void dispose() {
    _nationalId.removeListener(_onNationalIdChanged);
    _name.dispose();
    _nationalId.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    super.dispose();
  }

  /// Date of birth, gender and governorate are derived from the National ID
  /// and shown back for confirmation rather than asked for again.
  void _onNationalIdChanged() {
    final result = NationalId.parse(_nationalId.text);
    final info = result.isValid ? result.info : null;
    if (info != _derived) setState(() => _derived = info);
  }

  void _submit() {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _termsError = !_acceptedTerms);
    if (!formValid || !_acceptedTerms) return;

    context.read<AppState>().signInAsPatient();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.registerTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(Gap.xl),
            children: [
              Text(s.registerSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: Gap.xl),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.registerFullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => NameValidator.hasFourParts(value ?? '')
                    ? null
                    : s.errorNameFourParts,
              ),
              const SizedBox(height: Gap.lg),
              TextFormField(
                controller: _nationalId,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                inputFormatters: [LengthLimitingTextInputFormatter(14)],
                decoration: InputDecoration(
                  labelText: s.registerNationalId,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  counterText: '',
                ),
                validator: (value) {
                  final result = NationalId.parse(value ?? '');
                  if (result.isValid) return null;
                  return switch (result.error) {
                    NationalIdError.notFourteenDigits ||
                    NationalIdError.empty =>
                      s.errorNationalIdLength,
                    _ => s.errorNationalIdInvalid,
                  };
                },
              ),
              if (_derived != null) ...[
                const SizedBox(height: Gap.md),
                _DerivedCard(info: _derived!),
              ],
              const SizedBox(height: Gap.lg),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: s.registerPhone,
                  hintText: s.loginPhoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  counterText: '',
                ),
                validator: (value) => PhoneNumber.isValid(value ?? '')
                    ? null
                    : s.errorPhoneInvalid,
              ),
              const SizedBox(height: Gap.lg),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: '${s.registerEmail} — ${s.commonOptional}',
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return EmailValidator.isValid(value)
                      ? null
                      : s.errorEmailInvalid;
                },
              ),
              const SizedBox(height: Gap.lg),
              TextFormField(
                controller: _company,
                decoration: InputDecoration(
                  labelText: s.registerCompany,
                  helperText: s.registerCompanyHelper,
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: Gap.xl),
              // Consent is collected on unticked checkboxes, and marketing is
              // a separate, independently revocable opt-in (PROMPT.md 6.2).
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (v) => setState(() {
                  _acceptedTerms = v ?? false;
                  if (_acceptedTerms) _termsError = false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(s.registerAcceptTerms,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              if (_termsError)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: Text(
                    s.errorMustAcceptTerms,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13),
                  ),
                ),
              CheckboxListTile(
                value: _acceptedMarketing,
                onChanged: (v) =>
                    setState(() => _acceptedMarketing = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(s.registerAcceptMarketing,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: Gap.xl),
              FilledButton(
                onPressed: _submit,
                child: Text(s.registerSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DerivedCard extends StatelessWidget {
  const _DerivedCard({required this.info});

  final NationalIdInfo info;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AppCard(
      borderColor: AppColors.success.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                  size: 18, color: AppColors.success),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  s.registerDerivedTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          _Row(label: s.registerDob, value: Fmt.date(info.dateOfBirth, s)),
          _Row(
            label: s.registerGender,
            value: info.isMale ? s.genderMale : s.genderFemale,
          ),
          _Row(
            label: s.registerGovernorate,
            value: s.localeName == 'en' ? info.governorateEn : info.governorateAr,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

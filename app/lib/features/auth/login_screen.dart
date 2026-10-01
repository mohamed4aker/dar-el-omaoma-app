import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/validation/national_id.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';

/// A returning patient signs in with their National ID and the mobile number
/// they registered with. No SMS code: the hospital has no SMS gateway, and a
/// code that never arrives is worse than no code.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  bool _failed = false;

  @override
  void dispose() {
    _nationalId.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = context.read<AppState>().signInPatient(
          nationalId: _nationalId.text,
          phone: _phone.text,
        );
    if (!ok) {
      setState(() => _failed = true);
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.loginTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Gap.xl),
            children: [
              const Center(child: BrandMark(size: 80)),
              const SizedBox(height: Gap.xl),
              Text(
                context.tr('ادخل رقمك القومي ورقم الموبايل اللي سجلت بيه.',
                    'Enter your National ID and the mobile number you registered with.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Gap.xl),
              TextFormField(
                controller: _nationalId,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(14)],
                decoration: InputDecoration(
                  labelText: s.registerNationalId,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  counterText: '',
                ),
                validator: (v) => NationalId.parse(v ?? '').isValid
                    ? null
                    : s.errorNationalIdLength,
                onChanged: (_) {
                  if (_failed) setState(() => _failed = false);
                },
              ),
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
                validator: (v) =>
                    PhoneNumber.isValid(v ?? '') ? null : s.errorPhoneInvalid,
                onChanged: (_) {
                  if (_failed) setState(() => _failed = false);
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_failed) ...[
                const SizedBox(height: Gap.lg),
                InfoNote(
                  context.tr(
                      'البيانات دي مش مطابقة لحساب على الجهاز ده. اتأكد من الرقم القومي ورقم الموبايل، أو أنشئ حساب جديد.',
                      'These details do not match an account on this device. Check your National ID and mobile number, or create an account.'),
                  icon: Icons.error_outline,
                  color: AppColors.danger,
                ),
              ],
              const SizedBox(height: Gap.xl),
              FilledButton(onPressed: _submit, child: Text(s.loginTitle)),
              const SizedBox(height: Gap.md),
              TextButton(
                onPressed: () => context.pushReplacement('/register'),
                child: Text(context.tr('أول مرة؟ أنشئ حساب', 'First time? Create an account')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

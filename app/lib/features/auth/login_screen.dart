import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/validation/national_id.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/seed_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!PhoneNumber.isValid(_phone.text)) {
      setState(() => _error = context.s.errorPhoneInvalid);
      return;
    }
    setState(() {
      _error = null;
      _otpSent = true;
    });
  }

  void _verify() {
    // Demo build. In production the code is verified server-side, rate limited
    // to three sends per hour and five attempts (PROMPT.md section 6.2).
    if (_otp.text.trim() != '123456') {
      setState(() => _error = context.s.otpInvalid);
      return;
    }
    context.read<AppState>().signInAsPatient();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.loginTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _otpSent ? '${s.otpSubtitle} ${_phone.text}' : s.loginSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Gap.xl),
              if (!_otpSent) ...[
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    labelText: s.loginPhoneLabel,
                    hintText: s.loginPhoneHint,
                    errorText: _error,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: Gap.xl),
                FilledButton(onPressed: _sendOtp, child: Text(s.loginSendOtp)),
              ] else ...[
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: s.otpTitle,
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: Gap.lg),
                InfoNote(s.loginDemoHint),
                const SizedBox(height: Gap.xl),
                FilledButton(onPressed: _verify, child: Text(s.otpVerify)),
                const SizedBox(height: Gap.sm),
                TextButton(
                  onPressed: () => setState(() {
                    _otpSent = false;
                    _otp.clear();
                    _error = null;
                  }),
                  child: Text(s.otpResend),
                ),
              ],
              const SizedBox(height: Gap.xxl),
              const Divider(),
              const SizedBox(height: Gap.lg),
              // Demo-only role switch. In production the role is carried by the
              // server-issued session token and is never selectable in the
              // client (PROMPT.md section 5).
              Text(
                context.s.localeName == 'en'
                    ? 'Demo: enter as a doctor to open the theatre module'
                    : 'تجريبي: ادخل كطبيب لتجربة وحدة غرف العمليات',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: Gap.md),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final doctor in Seed.doctors.take(3))
                    OutlinedButton(
                      onPressed: () {
                        context.read<AppState>().signInAsDoctor(doctor.id);
                        context.go('/home');
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, kMinTouchTarget),
                        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                      ),
                      child: Text(doctor.name(s.localeName)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

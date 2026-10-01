import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';

/// Reception, doctors and administrators sign in here with the username and
/// password the administrator gave them. The role comes from the account.
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _failed = false;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = context.read<AppState>().signInStaff(
          username: _username.text,
          password: _password.text,
        );
    if (!ok) {
      setState(() => _failed = true);
      return;
    }
    context.go('/file');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('دخول الموظفين', 'Staff sign-in'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.xl),
          children: [
            const Center(child: BrandMark(size: 72)),
            const SizedBox(height: Gap.xl),
            TextField(
              controller: _username,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.tr('اسم المستخدم', 'Username'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onChanged: (_) => setState(() => _failed = false),
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _password,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: context.tr('كلمة المرور', 'Password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: context.tr('إظهار', 'Show'),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              onChanged: (_) => setState(() => _failed = false),
              onSubmitted: (_) => _submit(),
            ),
            if (_failed) ...[
              const SizedBox(height: Gap.lg),
              InfoNote(
                context.tr('اسم المستخدم أو كلمة المرور غير صحيحة، أو الحساب موقوف.',
                    'Wrong username or password, or the account is disabled.'),
                icon: Icons.error_outline,
                color: AppColors.danger,
              ),
            ],
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _submit,
              child: Text(context.tr('دخول', 'Sign in')),
            ),
            const SizedBox(height: Gap.lg),
            Text(
              context.tr('الحسابات بيعملها مدير النظام من لوحة التحكم ← المستخدمون والصلاحيات.',
                  'Accounts are created by the administrator under Admin → Users & roles.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../../state/site_content_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context
        .read<AuthController>()
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    // On success the router redirect sends the user to their area.
  }

  void _fill(String email, String password) {
    _email.text = email;
    _password.text = password;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.screenWidth >= 900;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Row(
        children: [
          if (wide) const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _form(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back, size: 18),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            label: const Text('Back to site'),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to your staff workspace or member portal.',
            style: TextStyle(fontSize: 16, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 28),
          const FieldLabel('Email'),
          AdminField(
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
          ),
          const SizedBox(height: 16),
          const FieldLabel('Password'),
          AdminField(
            controller: _password,
            hint: '••••••••',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your password' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB3261E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFB3261E), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _busy ? 'Signing in…' : 'Sign in',
              icon: Icons.login,
              onPressed: _busy ? () {} : _submit,
            ),
          ),
          const SizedBox(height: 28),
          const _DemoAccounts(),
        ],
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginPageState>()!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined,
                  size: 16, color: AppColors.inkSoft),
              const SizedBox(width: 8),
              Text('DEMO ACCOUNTS',
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          _DemoRow(
            role: 'Staff',
            email: 'staff@church.app',
            password: 'church123',
            onTap: () => state._fill('staff@church.app', 'church123'),
          ),
          const SizedBox(height: 8),
          _DemoRow(
            role: 'Member',
            email: 'member@church.app',
            password: 'welcome123',
            onTap: () => state._fill('member@church.app', 'welcome123'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap an account to fill the form. This demo stores data in your '
            'browser; connect a backend for production.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  final String role;
  final String email;
  final String password;
  final VoidCallback onTap;
  const _DemoRow({
    required this.role,
    required this.email,
    required this.password,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            StatusPill(label: role, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$email  ·  $password',
                style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
              ),
            ),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navy],
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: content.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              content.shortName.isNotEmpty
                  ? content.shortName.substring(0, 1)
                  : 'C',
              style: const TextStyle(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            content.churchName,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: AppColors.onDark,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'One place to manage your website, your people, attendance, and '
              'serving teams — all in one beautiful platform.',
              style: TextStyle(
                fontSize: 18,
                height: 1.6,
                color: AppColors.onDark.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const _FeatureLine(
              icon: Icons.edit_note_outlined, text: 'Edit your site in minutes'),
          const _FeatureLine(
              icon: Icons.people_alt_outlined, text: 'Track members & attendance'),
          const _FeatureLine(
              icon: Icons.volunteer_activism_outlined,
              text: 'Organize serving teams'),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldSoft, size: 22),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.onDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

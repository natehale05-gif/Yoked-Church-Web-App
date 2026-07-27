import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_providers.dart';
import 'auth_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text.trim());
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;

    return AuthLayout(
      title: 'Reset your password',
      subtitle: "We'll email you a link to reset it",
      child: _sent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Check your inbox for a password reset link.'),
                const SizedBox(height: 20),
                OutlinedButton(onPressed: () => context.go('/sign-in'), child: const Text('Back to sign in')),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthErrorBanner(),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: busy ? null : _submit,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Send Reset Link'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Back to sign in'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

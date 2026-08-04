import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/config/tenant.dart';
import '../application/signup_controller.dart';
import '../domain/church_slug.dart';

/// The two minutes that decide whether this is a product or a template.
///
/// Everything a church needs to exist: its name, and someone to run it.
/// No plan to choose, no card, no wizard - the rest is editable in the
/// app afterwards, and asking for it here would only be a reason to
/// close the tab.
class CreateChurchScreen extends ConsumerStatefulWidget {
  const CreateChurchScreen({super.key});

  @override
  ConsumerState<CreateChurchScreen> createState() => _CreateChurchScreenState();
}

class _CreateChurchScreenState extends ConsumerState<CreateChurchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _churchName = TextEditingController();
  final _yourName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Derived from the name as it is typed, and shown, because it is the
  /// address the church will print on things. Seeing it now is the only
  /// chance they get: it never changes afterwards.
  String get _slug => slugify(_churchName.text);

  @override
  void initState() {
    super.initState();
    _churchName.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _churchName.dispose();
    _yourName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final id = await ref.read(signupControllerProvider.notifier).createChurch(
          churchName: _churchName.text.trim(),
          yourName: _yourName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          desiredSlug: _slug,
        );

    // Straight into their own dashboard, which is empty and says so.
    if (id != null && mounted) context.go(churchPath(id, '/admin'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupControllerProvider);
    final busy = state.isLoading;
    final isMobile = Breakpoints.isMobile(context);
    final problem = _slug.isEmpty ? null : slugProblem(_slug);

    return Scaffold(
      backgroundColor: const Color(0xFF14202B),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 28 : 56),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                          label: const Text('Back', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set up your church',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 30 : 38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A minute now, and you have a site, a member app and a '
                        'dashboard. Everything else you can change later.',
                        style: TextStyle(color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.hasError) _Problem(message: '${state.error}'),
                              TextFormField(
                                controller: _churchName,
                                autofocus: !isMobile,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Church name',
                                  hintText: 'Grace Chapel',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? "What is your church called?"
                                    : slugProblem(slugify(v)),
                              ),
                              const SizedBox(height: 6),
                              _Address(slug: _slug, problem: problem),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'And you, so there is someone who can run it.',
                                style: TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _yourName,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(labelText: 'Your name'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(labelText: 'Email'),
                                validator: (v) => (v == null || !v.contains('@'))
                                    ? 'Enter the email you want to sign in with'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                autofillHints: const [AutofillHints.newPassword],
                                decoration: const InputDecoration(labelText: 'Password'),
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) => (v == null || v.length < 6)
                                    ? 'At least 6 characters'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: busy ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Create my church'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/choose-church'),
                          child: const Text(
                            'My church is already here',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The address the church is about to own, shown as they type it.
///
/// Not decoration: it is permanent, and a church that would rather be
/// `gracechapelriverside` than `grace-chapel` needs to find that out
/// before they commit, not after they have printed it on a banner.
class _Address extends ConsumerWidget {
  final String slug;
  final String? problem;

  const _Address({required this.slug, required this.problem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slug.isEmpty) {
      return const Text(
        'Your web address appears here as you type.',
        style: TextStyle(color: Colors.black45, fontSize: 12.5),
      );
    }

    if (problem != null) {
      return Text(problem!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12.5));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.link, size: 14, color: Colors.black45),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your address: ${churchPath(slug)}',
            style: const TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  final String message;

  const _Problem({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

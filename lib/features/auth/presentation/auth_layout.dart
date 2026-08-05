import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/settings_providers.dart';
import '../application/auth_providers.dart';
import '../domain/app_user.dart';

/// Shared centered-card chrome for sign-in / sign-up / reset, deliberately
/// lighter than the full site shell so the flow stays focused.
class AuthLayout extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthLayout({super.key, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: settings.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: InkWell(
                        onTap: () => context.go('/'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.church, color: settings.colors.primary, size: 28),
                            const SizedBox(width: 10),
                            // Flexible because church names are long.
                            // "First Presbyterian Church of Riverside"
                            // overflowed this row on a phone, and a
                            // church cannot shorten its own name to fit
                            // somebody's sign-in page.
                            Flexible(
                              child: Text(
                                settings.churchName,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: settings.colors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(subtitle, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    // Above the form, not below it. With no backend
                    // connected these buttons are the only way in - the
                    // form accepts anything and saves nothing - and on a
                    // 390x844 phone they landed below the fold, so the
                    // app looked like it had no way in at all. Renders
                    // nothing for a church with a real backend, so the
                    // order costs them nothing.
                    const DemoModeCard(),
                    Card(child: Padding(padding: const EdgeInsets.all(24), child: child)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown only when running without a backend: lets someone evaluating the
/// template jump straight into any role, and is explicit that nothing is
/// being saved.
class DemoModeCard extends ConsumerWidget {
  const DemoModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authRepositoryProvider).isDemo) return const SizedBox.shrink();
    final controller = ref.read(authControllerProvider.notifier);
    final busy = ref.watch(authControllerProvider).isLoading;

    return Card(
      color: Colors.amber.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Preview mode', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'No backend is connected, so accounts are not real and nothing '
              'you enter is saved. Jump in as any role to look around.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // No navigation here: the route guard sends a signed-in
                // person off the auth pages, and to the right one for
                // their role. Doing it from both places is what broke
                // this - see the redirect in lib/app/router.dart.
                for (final role in UserRole.values)
                  OutlinedButton(
                    onPressed: busy ? null : () => controller.signInAsDemo(role),
                    child: Text('As ${role.name}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Continue with Google/Apple", hidden entirely when the active auth
/// backend can't do social sign-in.
class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(authRepositoryProvider).supportsSocialSignIn) return const SizedBox.shrink();

    final controller = ref.read(authControllerProvider.notifier);
    final busy = ref.watch(authControllerProvider).isLoading;

    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Colors.black.withValues(alpha: 0.5))),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: busy ? null : controller.signInWithGoogle,
          icon: const Icon(Icons.g_mobiledata, size: 28),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : controller.signInWithApple,
          icon: const Icon(Icons.apple),
          label: const Text('Continue with Apple'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }
}

/// Surfaces an [AuthController] failure inline above the form actions.
class AuthErrorBanner extends ConsumerWidget {
  const AuthErrorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    if (!state.hasError) return const SizedBox.shrink();

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
                '${state.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

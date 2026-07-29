import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/section_container.dart';
import '../application/form_providers.dart';
import '../domain/church_form.dart';

/// The index of forms a church is currently running. Most people arrive
/// at a form by its direct link, but a church needs one page it can point
/// at from the pulpit.
class FormsScreen extends ConsumerWidget {
  const FormsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forms = ref.watch(visibleFormsProvider);
    final open = forms.where((f) => !f.hasClosed).toList();
    final closed = forms.where((f) => f.hasClosed).toList();

    return PageBody(
      children: [
        const PageBanner(
          eyebrow: 'Forms',
          title: 'Sign-ups & Registrations',
          subtitle: 'Everything currently open, in one place.',
        ),
        SectionContainer(
          maxWidth: 820,
          child: forms.isEmpty
              ? const EmptyState(
                  message: 'Nothing is open for sign-up right now.',
                  icon: Icons.assignment_outlined,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final form in open) _FormCard(form: form),
                    if (closed.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Closed', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      // Kept visible rather than hidden: someone who
                      // missed the deadline needs to see that they did,
                      // not a page that behaves as if the form never
                      // existed.
                      for (final form in closed) _FormCard(form: form),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FormCard extends ConsumerWidget {
  final FormDefinition form;

  const _FormCard({required this.form});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(settingsProvider).colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go('/forms/${form.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(form.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    if (form.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(form.description),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (form.membersOnly)
                          const Text('Members only',
                              style: TextStyle(color: Colors.black54, fontSize: 12)),
                        if (form.closesAt != null)
                          Text(
                            form.hasClosed
                                ? 'Closed ${DateFormat.yMMMd().format(form.closesAt!)}'
                                : 'Closes ${DateFormat.yMMMd().format(form.closesAt!)}',
                            style: TextStyle(
                              color: form.hasClosed
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chevron_right, color: brand.primary),
            ],
          ),
        ),
      ),
    );
  }
}

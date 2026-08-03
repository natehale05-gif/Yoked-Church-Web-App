import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../application/connect_providers.dart';
import '../domain/connect_submission.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  ConnectType _type = ConnectType.connectCard;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(connectFormControllerProvider.notifier).submit(
          ConnectSubmission(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            message: _message.text.trim(),
            type: _type,
            submittedAt: DateTime.now(),
          ),
        );
  }

  void _reset() {
    _formKey.currentState?.reset();
    _name.clear();
    _email.clear();
    _phone.clear();
    _message.clear();
    ref.read(connectFormControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectFormControllerProvider);
    final submitted = state.valueOrNull == true;
    final busy = state.isLoading;

    ref.listen(connectFormControllerProvider, (_, next) {
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send that: ${next.error}')),
        );
      }
    });

    return PageBody(
      children: [
        const PageBanner(
          title: 'Connect',
          subtitle: 'Let us know you were here, or share a prayer request - '
              'our team would love to hear from you.',
        ),
        SectionContainer(
          maxWidth: 640,
          child: submitted ? _SuccessMessage(onReset: _reset) : _buildForm(busy),
        ),
      ],
    );
  }

  Widget _buildForm(bool busy) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ConnectType>(
            segments: const [
              ButtonSegment(
                value: ConnectType.connectCard,
                label: Text('Connect Card'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: ConnectType.prayerRequest,
                label: Text('Prayer Request'),
                icon: Icon(Icons.favorite_outline),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (selection) => setState(() => _type = selection.first),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _message,
            decoration: InputDecoration(
              labelText: _type == ConnectType.prayerRequest ? 'How can we pray for you?' : 'Message (optional)',
            ),
            maxLines: 5,
            validator: (v) {
              if (_type == ConnectType.prayerRequest && (v == null || v.trim().isEmpty)) {
                return 'Please share your prayer request';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _SuccessMessage extends ConsumerWidget {
  final VoidCallback onReset;

  const _SuccessMessage({required this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: settings.colors.accent, size: 48),
        const SizedBox(height: 16),
        Text('Thank you!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'We received your submission and our team will follow up soon.',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: onReset, child: const Text('Submit Another')),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../config/church_config.dart';
import '../models/connect_submission.dart';
import '../services/connect_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_container.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final ConnectService _service = const ConnectService();

  ConnectType _type = ConnectType.connectCard;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _service.submit(
        ConnectSubmission(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          message: _messageController.text.trim(),
          type: _type,
          submittedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: ChurchConfig.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 48 : 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Let us know you were here, or share a prayer request - our team would love to hear from you.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
        SectionContainer(
          maxWidth: 640,
          child: _submitted ? _SuccessMessage(onReset: () => setState(() => _submitted = false)) : _buildForm(),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<ConnectType>(
            segments: const [
              ButtonSegment(value: ConnectType.connectCard, label: Text('Connect Card'), icon: Icon(Icons.person_outline)),
              ButtonSegment(value: ConnectType.prayerRequest, label: Text('Prayer Request'), icon: Icon(Icons.favorite_outline)),
            ],
            selected: {_type},
            onSelectionChanged: (selection) => setState(() => _type = selection.first),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your email';
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: _type == ConnectType.prayerRequest ? 'How can we pray for you?' : 'Message (optional)',
              border: const OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) {
              if (_type == ConnectType.prayerRequest && (value == null || value.trim().isEmpty)) {
                return 'Please share your prayer request';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
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

class _SuccessMessage extends StatelessWidget {
  final VoidCallback onReset;

  const _SuccessMessage({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: ChurchConfig.accentColor, size: 48),
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

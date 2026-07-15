import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/site_content_controller.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';
import '../utils/launch.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/content_width.dart';
import '../widgets/page_hero.dart';
import '../widgets/section_header.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Opens the visitor's email client pre-filled. Swap for a backend
      // endpoint when one is available.
      final subject = Uri.encodeComponent('Website enquiry from ${_name.text}');
      final body = Uri.encodeComponent(
        '${_message.text}\n\nFrom: ${_name.text} (${_email.text})',
      );
      final email = context.read<SiteContentController>().content.email;
      openUrl('mailto:$email?subject=$subject&body=$body');
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Column(
      children: [
        const PageHero(
          eyebrow: 'Contact',
          title: "Let's connect",
          subtitle:
              'Have a question, need prayer, or want to get involved? We would '
              'love to hear from you.',
        ),
        Section(
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: isDesktop ? 5 : 0, child: const _ContactDetails()),
              SizedBox(width: isDesktop ? 64 : 0, height: isDesktop ? 0 : 40),
              Expanded(
                flex: isDesktop ? 6 : 0,
                child: SurfaceCard(
                  padding: const EdgeInsets.all(32),
                  child: _sent ? _thankYou(context) : _form(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thankYou(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.gold, size: 44),
        const SizedBox(height: 16),
        Text('Thank you!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          'Your message is ready to send from your email app. We will get back '
          'to you as soon as we can.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'Send a Message',
            title: 'We would love to hear from you',
            centered: false,
          ),
          const SizedBox(height: 28),
          _Field(
            controller: _name,
            label: 'Your name',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _email,
            label: 'Email address',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _message,
            label: 'How can we help?',
            maxLines: 5,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter a message'
                : null,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Send Message',
            icon: Icons.send,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          icon: Icons.place_outlined,
          title: 'Visit',
          value: '${content.addressLine1}\n${content.addressLine2}',
          onTap: () => openUrl(content.mapUrl),
        ),
        _DetailRow(
          icon: Icons.mail_outline,
          title: 'Email',
          value: content.email,
          onTap: () => openEmail(content.email),
        ),
        _DetailRow(
          icon: Icons.call_outlined,
          title: 'Call',
          value: content.phone,
          onTap: () => openPhone(content.phone),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.navy),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.inkSoft),
        filled: true,
        fillColor: AppColors.ivory,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
      ),
    );
  }
}

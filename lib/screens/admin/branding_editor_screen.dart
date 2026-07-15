import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/site_controller.dart';
import '../../theme/app_theme.dart';
import 'admin_widgets.dart';

class BrandingEditorScreen extends StatelessWidget {
  const BrandingEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;

    return Scaffold(
      appBar: AppBar(title: const Text('Branding & Content')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSection(
            title: 'Identity',
            description: 'The core name and mark for the church.',
            children: [
              AdminField(
                label: 'Church name',
                value: config.churchName,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(churchName: v)),
              ),
              AdminField(
                label: 'Tagline',
                value: config.tagline,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(tagline: v)),
              ),
              AdminField(
                label: 'Logo initials (used if no logo image)',
                value: config.logoInitials,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(logoInitials: v)),
              ),
              AdminField(
                label: 'Logo image URL (optional)',
                value: config.logoImageUrl,
                hint: 'https://…',
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(logoImageUrl: v)),
              ),
            ],
          ),
          AdminSection(
            title: 'Branding',
            description: 'Colors, typography, and shape define the whole app.',
            children: [
              AdminColorField(
                label: 'Primary color',
                hex: config.primaryColorHex,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(primaryColorHex: v)),
              ),
              AdminColorField(
                label: 'Secondary color',
                hex: config.secondaryColorHex,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(secondaryColorHex: v)),
              ),
              AdminColorField(
                label: 'Accent color',
                hex: config.accentColorHex,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(accentColorHex: v)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: kFontChoices.contains(config.fontFamily)
                    ? config.fontFamily
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Font family'),
                items: [
                  for (final f in kFontChoices)
                    DropdownMenuItem(value: f, child: Text(f)),
                ],
                onChanged: (v) => site
                    .updateConfig(config.copyWith(fontFamily: v ?? 'Poppins')),
              ),
              const SizedBox(height: 20),
              Text('Corner roundness: ${config.cornerRadius.round()}',
                  style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: config.cornerRadius.clamp(0, 40),
                min: 0,
                max: 40,
                divisions: 40,
                label: config.cornerRadius.round().toString(),
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(cornerRadius: v)),
              ),
              AdminSwitch(
                title: 'Dark mode',
                subtitle: 'Ship the app with a dark theme by default.',
                value: config.darkMode,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(darkMode: v)),
              ),
            ],
          ),
          AdminSection(
            title: 'Home hero',
            children: [
              AdminField(
                label: 'Hero title',
                value: config.heroTitle,
                maxLines: 2,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(heroTitle: v)),
              ),
              AdminField(
                label: 'Hero subtitle',
                value: config.heroSubtitle,
                maxLines: 3,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(heroSubtitle: v)),
              ),
              AdminField(
                label: 'Primary button label',
                value: config.heroCtaLabel,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(heroCtaLabel: v)),
              ),
              AdminField(
                label: 'Primary button URL',
                value: config.heroCtaUrl,
                hint: 'https://…',
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(heroCtaUrl: v)),
              ),
              AdminField(
                label: 'Hero background image URL (optional)',
                value: config.heroImageUrl,
                hint: 'https://…',
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(heroImageUrl: v)),
              ),
            ],
          ),
          AdminSection(
            title: 'Welcome & About',
            children: [
              AdminField(
                label: 'Welcome title',
                value: config.welcomeTitle,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(welcomeTitle: v)),
              ),
              AdminField(
                label: 'Welcome message',
                value: config.welcomeBody,
                maxLines: 4,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(welcomeBody: v)),
              ),
              AdminField(
                label: 'About title',
                value: config.aboutTitle,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(aboutTitle: v)),
              ),
              AdminField(
                label: 'About / story',
                value: config.aboutBody,
                maxLines: 5,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(aboutBody: v)),
              ),
              AdminField(
                label: 'Mission statement',
                value: config.missionStatement,
                maxLines: 2,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(missionStatement: v)),
              ),
              AdminField(
                label: 'Beliefs (one per line)',
                value: config.beliefs.join('\n'),
                maxLines: 5,
                onChanged: (v) => site.updateConfig(config.copyWith(
                    beliefs: v
                        .split('\n')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList())),
              ),
            ],
          ),
          AdminSection(
            title: 'Contact',
            children: [
              AdminField(
                label: 'Address',
                value: config.address,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(address: v)),
              ),
              AdminField(
                label: 'Phone',
                value: config.phone,
                keyboardType: TextInputType.phone,
                onChanged: (v) => site.updateConfig(config.copyWith(phone: v)),
              ),
              AdminField(
                label: 'Email',
                value: config.email,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => site.updateConfig(config.copyWith(email: v)),
              ),
              AdminField(
                label: 'Map URL',
                value: config.mapUrl,
                hint: 'https://maps.google.com/…',
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(mapUrl: v)),
              ),
            ],
          ),
          AdminSection(
            title: 'Media & Giving',
            children: [
              AdminField(
                label: 'Live stream URL',
                value: config.liveStreamUrl,
                hint: 'https://youtube.com/…/live',
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(liveStreamUrl: v)),
              ),
              AdminField(
                label: 'Giving title',
                value: config.givingTitle,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(givingTitle: v)),
              ),
              AdminField(
                label: 'Giving message',
                value: config.givingBody,
                maxLines: 3,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(givingBody: v)),
              ),
              AdminField(
                label: 'Primary "Give Now" URL',
                value: config.primaryGiveUrl,
                hint: 'https://…',
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(primaryGiveUrl: v)),
              ),
            ],
          ),
          AdminSection(
            title: 'Sections',
            description: 'Turn parts of the app on or off for this church.',
            children: [
              AdminSwitch(
                title: 'About',
                value: config.showAbout,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(showAbout: v)),
              ),
              AdminSwitch(
                title: 'Messages / Sermons',
                value: config.showSermons,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(showSermons: v)),
              ),
              AdminSwitch(
                title: 'Events',
                value: config.showEvents,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(showEvents: v)),
              ),
              AdminSwitch(
                title: 'Ministries',
                value: config.showMinistries,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(showMinistries: v)),
              ),
              AdminSwitch(
                title: 'Giving',
                value: config.showGiving,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(showGiving: v)),
              ),
              AdminSwitch(
                title: 'Contact',
                value: config.showContact,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(showContact: v)),
              ),
              AdminSwitch(
                title: 'Live stream banner',
                value: config.showLiveStream,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(showLiveStream: v)),
              ),
            ],
          ),
          AdminSection(
            title: 'Footer',
            children: [
              AdminField(
                label: 'Footer note',
                value: config.footerNote,
                maxLines: 2,
                onChanged: (v) =>
                    site.updateConfig(config.copyWith(footerNote: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/church_settings.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../application/settings_controller.dart';
import 'admin_header.dart';

/// The screen that makes this app resellable: everything a church needs
/// to make the site theirs, editable without touching code or redeploying.
class SettingsAdminScreen extends ConsumerStatefulWidget {
  const SettingsAdminScreen({super.key});

  @override
  ConsumerState<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends ConsumerState<SettingsAdminScreen> {
  final _fields = <String, TextEditingController>{};
  final _serviceTimes = <_ServiceRow>[];
  late BrandColors _colors;
  late FeatureFlags _flags;
  bool _hydrated = false;

  TextEditingController _field(String key, String initial) =>
      _fields.putIfAbsent(key, () => TextEditingController(text: initial));

  /// Fill the form from loaded settings exactly once, so a later stream
  /// emission can't clobber what the admin is typing.
  void _hydrate(ChurchSettings s) {
    if (_hydrated) return;
    _hydrated = true;
    _field('churchName', s.churchName);
    _field('tagline', s.tagline);
    _field('logoUrl', s.logoUrl);
    _field('aboutHeadline', s.aboutHeadline);
    _field('aboutBody', s.aboutBody);
    _field('beliefs', s.beliefs);
    _field('visitInfo', s.visitInfo);
    _field('address', s.contact.address);
    _field('phone', s.contact.phone);
    _field('email', s.contact.email);
    _field('mapUrl', s.contact.mapUrl);
    _field('facebook', s.social.facebook);
    _field('instagram', s.social.instagram);
    _field('youtube', s.social.youtube);
    _field('givingUrl', s.social.givingUrl);
    _field('liveStreamUrl', s.social.liveStreamUrl);
    _field('podcastUrl', s.social.podcastUrl);
    _colors = s.colors;
    _flags = s.features;
    for (final service in s.serviceTimes) {
      _serviceTimes.add(_ServiceRow.from(service));
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final row in _serviceTimes) {
      row.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _fields[key]?.text.trim() ?? '';

  ChurchSettings _compose(ChurchSettings original) => original.copyWith(
        churchName: _text('churchName'),
        tagline: _text('tagline'),
        logoUrl: _text('logoUrl'),
        aboutHeadline: _text('aboutHeadline'),
        aboutBody: _text('aboutBody'),
        beliefs: _text('beliefs'),
        visitInfo: _text('visitInfo'),
        colors: _colors,
        contact: ContactInfo(
          address: _text('address'),
          phone: _text('phone'),
          email: _text('email'),
          mapUrl: _text('mapUrl'),
        ),
        social: SocialLinks(
          facebook: _text('facebook'),
          instagram: _text('instagram'),
          youtube: _text('youtube'),
          givingUrl: _text('givingUrl'),
          liveStreamUrl: _text('liveStreamUrl'),
          podcastUrl: _text('podcastUrl'),
        ),
        serviceTimes: [
          for (final row in _serviceTimes)
            if (row.day.text.trim().isNotEmpty || row.time.text.trim().isNotEmpty)
              ServiceTime(
                day: row.day.text.trim(),
                time: row.time.text.trim(),
                label: row.label.text.trim(),
              ),
        ],
        features: _flags,
      );

  Future<void> _save(ChurchSettings original) async {
    final ok = await ref.read(settingsControllerProvider.notifier).save(_compose(original));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Settings saved. The site has been updated.' : 'Could not save settings.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final busy = ref.watch(settingsControllerProvider).isLoading;
    _hydrate(settings);

    return PageBody(
      children: [
        const AdminHeader(
          title: 'Church Settings',
          subtitle: 'Branding and configuration. Changes apply to the live site immediately.',
        ),
        SectionContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section(
                title: 'Identity',
                children: [
                  _text_('Church name', 'churchName'),
                  _text_('Tagline', 'tagline'),
                  _text_('Logo URL (optional)', 'logoUrl'),
                ],
              ),
              _Section(
                title: 'Brand colors',
                description: 'Paste hex codes from your brand guide, e.g. #1B3A4B.',
                children: [
                  _ColorField(
                    label: 'Primary',
                    color: _colors.primary,
                    onChanged: (c) => setState(() => _colors = BrandColors(
                          primary: c,
                          accent: _colors.accent,
                          background: _colors.background,
                        )),
                  ),
                  _ColorField(
                    label: 'Accent',
                    color: _colors.accent,
                    onChanged: (c) => setState(() => _colors = BrandColors(
                          primary: _colors.primary,
                          accent: c,
                          background: _colors.background,
                        )),
                  ),
                  _ColorField(
                    label: 'Background',
                    color: _colors.background,
                    onChanged: (c) => setState(() => _colors = BrandColors(
                          primary: _colors.primary,
                          accent: _colors.accent,
                          background: c,
                        )),
                  ),
                  const SizedBox(height: 12),
                  _BrandPreview(colors: _colors, churchName: _text('churchName')),
                ],
              ),
              _Section(
                title: 'Homepage & About copy',
                children: [
                  _text_('About headline', 'aboutHeadline'),
                  _text_('About body', 'aboutBody', lines: 4),
                  _text_('What we believe', 'beliefs', lines: 4),
                  _text_('Plan a Visit info', 'visitInfo', lines: 4),
                ],
              ),
              _Section(
                title: 'Contact',
                children: [
                  _text_('Address', 'address'),
                  _text_('Phone', 'phone'),
                  _text_('Email', 'email'),
                  _text_('Map URL', 'mapUrl'),
                ],
              ),
              _Section(
                title: 'Service times',
                children: [
                  for (var i = 0; i < _serviceTimes.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _serviceTimes[i].day,
                              decoration: const InputDecoration(labelText: 'Day'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _serviceTimes[i].time,
                              decoration: const InputDecoration(labelText: 'Time'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _serviceTimes[i].label,
                              decoration: const InputDecoration(labelText: 'Label'),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() => _serviceTimes.removeAt(i).dispose()),
                          ),
                        ],
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(() => _serviceTimes.add(_ServiceRow.empty())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a service time'),
                  ),
                ],
              ),
              _Section(
                title: 'Links',
                children: [
                  _text_('Giving URL', 'givingUrl'),
                  _text_('Live stream URL', 'liveStreamUrl'),
                  _text_('Podcast feed URL', 'podcastUrl'),
                  _text_('Facebook', 'facebook'),
                  _text_('Instagram', 'instagram'),
                  _text_('YouTube', 'youtube'),
                ],
              ),
              _Section(
                title: 'Features',
                description: 'Turn off anything your church does not use. Disabled '
                    'features disappear from navigation entirely.',
                children: [
                  for (final entry in _featureLabels.entries)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(entry.value),
                      value: _flags.toMap()[entry.key] as bool? ?? true,
                      onChanged: (v) => setState(() => _flags = _flags.copyWithEntry(entry.key, v)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: busy ? null : () => _save(settings),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _text_(String label, String key, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _field(key, ''),
          maxLines: lines,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

const _featureLabels = {
  'sermons': 'Sermons',
  'events': 'Events',
  'giving': 'Giving',
  'connect': 'Connect / prayer requests',
  'groups': 'Small groups',
  'volunteering': 'Volunteering',
  'prayerWall': 'Prayer wall',
  'readingPlans': 'Bible reading plans',
  'devotionals': 'Devotionals',
  'resources': 'Resource library',
  'kidsCheckIn': 'Kids check-in',
  'roomBooking': 'Room booking',
};

class _Section extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const _Section({required this.title, this.description = '', required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Hex text field with a live swatch. Parsing reuses [BrandColors.fromMap],
/// which already tolerates `#RRGGBB`, bare `RRGGBB`, and `#AARRGGBB`.
class _ColorField extends StatefulWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorField({required this.label, required this.color, required this.onChanged});

  @override
  State<_ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<_ColorField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _hex(widget.color));
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: widget.label, hintText: '#1B3A4B'),
              onChanged: (value) {
                final parsed = BrandColors.fromMap({'primary': value}).primary;
                widget.onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows what the chosen palette looks like before saving.
class _BrandPreview extends StatelessWidget {
  final BrandColors colors;
  final String churchName;

  const _BrandPreview({required this.colors, required this.churchName});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: colors.background,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(6)),
              child: Text(
                churchName.isEmpty ? 'Your Church' : churchName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Give', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Text('Preview', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceRow {
  final TextEditingController day;
  final TextEditingController time;
  final TextEditingController label;

  _ServiceRow({required this.day, required this.time, required this.label});

  factory _ServiceRow.empty() => _ServiceRow(
        day: TextEditingController(),
        time: TextEditingController(),
        label: TextEditingController(),
      );

  factory _ServiceRow.from(ServiceTime service) => _ServiceRow(
        day: TextEditingController(text: service.day),
        time: TextEditingController(text: service.time),
        label: TextEditingController(text: service.label),
      );

  void dispose() {
    day.dispose();
    time.dispose();
    label.dispose();
  }
}

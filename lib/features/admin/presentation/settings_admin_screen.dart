import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/church_settings.dart';
import '../../../core/config/contrast.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/config/themes.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_container.dart';
import '../../live/application/live_providers.dart';
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
    _field('youtubeChannelId', s.social.youtubeChannelId);
    _field('podcastUrl', s.social.podcastUrl);
    _field('releasesRepo', s.releasesRepo);
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
        releasesRepo: _text('releasesRepo'),
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
          youtubeChannelId: _text('youtubeChannelId'),
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
                description: 'Start from a ready-made look, then change anything you '
                    'like. If you have a brand guide, paste its hex codes below.',
                children: [
                  _ThemeGallery(
                    current: _colors,
                    // A theme only fills in the fields below; the hex
                    // codes remain the record, so there is nothing new
                    // to save and nothing that can disagree with them.
                    onPicked: (theme) => setState(() => _colors = theme.colors),
                  ),
                  const SizedBox(height: 20),
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
                      // Day, time and label share about ninety pixels each
                      // on a phone. Stacked, they are just three fields.
                      child: ResponsiveRow(
                        spacing: 12,
                        flex: const [1, 1, 2],
                        children: [
                          TextField(
                            controller: _serviceTimes[i].day,
                            decoration: const InputDecoration(labelText: 'Day'),
                          ),
                          TextField(
                            controller: _serviceTimes[i].time,
                            decoration: const InputDecoration(labelText: 'Time'),
                          ),
                          Row(
                            children: [
                              Expanded(
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
                title: 'Live streaming',
                description: 'Paste your channel id and the home page raises a '
                    '"Live now" banner by itself whenever you go live, then files '
                    'the finished stream as an unpublished sermon for you to '
                    'review. Find the id in YouTube Studio under Settings → '
                    'Channel → Advanced settings; it starts with UC.',
                children: [
                  _text_('YouTube channel ID', 'youtubeChannelId'),
                  const _LastChecked(),
                ],
              ),
              _Section(
                title: 'App downloads',
                description: 'The GitHub repository whose releases hold the '
                    'installable apps, as owner/repo. Leave it blank and the '
                    'download page stays hidden.',
                children: [
                  _text_('Releases repository', 'releasesRepo'),
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
  'attendance': 'Attendance tracking',
  'forms': 'Forms & sign-ups',
  'appDownloads': 'App download page',
};

/// When the poller last looked at this church's channel.
///
/// The difference between "we checked, you are not streaming" and
/// "nothing has ever checked" is the whole of whether the setup worked,
/// and an admin who has just pasted a channel id has no other way to
/// tell - the banner staying away looks identical either way.
class _LastChecked extends ConsumerWidget {
  const _LastChecked();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(liveStatusProvider).valueOrNull;
    final checkedAt = status?.checkedAt;

    final (icon, message) = switch (status) {
      null => (Icons.hourglass_empty, 'Checking…'),
      _ when checkedAt == null => (
          Icons.schedule,
          'Not checked yet. The first check runs within five minutes of '
              'saving a channel id.',
        ),
      _ when status.live => (Icons.sensors, 'Live now — last checked ${_ago(checkedAt)}.'),
      _ => (Icons.check_circle_outline, 'Not streaming. Last checked ${_ago(checkedAt)}.'),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime when) {
    final minutes = DateTime.now().difference(when).inMinutes;
    if (minutes < 1) return 'just now';
    if (minutes < 60) return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hour${hours == 1 ? '' : 's'} ago';
    final days = hours ~/ 24;
    return '$days day${days == 1 ? '' : 's'} ago';
  }
}

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

/// Ready-made looks, as swatches you can see rather than codes you have
/// to imagine.
///
/// A church with a brand guide pastes hex codes into the fields below.
/// A church without one - which is most of them - was left staring at
/// `#RRGGBB` with no way to tell what it would do.
class _ThemeGallery extends StatelessWidget {
  final BrandColors current;
  final ValueChanged<ChurchTheme> onPicked;

  const _ThemeGallery({required this.current, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final theme in churchThemes)
          _ThemeSwatch(
            theme: theme,
            selected: theme.matches(current),
            onTap: () => onPicked(theme),
          ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final ChurchTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({required this.theme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 168,
      child: Material(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? scheme.primary : Colors.black12,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // The bar and the dot are the two colours doing the
                    // work everywhere else in the app: the banner, and
                    // whatever sits on it.
                    Expanded(
                      child: Container(
                        height: 26,
                        decoration: BoxDecoration(
                          color: theme.colors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: theme.colors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        theme.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (selected) Icon(Icons.check_circle, size: 16, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  theme.description,
                  style: const TextStyle(color: Colors.black54, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ),
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

  /// Follows the colour when it is changed from outside - which is what
  /// picking a theme does.
  ///
  /// Guarded on the *parsed* value rather than the text, so someone
  /// halfway through typing `#1B3A` is not interrupted by their own
  /// keystrokes being rewritten.
  @override
  void didUpdateWidget(_ColorField old) {
    super.didUpdateWidget(old);
    final shown = BrandColors.fromMap({'primary': _controller.text}).primary;
    if (shown.toARGB32() != widget.color.toARGB32()) {
      _controller.text = _hex(widget.color);
    }
  }

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
            // Wrap rather than Row: this is a preview of a button beside
            // a label, and at a large font size the pair is wider than a
            // phone. Letting them stack is what a preview should do.
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(6)),
                  // The same choice the real button makes. A preview
                  // that hardcoded white would be showing an admin a
                  // button their site does not have.
                  child: Text(
                    'Give',
                    style: TextStyle(color: readableOn(colors.accent), fontWeight: FontWeight.w600),
                  ),
                ),
                Text('Preview', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            _ContrastNote(colors: colors),
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

/// Says so when the colours an admin typed will not read.
///
/// Advice, not a gate. These are their church's colours and they may
/// have been chosen by somebody with a brand guide and an opinion - a
/// rule that cannot be overridden is one people route around by giving
/// up on the feature. What it can do is make sure nobody finds out from
/// a member squinting at a Give button in a car park.
///
/// Names the measured number and what it affects, because "poor
/// contrast" is not actionable and "2.4:1 against the 4.5:1 text needs"
/// is.
class _ContrastNote extends StatelessWidget {
  final BrandColors colors;

  const _ContrastNote({required this.colors});

  @override
  Widget build(BuildContext context) {
    final problems = <String>[
      // The button foreground is chosen for readability now, so this
      // only fires when *neither* black nor white works on the accent -
      // which takes a genuinely mid-grey choice.
      if (contrastRatio(readableOn(colors.accent), colors.accent) < readableContrast)
        'Buttons in this accent cannot be read in black or white '
            '(${contrastRatio(readableOn(colors.accent), colors.accent).toStringAsFixed(1)}:1). '
            'A darker or lighter accent would fix it.',
      if (contrastRatio(colors.primary, colors.background) < readableContrast)
        'Headings and links are hard to read on this background '
            '(${contrastRatio(colors.primary, colors.background).toStringAsFixed(1)}:1, '
            'against the ${readableContrast.toStringAsFixed(1)}:1 text needs). '
            'A deeper main colour, or a paler background, would fix it.',
    ];

    if (problems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final problem in problems)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      problem,
                      style: TextStyle(fontSize: 12, height: 1.35, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

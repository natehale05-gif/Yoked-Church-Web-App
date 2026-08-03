import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/config/settings_providers.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/section_container.dart';
import '../domain/app_download.dart';

/// Where a member goes to install the app on their own machine or phone.
///
/// The visitor's own platform is worked out and shown first, as one large
/// button. Everything else moves below a divider. A member should not
/// have to know whether they want the `.apk` or the `.tar.gz`.
class DownloadScreen extends ConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final repo = settings.releasesRepo.trim();
    final detected = buildForCurrentPlatform();
    final others = appBuilds.where((b) => b != detected).toList();

    return PageBody(
      children: [
        PageBanner(
          eyebrow: 'Apps',
          title: 'Get the ${settings.churchName} app',
          subtitle: 'The same site, installed on your computer or phone. '
              'Free, and there is nothing to sign up for.',
        ),
        SectionContainer(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detected != null) ...[
                Text('Recommended for you', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _DownloadCard(download: detected, repo: repo, highlighted: true),
                const SizedBox(height: 32),
                Text(
                  'Other platforms',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Reached on iPhone and iPad, and on anything whose
                // platform we could not identify.
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  const _Notice(icon: Icons.phone_iphone, text: iosExplanation),
                  const SizedBox(height: 32),
                ],
                Text('Choose your platform', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
              ],
              for (final other in others) ...[
                _DownloadCard(download: other, repo: repo),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 20),
              const _Notice(
                icon: Icons.lock_outline,
                // The honest version. These builds are not code-signed,
                // and a member who meets that warning cold assumes the
                // worst about the church, not about the build pipeline.
                text: 'These apps are not code-signed, so your computer or '
                    'phone will warn you the first time you open one. That '
                    'warning means the app has no paid certificate attached, '
                    'not that anything is wrong with it. Each download above '
                    'says exactly what you will see and what to click.',
              ),
              const SizedBox(height: 12),
              const _Notice(
                icon: Icons.public,
                text: 'Nothing to install? The website works everywhere, '
                    'including on iPhone and iPad, and it is always the '
                    'newest version.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final AppDownload download;
  final String repo;
  final bool highlighted;

  const _DownloadCard({required this.download, required this.repo, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    final button = FilledButton.icon(
      onPressed: () => launchUrl(Uri.parse(download.urlFor(repo)), webOnlyWindowName: '_blank'),
      icon: const Icon(Icons.download),
      label: Text('Download for ${download.label}'),
    );

    return Card(
      elevation: highlighted ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlighted ? theme.colorScheme.primary : theme.dividerColor,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // On a phone the button goes under the text at full width;
            // side by side it would squeeze the label to two characters.
            if (isMobile) ...[
              _heading(theme),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: button),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _heading(theme)),
                  const SizedBox(width: 16),
                  button,
                ],
              ),
            const SizedBox(height: 16),
            _line(theme, Icons.install_desktop, download.install),
            const SizedBox(height: 8),
            _line(theme, Icons.shield_outlined, download.warning),
            if (download.caveat.isNotEmpty) ...[
              const SizedBox(height: 8),
              _line(theme, Icons.info_outline, download.caveat),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heading(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(download.label, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(download.fileHint, style: theme.textTheme.bodySmall),
        ],
      );

  Widget _line(ThemeData theme, IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      );
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

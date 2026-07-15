import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/church_config.dart';
import '../navigation/nav_section.dart';
import '../state/site_controller.dart';
import '../utils/color_utils.dart';
import '../utils/launch_helper.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/site_footer.dart';

class HomeScreen extends StatelessWidget {
  final void Function(SectionId) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;

    return SingleChildScrollView(
      child: Column(
        children: [
          _Hero(config: config, onNavigate: onNavigate),
          if (config.serviceTimes.isNotEmpty)
            _ServiceTimesStrip(config: config),
          if (config.welcomeBody.isNotEmpty) _Welcome(config: config),
          _Highlights(site: site, onNavigate: onNavigate),
          if (config.showGiving) _GivingBanner(config: config),
          SiteFooter(config: config),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ChurchConfig config;
  final void Function(SectionId) onNavigate;

  const _Hero({required this.config, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = ColorUtils.fromHex(config.primaryColorHex);
    final secondary = ColorUtils.fromHex(config.secondaryColorHex);
    final onGradient = ColorUtils.onColor(primary);
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        image: config.heroImageUrl.trim().isNotEmpty
            ? DecorationImage(
                image: NetworkImage(config.heroImageUrl.trim()),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  primary.withOpacity(0.72),
                  BlendMode.multiply,
                ),
              )
            : null,
      ),
      child: ContentContainer(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isMobile ? 64 : 112,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.tagline.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: onGradient.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  config.tagline,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: onGradient,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                config.heroTitle.isNotEmpty
                    ? config.heroTitle
                    : 'Welcome to ${config.churchName}',
                style: (isMobile
                        ? theme.textTheme.displaySmall
                        : theme.textTheme.displayLarge)
                    ?.copyWith(
                  color: onGradient,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -1,
                ),
              ),
            ),
            if (config.heroSubtitle.isNotEmpty) ...[
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  config.heroSubtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onGradient.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () {
                    if (config.heroCtaUrl.trim().isNotEmpty) {
                      openUrl(context, config.heroCtaUrl);
                    } else {
                      onNavigate(SectionId.contact);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: onGradient,
                    foregroundColor: primary,
                  ),
                  child: Text(config.heroCtaLabel.isNotEmpty
                      ? config.heroCtaLabel
                      : 'Plan Your Visit'),
                ),
                if (config.showSermons)
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(SectionId.sermons),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onGradient,
                      side: BorderSide(color: onGradient.withOpacity(0.6)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Watch a Message'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTimesStrip extends StatelessWidget {
  final ChurchConfig config;

  const _ServiceTimesStrip({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentContainer(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final s in config.serviceTimes)
            Container(
              width: Responsive.isMobile(context) ? double.infinity : 260,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius:
                    BorderRadius.circular(config.cornerRadius.clamp(0, 28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(height: 12),
                  Text(s.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${s.day} · ${s.time}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  if (s.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(s.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final ChurchConfig config;

  const _Welcome({required this.config});

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionHeader(
            eyebrow: 'Welcome',
            title: config.welcomeTitle.isNotEmpty
                ? config.welcomeTitle
                : "We're glad you're here",
            subtitle: config.welcomeBody,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  final SiteController site;
  final void Function(SectionId) onNavigate;

  const _Highlights({required this.site, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final config = site.config;
    final latestSermon =
        site.sermonsByNewest.isNotEmpty ? site.sermonsByNewest.first : null;
    final nextEvent =
        site.upcomingEvents.isNotEmpty ? site.upcomingEvents.first : null;

    final cards = <Widget>[];
    if (config.showSermons && latestSermon != null) {
      cards.add(_HighlightCard(
        eyebrow: 'Latest Message',
        title: latestSermon.title,
        subtitle: latestSermon.speaker,
        icon: Icons.play_circle_fill,
        actionLabel: 'Watch',
        onTap: () => onNavigate(SectionId.sermons),
      ));
    }
    if (config.showEvents && nextEvent != null) {
      cards.add(_HighlightCard(
        eyebrow: 'Next Event',
        title: nextEvent.title,
        subtitle: DateFormat('EEE, MMM d · h:mm a').format(nextEvent.start),
        icon: Icons.event_available,
        actionLabel: 'See events',
        onTap: () => onNavigate(SectionId.events),
      ));
    }
    if (config.showMinistries && site.ministries.isNotEmpty) {
      cards.add(_HighlightCard(
        eyebrow: 'Get Involved',
        title: 'Find your place',
        subtitle: '${site.ministries.length} ministries to explore',
        icon: Icons.diversity_3,
        actionLabel: 'Explore',
        onTap: () => onNavigate(SectionId.ministries),
      ));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    final columns = Responsive.gridColumns(context,
        mobile: 1, tablet: 2, desktop: cards.length.clamp(1, 3));

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      width: double.infinity,
      child: ContentContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'This Week',
              title: 'What\'s happening',
            ),
            const SizedBox(height: 28),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: Responsive.isMobile(context) ? 1.6 : 1.15,
              children: cards,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  const _HighlightCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 34),
              const Spacer(),
              Text(eyebrow.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  )),
              const SizedBox(height: 6),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(actionLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  Icon(Icons.arrow_forward,
                      size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GivingBanner extends StatelessWidget {
  final ChurchConfig config;

  const _GivingBanner({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ColorUtils.fromHex(config.accentColorHex);
    final onAccent = ColorUtils.onColor(accent);
    return ContentContainer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(config.cornerRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.givingTitle.isNotEmpty ? config.givingTitle : 'Give',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: onAccent,
                  fontWeight: FontWeight.w800,
                )),
            if (config.givingBody.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(config.givingBody,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: onAccent.withOpacity(0.9))),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => openUrl(
                  context,
                  config.primaryGiveUrl.isNotEmpty
                      ? config.primaryGiveUrl
                      : config.heroCtaUrl),
              style: FilledButton.styleFrom(
                backgroundColor: onAccent,
                foregroundColor: accent,
              ),
              icon: const Icon(Icons.favorite),
              label: const Text('Give Now'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/site_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../utils/launch.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/content_width.dart';
import '../widgets/photo_frame.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Hero(),
        _WhatToExpect(),
        _WelcomeTeaser(),
        _ValuesBand(),
        _MinistriesPreview(),
        _LatestMessage(),
        _EventsPreview(),
        _VisitCta(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navy],
        ),
      ),
      padding: EdgeInsets.only(
        top: context.responsive(mobile: 120, desktop: 156),
        bottom: context.responsive(mobile: 64, desktop: 110),
      ),
      child: ContentWidth(
        child: Flex(
          direction: isDesktop ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: isDesktop ? 6 : 0, child: const _HeroText()),
            SizedBox(width: isDesktop ? 56 : 0, height: isDesktop ? 0 : 44),
            Expanded(
              flex: isDesktop ? 5 : 0,
              child: const PhotoFrame(
                aspectRatio: 4 / 5,
                radius: 28,
                placeholderIcon: Icons.groups_2_outlined,
                placeholderLabel: 'Add a warm, wide photo\nof your church family',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.onDark.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.onDark.withValues(alpha: 0.18)),
          ),
          child: Text(
            'WELCOME TO ${SiteConfig.shortName.toUpperCase()}',
            style: AppTheme.eyebrow(color: AppColors.goldSoft),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          SiteConfig.heroHeadline,
          style: context
              .responsive(
                mobile: Theme.of(context).textTheme.displayMedium,
                desktop: Theme.of(context).textTheme.displayLarge,
              )!
              .copyWith(color: AppColors.onDark),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            SiteConfig.heroSubhead,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.onDarkSoft, fontSize: 19),
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            PrimaryButton(
              label: 'Plan Your Visit',
              icon: Icons.arrow_forward,
              onPressed: () => context.go('/visit'),
            ),
            SecondaryButton(
              label: 'Watch a Message',
              icon: Icons.play_circle_outline,
              onDark: true,
              onPressed: () => context.go('/sermons'),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const _ServiceTimeStrip(),
      ],
    );
  }
}

class _ServiceTimeStrip extends StatelessWidget {
  const _ServiceTimeStrip();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 28,
      runSpacing: 16,
      children: [
        for (final s in SiteConfig.serviceTimes)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, color: AppColors.goldSoft, size: 18),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${s.day} ',
                      style: const TextStyle(
                        color: AppColors.onDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: s.time,
                      style: const TextStyle(
                        color: AppColors.onDarkSoft,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// What to expect
// ---------------------------------------------------------------------------
class _WhatToExpect extends StatelessWidget {
  const _WhatToExpect();

  @override
  Widget build(BuildContext context) {
    return Section(
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'Your First Visit',
            title: 'What to expect on Sunday',
            subtitle:
                'However you come and whatever you believe, you will find a '
                'friendly welcome and a place to belong.',
          ),
          const SizedBox(height: 56),
          ResponsiveGrid(
            children: [
              for (final p in SiteConfig.whatToExpect) ValueCard(p),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome teaser (photo + text)
// ---------------------------------------------------------------------------
class _WelcomeTeaser extends StatelessWidget {
  const _WelcomeTeaser();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Section(
      background: AppColors.cream,
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isDesktop ? 5 : 0,
            child: const PhotoFrame(
              aspectRatio: 4 / 3,
              placeholderIcon: Icons.diversity_1_outlined,
              placeholderLabel: 'Photo of people\nconnecting together',
            ),
          ),
          SizedBox(width: isDesktop ? 64 : 0, height: isDesktop ? 0 : 40),
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'Who We Are',
                  title: 'A church for real people, real life',
                  subtitle:
                      'We are ordinary people from every background and walk of '
                      'life, following Jesus together. No perfect people '
                      'required — just come as you are.',
                  centered: false,
                ),
                const SizedBox(height: 28),
                SecondaryButton(
                  label: 'Meet Our Team',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/about'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Values band (dark)
// ---------------------------------------------------------------------------
class _ValuesBand extends StatelessWidget {
  const _ValuesBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: EdgeInsets.symmetric(
        vertical: context.responsive(mobile: 56, desktop: 104),
      ),
      child: ContentWidth(
        child: Column(
          children: [
            const SectionHeader(
              eyebrow: 'What We Value',
              title: 'The heart behind everything we do',
              onDark: true,
            ),
            const SizedBox(height: 56),
            ResponsiveGrid(
              desktopColumns: 4,
              tabletColumns: 2,
              children: [
                for (final v in SiteConfig.values) _DarkValueCard(v),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkValueCard extends StatelessWidget {
  final ValuePoint point;
  const _DarkValueCard(this.point);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(point.icon, color: AppColors.goldSoft, size: 34),
        const SizedBox(height: 20),
        Text(
          point.title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: AppColors.onDark),
        ),
        const SizedBox(height: 12),
        Text(
          point.body,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.onDarkSoft),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ministries preview
// ---------------------------------------------------------------------------
class _MinistriesPreview extends StatelessWidget {
  const _MinistriesPreview();

  @override
  Widget build(BuildContext context) {
    final preview = SiteConfig.ministries.take(3).toList();
    return Section(
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'Get Involved',
            title: 'There is a place for you',
            subtitle:
                'From the youngest kids to seasoned saints, we have a community '
                'ready to welcome you.',
          ),
          const SizedBox(height: 56),
          ResponsiveGrid(
            children: [for (final m in preview) MinistryCard(m)],
          ),
          const SizedBox(height: 44),
          SecondaryButton(
            label: 'Explore All Ministries',
            icon: Icons.arrow_forward,
            onPressed: () => context.go('/ministries'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Latest message
// ---------------------------------------------------------------------------
class _LatestMessage extends StatelessWidget {
  const _LatestMessage();

  @override
  Widget build(BuildContext context) {
    final latest = SiteConfig.sermons.first;
    final isDesktop = context.isDesktop;
    return Section(
      background: AppColors.cream,
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'Latest Message',
                  title: 'Catch up on Sunday',
                  subtitle:
                      'Missed a week or want to revisit a message? Watch and '
                      'listen anytime, anywhere.',
                  centered: false,
                ),
                const SizedBox(height: 24),
                Text(
                  latest.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${latest.speaker}  •  ${latest.date}',
                  style: AppTheme.eyebrow(color: AppColors.gold),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Watch Now',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.go('/sermons'),
                ),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 64 : 0, height: isDesktop ? 0 : 40),
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: SermonCard(latest),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Events preview
// ---------------------------------------------------------------------------
class _EventsPreview extends StatelessWidget {
  const _EventsPreview();

  @override
  Widget build(BuildContext context) {
    final preview = SiteConfig.events.take(3).toList();
    return Section(
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: "What's Coming Up",
            title: 'Upcoming events',
            subtitle:
                'Mark your calendar and join us. Everyone is welcome at all of '
                'our gatherings.',
          ),
          const SizedBox(height: 56),
          ResponsiveGrid(
            children: [for (final e in preview) EventCard(e)],
          ),
          const SizedBox(height: 44),
          SecondaryButton(
            label: 'See All Events',
            icon: Icons.arrow_forward,
            onPressed: () => context.go('/events'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visit CTA band
// ---------------------------------------------------------------------------
class _VisitCta extends StatelessWidget {
  const _VisitCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navy, AppColors.navyDeep],
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: context.responsive(mobile: 64, desktop: 110),
      ),
      child: ContentWidth(
        child: Column(
          children: [
            Text(
              'We would love to meet you',
              textAlign: TextAlign.center,
              style: context
                  .responsive(
                    mobile: Theme.of(context).textTheme.displaySmall,
                    desktop: Theme.of(context).textTheme.displayMedium,
                  )!
                  .copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'Join us this Sunday at ${SiteConfig.addressLine1}. '
                'Come a few minutes early and let us welcome you in person.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.onDarkSoft),
              ),
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                PrimaryButton(
                  label: 'Plan Your Visit',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/visit'),
                ),
                SecondaryButton(
                  label: 'Get Directions',
                  icon: Icons.place_outlined,
                  onDark: true,
                  onPressed: () => openUrl(SiteConfig.mapUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

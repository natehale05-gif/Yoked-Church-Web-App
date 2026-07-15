import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/site_content_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../utils/launch.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/content_width.dart';
import '../widgets/page_hero.dart';
import '../widgets/photo_frame.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/section_header.dart';

class VisitPage extends StatelessWidget {
  const VisitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHero(
          eyebrow: "I'm New",
          title: 'Plan your first visit',
          subtitle:
              'We know walking into a new church can feel like a big step. '
              "Here is everything you need to feel at home before you arrive.",
        ),
        _WhenWhere(),
        const _ExpectSection(),
        const _KidsHighlight(),
        const _QuestionsCta(),
      ],
    );
  }
}

class _WhenWhere extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final content = context.watch<SiteContentController>().content;
    return Section(
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 5 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WHEN WE GATHER', style: AppTheme.eyebrow()),
                const SizedBox(height: 20),
                for (final s in content.serviceTimes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.gold),
                        const SizedBox(width: 14),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${s.day}, ${s.time}\n',
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: s.label,
                                  style: const TextStyle(
                                    color: AppColors.inkSoft,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text('WHERE TO FIND US', style: AppTheme.eyebrow()),
                const SizedBox(height: 16),
                Text(
                  '${content.addressLine1}\n${content.addressLine2}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Get Directions',
                  icon: Icons.place_outlined,
                  onPressed: () => openUrl(content.mapUrl),
                ),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 64 : 0, height: isDesktop ? 0 : 40),
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: const PhotoFrame(
              aspectRatio: 4 / 3,
              placeholderIcon: Icons.church_outlined,
              placeholderLabel: 'Photo of your\nbuilding or entrance',
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectSection extends StatelessWidget {
  const _ExpectSection();

  @override
  Widget build(BuildContext context) {
    final content = context.watch<SiteContentController>().content;
    return Section(
      background: AppColors.cream,
      child: Column(
        children: [
          const SectionHeader(
            eyebrow: 'What to Expect',
            title: 'No surprises, just a warm welcome',
          ),
          const SizedBox(height: 56),
          ResponsiveGrid(
            children: [for (final p in content.whatToExpect) ValueCard(p)],
          ),
        ],
      ),
    );
  }
}

class _KidsHighlight extends StatelessWidget {
  const _KidsHighlight();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Section(
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: const PhotoFrame(
              aspectRatio: 4 / 3,
              placeholderIcon: Icons.child_care_outlined,
              placeholderLabel: 'Photo of happy kids\nin your kids ministry',
            ),
          ),
          SizedBox(width: isDesktop ? 64 : 0, height: isDesktop ? 0 : 40),
          Expanded(
            flex: isDesktop ? 6 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'For Families',
                  title: 'Your kids will love it here',
                  subtitle:
                      'Check-in is quick and secure. Our trained, background-'
                      'checked team creates safe, fun spaces where kids learn '
                      'about God at their level.',
                  centered: false,
                ),
                const SizedBox(height: 28),
                SecondaryButton(
                  label: 'See Kids & Students',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/ministries'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionsCta extends StatelessWidget {
  const _QuestionsCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: EdgeInsets.symmetric(
        vertical: context.responsive(mobile: 56, desktop: 96),
      ),
      child: ContentWidth(
        child: Column(
          children: [
            Text(
              'Still have questions?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: 18),
            Text(
              "We would be glad to help. Reach out and we'll get back to you.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.onDarkSoft),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Contact Us',
              icon: Icons.mail_outline,
              onPressed: () => context.go('/contact'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/app_icons.dart';
import '../models/site_content.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'photo_frame.dart';

/// Generic elevated surface used for most cards.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.color = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Icon + title + body, used for "what to expect" and values.
class ValueCard extends StatelessWidget {
  final ValuePoint point;
  const ValueCard(this.point, {super.key});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconForKey(point.iconKey), color: AppColors.navy, size: 28),
          ),
          const SizedBox(height: 22),
          Text(point.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(point.body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Ministry card with icon, audience, and description.
class MinistryCard extends StatelessWidget {
  final Ministry ministry;
  const MinistryCard(this.ministry, {super.key});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconForKey(ministry.iconKey), color: AppColors.gold, size: 30),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ministry.forWho,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(ministry.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            ministry.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Person card with a large photo area (built for real photos of people).
class PersonCard extends StatelessWidget {
  final Person person;
  const PersonCard(this.person, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhotoFrame(
          imageUrl: person.imageUrl,
          aspectRatio: 3 / 4,
          placeholderIcon: Icons.person_outline,
          placeholderLabel: 'Photo of\n${person.name}',
        ),
        const SizedBox(height: 20),
        Text(person.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          person.role,
          style: AppTheme.eyebrow(color: AppColors.gold),
        ),
        const SizedBox(height: 12),
        Text(person.bio, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Event row/card with date, time, location.
class EventCard extends StatelessWidget {
  final ChurchEvent event;
  const EventCard(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.date.toUpperCase(),
            style: AppTheme.eyebrow(color: AppColors.gold),
          ),
          const SizedBox(height: 12),
          Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          _MetaRow(icon: Icons.schedule, text: event.time),
          const SizedBox(height: 8),
          _MetaRow(icon: Icons.place_outlined, text: event.location),
          const SizedBox(height: 16),
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.inkSoft),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Sermon card with a 16:9 media/thumbnail area and a play affordance.
class SermonCard extends StatelessWidget {
  final Sermon sermon;
  const SermonCard(this.sermon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            PhotoFrame(
              imageUrl: null,
              aspectRatio: 16 / 9,
              placeholderIcon: Icons.play_circle_outline,
              placeholderLabel: sermon.series,
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.navyDeep,
                size: 38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          '${sermon.series.toUpperCase()}  •  ${sermon.date}',
          style: AppTheme.eyebrow(color: AppColors.gold),
        ),
        const SizedBox(height: 10),
        Text(sermon.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          sermon.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.mic_none, size: 16, color: AppColors.inkSoft),
            const SizedBox(width: 8),
            Text(
              sermon.speaker,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../config/church_settings.dart';
import 'async_value_widget.dart';

/// When a church meets, as a row of cards.
///
/// One widget because there were two, on the home page and on Plan a
/// Visit, and they had already drifted: only one of them handled a
/// church with no service times yet, and the other showed a heading with
/// blank space under it. Both painted the time in the raw accent colour,
/// which does not read.
///
/// Neither difference was a decision. They are what happens to a copied
/// widget, and a third copy would have been a third set of them.
class ServiceTimes extends StatelessWidget {
  final ChurchSettings settings;

  /// The heading above the cards. The home page says "Join Us"; the
  /// visit page, which is already about visiting, says what these are.
  final String heading;

  const ServiceTimes({super.key, required this.settings, required this.heading});

  @override
  Widget build(BuildContext context) {
    final services = settings.serviceTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        if (services.isEmpty)
          // Reads correctly for a church that has not filled these in
          // yet *and* for one that is between timetables. "Being
          // updated" implied there had been some, which is wrong on the
          // day a church signs up - and that is exactly the day it is
          // most likely to hand its address out.
          const EmptyState(
            icon: Icons.schedule_outlined,
            message: 'Service times are not listed yet. Get in touch and '
                'someone will tell you when they meet.',
          )
        else
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final service in services)
                SizedBox(
                  width: 260,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.day,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.time,
                            style: TextStyle(
                              // Not the raw accent. At 22px bold WCAG
                              // would allow 3:1, and the default palette
                              // manages 2.2 - so this fails even the
                              // relaxed bar for large text.
                              color: settings.colors.accentInk,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(service.label, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

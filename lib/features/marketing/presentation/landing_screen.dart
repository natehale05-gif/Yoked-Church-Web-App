import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';

/// The product's front door.
///
/// The app used to open on "Find your church" - a directory of other
/// people's churches, which is a strange first thing to show someone who
/// came to make one. A church that already exists is reached by its own
/// address now, so this page is free to do the job it should: say what
/// this is, and offer the two things a stranger might want.
///
/// Deliberately outside the app shell and unthemed by any church: there
/// is no church yet, so there is nothing to be themed as.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _ink = Color(0xFF14202B);
  static const _accent = Color(0xFFC79A3C);

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 48,
                  vertical: isMobile ? 40 : 72,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.church, color: _accent, size: 26),
                        const SizedBox(width: 10),
                        Text(
                          'Yoked',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 48 : 72),
                    Text(
                      'Everything your church\nneeds online.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.1,
                        fontSize: isMobile ? 38 : 60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        'A website, a member app, and the tools to run a Sunday - '
                        'sermons, events, giving, groups, kids check-in, rotas. '
                        'Set it up yourself in a few minutes. No code, nobody to call.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isMobile ? 16 : 19,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: [
                        // The label carries its own size and weight
                        // rather than `styleFrom(textStyle:)`.
                        //
                        // A ButtonStyle's textStyle *replaces* the
                        // theme's instead of merging with it, so one
                        // without a `fontFamily` silently falls back to
                        // a font this app does not bundle - and on a
                        // network that cannot reach Google's font CDN,
                        // that is a button with no words on it. A style
                        // on the `Text` merges, so the bundled family
                        // survives and there is nothing to remember.
                        FilledButton(
                          onPressed: () => context.go('/start'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _ink,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                          ),
                          child: const Text(
                            'Start your church site',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/choose-church'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          ),
                          child: const Text('Find your church', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Free while this is in the making. No card.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    SizedBox(height: isMobile ? 48 : 80),
                    const _WhatYouGet(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatYouGet extends StatelessWidget {
  const _WhatYouGet();

  /// Named for what a church recognises, not for what the code calls it.
  static const _items = <(IconData, String, String)>[
    (Icons.public, 'A public site', 'Service times, directions, sermons, events, giving.'),
    (Icons.phone_iphone, 'A member app', 'Groups, rotas, reading plans, prayer, giving history.'),
    (Icons.dashboard_customize, 'A staff dashboard', 'Check-in, attendance, forms, rooms, reports.'),
    (Icons.palette_outlined, 'Your branding', 'Your name, colours and logo everywhere, in minutes.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final (icon, title, body) in _items)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, minWidth: 240),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: LandingScreen._accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(body, style: const TextStyle(color: Colors.white60, fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/branding/document_branding.dart';
import '../core/config/settings_providers.dart';
import 'router.dart';
import 'theme.dart';

class YokedChurchApp extends ConsumerStatefulWidget {
  const YokedChurchApp({super.key});

  @override
  ConsumerState<YokedChurchApp> createState() => _YokedChurchAppState();
}

class _YokedChurchAppState extends ConsumerState<YokedChurchApp> {
  @override
  void initState() {
    super.initState();
    // The settings stream has usually not emitted yet, so this writes the
    // fallback and the listener below corrects it a beat later. Applying
    // it anyway rather than waiting: on a church that never loads - no
    // backend, a dropped request - the page would otherwise keep the
    // bundled defaults and say nothing at all.
    _apply();
  }

  void _apply() => applyDocumentBranding(DocumentBranding.of(ref.read(settingsProvider)));

  @override
  Widget build(BuildContext context) {
    // The church can change underneath us: switching churches re-points
    // every repository, and an admin editing the name or colours
    // re-themes every open session without a reload. The page's own
    // identity has to move with it.
    //
    // Selected on the branding rather than the whole settings document,
    // so an unrelated edit - a service time, a feature flag - does not
    // rewrite the DOM.
    ref.listen<DocumentBranding>(
      settingsProvider.select(DocumentBranding.of),
      (_, branding) => applyDocumentBranding(branding),
    );

    return MaterialApp.router(
      // The tab, via Flutter's own Title widget. Everything else the
      // page says about itself is in [applyDocumentBranding].
      title: ref.watch(settingsProvider).churchName,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(themeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

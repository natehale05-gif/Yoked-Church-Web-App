import 'package:flutter/material.dart';

import 'config/site_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const YokedChurchApp());
}

class YokedChurchApp extends StatelessWidget {
  const YokedChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: SiteConfig.churchName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
      // Keep on-screen text at a sensible, readable scale.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clamped = media.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: clamped),
          child: child!,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/app_shell.dart';
import 'state/site_controller.dart';
import 'theme/app_theme.dart';

class YokedApp extends StatelessWidget {
  const YokedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final config = site.config;

    return MaterialApp(
      title: config.churchName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromConfig(config),
      home: site.isLoaded
          ? const AppShell()
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

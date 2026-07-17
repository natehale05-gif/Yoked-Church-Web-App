import 'package:flutter/material.dart';

import 'config/church_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class YokedChurchApp extends StatelessWidget {
  const YokedChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: ChurchConfig.churchName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}

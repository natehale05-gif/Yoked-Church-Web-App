import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/church_config.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class YokedChurchApp extends StatelessWidget {
  final AuthProvider authProvider;

  YokedChurchApp({super.key, AuthProvider? authProvider}) : authProvider = authProvider ?? AuthProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp.router(
        title: ChurchConfig.churchName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: buildAppRouter(authProvider),
      ),
    );
  }
}

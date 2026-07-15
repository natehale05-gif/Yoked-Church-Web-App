import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';

/// Decides whether to show the admin login or the dashboard based on the
/// current session.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return auth.isSignedIn
        ? const AdminDashboardScreen()
        : const AdminLoginScreen();
  }
}

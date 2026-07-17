import 'package:flutter/material.dart';

import 'footer.dart';
import 'nav_bar.dart';

/// Wraps every page with the shared nav bar and footer so pages only
/// need to implement their own content.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            child,
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

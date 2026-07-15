import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'site_footer.dart';
import 'top_nav.dart';

/// Wraps every page: a scroll-aware sticky top nav layered over the content,
/// with the footer appended automatically. Every page begins with a dark hero
/// so the transparent-to-solid nav transition feels consistent site-wide.
class SiteScaffold extends StatefulWidget {
  final Widget child;

  const SiteScaffold({super.key, required this.child});

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 24;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.ivory,
      endDrawer: const NavDrawer(),
      body: Stack(
        children: [
          // Scrolling page content, ending with the shared footer.
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  widget.child,
                  const SiteFooter(),
                ],
              ),
            ),
          ),
          // Sticky navigation overlay.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopNav(
              scrolled: _scrolled,
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/tenant.dart';
import '../application/church_providers.dart';

/// Makes the data layer agree with the church named in the URL.
///
/// Once a church has an address, the URL is the authority on which
/// church the app is - and the URL can change without anyone going
/// through [chooseChurch]: the back button, a pasted link, a link from
/// one church's site to another's.
///
/// The dangerous version of this widget sets the provider and lets the
/// frame render anyway, which paints the *previous* church's content and
/// colours for one frame before correcting itself. On a cold deep link
/// that is not a flicker, it is the wrong church's home page. So this
/// holds the frame back until the two agree - a gate, not a race.
///
/// The cold-start case is handled earlier still, in `main()`, which
/// seeds the provider from the browser URL before the first frame. This
/// covers every navigation after that.
class ChurchScope extends ConsumerStatefulWidget {
  /// The church the URL names. Null on routes that have no church, which
  /// renders [child] untouched.
  final String? churchId;

  final Widget child;

  const ChurchScope({super.key, required this.churchId, required this.child});

  @override
  ConsumerState<ChurchScope> createState() => _ChurchScopeState();
}

class _ChurchScopeState extends ConsumerState<ChurchScope> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ChurchScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.churchId != widget.churchId) _sync();
  }

  /// Deferred to after the frame because this runs from `initState` and
  /// `didUpdateWidget`, both of which are inside a build pass - writing a
  /// provider there throws.
  void _sync() {
    final id = widget.churchId;
    if (id == null || id == ref.read(selectedChurchIdProvider)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedChurchIdProvider.notifier).state = id;
      ChurchPreference.write(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.churchId;
    final selected = ref.watch(selectedChurchIdProvider);

    // Holding the frame rather than showing the wrong church. One frame,
    // and only when the URL has moved to a church the data layer has not
    // caught up with yet.
    if (id != null && selected != id) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}

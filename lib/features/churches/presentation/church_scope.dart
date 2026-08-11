import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      // Deliberately not remembered here. A mistyped or dead address
      // would otherwise become the church this browser opens on every
      // time. [_missing] writes it once the directory confirms it is
      // real.
    });
  }

  /// Whether the directory has come back and positively does not have
  /// this church.
  ///
  /// A directory still loading is not an answer, and neither is one that
  /// failed to load - `valueOrNull` is null for both, and both mean "keep
  /// going". Answering "no such church" from a dropped request would take
  /// a church's entire site down over one bad connection.
  bool _missing(String id) {
    final known = ref.watch(churchesProvider).valueOrNull;
    if (known == null) return false;

    final exists = known.any((church) => church.id == id);
    if (exists) ChurchPreference.write(id);
    return !exists;
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
    if (id != null && _missing(id)) return ChurchNotFound(churchId: id);
    return widget.child;
  }
}

/// What a link to a church that is not there should say.
///
/// The alternative is what this replaced: the address bar reading
/// `/c/grace-chapel` while the page shows a different church's name,
/// service times and colours, because nothing under the church id
/// resolved and the settings fell back to the bundled defaults. Someone
/// following a stale link would read another church's Sunday times and
/// believe they were their own.
///
/// Deliberately plain. There is no church here, so there is no palette to
/// theme it with, and dressing it in the last church's colours would be
/// the same lie in a quieter voice.
class ChurchNotFound extends ConsumerWidget {
  final String churchId;

  const ChurchNotFound({super.key, required this.churchId});

  /// Leaves the church behind before leaving the page.
  ///
  /// Order matters and is not cosmetic. The router sends `/` to whichever
  /// church is selected, so navigating with this one still selected would
  /// redirect straight back to the address that has no church - a loop
  /// with a Back button that cannot escape it.
  ///
  /// The *stored* church is left alone: it holds whichever real church
  /// this browser last opened, and a bad link should not cost someone
  /// that.
  void _leave(BuildContext context, WidgetRef ref, String to) {
    ref.read(selectedChurchIdProvider.notifier).state = null;
    context.go(to);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.travel_explore, size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  'No church at this address',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nothing is set up at "$churchId". The link may have a typo '
                  'in it, or the church may have moved to a different address.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _leave(context, ref, '/choose-church'),
                      icon: const Icon(Icons.search),
                      label: const Text('Find your church'),
                    ),
                    OutlinedButton(
                      onPressed: () => _leave(context, ref, '/'),
                      child: const Text('What is this?'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

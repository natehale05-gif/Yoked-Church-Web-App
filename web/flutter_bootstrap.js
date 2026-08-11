// Replaces the default bootstrap so the loading screen in index.html can
// be taken down at the right moment.
//
// The two mustache tokens below are substituted at build time with the
// loader and the build config - see flutter_tools/lib/src/web/bootstrap.dart.
// Do not write either token anywhere else in this file, including in a
// comment: substitution is textual and does not care that it is inside
// one. Naming them in this sentence cost an afternoon the first time,
// because the expansion landed mid-comment and the syntax error it threw
// pointed at minified loader code with no connection to anything here.

{{flutter_js}}
{{flutter_build_config}}

// There is deliberately no service worker here.
//
// Not an oversight of writing a custom bootstrap, which was the first
// theory: the bootstrap Flutter generates does not register one either.
// Both were tested - a fresh browser profile against a real build ends
// with zero registrations and no request for `flutter_service_worker.js`
// on either. Passing `serviceWorkerSettings` does not change that; the
// loader now only refreshes a registration that already exists, and
// creates none, which is the deprecation Flutter's own generated code
// warns about having already arrived.
//
// So repeat visits ride on ordinary HTTP caching, which GitHub Pages
// does properly: `max-age` for the quiet case and ETags for the rest, so
// a second visit is conditional requests rather than megabytes.
//
// Registering the file by hand would work today and is not worth it. It
// means owning a deprecated artifact's lifecycle, and the failure it
// invites - a stale worker serving last week's build - is one where a
// member reads the wrong service time and turns up an hour late.

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    const splash = document.getElementById('loading');
    if (!splash) return;

    function dismiss() {
      splash.classList.add('done');
      // Belt and braces: if the transition never fires - reduced motion,
      // a backgrounded tab - the splash still has to go. It is fixed and
      // full-screen, so leaving it up would hide the whole app.
      splash.addEventListener('transitionend', () => splash.remove(), { once: true });
      setTimeout(() => splash.remove(), 1200);
    }

    const painted = () => document.querySelector('flt-glass-pane, flt-scene-host');

    // `runApp` resolves once the app is running, which is a beat before
    // the first frame is actually on screen. Taking the splash down then
    // shows a white flash in between - the exact thing it exists to
    // prevent - so it waits for the scene to exist.
    if (painted()) return dismiss();

    const watcher = new MutationObserver(() => {
      if (!painted()) return;
      watcher.disconnect();
      dismiss();
    });
    watcher.observe(document.body, { childList: true, subtree: true });

    // A splash stuck over a working app is worse than a splash that
    // leaves too early, so it always leaves.
    setTimeout(() => {
      watcher.disconnect();
      dismiss();
    }, 10000);
  },
});

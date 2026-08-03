{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Serve CanvasKit from the app's own bundled assets instead of the
    // gstatic.com CDN, so the site keeps working even if that CDN is
    // slow, blocked, or unreachable for a visitor.
    canvasKitBaseUrl: "canvaskit/",
  },
});

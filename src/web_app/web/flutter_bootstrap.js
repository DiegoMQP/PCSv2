{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Force local CanvasKit — avoids CDN failures on mobile
    canvasKitBaseUrl: "canvaskit/",
  },
  // Service worker disabled — causes stale-cache issues on mobile Chrome
});

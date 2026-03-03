{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Force local CanvasKit — avoids CDN load that fails on mobile networks
    canvasKitBaseUrl: "canvaskit/",
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});

{{flutter_js}}
{{flutter_build_config}}

(async () => {
  const loading = document.getElementById('loading');
  const errEl   = document.getElementById('load-err');

  try {
    await _flutter.loader.load({
      config: {
        // Use local CanvasKit — avoids CDN failures on mobile
        canvasKitBaseUrl: "canvaskit/",
      },
      onEntrypointLoaded: async (engineInitializer) => {
        const appRunner = await engineInitializer.initializeEngine();
        // Hide loading screen right before Flutter paints
        if (loading) loading.style.display = 'none';
        await appRunner.runApp();
      },
    });
  } catch (e) {
    console.error('Flutter failed to load:', e);
    if (errEl) errEl.style.display = 'block';
    const spinner = document.querySelector('#loading .spinner');
    if (spinner) spinner.style.display = 'none';
  }
})();

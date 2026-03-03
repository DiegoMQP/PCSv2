{{flutter_js}}
{{flutter_build_config}}

(async () => {
  const loading = document.getElementById('loading');
  const errEl   = document.getElementById('load-err');
  const spinner = document.querySelector('#loading .spinner');

  function showError(msg) {
    if (spinner) spinner.style.display = 'none';
    if (errEl) {
      if (msg) errEl.innerHTML = msg;
      errEl.style.display = 'block';
    }
  }

  // Safety timeout: if Flutter hasn't loaded in 25s, show error
  const timeout = setTimeout(() => {
    showError('Error al cargar (tiempo agotado).<br>Verifica tu conexión y recarga.');
  }, 25000);

  try {
    await _flutter.loader.load({
      config: {
        canvasKitBaseUrl: 'canvaskit/',
      },
      onEntrypointLoaded: async (engineInitializer) => {
        try {
          const appRunner = await engineInitializer.initializeEngine();
          clearTimeout(timeout);
          if (loading) loading.style.display = 'none';
          await appRunner.runApp();
        } catch (e) {
          clearTimeout(timeout);
          console.error('Engine init failed:', e);
          showError('Error al iniciar el motor gráfico.<br>Intenta recargar la página.');
        }
      },
    });
  } catch (e) {
    clearTimeout(timeout);
    console.error('Flutter loader failed:', e);
    showError('Error al cargar la aplicación.<br>Intenta recargar la página.');
  }
})();

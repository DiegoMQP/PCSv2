{{flutter_js}}
{{flutter_build_config}}

(async () => {
  const loading  = document.getElementById('loading');
  const errEl    = document.getElementById('load-err');
  const spinner  = document.getElementById('load-spinner');
  const statusEl = document.getElementById('load-status');

  function setStatus(msg) {
    if (statusEl) statusEl.textContent = msg;
    console.log('[PCS]', msg);
  }

  function showError(msg) {
    if (spinner) spinner.style.display = 'none';
    if (statusEl) statusEl.style.display = 'none';
    if (errEl) {
      errEl.innerHTML = msg || 'Error al cargar la aplicación.<br>Intenta recargar la página.';
      errEl.style.display = 'block';
    }
  }

  // Timeout: show error if Flutter hasn't rendered after 30s
  const timeout = setTimeout(() => {
    showError('Tiempo agotado al cargar.<br>Verifica tu conexión e intenta recargar.');
  }, 30000);

  setStatus('Cargando archivos...');

  try {
    await _flutter.loader.load({
      config: {
        canvasKitBaseUrl: 'canvaskit/',
      },
      onEntrypointLoaded: async (engineInitializer) => {
        setStatus('Iniciando motor gráfico...');
        try {
          const appRunner = await engineInitializer.initializeEngine();
          setStatus('Ejecutando aplicación...');
          clearTimeout(timeout);
          if (loading) loading.style.display = 'none';
          await appRunner.runApp();
        } catch (e) {
          clearTimeout(timeout);
          console.error('[PCS] Engine init failed:', e);
          showError('Error al iniciar motor gráfico.<br><small style="opacity:0.6">' + String(e).substring(0,120) + '</small>');
        }
      },
    });
  } catch (e) {
    clearTimeout(timeout);
    console.error('[PCS] Loader failed:', e);
    showError('Error al cargar la aplicación.<br><small style="opacity:0.6">' + String(e).substring(0,120) + '</small>');
  }
})();

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

  // Timeout: show error if Flutter hasn't rendered after 15s
  const timeout = setTimeout(() => {
    showError('Error al cargar.<br>Recarga la página o intenta con otra red.');
  }, 15000);

  setStatus('Cargando...');

  try {
    await _flutter.loader.load({
      onEntrypointLoaded: async (engineInitializer) => {
        setStatus('Iniciando...');
        try {
          const appRunner = await engineInitializer.initializeEngine();
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

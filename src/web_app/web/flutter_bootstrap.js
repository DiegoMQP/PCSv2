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
      errEl.innerHTML = (msg || 'Error al cargar la aplicación.<br>Intenta recargar la página.')
        + '<br><br><button onclick="location.reload()" style="background:#0A84FF;color:#fff;border:none;padding:10px 28px;border-radius:10px;font-size:14px;cursor:pointer;">Recargar</button>';
      errEl.style.display = 'block';
    }
  }

  // Unregister stale service workers on hard errors
  function clearSW() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then(regs => {
        for (const r of regs) r.unregister();
      });
    }
  }

  // Timeout: show error if Flutter hasn't rendered after 12s
  const timeout = setTimeout(() => {
    clearSW();
    showError('La aplicación tardó demasiado en cargar.<br>Presiona Recargar para intentar de nuevo.');
  }, 12000);

  setStatus('Cargando...');

  try {
    await _flutter.loader.load({
      config: {
        // Use locally bundled CanvasKit instead of Google CDN
        canvasKitBaseUrl: "canvaskit/",
      },
      onEntrypointLoaded: async (engineInitializer) => {
        setStatus('Iniciando...');
        try {
          const appRunner = await engineInitializer.initializeEngine({
            useColorEmoji: true,
          });
          clearTimeout(timeout);
          if (loading) loading.style.display = 'none';
          await appRunner.runApp();
        } catch (e) {
          clearTimeout(timeout);
          clearSW();
          console.error('[PCS] Engine init failed:', e);
          showError('Error al iniciar motor gráfico.<br><small style="opacity:0.6">' + String(e).substring(0,120) + '</small>');
        }
      },
    });
  } catch (e) {
    clearTimeout(timeout);
    clearSW();
    console.error('[PCS] Loader failed:', e);
    showError('Error al cargar la aplicación.<br><small style="opacity:0.6">' + String(e).substring(0,120) + '</small>');
  }
})();

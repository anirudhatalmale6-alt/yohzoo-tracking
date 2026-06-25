{extends file='page.tpl'}

{block name='page_title'}
  Yohzoo Repartidor
{/block}

{block name='page_content'}
<style>
  #driver-app { max-width: 480px; margin: 0 auto; padding: 10px; font-family: 'Lato', sans-serif; }
  .driver-login { text-align: center; padding: 40px 20px; }
  .driver-login h2 { font-size: 22px; color: #2d3748; margin: 0 0 8px; }
  .driver-login p { color: #718096; margin: 0 0 24px; font-size: 14px; }
  .driver-login input { width: 100%; max-width: 280px; padding: 14px; border: 2px solid #e2e8f0; border-radius: 10px; font-size: 18px; text-align: center; text-transform: uppercase; letter-spacing: 3px; outline: none; box-sizing: border-box; }
  .driver-login input:focus { border-color: #667eea; }
  .driver-login button { display: block; width: 100%; max-width: 280px; margin: 16px auto 0; padding: 14px; background: #667eea; color: #fff; border: none; border-radius: 10px; font-size: 16px; font-weight: 600; cursor: pointer; }
  .driver-error { color: #e53e3e; margin-top: 12px; font-size: 14px; }

  .driver-header { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 2px solid #e2e8f0; margin-bottom: 16px; }
  .driver-header h3 { margin: 0; font-size: 18px; color: #2d3748; }
  .driver-header .gps-status { font-size: 12px; padding: 4px 10px; border-radius: 12px; }
  .gps-on { background: #c6f6d5; color: #22543d; }
  .gps-off { background: #fed7d7; color: #742a2a; }

  .delivery-card { background: #f7fafc; border-radius: 12px; padding: 16px; margin-bottom: 12px; border: 1px solid #e2e8f0; }
  .delivery-card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
  .delivery-order { font-weight: 700; font-size: 16px; color: #2d3748; }
  .delivery-status-badge { font-size: 11px; padding: 3px 10px; border-radius: 10px; font-weight: 600; }
  .badge-assigned { background: #bee3f8; color: #2a4365; }
  .badge-picked_up { background: #fefcbf; color: #744210; }
  .badge-on_the_way { background: #c6f6d5; color: #22543d; }
  .badge-nearby { background: #fed7d7; color: #742a2a; }

  .delivery-info { font-size: 14px; color: #4a5568; margin: 4px 0; }
  .delivery-info strong { color: #2d3748; }

  .delivery-actions { display: flex; gap: 8px; margin-top: 12px; flex-wrap: wrap; }
  .delivery-actions button { flex: 1; min-width: 100px; padding: 10px 12px; border: none; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; transition: transform 0.1s; }
  .delivery-actions button:active { transform: scale(0.96); }
  .btn-pickup { background: #ecc94b; color: #744210; }
  .btn-onway { background: #48bb78; color: #fff; }
  .btn-nearby { background: #ed8936; color: #fff; }
  .btn-delivered { background: #667eea; color: #fff; }
  .btn-call { background: #e2e8f0; color: #2d3748; }
  .btn-navigate { background: #38b2ac; color: #fff; }

  .no-deliveries { text-align: center; padding: 40px 20px; color: #a0aec0; }
  .no-deliveries p { font-size: 48px; margin: 0 0 12px; }

  .driver-logout { display: block; width: 100%; padding: 12px; background: none; border: 2px solid #e2e8f0; border-radius: 10px; color: #718096; font-size: 14px; cursor: pointer; margin-top: 16px; }

  .delivery-products { margin: 8px 0; padding: 8px; background: #fff; border-radius: 8px; border: 1px solid #e2e8f0; }
  .delivery-product-item { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
  .delivery-product-item + .delivery-product-item { border-top: 1px solid #edf2f7; padding-top: 6px; }
  .product-thumb { width: 40px; height: 40px; border-radius: 6px; object-fit: cover; flex-shrink: 0; }
  .product-detail { display: flex; flex-direction: column; min-width: 0; }
  .product-pname { font-size: 13px; color: #2d3748; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .product-pqty { font-size: 12px; color: #718096; }
  .delivery-total { font-size: 15px; margin-top: 6px; padding-top: 6px; border-top: 1px solid #e2e8f0; }

  #driver-live-map { height: 200px; border-radius: 12px; margin-bottom: 16px; border: 1px solid #e2e8f0; display: none; }
  .map-label { font-size: 12px; color: #718096; text-align: center; margin: -8px 0 12px; }

  .driver-tabs { display: flex; gap: 0; margin-bottom: 16px; border-radius: 10px; overflow: hidden; border: 2px solid #e2e8f0; }
  .driver-tab { flex: 1; padding: 10px 8px; text-align: center; font-size: 13px; font-weight: 600; cursor: pointer; background: #f7fafc; color: #718096; border: none; transition: all 0.2s; }
  .driver-tab.active { background: #667eea; color: #fff; }
  .history-card { background: #f7fafc; border-radius: 12px; padding: 14px; margin-bottom: 10px; border: 1px solid #e2e8f0; }
  .history-card .delivery-order { font-weight: 700; font-size: 15px; color: #2d3748; }
  .history-card .history-date { font-size: 12px; color: #a0aec0; }
  .history-card .delivery-info { font-size: 13px; color: #4a5568; margin: 3px 0; }
</style>

<div id="driver-app">

  <div id="driver-login-screen" class="driver-login">
    <h2>Yohzoo Repartidor</h2>
    <p>Ingresa tu codigo de acceso</p>
    <input type="text" id="driver-code" placeholder="CODIGO" maxlength="10">
    <button id="driver-login-btn">Ingresar</button>
    <div id="driver-login-error" class="driver-error" style="display:none;"></div>
  </div>

  <div id="driver-dashboard" style="display:none;">
    <div class="driver-header">
      <h3 id="driver-welcome"></h3>
      <span class="gps-status gps-off" id="gps-status">GPS OFF</span>
    </div>

    <div id="driver-live-map"></div>
    <p class="map-label" id="map-label" style="display:none;">Tu ubicacion en tiempo real</p>
    <div id="bg-warning" style="display:none;background:#fefcbf;border:1px solid #ecc94b;border-radius:8px;padding:8px 12px;margin-bottom:10px;font-size:12px;color:#744210;text-align:center;">Manten esta pantalla abierta para GPS continuo. No minimices el navegador.</div>
    <p id="gps-last-sent" style="display:none;font-size:11px;color:#48bb78;text-align:center;margin:-6px 0 10px;">Ultima actualizacion: --</p>
    <p id="gps-coords" style="display:none;font-size:11px;color:#718096;text-align:center;margin:-6px 0 10px;"></p>

    <div class="driver-tabs">
      <button class="driver-tab active" id="tab-active" onclick="switchTab('active')">Activos</button>
      <button class="driver-tab" id="tab-delivered" onclick="switchTab('delivered')">Entregados</button>
      <button class="driver-tab" id="tab-cancelled" onclick="switchTab('cancelled')">Cancelados</button>
    </div>

    <div id="deliveries-list"></div>
    <div id="history-list" style="display:none;"></div>

    <button class="driver-logout" id="driver-logout-btn">Cerrar sesion</button>
  </div>

</div>

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
var YOHZOO_AJAX_URL = '{$ajax_url nofilter}';
</script>
<script>
{literal}
(function() {
  var AJAX_URL = YOHZOO_AJAX_URL;
  var driverData = null;
  var gpsWatchId = null;
  var locationInterval = null;
  var gpsWatchdog = null;
  var lastLat = null, lastLng = null, lastAccuracy = null;
  var driverMap = null, driverMapMarker = null, driverMapReady = false;
  var lastSendTime = 0;
  var lastGPSTime = 0;
  var gpsSendCount = 0;
  var wakeLock = null;
  var audioCtx = null;
  var audioKeepAlive = null;

  function requestWakeLock() {
    if (!('wakeLock' in navigator)) return;
    navigator.wakeLock.request('screen').then(function(wl) {
      wakeLock = wl;
      wakeLock.addEventListener('release', function() {
        wakeLock = null;
        if (driverData) requestWakeLock();
      });
    }).catch(function() {});
  }

  function startAudioKeepAlive() {
    if (audioCtx) return;
    try {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      var oscillator = audioCtx.createOscillator();
      var gain = audioCtx.createGain();
      gain.gain.value = 0.001;
      oscillator.frequency.value = 1;
      oscillator.connect(gain);
      gain.connect(audioCtx.destination);
      oscillator.start();
      audioKeepAlive = oscillator;
    } catch(e) {}
  }

  function stopAudioKeepAlive() {
    if (audioKeepAlive) {
      try { audioKeepAlive.stop(); } catch(e) {}
      audioKeepAlive = null;
    }
    if (audioCtx) {
      try { audioCtx.close(); } catch(e) {}
      audioCtx = null;
    }
  }

  var loginScreen = document.getElementById('driver-login-screen');
  var dashboard = document.getElementById('driver-dashboard');

  document.getElementById('driver-login-btn').addEventListener('click', doLogin);
  document.getElementById('driver-code').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') doLogin();
  });
  document.getElementById('driver-logout-btn').addEventListener('click', doLogout);

  var saved = sessionStorage.getItem('yohzoo_driver');
  if (saved) {
    try {
      driverData = JSON.parse(saved);
      showDashboard();
    } catch(e) {}
  }

  function doLogin() {
    var code = document.getElementById('driver-code').value.trim();
    if (!code) return;

    fetch(AJAX_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'action=login&code=' + encodeURIComponent(code) + '&_t=' + Date.now()
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (!data.success) {
          document.getElementById('driver-login-error').textContent = data.error;
          document.getElementById('driver-login-error').style.display = 'block';
          return;
        }
        driverData = data.driver;
        sessionStorage.setItem('yohzoo_driver', JSON.stringify(driverData));
        showDashboard();
      })
      .catch(function() {
        document.getElementById('driver-login-error').textContent = 'Error de conexion';
        document.getElementById('driver-login-error').style.display = 'block';
      });
  }

  function doLogout() {
    driverData = null;
    sessionStorage.removeItem('yohzoo_driver');
    stopGPS();
    if (gpsWatchdog) { clearInterval(gpsWatchdog); gpsWatchdog = null; }
    if (wakeLock) { wakeLock.release(); wakeLock = null; }
    stopAudioKeepAlive();
    loginScreen.style.display = 'block';
    dashboard.style.display = 'none';
  }

  var deliveryInterval = null;

  function showDashboard() {
    loginScreen.style.display = 'none';
    dashboard.style.display = 'block';
    document.getElementById('driver-welcome').textContent = 'Hola, ' + driverData.name;
    document.getElementById('bg-warning').style.display = 'block';
    requestWakeLock();
    startAudioKeepAlive();
    startGPS();
    loadDeliveries();
    deliveryInterval = setInterval(loadDeliveries, 12000);
  }

  document.addEventListener('visibilitychange', function() {
    if (!document.hidden && driverData) {
      requestWakeLock();
      if (audioCtx && audioCtx.state === 'suspended') {
        audioCtx.resume().catch(function(){});
      }
      stopGPS();
      startGPS();
      sendLocation();
      loadDeliveries();
      if (deliveryInterval) clearInterval(deliveryInterval);
      deliveryInterval = setInterval(loadDeliveries, 12000);
    }
  });

  var prevSentLat = null, prevSentLng = null;

  function onGPSPosition(pos) {
    var newLat = pos.coords.latitude;
    var newLng = pos.coords.longitude;
    lastAccuracy = pos.coords.accuracy;
    lastGPSTime = Date.now();

    var moved = lastLat !== null && (Math.abs(newLat - lastLat) > 0.00003 || Math.abs(newLng - lastLng) > 0.00003);
    lastLat = newLat;
    lastLng = newLng;

    updateGPSStatus(true);
    updateDriverMap(lastLat, lastLng);

    var coordEl = document.getElementById('gps-coords');
    if (coordEl) {
      coordEl.style.display = 'block';
      coordEl.textContent = lastLat.toFixed(6) + ', ' + lastLng.toFixed(6) + ' (acc: ' + lastAccuracy.toFixed(0) + 'm)' + (moved ? ' MOVIDO' : '');
      coordEl.style.color = moved ? '#48bb78' : '#718096';
    }

    sendLocation();
  }

  function startGPS() {
    if (!navigator.geolocation) {
      updateGPSStatus(false);
      return;
    }

    gpsWatchId = navigator.geolocation.watchPosition(
      onGPSPosition,
      function() { updateGPSStatus(false); },
      { enableHighAccuracy: true, maximumAge: 0, timeout: 15000 }
    );

    locationInterval = setInterval(function() {
      navigator.geolocation.getCurrentPosition(
        onGPSPosition,
        function() {},
        { enableHighAccuracy: true, maximumAge: 0, timeout: 10000 }
      );
    }, 10000);

    if (gpsWatchdog) clearInterval(gpsWatchdog);
    gpsWatchdog = setInterval(function() {
      var elapsed = Date.now() - lastGPSTime;
      if (elapsed > 30000 && driverData) {
        var el = document.getElementById('gps-last-sent');
        if (el) {
          el.style.display = 'block';
          el.textContent = 'GPS detenido - reiniciando...';
          el.style.color = '#e53e3e';
        }
        stopGPS();
        startGPS();
        requestWakeLock();
      }
    }, 15000);
  }

  function stopGPS() {
    if (gpsWatchId !== null) {
      navigator.geolocation.clearWatch(gpsWatchId);
      gpsWatchId = null;
    }
    if (locationInterval) {
      clearInterval(locationInterval);
      locationInterval = null;
    }
  }

  function sendLocation() {
    if (!lastLat || !driverData) return;
    var now = Date.now();
    if (now - lastSendTime < 8000) return;
    lastSendTime = now;

    var params = 'action=updateLocation&driver_id=' + driverData.id
      + '&token=' + encodeURIComponent(driverData.token)
      + '&lat=' + lastLat + '&lng=' + lastLng + '&accuracy=' + lastAccuracy
      + '&_t=' + Date.now();

    fetch(AJAX_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params
    }).then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) {
        gpsSendCount++;
        var el = document.getElementById('gps-last-sent');
        if (el) {
          el.style.display = 'block';
          el.textContent = 'GPS enviado: ' + new Date().toLocaleTimeString('es-PE') + ' (#' + gpsSendCount + ')';
          el.style.color = '#48bb78';
        }
      }
    }).catch(function() {
      var el = document.getElementById('gps-last-sent');
      if (el) {
        el.style.display = 'block';
        el.textContent = 'Error enviando GPS - reintentando...';
        el.style.color = '#e53e3e';
      }
    });
  }

  function updateGPSStatus(on) {
    var el = document.getElementById('gps-status');
    el.className = 'gps-status ' + (on ? 'gps-on' : 'gps-off');
    el.textContent = on ? 'GPS ON' : 'GPS OFF';
  }

  function loadDeliveries() {
    if (!driverData) return;

    fetch(AJAX_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'action=getDeliveries&driver_id=' + driverData.id + '&token=' + encodeURIComponent(driverData.token) + '&_t=' + Date.now()
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (data.success) renderDeliveries(data.deliveries);
      })
      .catch(function() {});
  }

  function renderDeliveries(deliveries) {
    var container = document.getElementById('deliveries-list');

    if (!deliveries.length) {
      container.innerHTML = '<div class="no-deliveries"><p>&#128230;</p>No tienes entregas asignadas</div>';
      return;
    }

    var html = '';
    deliveries.forEach(function(d) {
      html += '<div class="delivery-card">'
        + '<div class="delivery-card-header">'
        + '<span class="delivery-order">#' + esc(d.order_reference) + '</span>'
        + '<span class="delivery-status-badge badge-' + d.status + '">' + esc(d.status_label) + '</span>'
        + '</div>'
        + '<p class="delivery-info"><strong>Cliente:</strong> ' + esc(d.customer_name) + '</p>';

      if (d.phone) {
        html += '<p class="delivery-info"><strong>Telefono:</strong> <a href="tel:' + esc(d.phone) + '" style="color:#667eea;text-decoration:none;">' + esc(d.phone) + '</a></p>';
      }

      html += '<p class="delivery-info"><strong>Direccion:</strong> ' + (d.district ? esc(d.district) + ', ' : '') + esc(d.address) + (d.address2 ? ', ' + esc(d.address2) : '') + ', ' + esc(d.city) + '</p>';

      if (d.payment_method) {
        html += '<p class="delivery-info"><strong>Pago:</strong> ' + esc(d.payment_method) + '</p>';
      }

      if (d.products && d.products.length) {
        html += '<div class="delivery-products">';
        d.products.forEach(function(p) {
          html += '<div class="delivery-product-item">';
          if (p.image) {
            html += '<img src="' + esc(p.image) + '" alt="' + esc(p.name) + '" class="product-thumb">';
          }
          html += '<div class="product-detail">'
            + '<span class="product-pname">' + esc(p.name) + '</span>'
            + '<span class="product-pqty">x' + p.quantity + ' - ' + esc(p.price) + '</span>'
            + '</div></div>';
        });
        html += '</div>';
      }

      html += '<p class="delivery-info delivery-total"><strong>Total:</strong> ' + esc(d.total) + '</p>';

      if (d.estimated_minutes) {
        html += '<p class="delivery-info"><strong>Tiempo est.:</strong> ~' + d.estimated_minutes + ' min</p>';
      }

      html += '<div class="delivery-actions">';

      if (d.phone) {
        html += '<button class="btn-call" onclick="window.location.href=\'tel:' + esc(d.phone) + '\'">Llamar</button>';
        var addr = encodeURIComponent(d.address + (d.district ? ', ' + d.district : '') + ', ' + d.city + ', Peru');
        html += '<button class="btn-navigate" onclick="window.open(\'https://www.google.com/maps/dir/?api=1&destination=' + addr + '\')">Navegar</button>';
      }

      if (d.status === 'assigned' || d.status === 'ready') {
        html += '<button class="btn-pickup" onclick="updateDeliveryStatus(' + d.id_delivery + ', \'picked_up\')">Recoger</button>';
      }
      if (d.status === 'picked_up') {
        html += '<button class="btn-onway" onclick="updateDeliveryStatus(' + d.id_delivery + ', \'on_the_way\')">En camino</button>';
      }
      if (d.status === 'on_the_way') {
        html += '<button class="btn-nearby" onclick="updateDeliveryStatus(' + d.id_delivery + ', \'nearby\')">Estoy cerca</button>';
      }
      if (d.status === 'on_the_way' || d.status === 'nearby') {
        html += '<button class="btn-delivered" onclick="updateDeliveryStatus(' + d.id_delivery + ', \'delivered\')">Entregado</button>';
      }

      html += '</div></div>';
    });

    container.innerHTML = html;
  }

  window.updateDeliveryStatus = function(idDelivery, status) {
    if (status === 'delivered' && !confirm('Confirmar entrega?')) return;

    sendLocation();

    var params = 'action=updateStatus&driver_id=' + driverData.id
      + '&token=' + encodeURIComponent(driverData.token)
      + '&id_delivery=' + idDelivery + '&status=' + status
      + '&_t=' + Date.now();

    fetch(AJAX_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (data.success) {
          loadDeliveries();
        } else {
          alert(data.error || 'Error');
        }
      })
      .catch(function() { alert('Error de conexion'); });
  };

  function updateDriverMap(lat, lng) {
    var mapEl = document.getElementById('driver-live-map');
    var labelEl = document.getElementById('map-label');
    if (!driverMapReady) {
      mapEl.style.display = 'block';
      labelEl.style.display = 'block';
      driverMap = L.map('driver-live-map').setView([lat, lng], 15);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OSM'
      }).addTo(driverMap);
      var icon = L.divIcon({
        className: '',
        html: '<div style="background:#667eea;color:#fff;width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:18px;box-shadow:0 2px 8px rgba(0,0,0,0.3);border:3px solid #fff;">&#128666;</div>',
        iconSize: [36, 36],
        iconAnchor: [18, 18]
      });
      driverMapMarker = L.marker([lat, lng], { icon: icon }).addTo(driverMap);
      driverMapReady = true;
    } else {
      driverMapMarker.setLatLng([lat, lng]);
      driverMap.panTo([lat, lng]);
    }
  }

  function esc(str) {
    if (!str) return '';
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  window.switchTab = function(tab) {
    document.querySelectorAll('.driver-tab').forEach(function(t) { t.classList.remove('active'); });
    document.getElementById('tab-' + tab).classList.add('active');

    if (tab === 'active') {
      document.getElementById('deliveries-list').style.display = 'block';
      document.getElementById('history-list').style.display = 'none';
      loadDeliveries();
    } else {
      document.getElementById('deliveries-list').style.display = 'none';
      document.getElementById('history-list').style.display = 'block';
      loadHistory(tab);
    }
  };

  function loadHistory(filter) {
    if (!driverData) return;
    var container = document.getElementById('history-list');
    container.innerHTML = '<div class="no-deliveries"><p>Cargando...</p></div>';

    fetch(AJAX_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'action=getHistory&driver_id=' + driverData.id + '&token=' + encodeURIComponent(driverData.token) + '&filter=' + filter + '&_t=' + Date.now()
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (!data.success || !data.deliveries.length) {
          container.innerHTML = '<div class="no-deliveries"><p>' + (filter === 'delivered' ? '&#9989;' : '&#10060;') + '</p>No hay pedidos ' + (filter === 'delivered' ? 'entregados' : 'cancelados') + '</div>';
          return;
        }
        var html = '';
        data.deliveries.forEach(function(d) {
          html += '<div class="history-card">'
            + '<div class="delivery-card-header">'
            + '<span class="delivery-order">#' + esc(d.order_reference) + '</span>'
            + '<span class="history-date">' + esc(d.date) + '</span>'
            + '</div>'
            + '<p class="delivery-info"><strong>Cliente:</strong> ' + esc(d.customer_name) + '</p>'
            + '<p class="delivery-info"><strong>Direccion:</strong> ' + (d.district ? esc(d.district) + ', ' : '') + esc(d.address) + ', ' + esc(d.city) + '</p>'
            + '<p class="delivery-info"><strong>Pago:</strong> ' + esc(d.payment_method) + '</p>'
            + '<p class="delivery-info delivery-total"><strong>Total:</strong> ' + esc(d.total) + '</p>'
            + '</div>';
        });
        container.innerHTML = html;
      })
      .catch(function() {
        container.innerHTML = '<div class="no-deliveries"><p>Error de conexion</p></div>';
      });
  }
})();
{/literal}
</script>
{/block}

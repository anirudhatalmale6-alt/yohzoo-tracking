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

  #driver-live-map { height: 200px; border-radius: 12px; margin-bottom: 16px; border: 1px solid #e2e8f0; display: none; }
  .map-label { font-size: 12px; color: #718096; text-align: center; margin: -8px 0 12px; }
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

    <div id="deliveries-list"></div>

    <button class="driver-logout" id="driver-logout-btn">Cerrar sesion</button>
  </div>

</div>

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
(function() {
  var AJAX_URL = '{$ajax_url nofilter}';
  var driverData = null;
  var gpsWatchId = null;
  var locationInterval = null;
  var lastLat = null, lastLng = null, lastAccuracy = null;
  var driverMap = null, driverMapMarker = null, driverMapReady = false;
  var lastSendTime = 0;

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

    fetch(AJAX_URL + '?action=login&code=' + encodeURIComponent(code) + '&_t=' + Date.now())
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
    loginScreen.style.display = 'block';
    dashboard.style.display = 'none';
  }

  function showDashboard() {
    loginScreen.style.display = 'none';
    dashboard.style.display = 'block';
    document.getElementById('driver-welcome').textContent = 'Hola, ' + driverData.name;
    startGPS();
    loadDeliveries();
    setInterval(loadDeliveries, 15000);
  }

  function startGPS() {
    if (!navigator.geolocation) {
      updateGPSStatus(false);
      return;
    }

    gpsWatchId = navigator.geolocation.watchPosition(
      function(pos) {
        lastLat = pos.coords.latitude;
        lastLng = pos.coords.longitude;
        lastAccuracy = pos.coords.accuracy;
        updateGPSStatus(true);
        updateDriverMap(lastLat, lastLng);
        sendLocation();
      },
      function() { updateGPSStatus(false); },
      { enableHighAccuracy: true, maximumAge: 5000 }
    );

    locationInterval = setInterval(sendLocation, 10000);
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
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params
    }).catch(function() {});
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
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
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
        + '<p class="delivery-info"><strong>Cliente:</strong> ' + esc(d.customer_name) + '</p>'
        + '<p class="delivery-info"><strong>Direccion:</strong> ' + esc(d.address) + (d.address2 ? ', ' + esc(d.address2) : '') + ', ' + esc(d.city) + '</p>'
        + '<p class="delivery-info"><strong>Total:</strong> ' + esc(d.total) + '</p>';

      if (d.estimated_minutes) {
        html += '<p class="delivery-info"><strong>Tiempo est.:</strong> ~' + d.estimated_minutes + ' min</p>';
      }

      html += '<div class="delivery-actions">';

      if (d.phone) {
        html += '<button class="btn-call" onclick="window.location.href=\'tel:' + esc(d.phone) + '\'">Llamar</button>';
        var addr = encodeURIComponent(d.address + ', ' + d.city + ', Peru');
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
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params
    })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (data.success) {
          if (data.whatsapp_url) {
            window.open(data.whatsapp_url, '_blank');
          }
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
})();
</script>
{/block}

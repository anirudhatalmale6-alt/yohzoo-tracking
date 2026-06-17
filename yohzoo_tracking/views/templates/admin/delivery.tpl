<div class="row">
  <div class="col-lg-3 col-md-6">
    <div class="panel" style="text-align:center;padding:20px;">
      <h2 style="margin:0;font-size:36px;color:#667eea;" id="stat-active">{$stats.active}</h2>
      <p style="margin:4px 0 0;color:#718096;">Entregas activas</p>
    </div>
  </div>
  <div class="col-lg-3 col-md-6">
    <div class="panel" style="text-align:center;padding:20px;">
      <h2 style="margin:0;font-size:36px;color:#48bb78;" id="stat-delivered">{$stats.delivered_today}</h2>
      <p style="margin:4px 0 0;color:#718096;">Entregadas hoy</p>
    </div>
  </div>
  <div class="col-lg-3 col-md-6">
    <div class="panel" style="text-align:center;padding:20px;">
      <h2 style="margin:0;font-size:36px;color:#ed8936;" id="stat-total">{$stats.total_today}</h2>
      <p style="margin:4px 0 0;color:#718096;">Total hoy</p>
    </div>
  </div>
  <div class="col-lg-3 col-md-6">
    <div class="panel" style="text-align:center;padding:20px;">
      <p style="margin:0 0 8px;color:#718096;font-size:12px;">Links rapidos</p>
      <a href="{$tracking_url}" target="_blank" class="btn btn-default btn-sm" style="margin:2px;">Tracking Page</a>
      <a href="{$driver_app_url}" target="_blank" class="btn btn-default btn-sm" style="margin:2px;">Driver App</a>
    </div>
  </div>
</div>

<ul class="nav nav-tabs" style="margin-bottom:20px;">
  <li class="{if $view == 'deliveries'}active{/if}"><a href="{$admin_link}&view=deliveries">Entregas</a></li>
  <li class="{if $view == 'drivers'}active{/if}"><a href="{$admin_link}&view=drivers">Repartidores</a></li>
  <li class="{if $view == 'map'}active{/if}"><a href="{$admin_link}&view=map">Mapa en vivo</a></li>
</ul>

{if $view == 'deliveries'}
<div class="panel">
  <div class="panel-heading">
    <span><i class="icon-truck"></i> Entregas</span>
    <span class="panel-heading-action">
      <span id="auto-refresh-indicator" style="font-size:11px;color:#a0aec0;margin-right:10px;"></span>
      <button class="btn btn-primary btn-sm" onclick="document.getElementById('new-delivery-form').style.display='block';">
        <i class="icon-plus"></i> Nueva entrega
      </button>
    </span>
  </div>

  <div id="new-delivery-form" style="display:none;padding:15px;background:#f7fafc;border-bottom:1px solid #e2e8f0;">
    <div class="form-inline">
      <label>ID Pedido: </label>
      <input type="number" id="new-order-id" class="form-control" placeholder="Ej: 12345" style="width:150px;margin:0 10px;">
      <button class="btn btn-success btn-sm" onclick="createDelivery()">Crear entrega</button>
      <button class="btn btn-default btn-sm" onclick="document.getElementById('new-delivery-form').style.display='none';">Cancelar</button>
    </div>
  </div>

  <div style="padding:10px 15px;border-bottom:1px solid #e2e8f0;background:#f7fafc;">
    <div class="btn-group" role="group">
      <button type="button" class="btn btn-sm btn-primary delivery-filter-btn" data-filter="active" id="filter-btn-active">
        <i class="icon-refresh"></i> Activos <span class="badge" id="badge-active" style="background:#fff;color:#667eea;">{$stats.active}</span>
      </button>
      <button type="button" class="btn btn-sm btn-default delivery-filter-btn" data-filter="delivered" id="filter-btn-delivered">
        <i class="icon-ok"></i> Entregados
      </button>
      <button type="button" class="btn btn-sm btn-default delivery-filter-btn" data-filter="cancelled" id="filter-btn-cancelled">
        <i class="icon-remove"></i> Cancelados
      </button>
    </div>
  </div>

  <div class="table-responsive">
    <table class="table table-striped" id="deliveries-table">
      <thead>
        <tr>
          <th>Codigo</th>
          <th>Pedido</th>
          <th>Cliente</th>
          <th>Direccion</th>
          <th>Repartidor</th>
          <th>Estado</th>
          <th>Fecha</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody id="deliveries-tbody">
      </tbody>
    </table>
    <p id="deliveries-empty" style="display:none;text-align:center;padding:30px;color:#a0aec0;font-size:14px;">No hay entregas en esta categoria</p>
  </div>
</div>

{elseif $view == 'drivers'}
<div class="panel">
  <div class="panel-heading">
    <span><i class="icon-user"></i> Repartidores</span>
    <span class="panel-heading-action">
      <button class="btn btn-primary btn-sm" onclick="document.getElementById('new-driver-form').style.display='block';">
        <i class="icon-plus"></i> Nuevo repartidor
      </button>
    </span>
  </div>

  <div id="new-driver-form" style="display:none;padding:15px;background:#f7fafc;border-bottom:1px solid #e2e8f0;">
    <div class="form-inline">
      <label>Nombre: </label>
      <input type="text" id="new-driver-name" class="form-control" placeholder="Nombre" style="width:150px;margin:0 5px;">
      <label>Telefono: </label>
      <input type="text" id="new-driver-phone" class="form-control" placeholder="987654321" style="width:130px;margin:0 5px;">
      <button class="btn btn-success btn-sm" onclick="createDriver()">Crear</button>
      <button class="btn btn-default btn-sm" onclick="document.getElementById('new-driver-form').style.display='none';">Cancelar</button>
    </div>
  </div>

  <div class="table-responsive">
    <table class="table table-striped">
      <thead>
        <tr>
          <th>Nombre</th>
          <th>Telefono</th>
          <th>Codigo de acceso</th>
          <th>Link app</th>
          <th>Estado</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody>
        {foreach $drivers as $dr}
        <tr>
          <td><strong>{$dr.name}</strong></td>
          <td>{$dr.phone}</td>
          <td><code style="font-size:16px;letter-spacing:2px;">{$dr.access_code}</code></td>
          <td>
            <a href="{$driver_app_url}" target="_blank" class="btn btn-xs btn-info">Abrir app</a>
          </td>
          <td>{if $dr.active}<span class="label label-success">Activo</span>{else}<span class="label label-danger">Inactivo</span>{/if}</td>
          <td>
            {if $dr.active}
              <button class="btn btn-xs btn-danger" onclick="if(confirm('Desactivar repartidor?')) deleteDriver({$dr.id_driver})">
                <i class="icon-trash"></i>
              </button>
            {/if}
          </td>
        </tr>
        {/foreach}
      </tbody>
    </table>
  </div>
</div>

{elseif $view == 'map'}
<div class="panel">
  <div class="panel-heading"><i class="icon-map-marker"></i> Mapa en vivo</div>
  <div class="panel-body">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <div id="admin-live-map" style="height:500px;border-radius:8px;"></div>
    <p id="map-last-refresh" style="font-size:12px;color:#a0aec0;text-align:center;margin-top:8px;">Actualizando...</p>
  </div>
</div>
{/if}

<script>
var adminLink = '{$admin_link nofilter}';
var trackingUrl = '{$tracking_url nofilter}';
var orderAdminToken = '{$order_admin_token nofilter}';
var waMsgTemplate = '{$wa_msg_template|escape:"javascript" nofilter}';
var waMsgDelivered = '{$wa_msg_delivered|escape:"javascript" nofilter}';
var driversData = {$drivers_json nofilter};
var statusesList = {$statuses_json nofilter};
</script>
<script>
{literal}
var currentFilter = 'active';
var deliveryRefreshInterval = null;

function esc(str) {
  if (!str) return '';
  var d = document.createElement('div');
  d.textContent = str;
  return d.innerHTML;
}

function formatPhone(phone) {
  if (!phone) return '';
  return phone.replace(/[^0-9]/g, '');
}

function buildWaUrl(phone, message) {
  var p = formatPhone(phone);
  if (!p) return '';
  if (p.charAt(0) !== '5') p = '51' + p;
  return 'https://wa.me/' + p + '?text=' + encodeURIComponent(message);
}

function renderDeliveryRow(d) {
  var phone = d.customer_phone || d.phone_mobile || '';
  var driverOptions = '<option value="">-- Asignar --</option>';
  driversData.forEach(function(dr) {
    var sel = (d.id_driver == dr.id_driver) ? ' selected' : '';
    driverOptions += '<option value="' + dr.id_driver + '"' + sel + '>' + esc(dr.name) + '</option>';
  });

  var statusOptions = '';
  statusesList.forEach(function(s) {
    var sel = (d.status === s) ? ' selected' : '';
    statusOptions += '<option value="' + s + '"' + sel + '>' + s + '</option>';
  });

  var waTrackingMsg = waMsgTemplate
    .replace('{customer_name}', d.customer_firstname || '')
    .replace('{tracking_code}', d.tracking_code || '')
    .replace('{tracking_url}', trackingUrl + '?code=' + (d.tracking_code || ''));
  var waDeliveredMsg = waMsgDelivered
    .replace('{customer_name}', d.customer_firstname || '')
    .replace('{tracking_code}', d.tracking_code || '');

  var actions = '';
  if (phone) {
    var waTrackUrl = buildWaUrl(phone, waTrackingMsg);
    var waDelUrl = buildWaUrl(phone, waDeliveredMsg);
    actions += '<a href="' + waTrackUrl + '" target="_blank" class="btn btn-xs btn-success" title="Enviar tracking por WhatsApp"><i class="icon-comment"></i> WA</a> ';
    actions += '<a href="' + waDelUrl + '" target="_blank" class="btn btn-xs btn-warning" title="Enviar mensaje de entrega por WhatsApp"><i class="icon-ok"></i> WA</a> ';
  }
  actions += '<a href="' + trackingUrl + '?code=' + esc(d.tracking_code) + '" target="_blank" class="btn btn-xs btn-info" title="Ver tracking"><i class="icon-eye-open"></i></a> ';
  actions += '<button class="btn btn-xs btn-danger" onclick="deleteDelivery(' + d.id_delivery + ', \'' + esc(d.tracking_code) + '\')" title="Eliminar"><i class="icon-trash"></i></button>';

  var dateStr = '';
  if (d.status === 'delivered' && d.date_delivered) {
    dateStr = d.date_delivered.substring(5, 16).replace('-', '/');
  } else {
    dateStr = (d.date_add || '').substring(5, 16).replace('-', '/');
  }

  var addr = '';
  if (d.state_name) addr += esc(d.state_name) + '<br>';
  addr += esc(d.address1);
  if (d.address2) addr += '<br>' + esc(d.address2);

  return '<tr>'
    + '<td><strong>' + esc(d.tracking_code) + '</strong></td>'
    + '<td><a href="index.php?controller=AdminOrders&id_order=' + d.id_order + '&vieworder&token=' + orderAdminToken + '" target="_blank">#' + esc(d.order_reference) + '</a></td>'
    + '<td>' + esc(d.customer_name) + '</td>'
    + '<td><small>' + addr + '</small></td>'
    + '<td><select class="form-control input-sm" id="driver-select-' + d.id_delivery + '" style="width:130px;">' + driverOptions + '</select>'
    + ' <button class="btn btn-xs btn-primary" onclick="assignDriver(' + d.id_delivery + ')">OK</button></td>'
    + '<td><select class="form-control input-sm" onchange="updateStatus(' + d.id_delivery + ', this.value)" style="width:130px;">' + statusOptions + '</select></td>'
    + '<td><small>' + dateStr + '</small></td>'
    + '<td>' + actions + '</td>'
    + '</tr>';
}

function loadDeliveryList(filter, showLoading) {
  if (showLoading) {
    document.getElementById('deliveries-tbody').innerHTML = '<tr><td colspan="8" style="text-align:center;padding:20px;color:#a0aec0;">Cargando...</td></tr>';
  }

  fetch(adminLink + '&action=getDeliveryList&filter=' + filter + '&ajax=1&_t=' + Date.now())
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (!data.success) return;

      var tbody = document.getElementById('deliveries-tbody');
      var emptyEl = document.getElementById('deliveries-empty');

      if (!data.deliveries.length) {
        tbody.innerHTML = '';
        emptyEl.style.display = 'block';
      } else {
        emptyEl.style.display = 'none';
        var html = '';
        data.deliveries.forEach(function(d) {
          html += renderDeliveryRow(d);
        });
        tbody.innerHTML = html;
      }

      if (data.stats) {
        var sa = document.getElementById('stat-active');
        var sd = document.getElementById('stat-delivered');
        var st = document.getElementById('stat-total');
        var ba = document.getElementById('badge-active');
        if (sa) sa.textContent = data.stats.active;
        if (sd) sd.textContent = data.stats.delivered_today;
        if (st) st.textContent = data.stats.total_today;
        if (ba) ba.textContent = data.stats.active;
      }

      var indicator = document.getElementById('auto-refresh-indicator');
      if (indicator) {
        indicator.textContent = 'Actualizado: ' + new Date().toLocaleTimeString('es-PE');
        indicator.style.color = '#48bb78';
        setTimeout(function() { indicator.style.color = '#a0aec0'; }, 2000);
      }
    })
    .catch(function() {});
}

function switchDeliveryFilter(filter) {
  currentFilter = filter;
  document.querySelectorAll('.delivery-filter-btn').forEach(function(btn) {
    btn.className = 'btn btn-sm ' + (btn.getAttribute('data-filter') === filter ? 'btn-primary' : 'btn-default') + ' delivery-filter-btn';
  });
  loadDeliveryList(filter, true);
}

function startDeliveryRefresh() {
  if (deliveryRefreshInterval) clearInterval(deliveryRefreshInterval);
  deliveryRefreshInterval = setInterval(function() {
    if (document.hidden) return;
    loadDeliveryList(currentFilter, false);
  }, 15000);
}

document.addEventListener('DOMContentLoaded', function() {
  var filterBtns = document.querySelectorAll('.delivery-filter-btn');
  if (filterBtns.length) {
    filterBtns.forEach(function(btn) {
      btn.addEventListener('click', function() {
        switchDeliveryFilter(this.getAttribute('data-filter'));
      });
    });
    loadDeliveryList('active', true);
    startDeliveryRefresh();
  }
});

document.addEventListener('visibilitychange', function() {
  if (!document.hidden && document.getElementById('deliveries-table')) {
    loadDeliveryList(currentFilter, false);
    startDeliveryRefresh();
  }
});

function createDelivery() {
  var orderId = document.getElementById('new-order-id').value;
  if (!orderId) return alert('Ingresa el ID del pedido');

  fetch(adminLink + '&action=createDelivery&id_order=' + orderId + '&ajax=1')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) {
        alert('Entrega creada! Codigo: ' + data.tracking_code);
        document.getElementById('new-order-id').value = '';
        document.getElementById('new-delivery-form').style.display = 'none';
        loadDeliveryList(currentFilter, false);
      } else {
        alert(data.error);
      }
    });
}

function assignDriver(idDelivery) {
  var select = document.getElementById('driver-select-' + idDelivery);
  var idDriver = select.value;
  if (!idDriver) return alert('Selecciona un repartidor');

  var minutes = prompt('Tiempo estimado de entrega (minutos):', '30');

  fetch(adminLink + '&action=assignDriver&id_delivery=' + idDelivery + '&id_driver=' + idDriver + '&estimated_minutes=' + (minutes || 0) + '&ajax=1')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) {
        if (data.whatsapp_url && confirm('Repartidor asignado! Enviar WhatsApp al cliente?')) {
          window.open(data.whatsapp_url, '_blank');
        }
        loadDeliveryList(currentFilter, false);
      } else {
        alert(data.error);
      }
    });
}

function updateStatus(idDelivery, status) {
  fetch(adminLink + '&action=updateStatus&id_delivery=' + idDelivery + '&status=' + status + '&ajax=1')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) {
        loadDeliveryList(currentFilter, false);
      } else {
        alert(data.error);
      }
    });
}

function createDriver() {
  var name = document.getElementById('new-driver-name').value.trim();
  var phone = document.getElementById('new-driver-phone').value.trim();
  if (!name || !phone) return alert('Completa todos los campos');

  fetch(adminLink + '&action=createDriver&driver_name=' + encodeURIComponent(name) + '&driver_phone=' + encodeURIComponent(phone) + '&ajax=1')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) {
        alert('Repartidor creado!\nCodigo de acceso: ' + data.driver.access_code + '\n\nComparte este codigo con el repartidor para que acceda a la app.');
        location.reload();
      } else {
        alert(data.error);
      }
    });
}

function deleteDelivery(idDelivery, trackingCode) {
  if (!confirm('Eliminar entrega ' + trackingCode + '? Esta accion no se puede deshacer.')) return;

  fetch(adminLink + '&action=deleteDelivery&id_delivery=' + idDelivery + '&ajax=1')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) loadDeliveryList(currentFilter, false);
      else alert(data.error);
    });
}

function deleteDriver(idDriver) {
  fetch(adminLink + '&action=deleteDriver&id_driver=' + idDriver + '&ajax=1')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) location.reload();
      else alert(data.error);
    });
}
{/literal}

{if $view == 'map'}
{literal}
document.addEventListener('DOMContentLoaded', function() {
  var map = L.map('admin-live-map').setView([-12.046, -77.043], 12);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap'
  }).addTo(map);

  var markers = {};

  function refreshMap() {
    fetch(adminLink + '&action=getMapData&ajax=1&_t=' + Date.now())
      .then(function(r) { return r.json(); })
      .then(function(data) {
        if (!data.success) return;
        data.deliveries.forEach(function(d) {
          if (!d.latitude) return;
          var key = d.id_delivery;
          var latlng = [parseFloat(d.latitude), parseFloat(d.longitude)];
          if (markers[key]) {
            markers[key].setLatLng(latlng);
          } else {
            var icon = L.divIcon({
              className: '',
              html: '<div style="background:#667eea;color:#fff;padding:4px 8px;border-radius:6px;font-size:12px;font-weight:bold;white-space:nowrap;box-shadow:0 2px 6px rgba(0,0,0,0.3);">' + (d.driver_name || '#' + d.tracking_code) + '</div>',
              iconAnchor: [40, 12]
            });
            markers[key] = L.marker(latlng, { icon: icon }).addTo(map);
            markers[key].bindPopup('<b>#' + d.tracking_code + '</b><br>' + (d.driver_name || '') + '<br>Estado: ' + d.status + '<br>GPS: ' + (d.location_time || 'N/A'));
          }
        });
        var el = document.getElementById('map-last-refresh');
        if (el) {
          el.textContent = 'Actualizado: ' + new Date().toLocaleTimeString('es-PE') + ' (' + data.deliveries.length + ' activos)';
          el.style.color = '#48bb78';
          setTimeout(function() { el.style.color = '#a0aec0'; }, 2000);
        }
      }).catch(function() {});
  }

  refreshMap();
  var mapInterval = setInterval(refreshMap, 10000);

  document.addEventListener('visibilitychange', function() {
    if (!document.hidden) {
      refreshMap();
      clearInterval(mapInterval);
      mapInterval = setInterval(refreshMap, 10000);
    }
  });
});
{/literal}
{/if}
</script>

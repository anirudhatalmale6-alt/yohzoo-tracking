<div class="row">
  <div class="col-lg-3 col-md-6">
    <div class="panel" style="text-align:center;padding:20px;">
      <h2 style="margin:0;font-size:36px;color:#667eea;">{$stats.active}</h2>
      <p style="margin:4px 0 0;color:#718096;">Entregas activas</p>
    </div>
  </div>
  <div class="col-lg-3 col-md-6">
    <div class="panel" style="text-align:center;padding:20px;">
      <h2 style="margin:0;font-size:36px;color:#48bb78;">{$stats.delivered_today}</h2>
      <p style="margin:4px 0 0;color:#718096;">Entregadas hoy</p>
    </div>
  </div>
  <div class="col-lg-3 col-md-6">
    <div class="panel" style="text-align:center;padding:20px;">
      <h2 style="margin:0;font-size:36px;color:#ed8936;">{$stats.total_today}</h2>
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

  <div class="table-responsive">
    <table class="table table-striped">
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
      <tbody>
        {foreach $deliveries as $d}
        <tr>
          <td><strong>{$d.tracking_code}</strong></td>
          <td><a href="index.php?controller=AdminOrders&id_order={$d.id_order}&vieworder&token={Tools::getAdminTokenLite('AdminOrders')}" target="_blank">#{$d.order_reference}</a></td>
          <td>{$d.customer_name}</td>
          <td>
            <small>
              {if $d.state_name}{$d.state_name}<br>{/if}
              {$d.address1}
              {if $d.address2}<br>{$d.address2}{/if}
            </small>
          </td>
          <td>
              <select class="form-control input-sm" id="driver-select-{$d.id_delivery}" style="width:130px;">
                <option value="">-- Asignar --</option>
                {foreach $drivers as $dr}
                  <option value="{$dr.id_driver}" {if $d.id_driver == $dr.id_driver}selected{/if}>{$dr.name}</option>
                {/foreach}
              </select>
              <button class="btn btn-xs btn-primary" onclick="assignDriver({$d.id_delivery})">OK</button>
          </td>
          <td>
            <select class="form-control input-sm" onchange="updateStatus({$d.id_delivery}, this.value)" style="width:130px;">
              {foreach $statuses as $s}
                <option value="{$s}" {if $d.status == $s}selected{/if}>{$s}</option>
              {/foreach}
            </select>
          </td>
          <td><small>{$d.date_add|date_format:"%d/%m %H:%M"}</small></td>
          <td>
            {if $d.customer_phone || $d.phone_mobile}
              {assign var="cphone" value=$d.customer_phone|default:$d.phone_mobile}
              <a href="https://wa.me/51{$cphone|regex_replace:'/[^0-9]/':''}?text={('Tu pedido #'|cat:$d.tracking_code|cat:' de Yohzoo esta en camino! Rastrealo aqui: '|cat:$tracking_url|cat:'?code='|cat:$d.tracking_code)|urlencode}" target="_blank" class="btn btn-xs btn-success" title="WhatsApp">
                <i class="icon-comment"></i> WA
              </a>
            {/if}
            <a href="{$tracking_url}?code={$d.tracking_code}" target="_blank" class="btn btn-xs btn-info" title="Ver tracking">
              <i class="icon-eye-open"></i>
            </a>
            <button class="btn btn-xs btn-danger" onclick="deleteDelivery({$d.id_delivery}, '{$d.tracking_code}')" title="Eliminar">
              <i class="icon-trash"></i>
            </button>
          </td>
        </tr>
        {/foreach}
      </tbody>
    </table>
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
  </div>
</div>
{/if}

<script>
var adminLink = '{$admin_link nofilter}';

function createDelivery() {
  var orderId = document.getElementById('new-order-id').value;
  if (!orderId) return alert('Ingresa el ID del pedido');

  fetch(adminLink + '&action=createDelivery&id_order=' + orderId + '&ajax=1')
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.success) {
        alert('Entrega creada! Codigo: ' + data.tracking_code);
        location.reload();
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
        location.reload();
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
        if (data.whatsapp_url && confirm('Entrega marcada como entregada! Enviar WhatsApp al cliente?')) {
          window.open(data.whatsapp_url, '_blank');
        }
        if (status === 'delivered') location.reload();
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
      if (data.success) location.reload();
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

{if $view == 'map'}
document.addEventListener('DOMContentLoaded', function() {
  var map = L.map('admin-live-map').setView([-12.046, -77.043], 12);
  L.tileLayer('https://{ldelim}s{rdelim}.tile.openstreetmap.org/{ldelim}z{rdelim}/{ldelim}x{rdelim}/{ldelim}y{rdelim}.png', {
    attribution: '&copy; OpenStreetMap'
  }).addTo(map);

  var markers = {};

  function refreshMap() {
    fetch(adminLink + '&action=getMapData&ajax=1')
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
            markers[key].bindPopup('<b>#' + d.tracking_code + '</b><br>' + (d.driver_name || '') + '<br>Estado: ' + d.status);
          }
        });
      }).catch(function() {});
  }

  refreshMap();
  setInterval(refreshMap, 10000);
});
{/if}
</script>

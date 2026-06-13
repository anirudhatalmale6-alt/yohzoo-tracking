<div class="panel">
  <div class="panel-heading">
    <i class="icon-truck"></i> Delivery Tracking
  </div>
  <div class="panel-body">
    {if $delivery}
      <div class="row">
        <div class="col-md-6">
          <p><strong>Codigo:</strong> {$delivery.tracking_code}</p>
          <p><strong>Estado:</strong> {$delivery.status}</p>
          {if $delivery.driver_name}
            <p><strong>Repartidor:</strong> {$delivery.driver_name} ({$delivery.driver_phone})</p>
          {/if}
          {if $delivery.date_delivered}
            <p><strong>Entregado:</strong> {$delivery.date_delivered|date_format:"%d/%m/%Y %H:%M"}</p>
          {/if}
        </div>
        <div class="col-md-6">
          <a href="{$tracking_url}?code={$delivery.tracking_code}" target="_blank" class="btn btn-info btn-sm">
            <i class="icon-eye-open"></i> Ver tracking
          </a>
          <a href="{$module_link}&view=deliveries" target="_blank" class="btn btn-default btn-sm">
            <i class="icon-cog"></i> Gestionar
          </a>
        </div>
      </div>
    {else}
      <p>No hay entrega creada para este pedido.</p>
      <button class="btn btn-primary btn-sm" onclick="createDeliveryFromOrder({$id_order}, '{$order_reference}')">
        <i class="icon-plus"></i> Crear entrega
      </button>
      <script>
      function createDeliveryFromOrder(orderId, ref) {
        fetch('{$module_link nofilter}&action=createDelivery&id_order=' + orderId + '&ajax=1')
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
      </script>
    {/if}
  </div>
</div>

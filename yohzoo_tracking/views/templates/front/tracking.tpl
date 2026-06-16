{extends file='page.tpl'}

{block name='page_title'}
  Seguir tu Pedido
{/block}

{block name='head'}
  {$smarty.block.parent}
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
  <link rel="stylesheet" href="{$urls.base_url}modules/yohzoo_tracking/views/css/tracking.css?v=4">
{/block}

{block name='page_content'}
<div id="yohzoo-tracking-app">

  <div id="tracking-search" class="tracking-section">
    <div class="tracking-search-box">
      <h2>Rastrea tu pedido en tiempo real</h2>
      <p>Ingresa el codigo de tu pedido para ver el estado de tu entrega</p>
      <form id="tracking-form" onsubmit="return false;">
        <div class="tracking-input-group">
          <input type="text" id="tracking-code-input" placeholder="Ej: ABCDEFGH" value="{$tracking_code|escape:'html'}" autocomplete="off" maxlength="32">
          <button type="submit" id="tracking-submit-btn">
            <span class="btn-text">Buscar</span>
            <span class="btn-loading" style="display:none;">Buscando...</span>
          </button>
        </div>
        <div id="tracking-error" class="tracking-error" style="display:none;"></div>
      </form>
    </div>
  </div>

  <div id="tracking-result" style="display:none;">

    <div class="tracking-status-header">
      <div class="status-icon-large" id="status-icon"></div>
      <div class="status-info">
        <h3 id="status-label"></h3>
        <p class="tracking-code-display">Pedido: <strong id="display-tracking-code"></strong></p>
        <p class="eta-display" id="eta-display" style="display:none;"></p>
      </div>
    </div>

    <div class="tracking-progress">
      <div class="progress-bar">
        <div class="progress-fill" id="progress-fill"></div>
      </div>
      <div class="progress-steps" id="progress-steps">
        <div class="step" data-step="0">
          <div class="step-dot"></div>
          <span>Preparando</span>
        </div>
        <div class="step" data-step="1">
          <div class="step-dot"></div>
          <span>Listo</span>
        </div>
        <div class="step" data-step="2">
          <div class="step-dot"></div>
          <span>Asignado</span>
        </div>
        <div class="step" data-step="3">
          <div class="step-dot"></div>
          <span>Recogido</span>
        </div>
        <div class="step" data-step="4">
          <div class="step-dot"></div>
          <span>En camino</span>
        </div>
        <div class="step" data-step="5">
          <div class="step-dot"></div>
          <span>Entregado</span>
        </div>
      </div>
    </div>

    <div class="tracking-map-container" id="tracking-map-container" style="display:none;">
      <h4>Ubicacion del repartidor</h4>
      <div id="tracking-map"></div>
      <p class="map-updated" id="map-updated"></p>
    </div>

    <div class="tracking-details">
      <div class="tracking-col">
        <div class="tracking-driver" id="tracking-driver" style="display:none;">
          <h4>Tu repartidor</h4>
          <div class="driver-info">
            <div class="driver-avatar">&#128666;</div>
            <div>
              <p class="driver-name" id="driver-name"></p>
              <p class="driver-phone" id="driver-phone" style="display:none;margin:4px 0 0;font-size:14px;"></p>
            </div>
          </div>
        </div>

        <div class="tracking-timeline">
          <h4>Historial</h4>
          <div id="timeline-list" class="timeline-list"></div>
        </div>
      </div>

      <div class="tracking-col">
        <div class="tracking-products">
          <h4>Tu pedido</h4>
          <div id="products-list" class="products-list"></div>
        </div>
      </div>
    </div>

  </div>

</div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
var yohzooTrackingConfig = {
  ajaxUrl: '{$ajax_url nofilter}',
  refreshInterval: 10000
};
</script>
<script src="{$urls.base_url}modules/yohzoo_tracking/views/js/tracking.js?v=4"></script>
{/block}

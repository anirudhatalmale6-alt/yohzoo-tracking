document.addEventListener('DOMContentLoaded', function() {
  var config = window.yohzooTrackingConfig;
  var map = null;
  var driverMarker = null;
  var refreshTimer = null;

  var form = document.getElementById('tracking-form');
  var input = document.getElementById('tracking-code-input');
  var submitBtn = document.getElementById('tracking-submit-btn');
  var errorEl = document.getElementById('tracking-error');
  var resultEl = document.getElementById('tracking-result');

  form.addEventListener('submit', function(e) {
    e.preventDefault();
    doSearch();
  });

  submitBtn.addEventListener('click', function() {
    doSearch();
  });

  if (input.value.trim()) {
    doSearch();
  }

  function doSearch() {
    var code = input.value.trim();
    if (!code) {
      showError('Ingresa tu codigo de seguimiento');
      return;
    }

    submitBtn.querySelector('.btn-text').style.display = 'none';
    submitBtn.querySelector('.btn-loading').style.display = 'inline';
    submitBtn.disabled = true;
    hideError();

    fetch(config.ajaxUrl, {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'action=getStatus&code=' + encodeURIComponent(code) + '&_t=' + Date.now()
      })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        submitBtn.querySelector('.btn-text').style.display = 'inline';
        submitBtn.querySelector('.btn-loading').style.display = 'none';
        submitBtn.disabled = false;

        if (!data.success) {
          showError(data.error);
          resultEl.style.display = 'none';
          stopRefresh();
          return;
        }

        renderResult(data);
        startRefresh(code);
      })
      .catch(function() {
        submitBtn.querySelector('.btn-text').style.display = 'inline';
        submitBtn.querySelector('.btn-loading').style.display = 'none';
        submitBtn.disabled = false;
        showError('Error de conexion. Intenta nuevamente.');
      });
  }

  function renderResult(data) {
    resultEl.style.display = 'block';

    document.getElementById('status-icon').textContent = data.status_icon;
    document.getElementById('status-label').textContent = data.status_label;
    document.getElementById('display-tracking-code').textContent = data.tracking_code;

    var etaEl = document.getElementById('eta-display');
    if (data.estimated_minutes && data.estimated_minutes > 0 && data.status !== 'delivered') {
      etaEl.textContent = 'Tiempo estimado: ~' + data.estimated_minutes + ' minutos';
      etaEl.style.display = 'block';
    } else if (data.driver_location && data.status !== 'delivered') {
      calculateClientETA(data.driver_location, etaEl);
    } else {
      etaEl.style.display = 'none';
    }

    var steps = document.querySelectorAll('#progress-steps .step');
    var fillPct = (data.current_step / (data.total_steps - 1)) * 100;
    document.getElementById('progress-fill').style.width = fillPct + '%';

    steps.forEach(function(step, i) {
      step.classList.remove('active', 'completed');
      if (i < data.current_step) {
        step.classList.add('completed');
      } else if (i === data.current_step) {
        step.classList.add('active');
      }
    });

    var driverEl = document.getElementById('tracking-driver');
    if (data.driver) {
      driverEl.style.display = 'block';
      var driverInfo = data.driver.name;
      document.getElementById('driver-name').textContent = driverInfo;
      var phoneEl = document.getElementById('driver-phone');
      if (phoneEl && data.driver.phone) {
        phoneEl.innerHTML = '<a href="tel:' + escapeHtml(data.driver.phone) + '" style="color:#667eea;text-decoration:none;">&#128222; ' + escapeHtml(data.driver.phone) + '</a>';
        phoneEl.style.display = 'block';
      }
    } else {
      driverEl.style.display = 'none';
    }

    var mapContainer = document.getElementById('tracking-map-container');
    if (data.driver_location) {
      mapContainer.style.display = 'block';
      renderMap(data.driver_location);
    } else {
      mapContainer.style.display = 'none';
    }

    renderTimeline(data.timeline);
    renderProducts(data.products, data.order_total);
  }

  function renderMap(location) {
    if (!map) {
      map = L.map('tracking-map').setView([location.lat, location.lng], 15);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap'
      }).addTo(map);
    }

    if (driverMarker) {
      driverMarker.setLatLng([location.lat, location.lng]);
    } else {
      var icon = L.divIcon({
        className: 'driver-map-marker',
        html: '<div style="background:#667eea;color:#fff;width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:18px;box-shadow:0 2px 8px rgba(0,0,0,0.3);border:3px solid #fff;">&#128666;</div>',
        iconSize: [36, 36],
        iconAnchor: [18, 18]
      });
      driverMarker = L.marker([location.lat, location.lng], {icon: icon}).addTo(map);
    }

    map.panTo([location.lat, location.lng]);

    var updatedEl = document.getElementById('map-updated');
    updatedEl.textContent = 'Actualizado: ' + new Date().toLocaleTimeString('es-PE');
  }

  function renderTimeline(timeline) {
    var container = document.getElementById('timeline-list');
    if (!timeline || !timeline.length) {
      container.innerHTML = '<p style="color:#a0aec0;font-size:14px;">Sin actualizaciones aun</p>';
      return;
    }

    var html = '';
    timeline.forEach(function(item) {
      html += '<div class="timeline-item">'
        + '<div class="timeline-icon">' + item.icon + '</div>'
        + '<div class="timeline-content">'
        + '<p class="timeline-status">' + escapeHtml(item.status) + '</p>'
        + (item.message ? '<p class="timeline-message">' + escapeHtml(item.message) + '</p>' : '')
        + '<p class="timeline-date">' + escapeHtml(item.date) + '</p>'
        + '</div></div>';
    });
    container.innerHTML = html;
  }

  function renderProducts(products, orderTotal) {
    var container = document.getElementById('products-list');
    if (!products || !products.length) {
      container.innerHTML = '<p style="color:#a0aec0;font-size:14px;">Sin productos</p>';
      return;
    }

    var html = '';
    products.forEach(function(p) {
      html += '<div class="product-item">';
      if (p.image) {
        html += '<img src="' + escapeHtml(p.image) + '" alt="' + escapeHtml(p.name) + '">';
      }
      html += '<div><p class="product-name">' + escapeHtml(p.name) + '</p>'
        + '<p class="product-qty">Cantidad: ' + p.quantity + '</p>';
      if (p.price) {
        html += '<p class="product-qty" style="color:#2d3748;font-weight:600;">' + escapeHtml(p.price) + '</p>';
      }
      html += '</div></div>';
    });
    if (orderTotal) {
      html += '<div style="text-align:right;padding:10px 0;border-top:2px solid #e2e8f0;margin-top:8px;">'
        + '<strong style="font-size:16px;color:#2d3748;">Total: ' + escapeHtml(orderTotal) + '</strong></div>';
    }
    container.innerHTML = html;
  }

  function startRefresh(code) {
    stopRefresh();
    refreshTimer = setInterval(function() {
      fetch(config.ajaxUrl, {
          method: 'POST',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'action=getStatus&code=' + encodeURIComponent(code) + '&_t=' + Date.now()
        })
        .then(function(r) { return r.json(); })
        .then(function(data) {
          if (data.success) {
            renderResult(data);
            if (data.status === 'delivered' || data.status === 'cancelled') {
              stopRefresh();
            }
          }
        })
        .catch(function() {});
    }, config.refreshInterval);
  }

  function stopRefresh() {
    if (refreshTimer) {
      clearInterval(refreshTimer);
      refreshTimer = null;
    }
  }

  function showError(msg) {
    errorEl.textContent = msg;
    errorEl.style.display = 'block';
  }

  function hideError() {
    errorEl.style.display = 'none';
  }

  function calculateClientETA(driverLoc, etaEl) {
    if (!navigator.geolocation) {
      etaEl.style.display = 'none';
      return;
    }

    navigator.geolocation.getCurrentPosition(function(pos) {
      var custLat = pos.coords.latitude;
      var custLng = pos.coords.longitude;
      var distKm = haversine(driverLoc.lat, driverLoc.lng, custLat, custLng);
      var avgSpeed = 20;
      var etaMin = Math.ceil((distKm / avgSpeed) * 60);
      if (etaMin < 1) etaMin = 1;
      if (etaMin > 180) etaMin = 180;
      etaEl.textContent = 'Tiempo estimado: ~' + etaMin + ' minutos';
      etaEl.style.display = 'block';
    }, function() {
      etaEl.style.display = 'none';
    }, { timeout: 5000 });
  }

  function haversine(lat1, lon1, lat2, lon2) {
    var R = 6371;
    var dLat = (lat2 - lat1) * Math.PI / 180;
    var dLon = (lon2 - lon1) * Math.PI / 180;
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  }

  function escapeHtml(str) {
    if (!str) return '';
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
});

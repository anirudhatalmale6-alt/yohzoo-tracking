<?php

class Yohzoo_TrackingTrackingModuleFrontController extends ModuleFrontController
{
    public function initContent()
    {
        parent::initContent();

        $action = Tools::getValue('action');

        if ($action === 'getStatus') {
            $this->ajaxGetStatus();
            return;
        }

        $trackingCode = Tools::getValue('code', '');

        $this->context->smarty->assign([
            'tracking_code' => $trackingCode,
            'ajax_url' => $this->context->link->getModuleLink('yohzoo_tracking', 'tracking'),
        ]);

        $this->setTemplate('module:yohzoo_tracking/views/templates/front/tracking.tpl');
    }

    private function ajaxGetStatus()
    {
        header('Content-Type: application/json');

        try {
            $code = trim(Tools::getValue('code', ''));
            if (empty($code)) {
                die(json_encode(['success' => false, 'error' => 'Ingresa tu codigo de seguimiento']));
            }

            $code = pSQL(strtoupper($code));

            $delivery = Db::getInstance()->getRow(
                'SELECT d.*, dr.name as driver_name, dr.phone as driver_phone
                 FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
                 LEFT JOIN `' . _DB_PREFIX_ . 'yohzoo_driver` dr ON d.id_driver = dr.id_driver
                 WHERE d.tracking_code = "' . $code . '"'
            );

            if (!$delivery) {
                die(json_encode(['success' => false, 'error' => 'Codigo de seguimiento no encontrado']));
            }

            $order = new Order((int) $delivery['id_order']);
            if (!Validate::isLoadedObject($order)) {
                die(json_encode(['success' => false, 'error' => 'Pedido no encontrado']));
            }

            $address = new Address((int) $order->id_address_delivery);

            $logs = Db::getInstance()->executeS(
                'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_tracking_log`
                 WHERE id_delivery = ' . (int) $delivery['id_delivery'] . '
                 ORDER BY date_add DESC LIMIT 20'
            );
            if (!$logs) {
                $logs = [];
            }

            $driverLocation = null;
            if ($delivery['id_driver'] && in_array($delivery['status'], ['picked_up', 'on_the_way', 'nearby'])) {
                try {
                    $driverLocation = Db::getInstance()->getRow(
                        'SELECT `latitude`, `longitude`, `accuracy`, `date_add`
                         FROM `' . _DB_PREFIX_ . 'yohzoo_driver_location`
                         WHERE `id_driver` = ' . (int) $delivery['id_driver'] . '
                         ORDER BY `date_add` DESC LIMIT 1'
                    );
                } catch (\Exception $e) {
                    $driverLocation = null;
                }
            }

            $productList = [];
            try {
                $products = $order->getProducts();
                if ($products) {
                    foreach ($products as $p) {
                        $imgUrl = '';
                        try {
                            $imgUrl = $this->getProductImageUrl($p);
                        } catch (\Exception $e) {
                            $imgUrl = '';
                        }
                        $productList[] = [
                            'name' => $p['product_name'] ?? 'Producto',
                            'quantity' => (int) ($p['product_quantity'] ?? 1),
                            'image' => $imgUrl,
                        ];
                    }
                }
            } catch (\Exception $e) {
                $productList = [];
            }

            $statusSteps = ['preparing', 'ready', 'assigned', 'picked_up', 'on_the_way', 'delivered'];
            $statusMap = ['nearby' => 'on_the_way'];
            $mappedStatus = $statusMap[$delivery['status']] ?? $delivery['status'];
            $currentStep = array_search($mappedStatus, $statusSteps);
            if ($currentStep === false) {
                $currentStep = 0;
            }

            $timeline = [];
            foreach ($logs as $log) {
                $timeline[] = [
                    'status' => Yohzoo_Tracking::getStatusLabel($log['status']),
                    'icon' => Yohzoo_Tracking::getStatusIcon($log['status']),
                    'message' => $log['message'] ?? '',
                    'date' => date('d/m H:i', strtotime($log['date_add'])),
                ];
            }

            $response = [
                'success' => true,
                'tracking_code' => $delivery['tracking_code'],
                'status' => $delivery['status'],
                'status_label' => Yohzoo_Tracking::getStatusLabel($delivery['status']),
                'status_icon' => Yohzoo_Tracking::getStatusIcon($delivery['status']),
                'current_step' => $currentStep,
                'total_steps' => count($statusSteps),
                'estimated_minutes' => $this->calculateETA($delivery, $driverLocation, $address),
                'driver' => $delivery['id_driver'] ? [
                    'name' => $delivery['driver_name'] ?? '',
                ] : null,
                'delivery_address' => [
                    'city' => $address->city ?? '',
                    'district' => $address->address2 ?: '',
                ],
                'products' => $productList,
                'timeline' => $timeline,
                'driver_location' => $driverLocation ? [
                    'lat' => (float) $driverLocation['latitude'],
                    'lng' => (float) $driverLocation['longitude'],
                    'updated' => $driverLocation['date_add'],
                ] : null,
            ];

            die(json_encode($response));
        } catch (\Exception $e) {
            die(json_encode(['success' => false, 'error' => 'Error: ' . $e->getMessage()]));
        }
    }

    private function calculateETA($delivery, $driverLocation, $address)
    {
        $manual = (int) ($delivery['estimated_minutes'] ?? 0);
        if ($manual > 0) {
            return $manual;
        }

        if (!$driverLocation || !in_array($delivery['status'], ['picked_up', 'on_the_way', 'nearby'])) {
            return null;
        }

        $driverLat = (float) $driverLocation['latitude'];
        $driverLng = (float) $driverLocation['longitude'];

        if ($driverLat == 0 || $driverLng == 0) {
            return null;
        }

        $destLat = null;
        $destLng = null;

        try {
            $fullAddress = trim(($address->address1 ?? '') . ', ' . ($address->city ?? '') . ', Peru');
            $cacheKey = 'yohzoo_geo_' . md5($fullAddress);
            $cached = Configuration::get($cacheKey);

            if ($cached) {
                $coords = explode(',', $cached);
                if (count($coords) === 2) {
                    $destLat = (float) $coords[0];
                    $destLng = (float) $coords[1];
                }
            }

            if (!$destLat) {
                $url = 'https://nominatim.openstreetmap.org/search?format=json&limit=1&q=' . urlencode($fullAddress);
                $opts = ['http' => ['header' => "User-Agent: YohzooPets/1.0\r\n", 'timeout' => 3]];
                $ctx = stream_context_create($opts);
                $result = @file_get_contents($url, false, $ctx);

                if ($result) {
                    $data = json_decode($result, true);
                    if (!empty($data[0]['lat']) && !empty($data[0]['lon'])) {
                        $destLat = (float) $data[0]['lat'];
                        $destLng = (float) $data[0]['lon'];
                        Configuration::updateValue($cacheKey, $destLat . ',' . $destLng);
                    }
                }
            }
        } catch (\Exception $e) {
            return null;
        }

        if (!$destLat || !$destLng) {
            return null;
        }

        $distanceKm = $this->haversineDistance($driverLat, $driverLng, $destLat, $destLng);
        $avgSpeedKmH = 20;
        $eta = (int) ceil(($distanceKm / $avgSpeedKmH) * 60);

        if ($eta < 1) {
            $eta = 1;
        }
        if ($eta > 180) {
            $eta = 180;
        }

        return $eta;
    }

    private function haversineDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }

    private function getProductImageUrl($product)
    {
        $idProduct = (int) $product['product_id'];
        $idImage = 0;

        if (!empty($product['image']) && is_object($product['image'])) {
            $idImage = (int) $product['image']->id;
        } elseif (!empty($product['id_image'])) {
            $idImage = (int) $product['id_image'];
        }

        if (!$idImage) {
            $cover = Image::getCover($idProduct);
            if ($cover) {
                $idImage = (int) $cover['id_image'];
            }
        }

        if (!$idImage) {
            return '';
        }

        return $this->context->link->getImageLink(
            $product['link_rewrite'] ?? 'product',
            $idProduct . '-' . $idImage,
            'small_default'
        );
    }
}

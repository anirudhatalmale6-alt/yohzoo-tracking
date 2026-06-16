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

        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

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
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

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
                $driverLocation = Db::getInstance()->getRow(
                    'SELECT latitude, longitude, accuracy FROM `' . _DB_PREFIX_ . 'yohzoo_driver_location` WHERE id_driver = ' . (int) $delivery['id_driver'] . ' ORDER BY id_location DESC'
                );
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
                            'price' => Tools::displayPrice((float) ($p['total_price_tax_incl'] ?? $p['product_price'] ?? 0), (int) $order->id_currency),
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
                'order_total' => Tools::displayPrice((float) $order->total_paid, (int) $order->id_currency),
                'driver' => $delivery['id_driver'] ? [
                    'name' => $delivery['driver_name'] ?? '',
                    'phone' => $delivery['driver_phone'] ?? '',
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
                    'updated' => date('Y-m-d H:i:s'),
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
            $refTime = $delivery['date_picked'] ?: $delivery['date_assigned'];
            if ($refTime) {
                $elapsed = (time() - strtotime($refTime)) / 60;
                if ($elapsed > $manual * 1.5) {
                    return null;
                }
                $remaining = (int) max(1, $manual - $elapsed);
                return $remaining;
            }
            return $manual;
        }

        if ($driverLocation && $address) {
            $destLat = null;
            $destLng = null;
            $cityCoords = [
                'Lima' => [-12.046, -77.043],
            ];
            $city = $address->city ?? '';
            if (isset($cityCoords[$city])) {
                $destLat = $cityCoords[$city][0];
                $destLng = $cityCoords[$city][1];
            }
            if ($destLat && $destLng) {
                $dLat = deg2rad((float)$driverLocation['latitude'] - $destLat);
                $dLng = deg2rad((float)$driverLocation['longitude'] - $destLng);
                $a = sin($dLat/2) * sin($dLat/2) +
                     cos(deg2rad($destLat)) * cos(deg2rad((float)$driverLocation['latitude'])) *
                     sin($dLng/2) * sin($dLng/2);
                $distKm = 6371 * 2 * atan2(sqrt($a), sqrt(1-$a));
                $roadDist = $distKm * 1.4;
                $speedKmh = 25;
                $etaMin = (int) ceil(($roadDist / $speedKmh) * 60);
                if ($etaMin >= 1 && $etaMin <= 120) {
                    return $etaMin;
                }
            }
        }

        return null;
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

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
        $address = new Address((int) $order->id_address_delivery);

        $logs = Db::getInstance()->executeS(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_tracking_log`
             WHERE id_delivery = ' . (int) $delivery['id_delivery'] . '
             ORDER BY date_add DESC LIMIT 20'
        );

        $driverLocation = null;
        if ($delivery['id_driver'] && in_array($delivery['status'], ['picked_up', 'on_the_way', 'nearby'])) {
            $driverLocation = Db::getInstance()->getRow(
                'SELECT latitude, longitude, accuracy, date_add
                 FROM `' . _DB_PREFIX_ . 'yohzoo_driver_location`
                 WHERE id_driver = ' . (int) $delivery['id_driver'] . '
                 ORDER BY date_add DESC LIMIT 1'
            );
        }

        $products = $order->getProducts();
        $productList = [];
        foreach ($products as $p) {
            $productList[] = [
                'name' => $p['product_name'],
                'quantity' => (int) $p['product_quantity'],
                'image' => $this->getProductImageUrl($p),
            ];
        }

        $statusSteps = ['preparing', 'ready', 'assigned', 'picked_up', 'on_the_way', 'delivered'];
        $currentStep = array_search($delivery['status'], $statusSteps);
        if ($currentStep === false) {
            $currentStep = 0;
        }

        $timeline = [];
        foreach ($logs as $log) {
            $timeline[] = [
                'status' => Yohzoo_Tracking::getStatusLabel($log['status']),
                'icon' => Yohzoo_Tracking::getStatusIcon($log['status']),
                'message' => $log['message'],
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
            'estimated_minutes' => $delivery['estimated_minutes'],
            'driver' => $delivery['id_driver'] ? [
                'name' => $delivery['driver_name'],
            ] : null,
            'delivery_address' => [
                'city' => $address->city,
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

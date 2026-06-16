<?php

class AdminYohzooDeliveryController extends ModuleAdminController
{
    public function __construct()
    {
        $this->bootstrap = true;
        $this->table = 'yohzoo_delivery';
        $this->identifier = 'id_delivery';
        $this->className = 'ObjectModel';

        parent::__construct();

        $this->meta_title = $this->l('Delivery Tracking');
    }

    public function initContent()
    {
        parent::initContent();

        $action = Tools::getValue('action');

        switch ($action) {
            case 'createDelivery':
                $this->ajaxCreateDelivery();
                return;
            case 'assignDriver':
                $this->ajaxAssignDriver();
                return;
            case 'updateStatus':
                $this->ajaxUpdateDeliveryStatus();
                return;
            case 'createDriver':
                $this->ajaxCreateDriver();
                return;
            case 'deleteDriver':
                $this->ajaxDeleteDriver();
                return;
            case 'deleteDelivery':
                $this->ajaxDeleteDelivery();
                return;
            case 'getMapData':
                $this->ajaxGetMapData();
                return;
        }

        $view = Tools::getValue('view', 'deliveries');

        $deliveries = Db::getInstance()->executeS(
            'SELECT d.*, o.reference as order_reference, dr.name as driver_name, dr.phone as driver_phone,
                    c.firstname as customer_firstname, CONCAT(c.firstname, " ", c.lastname) as customer_name,
                    a.address1, a.address2, a.city, a.postcode, a.phone as customer_phone, a.phone_mobile,
                    s.name as state_name
             FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
             JOIN `' . _DB_PREFIX_ . 'orders` o ON d.id_order = o.id_order
             JOIN `' . _DB_PREFIX_ . 'customer` c ON o.id_customer = c.id_customer
             JOIN `' . _DB_PREFIX_ . 'address` a ON o.id_address_delivery = a.id_address
             LEFT JOIN `' . _DB_PREFIX_ . 'yohzoo_driver` dr ON d.id_driver = dr.id_driver
             LEFT JOIN `' . _DB_PREFIX_ . 'state` s ON a.id_state = s.id_state
             ORDER BY d.date_add DESC LIMIT 50'
        );

        $drivers = Db::getInstance()->executeS(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_driver` ORDER BY name'
        );

        $activeDeliveries = Db::getInstance()->executeS(
            'SELECT d.*, dr.name as driver_name,
                    (SELECT CONCAT(dl.latitude, ",", dl.longitude) FROM `' . _DB_PREFIX_ . 'yohzoo_driver_location` dl
                     WHERE dl.id_driver = d.id_driver ORDER BY dl.date_add DESC LIMIT 1) as last_location
             FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
             LEFT JOIN `' . _DB_PREFIX_ . 'yohzoo_driver` dr ON d.id_driver = dr.id_driver
             WHERE d.status IN ("picked_up", "on_the_way", "nearby")
             AND d.id_driver IS NOT NULL'
        );

        $stats = [
            'total_today' => (int) Db::getInstance()->getValue(
                'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'yohzoo_delivery`
                 WHERE DATE(date_add) = CURDATE()'
            ),
            'active' => (int) Db::getInstance()->getValue(
                'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'yohzoo_delivery`
                 WHERE status NOT IN ("delivered", "cancelled")'
            ),
            'delivered_today' => (int) Db::getInstance()->getValue(
                'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'yohzoo_delivery`
                 WHERE status = "delivered" AND DATE(date_delivered) = CURDATE()'
            ),
        ];

        $trackingUrl = $this->context->link->getModuleLink('yohzoo_tracking', 'tracking');
        $driverAppUrl = $this->context->link->getModuleLink('yohzoo_tracking', 'driver');

        $msgTracking = Configuration::get('YOHZOO_MSG_TRACKING')
            ?: 'Hola {customer_name}! Tu pedido de Yohzoo (#{tracking_code}) esta en camino. Puedes seguirlo en tiempo real aqui: {tracking_url}';

        $this->context->smarty->assign([
            'deliveries' => $deliveries,
            'drivers' => $drivers,
            'active_deliveries' => $activeDeliveries,
            'stats' => $stats,
            'view' => $view,
            'admin_link' => $this->context->link->getAdminLink('AdminYohzooDelivery'),
            'tracking_url' => $trackingUrl,
            'driver_app_url' => $driverAppUrl,
            'statuses' => ['preparing', 'ready', 'assigned', 'picked_up', 'on_the_way', 'nearby', 'delivered', 'cancelled'],
            'wa_msg_template' => $msgTracking,
        ]);

        $this->content = $this->context->smarty->fetch(
            _PS_MODULE_DIR_ . 'yohzoo_tracking/views/templates/admin/delivery.tpl'
        );

        parent::initContent();
    }

    private function ajaxCreateDelivery()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $idOrder = (int) Tools::getValue('id_order');
        if (!$idOrder) {
            die(json_encode(['success' => false, 'error' => 'Order ID required']));
        }

        $existing = Db::getInstance()->getRow(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` WHERE id_order = ' . $idOrder
        );

        if ($existing) {
            die(json_encode(['success' => false, 'error' => 'Delivery already exists for this order']));
        }

        $order = new Order($idOrder);
        if (!Validate::isLoadedObject($order)) {
            die(json_encode(['success' => false, 'error' => 'Order not found']));
        }

        $trackingCode = strtoupper($order->reference);

        Db::getInstance()->insert('yohzoo_delivery', [
            'id_order' => $idOrder,
            'tracking_code' => $trackingCode,
            'status' => 'preparing',
            'date_add' => date('Y-m-d H:i:s'),
            'date_upd' => date('Y-m-d H:i:s'),
        ]);

        Db::getInstance()->insert('yohzoo_tracking_log', [
            'id_delivery' => (int) Db::getInstance()->Insert_ID(),
            'status' => 'preparing',
            'message' => 'Pedido registrado para entrega',
            'date_add' => date('Y-m-d H:i:s'),
        ]);

        die(json_encode(['success' => true, 'tracking_code' => $trackingCode]));
    }

    private function ajaxAssignDriver()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $idDelivery = (int) Tools::getValue('id_delivery');
        $idDriver = (int) Tools::getValue('id_driver');
        $estimatedMinutes = (int) Tools::getValue('estimated_minutes', 0);

        if (!$idDelivery || !$idDriver) {
            die(json_encode(['success' => false, 'error' => 'Missing parameters']));
        }

        Db::getInstance()->update('yohzoo_delivery', [
            'id_driver' => $idDriver,
            'status' => 'assigned',
            'estimated_minutes' => $estimatedMinutes ?: null,
            'date_assigned' => date('Y-m-d H:i:s'),
            'date_upd' => date('Y-m-d H:i:s'),
        ], 'id_delivery = ' . $idDelivery);

        Db::getInstance()->insert('yohzoo_tracking_log', [
            'id_delivery' => $idDelivery,
            'status' => 'assigned',
            'message' => 'Repartidor asignado',
            'date_add' => date('Y-m-d H:i:s'),
        ]);

        $delivery = Db::getInstance()->getRow(
            'SELECT d.*, o.reference FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
             JOIN `' . _DB_PREFIX_ . 'orders` o ON d.id_order = o.id_order
             WHERE d.id_delivery = ' . $idDelivery
        );

        $order = new Order((int) $delivery['id_order']);
        $customer = new Customer((int) $order->id_customer);
        $address = new Address((int) $order->id_address_delivery);
        $phone = $address->phone_mobile ?: $address->phone;

        $trackingUrl = $this->context->link->getModuleLink('yohzoo_tracking', 'tracking', ['code' => $delivery['tracking_code']]);

        $msgTemplate = Configuration::get('YOHZOO_MSG_TRACKING')
            ?: 'Hola {customer_name}! Tu pedido de Yohzoo (#{tracking_code}) esta en camino. Puedes seguirlo en tiempo real aqui: {tracking_url}';
        $whatsappMsg = str_replace(
            ['{customer_name}', '{tracking_code}', '{tracking_url}'],
            [$customer->firstname, $delivery['tracking_code'], $trackingUrl],
            $msgTemplate
        );

        if ($phone) {
            $phone = preg_replace('/[^0-9]/', '', $phone);
            if (substr($phone, 0, 1) !== '5') {
                $phone = '51' . $phone;
            }
        }

        die(json_encode([
            'success' => true,
            'whatsapp_url' => $phone ? 'https://wa.me/' . $phone . '?text=' . urlencode($whatsappMsg) : null,
            'whatsapp_msg' => $whatsappMsg,
            'customer_phone' => $phone,
        ]));
    }

    private function ajaxUpdateDeliveryStatus()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $idDelivery = (int) Tools::getValue('id_delivery');
        $status = pSQL(Tools::getValue('status', ''));

        $validStatuses = ['preparing', 'ready', 'assigned', 'picked_up', 'on_the_way', 'nearby', 'delivered', 'cancelled'];
        if (!in_array($status, $validStatuses)) {
            die(json_encode(['success' => false, 'error' => 'Invalid status']));
        }

        $updateData = [
            'status' => $status,
            'date_upd' => date('Y-m-d H:i:s'),
        ];

        if ($status === 'delivered') {
            $updateData['date_delivered'] = date('Y-m-d H:i:s');
        }

        Db::getInstance()->update('yohzoo_delivery', $updateData, 'id_delivery = ' . $idDelivery);

        Db::getInstance()->insert('yohzoo_tracking_log', [
            'id_delivery' => $idDelivery,
            'status' => $status,
            'message' => Yohzoo_Tracking::getStatusLabel($status),
            'date_add' => date('Y-m-d H:i:s'),
        ]);

        $whatsappUrl = null;
        if ($status === 'delivered') {
            $delivery = Db::getInstance()->getRow(
                'SELECT d.*, o.id_customer, o.id_address_delivery
                 FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
                 JOIN `' . _DB_PREFIX_ . 'orders` o ON d.id_order = o.id_order
                 WHERE d.id_delivery = ' . $idDelivery
            );

            if ($delivery) {
                $order = new Order((int) $delivery['id_order']);
                $deliveredState = Configuration::get('PS_OS_DELIVERED');
                if ($deliveredState) {
                    $order->setCurrentState((int) $deliveredState);
                }

                $address = new Address((int) $delivery['id_address_delivery']);
                $phone = $address->phone_mobile ?: $address->phone;
                if ($phone) {
                    $phone = preg_replace('/[^0-9]/', '', $phone);
                    if (strlen($phone) === 9) {
                        $phone = '51' . $phone;
                    }
                    $deliveredTemplate = Configuration::get('YOHZOO_MSG_DELIVERED')
                        ?: 'Hola! Tu pedido de Yohzoo Pets ha sido entregado. Gracias por tu compra! Si tienes alguna pregunta o duda, escribenos aqui.';
                    $whatsappUrl = 'https://wa.me/' . $phone . '?text=' . urlencode($deliveredTemplate);
                }
            }
        }

        die(json_encode(['success' => true, 'whatsapp_url' => $whatsappUrl]));
    }

    private function ajaxCreateDriver()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $name = pSQL(trim(Tools::getValue('driver_name', '')));
        $phone = pSQL(trim(Tools::getValue('driver_phone', '')));

        if (empty($name) || empty($phone)) {
            die(json_encode(['success' => false, 'error' => 'Name and phone required']));
        }

        $accessCode = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 6));

        Db::getInstance()->insert('yohzoo_driver', [
            'name' => $name,
            'phone' => $phone,
            'access_code' => $accessCode,
            'active' => 1,
            'date_add' => date('Y-m-d H:i:s'),
            'date_upd' => date('Y-m-d H:i:s'),
        ]);

        die(json_encode([
            'success' => true,
            'driver' => [
                'id' => (int) Db::getInstance()->Insert_ID(),
                'name' => $name,
                'access_code' => $accessCode,
            ],
        ]));
    }

    private function ajaxDeleteDriver()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $idDriver = (int) Tools::getValue('id_driver');
        if (!$idDriver) {
            die(json_encode(['success' => false, 'error' => 'Driver ID required']));
        }

        Db::getInstance()->update('yohzoo_driver', ['active' => 0, 'date_upd' => date('Y-m-d H:i:s')],
            'id_driver = ' . $idDriver
        );

        die(json_encode(['success' => true]));
    }

    private function ajaxDeleteDelivery()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $idDelivery = (int) Tools::getValue('id_delivery');
        if (!$idDelivery) {
            die(json_encode(['success' => false, 'error' => 'Delivery ID required']));
        }

        Db::getInstance()->execute(
            'DELETE FROM `' . _DB_PREFIX_ . 'yohzoo_tracking_log` WHERE id_delivery = ' . $idDelivery
        );

        Db::getInstance()->execute(
            'DELETE FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` WHERE id_delivery = ' . $idDelivery
        );

        die(json_encode(['success' => true]));
    }

    private function ajaxGetMapData()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $activeDeliveries = Db::getInstance()->executeS(
            'SELECT d.id_delivery, d.tracking_code, d.status, dr.name as driver_name,
                    dl.latitude, dl.longitude, dl.date_add as location_time
             FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
             JOIN `' . _DB_PREFIX_ . 'yohzoo_driver` dr ON d.id_driver = dr.id_driver
             LEFT JOIN `' . _DB_PREFIX_ . 'yohzoo_driver_location` dl ON dl.id_driver = d.id_driver
                 AND dl.id_location = (
                     SELECT MAX(id_location) FROM `' . _DB_PREFIX_ . 'yohzoo_driver_location`
                     WHERE id_driver = d.id_driver
                 )
             WHERE d.status IN ("picked_up", "on_the_way", "nearby")'
        );

        die(json_encode(['success' => true, 'deliveries' => $activeDeliveries]));
    }
}

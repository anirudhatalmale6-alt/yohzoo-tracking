<?php

class Yohzoo_TrackingDriverModuleFrontController extends ModuleFrontController
{
    public $auth = false;
    public $ssl = true;

    public function initContent()
    {
        parent::initContent();

        $action = Tools::getValue('action');

        if ($action === 'login') {
            $this->ajaxLogin();
            return;
        }
        if ($action === 'updateLocation') {
            $this->ajaxUpdateLocation();
            return;
        }
        if ($action === 'updateStatus') {
            $this->ajaxUpdateStatus();
            return;
        }
        if ($action === 'getDeliveries') {
            $this->ajaxGetDeliveries();
            return;
        }
        if ($action === 'getHistory') {
            $this->ajaxGetHistory();
            return;
        }

        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $this->context->smarty->assign([
            'ajax_url' => $this->context->link->getModuleLink('yohzoo_tracking', 'driver'),
        ]);

        $this->setTemplate('module:yohzoo_tracking/views/templates/front/driver.tpl');
    }

    private function ajaxLogin()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $code = pSQL(trim(Tools::getValue('code', '')));
        if (empty($code)) {
            die(json_encode(['success' => false, 'error' => 'Ingresa tu codigo']));
        }

        $driver = Db::getInstance()->getRow(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_driver`
             WHERE access_code = "' . $code . '" AND active = 1'
        );

        if (!$driver) {
            die(json_encode(['success' => false, 'error' => 'Codigo invalido']));
        }

        $token = hash('sha256', $driver['id_driver'] . $driver['access_code'] . date('Y-m-d'));

        die(json_encode([
            'success' => true,
            'driver' => [
                'id' => (int) $driver['id_driver'],
                'name' => $driver['name'],
                'token' => $token,
            ],
        ]));
    }

    private function validateDriverToken()
    {
        $driverId = (int) Tools::getValue('driver_id');
        $token = Tools::getValue('token', '');

        if (!$driverId || empty($token)) {
            return null;
        }

        $driver = Db::getInstance()->getRow(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_driver`
             WHERE id_driver = ' . $driverId . ' AND active = 1'
        );

        if (!$driver) {
            return null;
        }

        $expectedToken = hash('sha256', $driver['id_driver'] . $driver['access_code'] . date('Y-m-d'));
        if (!hash_equals($expectedToken, $token)) {
            return null;
        }

        return $driver;
    }

    private function ajaxUpdateLocation()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $driver = $this->validateDriverToken();
        if (!$driver) {
            die(json_encode(['success' => false, 'error' => 'No autorizado']));
        }

        $lat = (float) Tools::getValue('lat');
        $lng = (float) Tools::getValue('lng');
        $accuracy = (float) Tools::getValue('accuracy', 0);

        if ($lat == 0 || $lng == 0) {
            die(json_encode(['success' => false, 'error' => 'Ubicacion invalida']));
        }

        Db::getInstance()->insert('yohzoo_driver_location', [
            'id_driver' => (int) $driver['id_driver'],
            'latitude' => $lat,
            'longitude' => $lng,
            'accuracy' => $accuracy,
            'date_add' => date('Y-m-d H:i:s'),
        ]);

        // Clean old locations (keep last 100)
        Db::getInstance()->execute(
            'DELETE FROM `' . _DB_PREFIX_ . 'yohzoo_driver_location`
             WHERE id_driver = ' . (int) $driver['id_driver'] . '
             AND id_location NOT IN (
                 SELECT id_location FROM (
                     SELECT id_location FROM `' . _DB_PREFIX_ . 'yohzoo_driver_location`
                     WHERE id_driver = ' . (int) $driver['id_driver'] . '
                     ORDER BY `date_add` DESC LIMIT 100
                 ) tmp
             )'
        );

        die(json_encode(['success' => true]));
    }

    private function ajaxUpdateStatus()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $driver = $this->validateDriverToken();
        if (!$driver) {
            die(json_encode(['success' => false, 'error' => 'No autorizado']));
        }

        $idDelivery = (int) Tools::getValue('id_delivery');
        $status = pSQL(Tools::getValue('status', ''));

        $validStatuses = ['picked_up', 'on_the_way', 'nearby', 'delivered'];
        if (!in_array($status, $validStatuses)) {
            die(json_encode(['success' => false, 'error' => 'Estado invalido']));
        }

        $delivery = Db::getInstance()->getRow(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_delivery`
             WHERE id_delivery = ' . $idDelivery . '
             AND id_driver = ' . (int) $driver['id_driver']
        );

        if (!$delivery) {
            die(json_encode(['success' => false, 'error' => 'Entrega no encontrada']));
        }

        $updateData = [
            'status' => $status,
            'date_upd' => date('Y-m-d H:i:s'),
        ];

        if ($status === 'picked_up') {
            $updateData['date_picked'] = date('Y-m-d H:i:s');
        } elseif ($status === 'delivered') {
            $updateData['date_delivered'] = date('Y-m-d H:i:s');
        }

        Db::getInstance()->update('yohzoo_delivery', $updateData,
            'id_delivery = ' . $idDelivery
        );

        Db::getInstance()->insert('yohzoo_tracking_log', [
            'id_delivery' => $idDelivery,
            'status' => $status,
            'message' => Yohzoo_Tracking::getStatusLabel($status),
            'date_add' => date('Y-m-d H:i:s'),
        ]);

        die(json_encode(['success' => true, 'status_label' => Yohzoo_Tracking::getStatusLabel($status)]));
    }

    private function ajaxGetDeliveries()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $driver = $this->validateDriverToken();
        if (!$driver) {
            die(json_encode(['success' => false, 'error' => 'No autorizado']));
        }

        $deliveries = Db::getInstance()->executeS(
            'SELECT d.*, o.reference as order_reference
             FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
             JOIN `' . _DB_PREFIX_ . 'orders` o ON d.id_order = o.id_order
             WHERE d.id_driver = ' . (int) $driver['id_driver'] . '
             AND d.status NOT IN ("delivered", "cancelled")
             ORDER BY d.date_add DESC'
        );

        $result = [];
        foreach ($deliveries as $del) {
            $order = new Order((int) $del['id_order']);
            $address = new Address((int) $order->id_address_delivery);
            $customer = new Customer((int) $order->id_customer);

            $productList = [];
            try {
                $products = $order->getProducts();
                if ($products) {
                    foreach ($products as $p) {
                        $imgUrl = '';
                        $idProduct = (int) $p['product_id'];
                        $idImage = 0;
                        if (!empty($p['image']) && is_object($p['image'])) {
                            $idImage = (int) $p['image']->id;
                        } elseif (!empty($p['id_image'])) {
                            $idImage = (int) $p['id_image'];
                        }
                        if (!$idImage) {
                            $cover = Image::getCover($idProduct);
                            if ($cover) {
                                $idImage = (int) $cover['id_image'];
                            }
                        }
                        if ($idImage) {
                            $imgUrl = $this->context->link->getImageLink(
                                $p['link_rewrite'] ?? 'product',
                                $idProduct . '-' . $idImage,
                                'small_default'
                            );
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

            $district = '';
            if ($address->id_state) {
                $state = new State((int) $address->id_state);
                if (Validate::isLoadedObject($state)) {
                    $district = $state->name;
                }
            }

            $result[] = [
                'id_delivery' => (int) $del['id_delivery'],
                'order_reference' => $del['order_reference'],
                'tracking_code' => $del['tracking_code'],
                'status' => $del['status'],
                'status_label' => Yohzoo_Tracking::getStatusLabel($del['status']),
                'customer_name' => $customer->firstname . ' ' . $customer->lastname,
                'address' => $address->address1,
                'address2' => $address->address2 ?: '',
                'district' => $district,
                'city' => $address->city,
                'phone' => $address->phone_mobile ?: $address->phone,
                'total' => Tools::displayPrice($order->total_paid, (int) $order->id_currency),
                'payment_method' => $order->payment,
                'products' => $productList,
                'estimated_minutes' => $del['estimated_minutes'],
            ];
        }

        die(json_encode(['success' => true, 'deliveries' => $result]));
    }

    private function ajaxGetHistory()
    {
        header('Content-Type: application/json');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');

        $driver = $this->validateDriverToken();
        if (!$driver) {
            die(json_encode(['success' => false, 'error' => 'No autorizado']));
        }

        $filter = pSQL(Tools::getValue('filter', 'delivered'));
        if (!in_array($filter, ['delivered', 'cancelled'])) {
            $filter = 'delivered';
        }

        $deliveries = Db::getInstance()->executeS(
            'SELECT d.*, o.reference as order_reference
             FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
             JOIN `' . _DB_PREFIX_ . 'orders` o ON d.id_order = o.id_order
             WHERE d.id_driver = ' . (int) $driver['id_driver'] . '
             AND d.status = "' . $filter . '"
             ORDER BY d.date_upd DESC LIMIT 20'
        );

        $result = [];
        foreach ($deliveries as $del) {
            $order = new Order((int) $del['id_order']);
            $address = new Address((int) $order->id_address_delivery);
            $customer = new Customer((int) $order->id_customer);

            $district = '';
            if ($address->id_state) {
                $state = new State((int) $address->id_state);
                if (Validate::isLoadedObject($state)) {
                    $district = $state->name;
                }
            }

            $result[] = [
                'id_delivery' => (int) $del['id_delivery'],
                'order_reference' => $del['order_reference'],
                'tracking_code' => $del['tracking_code'],
                'status' => $del['status'],
                'status_label' => Yohzoo_Tracking::getStatusLabel($del['status']),
                'customer_name' => $customer->firstname . ' ' . $customer->lastname,
                'address' => $address->address1,
                'district' => $district,
                'city' => $address->city,
                'total' => Tools::displayPrice($order->total_paid, (int) $order->id_currency),
                'payment_method' => $order->payment,
                'date' => $del['status'] === 'delivered' ? date('d/m/Y H:i', strtotime($del['date_delivered'])) : date('d/m/Y H:i', strtotime($del['date_upd'])),
            ];
        }

        die(json_encode(['success' => true, 'deliveries' => $result]));
    }
}

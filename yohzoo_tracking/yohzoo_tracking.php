<?php

if (!defined('_PS_VERSION_')) {
    exit;
}

class Yohzoo_Tracking extends Module
{
    public function __construct()
    {
        $this->name = 'yohzoo_tracking';
        $this->tab = 'shipping_logistics';
        $this->version = '1.0.0';
        $this->author = 'Yohzoo';
        $this->need_instance = 0;
        $this->bootstrap = true;

        parent::__construct();

        $this->displayName = $this->l('Yohzoo Delivery Tracking');
        $this->description = $this->l('Live order tracking with GPS, ETA and WhatsApp notifications');
        $this->ps_versions_compliancy = ['min' => '1.7.0.0', 'max' => _PS_VERSION_];
    }

    public function install()
    {
        return parent::install()
            && $this->installDb()
            && $this->installTab()
            && $this->registerHook('displayHeader')
            && $this->registerHook('displayAdminOrder')
            && $this->registerHook('actionOrderStatusPostUpdate')
            && $this->registerHook('actionValidateOrder');
    }

    public function uninstall()
    {
        return $this->uninstallDb()
            && $this->uninstallTab()
            && parent::uninstall();
    }

    private function installDb()
    {
        $sql = [];

        $sql[] = 'CREATE TABLE IF NOT EXISTS `' . _DB_PREFIX_ . 'yohzoo_driver` (
            `id_driver` INT(11) NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(128) NOT NULL,
            `phone` VARCHAR(32) NOT NULL,
            `access_code` VARCHAR(16) NOT NULL,
            `active` TINYINT(1) NOT NULL DEFAULT 1,
            `date_add` DATETIME NOT NULL,
            `date_upd` DATETIME NOT NULL,
            PRIMARY KEY (`id_driver`),
            UNIQUE KEY `access_code` (`access_code`)
        ) ENGINE=' . _MYSQL_ENGINE_ . ' DEFAULT CHARSET=utf8mb4;';

        $sql[] = 'CREATE TABLE IF NOT EXISTS `' . _DB_PREFIX_ . 'yohzoo_delivery` (
            `id_delivery` INT(11) NOT NULL AUTO_INCREMENT,
            `id_order` INT(11) NOT NULL,
            `id_driver` INT(11) DEFAULT NULL,
            `tracking_code` VARCHAR(32) NOT NULL,
            `status` VARCHAR(32) NOT NULL DEFAULT "preparing",
            `estimated_minutes` INT(11) DEFAULT NULL,
            `notes` TEXT DEFAULT NULL,
            `date_assigned` DATETIME DEFAULT NULL,
            `date_picked` DATETIME DEFAULT NULL,
            `date_delivered` DATETIME DEFAULT NULL,
            `date_add` DATETIME NOT NULL,
            `date_upd` DATETIME NOT NULL,
            PRIMARY KEY (`id_delivery`),
            UNIQUE KEY `id_order` (`id_order`),
            UNIQUE KEY `tracking_code` (`tracking_code`),
            KEY `id_driver` (`id_driver`)
        ) ENGINE=' . _MYSQL_ENGINE_ . ' DEFAULT CHARSET=utf8mb4;';

        $sql[] = 'CREATE TABLE IF NOT EXISTS `' . _DB_PREFIX_ . 'yohzoo_driver_location` (
            `id_location` INT(11) NOT NULL AUTO_INCREMENT,
            `id_driver` INT(11) NOT NULL,
            `latitude` DECIMAL(10,7) NOT NULL,
            `longitude` DECIMAL(10,7) NOT NULL,
            `accuracy` DECIMAL(8,2) DEFAULT NULL,
            `date_add` DATETIME NOT NULL,
            PRIMARY KEY (`id_location`),
            KEY `id_driver` (`id_driver`),
            KEY `date_add` (`date_add`)
        ) ENGINE=' . _MYSQL_ENGINE_ . ' DEFAULT CHARSET=utf8mb4;';

        $sql[] = 'CREATE TABLE IF NOT EXISTS `' . _DB_PREFIX_ . 'yohzoo_tracking_log` (
            `id_log` INT(11) NOT NULL AUTO_INCREMENT,
            `id_delivery` INT(11) NOT NULL,
            `status` VARCHAR(32) NOT NULL,
            `message` VARCHAR(255) DEFAULT NULL,
            `date_add` DATETIME NOT NULL,
            PRIMARY KEY (`id_log`),
            KEY `id_delivery` (`id_delivery`)
        ) ENGINE=' . _MYSQL_ENGINE_ . ' DEFAULT CHARSET=utf8mb4;';

        foreach ($sql as $query) {
            if (!Db::getInstance()->execute($query)) {
                return false;
            }
        }

        return true;
    }

    private function uninstallDb()
    {
        $sql = [];
        $sql[] = 'DROP TABLE IF EXISTS `' . _DB_PREFIX_ . 'yohzoo_tracking_log`';
        $sql[] = 'DROP TABLE IF EXISTS `' . _DB_PREFIX_ . 'yohzoo_driver_location`';
        $sql[] = 'DROP TABLE IF EXISTS `' . _DB_PREFIX_ . 'yohzoo_delivery`';
        $sql[] = 'DROP TABLE IF EXISTS `' . _DB_PREFIX_ . 'yohzoo_driver`';

        foreach ($sql as $query) {
            Db::getInstance()->execute($query);
        }

        return true;
    }

    private function installTab()
    {
        $tab = new Tab();
        $tab->active = 1;
        $tab->class_name = 'AdminYohzooDelivery';
        $tab->name = [];
        foreach (Language::getLanguages(true) as $lang) {
            $tab->name[$lang['id_lang']] = 'Delivery Tracking';
        }
        $tab->id_parent = (int) Tab::getIdFromClassName('AdminParentShipping');
        $tab->module = $this->name;

        return $tab->add();
    }

    private function uninstallTab()
    {
        $id = (int) Tab::getIdFromClassName('AdminYohzooDelivery');
        if ($id) {
            $tab = new Tab($id);
            return $tab->delete();
        }
        return true;
    }

    public function hookDisplayHeader($params)
    {
        $page = $this->context->controller->php_self ?? '';
        if ($page === 'module-yohzoo_tracking-tracking') {
            $this->context->controller->registerStylesheet(
                'leaflet-css',
                'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css',
                ['server' => 'remote', 'priority' => 80]
            );
            $this->context->controller->registerJavascript(
                'leaflet-js',
                'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js',
                ['server' => 'remote', 'priority' => 80]
            );
            $this->context->controller->registerStylesheet(
                'yohzoo-tracking-css',
                'modules/' . $this->name . '/views/css/tracking.css',
                ['priority' => 90]
            );
            $this->context->controller->registerJavascript(
                'yohzoo-tracking-js',
                'modules/' . $this->name . '/views/js/tracking.js',
                ['priority' => 90]
            );
        }
    }

    public function hookDisplayAdminOrder($params)
    {
        $idOrder = (int) $params['id_order'];
        $order = new Order($idOrder);

        $delivery = Db::getInstance()->getRow(
            'SELECT d.*, dr.name as driver_name, dr.phone as driver_phone
             FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` d
             LEFT JOIN `' . _DB_PREFIX_ . 'yohzoo_driver` dr ON d.id_driver = dr.id_driver
             WHERE d.id_order = ' . $idOrder
        );

        $drivers = Db::getInstance()->executeS(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_driver` WHERE active = 1 ORDER BY name'
        );

        $this->context->smarty->assign([
            'delivery' => $delivery,
            'drivers' => $drivers,
            'id_order' => $idOrder,
            'order_reference' => $order->reference,
            'module_link' => $this->context->link->getAdminLink('AdminYohzooDelivery'),
            'tracking_url' => $this->context->link->getModuleLink($this->name, 'tracking'),
        ]);

        return $this->display(__FILE__, 'views/templates/admin/order_panel.tpl');
    }

    public function hookActionValidateOrder($params)
    {
        $order = $params['order'];
        $idOrder = (int) $order->id;

        $existing = Db::getInstance()->getRow(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` WHERE id_order = ' . $idOrder
        );

        if (!$existing) {
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
                'message' => 'Pedido registrado automaticamente para entrega',
                'date_add' => date('Y-m-d H:i:s'),
            ]);
        }
    }

    public function hookActionOrderStatusPostUpdate($params)
    {
        $idOrder = (int) $params['id_order'];

        $existing = Db::getInstance()->getRow(
            'SELECT * FROM `' . _DB_PREFIX_ . 'yohzoo_delivery` WHERE id_order = ' . $idOrder
        );

        if (!$existing) {
            $order = new Order($idOrder);
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
        }
    }

    public static function getStatusLabel($status)
    {
        $labels = [
            'preparing' => 'Preparando tu pedido',
            'ready' => 'Listo para envio',
            'assigned' => 'Repartidor asignado',
            'picked_up' => 'Pedido recogido',
            'on_the_way' => 'En camino',
            'nearby' => 'Cerca de tu ubicacion',
            'delivered' => 'Entregado',
            'cancelled' => 'Cancelado',
        ];

        return $labels[$status] ?? $status;
    }

    public static function getStatusIcon($status)
    {
        $icons = [
            'preparing' => '📦',
            'ready' => '✅',
            'assigned' => '🏍️',
            'picked_up' => '📤',
            'on_the_way' => '🚚',
            'nearby' => '📍',
            'delivered' => '🎉',
            'cancelled' => '❌',
        ];

        return $icons[$status] ?? '📦';
    }
}

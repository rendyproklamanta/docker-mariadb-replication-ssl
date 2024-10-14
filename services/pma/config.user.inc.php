<?php

$cfg['NavigationTreeDisableTableOperations'] = true;
$cfg['Export']                   = false;
$cfg['AllowUserDropDatabase']    = false;
$cfg['ShowChgPassword']          = false;

$cfg['blowfish_secret']          = 'Gi>-%hSk^S|7s/8F.F^6J{<3jNF2~<0X'; // Use a secure random string
$cfg['Servers'][1]['auth_type']  = 'cookie';
$cfg['Servers'][1]['ssl']        = true; // Enable SSL
$cfg['Servers'][1]['ssl_key']    = '/etc/phpmyadmin/tls/client-key.pem'; // Path to your client key
$cfg['Servers'][1]['ssl_cert']   = '/etc/phpmyadmin/tls/client-cert.pem'; // Path to your client certificate
$cfg['Servers'][1]['ssl_ca']     = '/etc/phpmyadmin/tls/ca-cert.pem'; // Path to your CA certificate
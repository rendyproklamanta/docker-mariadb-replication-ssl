# MariaDB replication using MaxScale (SSL)

![img](tls-mariadb-maxscale.jpg)

## Stacks

- MariaDB 11.x
- Docker
- Maxscale

## Servers

- Master
- Slave1

## Steps

- Create dir
  
```shell
mkdir -p /var/lib/mariadb
```

- goto dir and clone

```shell
cd /var/lib/mariadb
git clone https://github.com/rendyproklamanta/docker-mariadb-replication-ssl.git .
```

- Change Password by using text replacing tool

```shell
cd /var/lib/mariadb
find -type f -exec sed -i 's/REPL_PASSWORD_SET/YOUR_PASSWORD/g' {} +
find -type f -exec sed -i 's/MASTER_ROOT_PASSWORD_SET/YOUR_PASSWORD/g' {} +
find -type f -exec sed -i 's/SLAVE1_ROOT_PASSWORD_SET/YOUR_PASSWORD/g' {} +
find -type f -exec sed -i 's/SUPER_PASSWORD_SET/YOUR_PASSWORD/g' {} +
```

- Adding port to firewall

```shell
ufw allow 3306
ufw allow 6033
ufw allow 3301
ufw allow 3302
ufw allow 8989
```

- Generate ssl

```shell
cd /var/lib/mariadb/certs
chmod +x generate.sh && ./generate.sh
```

- Set permission and start!

```shell
cd /var/lib/mariadb
chmod +x start.sh && ./start.sh
```

- Check service status after reboot :

```shell
sudo journalctl -u mariadb-repl.service
```

## Rolling user password

<https://github.com/rendyproklamanta/docker-mysql-credential-rolling>

## Access

- Access database using PMA

```shell
Link : http://localhost:8000 or http://[YOUR_IP_ADDRESS]:8000
user : super_usr
pass : SUPER_PASSWORD_SET
```

- Access using MySql client, like navicat, etc..

```shell
host : maxscale or [YOUR_IP_ADDRESS]
user : super_usr
pass : SUPER_PASSWORD_SET
port : 6033 (proxy) | 3301 (master) | 3302 (slave)
```

- Access MaxScale web UI

```shell
Link : http://localhost:8989 or http://[YOUR_IP_ADDRESS]:8989
user : admin
pass : mariadb
```

## Note

- If server down

```shell
* Execute start.sh again : 
-- linux : ./start.sh
-- windows : ./start.dev.sh

* Check if 1 or more database not sync beetwen servers :
-- Login to mysqlclient : maxscale server
-- Run Query Lock : FLUSH TABLES WITH READ LOCK;
-- Export database {dbname}
-- Import database {dbname} to {dbname_new}
-- Delete old database {dbname}
-- Rename {dbname_new} to {dbname}
-- Run query unlock : UNLOCK TABLES;
-- Check if all tables synced up
```

- If GTID not sync between servers

```shell
cd resync
chmod +x main.sh && ./main.sh
```

## Mount local volume *certs* directory to your container

```yml
volumes:
   - /var/lib/mariadb/certs:/usr/share/nginx/html/application/third_party/db_certs/prod
```

## How to connect from mysql client to server using SSL

- Generate SSL for development only

```shell
cd /var/lib/mariadb/certs
chmod +x generate-dev.sh && ./generate-dev.sh
```

- Then copy all *.pem files to your local development

## Example fo use (CI3 database.php)

```php
$ssl_settings = array();

if (ENVIRONMENT === 'development') {
    $ssl_settings = array(
      'ssl_key' => realpath('./application/third_party/db_certs/dev/client-key.pem'),
      'ssl_cert' => realpath('./application/third_party/db_certs/dev/client-cert.pem'),
      'ssl_ca' => realpath('./application/third_party/db_certs/dev/ca-cert.pem'),
    );
} else {
    $ssl_settings = array(
      'ssl_key' => realpath('./application/third_party/db_certs/prod/client-key.pem'),
      'ssl_cert' => realpath('./application/third_party/db_certs/prod/client-cert.pem'),
      'ssl_ca' => realpath('./application/third_party/db_certs/prod/ca-cert.pem'),
    );
}

$db['default'] = array(
   ... # Other configs
   'ssl_set' => $ssl_settings # Add this line
)
```

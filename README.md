# MariaDB replication using MaxScale (SSL)

![img](tls-mariadb-maxscale.jpg)

## Prerequisite

- [Traefik v3](https://github.com/rendyproklamanta/docker-swarm-traefik) (optional: for domain pointing to service like PMA, maxscale, traefik dashboard)

## Stacks

- MariaDB 11.x
- Docker Swarm
- Maxscale

## Servers

- Master
- Slave1

## Steps

- Create, cd dir and clone

```shell
mkdir -p /var/lib/mariadb
cd /var/lib/mariadb
git clone https://github.com/rendyproklamanta/docker-mariadb-replication-ssl.git .
```

- Default BASE_DIR is /var/lib/mariadb | if you want change to other dir

```shell
cd /var/lib/mariadb
find . -type f -exec sed -i 's|/var/lib/mariadb|/var/lib/mariadb-new|g' {} +
mv /var/lib/mariadb /var/lib/mariadb-new
cd /var/lib/mariadb-new # this is your new mariadb directory!
```

- Default DATA_DIR is /data/mariadb | if you want change to other dir

```shell
cd /var/lib/mariadb # change with you mariadb directory
find . -type f -exec sed -i 's|/data/mariadb|/data/mariadb-new|g' {} +
```

- Default BACKUP_DIR is /backup/mariadb | if you want change to other dir

```shell
cd /var/lib/mariadb # change with you mariadb directory
find . -type f -exec sed -i 's|/backup/mariadb|/backup/mariadb-new|g' {} +
```

- Change Password by using text replacing tool

```shell
cd /var/lib/mariadb # change with you mariadb directory
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

- Change domain PMA

```shell
cd /var/lib/mariadb/services/pma # change with you mariadb directory
nano docker-compose.yaml
```

- Create encryption - FOR FIRST TIME ONLY!

> keep your keyfile secure, if diffrenet key the mariadb data directory cannot access, sp dont lost them!

```shell
cd /var/lib/mariadb/encryption && chmod +x generate.sh && ./generate.sh
chmod -R 755 /var/lib/mariadb/encryption
```

- Generate ssl

```shell
cd /var/lib/mariadb/tls # change with you mariadb directory
chmod +x generate.sh && ./generate.sh
```

- Set permission and start!

```shell
cd /var/lib/mariadb # change with you mariadb directory
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
Link : http://[YOUR_IP_ADDRESS]:8000 OR https://pma.secure.domain.com (We recomend using SSL)
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
- If GTID not sync between servers
- Execute start.sh again

```shell
./start.sh
```

## How to connect from application to server using SSL

- Copy all *.pem files to your application

- Example fo use (CI3 database.php)

```php
$db['default'] = array(
   ... # Other configs
   'encrypt' => array(
      'ssl_verify'  => FALSE,
      'ssl_ca'      => realpath('./application/third_party/db_certs/ca-cert.pem'),
      'ssl_key'     => realpath('./application/third_party/db_certs/client-key.pem'),
      'ssl_cert'    => realpath('./application/third_party/db_certs/client-cert.pem'),
    ),
)
```

## SQL Commands to check SSL

```shell
SHOW VARIABLES LIKE '%ssl%';
SHOW STATUS LIKE 'ssl_server_not%';
```

## Table encryption

- Encrypt table

```sql
ALTER TABLE table_name
ENCRYPTED=YES ENCRYPTION_KEY_ID=1;
```

- Test encryption is ON

```sql
SELECT A.NAME, B.ENCRYPTION_SCHEME FROM information_schema.INNODB_TABLESPACES_ENCRYPTION B 
JOIN information_schema.INNODB_SYS_TABLES A ON A.SPACE = B.SPACE;
```

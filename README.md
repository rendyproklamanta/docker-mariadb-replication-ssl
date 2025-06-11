# MariaDB replication using MaxScale (SSL)

![img](tls-mariadb-maxscale.jpg)

## Prerequisite

- Ubuntu 22.04
- [Traefik](https://github.com/rendyproklamanta/docker-swarm-traefik) (optional: for domain pointing to service like PMA, maxscale)

## Stacks

- MariaDB 11.x
- Docker Swarm
- Maxscale 21.06
- PhpMyAdmin

## Extra Features

- ✅ [Encryption at Transport](https://mariadb.com/kb/en/securing-connections-for-client-and-server)
- ✅ [Encryption at Rest](https://mariadb.com/kb/en/data-at-rest-encryption-overview/)
- ✅ Backup scheduled by cron

## Optional Features

- [Backup to S3](https://github.com/rendyproklamanta/docker-mysql-backup-s3)
- [User password rotation](https://github.com/rendyproklamanta/docker-mysql-credential-rolling) - to prevent credential leaks

## Servers

- Master
- Slave1

## Steps

## Create Network
```sh
docker network create --driver overlay mariadb-network
```

## Create dir and clone

```shell
sudo mkdir -p /var/lib/mariadb
cd /var/lib/mariadb
sudo git clone https://github.com/rendyproklamanta/docker-mariadb-replication-ssl.git .
```

## Change domain PMA

```shell
sudo nano /var/lib/mariadb/services/pma/docker-compose.yaml 
```


## Move start.sh to safety place

```shell
cd /var/lib/mariadb
sudo mv mariadb-start.sh /etc/init.d/mariadb-start.sh
```

## Set permission and start the mariadb service

```shell
cd /etc/init.d
sudo chmod +x mariadb-start.sh && sudo ./mariadb-start.sh
```

- Test reboot :

```shell
sudo reboot
```

- Check service status after reboot :

```shell
sudo journalctl -u mariadb-repl.service
```

---


## Credential dirs

- Get the credential and certs to connect from client (required)

```sh
cd /etc/secure/mariadb
```

## Access

- Access database using PMA

> We recomend using domain for PMA to enable SSL with traefik

```shell
Link : http://[YOUR_IP_ADDRESS]:8000 OR https://pma.secure.domain.com 
user : super_adm
pass : SUPERADMIN_PASSWORD_SET
```

- Access using Mysql-client like workbench, navicat, etc..

```shell
host : [YOUR_IP_ADDRESS]
user : super_adm
pass : SUPERADMIN_PASSWORD_SET
port : 60330
```

- Access MaxScale web UI

```shell
Link : http://[YOUR_IP_ADDRESS]:58989
user : admin
pass : mariadb
```

- Host & Port List

```shell
Maxscale
host : mariadb_maxscale
port : 60330
---------------------------
Master
host : mariadb_master
port : 3301
---------------------------
Slave1
host : mariadb_slave1
port : 3301
```

---

## Note

- If server down
- If GTID not sync between servers
- Execute start.sh again

```shell
./start.sh
```

---

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
ENCRYPTED=YES;
```

- Test encryption is ON

```sql
SELECT A.NAME, B.ENCRYPTION_SCHEME FROM information_schema.INNODB_TABLESPACES_ENCRYPTION B 
JOIN information_schema.INNODB_SYS_TABLES A ON A.SPACE = B.SPACE;
```

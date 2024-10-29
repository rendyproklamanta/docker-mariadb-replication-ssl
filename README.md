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

## Included

- [x] [Secure server & client: TLS/SSL](https://mariadb.com/kb/en/securing-connections-for-client-and-server)
- [x] [Encryption: Data-at-Rest](https://mariadb.com/kb/en/data-at-rest-encryption-overview/)
- [x] [Maxscale firewall: Query Blacklist Filter](https://mariadb.com/kb/en/mariadb-maxscale-24-database-firewall-filte)
- [x] Backup schedule by cron

## Not Included (optional)

- [Backup to S3](https://github.com/rendyproklamanta/docker-mysql-backup-s3)
- [User password rotation](https://github.com/rendyproklamanta/docker-mysql-credential-rolling) - to prevent credential leaks

## Servers

- Master
- Slave1

## Steps

**1. Create dir and clone**

```shell
mkdir -p /var/lib/mariadb
cd /var/lib/mariadb
git clone https://github.com/rendyproklamanta/docker-mariadb-replication-ssl.git .
```

---

**2. Change Password by using text replacing tool**

```shell
cd /var/lib/mariadb
find -type f -exec sed -i 's/REPL_PASSWORD_SET/YOUR_PASSWORD/g' {} +
find -type f -exec sed -i 's/MAXSCALE_PASSWORD_SET/YOUR_PASSWORD/g' {} +
find -type f -exec sed -i 's/MASTER_ROOT_PASSWORD_SET/YOUR_PASSWORD/g' {} +
find -type f -exec sed -i 's/SLAVE1_ROOT_PASSWORD_SET/YOUR_PASSWORD/g' {} +
find -type f -exec sed -i 's/SUPER_PASSWORD_SET/YOUR_PASSWORD/g' {} +
```

---

**3. Change domain PMA**

```shell
nano /var/lib/mariadb/services/pma/docker-compose.yaml 
```

---

**4. Change directory location (optional)**

- **DATA_DIR** default location is */data/mariadb* | if you want change to other dir

```shell
cd /var/lib/mariadb
find . -type f -exec sed -i 's|/data/mariadb|/mnt/blockstorage/mariadb|g' {} +
```

- **BACKUP_DIR** default location is */backup/mariadb* | if you want change to other dir

```shell
cd /var/lib/mariadb 
find . -type f -exec sed -i 's|/backup/mariadb|/mnt/blockstorage/backup/mariadb|g' {} +
```

- Edit in every docker-compose.yaml - If you using */mnt* as volume only!!

```shell
If you using block storage, add in the end of mounted volume ":z"
Because external storage "/mnt" volume is a shared volume
```

```shell
example:

- /mnt/blockstorage/mariadb/master:/var/lib/mysql:z
```

```shell
nano /var/lib/mariadb/nodes/master/docker-compose.yaml
nano /var/lib/mariadb/nodes/slave1/docker-compose.yaml
nano /var/lib/mariadb/services/backup/docker-compose.yaml
nano /var/lib/mariadb/services/maxscale/docker-compose.yaml
nano /var/lib/mariadb/services/pma/docker-compose.yaml
```

---

**5. Adding port to firewall**

```shell
ufw allow 3306
ufw allow 6033
ufw allow 3301
ufw allow 3302
ufw allow 8989
```

**6. Move start.sh to safety place**

```shell
cd /var/lib/mariadb # change with you "new" mariadb directory if changed
mv start.sh /etc/init.d/start.sh
```

**7. Set permission and start!**

```shell
cd /etc/init.d
chmod +x start.sh && ./start.sh
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

## Access

- Access database using PMA

> We recomend using domain for PMA to enable SSL with traefik

```shell
Link : http://[YOUR_IP_ADDRESS]:8000 OR https://pma.secure.domain.com 
user : super_usr
pass : SUPER_PASSWORD_SET
```

- Access using Mysql-client like workbench, navicat, etc..

```shell
host : [YOUR_IP_ADDRESS]
user : super_usr
pass : SUPER_PASSWORD_SET
port : 6033
```

- Access MaxScale web UI

```shell
Link : http://[YOUR_IP_ADDRESS]:8989
user : admin
pass : mariadb
```

- Host & Port List

```shell
Maxscale
host : mariadb_maxscale
port : 6033
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

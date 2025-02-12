#!/bin/bash

## Delete secret
sudo docker secret rm db_host
sudo docker secret rm db_port
sudo docker secret rm db_superadmin
sudo docker secret rm db_superadmin_paswd
sudo docker secret rm db_superuser
sudo docker secret rm db_superuser_paswd

## Create secret
echo "MAXSCALE_PORT_SET" | sudo docker secret create db_port -
echo "mariadb_maxscale" | sudo docker secret create db_host -
echo "super_adm" | sudo docker secret create db_superadmin -
echo "SUPERADMIN_PASSWORD_SET" | sudo docker secret create db_superadmin_paswd -
echo "super_usr" | sudo docker secret create db_superuser -
echo "SUPERUSER_PASSWORD_SET" | sudo docker secret create db_superuser_paswd -
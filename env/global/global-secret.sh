#!/bin/bash

## Delete secret
docker secret rm db_host
docker secret rm db_port
docker secret rm db_superadmin
docker secret rm db_superadmin_paswd
docker secret rm db_superuser
docker secret rm db_superuser_paswd

## Create secret
echo "6033" | docker secret create db_port -
echo "mariadb_maxscale" | docker secret create db_host -
echo "super_adm" | docker secret create db_superadmin -
echo "SUPERADMIN_PASSWORD_SET" | docker secret create db_superadmin_paswd -
echo "super_usr" | docker secret create db_superuser -
echo "SUPERUSER_PASSWORD_SET" | docker secret create db_superuser_paswd -
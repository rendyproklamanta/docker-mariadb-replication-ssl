#!/bin/bash

## Delete secret
docker secret rm db_host
docker secret rm db_port
docker secret rm db_super_user
docker secret rm db_super_paswd
docker secret rm db_master_paswd
docker secret rm db_slave1_paswd

## Create secret
echo "6033" | docker secret create db_port -
echo "mariadb_maxscale" | docker secret create db_host -
echo "super_usr" | docker secret create db_super_user -

echo "SUPER_PASSWORD_SET" | docker secret create db_super_paswd -
echo "MASTER_ROOT_PASSWORD_SET" | docker secret create db_master_paswd -
echo "SLAVE1_ROOT_PASSWORD_SET" | docker secret create db_slave1_paswd -

## Show list secrets
docker secret ls
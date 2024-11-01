#!/bin/bash

## Delete secret
docker secret rm db_host
docker secret rm db_port
docker secret rm db_super_user
docker secret rm db_super_paswd

## Create secret
echo "6033" | docker secret create db_port -
echo "mariadb_maxscale" | docker secret create db_host -
echo "super_usr" | docker secret create db_super_user -
echo "SUPER_PASSWORD_SET" | docker secret create db_super_paswd -
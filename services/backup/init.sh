#!/bin/bash

# Deploy backup
mkdir -p /backup/mariadb
chmod -R 777 /backup/mariadb

docker stack deploy --compose-file docker-compose.yaml --detach=false mariadb
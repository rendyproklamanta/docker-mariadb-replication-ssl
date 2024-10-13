#!/bin/bash

# load env file into the script's environment.
source ./env/global.sh
source ./env/master.sh
source ./env/slave1.sh

# Init swarm
docker swarm init
docker network create --driver overlay mariadb-network

# Stopping all services
docker stack rm mariadb

# Deploy master
echo "**** Deploy container master ****"
cd ./nodes/master
mkdir -p data
chmod -R 777 data
chmod +x init-sql.sh && ./init-sql.sh
docker stack deploy --compose-file docker-compose.yaml --detach=false mariadb

cd ../../

# Deploy slave1
echo "**** Deploy container slave1 ****"
cd ./nodes/slave1
mkdir -p data
chmod -R 777 data
chmod +x check-master.sh && ./check-master.sh
chmod +x init-sql.sh && ./init-sql.sh
docker stack deploy --compose-file docker-compose.yaml --detach=false mariadb
chmod +x check-slave1.sh && ./check-slave1.sh
docker exec -i $(docker ps -q -f name=$HOST_SLAVE1) mariadb -uroot -p$SLAVE1_ROOT_PASSWORD < initdb/01-init.sql

cd ../../

# Resync replication
echo "**** Resync replication ****"
cd resync && chmod +x main.sh && ./main.sh

cd ../

# --------------------------

echo '**** Deploy services ****'
cd services

# Deploy MaxScale
cd maxscale
docker stack deploy --compose-file docker-compose.yaml --detach=false mariadb
cd ../

# Deploy backup
cd backup
chmod +x init.sh && ./init.sh
cd ../

# Deploy PMA
cd pma
docker stack deploy --compose-file docker-compose.yaml --detach=false mariadb
cd ../

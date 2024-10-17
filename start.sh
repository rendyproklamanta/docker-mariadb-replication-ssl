#!/bin/bash

# Define color codes
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (reset to default)

# Define the absolute path to the data directory
BASE_DIR="/var/lib/mariadb"
BACKUP_DIR="/backup/mariadb"
DATA_DIR="/data/mariadb"

# load env file into the script's environment.
source $BASE_DIR/env/global.sh
source $BASE_DIR/env/master.sh
source $BASE_DIR/env/slave1.sh

# Create network
docker network create --driver overlay mariadb-network

# Stopping all services
docker stack rm mariadb

# ---------------------------

# Create mysql group
sudo groupadd mysql

# Create docker secrets
cd $BASE_DIR/env/secrets && chmod +x secrets.sh && ./secrets.sh

# Generate encryption
mkdir -p $DATA_DIR/encryption
cd $BASE_DIR/encryption && chmod +x generate.sh && ./generate.sh
cp $BASE_DIR/encryption/keyfile* $DATA_DIR/encryption
chmod -R 755 $DATA_DIR/encryption

# Initdb
cd $BASE_DIR/scripts && chmod +x initdb.sh && ./initdb.sh

# Deploy master
echo -e "${YELLOW}**** Deploy container master ****${NC}"
mkdir -p $DATA_DIR/master && chown -R root:mysql $DATA_DIR/master  # Create directory data
docker stack deploy --compose-file $BASE_DIR/nodes/master/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && chmod +x healthcheck.sh && set -k && ./healthcheck.sh host="$HOST_MASTER" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# Deploy slave1
echo -e "${YELLOW}**** Deploy container slave1 ****${NC}"
mkdir -p $DATA_DIR/slave1 && chown -R root:mysql $DATA_DIR/slave1  # Create directory data
docker stack deploy --compose-file $BASE_DIR/nodes/slave1/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && chmod +x healthcheck.sh && set -k && ./healthcheck.sh host="$HOST_SLAVE1" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# Resync replication
echo -e "${YELLOW}**** Resync replication ****${NC}"
# Sync slave to master
cd $BASE_DIR/scripts && chmod +x replica.sh && set -k && ./replica.sh master_host="$HOST_MASTER" master_port="$PORT_MASTER" host="$HOST_SLAVE1" port="$PORT_SLAVE1" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"
# Sync master to slave (if master down)
cd $BASE_DIR/scripts && chmod +x replica.sh && set -k && ./replica.sh master_host="$HOST_SLAVE1" master_port="$PORT_SLAVE1" host="$HOST_MASTER" port="$PORT_MASTER" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# ---------------------------

echo '**** Deploy services ****'

# Deploy MaxScale
echo -e "${YELLOW}**** Deploy maxscale container ****${NC}"
docker stack deploy --compose-file $BASE_DIR/services/maxscale/docker-compose.yaml --detach=false mariadb

# Deploy backup
echo -e "${YELLOW}**** Deploy backup container ****${NC}"
mkdir -p $BACKUP_DIR && chmod -R 755 $BACKUP_DIR # Create directory data
docker stack deploy --compose-file $BASE_DIR/services/backup/docker-compose.yaml --detach=false mariadb

# Deploy PMA
echo -e "${YELLOW}**** Deploy PMA container ****${NC}"
docker stack deploy --compose-file $BASE_DIR/services/pma/docker-compose.yaml --detach=false mariadb

# Enable startup service
echo -e "${YELLOW}**** Set auto startup mariadb service ****${NC}"
cp $BASE_DIR/mariadb-repl.service /etc/systemd/system/mariadb-repl.service
sudo systemctl enable mariadb-repl.service
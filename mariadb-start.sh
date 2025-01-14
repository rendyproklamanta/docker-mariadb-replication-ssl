#!/bin/bash

# Define color codes
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (reset to default)

# Define the absolute path to the data directory
BASE_DIR="/var/lib/mariadb"
NODES_DIR="/var/lib/mariadb/nodes"
SERVICE_DIR="/var/lib/mariadb/services"
SERVICE_ALT_DIR="/var/lib/mariadb_services"
MARIADB_LOG_DIR="/var/log/mariadb"

DATA_DIR="/data/mariadb"
BACKUP_DIR="/backup/mariadb"
SECURE_DIR="/etc/secure/mariadb"
SHARED_VOLUME="" # Add ":z" if you using shared volume like /mnt blockstorage

# init docker swarm
sudo docker swarm init

# Create network
sudo docker network create --driver overlay mariadb-network
sudo docker network create --driver overlay traefik-network

# Stopping all services
sudo docker stack rm mariadb

# CLONE : Check if the destination file/directory is exists (mariadb)
if [ -e "$BASE_DIR" ]; then
   echo "Error: Destination '$BASE_DIR' already exists. Move operation aborted. (OK)"
else
   sudo mkdir -p $BASE_DIR
   cd $BASE_DIR
   sudo git clone https://github.com/rendyproklamanta/docker-mariadb-replication-ssl.git .
fi

# Change atrributes
echo -e "${YELLOW}**** Changing attributes ****${NC}"
sudo chattr -R -a $SECURE_DIR

# Create Directory
echo -e "${YELLOW}**** Creating directory ****${NC}"
sudo mkdir -p $DATA_DIR && sudo chmod -R 755 $DATA_DIR
sudo mkdir -p $BACKUP_DIR && sudo chmod -R 755 $BACKUP_DIR
sudo mkdir -p $SECURE_DIR && sudo chmod -R 755 $SECURE_DIR
sudo mkdir -p $SERVICE_ALT_DIR && sudo chmod -R 755 $SERVICE_ALT_DIR

# Create Directory MariaDB Log
sudo mkdir -p $MARIADB_LOG_DIR
sudo touch $MARIADB_LOG_DIR/general.log
sudo touch $MARIADB_LOG_DIR/slow.log
sudo chmod -R 777 $MARIADB_LOG_DIR

# Set directory
echo -e "${YELLOW}**** Setting directory ****${NC}"
sudo find "$BASE_DIR" -type f -exec sed -i "s|DATA_DIR_SET|$DATA_DIR|g" {} +
sudo find "$BASE_DIR" -type f -exec sed -i "s|BACKUP_DIR_SET|$BACKUP_DIR|g" {} +
sudo find "$BASE_DIR" -type f -exec sed -i "s|SECURE_DIR_SET|$SECURE_DIR|g" {} +
sudo find "$BASE_DIR" -type f -exec sed -i "s| SHARED_VOLUME_SET|$SHARED_VOLUME|g" {} +

# MOVE : Check if the destination file/directory is exists (env)
if [ -e "$SECURE_DIR/env" ]; then
   echo "Error: Destination '$SECURE_DIR/env' already exists. Move operation aborted. (OK)"
else
   sudo mv "$BASE_DIR/env" "$SECURE_DIR/env"
   echo "Moved '$BASE_DIR/env' to '$SECURE_DIR/env'."
fi

# MOVE : Check if the destination file/directory is exists (encryption)
if [ -e "$SECURE_DIR/encryption" ]; then
   echo "Error: Destination '$SECURE_DIR/encryption' already exists. Move operation aborted. (OK)"
else
   sudo mv "$BASE_DIR/encryption" "$SECURE_DIR/encryption"
   echo "Moved '$BASE_DIR/encryption' to '$SECURE_DIR/encryption'."
fi

# MOVE : Check if the destination file/directory is exists (TLS)
if [ -e "$SECURE_DIR/tls" ]; then
   echo "Error: Destination '$SECURE_DIR/tls' already exists. Move operation aborted. (OK)"
else
   sudo mv "$BASE_DIR/tls" "$SECURE_DIR/tls"
   echo "Moved '$BASE_DIR/tls' to '$SECURE_DIR/tls'."
fi

# MOVE : Conf
echo -e "${YELLOW}**** Moving conf directory ****${NC}"
sudo rsync -a --delete $BASE_DIR/conf/ $SECURE_DIR/conf/

# load env file into the script's environment.
echo -e "${YELLOW}**** Set Up Environment ****${NC}"
source $SECURE_DIR/env/global/global-env.sh
source $SECURE_DIR/env/master/master-env.sh
source $SECURE_DIR/env/slave1/slave1-env.sh

### !!IF YOUR TLS/SSL EXPIRED!!
### -----------------------------------------------------
### Generate a new one by uncomment below and do sudo ./start again

# ----------
#cd $SECURE_DIR/tls && sudo chmod +x generate-new.sh && sudo ./generate-new.sh
# ----------

# And execute start.sh
# cd /etc/init.d
# sudo ./start.sh

### After that commented again to prevent generate new SSL
# nano /etc/init.d/start.sh
# and execute sudo ./start.sh again
### ------------------------------------------------------


### GENERATE =======================================================================
# Initdb
echo -e "${YELLOW}**** Executing initdb ****${NC}"
source $BASE_DIR/scripts/initdb.sh
sudo rsync -a --delete $BASE_DIR/scripts/initdb/ $SECURE_DIR/initdb/ # Moving initdb to secure_dir

# Create sudo docker global-secret
echo -e "${YELLOW}**** Executing global-secret.sh ****${NC}"
source $SECURE_DIR/env/global/global-secret.sh

# Generate encryption
echo -e "${YELLOW}**** Generating encryption ****${NC}"
source $SECURE_DIR/encryption/generate.sh
sudo chmod -R 755 $SECURE_DIR/encryption

# Generate CA certificate
echo -e "${YELLOW}**** Generating CA cert ****${NC}"
source $SECURE_DIR/tls/generate-ca.sh

# Generate CLIENT certificate
echo -e "${YELLOW}**** Generating Client cert ****${NC}"
source $SECURE_DIR/tls/generate-client.sh


### DEPLOY NODES =====================================================================
# Deploy master
echo -e "${YELLOW}**** Deploy container ${HOST_MASTER} ****${NC}"
source $SECURE_DIR/env/master/master-secret.sh
source $SECURE_DIR/tls/generate-master.sh
sudo mkdir -p $DATA_DIR/master && sudo chmod -R 755 $DATA_DIR/master  # Create directory data
sudo docker stack deploy --compose-file $NODES_DIR/master/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && sudo chmod +x healthcheck.sh && set -k && sudo -E ./healthcheck.sh host="$HOST_MASTER" user="root" pass="$MASTER_ROOT_PASSWORD"

# Deploy slave1
echo -e "${YELLOW}**** Deploy container ${HOST_SLAVE1} ****${NC}"
source $SECURE_DIR/env/slave1/slave1-secret.sh
source $SECURE_DIR/tls/generate-slave1.sh
sudo mkdir -p $DATA_DIR/slave1 && sudo chmod -R 755 $DATA_DIR/slave1  # Create directory data
sudo docker stack deploy --compose-file $NODES_DIR/slave1/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && sudo chmod +x healthcheck.sh && set -k && sudo -E ./healthcheck.sh host="$HOST_SLAVE1" user="root" pass="$SLAVE1_ROOT_PASSWORD"

# Resync replication
echo -e "${YELLOW}**** Start replication ****${NC}"
# Sync slave to master
cd $BASE_DIR/scripts && sudo chmod +x replica.sh && set -k && sudo -E ./replica.sh master_host="$HOST_MASTER" master_port="$PORT_MASTER" master_pass="$MASTER_ROOT_PASSWORD" host="$HOST_SLAVE1" user="root" pass="$SLAVE1_ROOT_PASSWORD"
# Sync master to slave (if master down)
cd $BASE_DIR/scripts && sudo chmod +x replica.sh && set -k && sudo -E ./replica.sh master_host="$HOST_SLAVE1" master_port="$PORT_SLAVE1" master_pass="$SLAVE1_ROOT_PASSWORD" host="$HOST_MASTER" user="root" pass="$MASTER_ROOT_PASSWORD"


### DEPLOY SERVICES ===================================================================
echo '**** Deploy services ****'

# Deploy MaxScale
echo -e "${YELLOW}**** Deploy maxscale container ****${NC}"
source $SECURE_DIR/tls/generate-maxscale.sh
source $SERVICE_DIR/maxscale/init.sh
sudo docker stack deploy --compose-file $SERVICE_DIR/maxscale/docker-compose.yaml --detach=false mariadb

# Deploy PMA
echo -e "${YELLOW}**** Deploy PMA container ****${NC}"
if [ -e "$SERVICE_ALT_DIR/pma" ]; then
   echo "Error: Destination '$SERVICE_ALT_DIR/pma' already exists. Move operation aborted. (OK)"
else
   sudo mv "$BASE_DIR/services/pma" "$SERVICE_ALT_DIR/pma"
   echo "Moved '$BASE_DIR/services/pma' to '$SERVICE_ALT_DIR/pma'."
fi
sudo docker stack deploy --compose-file $SERVICE_ALT_DIR/pma/docker-compose.yaml --detach=false mariadb

# Deploy backup
echo -e "${YELLOW}**** Deploy backup container ****${NC}"
sudo docker stack deploy --compose-file $SERVICE_DIR/backup/docker-compose.yaml --detach=false mariadb


### ADDITIONAL COMMANDS ===================================================================
# Enable startup service
echo -e "${YELLOW}**** Set auto startup mariadb service ****${NC}"
sudo rsync -a --delete $BASE_DIR/mariadb-repl.service /etc/systemd/system/mariadb-repl.service
sudo systemctl daemon-reload
sudo systemctl enable mariadb-repl.service

# Removing unnecessary files
echo -e "${YELLOW}**** Removing files ****${NC}"
sudo rm -rf $BASE_DIR

# Change atrributes
echo -e "${YELLOW}**** Changing attributes ****${NC}"
sudo chattr -R +a $SECURE_DIR

## Show list secrets
echo -e "${YELLOW}**** Secrets list ****${NC}"
sudo docker secret ls
#!/bin/bash

# Define color codes
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (reset to default)

# Define the absolute path to the data directory
BASE_DIR="/var/lib/mariadb"
NODES_DIR="/var/lib/mariadb/nodes"
SERVICE_DIR="/var/lib/mariadb/services"
SERVICE_ALT_DIR="/var/lib/mariadb_services"
DATA_DIR="/data/mariadb"
BACKUP_DIR="/backup/mariadb"
SECURE_DIR="/etc/secure/mariadb"
SHARED_VOLUME="" # Add ":z" if you using shared volume like /mnt blockstorage

# Create network
docker network create --driver overlay mariadb-network
docker network create --driver overlay traefik-network

# Stopping all services
docker stack rm mariadb

# CLONE : Check if the destination file/directory is exists (mariadb)
if [ -e "$BASE_DIR" ]; then
   echo "Error: Destination '$BASE_DIR' already exists. Move operation aborted. (OK)"
else
   mkdir -p $BASE_DIR
   cd $BASE_DIR
   git clone https://github.com/rendyproklamanta/docker-mariadb-replication-ssl.git .
fi

# Change atrributes
sudo chattr -R -a $SECURE_DIR
sudo chattr -R -a $DATA_DIR

# Create Directory
mkdir -p $DATA_DIR && chmod -R 755 $DATA_DIR
mkdir -p $BACKUP_DIR && chmod -R 755 $BACKUP_DIR
mkdir -p $SECURE_DIR && chmod -R 755 $SECURE_DIR
mkdir -p $SERVICE_ALT_DIR && chmod -R 755 $SERVICE_ALT_DIR

# Set directory
find "$BASE_DIR" -type f -exec sed -i "s|DATA_DIR_SET|$DATA_DIR|g" {} +
find "$BASE_DIR" -type f -exec sed -i "s|BACKUP_DIR_SET|$BACKUP_DIR|g" {} +
find "$BASE_DIR" -type f -exec sed -i "s|SECURE_DIR_SET|$SECURE_DIR|g" {} +
find "$BASE_DIR" -type f -exec sed -i "s| SHARED_VOLUME_SET|$SHARED_VOLUME|g" {} +

# MOVE : Check if the destination file/directory is exists (env)
if [ -e "$SECURE_DIR/env" ]; then
   echo "Error: Destination '$SECURE_DIR/env' already exists. Move operation aborted. (OK)"
else
   mv "$BASE_DIR/env" "$SECURE_DIR/env"
   echo "Moved '$BASE_DIR/env' to '$SECURE_DIR/env'."
fi

# MOVE : Check if the destination file/directory is exists (encryption)
if [ -e "$SECURE_DIR/encryption" ]; then
   echo "Error: Destination '$SECURE_DIR/encryption' already exists. Move operation aborted. (OK)"
else
   mv "$BASE_DIR/encryption" "$SECURE_DIR/encryption"
   echo "Moved '$BASE_DIR/encryption' to '$SECURE_DIR/encryption'."
fi

# MOVE : Check if the destination file/directory is exists (TLS)
if [ -e "$DATA_DIR/tls" ]; then
   echo "Error: Destination '$DATA_DIR/tls' already exists. Move operation aborted. (OK)"
else
   mv "$BASE_DIR/tls" "$DATA_DIR/tls"
   echo "Moved '$BASE_DIR/tls' to '$DATA_DIR/tls'."
fi

# MOVE : Conf
rm -rf $DATA_DIR/conf
mv $BASE_DIR/conf $DATA_DIR/conf

# load env file into the script's environment.
source $SECURE_DIR/env/global/global-env.sh
source $SECURE_DIR/env/master/master-env.sh
source $SECURE_DIR/env/slave1/slave1-env.sh

### !!IF YOUR TLS/SSL EXPIRED!!
### -----------------------------------------------------
### Generate a new one by uncomment below and do ./start again

#cd $DATA_DIR/tls && chmod +x generate-new.sh && ./generate-new.sh
#cd /etc/init.d
#./start.sh

### After that commented again to prevent generate new SSL
# nano /etc/init.d/start.sh
### ------------------------------------------------------

### GENERATE ----------------------------------------------
# Initdb
cd $BASE_DIR/scripts && chmod +x initdb.sh && ./initdb.sh

# MOVE : initdb
rm -rf $DATA_DIR/initdb
mv $BASE_DIR/scripts/initdb $DATA_DIR/initdb

# Create docker global-secret
cd $SECURE_DIR/env/global && chmod +x global-secret.sh && ./global-secret.sh 

# Generate encryption
cd $SECURE_DIR/encryption && chmod +x generate.sh && ./generate.sh && chmod -R 755 $SECURE_DIR/encryption

# Generate CA certificate
cd $DATA_DIR/tls && chmod +x generate-ca.sh && ./generate-ca.sh
chmod -R 755 $DATA_DIR/tls # Change permission to TLS directory after generated

# Generate CLIENT certificate
cd $DATA_DIR/tls && chmod +x generate-client.sh && ./generate-client.sh
chmod -R 755 $DATA_DIR/tls # Change permission to TLS directory after generated
### END OF GENERATE ----------------------------------------

# Deploy master
echo -e "${YELLOW}**** Deploy container master ****${NC}"
cd $SECURE_DIR/env/master && chmod +x master-secret.sh && ./master-secret.sh # Create docker secrets
cd $DATA_DIR/tls && chmod +x generate-master.sh && ./generate-master.sh # Generate certificate
chmod -R 755 $DATA_DIR/tls # Change permission to TLS directory after generated
mkdir -p $DATA_DIR/master && chmod -R 755 $DATA_DIR/master  # Create directory data
docker stack deploy --compose-file $NODES_DIR/master/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && chmod +x healthcheck.sh && set -k && ./healthcheck.sh host="$HOST_MASTER" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# Deploy slave1
echo -e "${YELLOW}**** Deploy container slave1 ****${NC}"
cd $SECURE_DIR/env/slave1 && chmod +x slave1-secret.sh && ./slave1-secret.sh # Create docker secrets
cd $DATA_DIR/tls && chmod +x generate-slave1.sh && ./generate-slave1.sh # Generate certificate
chmod -R 755 $DATA_DIR/tls # Change permission to TLS directory after generated
mkdir -p $DATA_DIR/slave1 && chmod -R 755 $DATA_DIR/slave1  # Create directory data
docker stack deploy --compose-file $NODES_DIR/slave1/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && chmod +x healthcheck.sh && set -k && ./healthcheck.sh host="$HOST_SLAVE1" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# Resync replication
echo -e "${YELLOW}**** Resync replication ****${NC}"
# Sync slave to master
cd $BASE_DIR/scripts && chmod +x replica.sh && set -k && ./replica.sh master_host="$HOST_MASTER" master_port="$PORT_MASTER" host="$HOST_SLAVE1" port="$PORT_SLAVE1" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"
# Sync master to slave (if master down)
cd $BASE_DIR/scripts && chmod +x replica.sh && set -k && ./replica.sh master_host="$HOST_SLAVE1" master_port="$PORT_SLAVE1" host="$HOST_MASTER" port="$PORT_MASTER" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# -----------------------------------------------------------------------

echo '**** Deploy services ****'

# Deploy MaxScale
echo -e "${YELLOW}**** Deploy maxscale container ****${NC}"
cd $DATA_DIR/tls && chmod +x generate-maxscale.sh && ./generate-maxscale.sh # Generate certificate
chmod -R 755 $DATA_DIR/tls # Change permission to TLS directory after generated
mkdir -p /var/log/maxscale && touch /var/log/maxscale/maxscale.log && chmod -R 777 /var/log/maxscale/maxscale.log # Create log
if [ -e "$SERVICE_ALT_DIR/maxscale" ]; then
   echo "Error: Destination '$SERVICE_ALT_DIR/maxscale' already exists. Move operation aborted. (OK)"
else
   mv "$BASE_DIR/services/maxscale" "$SERVICE_ALT_DIR/maxscale"
   echo "Moved '$BASE_DIR/services/maxscale' to '$SERVICE_ALT_DIR/maxscale'."
fi
docker stack deploy --compose-file $SERVICE_ALT_DIR/maxscale/docker-compose.yaml --detach=false mariadb

# Deploy PMA
echo -e "${YELLOW}**** Deploy PMA container ****${NC}"
if [ -e "$SERVICE_ALT_DIR/pma" ]; then
   echo "Error: Destination '$SERVICE_ALT_DIR/pma' already exists. Move operation aborted. (OK)"
else
   mv "$BASE_DIR/services/pma" "$SERVICE_ALT_DIR/pma"
   echo "Moved '$BASE_DIR/services/pma' to '$SERVICE_ALT_DIR/pma'."
fi
docker stack deploy --compose-file $SERVICE_ALT_DIR/pma/docker-compose.yaml --detach=false mariadb

# Deploy backup
echo -e "${YELLOW}**** Deploy backup container ****${NC}"
docker stack deploy --compose-file $SERVICE_DIR/backup/docker-compose.yaml --detach=false mariadb

# Enable startup service
echo -e "${YELLOW}**** Set auto startup mariadb service ****${NC}"
cp $BASE_DIR/mariadb-repl.service /etc/systemd/system/mariadb-repl.service
sudo systemctl enable mariadb-repl.service

# Removing unnecessary files
rm -rf $BASE_DIR

# Change atrributes
sudo chattr -R +a $SECURE_DIR
sudo chattr -R +a $DATA_DIR
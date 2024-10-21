#!/bin/bash

# Define color codes
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (reset to default)

# Define the absolute path to the data directory
BASE_DIR="/var/lib/mariadb"
DATA_DIR="/data/mariadb"
BACKUP_DIR="/backup/mariadb"

# load env file into the script's environment.
source $BASE_DIR/env/global/global-env.sh
source $BASE_DIR/env/master/master-env.sh
source $BASE_DIR/env/slave1/slave1-env.sh

# Create network
docker network create --driver overlay mariadb-network

# Change atrributes
sudo chattr -R -a $BASE_DIR
sudo chattr -R -a $DATA_DIR

# Stopping all services
docker stack rm mariadb

# ---------------------------------------------------------------------

# Create Directory Data
mkdir -p $DATA_DIR && chmod -R 755 $DATA_DIR

# Check if the destination file/directory is exists (env)
if [ -e "$DATA_DIR/env" ]; then
   echo "Error: Destination '$DATA_DIR/env' already exists. Move operation aborted."
else
   mv "$BASE_DIR/env" "$DATA_DIR/env"
   echo "Moved '$BASE_DIR/env' to '$DATA_DIR/env'."
fi

# Check if the destination file/directory is exists (encryption)
if [ -e "$DATA_DIR/encryption" ]; then
   echo "Error: Destination '$DATA_DIR/encryption' already exists. Move operation aborted."
else
   mv "$BASE_DIR/encryption" "$DATA_DIR/encryption"
   echo "Moved '$BASE_DIR/encryption' to '$DATA_DIR/encryption'."
fi

# Check if the destination file/directory is exists (TLS)
if [ -e "$DATA_DIR/tls" ]; then
   echo "Error: Destination '$DATA_DIR/tls' already exists. Move operation aborted."
else
   mv "$BASE_DIR/tls" "$DATA_DIR/tls"
   echo "Moved '$BASE_DIR/tls' to '$DATA_DIR/tls'."
fi

### !!IF YOUR TLS/SSL EXPIRED!!
### -----------------------------------------------------
### Generate a new one by uncomment below and do ./start again

#cd $DATA_DIR/tls && chmod +x generate-new.sh && ./generate-new.sh
#cd /etc/init.d
#./start.sh

### After that commented again to prevent generate new SSL
# nano /etc/init.d/start.sh
### ------------------------------------------------------

# Removing unnecessary files
rm -rf $BASE_DIR/README.md || true
rm -rf $BASE_DIR/start.sh || true
rm -rf $BASE_DIR/env || true
rm -rf $BASE_DIR/encryption || true
rm -rf $BASE_DIR/tls || true

### GENERATE ----------------------------------------------
# Create docker global-secret
cd $DATA_DIR/env/global && chmod +x global-secret.sh && ./global-secret.sh 

# Initdb
cd $BASE_DIR/scripts && chmod +x initdb.sh && ./initdb.sh

# Generate encryption
cd $DATA_DIR/encryption && chmod +x generate.sh && ./generate.sh && chmod -R 755 $DATA_DIR/encryption

# Generate CA certificate
cd $DATA_DIR/tls && chmod +x generate-ca.sh && ./generate-ca.sh

# Generate CLIENT certificate
cd $DATA_DIR/tls && chmod +x generate-client.sh && ./generate-client.sh
### END OF GENERATE ----------------------------------------

# Deploy master
echo -e "${YELLOW}**** Deploy container master ****${NC}"
cd $DATA_DIR/env/master && chmod +x master-secret.sh && ./master-secret.sh # Create docker secrets
cd $DATA_DIR/tls && chmod +x generate-master.sh && ./generate-master.sh # Generate certificate
mkdir -p $DATA_DIR/master && chmod -R 755 $DATA_DIR/master  # Create directory data
docker stack deploy --compose-file $BASE_DIR/nodes/master/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && chmod +x healthcheck.sh && set -k && ./healthcheck.sh host="$HOST_MASTER" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# Deploy slave1
echo -e "${YELLOW}**** Deploy container slave1 ****${NC}"
cd $DATA_DIR/env/slave1 && chmod +x slave1-secret.sh && ./slave1-secret.sh # Create docker secrets
cd $DATA_DIR/tls && chmod +x generate-slave1.sh && ./generate-slave1.sh # Generate certificate
mkdir -p $DATA_DIR/slave1 && chmod -R 755 $DATA_DIR/slave1  # Create directory data
docker stack deploy --compose-file $BASE_DIR/nodes/slave1/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && chmod +x healthcheck.sh && set -k && ./healthcheck.sh host="$HOST_SLAVE1" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# Change permission to TLS directory after generated
chmod -R 755 $DATA_DIR/tls

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
mkdir -p /var/log/maxscale && touch /var/log/maxscale/maxscale.log && chmod -R 777 /var/log/maxscale/maxscale.log # Create log
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

# Change atrributes
sudo chattr -R +a $BASE_DIR
sudo chattr -R +a $DATA_DIR
#!/bin/bash

# Define color codes
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (reset to default)

# Define the absolute path to the data directory
BASE_DIR="/var/lib/mariadb"
DATA_DIR="/data/mariadb"
BACKUP_DIR="/backup/mariadb"
SECURE_DIR="/etc/secure/mariadb"
SERVICE_DIR="/var/lib/mariadb_services"
NODES_DIR="/var/lib/mariadb_nodes"

# Create network
docker network create --driver overlay mariadb-network

# CLONE : Check if the destination file/directory is exists (mariadb)
if [ -e "$BASE_DIR" ]; then
   echo "Error: Destination '$BASE_DIR' already exists. Move operation aborted."
else
   mkdir -p $BASE_DIR
   cd $BASE_DIR
   git clone https://github.com/rendyproklamanta/docker-mariadb-replication-ssl.git .
fi

# Change atrributes
sudo chattr -R -a $DATA_DIR

# Stopping all services
docker stack rm mariadb

# Create Directory ta
mkdir -p $DATA_DIR && chmod -R 755 $DATA_DIR
mkdir -p $BACKUP_DIR && chmod -R 755 $BACKUP_DIR
mkdir -p $SECURE_DIR && chmod -R 755 $SECURE_DIR
mkdir -p $SERVICE_DIR && chmod -R 755 $SERVICE_DIR
mkdir -p $NODES_DIR && chmod -R 755 $NODES_DIR

# load env file into the script's environment.
source $SECURE_DIR/env/global/global-env.sh
source $SECURE_DIR/env/master/master-env.sh
source $SECURE_DIR/env/slave1/slave1-env.sh

# MOVE : Check if the destination file/directory is exists (env)
if [ -e "$SECURE_DIR/env" ]; then
   echo "Error: Destination '$SECURE_DIR/env' already exists. Move operation aborted."
else
   mv "$BASE_DIR/env" "$SECURE_DIR/env"
   echo "Moved '$BASE_DIR/env' to '$SECURE_DIR/env'."
fi

# MOVE : Check if the destination file/directory is exists (encryption)
if [ -e "$SECURE_DIR/encryption" ]; then
   echo "Error: Destination '$SECURE_DIR/encryption' already exists. Move operation aborted."
else
   mv "$BASE_DIR/encryption" "$SECURE_DIR/encryption"
   echo "Moved '$BASE_DIR/encryption' to '$SECURE_DIR/encryption'."
fi

# MOVE : Check if the destination file/directory is exists (TLS)
if [ -e "$DATA_DIR/tls" ]; then
   echo "Error: Destination '$DATA_DIR/tls' already exists. Move operation aborted."
else
   mv "$BASE_DIR/tls" "$DATA_DIR/tls"
   echo "Moved '$BASE_DIR/tls' to '$DATA_DIR/tls'."
fi

# MOVE : Conf
mv $BASE_DIR/conf $DATA_DIR/conf

# Initdb
cd $DATA_DIR/scripts && chmod +x initdb.sh && ./initdb.sh

# MOVE : initdb
mv $BASE_DIR/scripts/initdb $DATA_DIR/initdb

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
# Create directory nodes
if [ -e "$NODES_DIR/master" ]; then
   echo "Error: Destination '$NODES_DIR/master' already exists. Move operation aborted."
else
   mv "$BASE_DIR/nodes/master" "$NODES_DIR/master"
   echo "Moved '$BASE_DIR/nodes/master' to '$NODES_DIR/master'."
fi
docker stack deploy --compose-file $NODES_DIR/master/docker-compose.yaml --detach=false mariadb
cd $BASE_DIR/scripts && chmod +x healthcheck.sh && set -k && ./healthcheck.sh host="$HOST_MASTER" user="$SUPER_USERNAME" pass="$SUPER_PASSWORD"

# Deploy slave1
echo -e "${YELLOW}**** Deploy container slave1 ****${NC}"
cd $SECURE_DIR/env/slave1 && chmod +x slave1-secret.sh && ./slave1-secret.sh # Create docker secrets
cd $DATA_DIR/tls && chmod +x generate-slave1.sh && ./generate-slave1.sh # Generate certificate
chmod -R 755 $DATA_DIR/tls # Change permission to TLS directory after generated
mkdir -p $DATA_DIR/slave1 && chmod -R 755 $DATA_DIR/slave1  # Create directory data
# Create directory nodes
if [ -e "$NODES_DIR/slave1" ]; then
   echo "Error: Destination '$NODES_DIR/slave1' already exists. Move operation aborted."
else
   mv "$BASE_DIR/nodes/slave1" "$NODES_DIR/slave1"
   echo "Moved '$BASE_DIR/nodes/slave1' to '$NODES_DIR/slave1'."
fi
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
if [ -e "$SERVICE_DIR/maxscale" ]; then
   echo "Error: Destination '$SERVICE_DIR/maxscale' already exists. Move operation aborted."
else
mv $BASE_DIR/services/maxscale $SERVICE_DIR/maxscale
   echo "Moved '$BASE_DIR/services/maxscale' to '$SERVICE_DIR/maxscale'."
fi
cd $DATA_DIR/tls && chmod +x generate-maxscale.sh && ./generate-maxscale.sh # Generate certificate
chmod -R 755 $DATA_DIR/tls # Change permission to TLS directory after generated
mkdir -p /var/log/maxscale && touch /var/log/maxscale/maxscale.log && chmod -R 777 /var/log/maxscale/maxscale.log # Create log
docker stack deploy --compose-file $SERVICE_DIR/maxscale/docker-compose.yaml --detach=false mariadb

# Deploy backup
echo -e "${YELLOW}**** Deploy backup container ****${NC}"
if [ -e "$SERVICE_DIR/backup" ]; then
   echo "Error: Destination '$SERVICE_DIR/backup' already exists. Move operation aborted."
else
   mv $BASE_DIR/services/backup $SERVICE_DIR/backup
   echo "Moved '$BASE_DIR/services/backup' to '$SERVICE_DIR/backup'."
fi
docker stack deploy --compose-file $SERVICE_DIR/backup/docker-compose.yaml --detach=false mariadb

# Deploy PMA
echo -e "${YELLOW}**** Deploy PMA container ****${NC}"
if [ -e "$SERVICE_DIR/pma" ]; then
   echo "Error: Destination '$SERVICE_DIR/pma' already exists. Move operation aborted."
else
   mv "$BASE_DIR/services/pma" "$SERVICE_DIR/pma"
   echo "Moved '$BASE_DIR/services/pma' to '$SERVICE_DIR/pma'."
fi
docker stack deploy --compose-file $SERVICE_DIR/pma/docker-compose.yaml --detach=false mariadb

# Enable startup service
echo -e "${YELLOW}**** Set auto startup mariadb service ****${NC}"
cp $BASE_DIR/mariadb-repl.service /etc/systemd/system/mariadb-repl.service
sudo systemctl enable mariadb-repl.service

# Removing unnecessary files
rm -rf $BASE_DIR

# Change atrributes
sudo chattr -R +a $SECURE_DIR
sudo chattr -R +a $DATA_DIR
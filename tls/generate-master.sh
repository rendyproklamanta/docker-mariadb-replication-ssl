#!/bin/bash

sudo update-ca-certificates

# Set variable
MASTER_CN="mariadb_master"
EXPIRY_DAY="3650" # 10 years
generate_new=${generate_new:-false}

### MASTER ###
if [ "$generate_new" = true ] || [ ! -f master-server-key.pem ] || [ ! -f master-server-cert.pem ]; then
   echo "Generating master server certificate..."
   openssl genrsa -out master-server-key.pem 2048
   openssl req -new -key master-server-key.pem -out master-server-req.pem -subj "/CN=$MASTER_CN"
   openssl x509 -req -in master-server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out master-server-cert.pem -days $EXPIRY_DAY -sha256
   rm -f master-server-req.pem
else
   echo "Master server certificate already exists, skipping."
fi

find . -type f -exec chmod 755 {} \;

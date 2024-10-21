#!/bin/bash

sudo update-ca-certificates

# Set variable
SLAVE1_CN="mariadb_mariadb-slave1"
EXPIRY_DAY="3650" # 10 years
generate_new=${generate_new:-false}

### SLAVE1 ###
if [ "$generate_new" = true ] || [ ! -f slave1-server-key.pem ] || [ ! -f slave1-server-cert.pem ]; then
   echo "Generating slave1 server certificate..."
   openssl genrsa -out slave1-server-key.pem 2048
   openssl req -new -key slave1-server-key.pem -out slave1-server-req.pem -subj "/CN=$SLAVE1_CN"
   openssl x509 -req -in slave1-server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out slave1-server-cert.pem -days $EXPIRY_DAY -sha256
   rm -f slave1-server-req.pem
else
   echo "Slave1 server certificate already exists, skipping."
fi
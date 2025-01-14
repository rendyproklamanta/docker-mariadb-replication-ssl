#!/bin/bash

sudo update-ca-certificates

# Set variable
CLIENT_CN="mariadb_client"
EXPIRY_DAY="3650" # 10 years
generate_new=${generate_new:-false}

### CLIENT ###
if [ "$generate_new" = true ] || [ ! -f client-key.pem ] || [ ! -f client-cert.pem ]; then
   echo "Generating client certificate..."
   sudo openssl genrsa -out client-key.pem 2048
   sudo openssl req -new -key client-key.pem -out client-req.pem -subj "/CN=$CLIENT_CN"
   sudo openssl x509 -req -in client-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -days $EXPIRY_DAY -sha256
   rm -f client-req.pem
else
   echo "Client certificate already exists, skipping."
fi

sudo find . -type f -exec chmod 755 {} \;

#!/bin/bash

sudo update-ca-certificates

# Set variable
MAXSCALE_CN="mariadb_maxscale"
EXPIRY_DAY="3650" # 10 years
generate_new=${generate_new:-false}

### MAXSCALE ###
if [ "$generate_new" = true ] || [ ! -f maxscale-key.pem ] || [ ! -f maxscale-cert.pem ]; then
   echo "Generating MaxScale certificate..."
   openssl genrsa -out maxscale-key.pem 2048
   openssl req -new -key maxscale-key.pem -out maxscale-req.pem -subj "/CN=$MAXSCALE_CN"
   openssl x509 -req -in maxscale-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out maxscale-cert.pem -days $EXPIRY_DAY -sha256
   rm -f maxscale-req.pem
else
   echo "MaxScale certificate already exists, skipping."
fi

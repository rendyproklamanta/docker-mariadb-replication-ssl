#!/bin/bash

sudo update-ca-certificates

# Set variable
CA_CN="mariadb_ca"
EXPIRY_DAY="3650" # 10 years
generate_new=${generate_new:-false}

# Generate the CA certificate
if [ "$generate_new" = true ] || [ ! -f ca-key.pem ] || [ ! -f ca-cert.pem ]; then
   echo "Generating CA certificate..."
   sudo openssl genrsa -out ca-key.pem 2048
   sudo openssl req -new -x509 -nodes -days $EXPIRY_DAY -key ca-key.pem -out ca-cert.pem -subj "/CN=$CA_CN"
else
   echo "CA certificate already exists, skipping."
fi

sudo find . -type f -exec chmod 755 {} \;

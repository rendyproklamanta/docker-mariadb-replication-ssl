#!/bin/bash

sudo update-ca-certificates

# Define the absolute path to the script directory
BASE_DIR="/var/lib/mariadb"

# Common Name (CN) for the CA, server, and client
CA_CN="mariadb_ca"
CLIENT_CN="mariadb_client"
MAXSCALE_CN="mariadb_maxscale"
MASTER_CN="mariadb_mariadb-master"
SLAVE1_CN="mariadb_mariadb-slave1"
EXPIRY_DAY="$EXPIRY_DAY"

# Generate the CA certificate
openssl genrsa -out ca-key.pem 2048
openssl req -new -x509 -nodes -days $EXPIRY_DAY -key ca-key.pem -out ca-cert.pem -subj "/CN=$CA_CN"

### CLIENT ###
openssl genrsa -out client-key.pem 2048
openssl req -new -key client-key.pem -out client-req.pem -subj "/CN=$CLIENT_CN"
openssl x509 -req -in client-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -days $EXPIRY_DAY -sha256

### MASTER ###
# Generate server key and certificate for the MariaDB master
openssl genrsa -out master-server-key.pem 2048
openssl req -new -key master-server-key.pem -out master-server-req.pem -subj "/CN=$MASTER_CN"
openssl x509 -req -in master-server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out master-server-cert.pem -days $EXPIRY_DAY -sha256

### SLAVE1 ###
# Generate server key and certificate for the MariaDB slave
openssl genrsa -out slave1-server-key.pem 2048
openssl req -new -key slave1-server-key.pem -out slave1-server-req.pem -subj "/CN=$SLAVE1_CN"
openssl x509 -req -in slave1-server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out slave1-server-cert.pem -days $EXPIRY_DAY -sha256

### MAXSCALE ###
# Generate server key and certificate for MaxScale
openssl genrsa -out maxscale-key.pem 2048
openssl req -new -key maxscale-key.pem -out maxscale-req.pem -subj "/CN=$MAXSCALE_CN"
openssl x509 -req -in maxscale-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out maxscale-cert.pem -days $EXPIRY_DAY -sha256

# Clean up certificate requests
rm -f *-req.pem

# Set permissions for the TLS directory
chmod -R 777 $BASE_DIR/tls
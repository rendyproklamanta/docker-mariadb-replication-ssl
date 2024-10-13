#!/bin/bash

# Define the absolute path to the script directory
BASE_DIR="/var/lib/mariadb"

# Generate the CA certificate
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 365 -key ca-key.pem -out ca-cert.pem -subj "/CN=mariadb_ssl_CA"

# Generate the server key and certificate
openssl req -newkey rsa:2048 -days 365 -nodes -keyout server-key.pem -out server-req.pem -subj "/CN=mariadb_ssl_server"
openssl rsa -in server-key.pem -out server-key.pem
openssl x509 -req -in server-req.pem -days 365 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

# Generate the client key and certificate
openssl req -newkey rsa:2048 -days 365 -nodes -keyout client-key.pem -out client-req.pem -subj "/CN=mariadb_ssl_client"
openssl rsa -in client-key.pem -out client-key.pem
openssl x509 -req -in client-req.pem -days 365 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem

# Generate the MaxScale key and certificate
openssl req -newkey rsa:2048 -days 365 -nodes -keyout maxscale-key.pem -out maxscale-req.pem -subj "/CN=mariadb_ssl_maxscale"
openssl rsa -in maxscale-key.pem -out maxscale-key.pem
openssl x509 -req -in maxscale-req.pem -days 365 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out maxscale-cert.pem

# Remove request
rm -rf *-req.pem

# Copy directory certs to each nodes and maxscale
rsync -av --exclude='generate.sh' $BASE_DIR/certs $BASE_DIR/nodes/master/certs
rsync -av --exclude='generate.sh' $BASE_DIR/certs $BASE_DIR/nodes/master/certs
rsync -av --exclude='generate.sh' $BASE_DIR/certs $BASE_DIR/services/maxscale/certs
rsync -av --exclude='generate.sh' $BASE_DIR/certs $BASE_DIR/services/pma/certs
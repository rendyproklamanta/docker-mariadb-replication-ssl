#!/bin/bash

# Define the absolute path to the script directory
BASE_DIR="/var/lib/mariadb"

# Common Name (CN) for the CA, server, and client
CA_CN="mariadb_ca"
CLIENT_CN="mariadb_client"
MAXSCALE_CN="mariadb_maxscale"
SERVER_CN="db.domain.com" # Change with your domain

# Generate the CA certificate (used to sign both client and server certificates)
openssl genrsa -out ca-key.pem 2048
openssl req -new -x509 -nodes -days 365 -key ca-key.pem -out ca-cert.pem -subj "/CN=$CA_CN"

# Generate the server key and certificate for db.domain.com
openssl genrsa -out server-key.pem 2048
openssl req -new -key server-key.pem -out server-req.pem -subj "/CN=$SERVER_CN"
openssl x509 -req -in server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -days 365 -sha256

# Generate the client key and certificate for MyClient
openssl genrsa -out client-key.pem 2048
openssl req -new -key client-key.pem -out client-req.pem -subj "/CN=$CLIENT_CN"
openssl x509 -req -in client-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -days 365 -sha256

# Generate the MaxScale key and certificate
openssl genrsa -out maxscale-key.pem 2048
openssl req -new -key maxscale-key.pem -out maxscale-req.pem -subj "/CN=$MAXSCALE_CN"
openssl x509 -req -in maxscale-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out maxscale-cert.pem -days 365 -sha256

# Clean up certificate requests
rm -f *-req.pem

# Set permissions for the TLS directory
chmod -R 777 $BASE_DIR/tls

# Copy directory tls to each nodes and maxscale
rsync -av --include='*/' --include='*.pem' --exclude='*' $BASE_DIR/tls/ $BASE_DIR/nodes/master/tls/
rsync -av --include='*/' --include='*.pem' --exclude='*' $BASE_DIR/tls/ $BASE_DIR/nodes/slave1/tls/
rsync -av --include='*/' --include='*.pem' --exclude='*' $BASE_DIR/tls/ $BASE_DIR/services/maxscale/tls/
rsync -av --include='*/' --include='*.pem' --exclude='*' $BASE_DIR/tls/ $BASE_DIR/services/pma/tls/
rsync -av --include='*/' --include='*.pem' --exclude='*' $BASE_DIR/tls/ $BASE_DIR/services/backup/tls/

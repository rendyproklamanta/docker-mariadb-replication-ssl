#!/bin/bash

sudo update-ca-certificates

# Common Name (CN) for the CA, server, and client
CA_CN="mariadb_ca"
CLIENT_CN="mariadb_client"
MAXSCALE_CN="mariadb_maxscale"
MASTER_CN="mariadb_mariadb-master"
SLAVE1_CN="mariadb_mariadb-slave1"
EXPIRY_DAY="3650" # 10 years

# Generate the CA certificate
if [ ! -f ca-key.pem ] || [ ! -f ca-cert.pem ]; then
   echo "Generating CA certificate..."
   openssl genrsa -out ca-key.pem 2048
   openssl req -new -x509 -nodes -days $EXPIRY_DAY -key ca-key.pem -out ca-cert.pem -subj "/CN=$CA_CN"
else
   echo "CA certificate already exists, skipping."
fi

### CLIENT ###
if [ ! -f client-key.pem ] || [ ! -f client-cert.pem ]; then
   echo "Generating client certificate..."
   openssl genrsa -out client-key.pem 2048
   openssl req -new -key client-key.pem -out client-req.pem -subj "/CN=$CLIENT_CN"
   openssl x509 -req -in client-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -days $EXPIRY_DAY -sha256
   rm -f client-req.pem
else
   echo "Client certificate already exists, skipping."
fi

### MASTER ###
if [ ! -f master-server-key.pem ] || [ ! -f master-server-cert.pem ]; then
   echo "Generating master server certificate..."
   openssl genrsa -out master-server-key.pem 2048
   openssl req -new -key master-server-key.pem -out master-server-req.pem -subj "/CN=$MASTER_CN"
   openssl x509 -req -in master-server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out master-server-cert.pem -days $EXPIRY_DAY -sha256
   rm -f master-server-req.pem
else
   echo "Master server certificate already exists, skipping."
fi

### SLAVE1 ###
if [ ! -f slave1-server-key.pem ] || [ ! -f slave1-server-cert.pem ]; then
   echo "Generating slave1 server certificate..."
   openssl genrsa -out slave1-server-key.pem 2048
   openssl req -new -key slave1-server-key.pem -out slave1-server-req.pem -subj "/CN=$SLAVE1_CN"
   openssl x509 -req -in slave1-server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out slave1-server-cert.pem -days $EXPIRY_DAY -sha256
   rm -f slave1-server-req.pem
else
   echo "Slave1 server certificate already exists, skipping."
fi

### MAXSCALE ###
if [ ! -f maxscale-key.pem ] || [ ! -f maxscale-cert.pem ]; then
   echo "Generating MaxScale certificate..."
   openssl genrsa -out maxscale-key.pem 2048
   openssl req -new -key maxscale-key.pem -out maxscale-req.pem -subj "/CN=$MAXSCALE_CN"
   openssl x509 -req -in maxscale-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out maxscale-cert.pem -days $EXPIRY_DAY -sha256
   rm -f maxscale-req.pem
else
   echo "MaxScale certificate already exists, skipping."
fi

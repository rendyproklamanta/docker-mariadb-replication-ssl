#!/bin/bash

# Define the variables
BASE_DIR="/var/lib/mariadb"
EXPIRY_DAY="365"
CLIENT_CN="db.secure.myfkc.com"
MAXSCALE_CN="mariadb_maxscale"
LE_KEY_PATH="/etc/letsencrypt/live/db.secure.myfkc.com/privkey.pem"
LE_CA_PATH="/etc/letsencrypt/live/db.secure.myfkc.com/fullchain.pem"

# Generate client
openssl genpkey -algorithm RSA -out client-key.pem
openssl req -new -key client-key.pem -out client-req.pem -subj "/CN=$CLIENT_CN"
openssl x509 -req -in client-req.pem \
-CA $LE_CA_PATH \
-CAkey $LE_KEY_PATH \
-CAcreateserial -out client-cert.pem -days $EXPIRY_DAY

# Generate the MaxScale key and certificate
openssl genpkey -algorithm RSA -out maxscale-key.pem
openssl req -new -key maxscale-key.pem -out maxscale-req.pem -subj "/CN=$MAXSCALE_CN"
openssl x509 -req -in maxscale-req.pem \
-CA $LE_CA_PATH \
-CAkey $LE_KEY_PATH \
-CAcreateserial -out maxscale-cert.pem -days $EXPIRY_DAY

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

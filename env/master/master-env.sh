#!/bin/bash

# MASTER environment
export HOST_MASTER="mariadb_master"
export PORT_MASTER="3301"

SAVED_ENV_MASTER="./master-env.saved"

if [ -f "$SAVED_ENV_MASTER" ]; then
   source "$SAVED_ENV_MASTER"
else
   # Function to generate random passwords
   generate_password() {
      tr -dc 'A-Za-z0-9' </dev/urandom | head -c20
   }

   export MASTER_ROOT_PASSWORD="$(generate_password)"

# Save all exports to the file
cat > "$SAVED_ENV_MASTER" <<EOF
export MASTER_ROOT_PASSWORD="$MASTER_ROOT_PASSWORD"
EOF
fi
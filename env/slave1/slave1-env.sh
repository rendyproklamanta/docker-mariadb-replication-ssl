#!/bin/bash

# SLAVE1 environment
export HOST_SLAVE1="mariadb_slave1"
export PORT_SLAVE1="3302"

SAVED_ENV_SLAVE1="./slave1-env.saved"

if [ -f "$SAVED_ENV_SLAVE1" ]; then
   source "$SAVED_ENV_SLAVE1"
else
   # Function to generate random passwords
   generate_password() {
      tr -dc 'A-Za-z0-9' </dev/urandom | head -c20
   }

   export SLAVE1_ROOT_PASSWORD="$(generate_password)"

# Save all exports to the file
cat > "$SAVED_ENV_SLAVE1" <<EOF
export SLAVE1_ROOT_PASSWORD="$SLAVE1_ROOT_PASSWORD"
EOF
fi
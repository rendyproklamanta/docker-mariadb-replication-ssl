#!/bin/bash

# Set Timezone
export TIMEZONE="Asia/jakarta"

# Generate and export credentials
export REPL_USERNAME="repl"
export MAXSCALE_USERNAME="max_usr"
export MAXSCALE_PORT="60330"
export SUPERADMIN_USERNAME="super_adm"
export SUPERUSER_USERNAME="super_usr"

SAVED_ENV_GLOBAL="./global-env.saved"

if [ -f "$SAVED_ENV_GLOBAL" ]; then
   source "$SAVED_ENV_GLOBAL"
else
   # Function to generate random passwords
   generate_password() {
      tr -dc 'A-Za-z0-9' </dev/urandom | head -c20
   }

   export REPL_PASSWORD="$(generate_password)"
   export MAXSCALE_PASSWORD="$(generate_password)"
   export SUPERADMIN_PASSWORD="$(generate_password)"
   export SUPERUSER_PASSWORD="$(generate_password)"

# Save all exports to the file
cat > "$SAVED_ENV_GLOBAL" <<EOF
export REPL_PASSWORD="$REPL_PASSWORD"
export MAXSCALE_PASSWORD="$MAXSCALE_PASSWORD"
export SUPERADMIN_PASSWORD="$SUPERADMIN_PASSWORD"
export SUPERUSER_PASSWORD="$SUPERUSER_PASSWORD"
EOF
fi
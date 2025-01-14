#!/bin/bash

sudo mkdir -p $BASE_DIR/scripts/initdb

# Generate the init.sql file for user replica
sudo tee "$BASE_DIR/scripts/initdb/01-init.sql" > /dev/null <<EOF
-- Set the global time zone
SET GLOBAL time_zone = '$TIMEZONE';

-- Create replication user if it doesn't exist
CREATE USER IF NOT EXISTS '$REPL_USERNAME'@'%' IDENTIFIED BY '$REPL_PASSWORD' REQUIRE SSL;
ALTER USER '$REPL_USERNAME'@'%' IDENTIFIED BY '$REPL_PASSWORD';

-- Grant replication slave privileges to the user
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USERNAME'@'%';

-- Create user for monitor maxscale
CREATE USER IF NOT EXISTS '$MAXSCALE_USERNAME'@'%' IDENTIFIED BY '$MAXSCALE_PASSWORD' REQUIRE SSL;
ALTER USER '$MAXSCALE_USERNAME'@'%' IDENTIFIED BY '$MAXSCALE_PASSWORD';

-- Grant specific privileges for MaxScale
GRANT SELECT ON mysql.* TO '$MAXSCALE_USERNAME'@'%';

-- Additional grants for MaxScale with necessary permissions
GRANT BINLOG ADMIN,
      READ_ONLY ADMIN,
      RELOAD,
      REPLICA MONITOR,
      REPLICATION MASTER ADMIN,
      REPLICATION REPLICA ADMIN,
      REPLICATION REPLICA,
      BINLOG MONITOR,
      SHOW DATABASES
   ON *.* TO '$MAXSCALE_USERNAME'@'%';

-- Create new user for super admin
CREATE USER IF NOT EXISTS '$SUPERADMIN_USERNAME'@'%' IDENTIFIED BY '$SUPERADMIN_PASSWORD' REQUIRE SSL;
GRANT ALL PRIVILEGES ON *.* TO '$SUPERADMIN_USERNAME'@'%' WITH GRANT OPTION;

-- Create new user for app and limit privilege
CREATE USER IF NOT EXISTS '$SUPERUSER_USERNAME'@'%' IDENTIFIED BY '$SUPERUSER_PASSWORD' REQUIRE SSL;
GRANT ALL PRIVILEGES ON *.* TO '$SUPERUSER_USERNAME'@'%' WITH GRANT OPTION;
REVOKE DELETE, DROP ON *.* FROM '$SUPERUSER_USERNAME'@'%';

-- Lock user root for remote access for security
ALTER USER 'root'@'%' ACCOUNT LOCK;

-- Apply the privilege changes
FLUSH PRIVILEGES;
EOF

echo -e "${YELLOW}**** init.sql file generated successfully to ${BASE_DIR}/scripts ****${NC}"

sudo rsync -a --delete $BASE_DIR/scripts/initdb/ $SECURE_DIR/initdb/ # Moving initdb to secure_dir
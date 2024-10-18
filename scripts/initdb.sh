#!/bin/bash

# Create initdb directory if it doesn't exist
mkdir -p initdb

# Generate the init.sql file for user replica
cat <<EOF > initdb/01-init.sql
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

-- Create new user
CREATE USER IF NOT EXISTS '$SUPER_USERNAME'@'%' IDENTIFIED BY '$SUPER_PASSWORD' REQUIRE SSL;
GRANT ALL PRIVILEGES ON *.* TO '$SUPER_USERNAME'@'%' WITH GRANT OPTION;

-- Lock user root for remote access for security
ALTER USER 'root'@'%' ACCOUNT LOCK;

-- Apply the privilege changes
FLUSH PRIVILEGES;
EOF

echo "init.sql file generated successfully."
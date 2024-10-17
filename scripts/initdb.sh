#!/bin/bash

# Create initdb directory if it doesn't exist
mkdir -p initdb

# Generate the init.sql file for user replica
cat <<EOF > initdb/01-init.sql
-- Set the global time zone
SET GLOBAL time_zone = '$TIMEZONE';

-- Create replication user if it doesn't exist
CREATE USER IF NOT EXISTS '$REPL_USERNAME'@'%' IDENTIFIED BY '$REPL_PASSWORD' REQUIRE X509;

-- Grant replication slave privileges to the user
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USERNAME'@'%';

-- Apply the privilege changes
FLUSH PRIVILEGES;
EOF

echo "01-init.sql file generated successfully."

# Generate the init.sql file
cat <<EOF > initdb/02-init.sql
-- Create user for monitor maxscale
CREATE USER IF NOT EXISTS '$MAXSCALE_USERNAME'@'%' IDENTIFIED BY '$MAXSCALE_PASSWORD' REQUIRE X509;

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

-- Create test user
CREATE USER IF NOT EXISTS 'test_usr'@'%' IDENTIFIED BY 'test_pass' REQUIRE X509;
GRANT ALL PRIVILEGES ON *.* TO 'test_usr'@'%' WITH GRANT OPTION;

-- Lock user root for remote access for security
ALTER USER 'root'@'%' ACCOUNT LOCK;

FLUSH PRIVILEGES;
EOF

echo "02-init.sql file generated successfully."
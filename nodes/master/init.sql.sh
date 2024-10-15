#!/bin/bash

# Create initdb directory if it doesn't exist
mkdir -p initdb

# Generate the init.sql file
cat <<EOF > initdb/01-init.sql
-- Set the global time zone
SET GLOBAL time_zone = '$TIMEZONE';

-- Create replication user if it doesn't exist
CREATE USER IF NOT EXISTS '$REPL_USERNAME'@'%' IDENTIFIED BY '$REPL_PASSWORD' REQUIRE SSL;

-- Grant replication slave privileges to the user
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USERNAME'@'%';

-- Apply the privilege changes
FLUSH PRIVILEGES;
EOF

echo "01-init.sql file generated successfully."

# Generate the init.sql file
cat <<EOF > initdb/02-init.sql
-- Create user for monitor maxscale
CREATE USER IF NOT EXISTS '$MAXSCALE_USERNAME'@'%' IDENTIFIED BY '$MAXSCALE_PASSWORD' REQUIRE SSL;

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

-- Additional user
CREATE USER IF NOT EXISTS '$SUPER_USERNAME'@'%' IDENTIFIED BY '$SUPER_PASSWORD' REQUIRE SSL;
GRANT ALL PRIVILEGES ON *.* TO '$SUPER_USERNAME'@'%' WITH GRANT OPTION;

CREATE USER IF NOT EXISTS 'other_usr'@'%' IDENTIFIED BY 'other_password' REQUIRE X509;
GRANT ALL PRIVILEGES ON *.* TO 'other_usr'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EOF

echo "02-init.sql file generated successfully."
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

# Generate the init.sql file for optimize table
cat <<EOF > initdb/02-init.sql
-- Create PROCEDURE
DELIMITER //

DROP PROCEDURE IF EXISTS optimize_all_tables;
CREATE PROCEDURE optimize_all_tables()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE db_name VARCHAR(64);
    DECLARE tbl_name VARCHAR(64);
    DECLARE engine VARCHAR(64);
    DECLARE cur CURSOR FOR 
        SELECT table_schema, table_name 
        FROM information_schema.tables 
        WHERE table_type = 'BASE TABLE' 
          AND table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys'); 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO db_name, tbl_name;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Get the engine for the table
        SELECT ENGINE INTO engine 
        FROM information_schema.tables 
        WHERE table_schema = db_name AND table_name = tbl_name;

        IF engine = 'InnoDB' THEN
            -- InnoDB uses rebuild by ALTER TABLE
            SET @opt_stmt = CONCAT('ALTER TABLE ', db_name, '.', tbl_name, ' ENGINE = InnoDB');
            PREPARE stmt FROM @opt_stmt;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        ELSEIF engine = 'MyISAM' THEN
            -- Repair MyISAM tables
            SET @repair_stmt = CONCAT('REPAIR TABLE ', db_name, '.', tbl_name);
            PREPARE stmt FROM @repair_stmt;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        ELSE
            -- For other engines, use OPTIMIZE
            SET @opt_stmt = CONCAT('OPTIMIZE TABLE ', db_name, '.', tbl_name);
            PREPARE stmt FROM @opt_stmt;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;
    END LOOP;
    CLOSE cur;
END //

DELIMITER ;

-- Create EVENT to call procedure
DROP EVENT IF EXISTS optimize_all_tables_event;
CREATE EVENT optimize_all_tables_event
ON SCHEDULE EVERY 1 DAY
DO
CALL optimize_all_tables();
EOF

echo "init.sql file generated successfully."
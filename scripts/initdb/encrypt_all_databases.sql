DELIMITER //

CREATE PROCEDURE encrypt_all_tables(IN db_name VARCHAR(255))
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE table_name VARCHAR(255);
  DECLARE cur CURSOR FOR 
    SELECT table_name FROM information_schema.tables 
    WHERE table_schema = db_name AND engine = 'InnoDB';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO table_name;
    IF done THEN
      LEAVE read_loop;
    END IF;
    SET @stmt = CONCAT('ALTER TABLE ', db_name, '.', table_name, ' ENCRYPTION="Y";');
    PREPARE stmt FROM @stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP;
  CLOSE cur;
END//

DELIMITER ;

-- Create procedure to encrypt all databases
DELIMITER //

CREATE PROCEDURE encrypt_all_databases()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE db_name VARCHAR(255);
  DECLARE cur CURSOR FOR
    SELECT schema_name FROM information_schema.schemata 
    WHERE schema_name NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys');
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO db_name;
    IF done THEN
      LEAVE read_loop;
    END IF;
    SET @stmt = CONCAT('CALL encrypt_all_tables("', db_name, '");');
    PREPARE stmt FROM @stmt;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP;
  CLOSE cur;
END//

DELIMITER ;

-- Call the procedure to encrypt all databases
CALL encrypt_all_databases();
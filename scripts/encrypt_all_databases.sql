DELIMITER //

CREATE PROCEDURE encrypt_all_tables()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE table_name VARCHAR(255);
    DECLARE cur CURSOR FOR 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = DATABASE();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO table_name;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Attempt to encrypt the table using the provided syntax
        SET @sql = CONCAT('ALTER TABLE ', table_name, ' ENCRYPTED=YES ENCRYPTION_KEY_ID=1');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    END LOOP;

    CLOSE cur;

    SELECT 'Attempted to encrypt all tables.' AS Result;
END //

DELIMITER ;
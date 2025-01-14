#!/bin/bash

host=$host
port=$port
user=$user
pass=$pass
master_host=$master_host
master_port=$master_port

echo
echo ===[ Starting to resync $host ]===
echo

# Get the log position and name from master
result=$(sudo docker exec $(sudo docker ps -q -f "name=$master_host") mariadb -u$user --password=$pass --execute="show master status;")
log=$(echo $result|awk '{print $6}')
position=$(echo $result|awk '{print $5}')

sudo docker exec $(sudo docker ps -q -f "name=$host") \
	mariadb -u$user --password=$pass --port=$port \
	--execute="

	STOP SLAVE;\
	RESET SLAVE;\

	CHANGE MASTER TO\
	MASTER_HOST='$master_host',\
	MASTER_PORT=$master_port,\
	MASTER_USER='$REPL_USERNAME',\
	MASTER_PASSWORD='$REPL_PASSWORD',\
	MASTER_LOG_POS=$log,\
	MASTER_LOG_FILE='$position',\
	MASTER_CONNECT_RETRY=10,\
	MASTER_SSL=1,\
	MASTER_SSL_VERIFY_SERVER_CERT=1, \
	MASTER_SSL_CA='/etc/my.cnf.d/tls/ca-cert.pem',\
	MASTER_SSL_CERT='/etc/my.cnf.d/tls/client-cert.pem',\
	MASTER_SSL_KEY='/etc/my.cnf.d/tls/client-key.pem';\

	CHANGE MASTER TO MASTER_USE_GTID = slave_pos;\

	START SLAVE;\

	SHOW SLAVE STATUS\G;"

echo
echo ===[ $host resync complete ]===
echo
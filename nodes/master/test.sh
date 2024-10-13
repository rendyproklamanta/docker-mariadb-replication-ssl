#!/bin/bash
# load env file into the script's environment.
source master.env.sh

# Get the log position and name from master
result=$(docker exec $(docker ps -q -f name=$HOST_MASTER) mysql -u root --password=$MASTER_ROOT_PASSWORD --port=$PORT_MASTER --execute="show master status;")
log=$(echo $result|awk '{print $6}')
position=$(echo $result|awk '{print $5}')

echo $position;
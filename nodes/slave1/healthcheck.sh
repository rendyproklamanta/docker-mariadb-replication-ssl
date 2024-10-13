#!/bin/bash

WAIT_TIMEOUT=300

# Get the container ID
container_id=$(docker ps -q -f name=$HOST_SLAVE1)

# Function to check is running inside the container
check_mariadb_running() {
  docker exec $container_id mariadb -uroot --password=$SLAVE1_ROOT_PASSWORD --port=$PORT_SLAVE1 --execute="SELECT 1" > /dev/null 2>&1
}

# Check if the container is running
if [ -z "$container_id" ]; then
  echo "Error: $HOST_SLAVE1 container is not running."
  exit 1
fi

# Wait to be ready
echo "Waiting for $HOST_SLAVE1 to be ready..."
elapsed=0
while ! check_mariadb_running; do
  sleep 5
  elapsed=$((elapsed + 5))
  if [ $elapsed -ge $WAIT_TIMEOUT ]; then
    echo "Error: $HOST_SLAVE1 did not start within the timeout period."
    exit 1
  fi
  echo "$HOST_SLAVE1 not ready yet, waiting..."
done

echo "$HOST_SLAVE1 is running."
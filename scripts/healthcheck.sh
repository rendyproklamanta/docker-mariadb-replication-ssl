#!/bin/bash

# Get from passing arguments
host=$host
user=$user
pass=$pass

WAIT_TIMEOUT=300

container_id=$(docker ps -q -f "name=$host")

# Function to check is running inside the container
check_mariadb_running() {
  echo "Checking $host is running..."
  sleep 5
  docker exec $container_id mariadb -u$user --password=$pass --execute="SELECT 1" > /dev/null 2>&1
}

# Check if the container is running
if [ -z "$container_id" ]; then
  echo "Error: $host container is not running."
  exit 1
fi

# Wait to be ready
echo "Waiting for $host to be ready..."
elapsed=0
while ! check_mariadb_running; do
  sleep 5
  elapsed=$((elapsed + 5))
  if [ $elapsed -ge $WAIT_TIMEOUT ]; then
    echo "Error: $host did not start within the timeout period."
    exit 1
  fi
  echo "$host not ready yet, waiting..."
done

echo "$host is running. (OK)"
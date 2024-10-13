#!/bin/bash

# SLAVE1 environment
export HOST_SLAVE1="mariadb_mariadb-slave1"
export PORT_SLAVE1="3302"
export SLAVE1_ROOT_PASSWORD=$(cat /run/secrets/db_slave1_paswd)

#!/bin/bash

# MASTER environment
export HOST_MASTER="mariadb_mariadb-master"
export PORT_MASTER="3301"
export MASTER_ROOT_PASSWORD=$(cat /run/secrets/db_master_paswd)

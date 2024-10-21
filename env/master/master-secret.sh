#!/bin/bash

## Delete secret
docker secret rm db_master_paswd

## Create secret
echo "MASTER_ROOT_PASSWORD_SET" | docker secret create db_master_paswd -
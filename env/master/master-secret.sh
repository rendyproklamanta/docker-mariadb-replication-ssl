#!/bin/bash

## Delete secret
sudo docker secret rm db_master_paswd

## Create secret
echo "MASTER_ROOT_PASSWORD_SET" | sudo docker secret create db_master_paswd -
#!/bin/bash

## Delete secret
sudo docker secret rm db_slave1_paswd

## Create secret
echo "SLAVE1_ROOT_PASSWORD_SET" | sudo docker secret create db_slave1_paswd -
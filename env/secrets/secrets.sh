#!/bin/bash

## Create secret
docker secret rm db_super_user && echo "super_usr" | docker secret create db_super_user -
docker secret rm db_super_paswd && echo "SUPER_PASSWORD_SET" | docker secret create db_super_paswd -
docker secret rm db_repl_paswd && echo "REPL_PASSWORD_SET" | docker secret create db_repl_paswd -
docker secret rm db_master_paswd && echo "MASTER_ROOT_PASSWORD_SET" | docker secret create db_master_paswd -
docker secret rm db_slave1_paswd && echo "SLAVE1_ROOT_PASSWORD_SET" | docker secret create db_slave1_paswd -

## Show list secrets
docker secret ls
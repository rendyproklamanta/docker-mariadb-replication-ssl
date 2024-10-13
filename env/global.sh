#!/bin/bash

# ._SET : Dont change it manually, instead using find and replace tool in readme.md

export TIMEZONE="Asia/jakarta"

export REPL_USERNAME="repl"
export REPL_PASSWORD=$(cat /run/secrets/db_repl_paswd)

export MAXSCALE_USERNAME="maxuser"
export MAXSCALE_PASSWORD="maxpwd"

export SUPER_USERNAME=$(cat /run/secrets/db_super_user)
export SUPER_PASSWORD=$(cat /run/secrets/db_super_paswd)

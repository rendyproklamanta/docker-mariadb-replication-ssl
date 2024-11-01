#!/bin/bash

## Replace text
find "$BASE_DIR" -type f -exec sed -i "s|MAXCONF_PASSWORD_SET|$MAXSCALE_PASSWORD|g" {} +
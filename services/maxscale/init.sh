#!/bin/bash

## Replace text
sudo find "$BASE_DIR" -type f -exec sed -i "s|MAXSCALE_PASSWORD_SET|$MAXSCALE_PASSWORD|g" {} +

# MOVE : Conf
echo -e "${YELLOW}**** Moving maxscale conf directory ****${NC}"
sudo rsync -a --delete $SERVICE_DIR/maxscale/conf/ $SECURE_DIR/conf/maxscale/
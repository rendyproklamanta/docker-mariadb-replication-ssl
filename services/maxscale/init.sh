#!/bin/bash

## Replace text
find "$BASE_DIR" -type f -exec sed -i "s|MAXCONF_PASSWORD_SET|$MAXSCALE_PASSWORD|g" {} +

# MOVE : Conf
echo -e "${YELLOW}**** Moving maxscale conf directory ****${NC}"
rsync -a --delete $SERVICE_DIR/maxscale/conf/ $DATA_DIR/conf/maxscale/
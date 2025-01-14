#!/bin/bash

# Create log
echo -e "${YELLOW}**** Create log maxscale ****${NC}"
sudo mkdir -p /var/log/maxscale
sudo touch /var/log/maxscale/maxscale.log
sudo chmod -R 777 /var/log/maxscale/maxscale.log 

# Replace text
echo -e "${YELLOW}**** Replace maxscale password ****${NC}"
sudo find "$BASE_DIR" -type f -exec sed -i "s|MAX_PASSWORD_SET|$MAXSCALE_PASSWORD|g" {} +

# MOVE : Conf
echo -e "${YELLOW}**** Moving maxscale conf directory ****${NC}"
sudo rsync -a --delete $SERVICE_DIR/maxscale/conf/ $SECURE_DIR/conf/maxscale/
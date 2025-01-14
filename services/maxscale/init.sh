#!/bin/bash

## Replace text
find "$BASE_DIR" -type f -exec sed -i "s|MAX_PASSWORD_SET|$MAXSCALE_PASSWORD|g" {} +

# MOVE : Conf
echo -e "${YELLOW}**** Moving maxscale conf directory ****${NC}"
rsync -a --delete $SERVICE_DIR/maxscale/conf/ $SECURE_DIR/conf/maxscale/

# maxscale_pass=$maxscale_pass
# service_dir=$service_dir
# secure_dir=$secure_dir
# base_dir=$base_dir

# ## Replace text
# sudo find "$base_dir" -type f -exec sed -i "s|MAXSCALE_PASSWORD_SET|$maxscale_pass|g" {} +

# # MOVE : Conf
# echo -e "${YELLOW}**** Moving maxscale conf directory ****${NC}"
# sudo rsync -a --delete $service_dir/maxscale/conf/$secure_dir/conf/maxscale/
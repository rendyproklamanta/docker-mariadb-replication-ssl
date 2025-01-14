#!/bin/bash

set -k && sudo -E ./generate-ca.sh generate_new=true
set -k && sudo -E ./generate-client.sh generate_new=true
set -k && sudo -E ./generate-master.sh generate_new=true
set -k && sudo -E ./generate-slave1.sh generate_new=true
set -k && sudo -E ./generate-maxscale.sh generate_new=true

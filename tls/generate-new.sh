#!/bin/bash

set -k && ./generate-ca.sh generate_new=true
set -k && ./generate-client.sh generate_new=true
set -k && ./generate-master.sh generate_new=true
set -k && ./generate-slave1.sh generate_new=true
set -k && ./generate-maxscale.sh generate_new=true

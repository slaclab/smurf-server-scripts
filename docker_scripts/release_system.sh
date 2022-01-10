#!/usr/bin/env bash

# Prefix use in the default target release directory
target_dir_prefix=stable

# This is called by the help flag.
usage_header() {
    echo "Release a new stable system. Includes both server and client.
This SMuRF server is based on pysmurf and rogue v4

Note: The docker image used for the server is 'tidair/pysmurf-server'
and the docker image used for the client is 'tidair/pysmurf-client'.
Starting at version 'v5.0.0', the 'tidair/pysmurf-server' image comes
from the pysmurf repository."
}

# Call common release step to all type of applications,
# but in this case set the "stable_release" flag.
stable_release=1
. ${top_dir}/system_common.sh

echo "Scripts placed in ${target_dir}"
echo "End of release-system.sh"

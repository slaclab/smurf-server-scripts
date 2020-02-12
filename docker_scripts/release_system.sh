#!/usr/bin/env bash

###############
# Definitions #
###############

# Prefix use in the default target release directory
target_dir_prefix=stable

########################
# Function definitions #
########################

# Usage message
usage_header()
{
    echo "Release a new stable system. Includes both server and client."
    echo "This SMuRF server is based on pysmurf and rogue v4"
    echo
    echo "Note: The docker image used for the server is 'tidait/pysmurf-server'"
    echo "and the docker image used for the client is 'tidair/pysmurf-client'."
    echo
}

#############
# Main body #
#############

# Call common release step to all type of application,
# but in this case set the "stable_release" flag.
stable_release=1
. system_common.sh

# Print final report
echo ""
echo "All Done!"
echo "Script released to ${target_dir}"
echo ""
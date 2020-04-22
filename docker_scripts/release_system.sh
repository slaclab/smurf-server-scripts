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


# Get the pysmurf version used to build an specific pysmurf-stable version.
# The first argument is the pysmurf-stable version.
# It return the according version of pysmurf. Or an empty string if not found.
get_pysmurf_version()
{
    # pysmurf version
    local pysmurf_stable_version=$1

    # First, the the smurf-rogue version
    local pysmurf_version=$(curl -fsSL --retry-connrefused --retry 5 \
        https://raw.githubusercontent.com/slaclab/pysmurf-stable-docker/${pysmurf_stable_version}/definitions.sh 2> /dev/null \
        | grep -Po '^pysmurf_server_base_version=\s*\K.+') || exit 1

    # Return the rogue version
    echo ${rogue_version}
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
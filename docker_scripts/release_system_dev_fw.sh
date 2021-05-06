#!/usr/bin/env bash

###############
# Definitions #
###############

# Prefix use in the default target release directory
target_dir_prefix=dev_fw

########################
# Function definitions #
########################

# Usage message header, specific to this type of application
usage_header()
{
    echo "Release a new system for FW development. Includes both server and client."
    echo "This SMuRF server is based on pysmurf and rogue v4"
    echo
    echo "The SMuRF server docker image uses an user-provided FW version, located in the local 'fw' folder."
    echo
    echo "Note: The docker image used for the server is 'tidait/pysmurf-server-base', for version prior to"
    echo "'v5.0.0', or 'tidait/pysmurf-server' for versions starting at 'v5.0.0'. Starting at version"
    echo "'v5.0.0', the 'tidait/pysmurf-server' image comes from the pysmurf repository."
    echo "On the other hand, the docker image used for the client is 'tidair/pysmurf-client'."
    echo
}

#############
# Main body #
#############

# Call common release step to all type of application
. system_common.sh

# Create fw directory
mkdir -p ${target_dir}/fw

# Print final report
echo ""
echo "All Done!"
echo "Script released to ${target_dir}"
echo "Remember to place your FW related files in the 'fw' directory."
echo ""
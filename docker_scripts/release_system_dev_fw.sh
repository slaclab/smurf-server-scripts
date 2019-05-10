#!/usr/bin/env bash

###############
# Definitions #
###############

########################
# Function definitions #
########################

# Usage message header, specific to this type of application
usage_header()
{
    echo "Release a new system for FW development. Includes a SMuRF server and pysmurf."
    echo
    echo "The SMuRF server docker image uses an user-provided FW version, located in the local 'fw' folder."
    echo
    echo "Note: The docker image used for the 'smurf2mce' server is 'tidait/smurf2mce-base'"
    echo "and the docker image used for 'pysmurf' is 'tidair/pysmurf'."
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
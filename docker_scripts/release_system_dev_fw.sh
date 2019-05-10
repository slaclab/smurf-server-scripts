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
    echo "The SMuRF server uses an user provided FW version, located in the 'fw' folder."
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
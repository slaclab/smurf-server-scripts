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
    echo "Release a new stable system. Includes a SMuRF server and pysmurf."
    echo "This SMuRF server is based on the now deprecated smurf2mce app, based on rogue v3."
    echo
    echo "Note: The docker image used for the 'smurf2mce' server is 'tidait/smurf2mce'"
    echo "and the docker image used for 'pysmurf' is 'tidair/pysmurf'."
    echo
}


#############
# Main body #
#############

# Call common release step to all type of application
. system_common.sh

# Print final report
echo ""
echo "All Done!"
echo "Script released to ${target_dir}"
echo ""
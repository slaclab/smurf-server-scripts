#!/usr/bin/env bash

###############
# Definitions #
###############
# smurf2mce git repository
smurf2me_git_repo=http://github.com/slaclab/smurf2mce.git

########################
# Function definitions #
########################

# Usage message
usage_header()
{
    echo "Release a new system for SW development. Includes a SMuRF server and pysmurf."
    echo "The SMuRF server uses a user provided SW version, located in the 'smurf2mce' folder."
    echo "This script will clone the master branch from github."
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

# Clone pysmurf (master branch) in the target directory
git clone ${smurf2me_git_repo} ${target_dir}/smurf2mce

# Print final report
echo ""
echo "All Done!"
echo "Script released to ${target_dir}"
echo "The master branch of ${smurf2mce_git_repo} was clone in ${target_dir}/smurf2mce. That is the copy that runs inside the docker container."
echo "Remember to place your FW related files in the 'fw' directory."
echo ""
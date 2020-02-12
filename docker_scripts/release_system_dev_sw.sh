#!/usr/bin/env bash

###############
# Definitions #
###############

# Prefix use in the default target release directory
target_dir_prefix=dev_sw

########################
# Function definitions #
########################

# Usage message
usage_header()
{
    echo "Release a new system for SW development. Includes both server and client."
    echo "This SMuRF server is based on pysmurf and rogue v4"
    echo
    echo "This script will clone the 'pre-release' branch of both rogue and pysmurf repositories into the local"
    echo "directories 'rogue' and 'pysmurf' respectevely. The SMuRF server docker image will use these local copies,"
    echo "instead of the one provided internally. So, any change you make to the local copy will be present in the"
    echo "docker container."
    echo
    echo "The SMuRF server docker image uses an user-provided FW version, located in the local 'fw' folder."
    echo
    echo "Note: The docker image used for the server is 'tidait/pysmurf-server-base'"
    echo "and the docker image used for the client is 'tidair/pysmurf-client'."
    echo
}

#############
# Main body #
#############

# Call common release step to all type of application
. system_common.sh

# Create fw directory
mkdir -p ${target_dir}/fw

# Clone rogue (pre-release branch) in the target directory
git clone ${rogue_git_repo} ${target_dir}/rogue -b pre-release

# Clone pysmurf (pre-release branch) in the target directory
git clone ${pysmurf_git_repo} ${target_dir}/pysmurf -b pre-release

# Print final report
echo ""
echo "All Done!"
echo "Script released to ${target_dir}"
echo
echo "The 'pre-release' branch of ${rogue_git_repo} was clone in ${target_dir}/rogue."
echo "That is the copy that runs inside the docker container."
echo
echo "The 'pre-release' branch of ${pysmurf_git_repo} was clone in ${target_dir}/pysmurf."
echo "That is the copy that runs inside the docker container."
echo
echo "Remember that you need to compile the pysmurf application the first time you start the container."
echo "Remember to place your FW related files in the 'fw' directory."
echo ""
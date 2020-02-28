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

# Get the Rogue version used by an specific version of pysmurf.
# The first argument is the pysmurf version.
# It return the according version of rogue. Or an empty string if not found.
get_rogue_version()
{
    local pysmurf_version=$1
    local smurf_rogue_version=$(curl -fsSL --retry-connrefused --retry 5 https://raw.githubusercontent.com/slaclab/pysmurf/${pysmurf_version}/docker/server/Dockerfile 2>/dev/null | grep -Po '^FROM\s+tidair\/smurf-rogue:\K.+') || exit 1
    local rogue_version=$(curl -fsSL --retry-connrefused --retry 5 https://raw.githubusercontent.com/slaclab/smurf-rogue-docker/${smurf_rogue_version}/Dockerfile  2>/dev/null | grep -Po '^RUN\s+git\s+clone\s+https:\/\/github.com\/slaclab\/rogue\.git\s+-b\s+\K.+') || exit 1

    echo ${rogue_version}
}

#############
# Main body #
#############

# Call common release step to all type of application
. system_common.sh

# Look for the rogue version
rogue_version=$(get_rogue_version ${pysmurf_version})

# Check if a version of rogue was found
if [ ! ${rogue_version} ]; then
    echo "Error. Rogue version not found for pysmurf version ${pysmurf_version}"
else

    # Create fw directory
    mkdir -p ${target_dir}/fw

    # Clone rogue (on the specific tag) in the target directory
    git clone ${rogue_git_repo} ${target_dir}/rogue -b ${rogue_version}

    # Clone pysmurf (on the specific tag) in the target directory
    git clone ${pysmurf_git_repo} ${target_dir}/pysmurf -b ${pysmurf_version}

    # Print final report
    echo ""
    echo "All Done!"
    echo "Script released to ${target_dir}"
    echo
    echo "The tag '${rogue_version}' of ${rogue_git_repo} was checkout in ${target_dir}/rogue."
    echo "That is the copy that runs inside the docker container."
    echo
    echo "The tag '${pysmurf_version}' of ${pysmurf_git_repo} was checkout in ${target_dir}/pysmurf."
    echo "That is the copy that runs inside the docker container."
    echo
    echo "If you make changes to these repositories and want to push them back to git, remember to create"
    echo "and push a new branch, by running these commands in the respective directory (replace <new_branch_name>,"
    echo "with an appropriate branch name):"
    echo " $ git checkout -b <new_branch_name>"
    echo " $ git push -set-upstream origin <new_branch_name>"
    echo
    echo "Remember that you need to compile the pysmurf application the first time you start the container."
    echo "Remember to place your FW related files in the 'fw' directory."
    echo ""
fi
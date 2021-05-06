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
    echo "This script will clone the specified version of pysmurf, and its corresponding version of rogue repositories"
    echo "into the local directories 'rogue' and 'pysmurf' respectively. The SMuRF server docker image will use these"
    echo "local copies, instead of the one provided internally. So, any change you make to the local copy will be"
    echo "present in the docker container."
    echo
    echo "The SMuRF server docker image uses an user-provided FW version, located in the local 'fw' folder."
    echo
    echo "Note: The docker image used for the server is 'tidait/pysmurf-server-base', for version prior to"
    echo "'v5.0.0', or 'tidait/pysmurf-server' for versions starting at 'v5.0.0'. Starting at version"
    echo "'v5.0.0', the 'tidait/pysmurf-server' image comes from the pysmurf repository."
    echo "On the other hand, the docker image used for the client is 'tidair/pysmurf-client'."
    echo
}

# Get the Rogue version used by an specific version of pysmurf.
# The first argument is the pysmurf version.
# It return the according version of rogue. Or an empty string if not found.
get_rogue_version()
{
    # pysmurf version
    local pysmurf_version=$1

    # First, the the smurf-rogue version
    local smurf_rogue_version=$(curl -fsSL --retry-connrefused --retry 5 \
        https://raw.githubusercontent.com/slaclab/pysmurf/${pysmurf_version}/docker/server/Dockerfile 2>/dev/null \
        | grep -Po '^FROM\s+tidair\/smurf-rogue:\K.+') || exit 1

    # Now get the rogue version
    local rogue_version=$(curl -fsSL --retry-connrefused --retry 5 \
        https://raw.githubusercontent.com/slaclab/smurf-rogue-docker/${smurf_rogue_version}/Dockerfile  2>/dev/null \
        | grep -Po '^RUN\s+git\s+clone\s+https:\/\/github.com\/slaclab\/rogue\.git\s+-b\s+\K.+') || exit 1

    # Return the rogue version
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
    echo "Error: Rogue version not found for pysmurf version ${pysmurf_version}"
    echo
    return 1
fi

# Create fw directory
mkdir -p ${target_dir}/fw

# Clone software repositories
echo "Cloning repositories:"

## Clone rogue (on the specific tag) in the target directory
echo "Cloning rogue..."
cmd="git clone ${rogue_git_repo} ${target_dir}/rogue -b ${rogue_version}"
echo ${cmd}
${cmd}

if [ $? -ne 0 ]; then
    echo "Error: Failed to clone rogue."
    echo
    return 1
fi

echo

## Clone pysmurf (on the specific tag) in the target directory
echo "Cloning pysmurf..."
cmd="git clone ${pysmurf_git_repo} ${target_dir}/pysmurf -b ${pysmurf_version}"
echo ${cmd}
${cmd}

if [ $? -ne 0 ]; then
    echo "Error: Failed to clone rogue."
    echo
    return 1
fi

echo

# Build application
echo "Building applications:"

## Build rogue
echo "Building rogue..."
docker run -ti --rm \
    --user cryo:smurf \
    -v ${target_dir}/rogue:/usr/local/src/rogue \
    --workdir /usr/local/src/rogue \
    --entrypoint="" \
    tidair/pysmurf-server-base:${pysmurf_version} \
    /bin/bash -c "rm -rf build && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DROGUE_INSTALL=local .. && make -j4 install"

if [ $? -ne 0 ]; then
    echo "Error: Failed to build rogue"
    echo
    return 1
fi

echo

## Build pysmurf
echo "Building pysmurf..."
docker run -ti --rm \
    --user cryo:smurf \
    -v ${target_dir}/pysmurf:/usr/local/src/pysmurf \
    --workdir /usr/local/src/pysmurf \
    --entrypoint="" tidair/pysmurf-server-base:${pysmurf_version} \
    /bin/bash -c "rm -rf build && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && make -j4"

if [ $? -ne 0 ]; then
    echo "Error: Failed to build pysmurf"
    echo
    return 1
fi

echo

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
echo "and push a new branch, by running these commands in the respective directory (replace <new-branch-name>,"
echo "with an appropriate branch name):"
echo " $ git checkout -b <new-branch-name>"
echo " $ git push -set-upstream origin <new-branch-name>"
echo
echo "Remember to place your FW related files in the 'fw' directory."
echo ""
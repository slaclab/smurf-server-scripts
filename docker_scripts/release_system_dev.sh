#!/usr/bin/env bash

target_dir_prefix=dev

# Usage message
usage_header() {
    echo "Same as the system release, but allow the user to provide their own
rogue, pysmurf, and firmware files.

The rogue and pysmurf repositories are cloned at the given version,
and compiled locally. The firmware files must be provided by the user,
i.e. the .mcs.gz and corresponding .zip configuration. Put those in
the fw folder after running this script.

Note: For older systems, the docker image used for the server is
'tidair/pysmurf-server-base', for versions prior to 'v5.0.0', or
'tidair/pysmurf-server' for versions starting at 'v5.0.0'. Starting at
version 'v5.0.0', the 'tidait/pysmurf-server' image comes from the
pysmurf repository.  On the other hand, the docker image used for the
client is 'tidair/pysmurf-client'."
}

# Do exactly the system release, except without stable_release=1.
. ${top_dir}/system_common.sh

# Now clone rogue, pysmurf, compile them, and make the custom fw folder.

get_rogue_version() {
    # Get the Rogue version used by the given pysmurf
    # version. Practically this means digging into pysmurf to get the
    # smurf-rogue-docker version, then digging into smurf-rogue-docker
    # to get the version of Rogue it uses. I know.
    # $1 : Version of pysmurf

    local pysmurf_version=$1

    local smurf_rogue_version=$(curl -fsSL --retry-connrefused --retry 5 \
        https://raw.githubusercontent.com/slaclab/pysmurf/${pysmurf_version}/docker/server/Dockerfile 2>/dev/null \
        | grep -Po '^FROM\s+tidair\/smurf-rogue:\K.+') || exit 1

    local rogue_version=$(curl -fsSL --retry-connrefused --retry 5 \
        https://raw.githubusercontent.com/slaclab/smurf-rogue-docker/${smurf_rogue_version}/Dockerfile  2>/dev/null \
        | grep -Po '^RUN\s+git\s+clone\s+https:\/\/github.com\/slaclab\/rogue\.git\s+-b\s+\K.+') || exit 1

    echo ${rogue_version}
}

rogue_version=$(get_rogue_version ${pysmurf_version})

if [ ! ${rogue_version} ]; then
    echo "Error: Rogue version not found for pysmurf version ${pysmurf_version}"
    echo
    return 1
fi

mkdir -p ${target_dir}/fw

echo "Cloning rogue..."
cmd="git clone ${rogue_git_repo} ${target_dir}/rogue -b ${rogue_version}"
echo ${cmd}
${cmd}

if [ $? -ne 0 ]; then
    echo "Error: Failed to clone rogue."
    return 1
fi

echo "Cloning pysmurf..."
cmd="git clone ${pysmurf_git_repo} ${target_dir}/pysmurf -b ${pysmurf_version}"
echo ${cmd}
${cmd}

if [ $? -ne 0 ]; then
    echo "Error: Failed to clone pysmurf."
    echo
    return 1
fi

echo

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
    return 1
fi

echo "Building pysmurf..."
docker run -ti --rm \
    --user cryo:smurf \
    -v ${target_dir}/pysmurf:/usr/local/src/pysmurf \
    --workdir /usr/local/src/pysmurf \
    --entrypoint="" tidair/pysmurf-server-base:${pysmurf_version} \
    /bin/bash -c "rm -rf build && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && make -j4"

if [ $? -ne 0 ]; then
    echo "Error: Failed to build pysmurf"
    return 1
fi

echo "The tag ${rogue_version} of ${rogue_git_repo} was checked out in
${target_dir}/rogue.  That is the copy that runs inside the docker
container.

The tag ${pysmurf_version} of ${pysmurf_git_repo} was checkout in
${target_dir}/pysmurf.  That is the copy that runs inside the docker
container.

You may modify the pysmurf Python code on the fly, however you'll need
to recompile pysmurf or rogue yourself if you modify their C++ code.

Go ahead and cd ${target_dir} and ./run.sh.

End of release_system_dev.sh."

#!/usr/bin/env bash

###############
# Definitions #
###############
# Default release output directory
release_top_default_dir="/home/cryo/docker/utils/dev"

# Template directory for this application
template_dir=${template_top_dir}/utils

########################
# Function definitions #
########################

# Usage message
usage()
{
    echo "Release an utility system."
    echo
    echo "usage: ${script_name} -t utils -v|--version <smurf_base_version> [-o|--output-dir <output_dir>] [-h|--help]"
    echo
    echo "  -v|--version    <smurf-base_version> : Version of the smurf-base docker image."
    echo "  -o|--output-dir <output_dir>         : Directory where to release the scripts. Defaults to"
    echo "                                         ${release_top_default_dir}"
    echo "  -h|--help                            : Show this message."
    echo
    exit $1
}


#############
# Main body #
#############

# Verify inputs arguments
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -v|--version)
    smurf_base_version="$2"
    shift
    ;;
    -o|--output-dir)
    target_dir="$2"
    shift
    ;;
    -h|--help)
    usage 0
    ;;
    *)
    echo "Unknown argument"
    usage 1
    ;;
esac
shift
done

# Verify parameters
if [ -z ${smurf_base_version+x} ]; then
        echo "ERROR: smurf-base version not defined!"
        echo ""
        usage 1
fi

if [ -z ${target_dir+x} ]; then
    target_dir=${release_top_default_dir}
fi

# Verify is target directory already exist
if [ -d ${target_dir} ]; then
    echo "ERROR: release directory '${target_dir}' already exist."
    exit 1
fi

# Create target directory
echo "Creating target directory ${target_dir}..."

mkdir -p ${target_dir}

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: could not create the target directory"
    exit 1
fi

echo "Done!"
echo ""

# Generate the run script
cat ${template_dir}/run.sh \
        | sed s/%%SMURF_BASE_VERSION%%/${smurf_base_version}/g \
        > ${target_dir}/run.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/run.sh"
    exit 1
fi

# Make shared folder
mkdir -p ${target_dir}/shared

# Print final report
echo ""
echo "All Done!"
echo "Scripts released to ${target_dir}"
echo "The folder 'shared' is mounted inside the docker container as '/shared'. It can be used to shared files between the host and the docker environments."
echo ""
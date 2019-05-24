#!/usr/bin/env bash

###############
# Definitions #
###############
# Default release output directory
release_top_default_dir="/home/cryo/docker/pcie"

# Template directory for this application
template_dir=${template_top_dir}/pcie

########################
# Function definitions #
########################

# Usage message
usage()
{
    echo "Release a PCIe utility application."
    echo
    echo "usage: ${script_name} -t pcie -v|--version <version> [-o|--output-dir <output_dir>] [-h|--help]"
    echo
    echo "  -v|--version    <version>    : Version of the smurf-pcie docker image."
    echo "  -o|--output-dir <output_dir> : Directory where to release the scripts. Defaults to"
    echo "                                 ${release_top_default_dir}"
    echo "  -h|--help                    : Show this message."
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
    version="$2"
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
if [ -z ${version+x} ]; then
        echo "ERROR: version not defined!"
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
        | sed s/%%VERSION%%/${version}/g \
        > ${target_dir}/run.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/run.sh"
    exit 1
fi

# Mark the script as executable
chmod +x ${target_dir}/run.sh

# Make shared folder
mkdir -p ${target_dir}/shared

# Print final report
echo ""
echo "All Done!"
echo "Scripts released to ${target_dir}"
echo "The folder 'shared' is mounted inside the docker container as '/shared'. It can be used to shared files between the host and the docker container."
echo ""
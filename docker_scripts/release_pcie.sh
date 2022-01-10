#!/usr/bin/env bash

###############
# Definitions #
###############
# PCIe docker git repository
pcie_git_repo=https://github.com/slaclab/smurf-pcie-docker.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/pcie"

# Template directory for this application
template_dir=${template_top_dir}/pcie

# Usage message
usage()
{
    echo "Release a PCIe utility application."
    echo
    echo "usage: ${script_name} -t pcie -v|--version <pcie_version> [-o|--output-dir <output_dir>] [-l|--list-versions] [-h|--help]"
    echo
    echo "  -v|--version    <pcie_version> : Version of the smurf-pcie docker image."
    echo "  -o|--output-dir <output_dir>   : Directory where to release the scripts. Defaults to"
    echo "                                   ${release_top_default_dir}/<pcie_version>"
    echo "  -l|--list-versions             : Print a list of available versions."
    echo "  -h|--help                      : Show this message."
    echo
    exit $1
}

# Print a list of all available versions
print_list_versions()
{
    echo "List of available pcie_version:"
    print_git_tags ${pcie_git_repo}
    echo
    exit 0
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
    pcie_version="$2"
    shift
    ;;
    -o|--output-dir)
    target_dir="$2"
    shift
    ;;
    -l|--list-versions)
    print_list_versions
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
if [ -z ${pcie_version+x} ]; then
        echo "ERROR: smurf-pcie version not defined!"
        echo ""
        usage 1
fi

if [ -z ${target_dir+x} ]; then
    target_dir=${release_top_default_dir}/${pcie_version}
fi

# Check if the pcie-version exist
ret=$(verify_git_tag_exist ${pcie_git_repo} ${pcie_version})
if [ -z ${ret} ]; then
    echo "ERROR: pcie-version version ${pcie_version} does not exist"
    echo "You can use the '-l' option to list the available versions."
    echo
    exit 1
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
        | sed s/%%VERSION%%/${pcie_version}/g \
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

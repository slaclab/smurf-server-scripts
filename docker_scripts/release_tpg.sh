#!/usr/bin/env bash

###############
# Definitions #
###############
# TPG docker git repositories
tpg_git_repo=https://github.com/slaclab/smurf-tpg-ioc-docker.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/tpg"

# Template directory for this application
template_dir=${template_top_dir}/tpg

########################
# Function definitions #
########################
# Import common functions
. common.sh

# Usage message
usage()
{
    echo "Release a TPG IOC."
    echo
    echo "usage: ${script_name} -t tpg -v|--version <tpg_version> [-o|--output-dir <output_dir>] [-l|--list-versions] [-h|--help]"
    echo
    echo "  -v|--version    <tpg_version> : Version of the smurf-tpg-ioc docker image."
    echo "  -o|--output-dir <output_dir>  : Directory where to release the scripts. Defaults to"
    echo "                                  ${release_top_default_dir}/<tpg_version>"
    echo "  -l|--list-versions            : Print a list of available versions."
    echo "  -h|--help                     : Show this message."
    echo
    exit $1
}

# Print a list of all available versions
print_list_versions()
{
    echo "List of available tpg_version:"
    print_git_tags ${tpg_git_repo}
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
    tpg_version="$2"
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
if [ -z ${tpg_version+x} ]; then
        echo "ERROR: smurf-tpg-ioc version not defined!"
        echo ""
        usage 1
fi

if [ -z ${target_dir+x} ]; then
    target_dir=${release_top_default_dir}/${tpg_version}
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

# Generate file specific to this type of application
cat ${template_dir}/docker-compose.yml \
        | sed s/%%TPG_VERSION%%/${tpg_version}/g \
        > ${target_dir}/docker-compose.yml
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/docker-compose.yml"
    exit 1
fi
copy_template "run.sh"
copy_template "stop.sh"

# Mark the scripts as executable
chmod +x ${target_dir}/run.sh
chmod +x ${target_dir}/stop.sh

# Print final report
echo ""
echo "All Done!"
echo "Scripts released to ${target_dir}"
echo ""
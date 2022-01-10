#!/usr/bin/env bash

###############
# Definitions #
###############
# SMuRF Rogue docker git repository
smurf_rogue_git_repo=https://github.com/slaclab/smurf-rogue-docker.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/guis"

# Template directory for this application
template_dir=${template_top_dir}/guis

########################
# Function definitions #
########################
# Import common functions
. ${top_dir}/common.sh
. ${top_dir}/common.sh

# Usage message
usage()
{
    echo "Release an application to connect remote rogue GUIs."
    echo
    echo "usage: ${script_name} -t guis -v|--version <smurf-rogue_version> [-o|--output-dir <output_dir>]"
    echo "                                 [-l|--list-versions] [-h|--help]"
    echo
    echo "  -v|--version    <smurf-rogue_version> : Version of the smurf-rogue docker image."
    echo "  -o|--output-dir <output_dir>          : Directory where to release the scripts. Defaults to"
    echo "                                          ${release_top_default_dir}/<smurf-rogue_version>"
    echo "  -l|--list-versions                    : Print a list of available versions."
    echo "  -h|--help                             : Show this message."
    echo
    exit $1
}

# Print a list of all available versions
print_list_versions()
{
    # This application type is supported starting at version R2.7.0, so exclude all previous versions
    echo "List of available smurf-rogue_version:"
    print_git_tags ${smurf_rogue_git_repo} 'R0.\|R1.\|R2.0.\|R2.1\|R2.2\|R2.3\|R2.4\|R2.5\|R2.6'
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
    smurf_rogue_version="$2"
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
if [ -z ${smurf_rogue_version+x} ]; then
        echo "ERROR: smurf-rogue version not defined!"
        echo ""
        usage 1
fi

# Check if the smurf-rogue version exist
ret=$(verify_git_tag_exist ${smurf_rogue_git_repo} ${smurf_rogue_version} 'R0.\|R1.\|R2.0.\|R2.1\|R2.2\|R2.3\|R2.4\|R2.5\|R2.6')
if [ -z ${ret} ]; then
    echo "ERROR: smurf-rogue version ${smurf_rogue_version} does not exist"
    echo "You can use the '-l' option to list the available versions."
    echo
    exit 1
fi

if [ -z ${target_dir+x} ]; then
    target_dir=${release_top_default_dir}/${smurf_rogue_version}
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
        | sed s/%%SMURF_ROGUE_VERSION%%/${smurf_rogue_version}/g \
        > ${target_dir}/run.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/run.sh"
    exit 1
fi

# Mark the script as executable
chmod +x ${target_dir}/run.sh

# Print final report
echo ""
echo "All Done!"
echo "Scripts released to ${target_dir}"
echo ""
#!/usr/bin/env bash

###############
# Definitions #
###############
# TPG docker git repository
atca_monitor_git_repo=https://github.com/slaclab/smurf-atca-monitor.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/atca_monitor"

# Template directory for this application
template_dir=${template_top_dir}/atca-monitor

# Whether to list versions
list_versions=false

# Whether or not to list all versions, or just releases.
list_all=false

# Usage message
usage()
{
    echo "Release an ATCA monitor application."
    echo
    echo "usage: ${script_name} -t atca-monitor -v|--version <atca-monitor_version> [-o|--output-dir <output_dir>] [-h|--help]"
    echo
    echo "  -v|--version    <atca-monitor_version> : Version of the smurf-atca-monitor docker image."
    echo "  -o|--output-dir <output_dir>           : Directory where to release the scripts. Defaults to"
    echo "                                           ${release_top_default_dir}/<atca-monitor_version>"
    echo "  -l|--list-versions                     : Print a list of available versions."
    echo "  -a|--all-versions                      : Include all versions, not just releases."
    echo "  -h|--help                              : Show this message."
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
    atca_monitor_version="$2"
    shift
    ;;
    -o|--output-dir)
    target_dir="$2"
    shift
    ;;
    -a|--all-versions)
    list_all=true
    ;;    
    -l|--list-versions)
    list_versions=true    
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

# Now check if we should call print_list_versions
if [[ $list_versions == true ]]; then
    echo "List of available atca-monitor_version:"    
    print_list_versions ${atca_monitor_git_repo} '^$' ${list_all}
    echo
    exit 0
fi

# Verify parameters
if [ -z ${atca_monitor_version+x} ]; then
        echo "ERROR: smurf-atca-monitor version not defined!"
        echo ""
        usage 1
fi

# Check if the smurf-atca-monitor exist
ret=$(verify_git_tag_exist ${atca_monitor_git_repo} ${atca_monitor_version})
if [ -z ${ret} ]; then
    echo "ERROR: smurf-atca-monitor version ${atca_monitor_version} does not exist"
    echo "You can use the '-l' option to list the available versions."
    echo
    exit 1
fi

if [ -z ${target_dir+x} ]; then
    target_dir=${release_top_default_dir}/${atca_monitor_version}
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
        | sed s/%%VERSION%%/${atca_monitor_version}/g \
        > ${target_dir}/run.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/run.sh"
    exit 1
fi

# Which container registry
image_address=$(get_docker_image_address smurf-atca-monitor ${atca_monitor_version})
escaped_image_address=$(printf '%s' "$image_address" | sed 's/\//\\\//g')
sed -i -e "s/\%\%DOCKER_IMAGE_ADDRESS\%\%/${escaped_image_address}/g" ${target_dir}/run.sh

# Mark the script as executable
chmod +x ${target_dir}/run.sh

# Print final report
echo ""
echo "All Done!"
echo "Scripts released to ${target_dir}"
echo ""

#!/usr/bin/env bash

###############
# Definitions #
###############
# pysmurf git repository
pysmurf_git_repo=https://github.com/slaclab/pysmurf.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/pysmurf/dev"

# Template directory for this application
template_dir=${template_top_dir}/pysmurf-dev

########################
# Function definitions #
########################
# Import common functions
. common.sh

# Usage message
usage()
{
    echo "Release a stand alone pysmurf application in development mode."
    echo "It uses a user provide version of pysmurf located in the 'pysmurf' folder."
    echo "This script will clone the master branch from github."
    echo
    echo "usage: ${script_name} -t pysmurf-dev -v|--version <pysmurf_version>"
    echo "                         [-o|--output-dir <output_dir>] [-h|--help]"
    echo
    echo "  -v|--version    <pysmurf_version> : Version of the pysmurf docker image. Used as a base"
    echo "                                      image; pysmurf will be overwritten by the local copy."
    echo "  -o|--output-dir <output_dir>      : Directory where to release the scripts. Defaults to"
    echo "                                      ${release_top_default_dir}"
    echo "  -l|--list-versions                : Print a list of available versions."
    echo "  -h|--help                         : Show this message."
    echo
    exit $1
}

# Print a list of all available versions
print_list_versions()
{
    echo "List of available pysmurf_version:"
    print_git_tags ${pysmurf_git_repo}
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
    pysmurf_version="$2"
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
if [ -z ${pysmurf_version+x} ]; then
        echo "ERROR: pysmurf version not defined!"
        echo ""
        usage 1
fi

# Check if the pysmurf version exist
ret=$(verify_git_tag_exist ${pysmurf_git_repo} ${pysmurf_version})
if [ -z ${ret} ]; then
    echo "ERROR: pysmurf version ${pysmurf_version} does not exist"
    echo "You can use the '-l' option to list the available versions."
    echo
    exit 1
fi

if [ -z ${target_dir+x} ]; then
    target_dir=${release_top_default_dir}/${pysmurf_version}
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
        | sed s/%%PYSMURF_VERSION%%/${pysmurf_version}/g \
        > ${target_dir}/run.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/run.sh"
    exit 1
fi

# Mark the script as executable
chmod +x ${target_dir}/run.sh

# Clone pysmurf (master branch) in the target directory
echo "Cloning pysmurf..."
cmd="git clone ${pysmurf_git_repo} ${target_dir}/pysmurf -b ${pysmurf_version}"
echo ${cmd}
${cmd}
echo

# Print final report
echo ""
echo "All Done!"
echo "Script released to ${target_dir}"
echo
echo "The tag '${pysmurf_version}' of ${pysmurf_git_repo} was checkout in ${target_dir}/pysmurf."
echo "That is the copy that runs inside the docker container."
echo ""
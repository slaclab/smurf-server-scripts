#!/usr/bin/env bash

# pysmurf git repository
pysmurf_git_repo=https://github.com/slaclab/pysmurf.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/pysmurf/dev"

# Template directory for this application
template_dir=${template_top_dir}/pysmurf-dev

# Usage message
usage()
{
    echo "
Copy the pysmurf repository at the specified version.

usage: ${script_name} -t pysmurf -v|--version <pysmurf_version>
                         [-o|--output-dir <output_dir>] [-h|--help]

  -v|--version    <pysmurf_version> : Version of the pysmurf docker image. Used as a base
                                      image; pysmurf will be overwritten by the local copy.
  -o|--output-dir <output_dir>      : Directory where to release the scripts. Defaults to
                                      ${release_top_default_dir}/<pysmurf_version>
  -l|--list-versions                : Print a list of available versions.
  -h|--help                         : Show this message."
    
    exit $1
}

# Print a list of all available versions (excluding version before v4.*)
print_list_versions()
{
    echo "List of available pysmurf_version:"
    print_git_tags ${pysmurf_git_repo} 'v3.\|v2.\|v1.\|v0.'
    echo
    exit 0
}

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

# Check if the pysmurf version exist (excluding version before v4.*)
ret=$(verify_git_tag_exist ${pysmurf_git_repo} ${pysmurf_version} 'v3.\|v2.\|v1.\|v0.')
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

# Clone pysmurf (main branch) in the target directory
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
echo
echo "If you make changes to these repositories and want to push them back to git, remember to create"
echo "and push a new branch, by running these commands in the respective directory (replace <new-branch-name>,"
echo "with an appropriate branch name):"
echo " $ git checkout -b <new-branch-name>"
echo " $ git push -set-upstream origin <new-branch-name>"
echo ""

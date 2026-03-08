#!/usr/bin/env bash

###############
# Definitions #
###############
# TPG docker git repository
tpg_git_repo=https://github.com/slaclab/smurf-tpg-ioc-docker.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/tpg"

# Template directory for this application
template_dir=${template_top_dir}/tpg

# Whether to list versions
list_versions=false

# Whether or not to list all versions, or just releases.
list_all=false

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
    echo "  -a|--all-versions                      : Include all versions, not just releases."    
    echo "  -h|--help                     : Show this message."
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
    tpg_version="$2"
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

dockerhub_tpg_tags=$(get_all_dockerhub_tags "tidair/smurf-tpg-ioc" | sort --version-sort | cat)
# Now check if we should call print_list_versions
if [[ $list_versions == true ]]; then
    #echo "List of available tpg_version:"
    #print_list_versions ${tpg_git_repo} '^$' ${list_all}
    #echo

    # The TPG docker is a special case; releases were not properly done
    # out of the git repo, and all currently live only in dockerhub.
    # Print only those, for now.
    dockerhub_tpg_tags=$(get_all_dockerhub_tags "tidair/smurf-tpg-ioc" | sort --version-sort | cat)
    echo ${dockerhub_tpg_tags} | awk '{for(i=2;i<=NF-1;i++) if (i==2) printf "*%s\n", $i; else print $i}' | tac

    exit 0
fi

# Verify parameters
if [ -z ${tpg_version+x} ]; then
        echo "ERROR: smurf-tpg-ioc version not defined!"
        echo ""
        usage 1
fi

# Check if the smurf-tpg-ioc version exist
echo "${dockerhub_tpg_tags}" | grep -q "${tpg_version}"
if [ $? -eq 1 ]; then
    echo "ERROR: smurf-tpg-ioc version ${tpg_version} does not exist"
    echo "You can use the '-l' option to list the available versions."
    echo
    exit 1
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

# Which container registry for client
image_address=$(get_docker_image_address smurf-tpg-ioc ${tpg_version})
escaped_image_address=$(printf '%s' "$image_address" | sed 's/\//\\\//g')
sed -i -e "s/\%\%DOCKER_IMAGE_ADDRESS\%\%/${escaped_image_address}/g" ${target_dir}/docker-compose.yml

# Mark the scripts as executable
chmod +x ${target_dir}/run.sh
chmod +x ${target_dir}/stop.sh

# Print final report
echo ""
echo "All Done!"
echo "Scripts released to ${target_dir}"
echo ""

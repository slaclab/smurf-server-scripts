#!/usr/bin/env bash

###############
# Definitions #
###############
# Path to folder containing the template files
template_dir=/usr/local/src/smurf-server-scripts/docker_scripts/templates

# This script name
script_name=$(basename $0)

# Default release output directory
release_default_dir="/home/cryo/docker/smurf"

########################
# Function definitions #
########################

# Usage message
usage()
{
    echo "Release a new set of scripts to run a full system"
    echo ""
    echo "usage: ${script_name} -N|--slot <slot_number> -s|--smurf2mce-version <smurf2mce_version>"
    echo "                      -p|--pysmurf_version <pysmurf_version> [-o|--output-dir <output_dir>]"
    echo "                      [-h|--help]"
    echo "    -N|--slot              <slot_number>       : ATCA crate slot number."
    echo "    -s|--smurf2mce-version <smurf2mce_version> : Version of the smurf2mce docker image"
    echo "    -p|--pysmurf_version   <pysmurf_version>   : Version of the pysmurf docker image"
    echo "    -o|--output-dir        <output_dir>        : Directory where to release the scripts. Defaults to ${release_default_dir}"
    echo "    -h|--help                                  : Show this message"
    echo ""
    exit $1
}

# copy a template file without any substitutions
# First argument is the template file name, while the
# second argument is the output file name. If the second
# argument is omitted, then the output file will have the
# same name as the template fie
copy_template()
{
        local template_file=${template_dir}/$1
        local output_file
        if [ -z "$2" ]; then
                output_file=${target_dir}/$1
        else
                output_file=${target_dir}/$2
        fi
        echo "Creating ${output_file}"

        cat ${template_file} > ${output_file}
        if [ $? -ne 0 ]; then
                echo ""
                echo "ERROR: Could not create ${output_file}"
                exit 1
        fi

        echo "Done!"
        echo ""
}

#############
# Main body #
#############

# Verify inputs arguments
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -N|--slot)
    slot_number="$2"
    shift
    ;;
    -s|--smurf2mce-version)
    smurf2mce_version="$2"
    shift
    ;;
    -p|--pysmurf_version)
    pysmurf_version="$2"
    shift
    ;;
    -o|--output-dir)
    release_dir="$2"
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
if [ -z ${slot_number+x} ]; then
        echo "ERROR: Slot number not defined!"
        echo ""
        usage 1
fi

if [ -z ${smurf2mce_version+x} ]; then
        echo "ERROR: smurf2mce version not defined!"
        echo ""
        usage 1
fi

if [ -z ${pysmurf_version+x} ]; then
        echo "ERROR: pysmurf version not defined!"
        echo ""
        usage 1
fi

if [ -z ${release_dir+x} ]; then
        release_dir=${release_default_dir}
fi
if [ -d ${release_dir} ]; then
        echo "Release directory set to: ${release_dir}"
        echo ""
else
        echo "ERROR: Release directory ${release_dir} does not exist!"
        exit 1
fi

# Create output folders
target_dir="${release_dir}/slot${slot_number}/${smurf2mce_version}/dev"

echo "Creating target directory ${target_dir}..."

if [ -d ${target_dir} ]; then
        echo "ERROR: target directory already exist!"
        exit 1
fi

mkdir -p ${target_dir}

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: could not create the target directory"
    exit 1
fi

echo "Done!"
echo ""

# Generate docker compose file
cat ${template_dir}/docker_compose.yml \
        | sed s/%%SLOT_NUMBER%%/${slot_number}/g \
        | sed s/%%PYSMURF_VERSION%%/${pysmurf_version}/g \
        | sed s/%%SMURF2MCE_VERSION%%/${smurf2mce_version}/g \
        > ${target_dir}/docker_compose.yml
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/docker_compose.yml"
    exit 1
fi

# Create run script
copy_template "run.sh"

# create stop script
copy_template "stop.sh"

# Create env file
copy_template "env" ".env"

# Print final report
echo ""
echo "All Done!"
echo "Script released to ${target_dir}"
echo "Remember to create a \"fw\" directory and placed you fw related files in there"
echo ""
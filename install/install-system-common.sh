#!/bin/bash

# Used by:
# - system
# - system-dev
#
# Each of these application specific release script will call
# this script, and perform application specific step later.
# The variable ${app_type} will point to the application type,
# and the usage_header() function is defined for each one as well.
#
# The system application has different options, so that script
# sets the flag "stable_release" before calling this script. So,
# int his script, the that flag is used to processed the options
# accordingly.

pysmurf_git_repo=https://github.com/slaclab/pysmurf.git
install_dir="/home/cryo/docker/smurf"
target_dir=${install_dir}/${target_dir_prefix}

usage() {
    echo "Install the pysmurf server and client.

-v version : Version of the client and server to install.
-o output_dir : Output directory for the installation. Default ${install_dir}.
-c comm_type : Type of communication with the FPGA: eth or pcie.
-l : List available versions."
}

while [[ $# -gt 0 ]]; do
    case $1 in
	-v|--version)
	    version=$2
	    shift
	    ;;
	-o|--output-dir)
	    target_dir="$2"
	    shift
	    ;;
	-c|--comm-type)
	    comm_type="$2"
	    shift
	    ;;
	-l|--list-versions)
	    list_versions ${pysmurf_git_repo} 'v5.0.0\|v4.\|v3.\|v2.\|v1.\|v0.'
	    ;;
	-h|--help)
	    usage 0
	    ;;
    esac
    shift
done

case ${comm_type} in
    eth)
	comm_args="-c eth"
	;;
    pcie)
	comm_args="-c pcie"
	;;
    *)
	error "Invalid communication type ${comm_type}."
	;;
esac


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

# Generate file specific to this type of application, and for an specific slot number
template_dir=${template_top_dir}/${app_type}

cat ${template_dir}/docker-compose.yml \
    | sed s/%%SLOT_NUMBER%%/${slot_number}/g \
    | sed s/%%VERSION%%/${version}/g \
    | sed s/%%COMM_ARGS%%/"${comm_args}"/g \
          > ${target_dir}/docker-compose.yml
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/docker-compose.yml"
    exit 1
fi

# Generate file common to other type of application
template_dir=${template_top_dir}/common

cat ${template_dir}/docker-compose.pcie.yml \
    | sed s/%%SLOT_NUMBER%%/${slot_number}/g \
          > ${target_dir}/docker-compose.pcie.yml
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/docker-compose.pcie.yml"
    exit 1
fi

copy_template "run.sh"
copy_template "stop.sh"
copy_template "base.sh"
copy_template "env" ".env"

chmod +x ${target_dir}/run.sh
chmod +x ${target_dir}/stop.sh

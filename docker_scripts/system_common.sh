#!/usr/bin/env bash

# This script contains steps common to application types:
# - system
# - system-dev-fw
# - system-dev-sw
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

###############
# Definitions #
###############
# Git repositories
## rogue
rogue_git_repo=https://github.com/slaclab/rogue.git

## pysmurf
pysmurf_git_repo=https://github.com/slaclab/pysmurf.git

## pysmurf stable docker images
pysmurf_stable_git_repo=https://github.com/slaclab/pysmurf-stable-docker.git

# Default release output directory
release_top_default_dir="/home/cryo/docker/smurf"

########################
# Function definitions #
########################
# Import common functions
. common.sh

# Usage message
# Development releases need only 1 version, while stable
# releases need 2 version, the server and the client.
usage()
{
    usage_header
    echo "usage: ${script_name} -t ${app_type}"
    if [ -z ${stable_release+x} ]; then
        echo "                         -v|--version <pysmurf_version>"
    else
        echo "                         -v|--version <pysmurf_server_version>"
    fi
    echo "                         [-N|--slot <slot_number>]"
    echo "                         [-o|--output-dir <output_dir>]"
    echo "                         [-l|--list-versions]"
    echo "                         [-h|--help]"
    echo
    if [ -z ${stable_release+x} ]; then
        echo "  -v|--version        <pysmurf_version>        : Version of the pysmurf server/client images."
    else
        echo "  -v|--version        <pysmurf_server_version> : Version of the pysmurf-server docker image."
    fi
    echo "  -c|--comm-type      <commm_type>             : Communication type with the FPGA (eth or pcie). Defaults to 'eth'."
    echo "  -N|--slot           <slot_number>            : ATCA crate slot number (2-7) (Optional)."
    echo "  -o|--output-dir     <output_dir>             : Top directory where to release the scripts. Defaults to"
    echo "                                                 ${release_top_default_dir}/${target_dir_prefix}/<slot_number>/<pysmurf_version>"
    echo "  -l|--list-versions                           : Print a list of available versions."
    echo "  -h|--help                                    : Show this message."
    echo
    exit $1
}

# Print a list of all available versions
print_list_versions()
{
    if [ -z ${stable_release+x} ]; then
        # For development releases, print pysmurf versions (excluding version before v4.*)
        echo "List of available pysmurf_version:"
        print_git_tags ${pysmurf_git_repo} 'v3.\|v2.\|v1.\|v0.'
    else
        # For stable releases, print stable pysmurf-server versions
        echo "List of available pysmurf_server_version:"
        print_git_tags ${pysmurf_stable_git_repo}
    fi

    echo
    exit 0
}

#############
# Main body #
#############

# Default values
comm_type='eth'

# Verify inputs arguments
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -v|--version)
    # For development releases, this is the pysmurf version.
    # For stable released, this is the pysmurf-server version.
    if [ -z ${stable_release+x} ]; then
        pysmurf_version="$2"
        shift
    else
        server_version="$2"
        shift
    fi
    ;;
    -o|--output-dir)
    target_dir="$2"
    shift
    ;;
    -c|--comm-type)
    comm_type="$2"
    shift
    ;;
    -N|--slot)
    slot_number="$2"
    shift
    ;;
    -l|--list-versions)
    print_list_versions
    ;;
    -h|--help)
    usage 0
    ;;
    *)
    echo "ERROR: Unknown argument"
    echo
    usage 1
    ;;
esac
shift
done

# Verify parameters
if [ -z ${stable_release+x} ]; then
    # For no stable releases, we only need the pysmurf version
    if [ -z ${pysmurf_version+x} ]; then
            echo "ERROR: pysmurf version not defined!"
            echo ""
            usage 1
    fi

    # Check if the pysmurf_version exist (excluding version before v4.*)
    ret=$(verify_git_tag_exist ${pysmurf_git_repo} ${pysmurf_version} 'v3.\|v2.\|v1.\|v0.')
    if [ -z ${ret} ]; then
        echo "ERROR: pysmurf version ${pysmurf_version} does not exist"
        echo "You can use the '-l' option to list the available versions."
        echo
        exit 1
    fi

    # The server and client version are the same in this case
    server_version=${pysmurf_version}
    client_version=${pysmurf_version}
else
    # For stable releases, we only need server version
    if [ -z ${server_version+x} ]; then
            echo "ERROR: pysmurf server version not defined!"
            echo ""
            usage 1
    fi

    # Check if the server version exist
    ret=$(verify_git_tag_exist ${pysmurf_stable_git_repo} ${server_version})
    if [ -z ${ret} ]; then
        echo "ERROR: pysmurf server version ${server_version} does not exist"
        echo "You can use the '-l' option to list the available versions."
        echo
        exit 1
    fi

    # Now we need to look for the corresponding pysmurf client version
    client_version=$(get_pysmurf_version ${server_version})

    # Check if a version of pysmurf was found
    if [ ! ${client_version} ]; then
        echo "Error: pysmurf version not found for server version ${server_version}"
        echo
        exit 1
    fi

    # Check if the client version exist (excluding version before v4.*)
    ret=$(verify_git_tag_exist ${pysmurf_git_repo} ${client_version} 'v3.\|v2.\|v1.\|v0.')
    if [ -z ${ret} ]; then
        echo "ERROR: pysmurf version ${client_version} does not exist"
        echo
        exit 1
    fi

fi

# Verify the communication type
case ${comm_type} in
    eth)
    comm_args="-c eth"
    ;;
    pcie)
    comm_args="-c pcie"
    ;;
    *)
    echo
    echo "ERROR: Invalid communication type!"
    echo
    usage 1
    ;;
esac

# Verify if the slot number was defined
if [ -z ${slot_number+x} ]; then
    # If the slot number was not defined, the directory prefix will be "slotN"
    slot_prefix="slotN"

    # If the slot number was not defined, we will use the templates from the
    # 'any-slot' directory
    template_prefix="any-slot"
else
    # Verify that the slot number is valid
    if [[ (${slot_number} < 2) || (${slot_number} > 7) ]]; then
        echo "Invalid slot number. Must be a number between 2 and 7."
        echo
        usage 1
    fi

    # If the slot number was defined, the directory prefix will be "slot<slot_number>"
    slot_prefix="slot${slot_number}"

    # If the slot number was defined, we will use the templates from the
    # 'specific-slot' directory
    template_prefix="specific-slot"
fi

# Generate target directory
if [ -z ${target_dir+x} ]; then
    target_dir=${release_top_default_dir}/${target_dir_prefix}/${slot_prefix}/${server_version}
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

# Generate file specific to this type of application, and for an specific slot number
template_dir=${template_top_dir}/${app_type}/${template_prefix}


cat ${template_dir}/docker-compose.yml \
        | sed s/%%SLOT_NUMBER%%/${slot_number}/g \
        | sed s/%%SERVER_VERSION%%/${server_version}/g \
        | sed s/%%CLIENT_VERSION%%/${client_version}/g \
        | sed s/%%COMM_ARGS%%/"${comm_args}"/g \
        > ${target_dir}/docker-compose.yml
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not create ${target_dir}/docker-compose.yml"
    exit 1
fi

# Generate file common to other type of application
template_dir=${template_top_dir}/common/${template_prefix}

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
# Copy the base.sh common script only when the slot number is not defined
if [ -z ${slot_number+x} ]; then
    copy_template "base.sh"
fi

# Copy the .env file, which is common independent of the slot selection
template_dir=${template_top_dir}/common
copy_template "env" ".env"

# Mark the scripts as executable
chmod +x ${target_dir}/run.sh
chmod +x ${target_dir}/stop.sh
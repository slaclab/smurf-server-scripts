#!/usr/bin/env bash

# smurf server scripts git repository
server_scripts_git_repo=https://github.com/slaclab/smurf-server-scripts.git

# Top directory
top_dir=$(dirname -- "$(readlink -f $0)")

# Path to folder containing the template files
template_top_dir=${top_dir}/templates

# This script name
script_name=$(basename $0)

# Script version
version=$(cd ${top_dir} && git describe --tags --always --dirty)

# Import common functions
. common.sh

# Usage message
usage()
{
    echo "Script that provides SMuRF software. Does not set up the server, use setup-server.sh for that.

version: $version

usage: $(basename $0) -t|--type type [-h|--help]

  -t|--type type : Type of application to install. Options are:
    - system       : SMuRF software with preinstalled pysmurf, rogue, and firmware.
    - system-dev   : 'system' with modifiable pysmurf, rogue, and firmware files.
    - pysmurf      : Copy of the pysmurf repository.
    - utils        : The utility software, commonly used in operations.
    - tpg          : The timing software.
    - pcie         : PCIe software for 6-carrier operation.
    - atca-monitor : Interface to view ATCA crate information.
    - guis         : Interface to modify running systems.
  -u|--upgrade version : Upgrade this script to another version.
  -l|--list-versions : List this script's available versions.
  -h|--help : Show help. Use with -t for type help.
"
    exit $1
}

# Function to copy stuff from template_dir to target_dir. Used in
# system_common.sh and release-tpg.sh. Copy filename template_dir/$1
# to target_dir/$2, or target_dir/$1 if $2 is not specified.
copy_template()
{
        local template_file=${template_dir}/$1
        local output_file
        if [ -z "$2" ]; then
                output_file=${target_dir}/$1
        else
                output_file=${target_dir}/$2
        fi

        cat ${template_file} > ${output_file}
        if [ $? -ne 0 ]; then
                echo ""
                echo "ERROR: Could not create ${output_file}"
                exit 1
        fi

	echo "Copied ${output_file} from ${template_file}."
}

# Print a list of all available versions
print_list_versions()
{
    # The version list and upgrade feature was added in version R3.1.0,
    # so exclude previous versions.
    echo "List of available versions of this script:"
    print_git_tags ${server_scripts_git_repo} 'R1.\|R2.\|R3.0'
    echo
    exit 0
}

# Update these scripts
update_self()
{
    local tag="$1"

    cd ${top_dir}
    
    if [ -z ${tag} ]; then
        echo "No reference specified. Using branch main of ${server_scripts_git_repo}. Use -l if you want some specific version."
        sudo bash -c "git fetch --all --tags && git checkout main && git pull"
    else
        echo "Updating ${script_name} to version ${tag} of ${server_scripts_git_repo}."
        sudo bash -c "git fetch --all --tags && git checkout ${tag}"
    fi

    ret=$?
    cd - > /dev/null

    if [ ${ret} == 0 ]; then
        echo "Done, scripts now in ${top_dir}."
    else
        echo "Failed."
    fi

    exit ${ret}
}

app_options=""
# Verify inputs arguments
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -t|--type)
    app_type="$2"
    shift
    ;;
    -l|--list-versions)
    show_versions=1
    app_options="${app_options} ${key}"
    ;;
    -u|--upgrade)
    update_self "$2"
    ;;
    -h|--help)
    show_help=1
    app_options="${app_options} ${key}"
    ;;
    *)
    app_options="${app_options} ${key}"
    ;;
esac
shift
done

# Verify parameters
if [ -z ${app_type+x} ]; then

        # Show usage message when option '-h' was used
        # without defining an application type
        if [ ! -z ${show_help} ]; then
            usage 0
        fi

        # Print the available versions when option '-l'
        # was used without defining an application type.
        if [ ! -z ${show_versions} ]; then
            print_list_versions
        fi

        usage 1
fi

# Now call the application specific script
case ${app_type} in
    system)
    . ${top_dir}/release_system.sh ${app_options}
    ;;
    system-dev)
    . ${top_dir}/release_system_dev.sh ${app_options}
    ;;
    pysmurf)
    . ${top_dir}/release_pysmurf.sh ${app_options}
    ;;
    utils)
    . ${top_dir}/release_utils.sh ${app_options}
    ;;
    tpg)
    . ${top_dir}/release_tpg.sh ${app_options}
    ;;
    pcie)
    . ${top_dir}/release_pcie.sh ${app_options}
    ;;
    atca-monitor)
    . ${top_dir}/release_atca_monitor.sh ${app_options}
    ;;
    guis)
    . ${top_dir}/release_guis.sh ${app_options}
    ;;
    *)
    echo "ERROR: Invalid application type!"
    usage 1
    ;;
esac

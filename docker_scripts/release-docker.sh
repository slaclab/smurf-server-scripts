#!/usr/bin/env bash

###############
# Definitions #
###############
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

########################
# Function definitions #
########################
# Import common functions
. common.sh

# Usage message
usage()
{
    echo "Release a new set of scripts to run an specified system based on dockers."
    echo "Version: ${version}"
    echo
    echo "usage: ${script_name} -t|--type <app_type> [-h|--help]"
    echo
    echo "  -t|--type <app_type>   : Type of application to install. Options are:"
    echo "                           - system         : Full system (stable version) [pysmurf/rogue v4]."
    echo "                           - system-dev-fw  : Full system (with a development version of FW) [pysmurf/rogue v4]."
    echo "                           - system-dev-sw  : Full system with a development version of SW and FW [pysmurf/rogue v4]."
    echo "                           - system3        : Full system (stable version) [smurf2mce/rogue v3]."
    echo "                           - system3-dev-fw : Full system (with a development version of FW) [smurf2mce/rogue v3]."
    echo "                           - system3-dev-sw : Full system with a development version of SW and FW [smurf2mce/rogue v3]."
    echo "                           - pysmurf-dev    : A stand-alone version of pysmurf, in development mode."
    echo "                           - utils          : A utility system."
    echo "                           - tpg            : A TPG IOC."
    echo "                           - pcie           : A PCIe utility application."
    echo "                           - atca-monitor   : An ATCA monitor application."
    echo "  -u|--upgrade [version] : Upgrade these scripts to the specified version. If not version if specified, then the head"
    echo "                           of the master branch will be used. Note: You will be asked for the sudo password."
    echo "  -l|--list-versions     : Print a list of available versions."
    echo "  -h|--help              : Show help message for each application type."
    echo
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

# Print a list of all available versions
print_list_versions()
{
    echo "List of available versions of this script:"
    print_git_tags ${server_scripts_git_repo}
    echo
    exit 0
}

# Update these scripts
update_scripts()
{
    local tag="$1"

    # If not version was specified, user 'master'
    if [ -z ${tag} ]; then
        tag="master"
    fi

    echo "Updating these scripts to '${tag}'..."

    cd ${top_dir}
    sudo bash -c "git fetch --all --tags && git checkout ${tag} && git pull"
    ret=$?
    cd - > /dev/null

    if [ ${ret} == 0 ]; then
        echo "Done!"
    else
        echo "Failed!"
    fi

    exit ${ret}
}

#############
# Main body #
#############

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
    update_scripts "$2"
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

        echo "ERROR: Must specified the application type!"
        echo ""
        usage 1
fi

# Now call the application specific script
case ${app_type} in
    system)
    . ${top_dir}/release_system.sh ${app_options}
    ;;
    system-dev-fw)
    . ${top_dir}/release_system_dev_fw.sh ${app_options}
    ;;
    system-dev-sw)
    . ${top_dir}/release_system_dev_sw.sh ${app_options}
    ;;
    system3)
    . ${top_dir}/release_system3.sh ${app_options}
    ;;
    system3-dev-fw)
    . ${top_dir}/release_system3_dev_fw.sh ${app_options}
    ;;
    system3-dev-sw)
    . ${top_dir}/release_system3_dev_sw.sh ${app_options}
    ;;
    pysmurf-dev)
    . ${top_dir}/release_pysmurf_dev.sh ${app_options}
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
    *)
    echo "ERROR: Invalid application type!"
    usage 1
    ;;
esac

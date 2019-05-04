#!/usr/bin/env bash

###############
# Definitions #
###############
# Top directory
top_dir=/usr/local/src/smurf-server-scripts/docker_scripts

# Path to folder containing the template files
template_top_dir=${top_dir}/templates

# This script name
script_name=$(basename $0)

########################
# Function definitions #
########################

# Usage message
usage()
{
    echo "Release a new set of scripts to run an specified system based on dockers."
    echo
    echo "usage: ${script_name} -t|--type <app_type> [-h|--help]"
    echo
    echo "  -t|--type <app_type> : Type of application to install. Options are:"
    echo "                         - system        = Full system (stable version)."
    echo "                         - system-dev-fw = Full system (with a development version of FW)."
    echo "                         - system-dev-sw = Full system with a development version of SW and FW."
    echo "                         - pysmurf-dev   = A stand-alone version of pysmurf, in development mode."
    echo "                         - utils         = A utility system."
    echo "  -h|--help            : Show help message for each application type."
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

        # Show usage message when argument '-h' was used
        # without defining an application type
        if [ ! -z ${show_help} ]; then
            usage 0
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
    pysmurf-dev)
    . ${top_dir}/release_pysmurf_dev.sh ${app_options}
    ;;
    utils)
    . ${top_dir}/release_utils.sh ${app_options}
    ;;
    *)
    echo "ERROR: Invalid application type!"
    usage 1
    ;;
esac
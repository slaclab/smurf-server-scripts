#!/bin/bash

template_top_dir=${top_dir}/install/templates

function usage {
    echo "Script that installs SMuRF software. Assumes the OS has been configured already.
Usage: -t type 

  -t type : Type of installed application.
    - system       : SMuRF software with preinstalled pysmurf, rogue, and firmware.
    - system-dev   : 'system' with modifiable pysmurf, rogue, and firmware files.
    - pysmurf-dev  : Pysmurf client with modifiable pysmurf files.
    - utils        : Utility software.
    - tpg          : Timing software.
    - pcie         : PCIe software for 6-carrier operation. 
    - atca-monitor : Interface to view ATCA crate information.
    - gui          : Interface to modify Rogue registers.
"
}

function error () {
    echo "Error: $1"
    exit 1
}

# Function to copy stuff from template_dir to target_dir. Used in
# system_common.sh and release-tpg.sh. Copy filename template_dir/$1
# to target_dir/$2, or target_dir/$1 if $2 is not specified.
function copy_template {
    local template_file=${template_dir}/$1
    local output_file
    if [ -z "$2" ]; then
	output_file=${target_dir}/$1
    else
	output_file=${target_dir}/$2
    fi

    cat ${template_file} > ${output_file}
    if [ $? -ne 0 ]; then
	error "Could not create ${output_file}"
    fi

    echo "Copied ${template_file} to ${output_file}"
}

while [[ $# -gt 0 ]]; do
    # e.g. $1 $2 $3 = -t system -l
    case $1 in
	-t)
	    case $2 in
		system)
		    goto_script install/install-system.sh "${@:3}"
		    ;;
		system-dev)
    		    goto_script install/install-system_dev.sh ${version}
    		    ;;
		pysmurf-dev)
    		    goto_script install/install-pysmurf.sh ${version}
    		    ;;
		utils)
    		    goto_script install/install-utils.sh ${version}
    		    ;;
		tpg)
    		    goto_script install/install-tpg.sh ${version}
    		    ;;
		pcie)
    		    goto_script install/install-pcie.sh ${version}
    		    ;;
		atca-monitor)
    		    goto_script install/install-atca_monitor.sh ${version}
    		    ;;
		guis)
    		    goto_script install/install-guis.sh ${version}
    		    ;;
		*)
    		    usage
    		    error "Invalid application type $type." 
        	    ;;
            esac
	    shift
	    ;;
	*)
	    usage
	    ;;
    esac
    shift
done

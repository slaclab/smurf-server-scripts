#!/bin/bash

function usage {
    echo "Run SMuRF software that was recently deployed.

Usage: -t type [-v version | -l]
    	 
  -t type : Type of application that was deployed.
    - system       : SMuRF software with preinstalled pysmurf, rogue, and firmware.
    - system-dev   : 'system' with modifiable pysmurf, rogue, and firmware files.
    - pysmurf-dev  : The pysmurf client with modifiable pysmurf files.
    - utils        : The utility software.
    - tpg          : The timing software.
    - pcie         : The PCIe software for 6-carrier operation. 
    - atca-monitor : Interface to view ATCA crate information.
    - guis         : Interface to modify running systems.
  -v version : Version of the application to run.
  -l : List available versions of type.
"
    exit 1
}

script_dir=$(dirname -- "$(readlink -f $0)")
script_name=$(basename $0)

function goto_script {
    . $script_dir/$1
}

function parse_arguments {
    while getopts "t" opt; do
	case ${opt} in
	    h)
		usage
		;;
	    t)
		type=$2
		;;
	    l)
		list_versions=true
		;;
	    \?)
		usage
		;;
	esac
    done

    if [ $OPTIND -eq 1 ]; then
	usage
    fi
}

parse_arguments

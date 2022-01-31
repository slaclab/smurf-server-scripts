#!/bin/bash

function usage {
    echo "Run SMuRF software.
Usage: 
  -t type
    - system       : SMuRF software with preinstalled pysmurf, rogue, and firmware.
    - system-dev   : 'system' with modifiable pysmurf, rogue, and firmware files.
    - utils        : Utility software.
    - tpg          : Timing software.
    - pcie         : PCIe software for 6-carrier operation. 
    - atca-monitor : Interface to view ATCA crate information.
    - gui          : Interface to modify Rogue registers."
}

if [ $# -eq 1 ]; then
    usage
fi

while getopts "t:" opt; do
    case ${opt} in
        t)
    	type=$2
    	;;
    esac
    shift
done

case $type in
	system)
		goto_script run/run-system.sh
		;;
	system-dev)
		goto_script run/run-system-dev.sh
		;;
	*)
		error "Invalid type $type"
		;;
esac

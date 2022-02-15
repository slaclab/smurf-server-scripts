#!/usr/bin/env bash

function usage {
    echo "Start the SMuRF software on one particular slot. This means writing
    the firmware, turning on the PCIe card, enabling the AMC bays, rebooting
    the firmware, and starting the high level pysmurf software. After this
    script finishes, one container should be running the SMuRF server and one
    should be running the SMuRF client. Send pysmurf commands to the client.
Usage:
 -r : Run the software. Requires -n and -v.
 -s : Stop the software. Requires -n.
 -n slot : Slot number to operate on.
 -v version : Version to run."
}

function wait_for_ping {
    # Try to ping the IP, or exit after 30 seconds.
    # $1 IP address of specific carrier. e.g. 10.0.1.103.
    echo "Trying to ping $1..."
    ping -c 30 $1

    if [ $? > 0 ]; then
	    error "Couldn't ping $1. Check the network and try again."
    fi
}

function reactivate {
    echo "Deactivating and activating slot $slot using ssh to shm-smrf-sp01."
    deactivatecmd="clia deactivate board $slot"
    ssh root@shm-smrf-sp01 "$deactivatecmd"

    sleep 5

    activatecmd="clia activate board $slot"
    ssh root@shm-smrf-sp01 "$activatecmd"
}

function verify_args {
if [ -z ${slot+x} ]; then
    error "Slot number not defined."
else
    if ! [ ${slot} -ge 2 -a ${slot} -le 7 ]; then
        error "Invalid slot number. Must be a number between 2 and 7."
    fi
fi
}

if [ $# -eq 1 ]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case $1 in
	-r)
	    slot=$2
	    shift
	    ;;
	-v)
		version=$2
		shift
		;;
    esac
    shift
done

verify_args

reactivate

wait_for_ping 10.0.1.$((${slot}+100))

# If the PCIe card in present in the system, use the PCIe related
# docker-compose file as well. This doesn't automatically change the -c
# flag in start-server.sh.
pcie_flags=""
if [ -c /dev/datadev_0 ] && [ -c /dev/datadev_1 ]; then
    pcie_flags+=" -f $script_dir/system/docker-compose-pcie.yml"
fi

# docker-compose doesn't inherit 
slot=${slot} docker-compose -f $script_dir/system/docker-compose.yml ${pcie_flags} up"


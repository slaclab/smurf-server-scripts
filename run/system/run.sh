#!/usr/bin/env bash

# Used by:
# system
# system-dev

args=$@
script_name=$(basename $0)

function usage {
    echo "Start the SMuRF software on one particular slot. Run
this on multiple slots to set up the entire crate. By
starting one slot, I mean programming the carrier firmware
if required, turning on the PCIe card if required, turning
on the AMC bays if present, starting the firmware, and
starting the high level pysmurf software. After this script
finishes, one container should be running the SMuRF server
and one should be running the SMuRF client. Send pysmurf
commands to the client.
Usage:
 -n slot : ATCA crate slot number. "
}

run_cmd_with_echo() {
    echo "Running '$@'"
    eval "$@"
}

function wait_for_ping {
    # Try to ping the IP, or exit after 30 seconds.
    # $1 IP address of specific carrier. e.g. 10.0.1.103.
    echo "Trying to ping $1..."
    timeout 30 ping -c 1 $1

    if [ $? > 0 ]; then
	    error "Couldn't ping $1. Check the network and try again."
    fi
}

function reactivate {
    echo "Deactivating and activating slot ${slot} using ssh to ${shelfmanager}."
    deactivatecmd="clia deactivate board ${slot}"
    ssh root@${shelfmanager} "$deactivatecmd"

    sleep 5

    activatecmd="clia activate board ${slot}"
    ssh root@${shelfmanager} "$activatecmd"
}

if [ $# -eq 0 ]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    key="$1"

    case ${key} in
	-n)
	    slot="$2"
	    ;;
    esac
    shift
done

if [ -z ${slot+x} ]; then
    usage "Slot number not defined."
else
    if ! [ ${slot} -ge 2 -a ${slot} -le 7 ]; then
        usage "Invalid slot number. Must be a number between 2 and 7."
    fi
fi

goto_script run/system/stop.sh

reactivate

wait_for_ping 10.0.1.$((${slot}+100))

# If the PCIe card in present in the system, use the
# PCIe related docker-compose file as well
extra_composes=""
if [ -c /dev/datadev_0 ] && [ -c /dev/datadev_1 ]; then
    extra_composes+=" -f docker-compose.pcie.yml"
fi

run_cmd_with_echo "slot=${slot} extra_opts=${extra_opts} docker-compose -f $top_dir/run/system/docker-compose.yml ${extra_composes} up"


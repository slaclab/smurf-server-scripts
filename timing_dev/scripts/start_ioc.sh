#!/usr/bin/env bash

# Start the timing software. This script should be the entrypoint of
# the docker container.

# Usage
# 1. -a fpga_ip, or
# 2. -s shelfmanager_name and -n slot

# -s shelfmanager_name Hostname of the shelfmanager.
# -n slot_number ATCA crate slot number. Must be used with -S.
# -a fpga_ip FPGA IP address. If defined, -S and -N are ignored.
# -p prefix PV name prefix. Default 'TPG:SMRF:1'

prefix="TPG:SMRF:1"
shelfmanager='shm-smrf-sp01'
slot=2
top_pid=$$

# This script name
script_name=$(basename $0)

# Trap TERM signals and exit
trap "echo '$script_name: Unknown error.'; exit 1" TERM

error() {
    echo "$script_name: Error: " $1
    exit 1
}

getCrateId() {
    echo "Getting crate ID via IPMI given shelfmanager $shelfmanager and slot $slot..."
    
    ipmb=$(expr 0128 + 2 \* $slot)
    
    local crate_id_str

    crate_id_str=$(ipmitool -I lan -H $shelfmanager -t $ipmb -b 0 -A NONE raw 0x34 0x04 0xFD 0x02 2> /dev/null)

    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
    fi

    local crate_id=`printf %04X  $((0x$(echo $crate_id_str | awk '{ print $2$1 }')))`

    if [ -z ${crate_id} ]; then
        kill -s TERM ${top_pid}
    fi

    echo ${crate_id}
}

getFpgaIp() {
    # Calculate FPGA IP subnet from the crate ID
    local subnet="10.$((0x${crate_id:0:2})).$((0x${crate_id:2:2}))"

    # Calculate FPGA IP last octect from the slot number
    local fpga_ip="${subnet}.$(expr 100 + $slot)"

    echo ${fpga_ip}
}

while [[ $# -gt 0 ]]; do
    key="$1"

    case ${key} in
	-S|--shelfmanager)
	    shelfmanager="$2"
	    shift
	    ;;
	-N|--slot)
	    slot="$2"
	    shift
	    ;;
	-a|--addr)
	    fpga_ip="$2"
	    shift
	    ;;
	-p|--prefix)
	    prefix="$2"
	    shift
	    ;;
	*)
	    args="${args} $key"
	    ;;
    esac
    shift
done

echo

# Set fpga_ip
# Set crate_id
if [ -z ${fpga_ip+x} ]; then
    # If the IP address is not defined, shelfmanager and slot number must be defined

    if [ -z ${shelfmanager+x} ]; then
	error 'Variable shelfmanager not defined.'
    fi

    if [ -z ${slot+x} ]; then
        echo 'Variable slot not defined'
    fi

    echo "IP address was not defined. It will be calculated automatically from the crate ID and slot number..."
    
    crate_id=$(getCrateId)
    echo "Crate ID: ${crate_id}"

    echo "Calculating FPGA IP address..."
    fpga_ip=$(getFpgaIp)
    echo "FPGA IP: ${fpga_ip}"

else
    echo "IP address was defined. Ignoring shelfmanager and slot number."
fi

echo "Starting IOC..."
cd iocBoot/sioc-smrf-ts01/
PREFIX=${prefix} FPGA_IP=${fpga_ip} ./st.cmd

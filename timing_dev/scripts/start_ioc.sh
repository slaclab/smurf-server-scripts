#!/usr/bin/env bash

###############
# Definitions #
###############
# Shell PID
top_pid=$$

# This script name
script_name=$(basename $0)

########################
# Function definitions #
########################

# Trap TERM signals and exit
trap "echo 'An ERROR was found. Aborting...'; exit 1" TERM

# Usage message
usage()
{
    echo "Start the TPG IOC."
    echo
    echo "usage: ${script_name} [-S|--shelfmanager <shelfmanager_name> -N|--slot <slot_number>]"
    echo "                      [-a|--addr <fpga_ip>] [-p|--prefix <epics_prefix>] [-h|--help]"
    echo
    echo "    -S|--shelfmanager <shelfmanager_name> : ATCA shelfmanager node name or IP address. Must be used with -N."
    echo "    -N|--slot         <slot_number>       : ATCA crate slot number. Must be used with -S."
    echo "    -a|--addr         <fpga_ip>           : FPGA IP address. If defined, -S and -N are ignored."
    echo "    -p|--prefix       <epics_prefix>      : PV name prefix. Defaults to 'TPG:SMRF:1'"
    echo "    -h|--help                             : Show this message."
    echo
    echo "If -a if not defined, then -S and -N must both be defined, and the FPGA IP address will be automatically calculated from the crate ID and slot number."
    echo "If -a if defined, -S and -N are ignored."
    echo
    exit $1
}

getCrateId()
{
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

getFpgaIp()
{

    # Calculate FPGA IP subnet from the crate ID
    local subnet="10.$((0x${crate_id:0:2})).$((0x${crate_id:2:2}))"

    # Calculate FPGA IP last octect from the slot number
    local fpga_ip="${subnet}.$(expr 100 + $slot)"

    echo ${fpga_ip}
}

#############
# Main body #
#############

# Default prefix
prefix="TPG:SMRF:1"

# Verify inputs arguments
while [[ $# -gt 0 ]]
do
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
    -h|--help)
    usage
    ;;
    *)
    args="${args} $key"
    ;;
esac
shift
done

echo

# Verify mandatory parameters

# Check IP address or shelfmanager/slot number
if [ -z ${fpga_ip+x} ]; then
    # If the IP address is not defined, shelfmanager and slot number must be defined

    if [ -z ${shelfmanager+x} ]; then
        echo "Shelfmanager not defined!"
        usage
    fi

    if [ -z ${slot+x} ]; then
        echo "Slot number not defined!"
        usage
    fi

    echo "IP address was not defined. It will be calculated automatically from the crate ID and slot number..."

    ipmb=$(expr 0128 + 2 \* $slot)

    echo "Reading Crate ID via IPMI..."
    crate_id=$(getCrateId)
    echo "Create ID: ${crate_id}"

    echo "Calculating FPGA IP address..."
    fpga_ip=$(getFpgaIp)
    echo "FPGA IP: ${fpga_ip}"

else
    echo "IP address was defined. Ignoring shelfmanager and slot number."
fi

echo "Starting IOC..."
cd iocBoot/sioc-smrf-ts01/
PREFIX=${prefix} FPGA_IP=${fpga_ip} ./st.cmd
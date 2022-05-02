#!/usr/bin/env bash
#-----------------------------------------------------------------------------
# Title      : ProgramFPGA
#-----------------------------------------------------------------------------
# File       : ProgramFPGA.bash
# Created    : 2019-03-15
#-----------------------------------------------------------------------------
# Description:
# Bash script to program the HPS FPGA image for docker environments.
#-----------------------------------------------------------------------------
# This file is part of the ProgramFPGA software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

###############
# Definitions #
###############

# Shell PID
top_pid=$$

# TOP directory
TOP=$( dirname "${BASH_SOURCE[0]}" )

# YAML files location
yaml_top=$TOP/yaml

########################
# Function definitions #
########################

# Usage message
usage() {
    echo "usage: ProgramFPGA.bash -s|--shelfmanager shelfmanager_name -n|--slot slot_number -m|--mcs mcs_file [-f|--fsb] [-h|--help]"
    echo "    -s|--shelfmanager shelfmaneger_name      : name of the crate's shelfmanager"
    echo "    -n|--slot         slot_number            : logical slot number"
    echo "    -m|--mcs          mcs_file               : path to the mcs file. Can be given in GZ format"
    echo "    -f|--fsb                                 : use first stage boot (default to second stage boot)"
    echo "    -h|--help                                : show this message"
    echo
}

# Get the Build String
getBuildString()
{
    local addr=0x1000
    local addr_step=0x10
    local bs_len=0x100
    local bs

    for i in $( seq 1 $((bs_len/addr_step)) ); do
        bs=${bs}$(ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x34 $((addr/0x100)) $((addr%0x100)) ${addr_step} 2> /dev/null)

        # Verify IPMI errors
        if [ "$?" -ne 0 ]; then
            kill -s TERM ${top_pid}
            exit
        fi

        addr=$((addr+addr_step))
    done

    echo ${bs}
}

# Get FPGA Version
getFpgaVersion()
{
    local ver_inv
    local ver

    ver_inv=$(ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x34 0x04 0xf2 0x04 2> /dev/null)

    # Verify IPMI errors
    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    for c in ${ver_inv} ; do ver="${c}"${ver} ; done

    echo ${ver}
}

# Set 1st stage boot
setFirstStageBoot()
{
    printf "Setting boot address to 1st stage boot...         "
    ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x34 0xF1 0 0 0 0 &> /dev/null

    # Verify IPMI errors
    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    sleep 1

    ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x34 0xF0 &> /dev/null

    # Verify IPMI errors
    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    sleep 1

    printf "Done\n"

    rebootFPGA
}

# Set 2nd stage boot
setSecondStageBoot()
{
    printf "Setting boot address back to 2nd stage boot...    "
    ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x34 0xF1 4 0 0 0 &> /dev/null

    # Verify IPMI errors
    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
    fi

    sleep 1

    ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x34 0xF0 &> /dev/null

    # Verify IPMI errors
    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    sleep 1

    printf "Done\n"

    rebootFPGA
}

# Reboot FPGA
rebootFPGA()
{
    local bsi_state
    # If we know the FPGA IP, we try to ping it
    # ${retry_max} times, with a delay of ${retry_delay}
    # second between failed pings
    local retry_max=10
    local retry_delay=10
    # If we do not know the FPGA IP, when we simply wait for
    # ${no_ping_delay} seconds after the the FGPA boots.
    local no_ping_delay=40

    printf "Sending reboot command to FPGA...                 "
    ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x2C 0x0A 0 0 2 0 &> /dev/null

    # Verify IPMI errors
    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    sleep 1

    ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x2C 0x0A 0 0 1 0 &> /dev/null

    # Verify IPMI errors
    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    printf "Done\n"

    printf "Waiting for FPGA to boot...                       "

    # Wait until FPGA boots
    for i in $(seq 1 ${retry_max}); do

        sleep ${retry_delay}
        bsi_state=$(ipmitool -I lan -H ${shelfmanager} -t ${ipmb} -b 0 -A NONE raw 0x34 0xF4 2> /dev/null | awk '{print $1}')

        # Verify IPMI errors
        if [ "$?" -eq 0 ] && [ ${bsi_state} -eq 3 ]; then
            local ready_fpga=1
            break
        fi

    done

    if [ -z ${ready_fpga+x} ]; then
        printf "FPGA didn't boot after $((${retry_max}*${retry_delay})) seconds. Aborting...\n\n"
        kill -s TERM ${top_pid}
        exit
    else
        printf "FPGA booted after $((i*${retry_delay})) seconds\n"
    fi

    # If we don't know the FPGA IP, we wait for ${no_ping_delay} seconds.
    # Otherwise, we try to ping the FPGA until it is online.
    if [ -z ${fpga_ip+x} ]; then
       printf "Waiting ${no_ping_delay} seconds...                             "
	   sleep ${no_ping_delay}
	   printf "Done!\n"
    else
        printf "Waiting for FPGA's ETH to come up...              "

        # Wait until FPGA's ETH is ready
        for i in $(seq 1 ${retry_max}); do

            if /bin/ping -c 2 ${fpga_ip} &> /dev/null ; then
               local ready_eth=1
               break
            else
               sleep ${retry_delay}
            fi

        done

        if [ -z ${ready_eth+x} ]; then
            printf "FPGA's ETH didn't come up after $((${retry_max}*${retry_delay})) seconds. Aborting...\n\n"
            kill -s TERM ${top_pid}
            exit
        else
            printf "FPGA's ETH came up after $((i*${retry_delay})) seconds\n"
        fi
    fi
}

# Get crate ID
getCrateId()
{
    local crate_id_str

    crate_id_str=$(ipmitool -I lan -H $shelfmanager -t $ipmb -b 0 -A NONE raw 0x34 0x04 0xFD 0x02 2> /dev/null)

    if [ "$?" -ne 0 ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    local crate_id=`printf %04X  $((0x$(echo $crate_id_str | awk '{ print $2$1 }')))`

    if [ -z ${crate_id} ]; then
        kill -s TERM ${top_pid}
        exit
    fi

    echo ${crate_id}
}

# FPGA IP
getFpgaIp()
{

    # Calculate FPGA IP subnet from the crate ID
    local subnet="10.$((0x${crate_id:0:2})).$((0x${crate_id:2:2}))"

    # Calculate FPGA IP last octet from the slot number
    local fpga_ip="${subnet}.$(expr 100 + $slot)"

    echo ${fpga_ip}
}

#############
# Main body #
#############

# Verify inputs arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -s|--shelfmanager)
    shelfmanager="$2"
    shift
    ;;
    -n|--slot)
    slot="$2"
    shift
    ;;
    -m|--mcs)
    mcs_file=$(readlink -e "$2")
    shift
    ;;
    -f|--fsb)
    use_fsb=1
    shift
    ;;
    -h|--help)
    usage
    exit 0
    ;;
    *)
    echo
    echo "Unknown option"
    usage
    exit 1
    ;;
esac
shift
done

echo

# Verify mandatory parameters
if [ -z "${shelfmanager}" ]; then
    echo "Shelfmanager not defined!"
    usage
    exit 1
fi

if [ -z "${slot}" ]; then
    echo "Slot number not defined!"
    usage
    exit 1
fi

if [ ! -f "${mcs_file}" ]; then
    echo "MCS file not found!"
    usage
    exit 1
fi

# YAML definition used by the programming tool
if [ -z ${use_fsb+x} ]; then
    yaml_file=${yaml_top}/2sb/FirmwareLoader.yaml
else
    yaml_file=${yaml_top}/1sb/FirmwareLoader.yaml
fi

# Checking if MCS file was given in GZ format
printf "Verifying if MCS file is compressed...            "
if [[ ${mcs_file} == *.gz ]]; then
    printf "Yes, GZ file detected.\n"

    # Extract the MCS file into the /tmp folder
    mcs=/tmp/$(basename "${mcs_file%.*}")

    printf "Extracting GZ file into CPU disk...               "
    zcat ${mcs_file} > ${mcs}

    if [ "$?" -eq 0 ]; then
        printf "Done!\n"
    else
        printf "ERROR extracting MCS file. Aborting...\n\n"
        exit 1
    fi

else
    # If MCS file is not in GZ format, use the original file instead
    printf "No, MCS file detected.\n"
    mcs=${mcs_file}
fi

# Check connection with shelfmanager. Exit on error
printf "Checking connection with the shelfmanager...      "
if ! ping -c 2 ${shelfmanager} &> /dev/null ; then
    printf "Shelfmanager unreachable!\n"
    exit 1
else
    printf "Connection OK!\n"
fi

# Programing method to use
printf "Programing method to use:                         "
if [ -z ${use_fsb+x} ]; then
    printf "2nd stage boot\n"
else
    printf "1st stage boot\n"
fi

# IPMB address
ipmb=$(expr 0128 + 2 \* $slot)
printf "IPMB address:                                     0x%X\n" ${ipmb}

# If 1st stage boot method is used, then change bootload address and reboot
if [ ! -z ${use_fsb+x} ]; then
    setFirstStageBoot
fi

# Read crate ID from the shelfmanager, as a 4-digit hex number
printf "Reading the Crate ID...                           "
crate_id=$(getCrateId)
printf "0x${crate_id}\n"

# Calculate FPGA IP subnet from the crate ID and slot number
fpga_ip=$(getFpgaIp)
printf "FPGA IP address:                                  ${fpga_ip}\n"

# Check connection between CPU and FPGA.
printf "Testing CPU and FPGA connection (with ping)...    "

# Trying first with ping
if /bin/ping -c 2 ${fpga_ip} &> /dev/null ; then
    printf "FPGA connection OK!\n"
else
    printf "Failed!\n"
    printf "FPGA is unreachable.\n"
    # At  this point the FSB image usually don't support ICMP commands (ping).
    # We don't support arping in the docker environment at the moment.
    # So, for now set the script to continue anyways, but need to be fixed later.
    # exit 1
fi

# Current firmware build string from FPGA
printf "Current firmware build string:                    "
bs_old=$(getBuildString)

for c in ${bs_old} ; do printf "\x${c}" ; done
printf "\n"

# Current firmware version from FPGA
printf "Current FPGA Version:                             "
ver_old=$(getFpgaVersion)
printf "0x${ver_old}\n"

# Load image into FPGA
printf "Programming the FPGA...\n"

FirmwareLoader -r -Y ${yaml_file} -a ${fpga_ip} ${mcs}

# Catch the return value from the FirmwareLoader application (0: Normal, 1: Error)
ret=$?

# Show result of the firmware loading processes
printf "\n"
if [ "${ret}" -eq 0 ]; then
    printf "FPGA programmed successfully!\n\n"
else
    printf "ERROR: Errors were found during the FPGA Programming phase (Error code ${ret})\n\n"
    printf "Aborting as the FirmwareLoader failed\n"
    printf "\n"
    exit 1
fi

if [ -z ${use_fsb+x} ]; then
    # If 2st stage boot was not used, reboot FPGA.
    # If 1st stage boot was used, a reboot was done when returning to the second stage boot
    rebootFPGA
else
    # If 1st stage boot was used, return boot address to the second stage boot
    setSecondStageBoot
fi

# Read the new firmware build string
printf "New firmware build string:                        "
bs_new=$(getBuildString)

for c in ${bs_new} ; do printf "\x${c}" ; done
printf "\n"

# Read the new firmware version
printf "New FPGA Version:                                 "
ver_new=$(getFpgaVersion)
printf "0x${ver_new}\n"

# Print summary
printf "\n"
printf "  SUMMARY:\n"
printf "============================================================\n"

printf "Programing method used:                           "
if [ -z ${use_fsb+x} ]; then
    printf "2nd stage boot\n"
else
    printf "1st stage boot\n"
fi

printf "Shelfmanager name:                                ${shelfmanager}\n"

printf "Crate ID:                                         ${crate_id}\n"

printf "Slot number:                                      ${slot}\n"

printf "IPMB address:                                     0x%x\n" ${ipmb}

printf "FPGA IP address:                                  ${fpga_ip}\n"

printf "MCS file:                                         ${mcs_file}\n"

printf "Old firmware build string:                        "
for c in ${bs_old} ; do printf "\x${c}" ; done
printf "\n"

printf "Old FPGA version:                                 0x${ver_old}\n"

printf "New firmware build string:                        "
for c in ${bs_new} ; do printf "\x${c}" ; done
printf "\n"

printf "New FPGA version:                                 0x${ver_new}\n"

printf "Connection between CPU and FPGA (using ping):     "

if /bin/ping -c 2 ${fpga_ip} &> /dev/null ; then
    printf "FPGA connection OK!\n"
else
    printf "FPGA unreachable!\n"
fi

printf "\nDone!\n\n"

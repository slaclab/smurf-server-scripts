#!/usr/bin/env bash

# This script contains common functions to both
# start.sh and stop.sh scripts.

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

# Usage message
usage()
{
    echo "Start a docker container"
    echo ""
    echo "usage: ${script_name} -N|--slot <slot_number> [-e|--extra-opts <server_extra_opts>]"
    echo "    -N|--slot         <slot_number>       : ATCA crate slot number. Must be used with -S."
    echo "    -e|--extra-opts   <server_extra_opts> : Extra options to be passed to the pysmurf-server startup script."
    echo "                                            If passing a option with arguments, or multiple option, wrapped"
    echo "                                            then with quotes. For example: -e \"--hard-boot -a 10.0.1.102\"."
    echo "    -h|--help                             : Show this message."
    echo ""
    exit 1
}

# Run a command, echoing it first
run_cmd_with_echo()
{
    echo "Running '$@'"
    eval "$@"
}

#############
# Main body #
#############

# Verify inputs arguments
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -N|--slot)
    slot="$2"
    shift
    ;;
    -e|--extra-opts)
    extra_opts="\"$2\""
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

if [ -z ${slot+x} ]; then
    echo "Slot number not defined!"
    usage
else
    # Verify that the slot number is in the range [2,7]
    if ! [ ${slot} -ge 2 -a ${slot} -le 7 ]; then
        echo "Invalid slot number! Must be a number between 2 and 7."
        exit 1
    fi
fi

# Assemble the server name
server_name=smurf_server_s${slot}
pysmurf_name=pysmurf_s${slot}
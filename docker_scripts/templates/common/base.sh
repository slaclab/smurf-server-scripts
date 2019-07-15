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
    echo "usage: ${script_name} [-S|--shelfmanager <shelfmanager_name> -N|--slot <slot_number>]"
    echo "    -N|--slot         <slot_number>       : ATCA crate slot number. Must be used with -S."
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
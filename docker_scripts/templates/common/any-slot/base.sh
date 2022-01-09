#!/usr/bin/env bash

# Helper functions for start.sh and stop.sh

###############
# Definitions #
###############

script_name=$(basename $0)

########################
# Function definitions #
########################

# Usage message
usage() {
    echo "
Start a docker container

usage: ${script_name} -N|--slot <slot_number> [--reactivate] [-e|--extra-opts <server_extra_opts>]
  -N|--slot         <slot_number>       : ATCA crate slot number. Must be used with -S.
  --reactivate                          : Deactivate and activate the slot.
  -e|--extra-opts   <server_extra_opts> : Extra options to be passed to the pysmurf-server startup script.
                                          If passing a option with arguments, or multiple option, wrapped
                                          then with quotes. For example: -e \"--hard-boot -a 10.0.1.102\".
  -h|--help                             : Show this message.    
"
   exit 1
}

# Run a command, echoing it first
run_cmd_with_echo()
{
    echo "Running '$@'"
    eval "$@"
}

# Parse parameters

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
	--reactivate)
	    reactivate=true
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

# Assert parameters

if [ -z ${slot+x} ]; then
    echo "Slot number not defined."
    usage
else
    # Verify that the slot number is in the range [2,7]
    if ! [ ${slot} -ge 2 -a ${slot} -le 7 ]; then
        echo "Invalid slot number. Must be a number between 2 and 7."
        exit 1
    fi
fi

# Assemble the server name
server_name=smurf_server_s${slot}
pysmurf_name=pysmurf_s${slot}

reactivate() {
    echo "Deactivating slot ${slot} using ssh to ${shelfmanager}."
    deactivatecmd="clia deactivate board ${slot}"
    ssh root@${shelfmanager} "$deactivatecmd"

    # This can probably be shortened.
    sleep 5

    # activate carriers
    echo "Activating slot ${slot}"
    activatecmd="clia activate board ${slot}"
    ssh root@${shelfmanager} "$activatecmd"

    # Mean time until the carrier is up again is 25 seconds.
    # Pysmurf will crash if the carrier is down.
    sleep 30

    echo "Done reactivating."
}

#!/usr/bin/env bash

# Functions for start.sh or stop.sh

function usage {
    echo "Start the SMuRF software on one particular slot. Run this on
multiple slots to set up the entire crate. By starting one slot, I
mean programming the carrier firmware if required, turning on the PCIe
card if required, turning on the AMC bays if present, starting the
firmware, and starting the high level pysmurf software. After this
script finishes, one container should be running the SMuRF server and
one should be running the SMuRF client. Send pysmurf commands to the
client.

    usage: ${script_name} -N|--slot <slot_number> [--reactivate] [-e|--extra-opts <server_extra_opts>]
      -N|--slot         <slot_number>       : ATCA crate slot number. Must be used with -S.
      --reactivate                          : Deactivate and activate the slot.
      -e|--extra-opts   <server_extra_opts> : Extra arguments to pysmurf/docker/server/scripts/start_server.sh.
                                              E.g. --extra-opts \"--hard-boot -a 10.0.1.102\".
      -h|--help                             : Help."

    echo $1
    
    exit 1
}

# Run a command, echoing it first
run_cmd_with_echo() {
    echo "Running '$@'"
    eval "$@"
}

reactivate() {
    echo "Deactivating and activating slot ${slot} using ssh to ${shelfmanager}."
    deactivatecmd="clia deactivate board ${slot}"
    ssh root@${shelfmanager} "$deactivatecmd"

    # This can probably be shortened.
    sleep 5

    activatecmd="clia activate board ${slot}"
    ssh root@${shelfmanager} "$activatecmd"

    # Mean time until the carrier is up again is 15 seconds.
    # Pysmurf will crash if the carrier is down.
    sleep 30

    echo "Done reactivating."
}

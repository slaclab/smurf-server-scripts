#!/usr/bin/env bash

# Call the base script
. ./functions.sh

. .env

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

if [ -z ${slot+x} ]; then
    usage "Slot number not defined."
else
    if ! [ ${slot} -ge 2 -a ${slot} -le 7 ]; then
        usage "Invalid slot number. Must be a number between 2 and 7."
    fi
fi

server_name=smurf_server_s${slot}
pysmurf_name=pysmurf_s${slot}

# Stop and remove any pysmurf and smurf server container
for d in ${pysmurf_name} ${server_name}; do

    # Stop and remove running container, if any
    echo "Checking if a ${d} container is running on slot ${slot}..."
    r1=$(docker ps -f name=${d} -f status=running | wc -l)

    if [ ${r1} != 1 ]; then
        echo "A container is running. Stopping it..."
        for c in "docker stop ${d}" "docker rm ${d}"; do
            run_cmd_with_echo ${c}
        done
        echo
    else
        echo "No container is running."
        echo

        # If no container was running, remove any non-running container, if any
        echo "Check if a docker container is non-running state on slot ${slot}..."
        r2=$(docker ps -a -f name=${d} | wc -l)

        if [ ${r2} != 1 ]; then
            echo "A container was found, on state '$(docker ps -a -f name=${d} --format {{.Status}})'. Removing it..."
            run_cmd_with_echo "docker rm ${d}"
        else
            echo "No container was found"
        fi
        echo
    fi
    echo
done

echo "Done!"
echo

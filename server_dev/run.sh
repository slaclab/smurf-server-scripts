#!/usr/bin/env bash

<<<<<<< HEAD:dev/run.sh
while [[ $# -gt 0 ]]
do
    key="$1"

    case ${key} in
	-N|--slot)
	    slot="$2"
	    shift
	    ;;
    esac
    shift
done
=======
# Used by:
# system
# system-dev

args=$@
script_name=$(basename $0)
>>>>>>> 52f8283... Keep type pysmurf-dev named as is, it's used by setup-server.sh:docker_scripts/templates/common/run.sh

server_name=smurf_server_s${slot}
pysmurf_name=pysmurf_s${slot}

<<<<<<< HEAD:dev/run.sh
=======
# Most commands here are relative to the $cwd, please make sure you're
# cd'd into this folder. Fixme: remove relative paths so this can run
# anywhere.
. ./functions.sh

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

if [ -z ${slot+x} ]; then
    usage "Slot number not defined."
else
    if ! [ ${slot} -ge 2 -a ${slot} -le 7 ]; then
        usage "Invalid slot number. Must be a number between 2 and 7."
    fi
fi

server_name=smurf_server_s${slot}
pysmurf_name=pysmurf_s${slot}

>>>>>>> 52f8283... Keep type pysmurf-dev named as is, it's used by setup-server.sh:docker_scripts/templates/common/run.sh
./stop.sh ${args}

echo "Starting pysmurf server and client in slot ${slot}..."

if [ "$reactivate" = true ] ; then
    reactivate
fi

# If the PCIe card in present in the system, use the
# PCIe related docker-compose file as well
extra_composes=""
if [ -c /dev/datadev_0 ] && [ -c /dev/datadev_1 ]; then
    extra_composes+=" -f docker-compose.pcie.yml"
fi

# Start the smurf server and pysmurf
for d in ${server_name} ${pysmurf_name}; do
    run_cmd_with_echo "slot=${slot} extra_opts=${extra_opts} docker-compose -f docker-compose.yml ${extra_composes} up -d ${d}"
done

echo "Done!"

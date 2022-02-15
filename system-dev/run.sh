#!/usr/bin/env bash

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

server_name=smurf_server_s${slot}
pysmurf_name=pysmurf_s${slot}

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

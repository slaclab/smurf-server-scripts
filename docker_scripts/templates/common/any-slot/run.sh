#!/usr/bin/env bash

# Save input arguments
args=$@

# Call the base script
. ./base.sh

# Stop previously running server, if any by calling
# the stop.sh script with the input arguments.
./stop.sh ${args}

# Start the server
echo "Starting docker containers for slot ${slot}..."

# If the PCIe card in present in the system, use the
# PCIe related docker-compose file as well
extra_composes=""
if [ -c /dev/datadev_0 ] && [ -c /dev/datadev_1 ]; then
    extra_composes+=" -f docker-compose.pcie.yml"
fi

# Start the smurf server and pysmurf
for d in ${server_name} ${pysmurf_name}; do
    run_cmd_with_echo "slot=${slot} extra_opts=${extra_opts} docker-compose -f docker-compose.yml ${extra_composes} up -d ${d}"
    echo
done

echo "Done!"
echo
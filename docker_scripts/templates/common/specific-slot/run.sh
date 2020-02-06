#!/usr/bin/env bash

########################
# Function definitions #
########################

# Usage message
usage()
{
    echo "Start a docker container"
    echo ""
    echo "usage: ${script_name} [-e|--extra-opts <server_extra_opts>]"
    echo "    -e|--extra-opts   <server_extra_opts> : Extra options to be passed to the pysmurf-server startup script."
    echo "                                            If passing a option with arguments, or multiple option, wrapped"
    echo "                                            then with quotes. For example: -e \"--hard-boot -a 10.0.1.102\"."
    echo "    -h|--help                             : Show this message."
    echo ""
    exit 1
}

#############
# Main body #
#############

# Verify inputs arguments
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -e|--extra-opts)
    extra_opts="\"$2\""
    shift
    ;;
    -h|--help)
    usage
    ;;
esac
shift
done

echo

# Stop previously running server, if any by calling stop.sh
./stop.sh

# Start the sever
echo "Starting docker containers..."

if [ -c /dev/datadev_0 ]; then
    extra_opts=${extra_opts} docker-compose -f docker-compose.yml -f docker-compose.pcie.yml up -d
else
    docker-compose up -d
fi

echo "Done!"
echo
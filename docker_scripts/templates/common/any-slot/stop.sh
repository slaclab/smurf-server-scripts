#!/usr/bin/env bash

. ./base.sh

for d in ${pysmurf_name} ${server_name}; do
    r=$(docker ps -a -f name=${d} | wc -l)

    if [ ${r} != 1 ]; then
        echo "${d} already exists in state '$(docker ps -a -f name=${d} --format {{.Status}})'. Stopping and removing it."
	run_cmd_with_echo "docker stop ${d}"
        run_cmd_with_echo "docker rm ${d}"
    fi
done

echo "Done!"

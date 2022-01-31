#!/usr/bin/env bash

run_cmd_with_echo() {
    echo "Running '$@'"
    eval "$@"
}

for d in ${pysmurf_name} ${server_name}; do
    r=$(docker ps -a -f name=${d} | wc -l)

    if [ ${r} != 1 ]; then
        echo "${d} is in state '$(docker ps -a -f name=${d} --format {{.Status}})'. Stopping and removing it."
	run_cmd_with_echo "docker stop ${d}"
        run_cmd_with_echo "docker rm ${d}"
    fi
done

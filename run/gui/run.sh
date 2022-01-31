#!/usr/bin/env bash

function usage {
    echo "Run the Rogue GUI.

Usage: 
  -v version : The version of Rogue to run."
}

if [ $# -eq 1 ]; then
    usage
fi

while getopts "t:" opt; do
    case ${opt} in
        v)
    	version=$2
    	;;
    esac
    shift
done

docker run -it --rm  \
  --log-opt tag=guis \
  -u $(id -u cryo):$(id -g cryo) \
  --net host \
  -e DISPLAY \
  -e location=${PWD} \
  -v /home/cryo/.Xauthority:/home/cryo/.Xauthority \
  -v /home/cryo/.bash_history:/home/cryo/.bash_history \
  --entrypoint connect_remote_gui.py \
  tidair/smurf-rogue:${version} $@

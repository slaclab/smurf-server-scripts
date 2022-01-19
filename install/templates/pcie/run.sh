#!/usr/bin/env bash

user="cryo"

docker run -it --rm  \
  --log-opt tag=smurf_pcie \
  --security-opt "apparmor=docker-smurf" \
  -u $(id -u ${user}):$(id -g ${user}) \
  --net host \
  -e DISPLAY \
  -e location=${PWD} \
  -v /home/${user}/.Xauthority:/home/${user}/.Xauthority \
  -v /home/${user}/.bash_history:/home/${user}/.bash_history \
  -v /data:/data \
  -v ${PWD}/shared:/shared \
  --device /dev/datadev_0 \
  tidair/smurf-pcie:%%VERSION%% $1
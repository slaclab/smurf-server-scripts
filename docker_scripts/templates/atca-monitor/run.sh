#!/usr/bin/env bash

user="cryo"

docker run -it --rm  \
  --log-opt tag=atca_monitor \
  --security-opt "apparmor=docker-smurf" \
  -u $(id -u ${user}):$(id -g ${user}) \
  --net host \
  -e DISPLAY \
  -e location=${PWD} \
  -v /home/${user}:/home/${user} \
  -v /data:/data \
  tidair/smurf-atca-monitor:%%VERSION%% -g -S shm-smrf-sp01
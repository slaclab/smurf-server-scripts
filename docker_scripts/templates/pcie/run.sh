#!/usr/bin/env bash

user="%%USER_NAME%%"

security_opt=""
if which apparmor_parser > /dev/null 2>&1; then
  security_opt="--security-opt apparmor=docker-smurf"
fi

docker run -it --rm  \
  --log-opt tag=smurf_pcie \
  ${security_opt} \
  -u $(id -u ${user}):$(id -g ${user}) \
  --net host \
  -e DISPLAY \
  -e location=${PWD} \
  -v /home/${user}/.Xauthority:/home/${user}/.Xauthority \
  -v /home/${user}/.bash_history:/home/${user}/.bash_history \
  -v /data:/data \
  -v ${PWD}/shared:/shared \
  --device /dev/datadev_0 \
  %%DOCKER_IMAGE_ADDRESS%%:%%VERSION%% $1

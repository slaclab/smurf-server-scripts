#!/usr/bin/env bash

user="cryo"

docker run -it --rm  \
  --log-opt tag=guis \
  -u $(id -u ${user}):$(id -g ${user}) \
  --net host \
  -e DISPLAY \
  -e location=${PWD} \
  -v /home/${user}/.Xauthority:/home/${user}/.Xauthority \
  -v /home/${user}/.bash_history:/home/${user}/.bash_history \
  --entrypoint connect_remote_gui.py \
  tidair/smurf-rogue:%%SMURF_ROGUE_VERSION%% $@

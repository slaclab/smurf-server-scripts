#!/usr/bin/env bash

user="cryo"

docker run -dit --rm  \
  --log-opt tag=guis \
  -u $(id -u ${user}):$(id -g ${user}) \
  --net host \
  -e DISPLAY \
  -e location=${PWD} \
  -v /etc/group:/etc/group:ro \
  -entrypoint connect_remote_gui.py \
  tidair/smurf-rogue:%%SMURF_ROGUE_VERSION%% $@

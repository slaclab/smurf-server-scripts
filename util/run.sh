#!/usr/bin/env bash

docker run -it --rm  \
  --log-opt tag=utils \
  -u $(id -u cryo):$(id -g cryo) \
  --net host \
  -e EPICS_CA_AUTO_ADDR_LIST=NO \
  -e EPICS_CA_ADDR_LIST=127.255.255.255 \
  -e EPICS_CA_MAX_ARRAY_BYTES=80000000 \
  -e DISPLAY \
  -e location=${PWD} \
  -v /etc/group:/etc/group:ro \
  -v /home/cryo/.bash_history:/home/cryo/.bash_history \
  -v /data:/data \
  -v ${PWD}/shared:/shared \
  tidair/smurf-base:R1.1.3

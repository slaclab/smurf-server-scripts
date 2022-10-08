#!/usr/bin/env bash
VERSION=R1.1.3

user="cryo"

DOCKERID=`docker run -d -it --rm  \
  --log-opt tag=utils \
  -u $(id -u ${user}):$(id -g ${user}) \
  --net host \
  -e EPICS_CA_AUTO_ADDR_LIST=NO \
  -e EPICS_CA_ADDR_LIST=127.255.255.255 \
  -e EPICS_CA_MAX_ARRAY_BYTES=80000000 \
  -e DISPLAY \
  -e location=${PWD} \
  -v /etc/group:/etc/group:ro \
  -v /home/${user}/.bash_history:/home/${user}/.bash_history \
  -v /data:/data \
  -v ${PWD}/shared:/shared \
  tidair/smurf-base:${VERSION}`

# I think the docker command returns the docker sha? number? whatever
echo $DOCKERID

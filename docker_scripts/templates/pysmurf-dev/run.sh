#!/usr/bin/env bash

user="cryo"

docker run -it --rm  \
  --log-opt tag=pysmurf \
  --security-opt apparmor=docker-smurf \
  -u $(id -u ${user}):$(id -g ${user}) \
  --net host \
  -e DISPLAY \
  -e location=${PWD} \
  -e EPICS_CA_AUTO_ADDR_LIST=NO \
  -e EPICS_CA_ADDR_LIST=127.255.255.255 \
  -e EPICS_CA_MAX_ARRAY_BYTES=80000000 \
  -v /home/${user}/.Xauthority:/home/${user}/.Xauthority \
  -v /home/${user}/.bash_history:/home/${user}/.bash_history \
  -v /home/${user}/.ipython:/home/${user}/.ipython \
  -v /data:/data \
  -v ${PWD}/pysmurf:/usr/local/src/pysmurf \
  --entrypoint bash \
  --workdir /usr/local/src/pysmurf \
  tidair/pysmurf-client:%%PYSMURF_VERSION%%
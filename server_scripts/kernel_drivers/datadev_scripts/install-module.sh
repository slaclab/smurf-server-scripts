#!/usr/bin/env bash

if [ -z "$(lsmod | grep datadev)" ]; then
    insmod /usr/local/src/datadev/datadev.ko
    sysctl -w vm.max_map_count=262144
fi
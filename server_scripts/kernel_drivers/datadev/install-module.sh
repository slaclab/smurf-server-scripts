#!/usr/bin/env bash

if [ -z "$(lsmod | grep datadev)" ]; then
    insmod /usr/local/src/datadev/datadev.ko
fi
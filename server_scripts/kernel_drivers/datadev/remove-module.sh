#!/usr/bin/env bash

if [ "$(lsmod | grep datadev)" ]; then
    rmmod datadev
fi
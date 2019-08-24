#!/usr/bin/env bash

./stop.sh

echo "Starting docker containers..."

if [ -c /dev/datadev_0 ]; then
    docker-compose -f docker-compose.yml -f docker-compose.pcie.yml up -d
else
    docker-compose up -d
fi

echo "Done!"
echo
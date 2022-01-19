#!/usr/bin/env bash

./stop.sh

echo "Starting docker containers..."

docker-compose up -d

echo "Done!"
echo
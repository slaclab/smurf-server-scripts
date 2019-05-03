#!/usr/bin/env bash

echo "Detecting type of server..."
if dmidecode | grep -Fq R440
then
    echo "This is as Dell R440 server"
    dell_r440=1
elif dmidecode | grep -Fq R330
then
    echo "This is a Dell R330 server"
    dell_r330=1
else
    echo "Unsupported server"
    echo "Aborting..."
    exit 1
fi

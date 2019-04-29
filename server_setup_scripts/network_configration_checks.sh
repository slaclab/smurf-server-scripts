#!/usr/bin/env bash

echo "Verifiying that the interfaces are present in the server..."
for interface_name in ${interface_names}
do
        if ! ip addr | grep -Fq "${interface_name}:"
        then
            echo "ERROR: Interface '${interface_name}' not found!"
            echo "Aborting..."
            echo
            exit 1
        fi
done
echo "Done!"

echo "Verifying that the interfaces '${interface_names}' are not defined in '${config_file}'..."
for interface_name in ${interface_names}
do
    if grep -Fq "${interface_name}:" ${config_file}
    then
        echo "ERROR: Interface '${interface_name}' found in '${config_file}'"
        echo "Aborting..."
        echo
	exit 1
    fi
done
echo "Done!."

#!/usr/bin/env bash

config_file=/etc/netplan/01-network-manager-all.yaml

interface_names="eno2"

# Look for the USB-Ethernet interface which name is not fixed.
usb_interface_name=$(ip addr | grep -Po '^[0-9][0-9]*:.*\Kenx[^:][^:]*')
if [ "${usb_interface_name}" ]; then
	# If found, add it to the list of interfaces to configure
    interface_names="${interface_names} ${usb_interface_name}"
else
    echo "WARINIG: USB-Ethernet device not found! It will not be configured!"
fi

# Run network configuration checks
. network_configration_checks.sh

echo "writting configuration to ${config_file}..."
echo "    eno2:
      dhcp4: no
      dhcp6: no
      mtu: 9000
      addresses: [10.0.1.1/21, ]
    ${usb_interface_name}:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.1.1/24,]" >> ${config_file}

echo "Applying configuration to netplay..."
netplan apply

echo "Done!"

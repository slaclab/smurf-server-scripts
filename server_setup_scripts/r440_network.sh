#!/usr/bin/env bash

config_file=/etc/netplan/01-network-manager-all.yaml
interface_names="eno2 enx00249b46c78b"

# Run network configuration checks
. network_configration_checks.sh

echo "writting configuration to ${config_file}..."
echo "    eno2:
      dhcp4: no
      dhcp6: no
      mtu: 9000
      addresses: [10.0.1.1/21, ]
    enx00249b46c78b:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.1.1/24,]" >> ${config_file}

echo "Applying configuration to netplay..."
netplay apply

echo "Done!"

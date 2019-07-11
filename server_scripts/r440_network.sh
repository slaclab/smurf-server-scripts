#!/usr/bin/env bash

# Local interface (use to communicate with the ATCA system)
atca_interface_name="eno2"
configure_interafce=1
config_file=/etc/netplan/atca.yaml

echo "Configuring local interface, used for communication with the ATCA blade..."
echo

echo "Verifying the that the local interface ${atca_interface_name} is present in the server..."

if ! ip addr | grep -Fq "${atca_interface_name}:"; then
  echo "ERROR: Interface '${atca_interface_name}' not found!"
  configure_interafce=0
else

  echo "Interface found."
  echo

  echo "Verifying that the interfaces '${atca_interface_name}' is not defined in '${config_file}'..."
  if grep -Fq "${atca_interface_name}:" ${config_file} 2&> /dev/null ; then
      echo "ERROR: Interface '${atca_interface_name}' found in '${config_file}'"
      configure_interafce=0
  else
    echo "Interface not defined."
  fi
fi

echo

if [ ${configure_interafce} -eq 0 ]; then
  echo "Errors were founds. Interface ${atca_interface_name} will not be configured!"
else
  echo "Writing configuration to ${config_file} for interface ${atca_interface_name}..."
  cat << EOF >>  ${config_file}
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eno2:
      dhcp4: no
      dhcp6: no
      mtu: 9000
      addresses: [10.0.1.1/21, ]
EOF

  echo "Done!"
fi

echo

# Look for the USB-Ethernet interface which name is not fixed.
# (used to communicate with the ATCA shelf manager)
usb_interface_name=$(ip addr | grep -Po '^[0-9][0-9]*:.*\Kenx[^:][^:]*')
configure_interafce=1
config_file=/etc/netplan/management.yaml

echo "Configuring USB interface, used for communication with the ATCA shelfmanager..."

echo "Looking for USB interface..."

if [ "${usb_interface_name}" ]; then
  echo "Interface found: ${usb_interface_name}"
  echo

  echo "Verifying that the interfaces '${usb_interface_name}' is not defined in '${config_file}'..."
  if grep -Fq "${usb_interface_name}:" ${config_file} 2&> /dev/null ; then
      echo "ERROR: Interface '${usb_interface_name}' found in '${config_file}'"
      configure_interafce=0
  else
    echo "Interface not defined."
  fi
else
    echo "ERROR: USB-Ethernet device not found! It will not be configured!"
    configure_interafce=0
fi

echo

if [ ${configure_interafce} -eq 0 ]; then
  echo "Error were found. Interface ${usb_interface_name} will not be configured!"
else
  echo "writting configuration to ${config_file} for interface ${usb_interface_name}..."
  cat << EOF >>  ${config_file}
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ${usb_interface_name}:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.1.1/24,]
EOF

  echo "Done!"
fi

echo

echo "Applying configuration to netplay..."
netplan apply

echo "Done!"

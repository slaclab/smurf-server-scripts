#!/usr/bin/env bash

# Local interface (use to communicate with the ATCA system)
atca_interface_name="enp2s0f0"
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
      echo "Interface '${atca_interface_name}' found in '${config_file}'. Skipping..."
      configure_interafce=0
  else
    echo "Interface not defined."
  fi
fi

echo

if [ ${configure_interafce} -eq 0 ]; then
  echo "Interface ${atca_interface_name} will not be configured!"
else
  echo "Writing configuration to ${config_file} for interface ${atca_interface_name}..."
  cat << EOF >>  ${config_file}
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp2s0f0:
      dhcp4: no
      dhcp6: no
      mtu: 9000
      addresses: [10.0.1.1/21, ]
EOF

  echo "Done!"
fi

echo

# Local interface (used to communicate with the ATCA shelf manager)
shm_interface_name="enp2s0f1"
configure_interafce=1
config_file=/etc/netplan/management.yaml

echo "Configuring local interface, used for communication with the ATCA shelfmanager..."
echo

echo "Verifying the that the local interface ${shm_interface_name} is present in the server..."

if ! ip addr | grep -Fq "${shm_interface_name}:"; then
  echo "ERROR: Interface '${shm_interface_name}' not found!"
  configure_interafce=0
else

  echo "Interface found."
  echo

  echo "Verifying that the interfaces '${shm_interface_name}' is not defined in '${config_file}'..."
  if grep -Fq "${shm_interface_name}:" ${config_file} 2&> /dev/null ; then
      echo "Interface '${shm_interface_name}' found in '${config_file}'. Skipping..."
      configure_interafce=0
  else
    echo "Interface not defined."
  fi
fi

echo

if [ ${configure_interafce} -eq 0 ]; then
  echo "Interface ${shm_interface_name} will not be configured!"
else
  echo "Writing configuration to ${config_file} for interface ${shm_interface_name}..."
  cat << EOF >>  ${config_file}
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp2s0f1:
      dhcp4: no
      dhcp6: no
      addresses: [192.168.1.1/24,]
EOF

  echo "Done!"
fi

echo

echo "Applying configuration to netplan..."
netplan apply
sleep 5

echo "Done!"
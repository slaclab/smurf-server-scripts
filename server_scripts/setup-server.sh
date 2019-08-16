#!/usr/bin/env bash

########################
# ASK USER CONFIMATION #
########################
echo "This script will setup an SMuRF server right after the OS installation."
echo "This script should be run juts once, and right after the the OS is installed."
echo "Note: You must execute this script with root privileges."

read -p "Are you sure you want to continue? [Y/N]" -r
echo

if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
    echo "Aborting installation..."
    exit 0
fi

# Redirect stdout into a named pipe running tee, so that
# all the output messages goes to a log file as well.
# The -i option is used to avoid signal interrupt from
# disrupting stdout in the script.
# Redirect stderr as well to the log file.
exec > >(tee -ia server_setup.log)
exec 2>&1

echo "Starting server configuration..."
date
echo

############################
# DETECTING TYPE OF SERVER #
############################
. server_type.sh

####################
# INSTALL PACKAGES #
####################
echo "##############################"
echo "### Installing packages... ###"
echo "##############################"
echo

apt-get -y update
apt-get -y install \
    openssh-server \
    g++ \
    cmake \
    mesa-utils \
    vim \
    emacs \
    git \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    tree \
    ipmitool \
    screen \
    tightvncserver \
    xfce4 \
    xfce4-goodies

# Install it lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get -y install git-lfs
git lfs install

# Install this server scripts into the system
cp -r ../../smurf-server-scripts /usr/local/src/

# Create smurf bash profile file and add the docker scripts to PATH
if ! grep -Fq "export PATH=\${PATH}:/usr/local/src/smurf-server-scripts/docker_scripts" /etc/profile.d/smurf_config.sh 2> /dev/null; then
    echo "export PATH=\${PATH}:/usr/local/src/smurf-server-scripts/docker_scripts" >> /etc/profile.d/smurf_config.sh
fi

# Disable automatic system updates
sed -i -e 's|APT::Periodic::Update-Package-Lists ".*";|APT::Periodic::Update-Package-Lists "0";|g' /etc/apt/apt.conf.d/20auto-upgrades
sed -i -e 's|APT::Periodic::Unattended-Upgrade ".*";|APT::Periodic::Unattended-Upgrade "0";|g' /etc/apt/apt.conf.d/20auto-upgrades

echo
echo "#################################"
echo "### Done Installing packages. ###"
echo "#################################"
echo

#######################
# SETUP THE SWAP FILE #
#######################
echo "###############################"
echo "### Setting up swap file... ###"
echo "###############################"
echo

# Check if the swap partition exist. If not,
# then we have already done this.
if [ -e /dev/mapper/ubuntu--vg-swap_1 ]; then
    echo "Removing swap partition and creating swap file..."
    # Delete default swap partition
    swapoff -a
    lvremove -y /dev/mapper/ubuntu--vg-swap_1

    # Extend root partition to take the free space
    lvextend /dev/mapper/ubuntu--vg-root /dev/sda2
    resize2fs /dev/mapper/ubuntu--vg-root

    # Create a 16G swap file
    fallocate -l 16G /swapfile
    chmod 600 /swapfile

    # Activate the swap file
    mkswap /swapfile
    swapon /swapfile

    # Update fstab so that the changes are permanents
    sed -i -e 's|^/dev/mapper/ubuntu--vg-swap_1.*|/swapfile       swap            swap    defaults        0       0|g' /etc/fstab

    echo "Done!"
else
    echo "The swap partition does not exit."
fi

echo
echo "##################################"
echo "### Done setting up swap file. ###"
echo "##################################"
echo

#########################
# SYSTEM CONFIGURATIONS #
#########################
echo "#########################################"
echo "### Applying system configurations... ###"
echo "#########################################"
echo

# Enable persistent logs
if ! grep -Fq "Storage=persistent" /etc/systemd/journald.conf ; then
    echo Storage=persistent >> /etc/systemd/journald.conf
fi

# Disable Wayland (which will enable Xorg display server instead)
sed -i -e 's/#WaylandEnable=false/WaylandEnable=false/g' /etc/gdm3/custom.conf

# GRUB: set timeouts to 5s and disable quit boot
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/g' /etc/default/grub
sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/g' /etc/default/grub
if ! grep -q ^GRUB_RECORDFAIL_TIMEOUT=.* /etc/default/grub ; then
    echo "GRUB_RECORDFAIL_TIMEOUT=5" >> /etc/default/grub
fi
update-grub

echo
echo "############################################"
echo "### Done applying system configurations. ###"
echo "############################################"
echo

########################
# SMURF CONFIGURATIONS #
########################
echo "########################################"
echo "### Applying SMuRF configurations... ###"
echo "########################################"
echo

# Create the smurf group.
groupadd smurf

# Add the cryo user to the smurf group, as primary groups
usermod -aG smurf cryo
usermod -g smurf cryo

# Create the data directories
mkdir -p /data/{pysmurf_ipython_data,smurf2mce_config,smurf2mce_logs,smurf_data}
mkdir -p /data/epics/ioc/data/sioc-smrf-ml00/

# Set the data directories permissions
chown -R cryo:smurf /data

echo
echo "###########################################"
echo "### Done applying SMuRF configurations. ###"
echo "###########################################"
echo

#########################
# INSTALL DOCKER ENGINE #
#########################
echo "#######################################"
echo "### Installing the docker engine... ###"
echo "#######################################"
echo

if which docker > /dev/null; then
    echo "Docker is already installed in the system:"
    docker --version
    docker-compose --version
else
    # Add Docker’s official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    # Verify that you now have the key with the fingerprint 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88
    apt-key fingerprint 0EBFCD88

    # Set up the stable repository
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"

    # Update the apt package index.
    apt-get update

    # Install the latest version of Docker CE and containerd
    apt-get -y install docker-ce docker-ce-cli containerd.io

    # Create the docker group.
    groupadd docker

    # Add the cryo user to the docker group
    usermod -aG docker cryo

    # Start docker on boot
    systemctl enable docker

    # Install docker compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Setup the logging system in the  daemon configuration
    cp templates/daemon.json /etc/docker/daemon.json

    # Setup apparmor profile
    cp templates/smurf-apparmor-profile /etc/apparmor.d/docker-smurf
    apparmor_parser -r -W /etc/apparmor.d/docker-smurf

    # Disable NetworkManager from managing the docker0 bridge interface
    cat << EOF >> /etc/NetworkManager/NetworkManager.conf

[keyfile]
unmanaged-devices=interface-name:docker0
EOF

    systemctl restart network-manager.service
fi

echo
echo "#########################################"
echo "### Done installing the docker engine ###"
echo "#########################################"
echo

#########################
# NETWORK CONFIGURATION #
#########################
echo "########################################"
echo "### Setting network configuration... ###"
echo "########################################"
echo

# Apply the network configuration to each kind of server
if [ ${dell_r440+x} ]; then
    . r440_network.sh
elif [ ${dell_r330+x} ]; then
    . r330_network.sh
fi

echo
echo "############################################"
echo "### Done setting network configurations. ###"
echo "############################################"
echo

#######
# SSH #
#######
echo "#########################"
echo "### Setting up SSH... ###"
echo "#########################"
echo

# Add the shm-smrf-sp01 node name to ip address map entry
if ! grep -Fq shm-smrf-sp01 /etc/hosts ; then
    cat << EOF >> /etc/hosts
# ATCA shelfmanager
192.168.1.2     shm-smrf-sp01
10.0.1.101      cswh-smrf-sp01
EOF
fi

# Create the ssh configuration directory for the cryo user
su cryo -c "mkdir /home/cryo/.ssh"

# Generate ssh keys for the cryo user
su cryo -c 'ssh-keygen -t rsa  -N "" -f /home/cryo/.ssh/id_rsa'

# Add the ATCA shelfmanager and switch host information
# to the ssh configuration file
su cryo -c 'touch /home/cryo/.ssh/config'
cat << EOF >> /home/cryo/.ssh/config
Host shm-smrf-sp01 cswh-smrf-sp01
     User root
     ForwardX11 no
EOF

echo
echo "#########################"
echo "### Done setting SSH. ###"
echo "#########################"
echo

#####################
# SETUP VNC SERVER  #
#####################
echo "####################################"
echo "### Setting up the VNC server... ###"
echo "####################################"
echo

# Create the xstartup file
mkdir /home/cryo/.vnc
cat << EOF > /home/cryo/.vnc/xstartup
#!/bin/bash

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
EOF

# Make the script executable
chmod +x /home/cryo/.vnc/xstartup

# Change folder and files permissions
sudo chown -R cryo:smurf  /home/cryo/.vnc/

echo
echo "#######################################"
echo "### Done setting up the VNC server. ###"
echo "#######################################"
echo

############################
# INSTALL PCIE CARD DRIVER #
############################
# Install the kernel driver only on R440 servers
if [ ${dell_r440+x} ]; then
    echo "###############################################################"
    echo "### Installing PCIe KCU1500 card kernel driver (datadev)... ###"
    echo "###############################################################"

    # Driver version
    datadev_version=v5.4.0

    # Install directory
    datadev_install_dir=/usr/local/src/datadev/${datadev_version}

    # Create Install directory
    mkdir -p ${datadev_install_dir}

    # Copy the kernel module scripts
    cat ./kernel_drivers/datadev_scripts/install-module.sh \
        | sed s/%%VERSION%%/${datadev_version}/g \
        > ${datadev_install_dir}/install-module.sh
    chmod +x ${datadev_install_dir}/install-module.sh
    cp -r ./kernel_drivers/datadev_scripts/remove-module.sh ${datadev_install_dir}/remove-module.sh

    # Let the cryo user to run the install and remove modules without password, so it can be scripted
    if ! grep -Fq "cryo ALL=(root) NOPASSWD: ${datadev_install_dir}/install-module.sh, ${datadev_install_dir}/remove-module.sh" /etc/sudoers ; then
        echo "cryo ALL=(root) NOPASSWD: ${datadev_install_dir}/install-module.sh, ${datadev_install_dir}/remove-module.sh" | sudo EDITOR="tee -a" visudo
    fi

    # Run the install module script after login
    if ! grep -Fq "sudo ${datadev_install_dir}/install-module.sh" /etc/profile.d/smurf_config.sh ; then
        echo "sudo ${datadev_install_dir}/install-module.sh" >> /etc/profile.d/smurf_config.sh
    fi

    # Build the kernel module from source
    git clone https://github.com/slaclab/aes-stream-drivers.git -b ${datadev_version}
    cd aes-stream-drivers/data_dev/driver
    make
    # Verify if the kernel module was built successfully. If so, copy the resulting
    # kernel module to the install directory
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: Could not build the kernel module!"
        echo "It will not be installed"
        echo
    else
        cp datadev.ko ${datadev_install_dir}/
    fi
    cd -

    echo
    echo "################################################"
    echo "### Done installing PCIe card kernel driver. ###"
    echo "################################################"
    echo
fi

######################
# SHOW FINAL MESSAGE #
######################
echo
echo "Server configuration finished successfully!"
echo "Please reboot the server so all changes take effect."
echo
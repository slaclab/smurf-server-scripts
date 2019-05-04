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

echo "Starting server configuration..."
echo

############################
# DETECTING TYPE OF SERVER #
############################
. server_type.sh

####################
# INSTALL PACKAGES #
####################
echo "- Installing packages..."

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
    tightvncserver \
    xfce4

# Install it lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get -y install git-lfs
git lfs install

# Install this server scripts into the system
mkdir -p /usr/local/src/smurf-server-scripts
cp -r . /usr/local/src/smurf-server-scripts/

touch /etc/profile.d/smurf_config.sh
cat << EOF > /etc/profile.d/smurf_config.sh
export PATH=${PATH}:/usr/local/src/smurf-server-scripts/docker_scripts
EOF

echo "Done Installing packages."
echo

#######################
# SETUP THE SWAP FILE #
#######################
echo "- Setting up swap partition..."

# Create a 16G swap file
fallocate -l 16G /swapfile
chmod 600 /swapfile

# Activate the swap file
mkswap /swapfile
swapon /swapfile

# Update fstab so that the changes are permanents
cat << EOF > /etc/fstab
/swapfile       swap            swap    defaults        0       0
EOF

echo "Done setting up swap partition."
echo

#########################
# SYSTEM CONFIGURATIONS #
#########################
echo "- Applying system configurations..."

# Enable persistent logs
echo Storage=persistent >> /etc/systemd/journald.conf

# Disable Wayland (which will enable Xorg display server instead)
sed -i -e 's/#WaylandEnable=false/WaylandEnable=false/g' /etc/gdm3/custom.conf

# GRUB: set timeouts to 5s and disable quit boot
sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/g' /etc/default/grub
sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5\’$’\nGRUB_RECORDFAIL_TIMEOUT=5/g' /etc/default/grub
update-grub

echo "Done applying system configurations."
echo

########################
# SMURF CONFIGURATIONS #
########################
echo "- Applying SMuRF configurations..."

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

echo "Done applying SMuRF configurations."
echo

#########################
# INSTALL DOCKER ENGINE #
#########################
echo "- Installing the docker engine..."
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

echo "Done installing the docker engine"
echo

#########################
# NETWORK CONFIGURATION #
#########################
# Apply the network configuration to each kind of server
echo "Setting network configuration..."
if [ ${dell_r440+x} ]; then
    . r440_network.sh
elif [ ${dell_r330+x} ]; then
    . r330_network.sh
fi

echo "Done setting network configurations."
echo

#####################
# SETUP VNC SERVER  #
#####################
echo "- Setting up the VNC server..."

cat << EOF > /home/cryo/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF

echo "Done setting up the VNC server."
echo

######################
# SHOW FINAL MESSAGE #
######################
echo
echo "Server configuration finished successfully!"
echo "Please reboot the server so all changes take effect."
echo
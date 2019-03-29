#!/usr/bin/env bash

############################
# detecting type of server #
############################
. server_type.sh

####################
# Install packages #
####################
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
    tree

########################
# SMURF CONFIGURATIONS #
########################
# Create the smurf group.
groupadd smurf

# Add the cryo user to the smurf group, as primary groups
usermod -aG smurf cryo
usermod -g smurf cryo

# Create the data directories
mkdir -p /data/{pysmurf_ipython_data,smurf2mce_config,smurf2mce_logs,smurf_data}
mkdir -p /data/epics/ioc/data/sioc-smrf-ml00/

# Set the data directories persmissions 
chown -R cryo:smurf /data

#########################
# INSTALL DOCKER ENGINE #
#########################
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

###################
# INSTALL GIT LFS #
###################
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get -y install git-lfs
git lfs install

#########################
# Network configuration #
#########################
# Apply the network configuration to ecch kind of server
echo "Setting network configuration..."
if [ ${dell_r440+x} ]; then
    . r440_network.sh
elif [ ${dell_r330+x} ]; then
    . r330_network.sh
fi

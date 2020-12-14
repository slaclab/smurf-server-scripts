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
server_log_file="server_setup.log"
exec > >(tee -ia ${server_log_file})
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
    tigervnc-standalone-server \
    tigervnc-viewer \
    xfce4 \
    xfce4-goodies \
    dkms \
    tmux \
    python3-pip \
    ipython3 \
    gnuplot

# Install it lfs
curl -fsSL --retry-connrefused --retry 5 https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get -y install git-lfs
git lfs install

# Install this server scripts into the system
mkdir /usr/local/src/smurf-server-scripts
cp -r .. /usr/local/src/smurf-server-scripts

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

# Disable apport, and send core dump to custom location
sed -i -e 's/^enabled=.*/enabled=0/g' /etc/default/apport
rm -f /etc/sysctl.d/60-core-pattern.conf
cat << EOF > /etc/sysctl.d/60-core-pattern.conf
kernel.core_pattern = /data/cores/core_%t_%e_%P_%I_%g_%u
EOF

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

# Create the data directories, which should be owned by the cryo user
mkdir -p /data/{pysmurf_ipython_data,smurf2mce_config,smurf2mce_logs,smurf_data,cores,smurf_startup_cfg,smurf_data/tune,smurf_data/status}
mkdir -p /data/epics/ioc/data/sioc-smrf-ml00/
chown -R cryo:smurf /data

# Create the ipython home directory, which should be owned by the cryo user
mkdir -p /home/cryo/.ipython
chown -R cryo:smurf /home/cryo/.ipython

# Set git defaults configurations. Make a backup of the original file.
cp /home/cryo/.gitconfig /home/cryo/.gitconfig.BACKUP &> /dev/null
cat << EOF > /home/cryo/.gitconfig
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    lg1 = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all
    lg2 = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n'' %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all
    lg = !"git lg1"
    shawncommit = -c user.name='Shawn W. Henderson' -c user.email='shawn@slac.stanford.edu' commit
    edcommit = -c user.name='Edward Young' -c user.email='eyyoung@gmail.com' commit
[core]
    editor = emacs
[user]
    name = cryo
    email = cryo@$(hostname)
[filter "lfs"]
    required = true
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
[credential]
    helper = cache
EOF
chown -R cryo:smurf /home/cryo/.gitconfig{,.BACKUP}

# Set default bash aliases. Make a backup of the original file.
cp /home/cryo/.bash_aliases /home/cryo/.bash_aliases.BACKUP &> /dev/null
cat << OEF > /home/cryo/.bash_aliases
alias vnc_start='vncserver :2 -geometry 1920x1200 -alwaysshared -localhost yes'
alias killeverything='docker rm -f \$(docker ps -a -q)'
OEF
chown -R cryo:smurf /home/cryo/.bash_aliases{,.BACKUP}

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
    curl -fsSL --retry-connrefused --retry 5  https://download.docker.com/linux/ubuntu/gpg | apt-key add -

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
    curl -fsSL --retry-connrefused --retry 5 "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install docker-compose!"
    else
        chmod +x /usr/local/bin/docker-compose
    fi

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
EOF
fi

# Add the cswh-smrf-sp01 node name to ip address map entry
if ! grep -Fq cswh-smrf-sp01 /etc/hosts ; then
    cat << EOF >> /etc/hosts
# ATCA switch
10.0.1.101      cswh-smrf-sp01
EOF
fi

# Create the ssh configuration directory for the cryo user
mkdir -p /home/cryo/.ssh

# Add the ATCA shelfmanager host information to the ssh configuration
# file (if it doesn't exist already)
if ! grep -Fq shm-smrf-sp01 /home/cryo/.ssh/config 2> /dev/null; then
    cat << EOF >> /home/cryo/.ssh/config
Host shm-smrf-sp01
     User root
     ForwardX11 no

EOF
fi

# Add the ATCA switch host information to the ssh configuration
# file (if it doesn't exist already)
if ! grep -Fq cswh-smrf-sp01 /home/cryo/.ssh/config 2> /dev/null; then
    cat << EOF >> /home/cryo/.ssh/config
Host cswh-smrf-sp01
     User root
     ForwardX11 no

EOF
fi

# Change folder and files permissions
chown -R cryo:smurf  /home/cryo/.ssh/

# Generate ssh keys for the cryo user (if it doesn't exist)
if [ ! -e /home/cryo/.ssh/id_rsa ]; then
    su cryo -c 'ssh-keygen -t rsa  -N "" -f /home/cryo/.ssh/id_rsa'
fi

echo
echo "#########################"
echo "### Done setting SSH. ###"
echo "#########################"
echo

#######
# UFW #
#######
echo "#########################"
echo "### Setting up UFW... ###"
echo "#########################"
echo

# Enable the Uncomplicated Firewall program
ufw --force enable

# Allow ssh connections
ufw allow ssh

# Open port needed by docker swarm
ufw allow 2376/tcp
ufw allow 2377/tcp
ufw allow 7946/tcp
ufw allow 7946/udp
ufw allow 4789/udp

# Reload the new rules
ufw reload

echo
echo "#########################"
echo "### Done setting UFW. ###"
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
cp /home/cryo/.vnc/xstartup /home/cryo/.vnc/xstartup.BACKUP &> /dev/null
cat << EOF > /home/cryo/.vnc/xstartup
#!/bin/bash

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
EOF

# Make the script executable
chmod +x /home/cryo/.vnc/xstartup

# Change folder and files permissions
chown -R cryo:smurf  /home/cryo/.vnc/

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

    # Driver repository
    datadev_repo=https://github.com/slaclab/aes-stream-drivers

    # Driver name
    datadev_name=datadev

    # Driver version
    datadev_version=v5.7.0

    # Check if version exist in the repository
    if ! git ls-remote --refs --tag ${datadev_repo} | grep -q refs/tags/${datadev_version} > /dev/null ; then
        echo "ERROR: Invalid driver version: ${datadev_version}"
    else

        # Remove any loaded module
        rmmod ${datadev_name} &> /dev/null

        # Check is other version of the diver are install. If so, uninstall them.
        local list=$(dkms status -m ${datadev_name})

        if [ "${list}" ]; then
            echo "Removing previously installed versions..."

            declare -a local versions

            while IFS= read -r line; do
                versions+=($(echo "$line" | awk -F ', ' '{print $2}'))
            done <<< "${list}"

            for v in "${versions[@]}"; do
                echo "Uninstalling version ${v}..."
                dkms uninstall -m ${datadev_name} -v ${v}

                echo "Removing version ${v}..."
                dkms remove -m ${datadev_name}/${v} --all
            done
        fi

        # Clone the driver repository
        echo "Downloading driver..."
        rm -rf /usr/src/${datadev_name}-${v} && \
            mkdir /usr/src/${datadev_name}-${datadev_version}/
        git clone ${datadev_repo} -b ${datadev_version} \
            /usr/src/${datadev_name}-${datadev_version}/aes-stream-drivers

        # Verify is the repository was cloned correctly.
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to download the ${datadev_name} driver source!"
            rm -rf /usr/src/${datadev_name}-${datadev_version}/
        else
            # Create a configuration file for the driver
            echo "Creating driver configuration files..."
            cat << EOF > /etc/modprobe.d/${datadev_name}.conf
options ${datadev_name} cfgTxCount=1024 cfgRxCount=1024 cfgSize=131072 cfgMode=1 cfgCont=1
EOF
            cat << EOF > /usr/src/${datadev_name}-${datadev_version}/dkms.conf
MAKE="make -C aes-stream-drivers/data_dev/driver/"
CLEAN="make -C aes-stream-drivers/data_dev/driver/ clean"
BUILT_MODULE_NAME=${datadev_name}
BUILT_MODULE_LOCATION=aes-stream-drivers/data_dev/driver/
DEST_MODULE_LOCATION="/kernel/modules/misc"
PACKAGE_NAME=${datadev_name}
REMAKE_INITRD=no
AUTOINSTALL="yes"
PACKAGE_VERSION=${datadev_version}
EOF

            # Install the driver
            echo "Installing driver..."
            dkms add -m ${datadev_name} -v ${datadev_version} && \
                dkms build -m ${datadev_name} -v ${datadev_version} && \
                dkms install -m ${datadev_name} -v ${datadev_version}

            # Verify if the installation was successful.
            if [ $? -ne 0 ]; then
                echo "ERROR: Failed to install the ${datadev_name} driver!"
            else

                # Loading driver
                modprobe ${datadev_name}

                if [ $? -ne 0 ]; then
                    echo "ERROR: failed to load the module"
                else
                    # Remove the now legacy call to 'install_module.sh' in /etc/profile.d/smurf_config.sh
                    # and sudoers files.
                    sed -i -e '/.*\/usr\/local\/src\/datadev\/.*\/install-module.sh/d' /etc/profile.d/smurf_config.sh
                    sed -i -e '/.*\/usr\/local\/src\/datadev\/.*\/install-module.sh/d' /etc/sudoers

                    # Change the default virtual memory mmap count limits
                    sed -i -e '/^vm.max_map_count=.*/d' /etc/sysctl.conf
                    cat << EOF >> /etc/sysctl.conf
vm.max_map_count=262144
EOF

                    echo "The driver was installed and loaded successfully"
                fi
            fi
        fi
    fi

    echo
    echo "################################################"
    echo "### Done installing PCIe card kernel driver. ###"
    echo "################################################"
    echo
fi

###################
# RELEASE DOCKERS #
###################
echo "###################################"
echo "### Releasing docker scripts... ###"
echo "###################################"

# Move to the docker_script directory
cd ../docker_scripts

# Release latest utils, atca-monitor, guis, and pcie dockers. We need to release
# them as the 'cryo' user so that the generated files has the right permissions.
for d in 'utils' 'pcie' 'atca-monitor' 'guis' ; do
    v=$(./release-docker.sh -t ${d} -l | tail -n2 | head -n1)
    echo "Releasing '${d}' version '${v}'..."
    su cryo -c "./release-docker.sh -t ${d} -v ${v}"
done

# Move back to the original directory
cd -

echo "########################################"
echo "### Done releasing docker scripts... ###"
echo "########################################"

######################
# SHOW FINAL MESSAGE #
######################
echo
echo "Server configuration finished successfully!"
echo "The configuration log was written to '${server_log_file}'."
echo "Please reboot the server so all changes take effect."
echo
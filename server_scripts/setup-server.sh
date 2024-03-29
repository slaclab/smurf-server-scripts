#!/usr/bin/env bash

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
rm -f ${server_log_file}
touch ${server_log_file}
chown -R cryo:smurf ${server_log_file}
exec > >(tee -ia ${server_log_file})
exec 2>&1

. assert_server_type.sh

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

# Save the version of the script used during this setup:
version_file="version"
rm -f ${version_file}
touch ${version_file}
chown -R cryo:smurf ${version_file}
git describe --tags --always > ${version_file} 2> /dev/null

# Create smurf bash profile file and add the docker scripts to PATH
if ! grep -q "^export PATH=\${PATH}:/usr/local/src/smurf-server-scripts/docker_scripts\s*$" /etc/profile.d/smurf_config.sh 2> /dev/null; then
    echo "export PATH=\${PATH}:/usr/local/src/smurf-server-scripts/docker_scripts" >> /etc/profile.d/smurf_config.sh
fi

# Add an alias 'smurf-server-scripts-version' to the smurf bash profile file, to get the version of the smurf-server-script
# used during this setup
if ! grep -q "^alias smurf-server-scripts-version='cat /usr/local/src/smurf-server-scripts/server_scripts/version'\s*$" /etc/profile.d/smurf_config.sh 2> /dev/null; then
    echo "alias smurf-server-scripts-version='cat /usr/local/src/smurf-server-scripts/server_scripts/version'" >> /etc/profile.d/smurf_config.sh
fi

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
    echo "The swap partition does not exit. Skipping..."
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

# Set git defaults configurations. Make numbered backups of the original file.
# Set the right file permissions.
cp --backup=numbered templates/gitconfig /home/cryo/.gitconfig
chown -fR cryo:smurf /home/cryo/.gitconfig{,.~*}

# Set default bash aliases. Make numbered backups of the original file.
cp --backup=numbered templates/bash_aliases /home/cryo/.bash_aliases

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

# Create the xstartup file. Make numbered backups of the original file.
# Make the script executable, and with the right permissions.
mkdir -p /home/cryo/.vnc
cp --backup=numbered templates/vnc-xstartup /home/cryo/.vnc/xstartup
chmod +x /home/cryo/.vnc/xstartup
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

        # Check is other versions of the diver are installed. If so, uninstall them.
        datadev_list=$(dkms status -m ${datadev_name})

        if [ "${datadev_list}" ]; then
            echo "Removing previously installed versions..."

            declare -a datadev_versions

            while IFS= read -r line; do
                datadev_versions+=($(echo "$line" | awk -F ', ' '{print $2}'))
            done <<< "${datadev_list}"

            for v in "${datadev_versions[@]}"; do
                echo "Uninstalling version ${v}..."
                dkms uninstall -m ${datadev_name} -v ${v}

                echo "Removing version ${v}..."
                dkms remove -m ${datadev_name}/${v} --all
            done
        fi

        # Clone the driver repository
        echo "Downloading driver..."
        rm -rf /usr/src/${datadev_name}-${datadev_version} && \
            mkdir -p /usr/src/${datadev_name}-${datadev_version}/
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
MAKE="make -C aes-stream-drivers/data_dev/driver/ KVER=\${kernelver}"
CLEAN="make -C aes-stream-drivers/data_dev/driver/ KVER=\${kernelver} clean"
BUILT_MODULE_NAME=${datadev_name}
BUILT_MODULE_LOCATION=aes-stream-drivers/data_dev/driver/
DEST_MODULE_LOCATION=/kernel/modules/misc
PACKAGE_NAME=${datadev_name}
REMAKE_INITRD=no
AUTOINSTALL=yes
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

# Release latest pysmurf-dev, utils, atca-monitor, guis, and pcie dockers.
# We need to release them as the 'cryo' user so that the generated files
# has the right permissions.
for d in 'utils' 'pcie' 'atca-monitor' 'guis' 'pysmurf-dev'; do
    v=$(./release-docker.sh -t ${d} -l | tail -n2 | head -n1)
    echo "Releasing '${d}' version '${v}'..."
    su cryo -c "./release-docker.sh -t ${d} -v ${v}"
done

# Move back to the original directory
cd - &> /dev/null

echo "######################################"
echo "### Done releasing docker scripts. ###"
echo "######################################"

#######################
# RELEASE SHAWNHAMMER #
#######################
echo "########################################"
echo "### Releasing shawnhammer scripts... ###"
echo "########################################"

# List of shawnhammer scripts
shawnhammer_scripts=('ping_carrier' 'shawnhammer' 'shawnhammerfunctions' 'switch_carrier')

# First, move soft links defined, if any, under
# "/usr/local/src/smurf-server-scripts/docker_scripts/"
# to the standard location "/home/cryo/.local/bin"
old_script_path='/usr/local/src/smurf-server-scripts/docker_scripts'
new_script_path='/home/cryo/.local/bin'

# Make sure the 'new_script_path' directory exist
mkdir -p ${new_script_path}

for s in ${shawnhammer_scripts[@]}; do
    mv ${old_script_path}/${s} ${new_script_path}/${s} &> /dev/null && \
        chown -fR cryo:smurf ${new_script_path}/${s} && \
        echo "\"${s}\" was found under \"${old_script_path}/\". It was moved to \"${new_script_path}/\"."
done

# Get the latest version of pysmurf-dev. This version was either,
# released, or already existed.
cd ../docker_scripts
pysmurf_dev_version=$(./release-docker.sh -t pysmurf-dev -l | tail -n2 | head -n1)
cd - &> /dev/null

# Now create, new soft links.
# They will be created in the standard location "/home/cryo/.local/bin"
# and will point to the latest pysmurf-dev version.=, which was
# either released or already existed.
# If the soft links already exist, they won't be overridden.
shawnhammer_scripts_location="/home/cryo/docker/pysmurf/dev/${pysmurf_dev_version}/pysmurf/scratch/shawn/scripts"
for s in ${shawnhammer_scripts[@]}; do
    ln -s ${shawnhammer_scripts_location}/${s}.sh ${new_script_path}/${s} &> /dev/null && \
        chown -fR cryo:smurf ${new_script_path}/${s} && \
        echo "\"${s}\" was created, pointing to \"${shawnhammer_scripts_location}/${s}.sh\""
done

# The 'new_script_path' directory and its content should be owned by the 'cryo' user
chown -R cryo:smurf ${new_script_path}

echo "###########################################"
echo "### Done releasing shawnhammer scripts. ###"
echo "###########################################"

#########################################
# INSTALL THESE SCRIPTS INTO THE SYSTEM #
#########################################

# NOTE: We need to install these scripts, after installing
# shawnhammer scripts, to avoid overriding existing versions

echo "###################################################"
echo "### Installing these scripts into the system... ###"
echo "###################################################"

rm -rf /usr/local/src/smurf-server-scripts
mkdir -p /usr/local/src/smurf-server-scripts
cp -r .. /usr/local/src/smurf-server-scripts

echo "######################################################"
echo "### Done installing these scripts into the system. ###"
echo "######################################################"

######################
# SHOW FINAL MESSAGE #
######################
echo
echo "Server configuration finished successfully!"
echo "The configuration log was written to '${server_log_file}'."
echo "Please reboot the server so all changes take effect."
echo

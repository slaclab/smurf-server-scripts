#!/usr/bin/env bash

echo "This script will setup a generic server for running SMuRF dockers."
echo "Note: You must execute this script with root privileges (via sudo)."
echo

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root (use sudo)."
    exit 1
fi

if [[ -z "${SUDO_USER}" || "${SUDO_USER}" == "root" ]]; then
    echo "ERROR: This script must be run via 'sudo', not as bare root."
    echo "Usage: sudo ./setup-generic-server.sh"
    exit 1
fi

echo "Invoking user: ${SUDO_USER}"
echo

read -p "Are you sure you want to continue? [Y/N] " -r
echo

if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
    echo "Aborting installation..."
    exit 0
fi

# Redirect stdout and stderr to a log file via tee.
server_log_file="server_setup.log"
rm -f ${server_log_file}
touch ${server_log_file}
chown ${SUDO_USER} ${server_log_file}
exec > >(tee -ia ${server_log_file})
exec 2>&1

echo "##############################"
echo "### Installing packages... ###"
echo "##############################"
echo

apt-get -y update
apt-get -y install \
    openssh-server \
    g++ \
    cmake \
    vim \
    git \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    tree \
    screen \
    tmux \
    python3-pip \
    ipython3 \
    jq

# Install git lfs
curl -fsSL --retry-connrefused --retry 5 https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get -y install git-lfs
git lfs install

# Save the version of the script used during this setup
version_file="version"
rm -f ${version_file}
touch ${version_file}
chown ${SUDO_USER} ${version_file}
git describe --tags --always > ${version_file} 2> /dev/null

echo
echo "#################################"
echo "### Done installing packages. ###"
echo "#################################"
echo

echo "####################################"
echo "### Creating smurf group...      ###"
echo "####################################"
echo

# The SMuRF docker containers run as uid 1000:gid 1001 (cryo:smurf).
# This is hardcoded in the container images and the .env template.
# We create the smurf group with gid 1001 on the host so that host
# users added to this group can access container-written files.
smurf_gid=1001

if getent group ${smurf_gid} > /dev/null 2>&1; then
    existing_group=$(getent group ${smurf_gid} | cut -d: -f1)
    if [[ "${existing_group}" != "smurf" ]]; then
        echo "ERROR: GID ${smurf_gid} is already in use by group '${existing_group}'."
        echo "The SMuRF containers hardcode gid ${smurf_gid}. Either free this GID"
        echo "or add ${SUDO_USER} to '${existing_group}' manually and continue setup by hand."
        exit 1
    else
        echo "Group 'smurf' (gid ${smurf_gid}) already exists."
    fi
elif getent group smurf > /dev/null 2>&1; then
    echo "ERROR: Group 'smurf' exists but with a different GID than ${smurf_gid}."
    echo "The SMuRF containers hardcode gid ${smurf_gid}. Please resolve this conflict."
    exit 1
else
    groupadd -g ${smurf_gid} smurf
    echo "Created group 'smurf' with gid ${smurf_gid}."
fi

usermod -aG smurf ${SUDO_USER}
echo "Added ${SUDO_USER} to group 'smurf'."

echo
echo "####################################"
echo "### Done creating smurf group.   ###"
echo "####################################"
echo

echo "#########################################"
echo "### Creating data directories...      ###"
echo "#########################################"
echo

# These directories are bind-mounted into the containers.
# They must be owned by uid 1000:gid 1001 (the container's cryo:smurf).
# We do not create a cryo user on this host; ownership is numeric.
# The setgid bit ensures new files/dirs inherit gid 1001, and group-write
# lets host users in the smurf group read and write the data.
mkdir -p /data/{smurf_data,smurf_data/tune,smurf_data/status,pysmurf_ipython_data,smurf2mce_config,smurf2mce_logs,cores,smurf_startup_cfg}
chown -R 1000:1001 /data
chmod -R g+rwX /data
find /data -type d -exec chmod g+s {} \;

echo "Created /data directories (owned 1000:1001, setgid, group-writable)."
echo
echo "NOTE: release-docker.sh defaults to /home/cryo/docker/smurf/ which does"
echo "not exist on this machine. Use the -o flag to specify an output directory, e.g.:"
echo "  release-docker.sh -t system -v <version> -o /home/${SUDO_USER}/docker/smurf/stable/<version>"

echo
echo "#########################################"
echo "### Done creating data directories.   ###"
echo "#########################################"
echo

echo "#######################################"
echo "### Installing the docker engine... ###"
echo "#######################################"
echo

if which docker > /dev/null 2>&1; then
    echo "Docker is already installed in the system:"
    docker --version
else
    # Add Docker's official GPG key
    curl -fsSL --retry-connrefused --retry 5 https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    # Verify the key fingerprint
    apt-key fingerprint 0EBFCD88

    # Set up the stable repository
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"

    apt-get update

    apt-get -y install docker-ce docker-ce-cli containerd.io

    # Create the docker group (may already exist from the install)
    groupadd docker 2>/dev/null || true

    systemctl enable docker

    # Setup the docker daemon logging configuration
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "${script_dir}/templates/daemon.json" /etc/docker/daemon.json

    # Setup apparmor profile for smurf containers if apparmor is available
    if which apparmor_parser > /dev/null 2>&1; then
        cp "${script_dir}/templates/smurf-apparmor-profile" /etc/apparmor.d/docker-smurf
        apparmor_parser -r -W /etc/apparmor.d/docker-smurf
    else
        echo "AppArmor not available, skipping docker-smurf profile."
    fi
fi

# The smurf run/stop scripts invoke "docker-compose" (v1 standalone).
# Ensure it is available: if the v2 plugin works but the standalone
# command doesn't, install a shim wrapper.
if docker-compose --version > /dev/null 2>&1; then
    echo "docker-compose is available:"
    docker-compose --version
elif docker compose version > /dev/null 2>&1; then
    echo "docker-compose (standalone) not found, but docker compose (v2 plugin) is available."
    echo "Installing shim at /usr/local/bin/docker-compose..."
    cat << 'SHIM' > /usr/local/bin/docker-compose
#!/bin/sh
exec docker compose "$@"
SHIM
    chmod +x /usr/local/bin/docker-compose
else
    echo "Installing docker-compose standalone..."
    curl -fsSL --retry-connrefused --retry 5 \
        "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to install docker-compose!"
    else
        chmod +x /usr/local/bin/docker-compose
    fi
fi

# Add user to docker group (do this regardless, in case docker was
# already installed but the user wasn't in the group)
usermod -aG docker ${SUDO_USER}
echo "Added ${SUDO_USER} to group 'docker'."

echo
echo "#########################################"
echo "### Done installing the docker engine ###"
echo "#########################################"
echo

echo "#########################################"
echo "### Applying system configurations... ###"
echo "#########################################"
echo

# Enable persistent journald logs
if ! grep -Fq "Storage=persistent" /etc/systemd/journald.conf; then
    echo Storage=persistent >> /etc/systemd/journald.conf
fi

# Disable apport and send core dumps to /data/cores
if [[ -f /etc/default/apport ]]; then
    sed -i -e 's/^enabled=.*/enabled=0/g' /etc/default/apport
fi
rm -f /etc/sysctl.d/60-core-pattern.conf
cat << EOF > /etc/sysctl.d/60-core-pattern.conf
kernel.core_pattern = /data/cores/core_%t_%e_%P_%I_%g_%u
EOF

echo
echo "############################################"
echo "### Done applying system configurations. ###"
echo "############################################"
echo

echo "###################################################"
echo "### Installing smurf-server-scripts...          ###"
echo "###################################################"
echo

# Determine the repo root (parent of server_scripts/)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(dirname "${script_dir}")"

rm -rf /usr/local/src/smurf-server-scripts
mkdir -p /usr/local/src/smurf-server-scripts
cp -r "${repo_dir}/." /usr/local/src/smurf-server-scripts

# Mark as a git safe directory so release-docker.sh -u (self-update) works
# for non-root users. This is a system-level setting since the install is
# system-wide.
git config --system --add safe.directory /usr/local/src/smurf-server-scripts

# Add docker_scripts to PATH for all users
if ! grep -q "^export PATH=\${PATH}:/usr/local/src/smurf-server-scripts/docker_scripts\s*$" /etc/profile.d/smurf_config.sh 2>/dev/null; then
    echo 'export PATH=${PATH}:/usr/local/src/smurf-server-scripts/docker_scripts' >> /etc/profile.d/smurf_config.sh
fi

# Add version alias
if ! grep -q "^alias smurf-server-scripts-version=" /etc/profile.d/smurf_config.sh 2>/dev/null; then
    echo "alias smurf-server-scripts-version='cat /usr/local/src/smurf-server-scripts/server_scripts/version'" >> /etc/profile.d/smurf_config.sh
fi

echo
echo "######################################################"
echo "### Done installing smurf-server-scripts.          ###"
echo "######################################################"
echo

echo
echo "============================================="
echo "Server configuration finished successfully!"
echo "============================================="
echo
echo "The configuration log was written to '${server_log_file}'."
echo
echo "Next steps:"
echo "  1. Log out and back in (so group membership takes effect),"
echo "     or run: newgrp smurf && newgrp docker"
echo "  2. Release the docker you need, e.g.:"
echo "     release-docker.sh -t system -v <version>"
echo

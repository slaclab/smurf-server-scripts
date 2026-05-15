[DOE Code](https://www.osti.gov/doecode/biblio/75850)

# Scripts to setup SMuRF server

## Description

This repository contains a set of useful scripts for setting up SMuRF servers, divided in two main categories:
- Scripts used to setup a SMuRF server from scratch,
- Scripts used to release docker system in an SMuRF server.

These scripts are used during SMuRF system deployments as described [here](https://confluence.slac.stanford.edu/display/SMuRF/SMuRF+Deployment).

## Server setup script

These scripts are used to setup SMuRF servers, as part of the [initial configuration procedure](https://confluence.slac.stanford.edu/display/SMuRF/SMuRF+System+Initial+Configuration).

The scripts can also be used to upgrade existing SMuRF server.

### How to setup a new SMuRF server from scratch

In order to setup a new SMuRF server, please follow the initial configuration procedure described [here](https://confluence.slac.stanford.edu/display/SMuRF/SMuRF+System+Initial+Configuration). In that procedure, the [setup-server.sh](server_scripts/setup-server.sh) script is used to setup the SMuRF servers automatically.

### How to upgrade an existing SMuRF server

If you have a previously configured SMuRF server, you can use the [setup-server.sh](server_scripts/setup-server.sh) script to upgrade your server configuration, when new version of this repository are released. New version contain bug fixes and new feature which you should install in your server to keep it up to date.

In order to upgrade your existing server follow these steps:

1. First, reboot the server.
2. Then, run these commands on any directory of your preference (if the directory `smurf-server-scripts` already exist in that location, you will need to remove it first):
```bash
$ git clone https://github.com/slaclab/smurf-server-scripts -b <VERSION>
$ cd smurf-server-scripts/server_scripts/
$ sudo ./setup-server.sh
```
3. Finally, reboot the server.

Where `<VERSION>` is the version of this script you want to use.

A list of available versions, with release notes described the changes on each version, can be found in the releases section of this repository [here](https://github.com/slaclab/smurf-server-scripts/releases).

To see the version of the script used to configured your system, run this command:
```bash
$ smurf-server-scripts-version
```

**Note**: if the command `smurf-server-scripts-version` does not exist in your system, then you server was setup with a script version previous to `R3.8.0`.

## Docker System Release Scripts

As part of the system initialization described above, scripts to release SMuRF docker-based systems are installed in the server. For more information about these scripts, please refer to [this documentation](docker_scripts/README.md).

## smurfhammer (the `smurf` CLI)

`smurfhammer.py` is a Python orchestration tool for starting, managing, and inspecting running SMuRF systems. It replaces the legacy `shawnhammer.sh` bash script with a cleaner interface and live progress display.

The tool is invoked as `smurf` on the command line (via symlink).

### Quick start

```bash
smurf up                    # Start the full system (parallel, live progress table)
smurf status                # Check what's running right now
smurf attach 2              # Jump into an ipython session on slot 2
smurf down                  # Tear everything down
smurf restart 3             # Restart pyrogue on slot 3
smurf logs 2                # Tail pyrogue server logs
smurf release -t system     # Install a docker release (wraps release-docker.sh)
```

Run `smurf --help` or `smurf <command> --help` for full documentation on any command.

### Configuration

`smurf` uses a YAML config file (default: `/data/smurf_startup_cfg/smurf_startup.yml`). An example is provided at [docker_scripts/smurfhammer_example.yml](docker_scripts/smurfhammer_example.yml).

```yaml
crate:
  shelfmanager: shm-smrf-sp01
  id: 1
  fans: full

tmux_session: smurf
pysmurf: /home/cryo/docker/pysmurf/dev/v4.1.0

slots:
  2:
    pyrogue: /home/cryo/docker/smurf/current
    pysmurf_cfg: cfg_files/experiment.cfg
  3:
    pyrogue: /home/cryo/docker/smurf/current
    pysmurf_cfg: cfg_files/experiment.cfg

startup:
  reboot: true
  setup: true
```

### Installation

On deployment servers where `docker_scripts/` is already in PATH, `smurf` is available immediately.

For other machines (e.g. a local checkout of this repo):
```bash
export PATH=/path/to/smurf-server-scripts/docker_scripts:$PATH
```

### Requirements

- Python 3.6+
- PyYAML (`pip install pyyaml`) — already present on all SMuRF servers
- tmux, docker (for system management commands)

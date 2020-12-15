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

In order to upgrade your existing server follow these steps, on any directory in your server:
```bash
$ git clone https://github.com/slaclab/smurf-server-scripts -b <VERSION>
$ cd smurf-server-scripts/server_scripts/
$ sudo ./setup-server.sh
```

Where `<VERSION>` is the version of this script you want to use.

A list of available versions, with release notes described the changes on each version, can be found in the releases section of this repository [here](https://github.com/slaclab/smurf-server-scripts/releases).

## Docker System Release Scripts

As part of the system initialization described above, scripts to release SMuRF docker-based systems are installed in the server. For more information about these scripts, please refer to [this documentation](docker_scripts/README.md).

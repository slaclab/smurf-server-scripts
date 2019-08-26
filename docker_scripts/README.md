# Scripts to release dockers systems

## Description

This scripts are used to release a set of files necessary to run SMuRF system based on dockers.

## Installation

This script will be installed by the `setup-server.sh` script when setting up a new server. It will installed under `/usr/local/src/smurf-server-scripts/docker_scripts`, and that path is added to the `PATH` so that this script can be called from any location.

## Usage

To release a new system, run:

```
release-docker.sh -t|--type <type> <arguments>
```

where **type** specified the type of system to release, and **arguments** depends on the type.

The different type of systems, and their respective arguments are described next.

### Full stable system

A stable system is formed by a SMuRF server and pysmurf. For stables systems, the SMuRF server contains both the smur2mce application and the files from an specific firmware version.

The server runs in the [smur2mce docker](https://github.com/slaclab/smurf2mce-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release an stable system, use **type = system**, with the following arguments:

```
release-docker.sh -t|--type system -s|--smurf2mce-version <smurf2mce_version> -p|--pysmurf_version <pysmurf_version>
                  [-N|--slot <slot_number>] [-o|--output-dir <output_dir>] [-h|--help]

  -s|--smurf2mce-version <smurf2mce_version> : Version of the smurf2mce docker image.
  -p|--pysmurf_version   <pysmurf_version>   : Version of the pysmurf docker image.
  -c|--comm-type         <commm_type>        : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot              <slot_number>       : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir        <output_dir>        : Top directory where to release the scripts. Defaults to
                                               /home/cryo/docker/smurf/stable/<slot_number>/<smurf2mce_version>.
  -h|--help                                  : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

### Full system, for Firmware development

A development system is formed by a SMuRF server and pysmurf. For firmware development systems, the SMuRF server contains the smurf2mce application, while the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [smur2mce-base docker](https://github.com/slaclab/smurf2mce-base-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a firmware development system, use **type = system-dev-fw**, with the following arguments:

```
release-docker.sh -t|--type system-dev-fw -s|--smurf2mce-base-version <smurf2mce-base_version> -p|--pysmurf_version <pysmurf_version>
                  [-N|--slot <slot_number>] [-o|--output-dir <output_dir>] [-h|--help]

  -s|--smurf2mce-base-version <smurf2mce-base_version> : Version of the smurf2mce-base docker image.
  -p|--pysmurf_version        <pysmurf_version>        : Version of the pysmurf docker image.
  -c|--comm-type              <commm_type>             : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot                   <slot_number>            : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir             <output_dir>             : Top directory where to release the scripts. Defaults to
                                                         /home/cryo/docker/smurf/dev_fw/<slot_number>/<smurf2mce_base_version>.
  -h|--help                                            : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

### Full system, for Software development

A development system is formed by a SMuRF server and pysmurf. For software development systems, the SMuRF server contains a smurf2mce application provided by the user in a folder called **smurf2mce** in the release folder. The release script will do a clone of the master branch of the [smurf2mce git repository](https://github.com/slaclab/smurf2mce). Also, the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [smur2mce-base docker](https://github.com/slaclab/smurf2mce-base-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a software development system, use **type = system-dev-sw**, with the following arguments:

```
release-docker.sh -t|--type system-dev-fw -s|--smurf2mce-base-version <smurf2mce-base_version> -p|--pysmurf_version <pysmurf_version>
                  [-N|--slot <slot_number>] [-o|--output-dir <output_dir>] [-h|--help]

  -s|--smurf2mce-base-version <smurf2mce-base_version> : Version of the smurf2mce-base docker image. Used as a base
                                                         image; smurf2mce will be overwritten by the local copy.
  -p|--pysmurf_version        <pysmurf_version>        : Version of the pysmurf docker image.
  -c|--comm-type              <commm_type>             : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot                   <slot_number>            : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir             <output_dir>             : Top directory where to release the scripts. Defaults to
                                                         /home/cryo/docker/smurf/dev_sw/<slot_number>/<smurf2mce-base_version>.
  -h|--help                                            : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

When this container is run for the first time, the freshly cloned version of smurf2mce need to be compiled. In order to do that, edit the `docker-compose.yml` file, commenting out the `command:` line under the `smurf_server` section and start the container; in this way the container will run in bash script. Once started, attach to the container, go to the smurf2mce folder (`/usr/local/src/smurf2mce/mcetransmit`) and build it. Then exit and stop the container and revert the changes made to the `docker-compose.yml` file. You will need to repeat this steps every time you made changes to the C++ code; not necesary when making changes to the python code.

### Pysmurf application, in development mode

A pysmurf application in development mode, consist only on pysmurf. It contains a pysmurf application provided by the user in a folder called **pysmurf** in the release folder. The release script will do a clone of the master branch of the [pysmurf git repository](https://github.com/slaclab/pysmurf).

Pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a pysmurf development application, use **type = pysmurf-dev**, with the following arguments:

```
release-docker.sh -t pysmurf-dev -p|--pysmurf_version <pysmurf_version>
                  [-o|--output-dir <output_dir>] [-h|--help]"

  -p|--pysmurf_version <pysmurf_version> : Version of the pysmurf docker image. Used as a base.
                                           image; pysmurf will be overwritten by the local copy.
  -o|--output-dir      <output_dir>      : Directory where to release the scripts. Defaults to
                                           /home/cryo/docker/pysmurf/dev.
  -h|--help                              : Show this message.
```

### Utility application

An utility application contains tools useful on SMuRF system.

It run in the [smurf-base docker](https://github.com/slaclab/smurf-base-docker).

To release an utility application, use **type = utils**, with the following arguments:

```
release-docker.sh -t utils -v|--version <smurf_base_version> [-o|--output-dir <output_dir>] [-h|--help]

  -v|--version    <smurf-base_version> : Version of the smurf-base docker image.
  -o|--output-dir <output_dir>         : Directory where to release the scripts. Defaults to
                                         /home/cryo/docker/utils.
  -h|--help                            : Show this message.
```

### TPG IOC

A Timing Pattern Generator (TPG) IOC.

It runs in the [smurf-tpg-ioc docker](https://github.com/slaclab/smurf-tpg-ioc-docker).

To release a TPG IOCm use **type = tpg**, with the following arguments:

```
release-docker.sh -t tpg -v|--version <tpg_version> [-o|--output-dir <output_dir>] [-h|--help]

  -v|--version    <tpg_version>   : Version of the smurf-tpg-ioc docker image.
  -o|--output-dir <output_dir>    : Directory where to release the scripts. Defaults to
                                    /home/cryo/docker/tpg.
  -h|--help                       : Show this message.
```

### PCIe utility application

An application with utilities related to the SMuRF PCIe card.

It runs in the [smurf-pcie docker](https://github.com/slaclab/smurf-pcie-docker).

To release a PCIe utility application use **type = pcie**, with the following arguments:

```
release-docker.sh -t pcie -v|--version <pcie_version> [-o|--output-dir <output_dir>] [-h|--help]

  -v|--version    <pcie_version> : Version of the smurf-pcie docker image.
  -o|--output-dir <output_dir>   : Directory where to release the scripts. Defaults to
                                   /home/cryo/docker/pcie
  -h|--help                      : Show this message.
```

### ATCA monitor application

A PyRogue-based application used to monitor an entire ATCA crate.

It runs the [smurf-atca-monitor docker](https://github.com/slaclab/smurf-atca-monitor).

To release an ATCA monitor application use **type = atca-monitor**, with the following arguments:

```
release-docker.sh -t atca-monitor -v|--version <atca-monitor_version> [-o|--output-dir <output_dir>] [-h|--help]

  -v|--version    <atca-monitor_version> : Version of the smurf-atca-monitor docker image.
  -o|--output-dir <output_dir>           : Directory where to release the scripts. Defaults to
                                           /home/cryo/docker/atca-monitor
  -h|--help                              : Show this message.
```





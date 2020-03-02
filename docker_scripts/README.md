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

[Pysmurf application, in development mode](#pysmurf-application,-in-development-mode)

### Full systems based on pysmurf and rogue v4

#### Full stable system

A stable system is formed by a pysmurf server and a pysmurf client. For stables systems, the pysmurf server contains both the pysmurf server application and the files from an specific firmware version.

The server runs in the [pysmurf-server docker](https://github.com/slaclab/pysmurf-stable-docker), and pysmurf runs in the the [pysmurf-client docker](https://github.com/slaclab/pysmurf).

To release an stable system, use **type = system**, with the following arguments:

```
release-docker.sh -t system
                  -s|--server-version <pysmurf_server_version>
                  -p|--client-version <pysmurf_client_version>
                  [-N|--slot <slot_number>]
                  [-o|--output-dir <output_dir>]
                  [-l|--list-versions]
                  [-h|--help]

  -s|--server-version <pysmurf_server_version> : Version of the pysmurf-server docker image.
  -p|--client-version <pysmurf_client_version> : Version of the pysmurf-client docker image.
  -c|--comm-type      <commm_type>             : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot           <slot_number>            : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir     <output_dir>             : Top directory where to release the scripts. Defaults to
                                                 /home/cryo/docker/smurf/stable/<slot_number>/<pysmurf_version>
  -l|--list-versions                           : Print a list of available versions.
  -h|--help                                    : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

The `run.sh` script accepts options to be passed to the pysmurf-server's startup script, using the option `-e|--extra-opts`. For example, the `--hard-boot` option can be passed to the pysmurf-server by running `run.sh -e --hard-boot`. Multiple options, or options with argument can be passed by wrapping then in quotes, for example: `run.sh -e "--hard-boot -a 10.0.1.101 --disable-bay1"`.

#### Full system, for Firmware development

A development system is formed by a pysmurf server and a pysmurf client. For firmware development systems, the pysmurf server contains the pysmurf server application, while the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [pysmurf-server-base docker](https://github.com/slaclab/pysmurf), and pysmurf runs in the the [pysmurf-client docker](https://github.com/slaclab/pysmurf). As both of these images are released together, the user only needs to specify one version number, which will be used for both images.

To release a firmware development system, use **type = system-dev-fw**, with the following arguments:

```
release-docker.sh -t system-dev-fw
                  -v|--version <pysmurf_version>
                  [-N|--slot <slot_number>]
                  [-o|--output-dir <output_dir>]
                  [-l|--list-versions]
                  [-h|--help]

  -v|--version    <pysmurf_version>   : Version of the pysmurf server docker image.
  -c|--comm-type  <commm_type>        : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot       <slot_number>       : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir <output_dir>        : Top directory where to release the scripts. Defaults to
                                        /home/cryo/docker/smurf/dev_fw/<slot_number>/<pysmurf_version>
  -l|--list-versions                  : Print a list of available versions.
  -h|--help                           : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

The `run.sh` script accepts options to be passed to the pysmurf-server's startup script, using the option `-e|--extra-opts`. For example, the `--hard-boot` option can be passed to the pysmurf-server by running `run.sh -e --hard-boot`. Multiple options, or options with argument can be passed by wrapping then in quotes, for example: `run.sh -e "--hard-boot -a 10.0.1.101 --disable-bay1"`.

#### Full system, for Software development

A development system is formed by a pysmurf server a pysmurf client. For software development systems, the pysmurf server uses local copies of both rogue and pysmurf; rogue is located in a folder called **rogue**, and pysmurf is located in a folder called **pysmurf** in the release folder. The release script will checkout and build the specified version of pysmurf and the corresponding  version of rogue from [rogue git repository](https://github.com/slaclab/rogue) and [pysmurf git repository](https://github.com/slaclab/pysmurf) respectively. Also, the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [pysmurf-server-base docker](https://github.com/slaclab/pysmurf), and pysmurf runs in the the [pysmurf-client docker](https://github.com/slaclab/pysmurf).

To release a software development system, use **type = system-dev-sw**, with the following arguments:

```
release-docker.sh -t system-dev-sw
                  -v|--version <pysmurf_version>
                  [-N|--slot <slot_number>]
                  [-o|--output-dir <output_dir>]
                  [-l|--list-versions]
                  [-h|--help]

  -v|--version    <pysmurf_version>   : Version of the pysmurf server docker image.
  -c|--comm-type  <commm_type>        : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot       <slot_number>       : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir <output_dir>        : Top directory where to release the scripts. Defaults to
                                        /home/cryo/docker/smurf/dev_sw/<slot_number>/<pysmurf_version>
  -l|--list-versions                  : Print a list of available versions.
  -h|--help                           : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

The `run.sh` script accepts options to be passed to the pysmurf-server's startup script, using the option `-e|--extra-opts`. For example, the `--hard-boot` option can be passed to the pysmurf-server by running `run.sh -e --hard-boot`. Multiple options, or options with argument can be passed by wrapping then in quotes, for example: `run.sh -e "--hard-boot -a 10.0.1.101 --disable-bay1"`.

When this system is released, both rogue and pysmurf are build, so you can start the docker containers without any change. Moreover, you can modify python code from both local copies of rogue and pysmurf, and those changes will take effect by simply restarting the docker containers. However, if you make changes to C++ code, you will need to build the code. In order to do that, follow the following steps:
- First, edit the `docker-compose.yml` file, and comment out the line that stat with `command:` under the `smurf_server` section, and un-comment out the line `entrypoint: bash`.
- Start the container (by running the `run.sh` script). It will run a bash session instead of starting the pysmurf server.
- Attach to the container using the command `docker attach smurf_server_s<N>`, where *N* depend on which slot you are using. You will be now in the bash session inside the container.
- If you changed code in rogue go to the rogue folder (`/usr/local/src/rogue`) and make a clean build:
```
rm -rf build
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DROGUE_INSTALL=local ..
make -j4 install
```
- Go to the pysmurf folder (`/usr/local/src/pysmurf`) and make a clean build:
```
rm -rf build
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
make -j4
```
- Exist the docker container, by typing `exit`.
- Change back the `docker-compose.yml` file to its original state.

Now you can start the docker container normally again.

You need to repeat these steps every time you make changes to C++ code.

If you make changes to these repositories and want to push them back to Github, you need to create a new branch (the reason for this is that when you checkout a tagged version, you will in  detached mode, i.e. no attach to any branch). In order to do that you can run the following commands (you can create the new branch even after committing changes):"
```
git checkout -b <new-branch-name>"
git push -set-upstream origin <new-branch-name>"
```

Replace `<new-branch-name>`, with an appropriate branch name. After you push all your changes to Github, you should open a PR to merge your changes into the master branch.

### Full systems based on smurf2mce and rogue v3

#### Full stable system

A stable system is formed by a SMuRF server and pysmurf. For stables systems, the SMuRF server contains both the smur2mce application and the files from an specific firmware version.

The server runs in the [smur2mce docker](https://github.com/slaclab/smurf2mce-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release an stable system, use **type = system3**, with the following arguments:

```
release-docker.sh -t|--type system3 -s|--smurf2mce-version <smurf2mce_version> -p|--pysmurf_version <pysmurf_version>
                  [-N|--slot <slot_number>] [-o|--output-dir <output_dir>] [-h|--help]

  -s|--smurf2mce-version <smurf2mce_version> : Version of the smurf2mce docker image.
  -p|--pysmurf-version   <pysmurf_version>   : Version of the pysmurf docker image.
  -c|--comm-type         <commm_type>        : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot              <slot_number>       : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir        <output_dir>        : Top directory where to release the scripts. Defaults to
                                               /home/cryo/docker/smurf/stable/<slot_number>/<smurf2mce_version>.
  -h|--help                                  : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

#### Full system, for Firmware development

A development system is formed by a SMuRF server and pysmurf. For firmware development systems, the SMuRF server contains the smurf2mce application, while the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [smur2mce-base docker](https://github.com/slaclab/smurf2mce-base-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a firmware development system, use **type = system3-dev-fw**, with the following arguments:

```
release-docker.sh -t|--type system3-dev-fw -s|--smurf2mce-base-version <smurf2mce-base_version> -p|--pysmurf_version <pysmurf_version>
                  [-N|--slot <slot_number>] [-o|--output-dir <output_dir>] [-h|--help]

  -s|--smurf2mce-base-version <smurf2mce-base_version> : Version of the smurf2mce-base docker image.
  -p|--pysmurf-version        <pysmurf_version>        : Version of the pysmurf docker image.
  -c|--comm-type              <commm_type>             : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot                   <slot_number>            : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir             <output_dir>             : Top directory where to release the scripts. Defaults to
                                                         /home/cryo/docker/smurf/dev_fw/<slot_number>/<smurf2mce_base_version>.
  -h|--help                                            : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

#### Full system, for Software development

A development system is formed by a SMuRF server and pysmurf. For software development systems, the SMuRF server contains a smurf2mce application provided by the user in a folder called **smurf2mce** in the release folder. The release script will do a clone of the master branch of the [smurf2mce git repository](https://github.com/slaclab/smurf2mce). Also, the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [smur2mce-base docker](https://github.com/slaclab/smurf2mce-base-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a software development system, use **type = system3-dev-sw**, with the following arguments:

```
release-docker.sh -t|--type system3-dev-sw -s|--smurf2mce-base-version <smurf2mce-base_version> -p|--pysmurf_version <pysmurf_version>
                  [-N|--slot <slot_number>] [-o|--output-dir <output_dir>] [-h|--help]

  -s|--smurf2mce-base-version <smurf2mce-base_version> : Version of the smurf2mce-base docker image. Used as a base
                                                         image; smurf2mce will be overwritten by the local copy.
  -p|--pysmurf-version        <pysmurf_version>        : Version of the pysmurf docker image.
  -c|--comm-type              <commm_type>             : Communication type with the FPGA (eth or pcie). Defaults to 'eth'.
  -N|--slot                   <slot_number>            : ATCA crate slot number (2-7) (Optional).
  -o|--output-dir             <output_dir>             : Top directory where to release the scripts. Defaults to
                                                         /home/cryo/docker/smurf/dev_sw/<slot_number>/<smurf2mce-base_version>.
  -h|--help                                            : Show this message.
```

The slot number is optional:
- If the slot number is specified, then the released docker will run in that particular slot number; the container can be started simply by running the `run.sh` script.
- On the other hand, if the slot number is not specified, then the docker can run against any slot number, the `run.sh` script will accept the slot number as an argument, in the following way: `run.sh -N <slot_number>`. In the default release directory the `<slot_number>` directory will be called `slotN`.

In the software development mode, if you take a look a the  generated `docker-compose.yml` file you will see that the `command:` line under the `smurf_server` section is commented out. The effect of this, is that when the container is started (by running the `run.sh` script) it will run by default a bash session, instead of starting the smurf2mce pyrogue server. Later one, after you have done your software modification, you can choose to re-enable this line to start the server by default.

When this container is run for the first time, the freshly cloned version of smurf2mce need to be compiled. In order to do that, start the container and attach to it (by running `docker attach smurf_server_s<N>`, where *N* depend on which slot you are using). Then go to the smurf2mce folder (`/usr/local/src/smurf2mce/mcetransmit`) and make a clean build:

```
rm -rf build
mkdir build
cd build
cmake ..
make
```

You can now start the server using the `start_server.sh` script with the appropriate parameters (you can run the command with the same arguments defined in the `docker-compose.yml` file for example).

You will need to compile the code every time you make changes to the C++ code. On the other hand, you don't need to compile when changing python code.

### Pysmurf application, in development mode

**Note**: This mode only supports pysmurf starting at version 4, including all its initial release candidates.

A pysmurf application in development mode, consist only on the pysmurf client application. It uses a local checkout of the pysmurf repository located in a folder called **pysmurf** in the release folder. The release script will checkout the specified version of pysmurf from the [pysmurf git repository](https://github.com/slaclab/pysmurf).

Pysmurf runs in the the [pysmurf-client docker](https://github.com/slaclab/pysmurf).

To release a pysmurf development application, use **type = pysmurf-dev**, with the following arguments:

```
release-docker.sh -t pysmurf-dev -p|--pysmurf_version <pysmurf_version>
                  [-o|--output-dir <output_dir>] [-l|--list-versions] [-h|--help]"

  -p|--pysmurf_version <pysmurf_version> : Version of the pysmurf docker image. Used as a base.
                                           image; pysmurf will be overwritten by the local copy.
  -o|--output-dir      <output_dir>      : Directory where to release the scripts. Defaults to
                                           /home/cryo/docker/pysmurf/<pysmurf_version>.
  -l|--list-versions                     : Print a list of available versions.
  -h|--help                              : Show this message.
```

If you make changes to the pysmurf repository and want to push them back to Github, you need to create a new branch (the reason for this is that when you checkout a tagged version, you will in  detached mode, i.e. no attach to any branch). In order to do that you can run the following commands (you can create the new branch even after committing changes):"
```
git checkout -b <new-branch-name>"
git push -set-upstream origin <new-branch-name>"
```

Replace `<new-branch-name>`, with an appropriate branch name. After you push all your changes to Github, you should open a PR to merge your changes into the master branch.

### Utility application

An utility application contains tools useful on SMuRF system.

It run in the [smurf-base docker](https://github.com/slaclab/smurf-base-docker).

To release an utility application, use **type = utils**, with the following arguments:

```
release-docker.sh -t utils -v|--version <smurf_base_version> [-o|--output-dir <output_dir>]
                           [-l|--list-versions] [-h|--help]

  -v|--version    <smurf-base_version> : Version of the smurf-base docker image.
  -o|--output-dir <output_dir>         : Directory where to release the scripts. Defaults to
                                         /home/cryo/docker/utils/<smurf-base_version>.
  -l|--list-versions                   : Print a list of available versions.
  -h|--help                            : Show this message.
```

### TPG IOC

A Timing Pattern Generator (TPG) IOC.

It runs in the [smurf-tpg-ioc docker](https://github.com/slaclab/smurf-tpg-ioc-docker).

To release a TPG IOCm use **type = tpg**, with the following arguments:

```
release-docker.sh -t tpg -v|--version <tpg_version> [-o|--output-dir <output_dir>]
                         [-l|--list-versions] [-h|--help]

  -v|--version    <tpg_version>   : Version of the smurf-tpg-ioc docker image.
  -o|--output-dir <output_dir>    : Directory where to release the scripts. Defaults to
                                    /home/cryo/docker/tpg/<tpg_version>.
  -l|--list-versions              : Print a list of available versions.
  -h|--help                       : Show this message.
```

### PCIe utility application

An application with utilities related to the SMuRF PCIe card.

It runs in the [smurf-pcie docker](https://github.com/slaclab/smurf-pcie-docker).

To release a PCIe utility application use **type = pcie**, with the following arguments:

```
release-docker.sh -t pcie -v|--version <pcie_version> [-o|--output-dir <output_dir>]
                          [-l|--list-versions] [-h|--help]

  -v|--version    <pcie_version> : Version of the smurf-pcie docker image.
  -o|--output-dir <output_dir>   : Directory where to release the scripts. Defaults to
                                   /home/cryo/docker/pcie/<pcie_version>.
  -l|--list-versions             : Print a list of available versions.
  -h|--help                      : Show this message.
```

### ATCA monitor application

A PyRogue-based application used to monitor an entire ATCA crate.

It runs the [smurf-atca-monitor docker](https://github.com/slaclab/smurf-atca-monitor).

To release an ATCA monitor application use **type = atca-monitor**, with the following arguments:

```
release-docker.sh -t atca-monitor -v|--version <atca-monitor_version> [-o|--output-dir <output_dir>]
                                  [-l|--list-versions] [-h|--help]

  -v|--version    <atca-monitor_version> : Version of the smurf-atca-monitor docker image.
  -o|--output-dir <output_dir>           : Directory where to release the scripts. Defaults to
                                           /home/cryo/docker/atca-monitor/<atca-monitor_version>.
  -l|--list-versions                     : Print a list of available versions.
  -h|--help                              : Show this message.
```





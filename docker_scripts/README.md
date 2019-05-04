# Scripts to release dockers systems

## Description

This scripts are used to release a set of files necessary to run SMuRF system based on dockers.

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
release-docker.sh -t|--type system -N|--slot <slot_number> -s|--smurf2mce-version <smurf2mce_version>
                  -p|--pysmurf_version <pysmurf_version> [-o|--output-dir <output_dir>] [-h|--help]

  -N|--slot              <slot_number>       : ATCA crate slot number.
  -s|--smurf2mce-version <smurf2mce_version> : Version of the smurf2mce docker image
  -p|--pysmurf_version   <pysmurf_version>   : Version of the pysmurf docker image
  -o|--output-dir        <output_dir>        : Top directory where to release the scripts. Defaults to
                                               /home/cryo/docker/smurf/<slot_number>/stable/<smurf2mce_version>
  -h|--help                                  : Show this message
```

### Full system, for Firmware development

A development system is formed by a SMuRF server and pysmurf. For firmware development systems, the SMuRF server contains the smurf2mce application, while the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [smur2mce-base docker](https://github.com/slaclab/smurf2mce-base-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a firmware development system, use **type = system-dev-fw**, with the following arguments:

```
release-docker.sh -t|--type system-dev-fw -N|--slot <slot_number> -s|--smurf2mce-base-version <smurf2mce-base_version>
                  -p|--pysmurf_version <pysmurf_version> [-o|--output-dir <output_dir>] [-h|--help]

  -N|--slot                   <slot_number>            : ATCA crate slot number.
  -s|--smurf2mce-base-version <smurf2mce-base_version> : Version of the smurf2mce-base docker image.
  -p|--pysmurf_version        <pysmurf_version>        : Version of the pysmurf docker image.
  -o|--output-dir             <output_dir>             : Top directory where to release the scripts. Defaults to
                                                         /home/cryo/docker/smurf/<slot_number>/dev_fw/<smurf2mce_base_version>
  -h|--help                                            : Show this message.
```

### Full system, for Software development

A development system is formed by a SMuRF server and pysmurf. For software development systems, the SMuRF server contains a smurf2mce application provided by the user in a folder called **smurf2mce** in the release folder. The release script will do a clone of the master branch of the [smurf2mce git repository](https://github.com/slaclab/smurf2mce). Also, the firmware files are provided by the user by adding them in a folder called **fw** in the release folder.

The server runs in the [smur2mce-base docker](https://github.com/slaclab/smurf2mce-base-docker), and pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a software development system, use **type = system-dev-sw**, with the following arguments:

```
release-docker.sh -t|--type system-dev-fw -N|--slot <slot_number> -s|--smurf2mce-base-version <smurf2mce-base_version>
                  -p|--pysmurf_version <pysmurf_version> [-o|--output-dir <output_dir>] [-h|--help]

  -N|--slot                   <slot_number>            : ATCA crate slot number.
  -s|--smurf2mce-base-version <smurf2mce-base_version> : Version of the smurf2mce-base docker image. Used as a base
                                                         image; smurf2mce will be overwritten by the local copy.
  -p|--pysmurf_version        <pysmurf_version>        : Version of the pysmurf docker image.
  -o|--output-dir             <output_dir>             : Top directory where to release the scripts. Defaults to
                                                         /home/cryo/docker/smurf/<slot_number>/dev_sw/<smurf2mce-base_version>
  -h|--help                                            : Show this message
```

### Pysmurf application, in development mode

A pysmurf application in development mode, consist only on pysmurf. It contains a pysmurf application provided by the user in a folder called **pysmurf** in the release folder. The release script will do a clone of the master branch of the [pysmurf git repository](https://github.com/slaclab/pysmurf).

Pysmurf runs in the the [pysmurf docker](https://github.com/slaclab/pysmurf-docker).

To release a pysmurf development application, use **type = pysmurf-dev**, with the following arguments:

```
release-docker.sh -t pysmurf-dev -p|--pysmurf_version <pysmurf_version>"
                  [-o|--output-dir <output_dir>] [-h|--help]"

  -p|--pysmurf_version <pysmurf_version> : Version of the pysmurf docker image. Used as a base
                                           image; pysmurf will be overwritten by the local copy.
  -o|--output-dir      <output_dir>      : Directory where to release the scripts. Defaults to
                                           /home/cryo/docker/pysmurf/dev
  -h|--help                              : Show this message.
```

### Utility application

A utility application contains tools useful on SMuRF system.

It run in the [smurf-base docker](https://github.com/slaclab/smurf-base-docker)

To release an utility application, use **type = utils**, with the following arguments:

```
release-docker.sh -t utils -v|--version <smurf_base_version> [-o|--output-dir <output_dir>] [-h|--help]"

  -v|--version    <smurf-base_version> : Version of the smurf-base docker image.
  -o|--output-dir <output_dir>         : Directory where to release the scripts. Defaults to
                                         /home/cryo/docker/utils/dev
  -h|--help                            : Show this message.
```

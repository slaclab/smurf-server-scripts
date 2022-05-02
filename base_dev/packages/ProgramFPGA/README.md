# Bash script to program the HPS FPGA image.

## Overview

The propose of this bash script is to automatize the procedure of loading a new image into your FPGA.

You just need to know:
- the **shelfmanager** name of the crate where your carrier is installed,
- in which **slot** number,
- the path to your **MCS** file (**MCS.GZ** files are also accepted).

The script will use by default the second stage boot method, but you can choose using the first stage boot method instead with option `-f|--fsb`.

## Dependencies

The script depends on the FirmwareLoader external package. Its location must defined your `PATH`.

## Script usage:

```
ProgramFPGA.bash -s|--shelfmanager shelfmanager_name -n|--slot slot_number -m|--mcs mcs_file [-f|--fsb] [-h|--help]
    -s|--shelfmanager shelfmaneger_name      : name of the crate's shelfmanager
    -n|--slot         slot_number            : logical slot number
    -m|--mcs          mcs_file               : path to the mcs file. Can be given in GZ format
    -f|--fsb                                 : use first stage boot (default to second stage boot)
    -h|--help                                : show this message
```

## Examples:

* Program a FPGA using the second stage boot method

```
ProgramFPGA.bash --shelfmanager <shelfmanager_name> --slot <slot_number> --mcs <mcs_file>
```

* Program a FPGA using the first stage boot method

```
ProgramFPGA.bash --shelfmanager <shelfmanager_name> --slot <slot_number> --mcs <mcs_file> --fsb
```

* Program a FPGA using a compressed MCS file (.gz)

```
ProgramFPGA.bash --shelfmanager <shelfmanager_name> --slot <slot_number< --mcs <mcs_file.gz>
```

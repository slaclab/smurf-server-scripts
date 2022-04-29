#!../../bin/rhel6-x86_64/tpg

## You may have to change tpg to something else
## everywhere it appears in this file

< envPaths


cd ${TOP}

## Register all support components
dbLoadDatabase("dbd/tpg.dbd")
tpg_registerRecordDeviceDriver(pdbbase)


# ====================================================================
# Setup some additional environment variables
# ====================================================================
# Setup environment variables
epicsEnvSet("ENGINEER","Kukhee Kim")
epicsEnvSet("LOCATION","LI00")
epicsEnvSet("IOC_PV", "SIOC:SMRF:TS01")
epicsEnvSet("IOC",    "sioc-smrf-ts01")

# tag log messages with IOC name
# How to escape the "ioctpg" as the PERL program
# will try to repplace it.
# So, uncomment the following and remove the backslash
#epicsEnvSet("EPICS\_IOC\_LOG_CLIENT_INET","${IOC}")

# ========================================================
# Support Large Arrays/Waveforms; Number in Bytes
# Please calculate the size of the largest waveform
# that you support in your IOC.  Do not just copy numbers
# from other apps.  This will only lead to an exhaustion
# of resources and problems with your IOC.
# The default maximum size for a channel access array is
# 16K bytes.
# ========================================================
epicsEnvSet("EPICS_CA_MAX_ARRAY_BYTES", "80000000")

# END: Additional environment variables
# ====================================================================

########################################################################
# BEGIN: Load the record databases
#######################################################################
# TPG driver DB
dbLoadRecords("db/tpg_smrf.db", "DEV=${PREFIX}")
#dbLoadRecords("db/crossbarCtrl.db", "DEV=${PREFIX},PORT=crossbar")

# BSA driver DB
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=PIDU,SECN=PIDU")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=PIDL,SECN=PIDL")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=TSU,SECN=TSU")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=TSL,SECN=TSL")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=RATES,SECN=RATES")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BEAMREQ,SECN=BEAMREQ")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BEAMNRG01,SECN=BEAMNRG01")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BEAMNRG23,SECN=BEAMNRG23")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=PHWAVELEN,SECN=PHWAVELEN")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=MPSSTAT,SECN=MPSSTAT")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=MPSCLASS01,SECN=MPSCLASS01")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=MPSCLASS23,SECN=MPSCLASS23")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSAINITL,SECN=BSAINITL")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSAINITU,SECN=BSAINITU")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSAACTL,SECN=BSAACTL")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSAACTU,SECN=BSAACTU")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSAAVGL,SECN=BSAAVGL")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSAAVGU,SECN=BSAAVGU")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSADONEL,SECN=BSADONEL")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=BSADONEU,SECN=BSADONEU")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQ01,SECN=CTRLSEQ01")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQ23,SECN=CTRLSEQ23")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQ45,SECN=CTRLSEQ45")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQ67,SECN=CTRLSEQ67")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQ89,SECN=CTRLSEQ89")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQAB,SECN=CTRLSEQAB")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQCD,SECN=CTRLSEQCD")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=CTRLSEQEF,SECN=CTRLSEQEF")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=ACVADCA,SECN=ACVADCA")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=ACVADCB,SECN=ACVADCB")
#dbLoadRecords("db/bsa.db", "DEV=TPG:SMRF:1,PORT=bsaPort,BSAKEY=ACVADCC,SECN=ACVADCC")


#
# =====================================================================
# Load iocAdmin databases to support IOC Health and monitoring
# =====================================================================
dbLoadRecords("db/iocAdminSoft.db","IOC=${IOC_PV}")
dbLoadRecords("db/iocAdminScanMon.db","IOC=${IOC_PV}")

# The following database is a result of a python parser
# which looks at RELEASE_SITE and RELEASE to discover
# versions of software your IOC is referencing
# The python parser is part of iocAdmin
dbLoadRecords("db/iocRelease.db","IOC=${IOC_PV}")

# =====================================================================
# Load database for autosave status
# =====================================================================
dbLoadRecords("db/save_restoreStatus.db", "P=${IOC_PV}:")


# =====================================================================
#Load Additional databases:
# =====================================================================
## Load record instances
#dbLoadRecords("db/dbExample.db","user=khkimHost")

# END: Loading the record databases
########################################################################

# =================================
# Load YAML
# =================================
#cd yamlConfig_0x000C
cd yamlConfig_0x0000000E-20170420000855
cpswLoadYamlFile("000TopLevel.yaml", "NetIODev", "", "${FPGA_IP}")

# ===================================
# Load ADC configuration from YAML file
# ====================================
cd ${TOP}
cpswLoadConfigFile("config/configDump.yaml", "mmio/AmcCarrierTimingGenerator/ApplicationCore", "")

cd ${TOP}

# ====================================
# Setup TPG Driver
# ====================================
#tpgAsynDriverConfigure("tpgPort", "192.168.2.10")
#tpgAsynDriverConfigure("tpgPort", "10.0.3.102")
# TPG driver for yaml
tpgAsynDriverSetKind("SOUTH_POLE")
tpgAsynDriverConfigure("tpgPort")
crossbarControlAsynDriverConfigure("crossbar", "mmio/AmcCarrierTimingGenerator/AmcCarrierCore/AxiSy56040")

# ====================================
# Setup BSA Driver
# ====================================
# add BSA PVs
#addBsa("PIDL",       "uint32")
#addBsa("PIDU",       "uint32")
#addBsa("TSL",        "uint32")
#addBsa("TSU",        "uint32")
#addBsa("RATES",      "uint32")
#addBsa("BEAMREQ",    "uint32")
#addBsa("BEAMNRG01",  "uint32")
#addBsa("BEAMNRG23",  "uint32")
#addBsa("PHWAVELEN",  "uint32")
#addBsa("MPSSTAT",    "uint32")
#addBsa("MPSCLASS01", "uint32")
#addBsa("MPSCLASS23", "uint32")
#addBsa("BSAINITL",   "uint32")
#addBsa("BSAINITU",   "uint32")
#addBsa("BSAACTL",    "uint32")
#addBsa("BSAACTU",    "uint32")
#addBsa("BSAAVGL",    "uint32")
#addBsa("BSAAVGU",    "uint32")
#addBsa("BSADONEL",   "uint32")
#addBsa("BSADONEU",   "uint32")
#addBsa("CTRLSEQ01",  "uint32")
#addBsa("CTRLSEQ23",  "uint32")
#addBsa("CTRLSEQ45",  "uint32")
#addBsa("CTRLSEQ67",  "uint32")
#addBsa("CTRLSEQ89",  "uint32")
#addBsa("CTRLSEQAB",  "uint32")
#addBsa("CTRLSEQCD",  "uint32")
#addBsa("CTRLSEQEF",  "uint32")
#addBsa("ACVADCA",    "uint32")
#addBsa("ACVADCB",    "uint32")
#addBsa("ACVADCC",    "uint32")


# check up the BSA PVs
listBsa()
#
# Initialize the BSA driver
#
#bsaAsynDriverConfigure("bsaPort", "10.0.3.102")
#bsaAsynDriverConfigure("bsaPort", "slave")
# BSA driver for yaml
#bsaAsynDriverConfigure("bsaPort", "mmio/AmcCarrierTimingGenerator/AmcCarrierCore/AmcCarrierBsa","strm/AmcCarrierDRAM/dram")

# epicsThreadSleep(5.)

# =====================================================================
## Begin: Setup autosave/restore
# =====================================================================

# ============================================================
# If all PVs don't connect continue anyway
# ============================================================
save_restoreSet_IncompleteSetsOk(1)

# ============================================================
# created save/restore backup files with date string
# useful for recovery.
# ============================================================
save_restoreSet_DatedBackupFiles(1)

# ============================================================
# Where to find the list of PVs to save
# ============================================================
#set_requestfile_path("${IOC_DATA}/${IOC}/autosave-req")
set_requestfile_path("${IOC_DATA}/sioc-smrf-ts01", "autosave-req")

# ============================================================
# Where to write the save files that will be used to restore
# ============================================================
#set_savefile_path("${IOC_DATA}/${IOC}/autosave")
set_savefile_path("${IOC_DATA}/sioc-smrf-ts01", "autosave")

# ============================================================
# Prefix that is use to update save/restore status database
# records
# ============================================================
save_restoreSet_status_prefix("${IOC}:")

## Restore datasets
set_pass0_restoreFile("info_positions.sav")
set_pass1_restoreFile("info_positions.sav"
set_pass0_restoreFile("info_settings.sav")
set_pass1_restoreFile("info_settings.sav")

# =====================================================================
# End: Setup autosave/restore
# =====================================================================

# =====================================================================
# Channel Access Security:
# This is required if you use caPutLog.
# Set access security file
# Load common LCLS Access Configuration File
< ${ACF_INIT}

iocInit()

# =====================================================
# crossbar setup
# =====================================================
epicsThreadSleep(1.)
crossbarControl("RTM_OUT0", "FPGA")
crossbarControl("FPGA",     "FPGA")
crossbarControl("BP",       "FPGA")
crossbarControl("RTM_OUT1", "FPGA")

# =====================================================
# Turn on caPutLogging:
# Log values only on change to the iocLogServer:
caPutLogInit("${EPICS_CA_PUT_LOG_ADDR}")
caPutLogShow(2)
# =====================================================

## Start any sequence programs
#seq sncExample,"user=khkimHost"

## Start autosave process:
cd ("${IOC_DATA}/sioc-smrf-ts01/autosave-req")
makeAutosaveFiles()
create_monitor_set("info_positions.req", 30, "")
create_monitor_set("info_settings.req",30,"")


# ======================================================
# Dump ADC configuration into YAML file
# : ioc engineer can uncomment the followings on demenad
# ======================================================
cd ("${IOC_DATA}/sioc-smrf-ts01/yamlConfig")
#cpswDumpConfigFile("dump.yaml", "mmio/AmcCarrierTimingGenerator/ApplicationCore/AmcGenericAdcDacCore" , "")
#cpswDumpConfigFile("dump.yaml", "mmio/AmcCarrierTimingGenerator/ApplicationCore", "")


TOP=../..

include $(TOP)/configure/CONFIG

USR_CXXFLAGS += -std=c++0x
USR_CXXFLAGS += -DHAVE_YAML
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#========================================
INCLUDES += -I$(TPG_INCLUDE)
INCLUDES += -I$(BSA_INCLUDE)
INCLUDES += -I$(YAML_INCLUDE)
INCLUDES += -I$(BOOST_INCLUDE)

## this part is just for yaml loader driver
INCLUDES += -I$(CPSW_FRAMEWORK_INCLUDE)
#LIBS     += -L $(TPG_LIB)

# ================================================
# Build the IOC application
# ================================================
# This will attempt to build an IOC application 
# for every target including the host computer.
PROD_IOC = tpg

# Use the following for RTEMS Only IOCs
#PROD_IOC_RTEMS = tpg

# tpg.dbd will be created and installed
DBD += tpg.dbd

# tpg.dbd will be made up from these files:
tpg_DBD += base.dbd
tpg_DBD += devIocStats.dbd
tpg_DBD += asSupport.dbd
tpg_DBD += caPutLog.dbd
tpg_DBD += $(CEXP_DBDS)

# ================================================================================
# The system command will be mainly used by linux hosted IOCs
# Very useful for changing kernel thread priorities for kernel drivers
# ================================================================================
tpg_DBD += system.dbd
tpg_DBD += asyn.dbd
tpg_DBD += crossbarControl.dbd
tpg_DBD += tpgAsynDriver.dbd
tpg_DBD += bsaAsynDriver.dbd
tpg_DBD += yamlLoader.dbd

# If you don't have an EVR comment the following two lines:
#tpg_DBD += evrSupport.dbd
#tpg_DBD += devMrfEr.dbd

# ======================================================================
# <name>_registerRecordDeviceDriver.cpp will be created from <name>.dbd
tpg_SRCS += tpg_registerRecordDeviceDriver.cpp
tpg_SRCS += tpgAsynDriver.cpp
tpg_SRCS += tpgSequencer.cpp
tpg_SRCS += tpgBsaEdef.cpp
tpg_SRCS += tpgRmEdef.cpp
tpg_SRCS += tpgBsaPoll.cpp
tpg_SRCS += tpgDiagWf.cpp



# ===========================================================
# bsaDriver and yamlLoader have been separated out to epics modules
# after testing these lines should be be revmoved
# ===========================================================
# BSA module will be turned to a separated module.
#tpg_SRCS += bsaAsynDriver.cpp

# YAML loader module will be turned to a separate module.

#tpg_SRCS += yamlLoader.cpp
# ===========================================================

tpg_SRCS_DEFAULT += tpgMain.cpp

tpg_SRCS_vxWorks += -nil-

# ========================================================================
# ========================================================================
# Add locally compiled object code
# For example, subroutines
# ========================================================================
# tpg_SRCS += file1.c
# tpg_SRCS += file2.c

# =====================================================
# Link in the code from other libraries
# =====================================================
#
#
#

tpg_LIBS += asyn
tpg_DIR = $(TPG_LIB)
tpg_LIBS += tpg
tpg_LIBS += bsaDriver
tpg_LIBS += crossbarControl
bsa_DIR = $(BSA_LIB)
tpg_LIBS += bsa
cpsw_DIR = $(CPSW_FRAMEWORK_LIB)
tpg_LIBS += cpsw

yaml-cpp_DIR  += $(YAML_LIB)
tpg_LIBS += yaml-cpp
tpg_LIBS += yamlLoader

#tpg_LIBS += asyn

# Needed to link in iocAdmin support
tpg_LIBS += devIocStats

# Needed to link in autosave support
tpg_LIBS += autosave

# Needed to link caPutLog support
tpg_LIBS += caPutLog

# Needed to link cexpsh() support
tpg_LIBS += $(CEXP_LIBS)




# =============================================
# Begin to link in the EVR support for
# RTEMS, linux, and linuxRT
# If you don't have an EVR, you can comment out 
# the lines below.
# =============================================
# tpg_LIBS += evrSupport
# tpg_LIBS += devMrfEr

ifneq ($(T_A),linuxRT-x86)
  ifneq ($(T_A),linuxRT-x86_64)
   ifneq ($(T_A),linuxRT_glibc-x86_64)
    ifneq ($(T_A),linux-x86)
      ifneq ($(T_A),linux-x86_64)
#       tpg_LIBS += mrfVme64x
      endif
    endif
  endif
 endif
endif

 ifeq ($(T_A),linuxRT-x86)
#  tpg_LIBS += drvMrf
 endif

 ifeq ($(T_A),linuxRT-x86_64)
#  tpg_LIBS += drvMrf
 endif
 
 ifeq ($(T_A),linuxRT_glibc-x86_64)
#  tpg_LIBS += drvMrf
 endif

 ifeq ($(T_A),linux-x86)
#  tpg_LIBS += drvMrf
 endif

 ifeq ($(T_A),linux-x86_64)
#  tpg_LIBS += drvMrf
 endif
# =====================================================
# END EVR libraries
# =====================================================

# NOTE: To build SNL programs, SNCSEQ must be defined
# in the <top>/configure/RELEASE file

ifneq ($(SNCSEQ),)
    # This builds sncExample as a component of tpg
    tpg_SNCFLAGS += +r
    tpg_DBD += sncExample.dbd
    tpg_SRCS += sncExample.stt
    tpg_LIBS += seq pv

    # The following builds sncProgram as a standalone application
  ifneq ($(T_A),linuxRT-x86)
    PROD_HOST += sncProgram
    sncProgram_SNCFLAGS += +m
    sncProgram_SRCS += sncProgram.st
    sncProgram_LIBS += seq pv
    sncProgram_LIBS += $(EPICS_BASE_HOST_LIBS)
  endif
endif

tpg_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE


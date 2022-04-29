TOP=../..
include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE

#----------------------------------------------------
#  Optimization of db files using dbst (DEFAULT: NO)
#DB_OPT = YES

#----------------------------------------------------
# Create and install (or just install)
# databases, templates, substitutions like this
DB += dbExample.db
DB += dbExample1.db
DB += dbExample2.db
DB += userHost.substitutions
#
# TPG ioc application
#
DB += tpgAsynDriver.db
DB += tpgAsynDriver_smrf.db
DB += tpgFaultHistory.db
DB += tpgEngine.db
DB += tpgAllowEngine.db
DB += tpgBeamEngine.db
DB += tpgExptEngine.db
DB += tpgSeqList.db
DB += tpgBsaEdef.db
DB += tpgBsaEdef_smrf.db
DB += tpgRmEdef.db
DB += tpgRmEdef_smrf.db
DB += tpgDiag.db
DB += tpgMpsCtrlList.db
DB += tpgSeq.substitutions
DB += tpgMpsCtrl.substitutions
DB += tpg.substitutions
DB += tpg_smrf.substitutions
DB += tpgSeq.db
DB += tpgMpsCtrl.db
DB += tpg.db
DB += tpg_smrf.db

#
#  BSA module will be a separated module
#
#DB += bsaHst.db
#DB += bsa.substitutions
#DB += bsa.db

DB_INSTALLS += $(BSADRIVER)/db/bsa.db
DB_INSTALLS += $(CROSSBARCONTROL)/db/crossbarCtrl.db

# ========================================
# Install timing/event related databases
# ========================================
#DB_INSTALLS += $(EVENT)/db/EvrPmc.db
#DB_INSTALLS += $(EVENT)/db/EvrPci.db
#DB_INSTALLS += $(EVENT)/db/Pattern.db
#DB_INSTALLS += $(EVENT)/db/PCI-trig.db
#DB_INSTALLS += $(EVENT)/db/PMC-trig.db
#DB_INSTALLS += $(EVENT)/db/VME-trig.db
#DB_INSTALLS += $(EVENT)/db/VME-TTB-trig.db
#DB_INSTALLS += $(EVENT)/db/Bsa.db
#
# For event module BSA Test
#DB += bsaSimulator.db



# Install Common databases needed by All IOCs
# ========================================================
# Install databases from iocAdmin package
# These databases support IOC Health and Monitoring
# ========================================================
# HardIOC using RTEMS
DB_INSTALLS += $(IOCADMIN)/db/iocAdminRTEMS.db
# SoftIOC
DB_INSTALLS += $(IOCADMIN)/db/iocAdminSoft.db

DB_INSTALLS += $(IOCADMIN)/db/iocAdminScanMon.db
DB_INSTALLS += $(IOCADMIN)/db/iocScanMonSum.db
DB_INSTALLS += $(IOCADMIN)/db/iocScanMon.db
IOCRELEASE_DB += iocRelease.db

# Install Database to support reading the status of the autosave package:
DB_INSTALLS += $(AUTOSAVE)/db/save_restoreStatus.db

# =======================================================================

#----------------------------------------------------
# If <anyname>.db template is not named <anyname>*.template add
# <anyname>_TEMPLATE = <templatename>

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE


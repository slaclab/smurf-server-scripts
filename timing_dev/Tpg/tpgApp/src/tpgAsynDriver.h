#ifndef TPG_ASYN_DRIVER_H
#define TPG_ASYN_DRIVER_H

#include <ellLib.h>
#include <asynPortDriver.h>
#include <epicsEvent.h>
#include <epicsTypes.h>
#include <epicsTime.h>

#include "tpgSequencer.h"
#include "tpgBsaEdef.h"
#include "tpgBsaPoll.h"
#include "tpgRmEdef.h"
#include "tpg_cpsw.hh"

#ifdef HAVE_YAML
#include "tpg_yaml.hh"
#endif /* HAVE_YAML */


class tpgAsynDriver:asynPortDriver {
public:
    tpgAsynDriver(const char *portName, const char *ipString);
    ~tpgAsynDriver();
    asynStatus writeInt32(asynUser *pasynUser, epicsInt32 value);
    asynStatus writeInt32Array(asynUser *pasynUser, epicsInt32 *value, size_t nElements);
    asynStatus writeInt16Array(asynUser *pasynUser, epicsInt16 *value, size_t nElements);
    
    int setKind(int i);
    int report(int i);
    int clockStateMachine(void);          // state machine to keep wall clock time
    int dump(void);                       // status dump for dbior report command
    int digiWfGetBuff(unsigned);
    int diagWfProcess(void);
    int getMpsStatus(void);
    int irqPolling(void);
    int softPolling(void);
    int bsaPolling(void);
    int rateMeasurePolling(void);
    int diagnosticsPolling(void);
    int getPulseID(void);
    int setPulseID(void);
    int setPulseID(uint64_t offset);
    int getTimeStamp(void);
    int setTimeStamp(void);
    int getTimeSkew(void);
    int getFaultBuffer(void);
    int schedReset(void);

    int getDiags(void);
    
    int updateBsaProgress(unsigned index, unsigned avgCnt, unsigned acqCnt);
    int setbsaCtrlFlag(unsigned index, unsigned flag);
    int setdiagCtrlFlag(unsigned flag);
    BsaPoll* getBsaPoll(void) { return pBsaPoll; };
    
    void *pBsaBridge;
    
    int intervalCallback(void); 

private:

#ifndef HAVE_YAML
    TPGen::TPGCpsw *pTpg;
#else /* HAVE_YAML */
    TPGen::TPGYaml *pTpg;
#endif  /*HAVE_YAML */
    
    BsaPoll     *pBsaPoll;
    
    unsigned    fwVersion;
    unsigned    nBeamEngines;
    unsigned    nAllowEngines;
    unsigned    nExptEngines;
    unsigned    nArraysBSA;
    unsigned    nRateCounters;
    unsigned    seqAddrWidth;
    unsigned    fifoAddrWidth;
    
    unsigned    diagWfEngine;
    unsigned    diagWf_flag;
    unsigned    diagWf_instr_offset;

    uint64_t    pulseID;
    uint32_t    pulseID_U;
    uint32_t    pulseID_L;
    
    uint64_t    save_pulseID;
    uint32_t    save_pulseID_U;
    uint32_t    save_pulseID_L;

    epicsTimeStamp   timeStamp;
    unsigned    sec;
    unsigned    nSec;
    
    enum {
        lcls2,
        south_pole
    } tpg_kind;

   std::vector <ProgSequencer *> engines; 
   std::vector <BsaEdef *> bsaEdefs;
   std::vector <RmEdef *> rmEdefs; 


    


protected:

//
//  parameter section for asynPortDriver
//
    int firstTpgParam;
#define FIRST_TPG_PARAM  firstTpgParam

    // constant section
    int p_ipAddress;           /* asynOctet, ro */
    int p_fwVersion;           /* asynInt32, ro */
    int p_nAllowEngines;       /* asynInt32, ro */
    int p_nBeamEngines;        /* asynInt32, ro */
    int p_nExptEngines;        /* asynInt32, ro */
    int p_nArraysBSA;          /* asynInt32, ro */
    int p_seqAddrWidth;        /* asynInt32, ro */
    int p_fifoAddrWidth;       /* asynInt32, ro */
 
    // dynamic parameter
    int p_baseDivisor;         /* asynInt32, wo */
    int p_acDelay;             /* asynInt32, wo */
    int p_fixedDivisors;       /* asynInt32Array, rw */
    int p_acDivisors;          /* asynInt32Array, rw */
    int p_energy;              /* asynInt32Array, rw */
    int p_reloadDivisors;      /* asynInt32, rw */
    int p_forceResync;         /* asynInt32, rw */
    int p_setPulseID;          /* asynInt32, rw */
    int p_manualFault;         /* asynInt32, rw */
    int p_clearFaultBuffer;    /* asynInt32, rw */

    int p_pulseID_U;           /* asynInt32, rw */
    int p_pulseID_L;           /* asynInt32, rw */
    int p_pulseID_offset;      /* asynInt32, wo */
    
    int p_savePulseID_U;       /* asynInt32, rw */
    int p_savePulseID_L;       /* asynInt32, rw */

    int p_sec;                 /* asynInt32, rw */
    int p_nSec;                /* asynInt32, rw */
    int p_timeSkew;            /* asynFloat64, ro */
    int p_timeState;           /* asynInt32, ro */
    int p_clockInterval;       /* asynFloat64, ro */
    
    int p_timestampString;     /* asynOctet, ro */

    int p_waveform;             /* asynInt32Array, rw, for testing */


    // 
    // History buffer parameter, 4 instances
    //
    struct {
        int manualLatch;        /* asynInt32, ro */
        int bcsLatch;           /* asynInt32, ro */
        int mpsLatch;           /* asynInt32, ro */
        int tag;                /* asynInt32, ro */
        int mpsTag;             /* asynInt32, ro */
        int clear;              /* asynInt32, rw */
    } p_faultBuffer[4];


   struct {
        int numberEngine;      /* asynInt32, rw */
        int requiredMask;      /* asynInt32, rw */
        int destination;       /* asynInt32, rw */
        int descEngine;        /* asynOctet, rw */
        int descInstrSet;      /* asynOctet, rw */
        int wfInstruction;     /* asynInt32Array, rw */
        int wfInstructionSet;  /* asynInt16Array, rw */
        int counterInstruction;/* asynInt32, ro */
        int insertInstrSet;    /* asynInt32, wo */
        int cancelInstrSet;    /* asynInt32, wo */

        struct {
            int idxSeq;        /* asynInt32, ro */
            int descSeq;       /* asynint32, ro */
        } seqList[64];

        int idxSeqRemove;      /* asynInt32, wo */
        int seqRemove;         /* asynInt32, wo */

        int idxSeqReset;       /* asynInt32, wo */
        int jumpSeqReset;      /* asynInt32, wo */
        int schedReset;        /* asynInt32, wo */
        int schedResetFlag;    /* asynInt32, ro */
        int promptReset;       /* asynInt32, wo */
        
        int requestRate;       /* asynInt32, ro */
        
        
        // Just for MPS allow table engine
        // Beam Engine and Exp Engine do not use the followings
        struct {
            int idxSeq;        /* asynInt32, wo */
            int jumpAddr;      /* asynInt32, wo */
            int powerClass;    /* asynInt32, wo */
        } mpsJumpControl[16];
        
        int mpsStLatch;        /* asynInt32, ro */
        int mpsStState;        /* asynInt32, ro */
        
        int setMpsState;       /* asynInt32, wo */
        
        int dropMpsState;      /* asynInt32, ro */
        
    } p_sequencer[32+32+32];   // number of engine is not clear yet. just put some safety margine  


    struct {
        int bsaEdefIndex;      /* asynInt32, ro */
        int bsaNtoAvg;         /* asynInt32, rw */
        int bsaNtoAcq;         /* asynInt32, rw */
        int bsaRateMode;       /* asynInt32, rw */
        int bsaExpSeq;         /* asynInt32, rw */
        int bsaFixedRate;      /* asynInt32, rw */
        int bsaACRate;         /* asynInt32, rw */
        int bsaTimeslotMask;   /* asynInt32, rw */
        int bsaExpSeqBit;      /* asynInt32, rw */
        int bsaDestMode;       /* asynInt32, rw */
        int bsaDestMask;       /* asynInt32, rw */
        int destMask;          /* asynInt32, ro */
        int bsaStart;          /* asynInt32, rw */
        
        int bsaAvgCnt;         /* asynInt32, ro */
        int bsaAcqCnt;         /* asynInt32, ro */
        int bsaMeasSevr;       /* asynInt32, rw */
        
        int bsaCtrlFlag;       /* asynInt32, ro */
    } p_bsaEdef[64];
    
    int p_bsaNinProgress;      /* asynInt32, ro */
    
    
    struct {
        int rmIndex;           /* asynInt32, ro */
        int rmDesc;            /* asynOcete, rw */
        int rmRateMode;        /* asynInt32, rw */
        int rmExpSeq;          /* asynInt32, rw */
        int rmFixedRate;       /* asynInt32, rw */
        int rmACRate;          /* asynInt32, rw */
        int rmTimeslotMask;    /* asynInt32, rw */
        int rmExpSeqBit;       /* asynInt32, rw */
        int rmDestMode;        /* asynInt32, rw */
        int rmDestMask;        /* asynInt32, rw */
        
        int rmCounter;         /* asynInt32, ro */
        int rmRate;            /* asynFloat64, ro */
        
        int rmCtrl;            /* asynInt32, rw */
    } p_rmEdef[25];     // rate measurement counter
    
    int p_rmSoftJitter;    // software polling jitter
    
    int p_diagWfEng;          /* asynInt32, rw */
    int p_diagWfEngIdx;       /* asynInt32, rw */
    int p_diagWfStart;        /* asynInt32, rw */
    int p_diagWfCtrlFlag;     /* asynInt32, ro */
    int p_diagWfName;         /* asynOctet, ro */
    int p_diagWfLength;       /* asynInt32, ro */
    int p_diagWfStartAddr;    /* asynInt32, ro */
    int p_diagWfEndAddr;      /* asynInt32, ro */
    int p_diagWfNxtAddr;      /* asynInt32, ro */
    
    int p_diagWfClk;          /* asynInt32Array, ro */
    int p_diagWfClkDelta;     /* asynInt32Array, ro */
    int p_diagWfInstr;        /* asynInt16Array, ro */
    int p_diagWfInstrRAddr;   /* asynInt16Array, ro */ 
    int p_diagWfBrCnt0;       /* asynInt16Array, ro */
    int p_diagWfBrCnt1;       /* asynInt16Array, ro */
    int p_diagWfBrCnt2;       /* asynInt16Array, ro */
    int p_diagWfBrCnt3;       /* asynInt16Array, ro */


    int p_countPLL;           /* asynInt32, ro */
    int p_count186M;          /* asynInt32, ro */
    int p_countSyncE;         /* asynInt32, ro */
    int p_countBRT;           /* asynInt32, ro */
    int p_countIntv;          /* asynInt32, ro */
    int p_countTrig[12];      /* asynInt32, ro */
    int p_progCounter[8];       /* asynInt32, ro */

    int p_countTxClk;         /* asynInt32, ro */
    int p_deltaTxClk;         /* asynInt32, ro */
    int p_rateTxClk;          /* asynFloat64, ro */


    int p_mpsDiag_PhyReadyRx;        /* asynInt32, ro */
    int p_mpsDiag_PhyReadyTx;        /* asynInt32, ro */
    int p_mpsDiag_LocalLinkReady;    /* aysnInt32, ro */
    int p_mpsDiag_RemoteLinkReady;   /* asynInt32, ro */
    int p_mpsDiag_RxClockFreq;       /* asynInt32, ro */
    int p_mpsDiag_TxClockFreq;       /* asynInt32, ro */
    
    int lastTpgParam;
#define LAST_TPG_PARAM   lastTpgParam
    
};

#define NUM_TPG_DET_PARAMS ((int)(&LAST_TPG_PARAM - &FIRST_TPG_PARAM -1))

// constant section
#define ipAddressString      "ipAddress"
#define fwVersionString      "fwVersion"
#define nAllowEnginesString  "nAllowEngines"
#define nBeamEnginesString   "nBeamEngines"
#define nExptEnginesString   "nExptEngines"
#define nArraysBSAString     "nArraysBSA"
#define seqAddrWidthString   "seqAddrWidth"
#define fifoAddrWidthString  "fifoAddrWidth"


#define baseDivisorString    "baseDivisor"            
#define acDelayString        "acDelay"
#define fixedDivisorsString  "fixedDivisors"
#define acDivisorsString     "acDivisors"
#define energyString         "energy"
#define reloadDivisorsString "reloadDivisors"
#define forceResyncString    "forceResync"
#define setPulseIDString     "setPulseID"
#define manualFaultString    "manualFault"
#define clearFaultBufferString "clearFaultBuffer"

#define pulseID_UString       "pulseID_U"
#define pulseID_LString       "pulseID_L"
#define pulseID_offsetString  "pulseID_offset"

#define savePulseID_UString   "savePulseID_U"
#define savePulseID_LString   "savePulseID_L"

#define secString             "second"
#define nSecString            "nanoSecond"
#define timeSkewString        "timeSkew"
#define timeStateString       "timeState"
#define timestampString       "timestamp"
#define clockIntervalString   "clockInterval"


//
// History Buffer String, will be generated 4 instances dynamically 
//
#define faultBuffer_manualLatchString   "fltBuff_mLatch%d"
#define faultBuffer_bcsLatchString      "fltBuff_bcsLatch%d"
#define faultBuffer_mpsLatchString      "fltBuff_mpsLatch%d"
#define faultBuffer_tagString           "fltBuff_tag%d"
#define faultBuffer_mpsTagString        "fltBuff_mpsTag%d"
#define faultBuffer_clearString         "fltBuff_clear%d"
//
// Sequencer Engines
//

#define numberEngineString              "engine%d_number"
#define requiredMaskString              "engine%d_requiredMask"
#define destinationString               "engine%d_destination"
#define descEngineString                "engine%d_descEngine"
#define descInstrSetString              "engine%d_descInstrSet"
#define wfInstructionString             "engine%d_wfInstruction"
#define wfInstructionSetString          "engine%d_wfInstructionSet"
#define counterInstructionString        "engine%d_counterInstruction"
#define insertInstrSetString            "engine%d_insertInstrSet"
#define cancelInstrSetString            "engine%d_cancelInstrSet"

#define idxSeqRemoveString              "engine%d_idxSeqRemove"
#define seqRemoveString                 "engine%d_seqRemove"

#define idxSeqResetString               "engine%d_idxSeqReset"
#define jumpSeqResetString              "engine%d_jumpSeqReset"
#define schedResetString                "engine%d_schedReset"
#define schedResetFlagString            "engine%d_schedResetFlag"
#define promptResetString               "engine%d_promptReset"

#define requestRateString               "engine%d_requestRate"

// 
// Sequencer Instruction Set
//

#define idxSeqString       "engine%d_list%d_idxSeq"
#define descSeqString      "engine%d_list%d_descSeq"

//
//  MPS jump control
#define mpsJumpIdxSeqString      "engine%d_mpsJump%d_idxSeq"
#define mpsJumpJumpAddrString    "engine%d_mpsJump%d_jumpAddr"
#define mpsJumpPowerClassString  "engine%d_mpsJump%d_powerClass"
//
// readout MPS State Status
#define getMpsStLatchString      "engine%d_getMpsStLatch"
#define getMpsStStateString      "engine%d_getMpsStState"

// set MPS state
#define setMpsStateString        "engine%d_setMpsState"

// drop MPS state
#define dropMpsStateString       "engine%d_dropMpsState"

//
// BSA event defintition, BSAedef
//

#define bsaEdefIndexString    "bsa%d_edefIndex"
#define bsaDescString         "bsa%d_desc"
#define bsaNtoAvgString       "bsa%d_NtoAvg"
#define bsaNtoAcqString       "bsa%d_NtoAcq"
#define bsaRateModeString     "bsa%d_rateMode"
#define bsaExpSeqString       "bsa%d_expSeq"
#define bsaFixedRateString    "bsa%d_fixedRate"
#define bsaACRateString       "bsa%d_acRate"
#define bsaTimeslotMaskString "bsa%d_timeslotMask"
#define bsaExpSeqBitString    "bsa%d_expSeqBit"
#define bsaDestModeString     "bsa%d_destMode"
#define bsaDestMaskString     "bsa%d_destMask"
#define bsaInternalDeskMaskString "bsa%d_intDestMask"
#define bsaStartString        "bsa%d_start"
#define bsaAvgCntString       "bsa%d_avgCnt"
#define bsaAcqCntString       "bsa%d_acqCnt"
#define bsaMeasSevrString     "bsa%d_measSevr"
#define bsaCtrlFlagString     "bsa%d_ctrlFlag"

#define bsaNinProgressString  "bsa_NinProgress"


//
//   Rate Meausrement (RM) definitions
//

#define rateMeasureIndexString        "rm%d_index"
#define rateMeasureDescString         "rm%d_desc"
#define rateMeasureRateModeString     "rm%d_rateMode"
#define rateMeasureExpSeqString       "rm%d_expSeq"
#define rateMeasureFixedRateString    "rm%d_fixedRate"
#define rateMeasureACRateString       "rm%d_acRate"
#define rateMeasureTimeslotMaskString "rm%d_timeslotMask"
#define rateMeasureExpSeqBitString    "rm%d_expSeqBit"
#define rateMeasureDestModeString     "rm%d_destMode"
#define rateMeasureDestMaskString     "rm%d_destMask"
#define rateMeasureCounterString      "rm%d_counter"
#define rateMeasureRateString         "rm%d_rate"
#define rateMeasureCtrlString         "rm%d_ctrl"
#define rateMeasureSoftJitterString   "rm_softJitter"

// Diagnostics Waveform for Sequence Engine
#define diagWfEngString             "dw_eng"
#define diagWfEngIdxString          "dw_engIndex"
#define diagWfNameString            "dw_name"
#define diagWfStartString           "dw_start"
#define diagWfCtrlFlagString        "dw_ctrlFlag"
#define diagWfLengthString          "dw_length"
#define diagWfStartAddrString       "dw_startAddr"
#define diagWfEndAddrString         "dw_endAddr"
#define diagWfNxtAddrString         "dw_nxtAddr"

#define diagWfClkString             "dw_clock"
#define diagWfClkDeltaString        "dw_clock_delta"
#define diagWfInstrString           "dw_instruction"
#define diagWfInstrRAddrString      "dw_instruction_raddr"
#define diagWfBrCnt0String          "dw_branchCnt0"
#define diagWfBrCnt1String          "dw_branchCnt1"
#define diagWfBrCnt2String          "dw_branchCnt2"
#define diagWfBrCnt3String          "dw_branchCnt3"


// TPG diagnostic PVs
#define countPLLString              "countPLL"
#define count186MString             "count186M"
#define countSyncEString            "countSyncE"
#define countIntvString             "countIntv"
#define countBRTString              "countBRT"
#define countTrigString             "countTrig%d"
#define progCounterString           "progCounter%d"

#define countTxClkString            "countTxClk"
#define deltaTxClkString            "deltaTxClk"
#define rateTxClkString             "rateTxClk"


// MPS link/communication diagnostics
#define mpsDiag_PhyReadyRxString        "mpsDiag_PhyReadyRx"
#define mpsDiag_PhyReadyTxString        "mpsDiag_PhyReadyTx"
#define mpsDiag_LocalLinkReadyString    "mpsDiag_LocalLinkReady"
#define mpsDiag_RemoteLinkReadyString   "mpsDiag_RemoteLinkReady"
#define mpsDiag_RxClockFreqString       "mpsDiag_RxClockFreq"
#define mpsDiag_TxClockFreqString       "mpsDiag_TxClockFreq"


#define waveformString        "waveform"




#endif /* TPG_ASYN_DRIVER_H */

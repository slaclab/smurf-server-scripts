#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <math.h>
#include <time.h>

#include <sys/types.h>
#include <sys/stat.h>

#include <ellLib.h>
#include <epicsTypes.h>
#include <epicsTime.h>
#include <epicsThread.h>
#include <epicsString.h>
#include <epicsTimer.h>
#include <epicsMutex.h>
#include <epicsEvent.h>
#include <iocsh.h>

#include <drvSup.h>
#include <epicsExport.h>

#include <tpgAsynDriver.h>
#include <tpgSequencer.h>
#include <asynPortDriver.h>
#include <asynOctetSyncIO.h>

#include "yamlLoader.h"
#include "tpg.hh"
#include "tpg_cpsw.hh"

#ifdef HAVE_YAML
#include "tpg_yaml.hh"
#endif /* HAVE_YAML */

#define TIME_DEADBAND   50

#define NUM_FIXEDDIV    10
#define NUM_ACDIV       6


extern "C" { void * _getBsaBridge(void); }


static const  char *driverName="tpgAsynDriver";
static char port_name[32];
static char ip_address[32];
static int once = 0;   /* do not make more thant one instace */
static class tpgAsynDriver *pTpgDrv = NULL;

static int _tpg_kind = 0;  /* 0: LCLS2, 1: South Pole */



class FaultCallback: public TPGen::Callback {
    private:
        tpgAsynDriver *pTpgDrv;
    public:
        FaultCallback() {pTpgDrv = 0;}
        FaultCallback(tpgAsynDriver *p) { pTpgDrv = p; }
        ~FaultCallback() {}
    public:
        void routine(void) {
            if(!pTpgDrv) return;
            pTpgDrv->getFaultBuffer();
        }
};

class BSACallback: public TPGen::Callback {
    private:
        tpgAsynDriver *pTpgDrv;
    public:
        BSACallback() {pTpgDrv = 0;}
        BSACallback(tpgAsynDriver *p) { pTpgDrv = p; }
        ~BSACallback() {}
        void routine(void) {
            if(!pTpgDrv) return;
            /* do callback function here */
        }
};

class IntervalCallback: public TPGen::Callback {
    private:
        tpgAsynDriver *pTpgDrv;
    public:
        IntervalCallback() {pTpgDrv=0;}
        IntervalCallback(tpgAsynDriver *p) { pTpgDrv = p; }
        ~IntervalCallback() {}
        void routine(void) {
            if(!pTpgDrv) return;
            /* do callback function here */
            
            pTpgDrv->intervalCallback();
        }
};


/** Constructor for the cpswAsynDriver class.
 * Calls constructor for the asynPortDriver base class.
 * \param[in] portName The name of the asyn port driver to be created.
 * \param[in] ipString The IP address for TPG
 *
 * */

tpgAsynDriver::tpgAsynDriver(const char *portName, const char *ipString)
    : asynPortDriver(portName,
                     1, /* number of elements of this device */
                     NUM_TPG_DET_PARAMS, /* number of asyn params to be cleared for each device */
                     asynInt32Mask | asynFloat64Mask | asynOctetMask | asynDrvUserMask | asynInt32ArrayMask | asynInt16ArrayMask, /* Interface mask */
                     asynInt32Mask | asynFloat64Mask | asynOctetMask | asynEnumMask | asynInt32ArrayMask | asynInt16ArrayMask,  /* Interrupt mask */
                     1, /* asynFlags.  This driver does block and it is not multi-device, so flag is 1 */
                     1, /* Autoconnect */
                     0, /* Default priority */
                     0) /* Default stack size*/
{
    if(once) return;
    once = 1;
#ifndef HAVE_YAML
    pTpg = new TPGen::TPGCpsw(ipString);
#else /* HAVE_YAML */
    pTpg = new TPGen::TPGYaml(cpswGetRoot());
#endif /* HAVE_YAML */

    if(_tpg_kind == 0) {             /* lcls2 TPG */
        tpg_kind = lcls2;
        pTpg->setClockStep(5,5,13);
    } else if(_tpg_kind == 1) {      /* south pole TPG */
        tpg_kind = south_pole;
        pTpg->setClockStep(8,4,29);
    }
    
    save_pulseID_U = 0;
    save_pulseID_L = 0;
    save_pulseID = 0UL;

    createParam(ipAddressString,     asynParamOctet,         &p_ipAddress);
    createParam(fwVersionString,     asynParamInt32,         &p_fwVersion);
    createParam(nAllowEnginesString, asynParamInt32,         &p_nAllowEngines);
    createParam(nBeamEnginesString,  asynParamInt32,         &p_nBeamEngines);
    createParam(nExptEnginesString,  asynParamInt32,         &p_nExptEngines);
    createParam(nArraysBSAString,    asynParamInt32,         &p_nArraysBSA);
    createParam(seqAddrWidthString,  asynParamInt32,         &p_seqAddrWidth);
    createParam(fifoAddrWidthString, asynParamInt32,         &p_fifoAddrWidth);

    createParam(baseDivisorString,   asynParamInt32,         &p_baseDivisor);
    createParam(acDelayString,       asynParamInt32,         &p_acDelay);
    createParam(fixedDivisorsString, asynParamInt32Array,    &p_fixedDivisors);
    createParam(acDivisorsString,    asynParamInt32Array,    &p_acDivisors);
    createParam(energyString,        asynParamInt32Array,    &p_energy);
    createParam(reloadDivisorsString,asynParamInt32,         &p_reloadDivisors);
    createParam(forceResyncString,   asynParamInt32,         &p_forceResync);
    createParam(setPulseIDString,    asynParamInt32,         &p_setPulseID);
    createParam(manualFaultString,   asynParamInt32,         &p_manualFault);
    createParam(clearFaultBufferString, asynParamInt32,      &p_clearFaultBuffer);

    createParam(pulseID_UString,     asynParamInt32,         &p_pulseID_U);
    createParam(pulseID_LString,     asynParamInt32,         &p_pulseID_L);
    createParam(pulseID_offsetString,asynParamInt32,         &p_pulseID_offset);
    
    createParam(savePulseID_UString, asynParamInt32,         &p_savePulseID_U);
    createParam(savePulseID_LString, asynParamInt32,         &p_savePulseID_L);
    

    createParam(secString,           asynParamInt32,         &p_sec);
    createParam(nSecString,          asynParamInt32,         &p_nSec);
    createParam(timeSkewString,      asynParamFloat64,       &p_timeSkew);
    createParam(timeStateString,     asynParamInt32,         &p_timeState);
    createParam(timestampString,     asynParamOctet,         &p_timestampString);
    createParam(clockIntervalString, asynParamFloat64,       &p_clockInterval);

    createParam(waveformString,      asynParamInt32Array,    &p_waveform);

    char param_name[32];
    for(int i = 0; i < 4; i++) {
        sprintf(param_name, faultBuffer_manualLatchString, i); createParam(param_name, asynParamInt32, &(p_faultBuffer[i].manualLatch));
        sprintf(param_name, faultBuffer_bcsLatchString, i);    createParam(param_name, asynParamInt32, &(p_faultBuffer[i].bcsLatch));
        sprintf(param_name, faultBuffer_mpsLatchString, i);    createParam(param_name, asynParamInt32, &(p_faultBuffer[i].mpsLatch));
        sprintf(param_name, faultBuffer_tagString, i);         createParam(param_name, asynParamInt32, &(p_faultBuffer[i].tag));
        sprintf(param_name, faultBuffer_mpsTagString, i);      createParam(param_name, asynParamInt32, &(p_faultBuffer[i].mpsTag));
        sprintf(param_name, faultBuffer_clearString, i);       createParam(param_name, asynParamInt32, &(p_faultBuffer[i].clear));
    }


    fwVersion    = pTpg->fwVersion();
    nBeamEngines = pTpg->nBeamEngines();
    nAllowEngines = pTpg->nAllowEngines();
    nExptEngines = pTpg->nExptEngines();
    nArraysBSA   = pTpg->nArraysBSA();
    nRateCounters = pTpg->nRateCounters();
    seqAddrWidth  = pTpg->seqAddrWidth();
    fifoAddrWidth = pTpg->fifoAddrWidth();
    
    diagWfEngine = 255;  // stop diag waveform as a default
    diagWf_flag  = 0;
    diagWf_instr_offset = 0;
    pBsaBridge = NULL;
    pTpg->setDiagnosticSequence(diagWfEngine); // stop diag waveform
    
    
    
    pTpg->reset_xbar(); // sets timing XBAR to drive all ports from FPGA
    
    getFaultBuffer();

    for(unsigned i =0; i < (nBeamEngines + nAllowEngines + nExptEngines); i++) {
        engines.push_back(new ProgSequencer((void*)(this), pTpg, i, & pTpg->engine(i)));
        
        sprintf(param_name, numberEngineString, i);       createParam(param_name, asynParamInt32, &(p_sequencer[i].numberEngine));
        sprintf(param_name, requiredMaskString, i);       createParam(param_name, asynParamInt32, &(p_sequencer[i].requiredMask));
        sprintf(param_name, destinationString, i);        createParam(param_name, asynParamInt32, &(p_sequencer[i].destination));
        sprintf(param_name, descEngineString, i);         createParam(param_name, asynParamOctet, &(p_sequencer[i].descEngine));
        sprintf(param_name, descInstrSetString, i);       createParam(param_name, asynParamOctet, &(p_sequencer[i].descInstrSet));
        sprintf(param_name, wfInstructionString, i);      createParam(param_name, asynParamInt32Array, &(p_sequencer[i].wfInstruction));
        sprintf(param_name, wfInstructionSetString, i);   createParam(param_name, asynParamInt16Array, &(p_sequencer[i].wfInstructionSet));
        sprintf(param_name, counterInstructionString, i); createParam(param_name, asynParamInt32, &(p_sequencer[i].counterInstruction));
        sprintf(param_name, insertInstrSetString, i);     createParam(param_name, asynParamInt32, &(p_sequencer[i].insertInstrSet));
        sprintf(param_name, cancelInstrSetString, i);     createParam(param_name, asynParamInt32, &(p_sequencer[i].cancelInstrSet));

        for(unsigned j=0; j < 64; j++) {
            sprintf(param_name, idxSeqString, i, j);  createParam(param_name, asynParamInt32, &(p_sequencer[i].seqList[j].idxSeq));
            setIntegerParam(p_sequencer[i].seqList[j].idxSeq, -1); 
            sprintf(param_name, descSeqString, i, j); createParam(param_name, asynParamOctet, &(p_sequencer[i].seqList[j].descSeq));
            setStringParam(p_sequencer[i].seqList[j].descSeq, "");
        }

        sprintf(param_name, idxSeqRemoveString, i);       createParam(param_name, asynParamInt32, &(p_sequencer[i].idxSeqRemove));
        sprintf(param_name, seqRemoveString, i);          createParam(param_name, asynParamInt32, &(p_sequencer[i].seqRemove));
        sprintf(param_name, idxSeqResetString, i);        createParam(param_name, asynParamInt32, &(p_sequencer[i].idxSeqReset));
        sprintf(param_name, jumpSeqResetString, i);       createParam(param_name, asynParamInt32, &(p_sequencer[i].jumpSeqReset));
        sprintf(param_name, schedResetString, i);         createParam(param_name, asynParamInt32, &(p_sequencer[i].schedReset));
        sprintf(param_name, schedResetFlagString, i);     createParam(param_name, asynParamInt32, &(p_sequencer[i].schedResetFlag));
        sprintf(param_name, promptResetString, i);        createParam(param_name, asynParamInt32, &(p_sequencer[i].promptReset));
        
        sprintf(param_name, requestRateString, i);        createParam(param_name, asynParamInt32, &(p_sequencer[i].requestRate));
        
        setIntegerParam(p_sequencer[i].counterInstruction, 0);
        setIntegerParam(p_sequencer[i].numberEngine, i);
        
        for(unsigned j = 0; j < 16; j++) {
            sprintf(param_name, mpsJumpIdxSeqString, i, j);     createParam(param_name, asynParamInt32, &(p_sequencer[i].mpsJumpControl[j].idxSeq));
            sprintf(param_name, mpsJumpJumpAddrString, i, j);   createParam(param_name, asynParamInt32, &(p_sequencer[i].mpsJumpControl[j].jumpAddr));
            sprintf(param_name, mpsJumpPowerClassString, i, j); createParam(param_name, asynParamInt32, &(p_sequencer[i].mpsJumpControl[j].powerClass));
        }
        
        sprintf(param_name, getMpsStLatchString, i); createParam(param_name, asynParamInt32, &(p_sequencer[i].mpsStLatch));
        sprintf(param_name, getMpsStStateString, i); createParam(param_name, asynParamInt32, &(p_sequencer[i].mpsStState));
        sprintf(param_name, setMpsStateString,   i); createParam(param_name, asynParamInt32, &(p_sequencer[i].setMpsState));
        sprintf(param_name, dropMpsStateString,  i); createParam(param_name, asynParamInt32, &(p_sequencer[i].dropMpsState));
    }
    
    
    pBsaPoll = new BsaPoll((void*)(this), pTpg);

    for(unsigned i =0; i < nArraysBSA; i++) {
        bsaEdefs.push_back(new BsaEdef((void*)(this), pTpg,i));

        sprintf(param_name, bsaEdefIndexString, i);    createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaEdefIndex));
        sprintf(param_name, bsaNtoAvgString, i);       createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaNtoAvg));
        sprintf(param_name, bsaNtoAcqString, i);       createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaNtoAcq));
        sprintf(param_name, bsaRateModeString, i);     createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaRateMode));
        sprintf(param_name, bsaExpSeqString, i);       createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaExpSeq));
        sprintf(param_name, bsaFixedRateString, i);    createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaFixedRate));
        sprintf(param_name, bsaACRateString, i);       createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaACRate));
        sprintf(param_name, bsaTimeslotMaskString, i); createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaTimeslotMask));
        sprintf(param_name, bsaExpSeqBitString, i);    createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaExpSeqBit));
        sprintf(param_name, bsaDestModeString, i);     createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaDestMode));
        sprintf(param_name, bsaDestMaskString, i);     createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaDestMask));
        sprintf(param_name, bsaInternalDeskMaskString, i);
                                                       createParam(param_name, asynParamInt32, &(p_bsaEdef[i].destMask));
                                                       
        sprintf(param_name, bsaStartString, i);        createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaStart));
                                                       
                                                       
        sprintf(param_name, bsaAvgCntString, i);       createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaAvgCnt));
        sprintf(param_name, bsaAcqCntString, i);       createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaAcqCnt));
        sprintf(param_name, bsaMeasSevrString, i);     createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaMeasSevr));
        sprintf(param_name, bsaCtrlFlagString, i);     createParam(param_name, asynParamInt32, &(p_bsaEdef[i].bsaCtrlFlag));

        setIntegerParam(p_bsaEdef[i].bsaEdefIndex, i);
        setIntegerParam(p_bsaEdef[i].bsaCtrlFlag,  0);

    }
    
    createParam(bsaNinProgressString, asynParamInt32, &p_bsaNinProgress);
    
    
    for(unsigned i = 0; i < nRateCounters; i++) {
        rmEdefs.push_back(new RmEdef((void*)(this), pTpg, i));
    
        sprintf(param_name, rateMeasureIndexString, i);          createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmIndex));
        sprintf(param_name, rateMeasureDescString, i);           createParam(param_name, asynParamOctet, &(p_rmEdef[i].rmDesc));
        sprintf(param_name, rateMeasureRateModeString, i);       createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmRateMode));
        sprintf(param_name, rateMeasureExpSeqString, i);         createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmExpSeq));
        sprintf(param_name, rateMeasureFixedRateString, i);      createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmFixedRate));
        sprintf(param_name, rateMeasureACRateString, i);         createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmACRate));
        sprintf(param_name, rateMeasureTimeslotMaskString, i);   createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmTimeslotMask));
        sprintf(param_name, rateMeasureExpSeqBitString, i);      createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmExpSeqBit));
        sprintf(param_name, rateMeasureDestModeString, i);       createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmDestMode));
        sprintf(param_name, rateMeasureDestMaskString, i);       createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmDestMask));
        sprintf(param_name, rateMeasureCounterString, i);        createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmCounter));
        sprintf(param_name, rateMeasureRateString, i);           createParam(param_name, asynParamFloat64, &(p_rmEdef[i].rmRate));
        sprintf(param_name, rateMeasureCtrlString, i);           createParam(param_name, asynParamInt32, &(p_rmEdef[i].rmCtrl));
        
        setIntegerParam(p_rmEdef[i].rmIndex, rmEdefs[i]->RmIndex());
    }
    
    createParam(rateMeasureSoftJitterString, asynParamFloat64, &p_rmSoftJitter);
    
    
    createParam(diagWfEngString,       asynParamInt32, &p_diagWfEng);
    createParam(diagWfEngIdxString,    asynParamInt32, &p_diagWfEngIdx);
    createParam(diagWfStartString,     asynParamInt32, &p_diagWfStart);
    createParam(diagWfCtrlFlagString,  asynParamInt32, &p_diagWfCtrlFlag);
    createParam(diagWfNameString,      asynParamOctet, &p_diagWfName);
    createParam(diagWfLengthString,    asynParamInt32, &p_diagWfLength);
    createParam(diagWfStartAddrString, asynParamInt32, &p_diagWfStartAddr);
    createParam(diagWfEndAddrString,   asynParamInt32, &p_diagWfEndAddr);
    createParam(diagWfNxtAddrString,   asynParamInt32, &p_diagWfNxtAddr);
    
    setIntegerParam(p_diagWfCtrlFlag, 0);
    
    createParam(diagWfClkString,       asynParamInt32Array, &p_diagWfClk);
    createParam(diagWfClkDeltaString,  asynParamInt32Array, &p_diagWfClkDelta);
    createParam(diagWfInstrString,     asynParamInt16Array, &p_diagWfInstr);
    createParam(diagWfInstrRAddrString,asynParamInt16Array, &p_diagWfInstrRAddr);
    createParam(diagWfBrCnt0String,    asynParamInt16Array, &p_diagWfBrCnt0);
    createParam(diagWfBrCnt1String,    asynParamInt16Array, &p_diagWfBrCnt1);
    createParam(diagWfBrCnt2String,    asynParamInt16Array, &p_diagWfBrCnt2);
    createParam(diagWfBrCnt3String,    asynParamInt16Array, &p_diagWfBrCnt3);



    createParam(countPLLString,        asynParamInt32, &p_countPLL);
    createParam(count186MString,       asynParamInt32, &p_count186M);
    createParam(countSyncEString,      asynParamInt32, &p_countSyncE);
    createParam(countIntvString,       asynParamInt32, &p_countIntv);
    createParam(countBRTString,        asynParamInt32, &p_countBRT);

    createParam(countTxClkString,      asynParamInt32, &p_countTxClk);
    createParam(deltaTxClkString,      asynParamInt32, &p_deltaTxClk);
    createParam(rateTxClkString,       asynParamFloat64, &p_rateTxClk);

    for(unsigned i =0; i<12; i++) {
        sprintf(param_name, countTrigString, i); createParam(param_name, asynParamInt32, &p_countTrig[i]);
    }

    for(unsigned i=0; i<8; i++) {
        sprintf(param_name, progCounterString, i); createParam(param_name, asynParamInt32, &p_progCounter[i]);
    }

    createParam(mpsDiag_PhyReadyRxString,      asynParamInt32, &p_mpsDiag_PhyReadyRx);
    createParam(mpsDiag_PhyReadyTxString,      asynParamInt32, &p_mpsDiag_PhyReadyTx);
    createParam(mpsDiag_LocalLinkReadyString,  asynParamInt32, &p_mpsDiag_LocalLinkReady);
    createParam(mpsDiag_RemoteLinkReadyString, asynParamInt32, &p_mpsDiag_RemoteLinkReady);
    createParam(mpsDiag_RxClockFreqString,     asynParamInt32, &p_mpsDiag_RxClockFreq);
    createParam(mpsDiag_TxClockFreqString,     asynParamInt32, &p_mpsDiag_TxClockFreq);


    setStringParam(p_ipAddress, ipString);
    setIntegerParam(p_fwVersion, fwVersion);
    setIntegerParam(p_nAllowEngines, nAllowEngines);
    setIntegerParam(p_nBeamEngines, nBeamEngines);
    setIntegerParam(p_nExptEngines, nExptEngines);
    setIntegerParam(p_nArraysBSA,   nArraysBSA);
    setIntegerParam(p_seqAddrWidth, seqAddrWidth);
    setIntegerParam(p_fifoAddrWidth, fifoAddrWidth);
    
    callParamCallbacks();

    pTpg->subscribeFault(new FaultCallback(this));
    pTpg->subscribeInterval(new IntervalCallback(this));
    switch(tpg_kind) {
        case lcls2:
            pTpg->setCountInterval(182000000-1);     // LCLS2 TPG, clock rate 182 MHz
            // pTpg->setBaseDivisor(200);               // LCLS2 TPG, default base rate
            break;
        case south_pole:
            pTpg->setCountInterval(122880000-1);     // South Pole TPG, clock rate 122.88 MHZ 
            pTpg->setBaseDivisor(256);              // South Pole TPG, base rate 480kHz
           
            // south pole TPG: pre-programed divisors
            // 15kHz, 12kHz, 10kHz, 8kHz, 6kHz, 5kHz, 4kHz, 3kHz, 2kHz, 1kHz 
            std::vector<unsigned> v = {32, 40, 48, 60, 80, 96, 120, 160, 240, 480};
            pTpg->setFixedDivisors(v);
            pTpg->loadDivisors();
            break;
    }
    pTpg->enableIntervalIrq(false); // ioc has been slow down with the asynchoronous messages, need to disable until solve it.
}

tpgAsynDriver::~tpgAsynDriver()
{
    while(!engines.empty()) {
        delete engines.back();
        engines.pop_back();
    }

    while(!bsaEdefs.empty()) {
        delete bsaEdefs.back();
        bsaEdefs.pop_back();
    }
}


asynStatus tpgAsynDriver::writeInt32(asynUser *pasynUser, epicsInt32 value)
{
    int function = pasynUser->reason;
    asynStatus status = asynSuccess;
    const char *functionName = "writeInt32";

    /* set the paramter in the parameter library */
    status = (asynStatus) setIntegerParam(function, value);

    switch(function) {
        default:
            break;
    }

    if(function == p_baseDivisor && value) {
        /* we are not going to implement baseDivisor */
    }
    else if(function == p_acDelay && value) {              // set AC delay
        pTpg->setACDelay((unsigned) value);
    }
    else if(function == p_reloadDivisors && value) {       // load Divisors
        status = (asynStatus) setIntegerParam(function, 0);
        pTpg->loadDivisors();  
    }
    else if(function == p_forceResync && value) {          // force Resync
        status = (asynStatus) setIntegerParam(function, 0);
        setTimeStamp();
        pTpg->force_sync();
    }
    else if(function == p_setPulseID && value) {          // set pulseID
        status = (asynStatus) setIntegerParam(function, 0);
        setPulseID();
        
    }
    else if(function == p_manualFault && value) {         // generate a manual fault
        status = (asynStatus) setIntegerParam(function, 0);
        pTpg->acquireHistoryBuffers(1);
        printf("Generate Manual Fault\n");

    }
    else if(function == p_clearFaultBuffer && (value >= 0 && value < 4)) {    // clear fault buffer
       pTpg->clearHistoryBuffers((unsigned) value);
       getFaultBuffer();
    }
    	
 	  else if(function == p_savePulseID_U) {
        save_pulseID_U = (uint32_t) value;
    }
    else if(function == p_savePulseID_L) {
        save_pulseID_L = (uint32_t) value;
    }
    
    for(unsigned i=0; i < 4; i++) {
        if(function == p_faultBuffer[i].clear && value) {
            pTpg->clearHistoryBuffers(i);
            getFaultBuffer();
            break;
        }
    }
 
    
    for(unsigned i =0; i < (nBeamEngines+nAllowEngines+nExptEngines); i++) {
        if(function == p_sequencer[i].requiredMask) {    // set required Mast for a i-th engine
            engines[i]->SetRequiredMask((unsigned) value);
        
            break;
        } else
        if(function == p_sequencer[i].destination) {     // set destination for i-th engine
            engines[i]->SetDestination((TPGen::TPGDestination) value);
        
            break;
        } else
        if(function == p_sequencer[i].insertInstrSet && value) {  // proceed inser command for a given instruction set
            status = (asynStatus) setIntegerParam(function, 0);   /* release button immedeiately */
            char _s[256];
            int j =0;
            getStringParam(p_sequencer[i].descInstrSet, 256, _s);
            
            if (!engines[i]->InsertInstrSet(_s)) {
                for(std::unordered_map<int,std::string>::iterator it = (engines[i]->list).begin(); it != (engines[i]->list).end(); it++, j++) {
                    setIntegerParam(p_sequencer[i].seqList[j].idxSeq, it->first);                  // update sequencer index
                    setStringParam(p_sequencer[i].seqList[j].descSeq, it->second.c_str());         // update sequencer description
                }
                
                engines[i]->ReleaseInstrSet(0);
                setIntegerParam(p_sequencer[i].counterInstruction, engines[i]->GetSizeInstrSet());  // update instruction counter
            }
                    
            break;
        } else
        if(function == p_sequencer[i].cancelInstrSet && value) {  // cancel and remove a given instruction set
            status = (asynStatus) setIntegerParam(function, 0); /* release button (param) immediately */
            engines[i]->ReleaseInstrSet(1);    // release instruction set for current program
            setIntegerParam(p_sequencer[i].counterInstruction, engines[i]->GetSizeInstrSet());  // update instruction counter
        
            break;
        }
        if(function == p_sequencer[i].idxSeqRemove) {    // set program index to remove from the engine
        
            break;
        } else
        if(function == p_sequencer[i].seqRemove && value) {      // remove a given program from the engine 
        
           status = (asynStatus) setIntegerParam(function, 0); /* release button (param) immediately */
           int j =0;
           int idx;
           
           getIntegerParam(p_sequencer[i].idxSeqRemove, &idx);
           if(!engines[i]->RemoveInstrSet(idx)) {
                     
               for(std::unordered_map<int,std::string>::iterator it = (engines[i]->list).begin(); it != (engines[i]->list).end(); it++, j++) {  // update program list PVs
                   setIntegerParam(p_sequencer[i].seqList[j].idxSeq, it->first);
                   setStringParam(p_sequencer[i].seqList[j].descSeq, it->second.c_str());
               }
               for(; j<64; j++) {  // fill empty for reamined list PVs
                   setIntegerParam(p_sequencer[i].seqList[j].idxSeq, -1);
                   setStringParam(p_sequencer[i].seqList[j].descSeq, "");
               }
           }        
            break;
        } else
        if(function == p_sequencer[i].idxSeqReset) {    // set program index to start on the engine
        
            break;
        } else 
        if(function == p_sequencer[i].jumpSeqReset) {    // set instruction location to start
        
            break;
        } else
        if(function == p_sequencer[i].schedReset && value) {      // set schedule reset flag the engine when next global reset
            
            status = (asynStatus) setIntegerParam(function, 0); /* release button (param) immediately */
            int flag;
            
            getIntegerParam(p_sequencer[i].schedResetFlag, &flag); // read out latched flag
            if(flag) setIntegerParam(p_sequencer[i].schedResetFlag, 0);  // toggle the flag
            else     setIntegerParam(p_sequencer[i].schedResetFlag, 1);  // toggle the flag
            
            break;
        } else
        if(function == p_sequencer[i].promptReset  && value) {      // reset the engine immediately
            int seq, start;
            
            getIntegerParam(p_sequencer[i].idxSeqReset, &seq);
            getIntegerParam(p_sequencer[i].jumpSeqReset, &start);
            
            status = (asynStatus) setIntegerParam(function, 0);  /* release button immediately */
            
            engines[i]->SetAddress(seq, (unsigned) start);        
            engines[i]->Reset();
            
            break;
        }
        else
        if(function == p_sequencer[i].setMpsState) {
            engines[i]->SetMpsState(value);
        }
        else
        
        for(unsigned j=0; j < 16; j++) {
            if(function == p_sequencer[i].mpsJumpControl[j].idxSeq ||
               function == p_sequencer[i].mpsJumpControl[j].jumpAddr ||
               function == p_sequencer[i].mpsJumpControl[j].powerClass) {
               
               int mps = (int) j;
               int idx;
               int pclass;
               int start;
               
               getIntegerParam(p_sequencer[i].mpsJumpControl[j].idxSeq, &idx);
               getIntegerParam(p_sequencer[i].mpsJumpControl[j].jumpAddr, &start);
               getIntegerParam(p_sequencer[i].mpsJumpControl[j].powerClass, &pclass);
               
               engines[i]->SetMpsJump(mps, idx, (unsigned) pclass, (unsigned) start);
               
                          
               break;
            }
            
        }
    }
	
	  for(unsigned i=0; i < nRateCounters; i++) {
            if(function == p_rmEdef[i].rmCtrl) {
                if(value) rmEdefs[i]->Start(); 
                else      rmEdefs[i]->Stop();
            }
            else
            if(function == p_rmEdef[i].rmRateMode) {
                if(value==0)        rmEdefs[i]->SetRmRateMode(-2);  // fixed rate mode
                else if(value == 1) rmEdefs[i]->SetRmRateMode(-1);  // ac rate mode 
                else if(value == 2) {
                    int expseq_num;
                    getIntegerParam(p_rmEdef[i].rmExpSeq, &expseq_num);
                    rmEdefs[i]->SetRmRateMode(expseq_num);          // experiental sequencer
                }
              break;
            }
            else
            if(function == p_rmEdef[i].rmExpSeq) {
                int rate_mode;
                getIntegerParam(p_rmEdef[i].rmRateMode, &rate_mode);
                if(rate_mode == 2) rmEdefs[i]->SetRmRateMode(value);
              break;
            }
            else
            if(function == p_rmEdef[i].rmFixedRate) {
                rmEdefs[i]->SetRmFixedRate(value);
              break;
            }
            else
            if(function == p_rmEdef[i].rmACRate) {
                rmEdefs[i]->SetRmACRate(value);
              break;
            }
            else
            if(function == p_rmEdef[i].rmTimeslotMask) {
                rmEdefs[i]->SetRmTimeslotMask(value);
              break;
            }
            else
            if(function == p_rmEdef[i].rmExpSeqBit) {
                rmEdefs[i]->SetRmExpSeqBit(value);
              break;
            }
            else
            if(function == p_rmEdef[i].rmDestMode) {
                rmEdefs[i]->SetRmDestMode(value);
              break;
            }
            else
            if(function == p_rmEdef[i].rmDestMask) {
                rmEdefs[i]->SetRmDestMask(value);
              break;
            }
	  }


    for(unsigned int i = 0; i< nArraysBSA; i++) {
        if(function == p_bsaEdef[i].bsaNtoAvg) {   // set number of average for BSA 
            bsaEdefs[i]->SetbsaNtoAvg(value);
        }
        else
        if(function == p_bsaEdef[i].bsaNtoAcq) {  // set nubmer of acquire for BSA
            bsaEdefs[i]->SetbsaNtoAcq((value==-1)?65535:value);
        }
        else
        if(function == p_bsaEdef[i].bsaRateMode) {  // set rate mode, -2: fixed rate, -1: ac rate, 0.. : experimental seq
            if(value == 0) {
                bsaEdefs[i]->SetbsaRateMode(-2);    // fixed rate
            } else if(value == 1) {
                bsaEdefs[i]->SetbsaRateMode(-1);    // ac rate
            } else if(value == 2) {
                int expseq_num;
                getIntegerParam(p_bsaEdef[i].bsaExpSeq, &expseq_num);
                bsaEdefs[i]->SetbsaRateMode(expseq_num);    //experimental sequencer
            }
        }
        else
        if(function == p_bsaEdef[i].bsaExpSeq) {
            int rate_mode;
            getIntegerParam(p_bsaEdef[i].bsaRateMode, &rate_mode);
            if(rate_mode == 2) {                     // if rate mode is exp_seq then update exp_seq number immediately
                bsaEdefs[i]->SetbsaRateMode(value);
            }                                        // other wise, we can update it later when the rate_mode is turn to exp_seq.
        }
        else
        if(function == p_bsaEdef[i].bsaFixedRate) {  // set fixed rate
            bsaEdefs[i]->SetbsaFixedRate(value);
        }
        else
        if(function == p_bsaEdef[i].bsaACRate) { // set AC rate 
            bsaEdefs[i]->SetbsaACRate(value);
        }
        else
        if(function == p_bsaEdef[i].bsaTimeslotMask) {  // set timeslot mask for AC rate mode
            bsaEdefs[i]->SetbsaTimeslotMask(value);
        }
        else
        if(function == p_bsaEdef[i].bsaExpSeqBit) { // set experimental sequencer bit
            bsaEdefs[i]->SetexpSeqBit(value);
        }
        else
        if(function == p_bsaEdef[i].bsaDestMode) { // destination mode 0: disable, do not care 1: exclusion  2: inclusion
            bsaEdefs[i]->SetbsaDestMode(value);
        }
        else
        if(function == p_bsaEdef[i].bsaDestMask) { // destination mask
            bsaEdefs[i]->SetbsaDestMask(value);
        }
        else
        if(function == p_bsaEdef[i].bsaMeasSevr) { // BSA max severity, measurement severity
            bsaEdefs[i]->SetbsaMeasSevr((unsigned)value);
        }
        if(function == p_bsaEdef[i].bsaStart) { // BSA Start/Stop
            if(value) {
                bsaEdefs[i]->Start();
            } else {
                bsaEdefs[i]->Stop();
            }
        }


    }
    
    
    if(function == p_diagWfEng || function == p_diagWfEngIdx) {
        int e,i;
        getIntegerParam(p_diagWfEng,   &e);
        getIntegerParam(p_diagWfEngIdx, &i);
        diagWfEngine = e*16 + i;
    }
    
    if(function == p_diagWfStart) {
        if(value) {  // start diagnosticSequence
            // prepare ram offset value for relative address
            TPGen::InstructionCache c;
            int i;
            getIntegerParam(p_sequencer[diagWfEngine].idxSeqReset, &i);  // get sub-sequence index
            c = engines[diagWfEngine]->getCache(i);                      // get instruction cache for the sub-sequence
            if(c.index != -1) {
                diagWf_instr_offset = c.ram_address;  // set offset 
            }
            else {
                diagWf_instr_offset = 0;  // wrong sub-sequence index, set offset to zero
            }
            printf("diag buffer: engine %d, sub-seq %d\n, offset %d\n", diagWfEngine, i, diagWf_instr_offset);
            setdiagCtrlFlag(0);  // disable force button release
            pTpg->setDiagnosticSequence(diagWfEngine);
            pTpg->initializeRam();
            diagWf_flag = 1;
            // printf("Setup Diag for Eng %d\n", diagWfEngine);
        }
        else {    // stop diagnosticSequence
            pTpg->setDiagnosticSequence(128U);
            diagWf_flag = 0;
            // printf("Stop Diag for Eng %d\n", diagWfEngine);
        }
    
    }


    /* Do callback so higher layers see any changes */
    status = (asynStatus) callParamCallbacks();


    if(status)
        epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                      "%s:%s: status=%d, function=%d, value=%d",
                      driverName, functionName, status, function, value);
    else
        asynPrint(pasynUser, ASYN_TRACEIO_DRIVER,
                  "%s:%s: function=%d, value=%d\n",
                  driverName, functionName, function, value);

    return status;
}

asynStatus tpgAsynDriver::writeInt16Array(asynUser *pasynUser, epicsInt16 *value, size_t nElements)
{
    int function = pasynUser->reason;
    asynStatus status = asynSuccess;
    const char *functionName = "writeInt16Array";
    
    switch(function) {
        default:
            break;
    }
    
    
    for(unsigned int i =0; i< (nAllowEngines + nBeamEngines + nExptEngines); i++) {
        if(function == p_sequencer[i].wfInstructionSet) {
            printf("Instruction set programming for engine %d\n", i);  /* khkim */
            setIntegerParam(p_sequencer[i].counterInstruction, engines[i]->LatchInstructionSet((epicsUInt16*)value, nElements));
            break;
        }
    }
    

    if(status)
        epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                      "%s:%s: status=%d, function=%d, value pointer=%p, nElements=%lu",
                      driverName, functionName, status, function, value, nElements);
    else
        asynPrint(pasynUser, ASYN_TRACEIO_DRIVER,
                  "%s:%s: function=%d, value pointer=%p, nElements=%lu\n",
                  driverName, functionName, function, value, nElements); 
    
    return status;
}

asynStatus tpgAsynDriver::writeInt32Array(asynUser *pasynUser, epicsInt32 *value, size_t nElements)
{
    int function = pasynUser->reason;
    asynStatus   status = asynSuccess;
    const char *functionName = "writeInt32Array";

    switch(function) {
        default:
            break;
    }

    if(function == p_fixedDivisors && nElements >0) {
        std::vector<unsigned> v(NUM_FIXEDDIV);
        for(unsigned i=0; i<NUM_FIXEDDIV;i++) {
            if(i < nElements) v[i] = *(value+i);
            else              v[i] = 0;
        }
        pTpg->setFixedDivisors(v);
        pTpg->loadDivisors();
        
    }
    else
    if(function == p_acDivisors && nElements > 0) {
        std::vector<unsigned> v(NUM_ACDIV);
        for(unsigned i=0; i<NUM_ACDIV;i++) {
            if(i < nElements) v[i] = *(value+i);
            else              v[i] = 0;
        }
        pTpg->setACDivisors(v);
        pTpg->loadDivisors();
    }
    else
    if(function == p_energy && nElements > 0) {
        std::vector<unsigned> v(nElements);
        for(unsigned i=0; i<nElements;i++) v[i] = *(value+i);
        pTpg->setEnergy(v);
    }
    else
    {
        for(unsigned int i=0; i < (nBeamEngines + nAllowEngines + nExptEngines); i++) {
            if(function == p_sequencer[i].wfInstruction) {
                setIntegerParam(p_sequencer[i].counterInstruction, engines[i]->LatchInstruction(value, nElements));
            break;            
            }
   
        }
    
    }



    if(status)
        epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                      "%s:%s: status=%d, function=%d, value pointer=%p, nElements=%lu",
                      driverName, functionName, status, function, value, nElements);
    else
        asynPrint(pasynUser, ASYN_TRACEIO_DRIVER,
                  "%s:%s: function=%d, value pointer=%p, nElements=%lu\n",
                  driverName, functionName, function, value, nElements); 


    return status;
    
}

int tpgAsynDriver::setKind(int i)
{
    tpg_kind = lcls2;    // default kind is for LCLS2
    
    if(i==0) {           // for lcls2 TPG
        tpg_kind = lcls2;
    } else if(i==1) {    // for south pole TPG
        tpg_kind = south_pole;
    }
    
    return 0;
}

int tpgAsynDriver::report(int i)
{
    switch(tpg_kind) {
        case lcls2:
            printf("    LCLS2 mode\n");
            break;
        case south_pole:
            printf("    SouthPole mode\n");
            break;
        default:
            printf("    Wrong....\n");
    }
    
    return 0;
}

// 
//    State machine to keep TPG timestamp near by NTP
//
int tpgAsynDriver::clockStateMachine(void)
{
    typedef enum {init, nominal, fast, slow} state_s;

    static state_s st = init;
    double skew;


    getDoubleParam(p_timeSkew, &skew);

    switch(st) {
        case init:
               st = nominal;
               setIntegerParam(p_timeState, (int) st);
        case nominal:
            if(skew < -TIME_DEADBAND) {  /* transition to slow state */
                st = slow;
                setIntegerParam(p_timeState, (int) st);
                
                /* need to set larger  time interval */
                switch(tpg_kind) {
                    case lcls2:
                        pTpg->setClockStep(5,97,252);
                        setDoubleParam(p_clockInterval, (double)((97./252.) - (5./13.))*1000.);
                        break;
                    case south_pole:
                        pTpg->setClockStep(8,1,7);
                        setDoubleParam(p_clockInterval, (double)((1./7.) - (4./29.))*1000.);
                        break;
                }
                    
            } else if(skew > TIME_DEADBAND) {  /* transition to fast state */
                st = fast;
                setIntegerParam(p_timeState, (int) st);
                
                /* need to set smaller time interval */
                switch(tpg_kind) {
                    case lcls2:
                        pTpg->setClockStep(5,98,255);
                        setDoubleParam(p_clockInterval, (double)((98./255.) - (5./13.))*1000.);
                        break;
                    case south_pole:
                        pTpg->setClockStep(8,3,22);
                        setDoubleParam(p_clockInterval, (double)((3./22.) - (4./29.))*1000.);
                        break;
                }
            } 
        break;
        case fast:
            if(skew<0.) { /* transition to nominal */
                st = nominal;
                setIntegerParam(p_timeState, (int) st);
                
                /* need to set nominal time interval */
                switch(tpg_kind) {
                    case lcls2:
                        pTpg->setClockStep(5,5,13);
                        setDoubleParam(p_clockInterval, (double)(0.));
                        break;
                    case south_pole:
                        pTpg->setClockStep(8,4,29);
                        setDoubleParam(p_clockInterval, (double)(0.));
                        break;
                }
            }
        break;
        case slow:
            if(skew>0.) { /* transition to nominal */
                st = nominal;
                setIntegerParam(p_timeState, (int) st);
                
                /* need to set nominal time interval */
                switch(tpg_kind) {
                    case lcls2:
                        pTpg->setClockStep(5,5,13);
                        setDoubleParam(p_clockInterval, (double)(0.));
                        break;
                    case south_pole:
                        pTpg->setClockStep(8,4,29);
                        setDoubleParam(p_clockInterval, (double)(0.));
                        break;
                }
             }
        break;
    }


    callParamCallbacks();

    if(st==nominal) return 0;
    else            return -1;    
}

int tpgAsynDriver::dump(void)
{
    pTpg->dump();
    return 0;
}

int tpgAsynDriver::getMpsStatus(void)
{
    unsigned prev_latched;
    unsigned latched;
    unsigned state;
    
    for(unsigned int i=0; i < nAllowEngines; i++) {
        pTpg->getMpsState(i, latched, state);
        getIntegerParam(p_sequencer[i].mpsStLatch, (int*) &prev_latched);
        setIntegerParam(p_sequencer[i].mpsStLatch, (int) latched);
        setIntegerParam(p_sequencer[i].mpsStState, (int) state);
        
        if(prev_latched != latched) {
          unsigned set_state;
          getIntegerParam(p_sequencer[i].setMpsState, (int*) &set_state);
          if(latched < set_state) {
              // need to drop mpsSetState
              setIntegerParam(p_sequencer[i].dropMpsState, (int) set_state);
              setIntegerParam(p_sequencer[i].dropMpsState, (int) latched);
          }
        }
    }
    
    callParamCallbacks();
    return 0;
}


int tpgAsynDriver::irqPolling(void)
{
    pTpg->handleIrq();
    return 0;
}

int tpgAsynDriver::softPolling(void)
{
    epicsTimeStamp t1, t2;
    double         diff;
    int            st = 0;


    while(1) {
        epicsTimeGetCurrent(&t1);
        if(!st) getMpsStatus();    // readout MPS stae when the state machine is normal, make 1 second interval for the reading
        getPulseID();
        getTimeStamp();
        getTimeSkew();
        st = clockStateMachine();
        epicsTimeGetCurrent(&t2);
        diff = epicsTimeDiffInSeconds(&t2,&t1);

        if(st) epicsThreadSleep(0.05 - diff);
        else   epicsThreadSleep(1.-diff);
    }


    return 0;
}


int tpgAsynDriver::bsaPolling(void)
{

    while(1) {
        diagWfProcess();
        pBsaPoll->Process();
        setIntegerParam(p_bsaNinProgress, pBsaPoll->GetNinProgress()); 
        callParamCallbacks();   
        epicsThreadSleep(0.1);
    }


    return 0;
}


int tpgAsynDriver::rateMeasurePolling(void)
{
    double intv = 1.0;
    double diff, jitter;
    // double rate;
    unsigned counter;
    unsigned seqReqCounter[32+32+32];
    
    epicsTimeStamp curr, prev;
    
    // pTpg->lockCounters(1);
    epicsTimeGetCurrent(&curr);
    epicsThreadSleep(intv);
    
    while(1) {
        prev = curr;
        // pTpg->lockCounters(1);
        epicsTimeGetCurrent(&curr);
        diff = epicsTimeDiffInSeconds(&curr, &prev);
        
        for(unsigned int i = 0; i < rmEdefs.size(); i++) {
            if(rmEdefs[i]->IsActive()) {
                counter = rmEdefs[i]->RmGetCounter();
                //rate    = rmEdefs[i]->RmGetRate(diff);
                
                setIntegerParam(p_rmEdef[rmEdefs[i]->RmIndex()].rmCounter, counter);
                //setDoubleParam(p_rmEdef[rmEdefs[i]->RmIndex()].rmRate, rate);
            }
        }
        
        pTpg->getSeqRequests(seqReqCounter, 64 /* nAllowEngines+nBeamEngines+nExptEngines */);  // readout the sequencer request rates
        for(unsigned int i = 0; i < (nAllowEngines + nBeamEngines + nExptEngines); i++) {
            setIntegerParam(p_sequencer[i].requestRate, *(seqReqCounter+i));  // post the sequence request rates into epics PVs
        }
        jitter = diff - intv;  // calculate the soft polling jitter
        setDoubleParam(p_rmSoftJitter, (jitter *1.E+6));  // PV posting for the jitter with micro-second unit

        callParamCallbacks();
        epicsThreadSleep(intv - (0.5 * jitter));   // proortional control for the time interval to reduce the jitter
    }
    
    return 0;

}


int tpgAsynDriver::diagnosticsPolling(void)
{

    while(1) {
        getDiags();
        epicsThreadSleep(2.);
    }

    return 0;
    
}

int tpgAsynDriver::intervalCallback(void)
{
    unsigned counter;
    
    for(unsigned int i =0; i < rmEdefs.size(); i++) {
        if(rmEdefs[i]->IsActive()) {
            counter = rmEdefs[i]->RmGetCounter();
            setIntegerParam(p_rmEdef[rmEdefs[i]->RmIndex()].rmCounter, counter); 
        }
    }
    
    callParamCallbacks();
    
        
    return 0;
}



int tpgAsynDriver::getPulseID(void)
{
    pulseID = pTpg->getPulseID();
    pulseID_U = 0x00000000ffffffff & (pulseID>>32);
    pulseID_L = 0x00000000ffffffff & pulseID;
    
    save_pulseID = uint64_t(save_pulseID_U) <<32 | uint64_t(save_pulseID_L);
    
    if(save_pulseID == 0) return 0;  // save-restore doesn't comeback yet
    if(save_pulseID > pulseID) {
        setPulseID();
        return 0;
    }

    setIntegerParam(p_pulseID_U, (int) pulseID_U);
    setIntegerParam(p_pulseID_L, (int) pulseID_L);
    callParamCallbacks();

    return 0;
}

int tpgAsynDriver::setPulseID(void)
{
    int offset;

    getIntegerParam(p_pulseID_offset, &offset);
    return setPulseID((uint64_t) offset);
}

int tpgAsynDriver::setPulseID(uint64_t offset)
{
    printf("set Pulse ID\n");
    
    pTpg->setPulseID(save_pulseID + offset);

    return 0;
}

int tpgAsynDriver::getTimeStamp(void)
{
    char timestamp_string[64];
    
    pTpg->getTimestamp(sec, nSec);
    timeStamp.secPastEpoch = sec;
    timeStamp.nsec         = nSec;
    
    epicsTimeToStrftime(timestamp_string, sizeof(timestamp_string), "%Y/%m/%d %H:%M:%S.%09f", &timeStamp);

    setIntegerParam(p_sec, sec);
    setIntegerParam(p_nSec, nSec);
    setStringParam(p_timestampString, timestamp_string);
    callParamCallbacks();

    return 0;
}

int tpgAsynDriver::setTimeStamp(void)
{

    epicsTimeGetCurrent(&timeStamp);
    sec = timeStamp.secPastEpoch;
    nSec = timeStamp.nsec;

    pTpg->setTimestamp(sec, nSec);

    setIntegerParam(p_sec, sec);
    setIntegerParam(p_nSec, nSec);
    callParamCallbacks();


    return 0;
}

int tpgAsynDriver::getTimeSkew(void)
{
    epicsTimeStamp ts;
    epicsFloat64   tSkew;

    epicsTimeGetCurrent(&ts);

    tSkew = epicsTimeDiffInSeconds(&timeStamp, &ts);
    tSkew *= 1.E+6;  /* time skew in micro-seconds */

    setDoubleParam(p_timeSkew, tSkew);
    callParamCallbacks();
    return 0;
}

int tpgAsynDriver::getFaultBuffer(void)
{
    std::vector <TPGen::FaultStatus> vec(4);
    vec = pTpg->getHistoryStatus();

    for(int i=0; i<4; i++) {
        setIntegerParam(p_faultBuffer[i].manualLatch, vec[i].manualLatch);
        setIntegerParam(p_faultBuffer[i].bcsLatch,    vec[i].bcsLatch);
        setIntegerParam(p_faultBuffer[i].mpsLatch,    vec[i].mpsLatch);
        setIntegerParam(p_faultBuffer[i].tag,         vec[i].tag);
        setIntegerParam(p_faultBuffer[i].mpsTag,      vec[i].mpsTag);

    } 

    callParamCallbacks();

    printf("Callback: Get Fault Buffer\n");

    return 0;
}


int tpgAsynDriver::schedReset(void)
{
    std::list <unsigned> reset_list;
    
    for(unsigned i=0; i < (nBeamEngines + nAllowEngines + nExptEngines); i++) {
        if(p_sequencer[i].schedResetFlag) reset_list.push_back(i);
    }
    
    if(reset_list.size()>0) pTpg->resetSequences(reset_list);

    return 0;
}


int tpgAsynDriver::getDiags(void)
{
    unsigned rxRdy, txRdy, locLnkRdy, remLnkRdy, rxClkFreq, txClkFreq;
    unsigned txClkCount, prev_txClkCount, delta_txClkCount;
    double   txClkRate;
  
    pTpg->getMpsCommDiag(rxRdy, txRdy, locLnkRdy, remLnkRdy, rxClkFreq, txClkFreq);
    pTpg->getTimingFrameRxDiag(txClkCount);
    
    getIntegerParam(p_countTxClk, (int*) &prev_txClkCount);
    delta_txClkCount = txClkCount - prev_txClkCount;
    txClkRate = double (delta_txClkCount *(16/2)) * 1.E-6;  // million-counts per second

    setIntegerParam(p_countTxClk, txClkCount);
    setIntegerParam(p_deltaTxClk, (int)delta_txClkCount);
    setDoubleParam(p_rateTxClk, txClkRate);

    setIntegerParam(p_mpsDiag_PhyReadyRx, rxRdy?1:0);
    setIntegerParam(p_mpsDiag_PhyReadyTx, txRdy?1:0);
    setIntegerParam(p_mpsDiag_LocalLinkReady, locLnkRdy?1:0);
    setIntegerParam(p_mpsDiag_RemoteLinkReady, remLnkRdy?1:0);
    setIntegerParam(p_mpsDiag_RxClockFreq, rxClkFreq);
    setIntegerParam(p_mpsDiag_TxClockFreq, txClkFreq);

    setIntegerParam(p_countPLL,     pTpg->getPLLchanges());
    setIntegerParam(p_count186M,    pTpg->get186Mticks());
    setIntegerParam(p_countSyncE,   pTpg->getSyncErrors());
    setIntegerParam(p_countBRT,     pTpg->getBaseRateTrigs());
    setIntegerParam(p_countIntv,    pTpg->getCountInterval());

    for(unsigned ch = 0; ch < 12; ch++) setIntegerParam(p_countTrig[ch],  pTpg->getInputTrigs(ch));
    for(unsigned i = 0; i < 8; i++)     setIntegerParam(p_progCounter[i], pTpg->getCounter(i));

    callParamCallbacks();
    

    return 0;
}



int tpgAsynDriver::updateBsaProgress(unsigned index, unsigned avgCnt, unsigned acqCnt)
{
    setIntegerParam(p_bsaEdef[index].bsaAvgCnt, avgCnt);
    setIntegerParam(p_bsaEdef[index].bsaAcqCnt, acqCnt);
    
    callParamCallbacks();

    return 0;
}

int tpgAsynDriver::setbsaCtrlFlag(unsigned index, unsigned flag)
{
    setIntegerParam(p_bsaEdef[index].bsaCtrlFlag, flag);
    
    callParamCallbacks();
    
    return 0;
}

int tpgAsynDriver::setdiagCtrlFlag(unsigned flag)
{
    setIntegerParam(p_diagWfCtrlFlag, flag);
    
    callParamCallbacks();
    
    return 0;
}


extern "C" {

/** EPICS iocsh callable function to call constructor for the cpswAsynDriver class.
 * \param[in] portName The name of the asyn port driver to be created.
 * \param[in] ipAddress IP Address for TPG module */
int tpgAsynDriverConfigure(const char *portName, const char *ipString)
{
    pTpgDrv = new tpgAsynDriver(portName, ipString);
    strcpy(port_name, portName);
    strcpy(ip_address, ipString);
    return 0;
}

/* EPICS iocsh shell commands */

int tpgAsynDriverSetKind(const char *kind)
{
    if(!strcmp("lcls1", kind) || !strcmp("LCLS1", kind)) {
        _tpg_kind = 0;
    } else if(!strcmp("south_pole", kind) || !strcmp("SOUTH_POLE", kind)) {
        _tpg_kind = 1;
    }
    
    if(pTpgDrv) pTpgDrv->setKind(_tpg_kind);
    
    return 0;
}

static const iocshArg kindArg0 = {"tpg kind (lcls1, LCLS1, south_pole, SOUTH_POLE)", iocshArgString};
static const iocshArg * const kindArgs[] = { &kindArg0 };
static const iocshFuncDef kindFuncDef = {"tpgAsynDriverSetKind", 1, kindArgs };
static void  kindCallFunc(const iocshArgBuf *args)
{
    tpgAsynDriverSetKind(args[0].sval);
}


#ifndef HAVE_YAML

static const iocshArg initArg0 = { "portName",iocshArgString};
static const iocshArg initArg1 = { "ipAddress",iocshArgString};
static const iocshArg * const initArgs[] = {&initArg0,
                                            &initArg1};
static const iocshFuncDef initFuncDef = {"tpgAsynDriverConfigure",2,initArgs};
static void initCallFunc(const iocshArgBuf *args)
{
    if(once) {
        printf("The TPG driver allows single instance. "
               "Duplicated configuration is ignored.\n");
        return;
    }
    tpgAsynDriverConfigure(args[0].sval, args[1].sval);
}

#else   /* HAVE_YAML */

static const iocshArg initArg0 = { "portName",iocshArgString};
static const iocshArg * const initArgs[] = {&initArg0};
static const iocshFuncDef initFuncDef = {"tpgAsynDriverConfigure",1,initArgs};
static void initCallFunc(const iocshArgBuf *args)
{
    if(once) {
        printf("The TPG driver allows single instance. "
               "Duplicated configuration is ignored.\n");
        return;
    }
    tpgAsynDriverConfigure(args[0].sval, "IP address not applicable");
}

#endif  /* HAVE_YAML */

void tpgAsynDriverRegister(void)
{
    iocshRegister(&kindFuncDef,kindCallFunc);
    iocshRegister(&initFuncDef,initCallFunc);
}

epicsExportRegistrar(tpgAsynDriverRegister);



/* EPICS driver support for tpgAsynDriver */
static int irqPolling(void)
{
    return pTpgDrv->irqPolling();
}

static int softPolling(void)
{
    return pTpgDrv->softPolling();
}

static int bsaPolling(void)
{
    return pTpgDrv->bsaPolling();
}

static int rateMeasurePolling(void)
{
    return pTpgDrv->rateMeasurePolling();
}

static int diagnosticsPolling(void)
{
    return pTpgDrv->diagnosticsPolling();
}

static int tpgAsynDriverReport(int interest);
static int tpgAsynDriverInitialize(void);
static struct drvet tpgAsynDriver = {
    2,
    (DRVSUPFUN) tpgAsynDriverReport,
    (DRVSUPFUN) tpgAsynDriverInitialize
};


epicsExportAddress(drvet, tpgAsynDriver);



static int tpgAsynDriverReport(int interest)
{
    if(!once) return 0;

    printf("TPG port name: %s, TPG IP address: %s\n", port_name, ip_address);
    pTpgDrv->report(interest);
    
    if(interest<1) return 0; 

    pTpgDrv->dump();
    

    return 0;
}


static int tpgAsynDriverInitialize(void)
{

    if(!once) {
        printf ("Driver Initialization is so early.\n");
        return 0;
    }
    else      printf ("Driver Initialization is good.\n");
              printf ("BSA Bridge %p\n", _getBsaBridge());
              
    pTpgDrv->pBsaBridge = _getBsaBridge();
    pTpgDrv->setTimeStamp();
    
    epicsThreadCreate("tpgIrqPollingTask", epicsThreadPriorityMax,
                      epicsThreadGetStackSize(epicsThreadStackMedium),
                      (EPICSTHREADFUNC)irqPolling,0);

    epicsThreadCreate("tpgSoftPollingTask", epicsThreadPriorityHigh,
                      epicsThreadGetStackSize(epicsThreadStackMedium),
                      (EPICSTHREADFUNC)softPolling,0);

    epicsThreadCreate("tpgBsaPollingTask", epicsThreadPriorityMedium,
                      epicsThreadGetStackSize(epicsThreadStackMedium),
                      (EPICSTHREADFUNC) bsaPolling, 0); 
    
    epicsThreadCreate("tpgRateMeasurePollingTask", epicsThreadPriorityLow,
                      epicsThreadGetStackSize(epicsThreadStackMedium),
                      (EPICSTHREADFUNC) rateMeasurePolling, 0);
                      
                      
    epicsThreadCreate("tpgDiagnosticsTask", epicsThreadPriorityLow,
                      epicsThreadGetStackSize(epicsThreadStackMedium),
                      (EPICSTHREADFUNC) diagnosticsPolling, 0);
    



    return 0;
}



}  /* extern C */

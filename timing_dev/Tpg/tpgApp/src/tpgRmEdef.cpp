#include <stdlib.h>

#include "event_selection.hh"
#include "tpgAsynDriver.h"
#include "tpgRmEdef.h"

RmEdef::RmEdef(void *pTpgDrv, TPGen::TPG *pTpg, unsigned rmIndex)
{
    RmEdef::pTpgDrv     = pTpgDrv;
    RmEdef::pTpg        = pTpg;
    RmEdef::rmIndex     = rmIndex;
    
    rmRateMode = -2;    /* make fixed rate mode as a default mode */
    rmFixedRate = 0;
    rmACRate =0;
    rmTimeslotMask = 0;
    rmExpSeqBit = 0;
    rmDestMode = 0;
    rmDestMask = 0;
    destMask = 0;
    
    rmCtrl = 0;   // control flag 
    
}

void RmEdef::Start(void)
{
    if(rmCtrl) return;  // the rate measurement has been started already, nothing todo */
    
    rmCtrl = 1; 
    
    switch(rmDestMode) {
        case 0:   /* disable the destination mode, do not care */
            destMask = 0x02 << 16;
            break;
        case 1:   /* exclusion mode */
            destMask = (0x01 << 16) | (0xffff & rmDestMask);
            break;
        case 2:   /* inclusion mode */
            destMask = (0xffff & rmDestMask);
            break;
        default:
            break;
    
    }
    
    switch(rmRateMode) {
        case -2:  /* fixed rate */
            pTpg->setCounter(rmIndex, new TPGen::FixedRateSelect(rmFixedRate, destMask));
            break;
        case -1:  /* AC rate */
            pTpg->setCounter(rmIndex, new TPGen::ACRateSelect(rmACRate, rmTimeslotMask, destMask));
            break;
        default:  /* Experimental Sequencer */
            if(rmDestMode < 0) break;
            unsigned exp_seq = rmRateMode;
            
            pTpg->setCounter(rmIndex, new TPGen::ExpSeqSelect(exp_seq, rmExpSeqBit, destMask));
            break;
    }
}

void RmEdef::Stop(void)
{
    if(!rmCtrl) return;  /* the rate measurement has been stopped already, noting to do here */
    
    rmCtrl = 0;
}


unsigned RmEdef::RmGetCounter(void)
{
    rmCounter = pTpg->getCounter(rmIndex);
    return rmCounter;
}


double RmEdef::RmGetRate(double Intv)
{
 
    rmRate = (double) rmCounter / Intv;
    return rmRate;
}
#include <stdlib.h>

#include "event_selection.hh"
#include "tpgAsynDriver.h"
#include "tpgBsaEdef.h"

template <class T> class BsaPV {
    public:
    virtual const char name(void) = 0;
    virtual T extract(uint8_t *) = 0;
};


template <class T> class ScopePtr {
    private:
        T *ptr;
    public:
        explicit ScopePtr(T *p=NULL) { ptr = p; }
        ~ScopePtr() { delete ptr; }

        T& operator * ()  { return *ptr; }
        T* operator -> () { return ptr; }
};

BsaEdef::BsaEdef(void *pTpgDrv, TPGen::TPG *pTpg, unsigned bsaEdefIndex)
{
    BsaEdef::pTpgDrv      = pTpgDrv;
    BsaEdef::pTpg         = pTpg;
    BsaEdef::bsaEdefIndex = bsaEdefIndex;

    bsaNtoAvg = 0;
    bsaNtoAcq = 0;
    bsaRateMode = -2;  /* make fixed rate is a default */
    bsaFixedRate = 0;
    bsaACRate = 0;
    bsaTimeslotMask = 0;
    expSeqBit = 0;
    bsaDestMode = 0;
    bsaDestMask = 0;
    destMask = 0;
    bsaStartFlag = 0;
    bsaMeasSevr = 3;   // set invalid as a max. severity 
}

void BsaEdef::StatusQuery(uint64_t completeMask, uint64_t &ackMask)
{
    tpgAsynDriver *pDrv = (tpgAsynDriver*) pTpgDrv;
    // BsaPoll   *pBsaPoll = pDrv->getBsaPoll(); 
    unsigned nToAverage, avgToAcquire;
    
    
    pTpg->queryBSA(bsaEdefIndex, nToAverage, avgToAcquire);
    pDrv->updateBsaProgress(bsaEdefIndex,  nToAverage, avgToAcquire);
    
    if((bsaNtoAcq == avgToAcquire) && (completeMask & (1UL << bsaEdefIndex))) {
        pDrv->setbsaCtrlFlag(bsaEdefIndex, 1);   /* make release the BSA Start button */
        ackMask |= (1UL << bsaEdefIndex);
    }
    

}

void BsaEdef::Start(void) 
{
    tpgAsynDriver *pDrv = (tpgAsynDriver*) pTpgDrv;
    BsaPoll *pBsaPoll   = pDrv->getBsaPoll();
    
    

    if(bsaStartFlag) return; // the BSA has been started already, nothing todo.
    if(bsaNtoAcq ==0) {      // nothing todo
        pDrv->setbsaCtrlFlag(bsaEdefIndex, 1);  // make release the BSA Start button
        return;
    }

    bsaStartFlag = 1;
    
        
    pDrv->updateBsaProgress(bsaEdefIndex, 0, 0);
    pBsaPoll->AddList(this);

    switch(bsaDestMode) {
        case 0:        /* disable the destination mask, do not care */
            destMask = 0x02 << 16;
            break;
        case 1:        /* exclusion mode */
            destMask = (0x01 << 16) | (0xffff & bsaDestMask);
            break;
        case 2:        /* inclusion mode */
            destMask = (0xffff &bsaDestMask);
            break;
        default:
            break; 
    }


    switch (bsaRateMode) {
        case -2: /* Fixed rate */
            /*
            pTpg->startBSA(bsaEdefIndex, bsaNtoAvg, bsaNtoAcq, 
                           &*ScopePtr<TPGen::FixedRateSelect> (new TPGen::FixedRateSelect(bsaFixedRate, destMask)));
            */
            pTpg->startBSA(bsaEdefIndex, bsaNtoAvg, bsaNtoAcq, new TPGen::FixedRateSelect(bsaFixedRate, destMask), bsaMeasSevr);
            break;

        case -1: /* AC rate */
            /*
            pTpg->startBSA(bsaEdefIndex, bsaNtoAvg, bsaNtoAcq,
                           &*ScopePtr<TPGen::ACRateSelect> (new TPGen::ACRateSelect(bsaACRate, bsaTimeslotMask, destMask)));
            */
            pTpg->startBSA(bsaEdefIndex, bsaNtoAvg, bsaNtoAcq, new TPGen::ACRateSelect(bsaACRate, bsaTimeslotMask, destMask), bsaMeasSevr);
            
            break;
        default: /* Experimental Sequencer */
            if(bsaDestMode<0) break;
            unsigned exp_seq = bsaRateMode;
            /*
            pTpg->startBSA(bsaEdefIndex, bsaNtoAvg, bsaNtoAcq,
                           &*ScopePtr<TPGen::ExpSeqSelect> (new TPGen::ExpSeqSelect(exp_seq, expSeqBit, destMask)));
            */
            
            pTpg->startBSA(bsaEdefIndex, bsaNtoAvg, bsaNtoAcq, new TPGen::ExpSeqSelect(exp_seq, expSeqBit, destMask), bsaMeasSevr); 
            break;
    }
}


void BsaEdef::Stop(void) 
{
    tpgAsynDriver *pDrv = (tpgAsynDriver*) pTpgDrv;
    BsaPoll *pBsaPoll   = pDrv->getBsaPoll();
    
    pDrv->setbsaCtrlFlag(bsaEdefIndex, 0);   /* disable the force button release */
    
    if(!bsaStartFlag) return;  // the BAS has been stopped already, nothing to do.

    bsaStartFlag = 0;
    pTpg->stopBSA(bsaEdefIndex);
    pBsaPoll->DeleteList(this);
}

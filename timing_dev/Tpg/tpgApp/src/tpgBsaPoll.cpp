#include <stdlib.h>

#include "tpgAsynDriver.h"
#include "tpgBsaPoll.h"


#ifndef HAVE_YAML 
BsaPoll::BsaPoll(void *pTpgDrv, TPGen::TPGCpsw *pTpg)
{
    BsaPoll::pTpgDrv = pTpgDrv;
    BsaPoll::pTpg    = pTpg;
    
    plock = new epicsMutex;
    pList = new ELLLIST;
    ellInit(pList);
}
#else  /* HAVE_YAML */

BsaPoll::BsaPoll(void *pTpgDrv, TPGen::TPGYaml *pTpg)
{
    BsaPoll::pTpgDrv = pTpgDrv;
    BsaPoll::pTpg    = pTpg;
    
    plock = new epicsMutex;
    pList = new ELLLIST;
    ellInit(pList);
}

#endif /* HAVE_YAML */



void BsaPoll::AddList(BsaEdef *p)
{
    bsaPollList_t *pPoll;
    if(!pList) return;
    
    plock->lock();
    
    pPoll = (bsaPollList_t*)ellFirst(pList);
    while(pPoll) {
        if(pPoll->pBsaEdef == p) break;   
        pPoll = (bsaPollList_t*) ellNext(&pPoll->node);
    }
 
    if(!pPoll) {  /* the BSA Edef is not in the list, need to register into the list */
        pPoll = new bsaPollList_t;
        pPoll->bsaEdefIndex = p->GetbsaEdefIndex();
        pPoll->pBsaEdef     = p;
        ellAdd(pList, &pPoll->node);
    }
    
    plock->unlock();
    
}

void BsaPoll::DeleteList(BsaEdef *p)
{
    bsaPollList_t *pPoll;
    if(!pList) return;
    
    
    plock->lock();
    
    pPoll = (bsaPollList_t*) ellFirst(pList);
    while(pPoll) {
        if(pPoll->pBsaEdef == p) break;
        pPoll = (bsaPollList_t*) ellNext(&pPoll->node);
    }
    
    if(pPoll) {
        ellDelete(pList, &pPoll->node);
        delete pPoll;
    }
    
    plock->unlock();
}


void BsaPoll::Process(void)
{
    // tpgAsynDriver *pDrv = (tpgAsynDriver *) pTpgDrv;
    bsaPollList_t *pPoll;
    BsaEdef       *pBsaEdef;
    if(!pList) return;
    
       
    plock->lock();
    
    ackMask = 0L;  // clear ack mask
    completeMask = pTpg->bsaComplete();  // get complete mask
    
    pPoll = (bsaPollList_t *) ellFirst(pList);
    while(pPoll) {
        pBsaEdef = pPoll->pBsaEdef;
        pBsaEdef->StatusQuery(completeMask, ackMask);
        pPoll = (bsaPollList_t*) ellNext(&pPoll->node);
    }
    
    pTpg->bsaComplete(ackMask);  // give acknowledge for the complete mask
    
    plock->unlock();
    

}

unsigned BsaPoll::GetNinProgress(void)
{
    unsigned n;
    
    plock->lock();
    n = ellCount(pList);
    plock->unlock();
    
    return n;
}
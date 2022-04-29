#include <iocsh.h>
#include <epicsExport.h>
#include <tpgAsynDriver.h>
#include "AmcCarrierBase.hh"
#include "BsaDefs.hh"

#include "yamlLoader.h"

#define MAX_DIAG_LENGTH 20000

// #define DEBUG_ 1


class diagBuf_t {
  public:
    unsigned short branch_cnt0:8;
    unsigned short branch_cnt1:8;
    unsigned short branch_cnt2:8;
    unsigned short branch_cnt3:8;
    unsigned short seq_instr:12;
    unsigned       clock_cnt:20;
};



int tpgAsynDriver::digiWfGetBuff(unsigned length)
{
    if(!pBsaBridge) return 0;
    
    unsigned max = MAX_DIAG_LENGTH * sizeof(diagBuf_t);
    unsigned nelm;
    
    if(length > max) length = max;
    
    uint64_t s = (1ULL<<32);
    uint64_t e = s + length;
    Bsa::AmcCarrierBase *p = (Bsa::AmcCarrierBase *) pBsaBridge;
    uint8_t *pbuf = p->getBuffer(s,e);
    if(!pbuf) return 1;
    
    diagBuf_t *pdiag = (diagBuf_t*) pbuf;
    nelm = length / sizeof(diagBuf_t);
    
    unsigned       *p_clock_cnt   = new unsigned [nelm];        // clock counter
    unsigned       *p_clock_delta = new unsigned [nelm];        // delta clock counter
    unsigned short *p_seq_instr   = new unsigned short [nelm];  // absolute address for instruction
    unsigned short *p_seq_instr_raddr = new unsigned short [nelm]; // relative address for instruction
    unsigned short *p_branch_cnt0 = new unsigned short [nelm];   // branch counter 0
    unsigned short *p_branch_cnt1 = new unsigned short [nelm];   // branch counter 1
    unsigned short *p_branch_cnt2 = new unsigned short [nelm];   // branch counter 2
    unsigned short *p_branch_cnt3 = new unsigned short [nelm];   // branch counter 3
    
    if(!pdiag || !p_clock_cnt || !p_seq_instr
       || !p_branch_cnt0 || !p_branch_cnt1 || !p_branch_cnt2 || !p_branch_cnt3) goto clean_up;
       
       
       printf("sizeof(diagBuf_t): %d\n", sizeof(diagBuf_t));
    
    for(unsigned i=0; i < nelm; i++) {
    #if DEBUG_
      if(i<16) {
        printf("\t ClkCnt %10u: InstrLine %6u, BrCnt0 %u, BrCnt1 %u, BrCnt2 %u, BrCnt3 %u\n", 
        (pdiag+i)->clock_cnt, (pdiag+i)->seq_instr,
        (pdiag+i)->branch_cnt0, (pdiag+i)->branch_cnt1, (pdiag+i)->branch_cnt2, (pdiag+i)->branch_cnt3);
      }
    #endif
        
        *(p_clock_cnt + i)   = (pdiag + i)->clock_cnt;
        *(p_clock_delta +i)  = (!i)? 0: (pdiag +i)->clock_cnt - (pdiag+i-1)->clock_cnt;
        *(p_seq_instr + i)   = (pdiag + i)->seq_instr;
        *(p_seq_instr_raddr +i) = (pdiag +i)->seq_instr - diagWf_instr_offset;
        *(p_branch_cnt0 + i) = (pdiag + i)->branch_cnt0;
        *(p_branch_cnt1 + i) = (pdiag + i)->branch_cnt1;
        *(p_branch_cnt2 + i) = (pdiag + i)->branch_cnt2;
        *(p_branch_cnt3 + i) = (pdiag + i)->branch_cnt3;
    }
    
    doCallbacksInt32Array((epicsInt32*) p_clock_cnt, nelm, p_diagWfClk,0);
    doCallbacksInt32Array((epicsInt32*) p_clock_delta, nelm, p_diagWfClkDelta,0);
    doCallbacksInt16Array((epicsInt16*) p_seq_instr, nelm, p_diagWfInstr, 0);
    doCallbacksInt16Array((epicsInt16*) p_seq_instr_raddr, nelm, p_diagWfInstrRAddr,0);
    doCallbacksInt16Array((epicsInt16*) p_branch_cnt0, nelm, p_diagWfBrCnt0, 0);
    doCallbacksInt16Array((epicsInt16*) p_branch_cnt1, nelm, p_diagWfBrCnt1, 0);
    doCallbacksInt16Array((epicsInt16*) p_branch_cnt2, nelm, p_diagWfBrCnt2, 0);
    doCallbacksInt16Array((epicsInt16*) p_branch_cnt3, nelm, p_diagWfBrCnt3, 0);
    
    clean_up:
    
    if(pbuf) delete pbuf;
    if(p_clock_cnt) delete p_clock_cnt;
    if(p_clock_delta) delete p_clock_delta;
    if(p_seq_instr) delete p_seq_instr;
    if(p_seq_instr_raddr) delete p_seq_instr_raddr;
    if(p_branch_cnt0) delete p_branch_cnt0;
    if(p_branch_cnt1) delete p_branch_cnt1;
    if(p_branch_cnt2) delete p_branch_cnt2;
    if(p_branch_cnt3) delete p_branch_cnt3;
    
    return 0;
}

int tpgAsynDriver::diagWfProcess(void)
{
    static int max = -1;
    static int length;
    
    if(!diagWf_flag && max >0 ) {
      digiWfGetBuff(length);
      max = -1;
      length = 0;
    }
    if(!diagWf_flag || !pBsaBridge) return 0;
    
    Bsa::AmcCarrierBase *p = (Bsa::AmcCarrierBase *) pBsaBridge;
    Bsa::RingState    ring = p->ring(0);

    length = (ring.nxtAddr - ring.begAddr);
    if(length>max) max = length;
    if(length==0 && max >0) {   // buffer is full, release control button
        length = max;
        setdiagCtrlFlag(1);
    }
    
    if(length > (MAX_DIAG_LENGTH * sizeof(diagBuf_t))) setdiagCtrlFlag(1);  // acquisition is reached length of waveform, release control button
    
    setIntegerParam(p_diagWfLength, length);
    setIntegerParam(p_diagWfStartAddr, (int) ring.begAddr);
    setIntegerParam(p_diagWfEndAddr,   (int) ring.endAddr);
    setIntegerParam(p_diagWfNxtAddr,   (int) ring.nxtAddr);
    
    #if DEBUG_
    printf("begAddr %16llx, endAddr %16llx, nxtAddr %16llx\n", ring.begAddr, ring.endAddr, ring.nxtAddr);
    #endif
    
    
    return 0;
}


#ifndef TPG_DRIVER_SEQUENCER_H
#define TPG_DRIVER_SEQUENCER_H

#include <string>
#include <map>
#include <unordered_map>
#include <epicsTypes.h>
#include "tpg.hh"
#include "tpg_cpsw.hh"
#include "user_sequence.hh"
#include "sequence_engine.hh"



class ProgSequencer {
    enum instrTyp {FixedRateSync, ACRateSync,  Branch, CheckPoint, BeamRequest, ExptRequest};
    enum cntIdx   {ctrA, ctrB, ctrC, ctrD};

    private:
        TPGen::TPG *pTpg;
        void  *pTpgDrv;
        unsigned              index;
        unsigned              requiredMask;
        TPGen::TPGDestination destination;
          

    private:
        std::vector<TPGen::Instruction*> instrSet;
        TPGen::SequenceEngine* pSequencer;
        
    public:
        std::unordered_map <int,std::string> list;

    public:
        ProgSequencer();
        ProgSequencer(void *pTpgDrv, TPGen::TPG *pTpg, unsigned index, TPGen::SequenceEngine* pSequencer);
        ~ProgSequencer();

        int  SetRequiredMask(unsigned mask);
        int  SetDestination(TPGen::TPGDestination destination);
        int  ReleaseInstrSet(int freeMemFlag);
        int  GetSizeInstrSet(void);
        int  DumpInstrSet(void);
        int  LatchInstructionSet(epicsUInt16 *pInstrSet, int n);
        int  LatchInstruction(epicsInt32 *pInstr, int nArgs);
        int  SetAddress(int idx, unsigned start);
        int  Reset(void);
        int  InsertInstrSet(char *s);
        int  RemoveInstrSet(int idx);
        
        int  SetMpsJump(int mps, int idx, unsigned pclass, unsigned start);
        int  SetMpsState(int mps);
        
        TPGen::InstructionCache getCache(int idx);
        std::vector<TPGen::InstructionCache> getCache(void);


};


#endif   /* TPG_DRIVER_SEQUENCER_H */


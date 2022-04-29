#include <epicsTypes.h>
#include "tpg.hh"
#include "tpg_cpsw.hh"
#include "user_sequence.hh"
#include "sequence_engine.hh"
#include "tpgSequencer.h"
#include "tpgAsynDriver.h"


ProgSequencer::ProgSequencer()
{
    pTpgDrv    = NULL;
    pTpg       = NULL;
    pSequencer = NULL;
}


ProgSequencer::ProgSequencer(void *pTpgDrv, TPGen::TPG *pTpg, unsigned index, TPGen::SequenceEngine* pSequencer)
{
    ProgSequencer::pTpgDrv    = pTpgDrv;
    ProgSequencer::pTpg       = pTpg;
    ProgSequencer::index      = index;
    ProgSequencer::pSequencer = pSequencer;
  
}


ProgSequencer::~ProgSequencer() { ReleaseInstrSet(1); }


int ProgSequencer::SetRequiredMask(unsigned mask)
{
    if(!pTpg) return -1;

    pTpg->setSequenceRequired(index, requiredMask = mask);


    return 0;
}

int ProgSequencer::SetDestination(TPGen::TPGDestination destination)
{
   if(!pTpg) return -1;

    pTpg->setSequenceDestination(index, ProgSequencer::destination = destination);
    
    return 0;
}

int ProgSequencer::ReleaseInstrSet(int freeMemFalg) {

    if(freeMemFalg) {
        while(!instrSet.empty()) {
            delete instrSet.back();
            instrSet.pop_back();
        }
    } else {
        instrSet.resize(0);
    }

    return 0;

}

int ProgSequencer::GetSizeInstrSet(void) {
    return instrSet.size();
}

int ProgSequencer::DumpInstrSet(void)
{
    if(!pTpg || !pSequencer) return -1;

    pSequencer->dump();
    
    
    return 0;
}


int ProgSequencer::LatchInstructionSet(epicsUInt16 *pInstrSet, int n)
{
    typedef struct {
        epicsUInt16 nArgs;
        epicsUInt16 instr;
        epicsUInt16 arg0;
        epicsUInt16 arg1;
        epicsUInt16 arg2;
        epicsUInt16 arg3;
        epicsUInt16 arg4;
        //epicsUInt16 arg5;
    } s_instr;
    
    int nInstr = (int)(*pInstrSet++);
    s_instr *p = (s_instr *) pInstrSet;
    epicsInt32 pInstr[8];
    
    printf("(khkim)number of instruction: %d\n", nInstr);
    
    for(int i=0; i < nInstr; i++) {
        int j =0;
        
        printf("(khkim) [%d]instruction: args %(%d) instr(%d) %d %d %d %d %d  \n",
                i, p->nArgs, p->instr, p->arg0, p->arg1, p->arg2, p->arg3, p->arg4);
        
        pInstr[j++] = p->instr;
        pInstr[j++] = p->arg0;
        pInstr[j++] = p->arg1;
        pInstr[j++] = p->arg2;
        pInstr[j++] = p->arg3;
        pInstr[j++] = p->arg4;
        //pInstr[j++] = p->arg5;
        
        LatchInstruction(pInstr, p->nArgs +1);
        p++;  
    }
    
    

    return instrSet.size();
}


/* success:        return > 0,
 * fail:           return == -1,
 * no implemented: return == -2
 */
int ProgSequencer::LatchInstruction(epicsInt32 *pInstr, int nArgs)
{

    if(*(pInstr+0) == FixedRateSync && nArgs == (2+1)) {
        unsigned marker_id  = *(++pInstr);
        unsigned occurrence = *(++pInstr);
        
        instrSet.push_back(new TPGen::FixedRateSync(marker_id, occurrence));
    } else
    if(*(pInstr+0) == ACRateSync && nArgs == (3+1)) {
        unsigned timeslot_mask = *(++pInstr);
        unsigned marker_id     = *(++pInstr);
        unsigned occurrence    = *(++pInstr);

        instrSet.push_back(new TPGen::ACRateSync(timeslot_mask, marker_id, occurrence)); 
    } else
    if(*(pInstr+0) == Branch && nArgs == (1+1)) {
        unsigned address = *(++pInstr);

        instrSet.push_back(new TPGen::Branch(address));
    } else
    if(*(pInstr+0) == Branch && nArgs == (3+1)) {
        unsigned     address    = *(++pInstr);
        unsigned     counter_id = *(++pInstr);
        unsigned     test       = *(++pInstr);

        instrSet.push_back(new TPGen::Branch(address, TPGen::CCnt(counter_id), test));
    } else
    if(*(pInstr+0) == CheckPoint && nArgs == (1+1)) {
        return -2;  /* not implemented yet */
    } else 
    if(*(pInstr+0) == BeamRequest && nArgs == (1+1)) {
        unsigned    charge = *(++pInstr);

        instrSet.push_back(new TPGen::BeamRequest(charge));
    } else
    if(*(pInstr+0) == ExptRequest && nArgs == (1+1)) {
        unsigned word = *(++pInstr);
        
        instrSet.push_back(new TPGen::ExptRequest(word));
        
    } else
    {
        return -1; /* unexpected errors in the instruction */
    }
    


    return instrSet.size(); 
}


int ProgSequencer::SetAddress(int idx, unsigned start)
{
    if (!pTpgDrv || !pTpg || !pSequencer) return -1;
    
    pSequencer->setAddress(idx, start);
    
    return 0;
}

int ProgSequencer::Reset(void)
{
    if (!pTpgDrv || !pTpg || !pSequencer) return -1;
    /*
    std::list <unsigned> reset_list;
    
    reset_list.push_back(index);
    pTpg->resetSequences(reset_list);
    */
    
    pSequencer->reset();
    
      
    
    return 0;
}


int ProgSequencer::InsertInstrSet(char *s)
{

    
    if(!pTpgDrv || !pTpg || !pSequencer || instrSet.size() <1 ) return -1;
    
    // std::map <int,std::string> :: iterator it;
    // it = list.begin();
     
    list.insert(std::pair<int,std::string>((int)pSequencer->insertSequence(instrSet),std::string(s)));
    // printf("program results:\n"); 
    // pSequencer->dumpSequence(2);

    return 0;
}


int ProgSequencer::RemoveInstrSet(int idx)
{
    if(!pTpgDrv || !pTpg || !pSequencer) return -1;
    
    std::unordered_map <int,std::string> :: iterator it;
    it = list.find(idx);
    
    if(it == list.end()) return -1;
    
    list.erase(it);     
    if(pSequencer->removeSequence(idx)<0) return -1;
        
    return 0;    
}

int ProgSequencer::SetMpsJump(int mps, int idx, unsigned pclass, unsigned start)
{

    pSequencer->setMPSJump(mps, idx, pclass, start);
    return 0;
    
}

int ProgSequencer::SetMpsState(int mps)
{
    pSequencer->setMPSState(mps);
    
    return 0;
}


TPGen::InstructionCache  ProgSequencer::getCache(int idx)
{
    return pSequencer->cache((unsigned) idx);
}


std::vector<TPGen::InstructionCache> ProgSequencer::getCache(void)
{
    return pSequencer->cache();
}


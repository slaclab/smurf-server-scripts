#ifndef TPG_BSA_POLL_H
#define TPG_BSA_POLL_H

#include <ellLib.h>
#include <epicsMutex.h>

#include "tpg.hh"
#include "tpg_cpsw.hh"
#include "tpg_yaml.hh"

#include "tpgBsaEdef.h"

typedef struct {
    ELLNODE     node;
    unsigned    bsaEdefIndex;
    BsaEdef     *pBsaEdef;   
} bsaPollList_t;

class BsaPoll {
    private:
#ifndef HAVE_YAML
        TPGen::TPGCpsw *pTpg;
#else  /* HAVE_YAML */
        TPGen::TPGYaml *pTpg;
#endif /* HAVE_YAML */
        void           *pTpgDrv;
        
        epicsMutex *plock;
        ELLLIST    *pList;
        
        uint64_t  completeMask;
        uint64_t  ackMask;  
    
    
    public:
        BsaPoll() {};
#ifndef HAVE_YAML
        BsaPoll(void *pTpgDrv, TPGen::TPGCpsw *pTpg);
#else  /* HAVE_YAML */
        BsaPoll(void *pTpgDrv, TPGen::TPGYaml *pTpg);
#endif /* HAVE_YAML */

        ~BsaPoll() {};
        
        void lock(void) { plock->lock(); };
        void unlock(void) { plock->unlock(); };
        
        void AddList(BsaEdef *pBsaEdef);    
        void DeleteList(BsaEdef *pBsaEdef);
        void Process(void);
        unsigned  GetNinProgress(void);
    
};


#endif  /* TPG_BSA_POLL_H */

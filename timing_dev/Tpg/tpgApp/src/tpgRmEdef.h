#ifndef TPG_RM_EDEF_H
#define TPG_RM_EDEF_H

#include "tpg.hh"
#include "tpg_cpsw.hh"

class RmEdef {
    private:
        TPGen::TPG *pTpg;
        void       *pTpgDrv;
        
        unsigned   rmIndex;
        int        rmRateMode;
        unsigned   rmFixedRate;
        unsigned   rmACRate;
        unsigned   rmTimeslotMask;
        unsigned   rmExpSeqBit;
        int        rmDestMode;
        unsigned   rmDestMask;
        unsigned   destMask;
        unsigned   rmCtrl;
        
        unsigned   rmCounter;
        double     rmRate;
        
        
    
    public:
        RmEdef() {};
        RmEdef(void *pTpgDrv, TPGen::TPG *pTpg, unsigned rmEdefIndex);
        ~RmEdef() {};
        
        
        void SetRmIndex(unsigned        rmIndex)        { RmEdef::rmIndex        = rmIndex; }
        void SetRmRateMode(unsigned     rmRateMode)     { RmEdef::rmRateMode     = rmRateMode; }
        void SetRmFixedRate(unsigned    rmFixedRate)    { RmEdef::rmFixedRate    = rmFixedRate; }
        void SetRmACRate(unsigned       rmACRate)       { RmEdef::rmACRate       = rmACRate; }
        void SetRmTimeslotMask(unsigned rmTimeslotMask) { RmEdef::rmTimeslotMask = rmTimeslotMask; }
        void SetRmExpSeqBit(unsigned    rmExpSeqBit)    { RmEdef::rmExpSeqBit    = rmExpSeqBit; }
        void SetRmDestMode(unsigned     rmDestMode)     { RmEdef::rmDestMode     = rmDestMode; }
        void SetRmDestMask(unsigned     rmDestMask)     { RmEdef::rmDestMask     = rmDestMask; }
        
        void Start(void);
        void Stop(void);
        unsigned IsActive(void) { return rmCtrl; }
        unsigned RmIndex(void)  { return rmIndex; }
        unsigned RmGetCounter(void);
        double   RmGetRate(double intv);
};

#endif /* TPG_RM_EDEF_H */
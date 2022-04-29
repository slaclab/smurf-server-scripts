#ifndef TPG_BSA_EDEF_H
#define TPG_BSA_EDEF_H

#include "tpg.hh"
#include "tpg_cpsw.hh"


class BsaEdef {
    private:
        TPGen::TPG *pTpg;
        void       *pTpgDrv;

        unsigned bsaEdefIndex;
        unsigned bsaNtoAvg;
        unsigned bsaNtoAcq;
        int      bsaRateMode;
        unsigned bsaFixedRate;
        unsigned bsaACRate;
        unsigned bsaTimeslotMask;
        unsigned expSeqBit;
        int      bsaDestMode;
        unsigned bsaDestMask;
        unsigned destMask;
        unsigned bsaStartFlag;
        
        unsigned bsaMeasSevr;

    public:
        BsaEdef() {};
        BsaEdef(void *pTpgDrv, TPGen::TPG *pTpg, unsigned bsaEdefIndex);        
        ~BsaEdef(){};

        void SetbsaEdefIndex(unsigned bsaEdefIndex) { BsaEdef::bsaEdefIndex = bsaEdefIndex; }
        unsigned GetbsaEdefIndex(void) { return BsaEdef::bsaEdefIndex; };
        void SetbsaNtoAvg(unsigned    bsaNtoAvg)    { BsaEdef::bsaNtoAvg    = bsaNtoAvg; }
        void SetbsaNtoAcq(unsigned    bsaNtoAcq)    { BsaEdef::bsaNtoAcq    = bsaNtoAcq; }
        void SetbsaRateMode(int       bsaRateMode)  { BsaEdef::bsaRateMode  = bsaRateMode; }
        void SetbsaFixedRate(unsigned bsaFixedRate) { BsaEdef::bsaFixedRate = bsaFixedRate; }
        void SetbsaACRate(unsigned    bsaACRate)    { BsaEdef::bsaACRate    = bsaACRate; }
        void SetbsaTimeslotMask(unsigned  bsaTimeslotMask) { BsaEdef::bsaTimeslotMask = bsaTimeslotMask; }
        void SetexpSeqBit(unsigned    expSeqBit)    { BsaEdef::expSeqBit    = expSeqBit; }
        void SetbsaDestMode(int       bsaDestMode)  { BsaEdef::bsaDestMode  = bsaDestMode; }
        void SetbsaDestMask(unsigned  bsaDestMask)  { BsaEdef::bsaDestMask  = bsaDestMask; }
        void SetbsaMeasSevr(unsigned  bsaMeasSevr)  { BsaEdef::bsaMeasSevr  = bsaMeasSevr; }
        void ClearStartFlag(void)                   { BsaEdef::bsaStartFlag = 0; }
        
        void StatusQuery(uint64_t completeMask, uint64_t &ackMask);
        

        void Start(void);
        void Stop (void);

};


#endif /* TPG_BSA_EDEF_H */

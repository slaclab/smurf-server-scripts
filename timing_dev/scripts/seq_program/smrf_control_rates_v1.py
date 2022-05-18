import sys
import argparse
from sequser import *
#from seq_ca_new import *

Prefix='TPG:SMRF:1'

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='simple exp seq setup')
    parser.add_argument('--pv' , help="TPG pv base", default=Prefix)
    parser.add_argument('--seq', help="sequence number", type=int, default=0)
    args = parser.parse_args()

    global_sync_marker = 9     # 1kHz fixed rate marker, we do not have lower rate :(
    fix2u_sync_marker  = 4     # 6kHz fixed rate marker
    ctrl_100Hz_marker  = 0x1<<0
    ctrl_200Hz_marker  = 0x1<<1
    ctrl_300Hz_marker  = 0x1<<2
    ctrl_400Hz_marker  = 0x1<<3
    
    
    instrset = []
    #  Insert global sync instruction (1Hz?), wo do not have slower rate :(
    instrset.append(FixedRateSync(marker=global_sync_marker, occ=1))

    b0 = len(instrset)
    for i in range(12):
        mask = 0x0
        mask |= ctrl_400Hz_marker if i % 3 == 0 else mask
        mask |= ctrl_300Hz_marker if i % 4 == 0 else mask
        mask |= ctrl_200Hz_marker if i % 6 == 0 else mask
        mask |= ctrl_100Hz_marker if i % 12 == 0 else mask
        if mask != 0x0:
            instrset.append(ControlRequest(word = mask))
        instrset.append(FixedRateSync(marker=fix2u_sync_marker, occ = 5)) 

    instrset.append(Branch.unconditional(line = b0)) 

    # Sequencer Never reach this point, Safty Bound 
    instrset.append(Branch.unconditional(line=0))

    print(len(instrset))
    i=0
    for instr in instrset:
        print ('instruction line({0}): {1}'.format(i, instr.print_()))

        i += 1


    title = 'SMuRF Control Rates'

    seq = SeqUser(args.pv+':EXP',args.seq)
    seq.execute(title,instrset)


# caput TPG:SMRF:1:EXP00:RUNIDX 2
# caput TPG:SMRF:1:EXP00:FORCERESET 1
# caput TPG:SMRF:1:EXP00:FORCERESET 0


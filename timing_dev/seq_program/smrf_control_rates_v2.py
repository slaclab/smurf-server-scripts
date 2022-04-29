import sys
import argparse
from sequser import *
#from seq_ca_new import *

Prefix='TPG:SMRF:1'

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='simple exp seq setup')
    parser.add_argument('--pv' , help="TPG pv base", default=Prefix)
    parser.add_argument('--seq', help="sequence number", type=int, default=0)
    parser.add_argument('--rate', help = "rates string", default='100Hz')
    args = parser.parse_args()

    global_sync_marker = 9     # 1kHz fixed rate marker, we do not have lower rate :(
    fix2u_sync_marker  = 4     # 6kHz fixed rate marker
    ctrl_marker        = 0x1<<0
    program_name = {
            "100Hz": "control rate 100Hz",
            "200Hz": "control rate 200Hz",
            "300Hz": "control rate 300Hz",
            "400Hz": "control rate 400Hz"
    }
    occurence = {
            "100Hz": 12 * 5,
            "200Hz":  6 * 5,
            "300Hz":  4 * 5,
            "400Hz":  3 * 5
    }
    
    
    instrset = []
    #  Insert global sync instruction (1Hz?), wo do not have slower rate :(
    instrset.append(FixedRateSync(marker=global_sync_marker, occ=1))

    b0 = len(instrset)
    instrset.append(ControlRequest(word = ctrl_marker))
    instrset.append(FixedRateSync(marker=fix2u_sync_marker, occ = occurence[args.rate])) 

    instrset.append(Branch.unconditional(line = b0)) 

    # Sequencer Never reach this point, Safty Bound 
    instrset.append(Branch.unconditional(line=0))

    print(len(instrset))
    i=0
    for instr in instrset:
        print ('instruction line({0}): {1}'.format(i, instr.print_()))

        i += 1


    title = program_name[args.rate]

    seq = SeqUser(args.pv+':EXP',args.seq)
    seq.execute(title,instrset)


# caput TPG:SMRF:1:EXP00:RUNIDX 2
# caput TPG:SMRF:1:EXP00:FORCERESET 1
# caput TPG:SMRF:1:EXP00:FORCERESET 0


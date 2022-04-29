#! /bin/bash

#
#  Programming 100Hz
#


# remove existing program
caput TPG:SMRF:1:EXP00:RMVIDX 2
sleep .5
# push remove button
caput TPG:SMRF:1:EXP00:RMVSEQ 1
sleep .5
caput TPG:SMRF:1:EXP00:RMVSEQ 0

# program a new sequence program
python3 smrf_control_rates_v2.py --seq=0 --rate=100Hz

caput TPG:SMRF:1:EXP00:RUNIDX 2
sleep .5
# push force reset
caput TPG:SMRF:1:EXP00:FORCERESET 1
sleep .5
caput TPG:SMRF:1:EXP00:FORCERESET 0



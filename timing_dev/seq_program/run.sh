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


#
#  Programming 200Hz
#


# remove existing program
caput TPG:SMRF:1:EXP01:RMVIDX 2
sleep .5
# push remove button
caput TPG:SMRF:1:EXP01:RMVSEQ 1
sleep .5
caput TPG:SMRF:1:EXP01:RMVSEQ 0

# program a new sequence program
python3 smrf_control_rates_v2.py --seq=1 --rate=200Hz

caput TPG:SMRF:1:EXP01:RUNIDX 2
sleep .5
# push force reset
caput TPG:SMRF:1:EXP01:FORCERESET 1
sleep .5
caput TPG:SMRF:1:EXP01:FORCERESET 0


#
#  Programming 300Hz
#


# remove existing program
caput TPG:SMRF:1:EXP02:RMVIDX 2
sleep .5
# push remove button
caput TPG:SMRF:1:EXP02:RMVSEQ 1
sleep .5
caput TPG:SMRF:1:EXP02:RMVSEQ 0

# program a new sequence program
python3 smrf_control_rates_v2.py --seq=2 --rate=300Hz

caput TPG:SMRF:1:EXP02:RUNIDX 2
sleep .5
# push force reset
caput TPG:SMRF:1:EXP02:FORCERESET 1
sleep .5
caput TPG:SMRF:1:EXP02:FORCERESET 0


#
#  Programming 400Hz
#


# remove existing program
caput TPG:SMRF:1:EXP03:RMVIDX 2
sleep .5
# push remove button
caput TPG:SMRF:1:EXP03:RMVSEQ 1
sleep .5
caput TPG:SMRF:1:EXP03:RMVSEQ 0

# program a new sequence program
python3 smrf_control_rates_v2.py --seq=3 --rate=400Hz

caput TPG:SMRF:1:EXP03:RUNIDX 2
sleep .5
# push force reset
caput TPG:SMRF:1:EXP03:FORCERESET 1
sleep .5
caput TPG:SMRF:1:EXP03:FORCERESET 0


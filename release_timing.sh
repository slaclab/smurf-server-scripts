#!/usr/bin/env bash
# [$1 == version to tag release with.  Use semantic versioning ; vX.Y.Z.
rev=$1
#
if [ "$1" = "" ]
then
  echo "Usage: $0 REV TO TAG RELEASE WITH.  USE SEMANTIC VERSIONING IE vX.Y.Z"
  exit
fi

# Must run this in the smurf-server-scripts directory
parentdir=$(basename `pwd`)
if [ ! "$parentdir" == "smurf-server-scripts" ]; then
    echo "!!! Must run in smurf-server-scripts directory.  Abort!!!"
    exit 1
fi

echo "Releasing rev ${rev} ..."
# timing is a mess right now ; this script at least make the releasing
# process easier

# remove local image if one by that name already exists.  it seems
# like this is necessary or else the cached image gets released.
#docker image rm timing_dev

# Grab hashes.
# first make sure lcls2-timing-patterns repo is here!
if [ ! -d "timing_dev/Tpg/lcls2-timing-patterns" ]; then
    echo "!!! For v3+ must checkout lcls2-timing-patterns and put it in timing_dev to supply patterns !!!  ABORT!"
    exit 1
fi

# Make sure no local unstaged changes in lcls2-timing-patterns
cd timing_dev/Tpg/lcls2-timing-patterns
git diff --exit-code --quiet HEAD
if [ $? == 1 ]; then
    echo "!!! There are local unstaged or uncommited changes in lcls2-timing-patterns!!!  Check them in before releasing!!!  ABORT!"
    exit 1
fi

echo "SMURF_TPG_IOC_RELEASE=${rev}"

# Get branch and hash of lcls2-timing-patterns
LCLS2_TIMING_PATTERNS_HASH=`git rev-parse --short HEAD`
echo "LCLS2_TIMING_PATTERNS_HASH=${LCLS2_TIMING_PATTERNS_HASH}"
LCLS2_TIMING_PATTERNS_BRANCH=`git rev-parse --abbrev-ref HEAD`
echo "LCLS2_TIMING_PATTERNS_BRANCH=${LCLS2_TIMING_PATTERNS_BRANCH}"

# Now check for uncommited timing_dev changes
cd ../../../
git diff --exit-code --quiet HEAD
if [ $? == 1 ]; then
    echo "!!! There are local unstaged of uncommited changes in timing_dev!!!  Check them in before releasing!!!  ABORT!"
    exit 1
fi

# Get branch and hash of lcls2-timing-patterns
TIMING_DEV_HASH=`git rev-parse --short HEAD`
echo "TIMING_DEV_HASH=${TIMING_DEV_HASH}"
TIMING_DEV_BRANCH=`git rev-parse --abbrev-ref HEAD`
echo "TIMING_DEV_BRANCH=${TIMING_DEV_BRANCH}"

# Put version numbers in timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd;
sed -i "s/^# SMURF_TPG_IOC_RELEASE=.*/# SMURF_TPG_IOC_RELEASE=${rev}/" timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd
sed -i "s/^# LCLS2_TIMING_PATTERNS_HASH=.*/# LCLS2_TIMING_PATTERNS_HASH=${LCLS2_TIMING_PATTERNS_HASH}/" timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd
sed -i "s/^# LCLS2_TIMING_PATTERNS_BRANCH=.*/# LCLS2_TIMING_PATTERNS_BRANCH=${LCLS2_TIMING_PATTERNS_BRANCH}/" timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd
sed -i "s/^# TIMING_DEV_HASH=.*/# TIMING_DEV_HASH=${TIMING_DEV_HASH}/" timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd
sed -i "s/^# TIMING_DEV_BRANCH=.*/# TIMING_DEV_BRANCH=${TIMING_DEV_BRANCH}/" timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd

# Re-commit
git add timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd
git commit -m "Committing versioned timing_dev/Tpg/iocBoot/sioc-smrf-ts01/st.cmd for new timing_dev version ${rev}."

# Tag
git tag -a timing_dev-${rev} -m "timing_dev version ${rev}"
git push origin timing_dev-${rev}

# Push commit
git push

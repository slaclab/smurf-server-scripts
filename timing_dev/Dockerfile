# Assume you have run build.sh.
# Assume temp_files contains:
# - ...

# Use this image for compiling, then delete it.
FROM centos:6.10 as builder

# yum -y update fails otherwise
RUN curl https://www.getpagespeed.com/files/centos6-eol.repo --output /etc/yum.repos.d/CentOS-Base.repo; \

# Install packages
yum -y update && yum install -y wget gcc gcc-c++ readline-devel perl && yum clean all -y; \

# Add epel repo
# epel-release has been archived, new link
wget https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm; \
rpm -ivh epel-release-6-8.noarch.rpm; \
rm -rf epel-release-6-8.noarch.rpm; \

# Install extra packages from epel
# util-linux-ng is used by cexp
yum install -y re2c util-linux-ng && yum clean all -y

# Define some common global env vars
## EPICS base version
ENV EPICS_BASE_VERSION R3.15.5-1.1
## Host architecture
ENV EPICS_HOST_ARCH rhel6-x86_64
## Top directory for all EPICS related packages
ENV EPICS_SITE_TOP /usr/local/src/epics
## Top directory for base
ENV BASE_SITE_TOP ${EPICS_SITE_TOP}/base
## Directory of the EPICS base version we are using
ENV EPICS_BASE ${BASE_SITE_TOP}/${EPICS_BASE_VERSION}
## Top directory for modules
ENV EPICS_MODULES ${EPICS_SITE_TOP}/${EPICS_BASE_VERSION}/modules
## Top directory for IOCs
ENV IOC_SITE_TOP ${EPICS_SITE_TOP}/iocTop
## Top directory for packages
ENV PACKAGE_SITE_TOP /usr/local/src/packages
## EPICS CONFIGURATIONS
ENV EPICS_CA_REPEATER_PORT 5065
ENV EPICS_CA_AUTO_ADDR_LIST YES
ENV EPICS_CA_SERVER_PORT 5064

# Install packages
# (I'm copying the ones from AFS for now instead of recompile...)
WORKDIR ${PACKAGE_SITE_TOP}
COPY temp_files/packages ./

# Install EPICS base
RUN mkdir -p ${BASE_SITE_TOP}
WORKDIR ${BASE_SITE_TOP}

COPY temp_files/base .
WORKDIR ${EPICS_BASE_VERSION}
# Build only for the host architecture
RUN sed -i -e 's/^CROSS_COMPILER_TARGET_ARCHS=.*/CROSS_COMPILER_TARGET_ARCHS=/g' configure/CONFIG_SITE; \
    sed -i -e 's/^CROSS_COMPILER_TARGET_ARCHS +=.*/CROSS_COMPILER_TARGET_ARCHS +=/g' configure/CONFIG_SITE; \
    make

ENV PATH ${PATH}:${EPICS_BASE}/bin/${EPICS_HOST_ARCH}
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:${EPICS_BASE}/lib/${EPICS_HOST_ARCH}

# Install EPICS modules
WORKDIR ${EPICS_MODULES}
ADD temp_files/modules/RELEASE_SITE .

# End of Dockerfile_template_1

##  seq
###  R2.2.4-1.0
ARG SEQ_MODULE_VERSION=R2.2.4-1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p seq/${SEQ_MODULE_VERSION}
WORKDIR seq/${SEQ_MODULE_VERSION}
COPY temp_files/modules/seq/${SEQ_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  seq
###  R2.2.4-1.1
ARG SEQ_MODULE_VERSION=R2.2.4-1.1
WORKDIR ${EPICS_MODULES}
RUN mkdir -p seq/${SEQ_MODULE_VERSION}
WORKDIR seq/${SEQ_MODULE_VERSION}
COPY temp_files/modules/seq/${SEQ_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  asyn
###  R4.31-0.1.0
ARG ASYN_MODULE_VERSION=R4.31-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p asyn/${ASYN_MODULE_VERSION}
WORKDIR asyn/${ASYN_MODULE_VERSION}
COPY temp_files/modules/asyn/${ASYN_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  autosave
###  R5.8-1.0.0
ARG AUTOSAVE_MODULE_VERSION=R5.8-1.0.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p autosave/${AUTOSAVE_MODULE_VERSION}
WORKDIR autosave/${AUTOSAVE_MODULE_VERSION}
COPY temp_files/modules/autosave/${AUTOSAVE_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  autosave
###  R5.7.1-3.2.0
ARG AUTOSAVE_MODULE_VERSION=R5.7.1-3.2.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p autosave/${AUTOSAVE_MODULE_VERSION}
WORKDIR autosave/${AUTOSAVE_MODULE_VERSION}
COPY temp_files/modules/autosave/${AUTOSAVE_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  caPutLog
###  R3.5-0.1.0
ARG CAPUTLOG_MODULE_VERSION=R3.5-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p caPutLog/${CAPUTLOG_MODULE_VERSION}
WORKDIR caPutLog/${CAPUTLOG_MODULE_VERSION}
COPY temp_files/modules/caPutLog/${CAPUTLOG_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  iocAdmin
###  R3.1.15-1.0.0
ARG IOCADMIN_MODULE_VERSION=R3.1.15-1.0.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p iocAdmin/${IOCADMIN_MODULE_VERSION}
WORKDIR iocAdmin/${IOCADMIN_MODULE_VERSION}
COPY temp_files/modules/iocAdmin/${IOCADMIN_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  iocAdmin
###  R3.1.15-1.1.0
ARG IOCADMIN_MODULE_VERSION=R3.1.15-1.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p iocAdmin/${IOCADMIN_MODULE_VERSION}
WORKDIR iocAdmin/${IOCADMIN_MODULE_VERSION}
COPY temp_files/modules/iocAdmin/${IOCADMIN_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  calc
###  R3.6.1-0.1.0
ARG CALC_MODULE_VERSION=R3.6.1-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p calc/${CALC_MODULE_VERSION}
WORKDIR calc/${CALC_MODULE_VERSION}
COPY temp_files/modules/calc/${CALC_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  sscan
###  R2.10.2-0.1.0
ARG SSCAN_MODULE_VERSION=R2.10.2-0.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p sscan/${SSCAN_MODULE_VERSION}
WORKDIR sscan/${SSCAN_MODULE_VERSION}
COPY temp_files/modules/sscan/${SSCAN_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  miscUtils
###  R2.2.5
ARG MISCUTILS_MODULE_VERSION=R2.2.5
WORKDIR ${EPICS_MODULES}
RUN mkdir -p miscUtils/${MISCUTILS_MODULE_VERSION}
WORKDIR miscUtils/${MISCUTILS_MODULE_VERSION}
COPY temp_files/modules/miscUtils/${MISCUTILS_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  yamlLoader
###  R1.1.0
ARG YAMLLOADER_MODULE_VERSION=R1.1.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p yamlLoader/${YAMLLOADER_MODULE_VERSION}
WORKDIR yamlLoader/${YAMLLOADER_MODULE_VERSION}
COPY temp_files/modules/yamlLoader/${YAMLLOADER_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  bsaDriver
###  R1.5.0
ARG BSADRIVER_MODULE_VERSION=R1.5.0
WORKDIR ${EPICS_MODULES}
RUN mkdir -p bsaDriver/${BSADRIVER_MODULE_VERSION}
WORKDIR bsaDriver/${BSADRIVER_MODULE_VERSION}
COPY temp_files/modules/bsaDriver/${BSADRIVER_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make

##  crossbarControl
###  R1.0.4
ARG CROSSBARCONTROL_MODULE_VERSION=R1.0.4
WORKDIR ${EPICS_MODULES}
RUN mkdir -p crossbarControl/${CROSSBARCONTROL_MODULE_VERSION}
WORKDIR crossbarControl/${CROSSBARCONTROL_MODULE_VERSION}
COPY temp_files/modules/crossbarControl/${CROSSBARCONTROL_MODULE_VERSION} .
# Point to the re2c install in the system
RUN if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^RE2C =.*|RE2C = /usr/bin/re2c|g' configure/CONFIG_SITE; fi; \
# Remove cross compilation
    if [ -f configure/CONFIG_SITE.Common.rhel6-x86_64 ]; then sed -i -e 's|^PACKAGE_AREA=.*|PACKAGE_AREA=${PACKAGE_SITE_TOP}|g' configure/CONFIG_SITE.Common.rhel6-x86_64; fi; \
    if [ -f configure/CONFIG_SITE ]; then sed -i -e 's|^CROSS_COMPILER_TARGET_ARCHS\s*=.*|CROSS_COMPILER_TARGET_ARCHS=|g' configure/CONFIG_SITE; fi; \
    rm -rf configure/CONFIG_SITE.Common.linuxRT-x86_64; \
    make
# dockerfile_template_2

# Application top directory
ARG DOCKER_DIR=/root/Tpg
# Add ipmitool to the image
RUN yum -y update && yum install -y ipmitool && yum clean all -y
# Set some EPICS env vars
ENV BASE_MODULE_VERSION R3.15.5-1.1
# Prepare the build directory
RUN mkdir -p ${DOCKER_DIR}
WORKDIR ${DOCKER_DIR}
# Copy files from the repo.
ADD Tpg .
ADD scripts/start_ioc.sh .
ADD config config
# Build the application
RUN make distclean && make

# Extract data.tar.gz into $DOCKER_DIR/sioc-smrf-ts01. These are variables in the IOC.
COPY data.tar.gz .
RUN mkdir sioc-smrf-ts01
RUN tar -xf data.tar.gz -C sioc-smrf-ts01/
RUN mv sioc-smrf-ts01/data/* sioc-smrf-ts01
RUN rmdir sioc-smrf-ts01/data
RUN rm data.tar.gz

# Extract tpg.tar.gz, which is a compiled version of /afs/slac/g/cd/swe/git/repos/package/timing/tpg.git, which contains the scripts hps_peek. Useful for debugging.
COPY tpg.tar.gz .
RUN mkdir tpg
RUN tar -xf tpg.tar.gz -C tpg/
RUN rm tpg.tar.gz

COPY lcls2-timing-patterns.tar .
RUN tar -xf lcls2-timing-patterns.tar
RUN rm lcls2-timing-patterns.tar

# Go to the output image
FROM centos:7

# Get python3 to run lcls2-timing-patterns/smurf/patterngeneratory.py
RUN yum -y update
RUN yum -y install python3
RUN python3 -m pip install numpy pyqtgraph

# ARG and ENV do not persist after FROM, set them again.

ARG DOCKER_DIR=/root/Tpg
ENV EPICS_CA_REPEATER_PORT 5065
ENV EPICS_CA_AUTO_ADDR_LIST YES
ENV EPICS_CA_SERVER_PORT 5064
ENV IOC_DATA $DOCKER_DIR

# Copy the IOC produced during the building stage
COPY --from=builder $DOCKER_DIR $DOCKER_DIR
# Copy the ipmitool binary
COPY --from=builder /usr/bin/ipmitool /usr/bin/ipmitool
# Go to the application top level
WORKDIR $DOCKER_DIR
# Start the IOC using the default shelfmanager name and slot number
ENTRYPOINT ["./start_ioc.sh","-S", "shm-smrf-sp01", "-N", "2"]

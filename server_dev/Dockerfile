# server_dev/Dockerfile. Build the pysmurf server. Both local users
# and the GitHub servers should be able to run this Dockerfile. GitHub
# builds it during testing and during release.

FROM tidair/smurf-base:R1.1.1

# Install system tools
RUN apt-get update && apt-get install -y \
    cmake \
    libboost-all-dev \
    libbz2-dev \
    libzmq3-dev \
    python3-pyqt5 \
    python3-pyqt5.qtsvg \
 && rm -rf /var/lib/apt/lists/*

# PIP Packages
RUN pip3 install PyYAML Pyro4 parse click pyzmq packaging jsonpickle sqlalchemy serial pydm

# Install Rogue (An specific point in the the pre-release branch)
WORKDIR /usr/local/src
RUN git clone https://github.com/slaclab/rogue.git -b v4.11.10
WORKDIR rogue

# Apply patches
RUN mkdir build
WORKDIR build
RUN cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DROGUE_INSTALL=local .. && make -j4 install
ENV PYTHONPATH /usr/local/src/rogue/lib:${PYTHONPATH}
ENV PYTHONPATH /usr/local/src/rogue/python:${PYTHONPATH}
ENV ROGUE_DIR  /usr/local/src/rogue

# Setup PyDM environmental variables
ENV PYQTDESIGNERPATH       ${ROGUE_DIR}/python/pyrogue/pydm:${PYQTDESIGNERPATH}
ENV PYDM_DATA_PLUGINS_PATH ${ROGUE_DIR}/python/pyrogue/pydm/data_plugins
ENV PYDM_TOOLS_PATH        ${ROGUE_DIR}/python/pyrogue/pydm/tools

# Copy utility scripts
RUN mkdir -p /usr/local/src/rogue_utilities
COPY scripts/* /usr/local/src/rogue_utilities/
ENV PATH /usr/local/src/rogue_utilities:${PATH}

# Get the firmware files locally.
# /tmp/fw/ contains:
# - smurf_cfg: Clone of https://github.com/slaclab/smurf_cfg
# - .mcs.gz file: File from 'make' from https://github.com/slaclab/cryo-det
# - .zip file: File from 'make release' from https://github.com/slaclab/cryo-det
RUN mkdir -p /tmp/fw/ && chmod -R a+rw /tmp/fw/
COPY fw /tmp/fw/

# Get smurf-pcie remotely and compile it.
WORKDIR /usr/local/src
RUN git clone https://github.com/slaclab/smurf-pcie.git -b v2.0.0
WORKDIR smurf-pcie
RUN sed -i -e 's|git@github.com:|https://github.com/|g' .gitmodules
RUN git submodule sync && git submodule update --init --recursive
ENV PYTHONPATH /usr/local/src/smurf-pcie/software/python:${PYTHONPATH}
ENV PYTHONPATH /usr/local/src/smurf-pcie/firmware/submodules/axi-pcie-core/python:${PYTHONPATH}

# Get pysmurf locally and compile it.
COPY pysmurf /usr/local/src/pysmurf
WORKDIR /usr/local/src/pysmurf
RUN mkdir build
WORKDIR build
RUN cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && make -j4
ENV PYTHONPATH /usr/local/src/pysmurf/lib:${PYTHONPATH}
ENV PYTHONPATH /usr/local/src/pysmurf/python:${PYTHONPATH}
ENV SMURF_DIR /usr/local/src/pysmurf

# Get the local scripts.
RUN mkdir -p /usr/local/src/pysmurf_utilities
ADD scripts/* /usr/local/src/pysmurf_utilities/
ENV PATH /usr/local/src/pysmurf_utilities:${PATH}

# Set the working directory to the root
WORKDIR /

# Define the entrypoint
ENTRYPOINT ["start_server.sh"]

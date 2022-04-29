# server_dev/Dockerfile. Build the pysmurf server. Both local users
# and the GitHub servers should be able to run this Dockerfile. GitHub
# builds it during testing and during release.

FROM tidair/smurf-rogue:R2.8.8

# Get the firmware files locally.
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

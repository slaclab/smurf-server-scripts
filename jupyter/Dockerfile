FROM tidair/smurf-base:R1.1.1

RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive \
apt-get install -y \
python3-gi \
python3-gi-cairo \
gir1.2-gtk-3.0 \
python3-cairocffi \
python3-matplotlib \
&& rm -rf /var/lib/apt/lists/*

RUN pip3 install \
scipy==1.5.2 \
pandas==1.1.0 \
PyYAML==5.3.1 \
pillow==6.2.2 \
seaborn==0.11.2 \
jupyterlab==3.2.9 \
pytest==6.0.1 \
GitPython==3.1.7 \
schema==0.7.1

ENV MPLBACKEND GTK3Agg

# Goto / in the container's filesystem. docker-compose will insert /data into here.
WORKDIR /
ENTRYPOINT ["jupyter", "lab", "--ip=*"]

# How does this docker image find pysmurf? Python uses PYTHONPATH.  In
# docker-compose.yml should set PYTHONPATH to wherever pysmurf should
# be.
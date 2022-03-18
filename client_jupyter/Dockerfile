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

# Go to root, so /home/, /data/, etc. will be visible to Jupyter.
WORKDIR /
ENTRYPOINT ["jupyter", "lab", "--allow-root", "--ip=0.0.0.0"]

# How does this docker image find pysmurf? It searches PYTHONPATH,
# then import pysmurf can run correctly. In this docker container
# PYTHONPATH is set to ${docker_pysmurf_dir}, and
# ${docker_pysmurf_dir} maps to ${host_pysmurf_dir} on the host via
# the docker-compose.yml file. This should make it very easy to move
# around the pysmurf directory on the host to whatever you want.
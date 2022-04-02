from main_docker import docker_compose

"""
This docker container is used by humans and robots. Humans use it to
interrogate the crate with amcc_bsi_dump --all shm-smrf-sp01, compile
software, and run caget against the SMuRF server and robots use it to
start pysmurf ipython sessions and send commands, although interacting
with SMuRF server this way is fragile.
"""

def start(main_dict, service):
    docker_compose(main_dict, ['stop'], service)
    docker_compose(main_dict, ['rm', '-f'], service)
    docker_compose(main_dict, ['run'], service)

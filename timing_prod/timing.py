from smurf_os import docker_compose

"""
Run the SMuRF timing software. This is designed to be used with
the SMuRF timing system. Typically most users don't use this, and
instead use either internal timing or some 122.88 MHz signal.
"""

def start(smurf_dict, service):
    docker_compose(smurf_dict, ['stop'], service)
    docker_compose(smurf_dict, ['rm', '-f'], service)
    docker_compose(smurf_dict, ['run'], service)

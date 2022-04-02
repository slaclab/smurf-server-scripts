"""
Start SMuRF docker containers. Here we define "service" as the
string inside docker-compose.yml, and "container" as the name of the
container for the service. One service can run multiple times, and be
given different container names. For example, smurf_server_s6 is the
container name for the service server_prod in docker-compose.yml. The
service name in docker-compose.yml is named exactly the same as the
folder that contains it, just so we can better organize the different
docker services. So these scripts start services, and give them
specific container names.
"""

import subprocess
import os

def get_env(main_dict, service):
    env = os.environ.copy()

    for key in main_dict[service]:
        val = main_dict[service][key]
        env[key] = str(val)

    return env

def docker_compose(main_dict, arg_list, service):
    proc_list = ['docker-compose'] + arg_list + [service]
    env = get_env(main_dict, service)
    subprocess.call(proc_list, env = env, cwd = service)

def docker_restart(main_dict, service):
    """
    Restart the given service.
    """
    docker_compose(main_dict, ['stop'], service)
    docker_compose(main_dict, ['rm', '-f'], service)
    docker_compose(main_dict, ['up', '-d'], service)

def docker_attach(main_dict, service, container):
    """
    Attach to the docker container named container. This container is
    related to the Docker service named service, so get the
    environment variables for that service so the container can access
    them, for example slot number.
    """
    proc_list = ['docker', 'attach', container]
    # I guess we don't need anything except "docker attach" here.
    subprocess.call(proc_list)
    

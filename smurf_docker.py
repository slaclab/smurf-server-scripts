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

def compose(arg_list, service):
    """
    docker-compose will find the .env file in the current directory.
    """
    proc_list = ['docker-compose'] + arg_list + [service]
    subprocess.check_call(proc_list)

def stop(service):
    """
    Stop and also remove the container.
    """
    compose(['stop'], service)
    compose(['rm', '-f'], service)

def start(service):
    """
    Start the given docker service string. If it's a Dockerfile
    always rebuild it.
    """
    compose(['stop'], service)
    compose(['rm', '-f'], service)
    compose(['up', '-d', '--build'], service)

def attach(service):
    """
    Attach to the given docker service string.
    """
    subprocess.call(['docker', 'attach', service])

def logs(service):
    compose(['logs', '-f'], service)

def build(service):
    compose(['build'], service)

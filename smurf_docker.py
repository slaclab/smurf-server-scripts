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

def docker_command(arg_list, service, env):
    """
    Run a docker command. Used to stop docker containers by their
    name.
    """
    proc_list = ['docker'] + arg_list
    subprocess.check_call(proc_list, env = env, cwd = service)

def compose(arg_list, service, env):
    """
    Given the arguments, service name, and environment variables, call
    docker-compose for that service. docker-compose will run in the
    services folder, and use that folder's docker-compose.yml file,
    and the environment variables will populate the yml file. Used to
    stop docker container by their service name. This function
    usescheck_call, which uses popen. popen args include env, cwd.
    """
    proc_list = ['docker-compose'] + arg_list
    subprocess.check_call(proc_list, env = env, cwd = service)

def stop(service, env):
    """
    Stop and also remove the container. If stopping the server or
    client, call the container name, not the service name, because
    multiple containers run for the same service.
    """

    name = service
    
    if service == 'server_dev' or service == 'server_prod':
        name = env['server_prefix'] + env['slot']
        docker_command(['stop', name], service, env)
        docker_command(['rm', '-f', name], service, env)
        
    elif service == 'client_dev' or service == 'client_prod':
        name = env['client_prefix'] + env['slot']
        docker_command(['stop', name], service, env)
        docker_command(['rm', '-f', name], service, env)
        
    else:
        compose(['stop', service], service, env)
        compose(['rm', '-f', service], service, env)

def start(service, env):
    """
    Start the given docker service string. If it uses a Dockerfile
    always rebuild it, which uses the cache anyway, so it shouldn't
    take too long. Docker is incapable of starting one service into
    two containers without adding the -p flag, sorry.
    """
    compose(['-p', env['slot'], 'up', service], service, env)

def attach(service, env):
    """
    Attach to the given docker service string.
    """
    subprocess.call(['docker', 'attach', service], service, env)

def logs(service, env):
    compose(['logs', '-f', service], service, env)

def build(folder, env):
    """
    Build the service. The docker-compose.yml file has one service
    with the same name as its folder. The image will be named
    identically.
    """
    compose(['build', folder], folder, env)

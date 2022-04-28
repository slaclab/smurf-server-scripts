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

def get_env(smurf_dict, service):
    env = os.environ.copy()

    for key in smurf_dict[service]:
        val = smurf_dict[service][key]
        env[key] = str(val)

    return env

def compose(smurf_dict, arg_list, service):
    proc_list = ['docker-compose'] + arg_list + [service]
    env = get_env(smurf_dict, service)
    subprocess.call(proc_list, env = env, cwd = service)

def stop(smurf_dict, service):
    "Stop the given service."
    compose(smurf_dict, ['stop'], service)
    compose(smurf_dict, ['rm', '-f'], service)

def restart(smurf_dict, service):
    """
    Restart the given service. Add --build to always rebuild the image. -d is detatch.
    """
    stop(smurf_dict, service)
    compose(smurf_dict, ['up', '--build', '-d'], service)    

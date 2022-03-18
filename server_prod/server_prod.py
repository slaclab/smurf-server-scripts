import os
import subprocess
from main_os import start_proc, get_env, docker_compose

def start(main_dict, service):
    
    # Docker services can be run multiple times with different
    # container names. This is useful for us, because we can run
    # multiple slots on the same source code, just with different
    # names. However, be careful to not leave servers running.
    
    container_name = service + main_dict[service]['slot']
    docker_compose(main_dict, ['stop'], container_name)
    docker_compose(main_dict, ['rm', '-f'], container_name)
    docker_compose(main_dict, ['up', '-d'], container_name)

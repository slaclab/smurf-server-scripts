import os
import subprocess

def start_proc(proc_list, smurf_dict):
    env = get_env(smurf_dict)
    subprocess.call(proc_list, env = env, cwd = 'prod')

def get_env(smurf_dict):
    env = os.environ.copy()

    for key in smurf_dict['prod']:
        val = smurf_dict['prod'][key]
        env[key] = str(val)

    return env

def docker_compose(smurf_dict, arg_list):
    proc_list = ['docker-compose'] + arg_list
    start_proc(proc_list, smurf_dict)

def docker_restart_service(smurf_dict, service):
    docker_compose(smurf_dict, ['stop', service])
    docker_compose(smurf_dict, ['rm', '-f', service])
    docker_compose(smurf_dict, ['up', '-d', service])
    
def start_server(smurf_dict):
    docker_restart_service(smurf_dict, "smurf_server")
    
def start_client(smurf_dict):
    docker_restart_service(smurf_dict, "smurf_client")


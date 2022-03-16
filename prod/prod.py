import os
import subprocess

def start_proc(proc_list, smurf_dict):
    env = get_env(smurf_dict)
    subprocess.Popen(proc_list, env = env, cwd = 'prod')

def get_env(smurf_dict):
    env = os.environ.copy()

    for key in smurf_dict['prod']:
        val = smurf_dict['prod'][key]
        env[key] = str(val)

    return env

def start_server(smurf_dict):
    docker_compose(smurf_dict, 'stop')
    docker_compose(smurf_dict, 'rm')
    docker_compose(smurf_dict, 'up')

def docker_compose(smurf_dict, command):
    proc_list = ['docker-compose', command, 'smurf_server_s4']
    start_proc(proc_list, smurf_dict)


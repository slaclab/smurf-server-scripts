import os
import subprocess

def start_proc(proc_list, main_dict):
    env = get_env(main_dict)
    subprocess.call(proc_list, env = env, cwd = main_dict['program'])

def get_env(main_dict):
    env = os.environ.copy()

    for key in main_dict['prod']:
        val = main_dict['prod'][key]
        env[key] = str(val)

    return env

def docker_compose(main_dict, arg_list):
    proc_list = ['docker-compose'] + arg_list
    start_proc(proc_list, main_dict)

def docker_restart_service(main_dict, service):
    docker_compose(main_dict, ['stop', service])
    docker_compose(main_dict, ['rm', '-f', service])
    docker_compose(main_dict, ['up', '-d', service])
    
def start_server(main_dict):
    docker_restart_service(main_dict, "smurf_server")
    
def start_client(main_dict):
    docker_restart_service(main_dict, "smurf_client")


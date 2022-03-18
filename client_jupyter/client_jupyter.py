import os
import subprocess

def start_proc(proc_list, main_dict):
    env = get_env(main_dict)
    subprocess.call(proc_list, env = env, cwd = main_dict['program'])

def get_env(main_dict):
    env = os.environ.copy()

    for key in main_dict[main_dict['program']]:
        val = main_dict[main_dict['program']][key]
        env[key] = str(val)

    return env

def docker_compose(main_dict, arg_list):
    proc_list = ['docker-compose'] + arg_list
    start_proc(proc_list, main_dict)

def docker_restart_service(main_dict):
    docker_compose(main_dict, ['stop', main_dict['program']])
    docker_compose(main_dict, ['rm', '-f', main_dict['program']])
    docker_compose(main_dict, ['up', '-d', main_dict['program']])
    
def start(main_dict):
    docker_restart_service(main_dict)

import subprocess
import os

def start_proc(proc_list, main_dict, service):
    env = get_env(main_dict, service)

    # docker-compose needs to be in the same dir as docker-compose.yml unfortunately, so
    # cd into there.
    
    subprocess.call(proc_list, env = env, cwd = service)

def get_env(main_dict, service):
    env = os.environ.copy()

    for key in main_dict[service]:
        val = main_dict[service][key]
        env[key] = str(val)

    return env

def docker_compose(main_dict, arg_list, service):
    proc_list = ['docker-compose'] + arg_list + [service]
    start_proc(proc_list, main_dict, service)

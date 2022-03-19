from main_os import docker_compose

def start(main_dict, service):
    
    # Docker services can be run multiple times with different
    # container names. This is useful for us, because we can run
    # multiple slots on the same source code, just with different
    # names. However, be careful to not leave servers running.
    
    docker_compose(main_dict, ['stop'], service)
    docker_compose(main_dict, ['rm', '-f'], service)
    docker_compose(main_dict, ['up', '-d'], service)

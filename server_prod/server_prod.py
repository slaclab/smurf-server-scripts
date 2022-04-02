from main_docker import docker_restart

def start(main_dict, service):
    """
    Start one container with the server, and another with the client
    if specified. Docker services can be run multiple times with
    different container names, but still operate independent of
    eachother.
    """

    docker_restart(main_dict, service)

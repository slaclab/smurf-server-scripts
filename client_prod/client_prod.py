from main_docker import docker_restart, docker_attach

def start(main_dict, service):
    """
    Start one container with the server, and another with the client
    if specified. Docker services can be run multiple times with
    different container names, but still operate independent of
    eachother.
    """

    docker_restart(main_dict, service)

    if main_dict[service]['attach'] == True:
        container = main_dict[service]['prefix'] + main_dict[service]['slot']
        docker_attach(main_dict, service, container)

from smurf_docker import docker_restart, docker_attach

def start(smurf_dict, service):
    """
    Start one container with the server, and another with the client
    if specified. Docker services can be run multiple times with
    different container names, but still operate independent of
    eachother.
    """
    
    docker_restart(smurf_dict, service)

    if smurf_dict[service]['attach'] == True:
        container = smurf_dict[service]['prefix'] + smurf_dict[service]['slot']
        print('client_prod.py: Attaching to the production client. Use Ctrl-P Ctrl-Q to detatch, or Ctrl-D to kill the container. To attach again, use the command docker attach.')
        docker_attach(smurf_dict, service, container)

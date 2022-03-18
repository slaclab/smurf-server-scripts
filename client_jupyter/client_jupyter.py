import webbrowser
from main_os import docker_compose
from main_git import get_repo_if_nonexistant

def start(main_dict, service):
    url = main_dict[service]['pysmurf_url']

    # If the repository doesn't exist on the host, just clone it at
    # this default version, then the user can check out other branches
    # as they see fit.
    
    version = main_dict[service]['default_version']

    # We'd like the pysmurf directory to be on the host and not buried
    # inside the docker container. So specify it here and clone if it
    # doesn't exist. Example: /home/cryo/myrepos/pysmurf.
    
    path = main_dict[service]['host_pysmurf_dir']
    get_repo_if_nonexistant(url, version, path)

    # Restart the container named service.
    
    docker_compose(main_dict, ['stop'], service)
    docker_compose(main_dict, ['rm', '-f'], service)

    # Docker should detect changes in the Dockerfile if you choose to
    # change it, for example to update packages. If this doesn't
    # happen for some reason, add --build to the argument list.
    
    docker_compose(main_dict, ['up', '-d'], service)

    print(f'On the host pysmurf is at {path}, which is mapped to {main_dict[service]["docker_pysmurf_dir"]} in the container.')

    # For convenience open the browser. Does nothing if on terminal.
    webbrowser.open('http://localhost:8888', new = 2)

    

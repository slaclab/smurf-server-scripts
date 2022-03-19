import webbrowser
from main_os import docker_compose
from main_git import get_repo_if_nonexistant

def start(main_dict, service):
    '''
    Starting from the host, outside of all docker containers, start
    Jupyter inside one docker container, and open the web browser. Run
    the pysmurf Python code to connect to another docker container
    running the uMux firmware.
    '''
    url = main_dict[service]['pysmurf_url']

    # If the repository doesn't exist on the host, just clone it at
    # this default version, then the user can check out other branches.
    
    version = main_dict[service]['default_version']

    # We'd like the pysmurf directory to be on the host and not buried
    # inside the docker container. So specify it here and clone if it
    # doesn't exist. Example: /home/cryo/myrepos/pysmurf.
    
    path = main_dict[service]['host_pysmurf_dir']
    get_repo_if_nonexistant(url, version, path)

    # Restart the container named service.
    
    docker_compose(main_dict, ['stop'], service)
    docker_compose(main_dict, ['rm', '-f'], service)

    # Use --build to check if the Dockerfile has changed.
    
    docker_compose(main_dict, ['up', '-d', '--build'], service)

    docker_pysmurf_dir = main_dict[service]['docker_pysmurf_dir']
    print(f'On the host pysmurf is {path}, which maps to {docker_pysmurf_dir} in container {service}.')

    # For convenience open the browser. Does nothing if on terminal.
    # The web browser runs on the host, but connects to the Jupyter
    # program running inside the docker container.
    
    webbrowser.open('http://localhost:8888', new = 2)

    

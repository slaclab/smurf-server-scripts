import webbrowser
from smurf_docker import docker_restart
from smurf_git import is_repo_verbose

def start(smurf_dict, service):
    '''
    Starting from the host, outside of all docker containers, start
    Jupyter inside one docker container, and open the web browser. Run
    the pysmurf Python code to connect to another docker container
    running the uMux firmware.
    '''

    # We'd like the pysmurf directory to be on the host and not buried
    # inside the docker container. Example: /home/cryo/repos/pysmurf.
    
    path = smurf_dict[service]['host_pysmurf_dir']

    if is_repo_verbose(path):
        docker_restart(smurf_dict, service)

        docker_pysmurf_dir = smurf_dict[service]['docker_pysmurf_dir']
        print(f'On the host pysmurf is {path}, which maps to {docker_pysmurf_dir} in container {service}.')

        # For convenience open the browser. Does nothing if on terminal.
        # The web browser runs on the host, but connects to the Jupyter
        # program running inside the docker container.
        
        webbrowser.open('http://localhost:8888', new = 2)

    

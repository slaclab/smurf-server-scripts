"""
The top level python file for SMuRF systems. You may call it as
the main program, or from another Python library (e.g. from
simonsobs/sodetlib). This code depends on the Python modules in
requirements.txt and assumes its on Python 3.
"""

import jupyter.jupyter
import util.util
import client_prod.client_prod
import server_prod.server_prod
import smurf_dict

def start(sd):
    """
    Start one or multiple SMuRF programs. Read the given dictionary
    and starts the given services listed in smurf_dict['services'].
    """

    for service in sd['services']:
        if service == 'server_prod':
            docker_restart(sd, service)
            
        elif service == 'client_prod':
            docker_restart(sd, service)

        elif service == 'server_dev':
            server_dev.server_dev.start(sd, service)

        elif service == 'client_dev':
            client_dev.client_dev.start(sd, service)

        elif service == 'timing_prod':
            pass

        elif service == 'timing_dev':
            pass

def stop(sd):
    

def main():
    sd = smurf_dict.get('./smurf.json')

    action = sd['action']

    if action == 'start':
        start(sd)

    elif action == 'stop':
        stop(sd)

if __name__ == "__main__":
    main()

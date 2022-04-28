"""
The top level python file for interacting with SMuRF systems. You
may call it as the main program, or from another Python library
(e.g. from simonsobs/sodetlib).

This essentially boils down to orchestrating the assorted SMuRF docker
containers. Ultimately I suggest scripting over docker images as
little as possible.  Their initial script should know what to do.

Assumptions:
- Python 3
- python -m pip install -r requirements.txt
"""

import smurf_dict
import smurf_docker

def main():
    sd = smurf_dict.get('./smurf.json')

    action = sd['action']
    services = sd['services']

    for service in services:
        
        if action == 'start':
            smurf_docker.restart(sd, service)
            
        elif action == 'stop':
            smurf_docker.stop(sd, service)
    
if __name__ == "__main__":
    main()

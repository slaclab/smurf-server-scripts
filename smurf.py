"""
The top level script for SMuRF systems. You may call it as the
main program, or from another Python library (e.g. from
simonsobs/sodetlib). 
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

    services = sd['services']
    
    for service in services:
        if service == 'server_prod':
            server_prod.server_prod.start(sd, service)
            
        elif service == 'client_prod':
            client_prod.client_prod.start(sd, service)
        
        elif service == 'jupyter':
            jupyter.jupyter.start(sd, service)
            
        elif service == 'util':
            util.util.start(sd, service)

        elif service == 'timing':
            pass

        elif service == 'timing_dev':
            pass

        elif service == 'gui':
            pass

def main():
     sd = smurf_dict.get('./smurf.json')
     start(sd)

if __name__ == "__main__":
    main()

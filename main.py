import jupyter.jupyter
import main_dict
import util.util

import client_prod.client_prod
import server_prod.server_prod

def main():
    """
    Start one or multiple SMuRF programs.
    """

    # Read the main.json file.
    md = main_dict.get()
    services = md['services']

    # Start the services listed in main.json.
    
    for service in services:
        if service == 'server_prod':
            server_prod.server_prod.start(md, service)
            
        elif service == 'client_prod':
            client_prod.client_prod.start(md, service)
        
        elif service == 'jupyter':
            jupyter.jupyter.start(md, service)
            
        elif service == 'util':
            util.util.start(md, service)

        elif service == 'timing':
            pass

        elif service == 'timing_dev':
            pass

        elif service == 'gui':
            pass

if __name__ == '__main__':
    main()

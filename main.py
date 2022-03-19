import client_dev.client_dev
import client_jupyter.client_jupyter
import client_prod.client_prod
import main_dict
import main_os
import server_dev.server_dev
import server_prod.server_prod
import utils.utils

def main():
    """
    Start the SMuRF services listed in main.json.
    """
    
    md = main_dict.get()
    services = md['services']

    for service in services:
        if service == 'server_prod':
            server_prod.server_prod.start(md, service)

        elif service == 'client_prod':
            client_prod.client_prod.start(md, service)
            
        elif service == 'server_dev':
            server_dev.server_dev.start(md, service)

        elif service == 'client_dev':
            client_dev.client_dev.start(md, service)
        
        elif service == 'client_jupyter':
            client_jupyter.client_jupyter.start(md, service)
            
        elif service == 'utils':
            utils.utils.start(md, service)
        
if __name__ == '__main__':
    main()

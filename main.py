import server_prod.server_prod
import client_jupyter.client_jupyter
import main_os
import main_dict

def main():
    """
    Start the SMuRF service as listed in main.json.
    """
    
    md = main_dict.get()
    services = md['services']

    for service in services:
        if service == 'server_prod':
            server_prod.server_prod.start(md, service)

        elif service == 'client_prod':
            pass
            
        elif service == 'server_dev':
            pass

        elif service == 'client_dev':
            pass
        
        elif service == 'client_jupyter':
            client_jupyter.client_jupyter.start(md, service)
            
        elif service == 'utils':
            # utils.utils.start(md)
            pass
        
if __name__ == '__main__':
    main()

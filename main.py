import json
import os

import prod.prod
import client_jupyter.client_jupyter

def get_main_dict():
    """Get dictionary of SMuRF's configuration. Called by main, used by
    Docker.

    """
    main_dict = {}

    json_path = 'main.json'

    if not os.path.isfile(json_path):
        print('No JSON found.')
    else:
        with open(json_path) as json_object:
            main_dict = json.loads(json_object.read())

    return main_dict

def main():
    """Start the SMuRF program as listed in main.json.

    """
    
    main_dict = get_main_dict()
    program = main_dict['program']

    if program == 'prod':
        prod.prod.start_server(main_dict)
        prod.prod.start_client(main_dict)

    elif program == 'dev':
        pass

    elif program == 'client_jupyter':
        client_jupyter.client_jupyter.start(main_dict)

    elif program == 'utils':
        # utils.utils.start(main_dict)
        pass
    
if __name__ == '__main__':
    main()

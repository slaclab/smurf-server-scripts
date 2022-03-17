import json
import os

import prod.prod

def get_smurf_dict():
    """Get dictionary of SMuRF's configuration. Called by main, used by
    Docker.

    """
    smurf_dict = {}

    json_path = 'smurf.json'

    if not os.path.isfile(json_path):
        print('smurf.py: No JSON found.')
    else:
        with open(json_path) as json_object:
            smurf_dict = json.loads(json_object.read())

    return smurf_dict

def main():
    """Start the SMuRF program as listed in smurf-json. This expects you
    have the necessary repos downloaded and packages installed for the
    given command.

    """
    
    smurf_dict = get_smurf_dict()
    program = smurf_dict['program']

    if program == 'prod':
        prod.prod.start_server(smurf_dict)
        prod.prod.start_client(smurf_dict)
    
if __name__ == '__main__':
    main()

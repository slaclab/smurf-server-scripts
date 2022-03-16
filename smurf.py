import json
import os

import prod.prod

def get_smurf_dict():
    smurf_dict = {}

    json_path = 'smurf.json'

    if not os.path.isfile(json_path):
        print('smurf.py: No JSON found.')
    else:
        with open(json_path) as json_object:
            smurf_dict = json.loads(json_object.read())

    return smurf_dict

def verify_smurf_dict(smurf_dict):
    return True

def main():
    smurf_dict = get_smurf_dict()

    if verify_smurf_dict(smurf_dict):
        if smurf_dict['program'] == 'prod':
            prod.prod.start_server(smurf_dict)
            
    else:
        print('verify_smurf_dict is False.')
    
if __name__ == '__main__':
    main()

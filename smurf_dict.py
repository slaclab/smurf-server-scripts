"""
Given the main.json turn it into dictionary and verify.
"""

import os
import json

def get(json_path):
    """
    Get dictionary of SMuRF's configuration. Called by smurf.py, used
    mostly by Docker for configuration variables.
    """
    
    smurf_dict = {}

    if not os.path.isfile(json_path):
        print('No JSON found.')
    else:
        with open(json_path) as json_object:
            smurf_dict = json.loads(json_object.read())

    return smurf_dict

def verify():
    pass

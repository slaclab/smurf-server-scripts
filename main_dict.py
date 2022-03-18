"""
Given the main.json turn it into dictionary and verify.
"""

import os
import json

def get():
    """
    Get dictionary of SMuRF's configuration. Called by main, used by
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

def verify():
    pass

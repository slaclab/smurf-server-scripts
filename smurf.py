import json
import argparse
import subprocess
import os
import sys

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('json_path', type=str, help='Fullpath to config json.')
    args = parser.parse_args()

    whatever_json = {}

    if not os.path.isfile(args.json_path):
        print('No whatever_json found.')
    else:
        with open(args.json_path) as json_fileobject:
            whatever_json = json.loads(json_fileobject)

    print(whatever_json)
    
if __name__ == '__main__':
    main()

import argparse
import subprocess
import os
import sys

import util.util

def list_dirs():
    software = []
    for f in os.listdir('.'):
        if os.path.isdir(f) and not f.startswith('.'):
            software.append(f)

    return software



if __name__ == '__main__':
    description = "Interact with SMuRF software."
    parser = argparse.ArgumentParser(description)
    parser.add_argument('--type', choices = list_dirs(), type = str)
    args = parser.parse_args()

    cwd = os.getcwd()

    if args.type == 'util':
        subprocess.call(util_call, shell = True)

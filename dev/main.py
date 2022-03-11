import argparse
import os
import sys
import subprocess

def add_subparser(subparsers):
    parser = subparsers.add_parser('dev', help = 'Development system')
    parser.add_argument('--run', dest = 'run', action = 'store_true')


def os_function(function_str):
    print('Running', function_str)
    return subprocess.call(function_str)

def kill_everything():
    os_function('killeverything')

def main():
    kill_everything()

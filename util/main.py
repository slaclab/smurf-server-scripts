import argparse

"""
os.system("some_command < input_file | another_command > output_file")  
print(os.popen("ls -l").read())
print subprocess.Popen("echo Hello World", shell=True, stdout=subprocess.PIPE).stdout.read()
print os.popen("echo Hello World").read()
return_code = subprocess.call("echo Hello World", shell=True)
subprocess.run
"""

def add_subparser(subparsers):
    parser = subparsers.add_parser('util', help = 'Utility software.')
    parser.add_argument('--run', dest = 'run', action = 'store_true')

def run():
    if args.run:
        print('yiz')
        subprocess.call(util_call, shell = True)

    util_call = 'docker run -it --rm  \
  --log-opt tag=utils \
  -u 1000:1001 \
  --net host \
  -e EPICS_CA_AUTO_ADDR_LIST=NO \
  -e EPICS_CA_ADDR_LIST=127.255.255.255 \
  -e EPICS_CA_MAX_ARRAY_BYTES=80000000 \
  -e DISPLAY \
  -v /etc/group:/etc/group:ro \
  -v /home/cryo/.bash_history:/home/cryo/.bash_history \
  -v /data:/data \
  tidair/smurf-base:R1.1.3'

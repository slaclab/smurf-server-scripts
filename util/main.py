import argparse

def main(args):
    description = "The utils software."
    parser = argparse.ArgumentParser(description)
    parser.add_argument('--run', dest = 'run', action = 'store_true')
    args = parser.parse_args(args)

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

  if args.run:
      print('yiz')

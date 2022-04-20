. runfunctions.sh

docker rm -f $(docker ps -a -q)
#start_timing
get_cfg
assert_fw
start_dev

firefox http://127.0.0.1:8888

docker container logs smurf_server_s${slot} -f

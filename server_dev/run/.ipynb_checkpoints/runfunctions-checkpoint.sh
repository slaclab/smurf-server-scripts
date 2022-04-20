# runfunctions.sh
# Should be capable of running the pysmurf client and server locally on your
# server. Use this to test local changes.

# Docker build uses .env for compilation. Conveniently put our variables in
# here as well.
. .env

start_timing() {
    # Start the TPG IOC docker and configure it.
    
    echo "Stopping the timing system."
    
    . ~/docker/tpg/R1.7.3-1.3.0/stop.sh

    echo "Starting the timing system."
    
    . ~/docker/tpg/R1.7.3-1.3.0/run.sh
    
    sleep 20
    
    . ~/smurf-tpg-ioc-docker/seq_program/run_100Hz.sh
}

assert_fw() {
    mcs_gz_exists=$(test -n $(find ../docker/server/local_files/ -maxdepth 1 -name '*.mcs.gz' -print -quit))
    
    # GitHub can access cryo-det and pull down the firmware .mcs.gz and .zip
    # files on its own, for the purpose of building the release versions. But
    # locally we don't have access unless the user has rights to cryo-det.

        if ! $mcs_gz_exists; then
        echo "No .mcs.gz file present in ../docker/server/local_files"
        echo "The server docker image needs its firmware .mcs.gz and .zip files."
        echo "You can get them from the cryo-det repo, just ask."
        exit 1
    fi
}

get_cfg() {
    # Duplicate of the function in pysmurf/docker/server/build.sh but
    # build.sh runs on the remote, not locally.
    
    . ../docker/server/definitions.sh
    rm -rf ../docker/server/local_files/smurf_cfg
    git -C ../docker/server/local_files clone ${config_repo} -b ${config_repo_tag} || exit 1
}

ping_after_restart() {
    ip=10.0.${crate_number}.$((${slot}+100))
    echo "Trying to ping ip ${ip}. Mean wait time is 30 seconds."
    while ! timeout 0.5 ping -c 1 -n ${ip} &> /dev/null; do
        printf "%c" "."
    done
    echo "Done."
}

restart_carrier() {
    # Preferably this is possible from within the server docker using
    # docker/server/scripts/server_common.sh but unfortunately the
    # docker container doesn't have any key or password to get into
    # the shelf manager shm-smrf-sp01.
    
    shelfmanager=shm-smrf-sp0${crate_number}
    deactivatecmd="$deactivatecmd clia deactivate board ${slot};"
    activatecmd="$activatecmd clia activate board ${slot};"

    echo "Deactivating carrier ${slot}"
    ssh root@${shelfmanager} "$deactivatecmd"

    echo "Waiting 5 sec before re-activating carrier"
    sleep 5

    echo "Activating carrier ${slot}"
    ssh root@${shelfmanager} "$activatecmd"

    # Force waiting for the slot to come online
    ping_after_restart 
}


run_dev() {
    # Build and run the pysmurf server and client. You should be able to
    # modify both the server and client Dockerfile in this repo on your own.

    docker-compose build smurf-server-dev
    docker-compose up -d smurf-server-dev
    
    docker-compose build smurf-client-dev
    docker-compose up -d smurf-client-dev
}

get_browser() {
    # After starting pysmurf, open up the browser to behold the Jupyter notebooks. But docker
    # containers cant open browsers of their host, so the best we can do is just spit the url.

    echo "Done. Open http://$(hostname):8888 remotely or with Firefox."
}

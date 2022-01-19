#!/bin/bash

function usage {
    echo "Interact with SMuRF systems.

Usage: [-c | -i | -r]
    	 
  -c : Configure the server's operating system (one-shot).
  -i : Install some type of SMuRF software.=
  -r : Run commands to interact with SMuRF.
"
    exit 1
}

script_dir=$(dirname -- "$(readlink -f $0)")

function goto_script {
    . $script_dir/$1
}

while getopts "ciur" opt; do
    case ${opt} in
	c)
	    goto_script configure/configure.sh $2
	    ;;
	i)
	    goto_script install/install.sh $2
	    ;;
	r)
	    goto_script run/run.sh $2
	    ;;
	\?)
	    usage
	    ;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    usage
fi

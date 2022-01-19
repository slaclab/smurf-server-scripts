#!/bin/bash

function usage {
    echo "Run some type of SMuRF software.
    	 
  -h : Help message. Use with -s, -d, or -r for particular help.
  -t type : Run the type of deployed instance.
"
    exit 1
}

script_dir=$(dirname -- "$(readlink -f $0)")
script_name=$(basename $0)

function goto_script {
    . $script_dir/$1
}

while getopts "hsdr" opt; do
    case ${opt} in
	h)
	    usage
	    ;;
	s)
	    goto_script setup/setup.sh $2
	    ;;
	d)
	    goto_script deploy/deploy.sh $2
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

#!/usr/bin/env bash

function usage {
	echo "Run or stop the SMuRF timing software.
Usage:
  -r : Run.
  -s : Stop."
}

if [ $# -eq 1 ]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case $1 in
	-r)
	    goto_script timing/run.sh
	    shift
	    ;;
	-s)
	    goto_script timing/stop.sh
	    shift
	    ;;
    esac
    shift
done

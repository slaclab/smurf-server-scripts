#!/usr/bin/env bash

function usage {
	echo "Run or stop utilities prompt.
Usage:
  -r : Run."
}

if [ $# -eq 1 ]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case $1 in
	-r)
	    goto_script util/run.sh
	    shift
	    ;;
    esac
    shift
done

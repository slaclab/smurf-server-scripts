#!/bin/bash

function usage {
    echo "Interact with SMuRF software.
Usage: 
  -t type : 
    - system : Production software, with fixed pysmurf, rogue, and firmware.
    - system-dev : 'system' with modifiable pysmurf, rogue, and firmware.
    - timing : Fiber-based timing software.
    - util : Utilities prompt.
  -c : Configure the server's operating system.
  -v : Get version of smurf.sh.
  -l : List versions of smurf.sh.
  -u version : Upgrade smurf.sh to version."
}

top_dir=$(dirname -- "$(readlink -f $0)")

function error {
	echo "smurf.sh: Error: $1"
	exit 1
}

function list_versions {
    # Just list the tags associated with the repo. This is
    # necessary for listing versions to install.  Print all
    # the available tags in a remote repository, pointed by
    # passed argument ($1) Only the tag names are printed,
    # and they are sorted from high to low.  The second
    # argument is optional, and defines string to be excluded
    # (for example 'v1.' to exclude all v1.* versions)
    # $1 String for URL repo
    # $2 String for exclusion regex

    local repo=$1
    local exclude=$2

    if [ ${exclude} ]; then
        git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep -v ${exclude} | sort --version-sort
    else
        git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | sort --version-sort
    fi
}

# Verify if a tag exist in a remote repository
# $1 repository url,
# $2 tag
# $3 exclusion regex
function verify_git_tag_exist {
    local repo=$1
    local tag=$2
    local exclude=$3

    if [ ${exclude} ]; then
        local match=$(git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep -v ${exclude} | grep -P ^${tag}$)
    else
        local match=$(git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep -P ^${tag}$)
    fi

    echo ${match}
}

script_dir=$(dirname -- "$(readlink -f $0)")

function goto_script {
    echo "Go to script $1 with args ${@:1}"
    source $script_dir/$1 "${@:1}"
}

function update_self {
    # $1 Ref to update this repository to. e.g. R3.10.2 or main.

    local tag=$1

    cd ${top_dir}
    
    if [ -z ${tag} ]; then
	    error "No tag specified."
    fi

    bash -c "git fetch --all --tags && git checkout ${tag}"
    ret=$?

    cd - > /dev/null

    if [ ${ret} == 0 ]; then
        echo "Finished updating scripts in ${top_dir}."
    else
        echo "Failed updating."
    fi

    exit ${ret}
}

if [ $# -eq 0 ]; then
    usage
fi

# While the number of args is greater than 0, parse the first
# arg $1, second arg $2, etc. It's generally good practice to
# shift as soon as you can throw away the argument.
while [[ $# -gt 0 ]]; do
    case $1 in
	-t)
	    # e.g. smurf.sh -t system -r -v v5.0.4,
	    # then goto_script system/system.sh -r -v v5.0.4
	    type=$2
	    shift; shift;
	    goto_script $type/$type.sh $@
	    ;;
	-c)
	    goto_script configure/configure.sh
	    ;;
	-v)
            version=$(git describe --tags --always --dirty)
	    echo $version
	    ;;
	-l)
            list_versions 'https://github.com/slaclab/smurf-server-scripts.git' 'R1.\|R2.\|R3.0'
	    ;;
	-u)
            update_self $2
	    shift
	    ;;
    esac
    shift
done

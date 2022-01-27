#!/bin/bash

# Top level script for SMuRF software. The bash scripts
# are organized binary-tree style. Useful reading:
# - https://tldp.org/LDP/abs/html/comparison-ops.html
# - http://linuxsig.org/files/bash_scripting.html

version=$(git describe --tags --always --dirty)
top_dir=$(dirname -- "$(readlink -f $0)")

function usage {
    echo "Interact with SMuRF systems.
Git version: ${version}
Usage: [-c | -i | -r | -l | -u version]
    	 
  -c : Configure the server's operating system.
  -i : Install some type of SMuRF software.
  -r : Run some type of SMuRF software.
  -s : Stop some type of SMuRF software.
  -l : List versions of the SMuRF scripts.
  -u version : Upgrade the SMuRF scripts to version.
"
}

function error {
	echo "Error: $1"
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
    echo "Go to script $1 with args ${@:2}"
    source $script_dir/$1 "${@:2}"
}

function update_self {
    # $1 Tag to update this repository to.

    local tag="$1"

    cd ${top_dir}
    
    if [ -z ${tag} ]; then
        echo "No reference specified. Using branch main of ${server_scripts_git_repo}. Use -l if you want some specific version."
        sudo bash -c "git fetch --all --tags && git checkout main && git pull"
    else
        echo "Updating to version ${tag} of ${server_scripts_git_repo}."
        sudo bash -c "git fetch --all --tags && git checkout ${tag}"
    fi

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

while [[ $# -gt 0 ]]; do
    arg=$1

    case ${arg} in
	-h)
	    usage
	    ;;
	-c)
	    goto_script configure/configure.sh
	    ;;
	-i)
            goto_script install/install.sh "${@:2}"
	    ;;
	-r)
	    goto_script run/run.sh "${@:2}"
	    ;;
	-l)
            list_versions 'https://github.com/slaclab/smurf-server-scripts.git' 'R1.\|R2.\|R3.0'
	    ;;
	-u)
            update_self
	    ;;
    esac
    shift
done

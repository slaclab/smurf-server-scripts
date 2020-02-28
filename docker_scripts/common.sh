#!/usr/bin/env bash

# This script contains common functions to all scrips

# Print all the available tags in a remote repository, pointed by passed argument ($1)
# Only the tag names are printed, and they are sorted from high to low.
print_git_tags()
{
    git ls-remote --tags --refs $1 | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | sort -g -t. -r
}

# Verify if a tag exist in a remote repository
# The first argument is the repository url,
# The second argument is the tag
verify_git_tag_exist()
{
	local repo=$1
	local tag=$2

	git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep ${tag}

	echo $?
}
#!/usr/bin/env bash

# This script contains common functions to all scrips

# Print all the available tags in a remote repository, pointed by passed argument ($1)
# Only the tag names are printed, and they are sorted from high to low.
print_git_tags()
{
    git ls-remote --tags --refs $1 | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | sort -g -t. -r
}
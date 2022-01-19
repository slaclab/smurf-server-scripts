#!/usr/bin/env bash

# Print all the available tags in a remote repository, pointed by passed argument ($1)
# Only the tag names are printed, and they are sorted from high to low.
# The second argument is optional, and defines string to be excluded (for example 'v1.' to exclude all v1.* versions)
print_git_tags()
{
    local repo=$1
    local exclude=$2

    if [ ${exclude} ]; then
        git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep -v ${exclude} | sort --version-sort
    else
        git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | sort --version-sort
    fi
}

# Verify if a tag exist in a remote repository
# The first argument is the repository url,
# The second argument is the tag
# The third argument is optional, and defines string to be excluded (for example 'v1.' to exclude all v1.* versions)
verify_git_tag_exist()
{
    local repo=$1
    local tag=$2
    local exclude=$3

    if [ ${exclude} ]; then
        local macth=$(git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep -v ${exclude} | grep -P ^${tag}$)
    else
        local macth=$(git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep -P ^${tag}$)
    fi

    echo ${macth}
}

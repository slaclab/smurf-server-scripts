#!/usr/bin/env bash

get_all_dockerhub_tags() {
    local repo_name="$1"
    local tags=()
    local page=1

    while true; do
        local url="https://hub.docker.com/v2/repositories/$repo_name/tags/?page=$page"
        local response=$(curl -s "$url")
        local tag_names=$(echo "$response" | jq -r '.results[].name')

        readarray -t tag_array <<< "$tag_names"
        tags+=("${tag_array[@]}")

        local next_url=$(echo "$response" | jq -r '.next')
        if [ "$next_url" = "null" ]; then
            break
        fi

        page=$((page + 1))
    done

    echo "${tags[@]}"
}

check_dockerhub_tag() {
    local repo_name="$1"
    local tag_to_check="$2"
    local all_tags=($(get_all_dockerhub_tags "tidair/$repo_name"))

    for tag in "${all_tags[@]}"; do
	if [ "$tag" = "$tag_to_check" ]; then
            #echo "Tag '$tag_to_check' found in DockerHub repository 'tidair/$repo_name'"
            return 0
        fi
    done

    #echo "Tag '$tag_to_check' not found in Dockerhub"
    return 1
}

get_docker_image_address() {
    local repo="$1"
    local tag="$2"

    if check_dockerhub_tag "$1" "$2"; then
        echo "tidair/${repo}"
    else
        # Currently, ghcr.io container registry repos are private, so
        # assuming that if the image isn't in dockerhub, it's in the
        # GitHub Container Registry.
	if [ "$repo" == "pysmurf-server" ]; then # renamed in ghcr.io
            echo "ghcr.io/slaclab/${repo}-base"
	else # same name
            echo "ghcr.io/slaclab/${repo}"
	fi
    fi
}

# For comparing semantic versions.
function semver_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function semver_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function semver_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function semver_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

# Print all the available tags in a remote repository, pointed by passed argument ($1)
# Only the tag names are printed, and they are sorted from high to low.
# The second argument is optional, and defines string to be excluded (for example 'v1.' to exclude all v1.* versions)
print_git_tags()
{
    local repo=$1
    local full=${2:-false}
    local exclude=$3

    echo "repo=$repo"

    if [ ${exclude} ]; then
        git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | grep -v ${exclude} | sort --version-sort | (if [ "$full" = true ]; then cat; else grep -E '^[vR][0-9]+(\.[0-9]+){2}$'; fi)
    else
        git ls-remote --tags --refs ${repo} | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' | sort --version-sort | (if [ "$full" = true ]; then cat; else grep -E '^[vR][0-9]+(\.[0-9]+){2}$'; fi)
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

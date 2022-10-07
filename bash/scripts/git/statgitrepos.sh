#!/usr/bin/env bash

set -e

_description_="Return statuts of git repos in ~/Work/git"
_author_="Choops <choopsbd@gmail.com>"

DEF="\e[0m"
RED="\e[31m"
GRN="\e[32m"
YLO="\e[33m"
CYN="\e[36m"

ERR="${RED}ERR${DEF}:"
OK="${GRN}OK${DEF}:"
WRN="${YLO}WRN${DEF}:"
NFO="${CYN}NFO${DEF}:"


usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${_description_}${DEF}"
    echo -e "${CYN}Usage${DEF}:"
    echo -e "  $(basename "$0") [OPTION]"
    echo -e "${CYN}Options${DEF}:"
    echo -e "  -h,--help: Print this help"
    echo

    exit "${errcode}"
}

get_status(){
    git_folder="$1"
    echo -e "${CYN}Repo${DEF}: ${YLO}$(basename "${git_folder}")${DEF}"

    pushd "${git_folder}" > /dev/null

    last_commit="$(git show | awk '/^Date:/ {print $2 " " $3 " " $4 " " $6 " " $5}')"
    commits_count="$(git rev-list --all --count)"
    echo -e "${CYN}Last commit${DEF}: ${last_commit} (${commits_count})"

    status="$(git status -s)"
    if [[ ${status} ]]; then
        echo -e "${YLO}Uncommited changes${DEF}:"
        git status -s
    else
        echo -e "${GRN}Up to date${DEF}"
    fi
    echo

    popd > /dev/null
}

if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo -e "${ERR} Bad argument" && usage 1
fi

git_stock="${HOME}"/Work/git
[[ ! -d "${git_stock}" ]] &&
    echo -e "${ERR} ${git_stock} does not exist\n" && exit 1

for folder in "${git_stock}"/*; do
    [[ -d "${folder}"/.git ]] && get_status "${folder}"
done

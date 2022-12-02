#!/usr/bin/env bash

set -e

description="Install/Update WhiteSur cursors"
# version: 0.1
# author: Choops <choopsbd@gmail.com>

DEF="\e[0m"
RED="\e[31m"
GRN="\e[32m"
YLO="\e[33m"
CYN="\e[36m"
GRY="\e[37m"

ERR="${RED}ERR${DEF}:"
OK="${GRN}OK${DEF}:"
WRN="${YLO}WRN${DEF}:"
NFO="${CYN}NFO${DEF}:"

THEMES_DIR=/usr/share/icons

cursors=WhiteSur-cursors
git_url="https://github.com/vinceliuice/WhiteSur-cursors.git"


usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${description}${DEF}"
    echo -e "${CYN}Usage${DEF}:"
    echo -e "  $(basename "$0") [OPTION]"
    echo -e "${CYN}Options${DEF}:"
    echo -e "${NFO} No option => install ${cursors}"
    echo -e "  -h,--help:   Print this help"
    echo -e "  -r,--remove: Remove ${cursors}"
    echo

    exit "${errcode}"
}

bye_cursors(){
    echo -e "${NFO} Removing ${cursors}..."
    sudo rm -rf "${THEMES_DIR}"/WhiteSur*
}

byebye_cursors(){
    [[ ! -d "${THEMES_DIR}" ]] && echo -e "${NFO} ${cursors} is not installed\n" && exit 0
    bye_cursors
    echo
    exit 0
}

hello_cursors(){
    echo -e "${NFO} Installing/Updating ${cursors}..."
    sudo rm -rf /tmp/"${cursors}"
    git clone "${git_url}" /tmp/"${cursors}"
    pushd /tmp/"${cursors}" >/dev/null
    sudo ./install.sh
    popd >/dev/null
    echo
}


[[ $1 =~ ^-(h|-help)$ ]] && usage 0

(groups | grep -qv sudo) && echo -e "${ERR} Need 'sudo' rights" && exit 1

[[ $1 =~ ^-(r|-remove)$ ]] && byebye_cursors

[[ $1 ]] && echo -e "${error} Bad argument" && usage 1

bye_cursors
hello_cursors

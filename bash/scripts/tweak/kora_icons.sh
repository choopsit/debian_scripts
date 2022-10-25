#!/usr/bin/env bash

set -e

_description_="Install/Update Kora icon-theme"
_author_="Choops <choopsbd@gmail.com>"

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

ICONS_DIR=/usr/share/icons


usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${_description_}${DEF}"
    echo -e "${CYN}Usage${DEF}:"
    echo -e "  $(basename "$0") [OPTION]"
    echo -e "${CYN}Options${DEF}:"
    echo -e "${NFO} No option => install Kora icon-theme"
    echo -e "  -h,--help:   Print this help"
    echo -e "  -r,--remove: Remove Kora icon-theme"
    echo

    exit "${errcode}"
}

bye_kora(){
    echo -e "${NFO} Removing Kora icon-theme..."
    sudo rm -rf "${ICONS_DIR}"/kora
}

byebye_kora(){
    [[ ! -d "${ICONS_DIR}"/kora ]] && echo -e "${NFO} Kora icon-theme is not installed\n" && exit 0
    bye_kora
    echo
    exit 0
}

hello_kora(){
    tmp_dir=/tmp
    git_url="https://github.com/bikass/kora.git"

    echo -e "${NFO} Installing/Updating Kora icon-theme..."
    sudo rm -rf "${tmp_dir}"/kora
    git clone "${git_url}" "${tmp_dir}"/kora
    sudo cp -r "${tmp_dir}"/kora/kora "${ICONS_DIR}"/
    echo
}


[[ $1 =~ ^-(h|-help)$ ]] && usage 0

(groups | grep -qv sudo) && echo -e "${ERR} Need 'sudo' rights" && exit 1

[[ $1 =~ ^-(r|-remove)$ ]] && byebye_kora

[[ $1 ]] && echo -e "${error} Bad argument" && usage 1

bye_kora
hello_kora

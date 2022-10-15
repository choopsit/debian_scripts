#!/usr/bin/env bash

description="Deploy my personal base configuration"
author="Choops <choopsbd@gmail.com>"

set -e

DEF="\e[0m"
RED="\e[31m"
GRN="\e[32m"
YLO="\e[33m"
CYN="\e[36m"

ERR="${RED}ERR${DEF}:"
OK="${GRN}OK${DEF}:"
WRN="${YLO}WRN${DEF}:"
NFO="${CYN}NFO${DEF}:"

SCRIPT_PATH="$(dirname "$(realpath "$0")")"


usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${description}${DEF}" &&
        echo -e "${WRN} It's a combination of personal choices. Use it at your own risk."

    echo -e "${CYN}Usage${DEF}:"
    echo -e "  ./$(basename "$0") [OPTION]"
    echo -e "  ${WRN} Must be run by 'root' or a normal user, not using 'sudo'"
    echo -e "${CYN}Options${DEF}:"
    echo -e "  -h,--help: Print this help"
    echo

    exit "${errcode}"
}


[[ $2 ]] && echo -e "${ERR} Too many arguments" && usage 1
[[ $1 =~ ^-(h|-help)$ ]] && usage 0 ||
    { [[ $1 ]] && echo -e "${ERR} Bad argument" && usage 1; }

if [[ $(whoami) == root ]]; then
    [[ ${SUDO_USER} ]] &&
    echo -e "${ERR} This script must be run by 'root' or a normal user, not using 'sudo'" &&
    exit 1

    echo -e "${WRN} Launched by root, this script only apply 'root' config (bash and vim for 'root')"
    ok_root=y
    read -rp "Continue [Y/n] ? " -n1 ok_root
    [[ ${ok_root} ]] && echo
    [[ ${ok_root} == n ]] && exit 0
fi

source "${CRIPT_PATH}"/bash.sh
source "${CRIPT_PATH}"/vim.sh

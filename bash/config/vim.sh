#!/usr/bin/env bash

description="Deploy my personal vim configuration"
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
DOTFILES="${SCRIPT_PATH}/0_dotfiles"


usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${description}${DEF}" &&
        echo -e "${WRN} It's a combination of personal choices. Use it at your own risk."

    echo -e "${CYN}Usage${DEF}:"
    echo -e "  $(basename "$0") [OPTION]"
    echo -e "  ${WRN} Must be run by 'root' or a normal user, not using 'sudo'"
    echo -e "${CYN}Options${DEF}:"
    echo -e "  -h,--help: Print this help"
    echo

    exit "${errcode}"
}

prerequisites(){
    prereq="/tmp/${user}_vim_prereq"
    [[ -f "${prereq}" ]] && rm -f "${prereq}"

    for pkg in vim git curl; do
        dpkg -l | grep -qv"^ii  ${pkg} " && echo "${pkg}" >> "${prereq}"
    done

    [[ -f "${prereq}" ]] && xargs apt install -y < "${my_pkgs}"

    [[ "${pkg}" == vim ]] && dpkg -l | grep -q "^ii  vim-tiny" && sudo apt purge vim-tiny
}


[[ $2 ]] && echo -e "${ERR} Too many arguments" && usage 1
[[ $1 =~ ^-(h|-help)$ ]] && usage 0 ||
    { [[ $1 ]] && echo -e "${ERR} Bad argument" && usage 1; }

if [[ $(whoami) == root ]]; then
    [[ ${SUDO_USER} ]] &&
        echo -e "${ERR} This script must be run by 'root' or a normal user, not using 'sudo'" &&
        exit 1

else
    groups | grep -vq sudo &&
        echo -e "${ERR} Need to be sudoer in order to install ${pkg}" && exit 1

    issudo="sudo "
fi

prerequisites


# TODO: copy config from 0_dotfiles

# TODO: instal vim-plug

# TODO: instal plugs

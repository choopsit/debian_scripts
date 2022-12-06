#!/usr/bin/env bash

set -e

description="Install/Update WhiteSur icon-theme"
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

icon_theme=WhiteSur-icon-theme
git_url="https://github.com/vinceliuice/WhiteSur-icon-theme.git"


usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${description}${DEF}"
    echo -e "${CYN}Usage${DEF}:"
    echo -e "  $(basename "$0") [OPTION]"
    echo -e "${CYN}Options${DEF}:"
    echo -e "${NFO} No option => install ${icon_theme}"
    echo -e "  -h,--help:   Print this help"
    echo -e "  -r,--remove: Remove ${icon_theme}"
    echo

    exit "${errcode}"
}

bye_icon(){
    echo -e "${NFO} Removing ${icon_theme}..."
    sudo rm -rf "${THEMES_DIR}"/WhiteSur*
}

byebye_icon(){
    [[ ! -d "${THEMES_DIR}" ]] && echo -e "${NFO} ${icon_theme} is not installed\n" && exit 0
    bye_icon
    echo
    exit 0
}

hello_icon(){
    echo -e "${NFO} Installing/Updating ${icon_theme}..."
    pkg_list=/tmp/pkglist
    rm -f "${pkg_list}"
    for pkg in sassc optipng libglib2.0-dev-bin; do
        (dpkg -l | grep -q "^ii  ${pkg} ") || echo "${pkg}" >>"${pkg_list}"
    done
    [[ -f "${pkg_list}" ]] && sudo xargs apt install -y < "${pkg_list}"
    sudo rm -rf /tmp/"${icon_theme}"
    git clone "${git_url}" /tmp/"${icon_theme}"
    sudo /tmp/"${icon_theme}"/install.sh --black -b
    echo
}


[[ $1 =~ ^-(h|-help)$ ]] && usage 0

(groups | grep -qv sudo) && echo -e "${ERR} Need 'sudo' rights" && exit 1

[[ $1 =~ ^-(r|-remove)$ ]] && byebye_icon

[[ $1 ]] && echo -e "${error} Bad argument" && usage 1

bye_icon
hello_icon

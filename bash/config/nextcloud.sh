#!/usr/bin/env bash

description="Deploy nextcloud server"
# version: 0.1
# author: Choops <choopsbd@gmail.com>

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

STABLE=bullseye
TESTING=bookworm

usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${description}${DEF}"

    echo -e "${CYN}Usage${DEF}:"
    echo -e "  ./$(basename "$0") [OPTION]"
    echo -e "  ${WRN} Must be run as 'root' or using 'sudo'"
    echo -e "${CYN}Options${DEF}:"
    echo -e "  -h,--help: Print this help"
    echo

    exit "${errcode}"
}

stable_sources(){
    cat <<EOF > /etc/apt/sources.list
# ${STABLE}
deb http://deb.debian.org/debian/ ${STABLE} main contrib non-free
#deb-src http://deb.debian.org/debian/ ${STABLE} main contrib non-free
# ${STABLE} security
deb http://deb.debian.org/debian-security/ ${STABLE}-security/updates main contrib non-free
#deb-src http://deb.debian.org/debian-security/ ${STABLE}-security/updates main contrib non-free
# ${STABLE} volatiles
deb http://deb.debian.org/debian/ ${STABLE}-updates main contrib non-free
#deb-src http://deb.debian.org/debian/ ${STABLE}-updates main contrib non-free
# ${STABLE} backports
deb http://deb.debian.org/debian/ ${STABLE}-backports main contrib non-free
#deb-src http://deb.debian.org/debian/ ${STABLE}-backports main contrib non-free
EOF
}

testing_sources(){
    cat <<EOF > /etc/apt/sources.list
# testing
deb http://deb.debian.org/debian/ testing main contrib non-free
#deb-src http://deb.debian.org/debian/ testing main contrib non-free

# testing security
deb http://deb.debian.org/debian-security/ testing-security/updates main contrib non-free
#deb-src http://deb.debian.org/debian-security/ testing-security/updates main contrib non-free
EOF
}

sid_sources(){
    cat <<EOF > /etc/apt/sources.list
# sid
deb http://deb.debian.org/debian/ sid main contrib non-free
#deb-src http://deb.debian.org/debian/ sid main contrib non-free
EOF
}

clean_sources(){
    version="$1"
    echo -e "${NFO} Cleaning sources.list..."
    if [[ ${version} == sid ]]; then
        sid_sources
    elif [[ ${version} == "${STABLE}" ]]; then
        stable_sources
    elif [[ ${version} == "${TESTING}" ]]; then
        testing_sources
    else
        echo -e "${ERR} Unsupported version '${version}'"
        exit 1
    fi
}

sys_update(){
    echo -e "${NFO} Upgrading system..."
    apt update || { echo -e "${RED}WTF !!!${DEF}" && exit 1; }
    apt upgrade -y
    apt full-upgrade -y
}


install_nextcloud(){
    echo -e "${NFO} Installing new packages..."
    usefull=/tmp/usefull_pkgs
    pkg_lists="${SCRIPT_PATH}"/1_pkg

    cp "${pkg_lists}"/nextcloud "${usefull}"

    xargs apt install -y < "${usefull}"

    apt autoremove --purge -y
}

copy_conf(){
    if [[ -f "$1" ]]; then
        cp "$1" "$2"/."$(basename "$1")"
    elif [[ -d "$1" ]]; then
        mkdir -p  "$2"/."$(basename "$1")" &&
            cp -r "$1"/* "$2"/."$(basename "$1")"/

        [[ $(basename "$1") == vim ]] && vim +PlugInstall +qall
    fi
}

configure_nextcloud(){
    # TODO: define nextcloud configuration
}

sys_config(){
    echo -e "${NFO} Applying custom system configuration..."

    for dotfile in "${SCRIPT_PATH}"/0_dotfiles/root/*; do
        copy_conf "${dotfile}" /root
    done

    if [[ ${allow_root_ssh,,} == y ]]; then
        [[ -d "${ssh_conf}".d ]] || mkdir -p "${ssh_conf}".d
        echo "PermitRootLogin yes" > "${ssh_confroot}"
        systemctl restart ssh
    fi
}


[[ $2 ]] && echo -e "${ERR} Too many arguments" && usage 1
if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo -e "${ERR} Bad argument" && usage 1
fi

[[ $(whoami) != root ]] && echo -e "${ERR} Need higher privileges" && exit 1

my_dist="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
[[ ${my_dist} != debian ]] &&
    echo -e "${ERR} $(basename "$0") works only on Debian" && exit 1

debian_version="$(lsb_release -sc)"
if [[ ${debian_version} == "${TESTING}" ]]; then
    for vers in sid unstable; do
        grep -q "^deb .*${vers}" /etc/apt/sources.list && debian_version=sid
    done
fi

read -rp "Clean sources.list [y/N] ? " -n1 clean_sl
[[ ${clean_sl} ]] && echo

ssh_conf=/etc/ssh/sshd_config
ssh_confroot="${ssh_conf}".d/allow_root.conf
(grep -q ^"PermitRootLogin yes" "${ssh_conf}") || [[ -f "${ssh_confroot}" ]] ||
    read -rp "Allow 'root' on ssh [y/N] ? " -n1 allow_root_ssh

[[ ${allow_root_ssh} ]] && echo

[[ ${clean_sl,,} == y ]] && clean_sources "${debian_version}"

sys_update

install_nextcloud

sys_config

echo -e "${OK} Nextcloud installed"

configure_nextcloud

echo -e "${OK} Nextcloud installed and configured"

read -rp "Reboot now and enjoy [Y/n] ? " -n1 reboot_now

[[ ${reboot_now} ]] && echo
[[ ${reboot_now,,} == n ]] || reboot


#!/usr/bin/env bash

description="Debian server base configuration"
# version: 0.2
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

install_prerequisites(){
    echo -e "${NFO} Installing new packages..."
    usefull=/tmp/usefull_pkgs
    pkg_lists="${SCRIPT_PATH}"/1_pkg

    cp "${pkg_lists}"/srv_base "${usefull}"

    xargs apt install -y < "${usefull}"

    apt autoremove --purge -y
}

copy_conf(){
    src="$1"
    dst="$2"

    if [[ -f "${src}" ]]; then
        cp "${src}" "${dst}"/."$(basename "${src}")"
    elif [[ -d "${src}" ]]; then
        mkdir -p  "${dst}"/."$(basename "${src}")" &&
            cp -r "${src}"/* "${dst}"/."$(basename "${src}")"/

        [[ $(basename "${src}") == vim ]] && vim +PlugInstall +qall
    fi
}

disable_ipv6(){
    echo -e "${NFO} Disabling ipv6..."

    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.all.autoconf=0

    cat <<EOF >"${noipv6_conf}"
# disable ipv6 for all interfaces
net.ipv6.conf.all.disable_ipv6 = 1
# disable ipv6 auto-configuration for all interfaces
net.ipv6.conf.all.autoconf = 0
# disable ipv6 for new interfaces
net.ipv6.conf.default.disable_ipv6 = 1
# disable ipv6 auto-configuration for new interfaces
net.ipv6.conf.default.autoconf = 0
EOF
}

set_network(){
    echo -e "${NFO} Editing '/etc/network/interfaces'..."

    vim /etc/network/interfaces
}

sys_config(){
    echo -e "${NFO} Applying custom system configuration..."

    for dotfile in "${SCRIPT_PATH}"/0_dotfiles/root/*; do
        copy_conf "${dotfile}" /root
    done

    curl -sSfLo /root/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    vim +PlugInstall +qall

    if [[ ${root_ssh,,} == y ]]; then
        mkdir -p "${ssh_conf}".d
        echo "PermitRootLogin yes" > "${ssh_conf}".d/allow_root.conf
        systemctl restart ssh
    fi

    [[ ${new_hostname} ]] && renew_hostname
    [[ ${no_ipv6,,} == y ]] && disable_ipv6
    [[ ${conf_net,,} == y ]] && set_network
}


# Arguments check
[[ $2 ]] && echo -e "${ERR} Too many arguments" && usage 1
if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo -e "${ERR} Bad argument" && usage 1
fi

# Privileges check
[[ $(whoami) != root ]] && echo -e "${ERR} Need higher privileges" && exit 1

# Distro check
my_dist="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
[[ ${my_dist} != debian ]] &&
    echo -e "${ERR} $(basename "$0") works only on Debian" && exit 1

debian_version="$(lsb_release -sc)"
if [[ ${debian_version} == "${TESTING}" ]]; then
    for vers in sid unstable; do
        grep -q "^deb .*${vers}" /etc/apt/sources.list && debian_version=sid
    done
fi
if [[ ${debian_version} != "${STABLE}" ]]; then
    echo -e "${WRN} You are not using Debian stable. Script can fail."
    read -rp "Continue [y/N] ? " -n1 lets_go
    [[ ${lets_go} ]] && echo
    [[ ${lets_go,,} != y ]] && exit 0
fi

# Questioning
read -rp "Change hostname [y/N] ? " -n1 chg_hostname
[[ ${chg_hostname} ]] && echo
if [[ ${chg_hostname,,} == y ]]; then
    read -rp "New hostname: " new_hostname
    [[ ${new_hostname} ]] && read -rp "New domain (optional): " new_domain
    [[ -z ${new_hostname} ]] && echo -e "${NFO} No hostname given. Keeping current one."
fi

read -rp "Clean sources.list [y/N] ? " -n1 clean_sl
[[ ${clean_sl} ]] && echo

noipv6_conf=/etc/sysctl.d/10-noipv6.conf
[[ -f "${noipv6_conf}" ]] || read -rp "Disable ipv6 [y/N] ? " -n1 no_ipv6
[[ ${no_ipv6} ]] && echo

read -rp "Configure network interface(s) [y/N] ? " -n1 conf_net
[[ ${conf_net} ]] && echo

ssh_conf=/etc/ssh/sshd_config
if [[ -f "${ssh_conf}" ]]; then
    (grep -qv ^"PermitRootLogin yes" "${ssh_conf}") ||
        (grep -qv ^"PermitRootLogin yes" "${ssh_conf}".d/*) ||
        read -rp "Allow 'root' on ssh [y/N] ? " -n1 root_ssh
fi
[[ ${root_ssh} ]] && echo

# Installation and configuration
[[ ${clean_sl,,} == y ]] && clean_sources "${debian_version}"
sys_update
install_prerequisites
sys_config

# Exit
echo -e "${NFO} Base configuration deployed"
read -rp "Reboot now [y/N] ? " -n1 reboot_now
[[ ${reboot_now} ]] && echo
[[ ${reboot_now,,} == y ]] && reboot

echo -e "${GRN}Enjoy !${DEF}"

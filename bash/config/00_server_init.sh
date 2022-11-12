#!/usr/bin/env bash

description="Debian server base configuration"
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


usage(){
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo -e "${CYN}${description}${DEF}" &&
        echo -e "${WRN} It's a combination of personal choices. Use it at your own risk."

    echo -e "${CYN}Usage${DEF}:"
    echo -e "  ./$(basename "$0") [OPTION]"
    echo -e "  ${WRN} Must be run as 'root' or using 'sudo'"
    echo -e "${CYN}Options${DEF}:"
    echo -e "  -h,--help: Print this help"
    echo

    exit "${errcode}"
}

renew_hostname(){
    echo -e "${NFO} Renaming..."

    current_hostname="$(hostname -s)"
    current_fqdn="$(hostname -f)"

    if [[ ${new_domain} ]]; then
        host_line="127.0.1.1\t${new_hostname}.${new_domain}\t${new_hostname}"
    else
        host_line="127.0.1.1\t${new_hostname}"
    fi

    sed "s/^127.0.1.1.*${current_hostname}/${host_line}/" -i /etc/hosts
    echo "${new_hostname}" >/etc/hostname

    hostname "${new_hostname}"
}

clean_sources(){
    echo -e "${NFO} Cleaning /etc/apt/sources.list..."

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

install_base(){
    echo -e "${NFO} Updating and installing base packages..."

    apt update
    apt full-upgrade

    rm -f /tmp/pkgs
    for pkg in vim git ssh curl tree htop; do
        (dpkg -l | grep -q "^ii  ${pkg} ") || echo "${pkg}" >>/tmp/pkgs
    done

    if [[ -f /tmp/pkgs ]]; then
        xargs apt install -y </tmp/pkgs
    fi
}

root_conf(){
    echo -e "${NFO} Deploying 'root' dotfiles..."

    for conf in "${SCRIPT_PATH}"/0_dotfiles/root/*; do
        cp -r "${conf}" /root/."$(basename "${conf}")"
    done

    echo -e "${NFO} Loading vim plugins..."

    curl -sSfLo /root/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    vim +PlugInstall +qall
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

allow_rot_on_ssh(){
    [[ -d "${ssh_conf}".d ]] || mkdir -p "${ssh_conf}".d
    echo "PermitRootLogin yes" > "${ssh_confroot}"
    systemctl restart ssh
}


[[ $2 ]] && echo -e "${ERR} Too many arguments" && usage 1
if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo -e "${ERR} Bad argument" && usage 1
fi


[[ $(whoami) != root ]] && echo -e "${ERR} Need higher privileges." && exit 1

my_dist="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
[[ ${my_dist} != debian ]] &&
    echo -e "${ERR} '$(basename "$0")' works only on Debian." && exit 1

debian_version="$(lsb_release -sc)"
[[ ${debian_version} != "${STABLE}" ]] &&
    echo -e "${ERR} '$(basename "$0")' works only on Debian ${STABLE} (stable)." && exit 1


read -rp "Change hostname [y/N] ? " -n1 chg_hostname
[[ ${chg_hostname} ]] && echo
if [[ ${chg_hostname,,} == y ]]; then
    read -rp "New hostname: " new_hostname
    [[ ${new_hostname} ]] && read -rp "New domain (optional): " new_domain
    [[ -z ${new_hostname} ]] && echo -e "${NFO} No hostname given. Keeping current one."
fi

noipv6_conf=/etc/sysctl.d/10-noipv6.conf
[[ -f "${noipv6_conf}" ]] || read -rp "Disable ipv6 [y/N] ? " -n1 no_ipv6
[[ ${no_ipv6} ]] && echo

read -rp "Configure network interface(s) [y/N] ? " -n1 conf_net
[[ ${conf_net} ]] && echo

ssh_conf=/etc/ssh/sshd_config
ssh_confroot="${ssh_conf}".d/allow_root.conf
(grep -q ^"PermitRootLogin yes" "${ssh_conf}") || [[ -f "${ssh_confroot}" ]] ||
    read -rp "Allow root on ssh [y/N] ? " -n1 root_ssh

[[ ${root_ssh} ]] && echo


clean_sources
install_base

root_conf


[[ ${new_hostname} ]] && renew_hostname
[[ ${no_ipv6,,} == y ]] && disable_ipv6
[[ ${conf_net,,} == y ]] && set_network
[[ ${root_ssh,,} == y ]] && allow_root_on_ssh


echo -e "${NFO} Base configuration deployed"
read -rp "Reboot now [y/N] ? " -n1 reboot_now
[[ ${reboot_now} ]] && echo
[[ ${reboot_now,,} == y ]] && reboot

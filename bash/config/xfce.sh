#!/usr/bin/env bash

description="Deploy my personal xfce configuration"
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

install_xfce(){
    echo -e "${NFO} Installing new packages then removing useless ones..."
    usefull=/tmp/usefull_pkgs
    useless=/tmp/useless_pkgs
    pkg_lists="${SCRIPT_PATH}"/1_pkg

    cp "${pkg_lists}"/base "${usefull}"
    cp "${pkg_lists}"/useless "${useless}"

    add_i386=n

    [[ ${debian_version} == sid ]] &&
        echo -e "firefox\napt-listbugs\nneedrestart" >> "${usefull}" &&
        echo -e "firefox-esr\nzutty" >> "${useless}"

    (lspci | grep -q NVIDIA) && echo "nvidia-driver" >> "${usefull}" && add_i386=y

    [[ ${inst_kodi,,} == y ]] && echo "kodi" >> "${usefull}"

    [[ ${inst_steam,,} == y ]] && echo "steam" >> "${usefull}" && add_i386=y

    [[ ${inst_virtmanager,,} == y ]] && echo "virt-manager" >> "${usefull}"

    [[ ${add_i386} == y ]] && dpkg --add-architecture i386 && apt update

    xargs apt install -y < "${usefull}"

    xargs apt purge -y < "${useless}"

    apt autoremove --purge -y
}

copy_conf(){
    if [[ -f "$1" ]]; then
        cp "$1" "$2"/."$(basename "$1")"
    elif [[ -d "$1" ]]; then
        mkdir -p  "$2"/."$(basename "$1")" &&
            cp -r "$1"/* "$2"/."$(basename "$1")"/
    fi
}

lightdm_config(){
    cat <<EOF > "$1"
[Seat:*]
greeter-hide-users=false
user-session=xfce
[Greeter]
draw-user-backgrounds=true
EOF
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

    pulse_param="flat-volumes = no"
    pulse_conf=/etc/pulse/daemon.conf
    (grep -q ^"${pulse_param}" "${pulse_conf}") &&
        sed -e "s/; ${pulse_param}/${pulse_param}/" -i "${pulse_conf}"

    lightdm_conf=/usr/share/lightdm/lightdm.conf.d/10_my.conf
    [[ -f "${lightdm_conf}" ]] || lightdm_config "${lightdm_conf}"

    redshift_conf=/etc/geoclue/geoclue.conf
    (grep -qvs redshift "${redshift_conf}") &&
        echo -e "\n[redshift]\nallowed=true\nsystem=false\nusers=" >> "${redshift_conf}"

    resources="${SCRIPT_PATH}"/2_resources

    gruvbox_gtk="${resources}"/gruvbox-arc.xml
    gtk_styles=/usr/share/gtksourceview-4/styles
    cp "${gruvbox_gtk}" "${gtk_styles}"/
}

user_config(){
    dest="$1"

    if [[ ${dest} == /etc/skel ]]; then
        conf_user="future users"
    else
        conf_user="$(basename "${dest}")"
    fi

    echo -e "${NFO} Applying custom configuration for ${conf_user}..."

    for dotfile in "${SCRIPT_PATH}"/0_dotfiles/user/*; do
        copy_conf "${dotfile}" "${dest}"
    done

    curl -sSfLo "${dest}"/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    chmod 775 "${dest}"/.vim/autoload

    autostart_dir="${dest}"/.config/autostart
    mkdir -p "${autostart_dir}"
    cp /usr/share/applications/plank.desktop "${autostart_dir}"/

    for useless_file in .bashrc .bash_logout; do
        rm -f "${dest}"/"${useless_file}"
    done
}

add_grp(){
    group="$1"
    user="$2"

    [[ $(groups "${user}") == *" ${group}"* ]] ||
        read -rp "Add user '${user}' to '${group}' group [y/N] ? " -n1 add_user_to_grp

    [[ ${add_user_to_grp} ]] && echo
    [[ ${add_user_to_grp,,} == y ]] && adduser "${user}" "${group}"

    echo -e "${NFO} '${user}' added to '${group}'"
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

(dpkg -l | grep -q "^ii  kodi ") ||
    read -rp "Install Kodi [y/N] ? " -n1 inst_kodi

[[ ${inst_kodi} ]] && echo

(dpkg -l | grep -q "^ii  steam") ||
    read -rp "Install Steam [y/N] ? " -n1 inst_steam

[[ ${inst_steam} ]] && echo

(dpkg -l | grep -q "^ii  virt-manager") && (lspci | grep -qv QEMU) &&
    (dpkg -l | grep -q "^ii  virtualbox ") && (lspci | grep -qiv virtualbox) &&
    read -rp "Install Virtual Machine Manager [y/N] ? " -n1 inst_virtmanager

[[ ${inst_virtmanager} ]] && echo

[[ ${clean_sl,,} == y ]] && clean_sources "${debian_version}"

sys_update

install_xfce

sys_config

user_config /etc/skel

echo -e "${OK} Custom XFCE installed"

users_cpt=0

for user_home in /home/*; do
    user="$(basename "${user_home}")"

    if (grep -q ^"${user}:" /etc/passwd); then
        add_grp sudo "${user}"
        [[ ${inst_virtmanager,,} == y ]] && add_grp libvirt "${user}"

        read -rp "Apply configuration to user '${user}' [y/N] ? " -n1 user_conf

        [[ ${user_conf} ]] && echo
        [[ ${user_conf,,} == y ]] && users[${users_cpt}]="${user}" &&
            users_home[${users_cpt}]="${user_home}" && ((users_cpt+=1))
    fi
done

for i in $(seq 0 $((users_cpt-1))); do
    user_config "${users_home[${i}]}"
    user_group="$(awk -F: '/^'"${users[${i}]}"':/{print $5}' /etc/passwd)"
    chown -R "${users[${i}]}":"${user_group//,}" "${users_home[${i}]}"
done

echo -e "${OK} Custom XFCE installed and configured"
echo -e "${NFO} Execute '${YLO}vim +PlugInstall +qall${DEF}' on each profile to finish vim configuration"

read -rp "Reboot now and enjoy [Y/n] ? " -n1 reboot_now

[[ ${reboot_now} ]] && echo
[[ ${reboot_now,,} == n ]] || reboot


#!/usr/bin/env bash

description="Deploy my personal xfce configuration"
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
    apt full-upgrade -y
}

install_xfce(){
    echo -e "${NFO} Installing new packages then removing useless ones..."
    my_pkgs=/tmp/my_pkgs
    pkg_lists="${SCRIPT_PATH}"/1_pkg

    cp "${pkg_lists}"/base "${my_pkgs}"

    (lspci | grep -q NVIDIA) && echo "nvidia-driver" >> "${my_pkgs}"

    [[ ${inst_kodi} =~ ^(y|Y) ]] && echo "kodi" >> "${my_pkgs}"

    xargs apt install -y < "${my_pkgs}"

    xargs apt purge -y < "${pkg_lists}"/useless

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

    [[ ${allow_root_ssh} =~ ^(y|Y) ]] &&
        echo "PermitRootLogin yes" > "${ssh_conf}" && systemctl restart ssh

    pulse_param="flat-volumes = no"
    pulse_conf=/etc/pulse/daemon.conf
    (grep -q ^"${pulse_param}" "${pulse_conf}") &&
       sed -e "s/; ${pulse_param}/${pulse_param}/" -i "${pulse_conf}"

    lightdm_conf=/usr/share/lightdm/lightdm.conf.d/10_my.conf
    [[ -f "${lightdm_conf}" ]] || lightdm_config "${lightdm_conf}"

    # TODO: redshift config

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

    gitraw_url="https://raw.githubusercontent.co"m
    vimplug_url="${gitraw_url}/junegunn/vim-plug/master/plug.vim"
    curl -sfLo "${dest}"/.vim/autoload/plug.vim --create-dirs "${vimplug_url}"
    chmod 775 "${dest}"/.vim/autoload

    autostart_dir="${dest}"/.config/autostart
    mkdir -p "${autostart_dir}"
    cp /usr/share/applications/plank.desktop "${autostart_dir}"/

    for useless_file in .bashrc .bash_logout; do
        rm -f "${dest}"/"${useless_file}"
    done
}


[[ $2 ]] && echo -e "${ERR} Too many arguments" && usage 1
[[ $1 =~ ^-(h|-help)$ ]] && usage 0 ||
    { [[ $1 ]] && echo -e "${ERR} Bad argument" && usage 1; }

[[ $(whoami) != root ]] && echo -e "${ERR} Need higher privileges" && exit 1

my_dist="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
[[ ${my_dist} != debian ]] &&
    echo -e "${ERR} $(basename "$0") works only on Debian" && exit 1

debian_version="$(lsb_release -sc)"

# TODO: differeciate sid and testing properly
#read -rp "Clean sources.list [y/N] ? " -n1 clean_sl
#[[ ${clean_sl} ]] && echo

(dpkg -l | grep -q ^"ii  kodi") ||
    read -rp "Install Kodi (mediacenter) [y/N] ? " -n1 inst_kodi

[[ ${inst_kodi} ]] && echo

ssh_conf=/etc/ssh/sshd_config
ssh_conf2=/etc/ssh/sshd_config.d/allow_root.conf

(grep -q ^"PermitRootLogin yes" "${ssh_conf}") || [[ -f "${ssh_conf2}" ]] || 
    read -rp "Allow 'root' on ssh [y/N] ? " -n1 allow_root_ssh

[[ ${allow_root_ssh} ]] && echo

users_cpt=0

for user_home in /home/*; do
    user="$(basename "${user_home}")"

    if (grep -q ^"${user}:" /etc/passwd); then
        [[ $(groups "${user}") == *" sudo"* ]] ||
            read -rp "Add user '${user}' to 'sudo' group [y/N] ? " -n1 user_sudo

        [[ ${user_sudo} ]] && echo
        [[ ${user_sudo} =~ ^(y|Y) ]] && adduser "${user}" sudo

        read -rp "Apply configuration to user '${user}' [y/N] ? " -n1 user_conf

        [[ ${user_conf} ]] && echo
        [[ ${user_conf} =~ ^(y|Y) ]] && users[${users_cpt}]="${user}" &&
            users_home[${users_cpt}]="${user_home}" && ((users_cpt+=1))
    fi
done

[[ ${clean_sl} =~ ^(y|Y) ]] && clean_sources "${debian_version}"

sys_update

install_xfce

sys_config

user_config /etc/skel

for i in $(seq 0 $((users_cpt-1))); do
    user_config "${users_home[${i}]}"
    user_group="$(awk -F: '/^'"${users[${i}]}"':/{print $5}' /etc/passwd)"
    chown -R "${users[${i}]}":"${user_group//,}" "${users_home[${i}]}"
done

echo -e "${NFO} Custom XFCE configuration installed"
echo -e "${NFO} Execute '${YLO}vim +PlugInstall +qall${DEF}' on each profile to finish vim configuration"

read -rp "Reboot now and enjoy [Y/n] ? " -n1 reboot_now

[[ ${reboot_now} ]] && echo
[[ ${reboot_now} =~ ^(n|N) ]] || reboot


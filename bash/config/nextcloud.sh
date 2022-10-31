#!/usr/bin/env bash

description="Deploy nextcloud server (nginx + postgresql)"
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

install_prerequisites(){
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

ask_nc_user(){
    read -rp "Nextcloud user ? " nc_user
    [[ ! ${nc_user} ]] && echo -e "${ERR} Need a username" && ask_nc_user
}

ask_nc_mail(){
    read -rp "Nextcloud user's email ? " nc_mail
    [[ ${nc_user} != *@*;* ]] && echo -e "${ERR} Need a email address" && ask_nc_mail
}

ask_nc_pass(){
    # TODO: make typing password invisible

    read -rp "Nextcloud user's password ? " nc_pass
    [[ ! ${nc_pass} ]] && echo -e "${ERR} Need a password" && ask_nc_pass

    # TODO: test password strength

    read -rp "Confirm Nextcloud user's password: " nc_pass2
    [[ ${nc_pass2} ]] && echo

    [[ "${nc_pass2}" != "${nc_pass}" ]] && echo -e "${ERR} Different password" && ask_nc_pass
}

configure_database(){
    echo -e "${NFO} Configuring database..."

    ask_nc_mail
    ask_nc_pass

    echo -e "${NFO} Commands to pass to postgresql:"
    echo -e "${YLO}  CREATE USER nextcloud WITH PASSWORD '${nc_pass}';${DEF}"
    echo -e "${YLO}  CREATE DATABASE nextcloud TEMPLATE template0 ENCODING 'UNICODE';${DEF}"
    echo -e "${YLO}  ALTER DATABASE nextcloud OWNER TO nextcloud;${DEF}"
    echo -e "${YLO}  GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;${DEF}"
    echo -e "${YLO}  \\q${DEF}"

    postgres psql
}

nginx_nextcloud_conf(){
    cat <<EOF > /etc/nginx/conf.d/nextcloud.conf
server {
    listen 80;

    server_name $(hostname -f);
    root /var/www/nextcloud;
    index index.php;

    # Add headers to serve security related headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;

    add_header X-Frame-Options "SAMEORIGIN";

    # Path to the root of Nextcloud installation
    root /usr/share/nginx/nextcloud/;

    access_log /var/log/nginx/nextcloud.access;
    error_log /var/log/nginx/nextcloud.error;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # The following 2 rules are only needed for the user_webfinger app.
    # Uncomment it if you're planning to use this app.
    #rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
    #rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json
    # last;

    location = /.well-known/carddav {
        return 301 \$scheme://\$host/remote.php/dav;
    }
    location = /.well-known/caldav {
       return 301 \$scheme://\$host/remote.php/dav;
   }

    location ~ /.well-known/acme-challenge {
      allow all;
  }

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Disable gzip to avoid the removal of the ETag header
    gzip off;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    error_page 403 /core/templates/403.php;
    error_page 404 /core/templates/404.php;

    location / {
       rewrite ^ /index.php;
   }

    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
       deny all;
   }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
       deny all;
   }

    location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\.php(?:$|/) {
       include fastcgi_params;
       fastcgi_split_path_info ^(.+\.php)(/.*)$;
       try_files \$fastcgi_script_name =404;
       fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
       fastcgi_param PATH_INFO \$fastcgi_path_info;
       #Avoid sending the security headers twice
       fastcgi_param modHeadersAvailable true;
       fastcgi_param front_controller_active true;
       fastcgi_pass unix:/run/php/php7.4-fpm.sock;
       fastcgi_intercept_errors on;
       fastcgi_request_buffering off;
   }

    location ~ ^/(?:updater|ocs-provider)(?:$|/) {
       try_files \$uri/ =404;
       index index.php;
   }

    # Adding the cache control header for js and css files
    # Make sure it is BELOW the PHP block
    location ~* \.(?:css|js)$ {
        try_files \$uri /index.php\$uri\$is_args\$args;
        add_header Cache-Control "public, max-age=7200";
        # Add headers to serve security related headers (It is intended to
        # have those duplicated to the ones above)
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;
        # Optional: Don't log access to assets
        access_log off;
    }

   location ~* \.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$ {
        try_files \$uri /index.php\$uri\$is_args\$args;
        # Optional: Don't log access to other assets
        access_log off;
    }
}
EOF
}

secure_nextcloud(){
    cat <<EOF >> /etc/nginx/conf.d/nextcloud.conf
add_header Strict-Transport-Security "max-age=31536000" always;
listen 443 ssl http2; # managed by Certbot
EOF
}

install_nextcloud(){
    configure_database

    wget https://download.nextcloud.com/server/releases/latest.zip -P /tmp

    7z x /tmp/latest.zip -o/usr/share/nginx/

    mkdir -p /usr/share/nginx/nextcloud
    chown -R www-data:www-data /usr/share/nginx/nextcloud
    #chmod -R 755 /usr/share/nginx/nextcloud

    mkdir -p /usr/share/nginx/nextcloud-data
    chown -R www-data:www-data /usr/share/nginx/nextcloud-data
    #chmod -R 755 /usr/share/nginx/nextcloud-data

    nginx_nextcloud_conf

    nginx -t

    systemctl enable nginx
    systemctl enable --now php7.4-fpm

    certbot --nginx --agree-tos --redirect --staple-ocsp --email "${nc_mail}" -d "$(hostname -f)"

    secure_nextcloud

    # TODO: additional configuration

    systemctl restart php7.4-fpm nginx

    rm -f /tmp/latest.zip
    rm -rf /tmp/nextcloud
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

install_prerequisites

sys_config

install_nextcloud

echo -e "${OK} Nextcloud installed"
echo -e "${NFO} Connect 'http://$(hostname -f)/nextcloud' to finish configuration"
echo -e "${YLO}Enjoy !${DEF}"


# debian_scripts

## bash/config

bash/config/00_server_init.sh
Debian server base configuration
Usage:
  ./00_server_init.sh [OPTION] as root or using sudo
Options[0m:
  -h,--help: Print this help

bash/config/xfce.sh
Deploy my personal xfce configuration
WRN: It's a combination of personal choices. Use it at your own risk.
Usage:
  ./xfce.sh [OPTION] as root or using sudo
Options:
  -h,--help: Print this help

## bash/scripts

bash/scripts/chromium/play_drm.sh
mInstall or remove widevine lib in chromium
Usage:
  play_drm.sh [OPTION]
Options:
  no option: Install widevine
  -h,--help:   Print this help
  -r,--remove: Remove widevine lib

bash/scripts/git/statgitrepos.sh
Return statuts of git repos in ~/Work/git
Usage:
  statgitrepos.sh [OPTION]
Options:
  -h,--help: Print this help

bash/scripts/pulseaudio/pastep.sh
Set puseaudio-plugin volume control step
Usage:
  pastep.sh [OPTION] <STEP>
  mwith STEP the percentage to apply to volume control step between 1 and 20
Options:
  -h,--help: Print this help

bash/scripts/synchro/backup.sh
Backup user config and more in /volumes/backup
Usage:
  backup.sh <OPTION>
Options:
  -h,--help:     Print this help
  -v,--versbose: Add verbosity

bash/scripts/system_info/sysinfo.sh
Display system informations
Usage:
  sysinfo.sh [OPTION]
Options:
  -h,--help:    Print this help
  -u,--upgrade: Upgrade system before displaying informations
  -ub: Upgrade system and do a backup before displaying informations

bash/scripts/transmissiond/tsm.sh
Make 'transmission-cli' manipulations simplified
Usage:
  tsm.sh <OPTION>
Options:
  no option:    Show queue
  -h,--help:    Print this help
  -a,--add:     Add .torrent files from ~/Download to queue
  -d <ID>:      Remove torrent with id ID and delete downloaded data
  -t,--test:    Test port
  -r,--restart: Restart transmission-daemon (need 'sudo' rights)

bash/scripts/tweak/kora_icons.sh
Install/Update Kora icon-theme
Usage:
  kora_icons.sh [OPTION]
Options:
  no option:   Install Kora icon-theme
  -h,--help:   Print this help
  -r,--remove: Remove Kora icon-theme

bash/scripts/tweak/mcmojave_cursors.sh
Install/Update McMojave cursors
Usage:
  mcmojave_cursors.sh [OPTION]
Options:
  no option:   Install McMojave-cursors
  -h,--help:   Print this help
  -r,--remove: Remove McMojave-cursors

bash/scripts/tweak/mojave_gtk.sh
Install/Update Mojave gtk-theme
Usage:
  mojave_gtk.sh [OPTION]
Options:
  no option:   Install Mojave-gtk-theme
  -h,--help:   Print this help
  -r,--remove: Remove Mojave-gtk-theme

## bash/systools

bash/systools/usbcreator.sh
Create USB bootable key with debian stable on it
Usage:
  'usbcreator.sh [OPTION] <DEVICE>' as root or using sudo
  with DEVICE the device in /dev/ corrsponding to your USB key
Options:
  -h,--help: Print this help

## bash/deployment

bash/deployment/deploy_bash_scripts.sh
Deploy bash scripts to ~/.local/bin
Usage:
  ./deploy_bash_scripts.sh [OPTION]
Options:
  -h,--help: Print this help

bash/deployment/deploy_systools.sh
Deploy 'systools' bash and python scripts to /usr/local/bin
Usage:
  './deployment/deploy_systools.sh [OPTION]' as root or using sudo
Options:
  -h,--help: Print this help

## python/systools

/volumes/speedix/Work/git/debian_scripts/bash/systools/usbcreator.sh
Create USB bootable key with debian stable on it
Usage:
  'usbcreator.sh [OPTION] <DEVICE>' as root or using sudo
  with DEVICE the device in /dev/ corrsponding to your USB key
Options:
  -h,--help: Print this help


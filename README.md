# debian_scripts

## bash/config

__bash/config/00_server_init.sh__  
Debian server base configuration 
Usage:  
&ensp;'./00_server_init.sh [OPTION]' as root or using sudo  
Options:  
&ensp;-h,--help: Print this help

__bash/config/xfce.sh__  
Deploy my personal xfce configuration  
WRN: It's a combination of personal choices. Use it at your own risk.  
Usage:  
&ensp;'./xfce.sh [OPTION]' as root or using sudo  
Options:  
&ensp;-h,--help: Print this help

## bash/scripts

__bash/scripts/chromium/play_drm.sh__  
Install or remove widevine lib in chromium  
Usage:  
&ensp;./play_drm.sh [OPTION]  
Options:  
&ensp;no option: Install widevine  
&ensp;-h,--help:   Print this help  
&ensp;-r,--remove: Remove widevine lib

__bash/scripts/git/statgitrepos.sh__  
Return statuts of git repos in ~/Work/git  
Usage:
&ensp;./statgitrepos.sh [OPTION]  
Options:  
&ensp;-h,--help: Print this help

__bash/scripts/pulseaudio/pastep.sh__  
Set puseaudio-plugin volume control step  
Usage:  
&ensp;./pastep.sh [OPTION] <STEP>  
&ensp;mwith STEP the percentage to apply to volume control step between 1 and 20  
Options:  
&ensp;-h,--help: Print this help

__bash/scripts/synchro/backup.sh__  
Backup user config and more in /volumes/backup  
Usage:  
&ensp;./backup.sh <OPTION>  
Options:  
&ensp;-h,--help:     Print this help  
&ensp;-v,--versbose: Add verbosity

__bash/scripts/system_info/sysinfo.sh__  
Display system informations  
Usage:  
&ensp;./sysinfo.sh [OPTION]  
Options:  
&ensp;-h,--help:    Print this help  
&ensp;-u,--upgrade: Upgrade system before displaying informations  
&ensp;-ub: Upgrade system and do a backup before displaying informations

__bash/scripts/transmissiond/tsm.sh__  
Make 'transmission-cli' manipulations simplified  
Usage:  
&ensp;./tsm.sh <OPTION>  
Options:  
&ensp;no option:    Show queue  
&ensp;-h,--help:    Print this help  
&ensp;-a,--add:     Add .torrent files from ~/Download to queue  
&ensp;-d <ID>:      Remove torrent with id ID and delete downloaded data  
&ensp;-t,--test:    Test port  
&ensp;-r,--restart: Restart transmission-daemon (need 'sudo' rights)

__bash/scripts/tweak/kora_icons.sh__  
Install/Update Kora icon-theme  
Usage:  
&ensp;./kora_icons.sh [OPTION]  
Options:  
&ensp;no option:   Install Kora icon-theme  
&ensp;-h,--help:   Print this help  
&ensp;-r,--remove: Remove Kora icon-theme

__bash/scripts/tweak/mcmojave_cursors.sh__  
Install/Update McMojave cursors  
Usage:  
&ensp;./mcmojave_cursors.sh [OPTION]  
Options:  
&ensp;no option:   Install McMojave-cursors  
&ensp;-h,--help:   Print this help  
&ensp;-r,--remove: Remove McMojave-cursors

__bash/scripts/tweak/mojave_gtk.sh__  
Install/Update Mojave gtk-theme  
Usage:  
&ensp;./mojave_gtk.sh [OPTION]  
Options:  
&ensp;no option:   Install Mojave-gtk-theme  
&ensp;-h,--help:   Print this help  
&ensp;-r,--remove: Remove Mojave-gtk-theme

## bash/systools

__bash/systools/usbcreator.sh__  
Create USB bootable key with debian stable on it  
Usage:  
&ensp;'./usbcreator.sh [OPTION] <DEVICE>' as root or using sudo  
&ensp;with DEVICE the device in /dev/ corrsponding to your USB key  
Options:  
&ensp;-h,--help: Print this help

## bash/deployment

__bash/deployment/deploy_bash_scripts.sh__  
Deploy bash scripts to ~/.local/bin  
Usage:  
&ensp;./deploy_bash_scripts.sh [OPTION]  
Options:  
&ensp;-h,--help: Print this help

__bash/deployment/deploy_systools.sh__  
Deploy 'systools' bash and python scripts to /usr/local/bin  
Usage:  
&ensp;'./deploy_systools.sh [OPTION]' as root or using sudo  
Options:  
&ensp;-h,--help: Print this help

## python/systools

__python/netinfo.py__  
Show network informations  
Usage:  
&ensp;./netinfo.py [OPTION]  
Options:  
&ensp;-h,--help: Print this help

__python/systools/pydf.py__  
Graphical filesystems usage  
Usage:  
&ensp;./pydf.py [OPTION]  
Options:  
&ensp;-h,--help: Print this help  
&ensp;-a,--all:  Show all filesystems including tmpfs

__python/systools/pyfetch.py__  
Fetch system informations  
Usage:  
&ensp;./pyfetch.py [OPTION]  
Options:  
&ensp;-h,--help:         Print this help  
&ensp;-d,--default-logo: Use default logo

# ovmenu
ovmenu-ng.sh of Openvarion, adapted for Armbian/Raspbian self build.
It  s invoked by autostart as below.

~/.config/autostart/ovmenu.desktop on Armbian:
[Desktop Entry]
Name=Openvario Menu
Comment=Openvario Menu
Icon=ovmenu
Exec=sh -c "exec xterm -e ${HOME}/ovmenu/ovmenu-ng.sh"
TryExec=xterm
Terminal=false
Type=Application
Categories=
NotShowIn=LXDE
X-Ubuntu-Gettext-Domain=ovmenu

/etc/xdg/lxsession/LXDE-pi/autostart on Raspbian:
@lxpanel --profile LXDE-pi 
@pcmanfm --desktop --profile LXDE-pi 
@xscreensaver -no-splash 
point-rpi 
@xterm -e ovmenu-ng.sh 

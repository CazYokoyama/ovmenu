#!/bin/bash

#Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$

TOUCH_CAL=/opt/conf/touch.cal

XCSOAR_BIN=${HOME}/XCSoar/output/UNIX/bin/xcsoar
#XCSOAR_RESOLUTION=800x480 # 0 or 180 degree landscape
XCSOAR_RESOLUTION=480x800 # 90 or 270 degree portrait
DIALOG_LOC="3 1"

#get config files
source /opt/conf/*.conf

# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

main_menu () {
while true; do
	### display main menu ###
	dialog --clear --nocancel --backtitle "OpenVario" \
	--title "[ M A I N - M E N U ]" \
	--begin ${DIALOG_LOC} \
	--menu "You can use the UP/DOWN arrow keys" 15 50 7 \
	XCSoar   "Start XCSoar" \
	File     "Copy files" \
	System   "Update/Settings, ..." \
	Exit     "Exit to shell" \
	Restart  "Reboot" \
	Pwr_off  "Power off" 2>"${INPUT}" \
	ovmenu   "Restart ovmenu"

	menuitem=$(<"${INPUT}")
 
	# make decsion 
	case $menuitem in
	XCSoar)   start_xcsoar;;
	File)     submenu_file;;
	System)   submenu_system;;
	Exit)     yesno_exit;;
	Restart)  yesno_restart;;
	Pwrr_off) yesno_power_off;;
	ovmenu)   exec $0;; # restart myself
	esac
done
}

function submenu_file() {

	### display file menu ###
	dialog --nocancel --backtitle "OpenVario" \
	--title "[ F I L E ]" \
	--begin ${DIALOG_LOC} \
	--menu "You can use the UP/DOWN arrow keys" 15 50 4 \
	DL_IGC   "IGC files -> USB" \
	DL_all   ".xcsoar -> USB" \
	Upload   ".xcsoar <- USB" \
	Back   "Back to Main" 2>"${INPUT}"
	
	menuitem=$(<"${INPUT}")
	
	# make decision 
	case $menuitem in
	DL_IGC) download_igc_files;;
	DL_all) download_files;;
	Upload) upload_files;;
	Exit) ;;
	esac
}

function submenu_system() {
	### display system menu ###
	dialog --nocancel --backtitle "OpenVario" \
	--title "[ S Y S T E M ]" \
	--begin ${DIALOG_LOC} \
	--menu "You can use the UP/DOWN arrow keys" 15 50 6 \
	Update_System   "Update system software" \
	Update_Maps   "Update Maps files" \
	Calibrate_Sensors   "Calibrate Sensors" \
	Calibrate_Touch   "Calibrate Touch" \
	Settings   "System Settings" \
	Information "System Info" \
	Back   "Back to Main" 2>"${INPUT}"
	
	menuitem=$(<"${INPUT}")
	
	# make decsion 
	case $menuitem in
		Update_System) 
			update_system
			;;
		Update_Maps) 
			update_maps
			;;
		Calibrate_Sensors) 
			calibrate_sensors
			;;
		Calibrate_Touch) 
			calibrate_touch
			;;
		Settings)
			submenu_settings
			;;
		Information)
			show_info
			;;
		Exit) ;;
	esac		
}

function show_info() {
	### collect info of system
	XCSOAR_VERSION=$(cd ${HOME}/XCSoar; git log -n1 | grep ^commit | cut --characters=8-17)
	XCSOAR_MAPS_FLARMNET=
	XCSOAR_MAPS_VERSION=
	IMAGE_VERSION=
	IP_ETH0=$(/sbin/ifconfig eth0 | grep 'inet ' | awk '{ print $2}')
	IP_WLAN=$(/sbin/ifconfig wlan0 | grep 'inet ' | awk '{ print $2}')
	
	dialog --backtitle "OpenVario" \
	--title "[ S Y S T E M I N F O ]" \
	--begin ${DIALOG_LOC} \
	--msgbox " \
	\n \
	Image: $IMAGE_VERSION\n \
	XCSoar: $XCSOAR_VERSION\n \
	Maps: $XCSOAR_MAPS_VERSION\n \
	Flarmnet: $XCSOAR_MAPS_FLARMNET\n \
	IP eth0: $IP_ETH0\n \
	IP wlan0: $IP_WLAN\n \
	" 15 50
	
}

function submenu_settings() {
	### display settings menu ###
	dialog --nocancel --backtitle "OpenVario" \
	--title "[ S Y S T E M ]" \
	--begin ${DIALOG_LOC} \
	--menu "You can use the UP/DOWN arrow keys" 15 50 5 \
	Display_Rotation 	"Set rotation of the display" \
	XCSoar_Language 	"Set language used for XCSoar" \
	Back   "Back to Main" 2>"${INPUT}"
	
	menuitem=$(<"${INPUT}")

	# make decsion 
	case $menuitem in
		Display_Rotation)
			submenu_rotation
			;;
		XCSoar_Language)
			submenu_xcsoar_lang
			;;
		Back) ;;
	esac		
}

function submenu_xcsoar_lang() {
	if [ -n $XCSOAR_LANG ]; then
		dialog --nocancel --backtitle "OpenVario" \
		--title "[ S Y S T E M ]" \
		--begin ${DIALOG_LOC} \
		--menu "Actual Setting is $XCSOAR_LANG \nSelect Language:" 15 50 4 \
		 system "Default system" \
		 de_DE.UTF-8 "German" \
		 fr_FR.UTF-8 "France" \
		 it_IT.UTF-8 "Italian" \
		 hu_HU.UTF-8 "Hungary" \
		 pl_PL.UTF-8 "Poland" \
		 cs_CZ.UTF-8 "Czech" \
	 	 sk_SK.UTF-8 "Slowak" \
		 2>"${INPUT}"
		 
		 menuitem=$(<"${INPUT}")

		# update config
		sed -i 's/^XCSOAR_LANG=.*/XCSOAR_LANG='$menuitem'/' /opt/conf/ov-xcsoar.conf
		dialog --msgbox "New Setting saved !!\n A Reboot is required !!!" 10 50	
	else
		dialog --backtitle "OpenVario" \
		--title "ERROR" \
		--msgbox "No Config found !!"
	fi
}

function submenu_rotation() {
	
	mount /dev/mmcblk0p1 /boot 
	TEMP=$(grep "rotation" /boot/config.uEnv)
	if [ -n $TEMP ]; then
		ROTATION=${TEMP: -1}
		dialog --nocancel --backtitle "OpenVario" \
		--title "[ S Y S T E M ]" \
		--begin ${DIALOG_LOC} \
		--menu "Actual Setting is $ROTATION \nSelect Rotation:" 15 50 4 \
		 0 "Landscape 0 deg" \
		 1 "Portrait 90 deg" \
		 2 "Landscape 180 deg" \
		 3 "Portrait 270 deg" 2>"${INPUT}"
		 
		 menuitem=$(<"${INPUT}")

		# update config
		# uboot rotation
		sed -i 's/^rotation=.*/rotation='$menuitem'/' /boot/config.uEnv
		# touch cal
		if [ -e $TOUCH_CAL ]; then
			cd /opt/bin
			./caltool -c $TOUCH_CAL -r $menuitem
			cp ./touchscreen.rules /etc/udev/rules.d/
			dialog --msgbox "New Setting saved !!\n A Reboot is required !!!" 10 50
		else
			dialog --msgbox "New Setting saved, but touch cal not valid !!\n A Reboot is required !!!" 10 50
		fi
	else
		dialog --backtitle "OpenVario" \
		--title "ERROR" \
		--msgbox "No Config found !!"
	fi
	
	umount /boot
}

function update_system() {

	echo "Updating System ..." > /tmp/tail.$$
	opkg update &>/dev/null
	OPKG_UPDATE=$(opkg list-upgradable)
	
	dialog --backtitle "Openvario" \
	--begin ${DIALOG_LOC} \
	--defaultno \
	--title "Update" --yesno "$OPKG_UPDATE" 15 40
	
	response=$?
	case $response in
	0)
		apt update &>/tmp/tail.$$
		apt upgrade &>>/tmp/tail.$$
		dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
		;;
	esac
}

function calibrate_sensors() {

	dialog --backtitle "Openvario" \
	--begin ${DIALOG_LOC} \
	--defaultno \
	--title "Sensor Calibration" --yesno "Really want to calibrate sensors ?? \n This takes a few moments ...." 10 40
	
	response=$?
	case $response in
		0) ;;
		*) return 0
	esac
		
	echo "Calibrating Sensors ..." >> /tmp/tail.$$
	systemctl stop sensord
	/opt/bin/sensorcal -c > /tmp/tail.$$

	if [ $? -eq 2 ]
	then
		# board not initialised
		dialog --backtitle "Openvario" \
		--begin ${DIALOG_LOC} \
		--defaultno \
		--title "Init Sensorboard" --yesno "Sensorboard is virgin ! \n Do you want to initialize ??" 10 40
	
		response=$?
		case $response in
			0) /opt/bin/sensorcal -i > /tmp/tail.$$
			;;
		esac
		echo "Please run sensorcal again !!!" > /tmp/tail.$$
	fi
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
	systemctl start sensord
}

function calibrate_touch() {
	echo "Calibrating Touch ..." >> /tmp/tail.$$
	# reset touch calibration
	# uboot rotation
	mount /dev/mmcblk0p1 /boot
	sed -i 's/^rotation=.*/rotation=0/' /boot/config.uEnv
	umount /dev/mmcblk0p1
	
	rm /opt/conf/touch.cal
	cp /opt/bin/touchscreen.rules.template /etc/udev/rules.d/touchscreen.rules
	udevadm control --reload-rules
	udevadm trigger
	sleep 2
	/opt/bin/caltool -c $TOUCH_CAL
	dialog --msgbox "Display rotation is RESET !!\nPlease set Display rotation again to apply calibration !!" 10 50
}

# Copy /usb/usbstick/openvario/maps to /home/root/.xcsoar
# Copy only xcsoar-maps*.ipk and *.xcm files
function update_maps() {
	echo "Updating Maps ..." > /tmp/tail.$$
	update-maps.sh >> /tmp/tail.$$ 2>/dev/null &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /home/root/.xcsoar to /usb/usbstick/openvario/download/xcsoar
function download_files() {
	echo "Downloading files ..." > /tmp/tail.$$
	download-all.sh >> /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /home/root/.xcsoar/logs to /usb/usbstick/openvario/igc
# Copy only *.igc files
function download_igc_files() {
	echo "Downloading IGC files ..." > /tmp/tail.$$
	download-igc.sh >> /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /usb/usbstick/openvario/upload to /home/root/.xcsoar
function upload_files(){
	echo "Uploading files ..." > /tmp/tail.$$
	upload-xcsoar.sh >> /tmp/tail.$$ &
	dialog --backtitle "OpenVario" --title "Result" --tailbox /tmp/tail.$$ 30 50
}

function start_xcsoar() {
	xcsoar_config.sh
	if [ -z $XCSOAR_LANG ]; then
		${XCSOAR_BIN} -fly -${XCSOAR_RESOLUTION}
	else
		LANG=$XCSOAR_LANG ${XCSOAR_BIN} -fly -${XCSOAR_RESOLUTION}
	fi
}

function yesno_exit(){
	dialog --backtitle "Openvario" \
	--begin ${DIALOG_LOC} \
	--defaultno \
	--title "Really exit ?" --yesno "Really want to go to console ??" 5 40

	response=$?
	case $response in
		0) echo "Bye";exit 1;;
	esac
}

function yesno_restart(){
	dialog --backtitle "Openvario" \
	--begin ${DIALOG_LOC} \
	--defaultno \
	--title "Really restart ?" --yesno "Really want to restart ??" 5 40

	response=$?
	case $response in
		0) reboot;;
	esac
}

function yesno_power_off(){
	dialog --backtitle "Openvario" \
	--begin ${DIALOG_LOC} \
	--defaultno \
	--title "Really Power-OFF ?" --yesno "Really want to Power-OFF" 5 40

	response=$?
	case $response in
		0) shutdown -h now;;
	esac
}

setfont cp866-8x14.psf.gz

DIALOG_CANCEL=1 dialog --nook --nocancel --pause "Starting XCSoar ... \\n Press [ESC] for menu" 10 30 $TIMEOUT 2>&1

case $? in
	0) start_xcsoar;;
	*) main_menu;;
esac
main_menu

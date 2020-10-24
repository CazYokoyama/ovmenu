#!/bin/bash

#Config
TIMEOUT=3
INPUT=/tmp/menu.sh.$$

BACKTITLE=RpiVario

XCSOAR_BIN=${HOME}/XCSoar/output/UNIX/bin/xcsoar
XCSOAR_VERSION_TXT=${HOME}/XCSoar/VERSION.txt
XCSOAR_RESOLUTION=800x480 # 0 or 180 degree landscape
#XCSOAR_RESOLUTION=480x800 # 90 or 270 degree portrait

BOOT_CONFIG_TXT=/boot/config.txt
LIBINPUT_CONF=/etc/X11/xorg.conf.d/40-libinput.conf
XCSOAR_CONF_DIR=/opt/conf
XCSOAR_CONF=${XCSOAR_CONF_DIR}/ov-xcsoar.conf

#get config files
source ${XCSOAR_CONF_DIR}/*.conf 2>/dev/null

# trap and delete temp files
trap "rm $INPUT;rm /tmp/tail.$$; exit" SIGHUP SIGINT SIGTERM

main_menu () {
while true
do
	### display main menu ###
	dialog --clear --nocancel --backtitle ${BACKTITLE} \
	--title "[ M A I N - M E N U ]" \
	--begin 3 4 \
	--menu "You can use the UP/DOWN arrow keys" 15 50 6 \
	XCSoar   "Start XCSoar" \
	File   "Copys file to and from OpenVario" \
	System   "Update, Settings, ..." \
	Exit   "Exit to the shell" \
	Restart "Restart" \
	Power_OFF "Power OFF" 2>"${INPUT}"
	 
	menuitem=$(<"${INPUT}")
 
	# make decsion 
case $menuitem in
	XCSoar) start_xcsoar;;
	File) submenu_file;;
	System) submenu_system;;
	Exit) yesno_exit;;
	Restart) yesno_restart;;
	Power_OFF) yesno_power_off;;
esac

done
}

function submenu_file() {

	### display file menu ###
	dialog --nocancel --backtitle ${BACKTITLE} \
	--title "[ F I L E ]" \
	--begin 3 4 \
	--menu "You can use the UP/DOWN arrow keys" 15 50 4 \
	Download_IGC   "Download XCSoar IGC files to USB" \
	Download   "Download XCSoar to USB" \
	Upload   "Upload files from USB to XCSoar" \
	Back   "Back to Main" 2>"${INPUT}"
	
	menuitem=$(<"${INPUT}")
	
	# make decsion 
	case $menuitem in
		Download_IGC) download_igc_files;;
		Download) download_files;;
		Upload) upload_files;;
		Exit) ;;
	esac
}

function submenu_system() {
	### display system menu ###
	dialog --nocancel --backtitle ${BACKTITLE} \
	--title "[ S Y S T E M ]" \
	--begin 3 4 \
	--menu "You can use the UP/DOWN arrow keys" 15 50 7 \
	Update_System   "Update system software" \
	Update_Maps   "Update Maps files" \
	Calibrate_Sensors   "Calibrate Sensors" \
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
    dialog --backtitle ${BACKTITLE} \
	--title "[ S Y S T E M I N F O ]" \
	--begin 3 4 \
	--msgbox " \
	\n \
	OS:         $(grep PRETTY_NAME /etc/os-release | cut -d"=" -f2 | tr -d \")\n \
	kernel:     $(uname -r)\n \
	XCSoar:     v$(cat ${XCSOAR_VERSION_TXT})/$(cd ${HOME}/XCSoar; git log -n1 | grep ^commit | \
	    cut --characters=8-17)\n \
	XCSoarData: $(cd ${HOME}/XCSoarData; git log -n1 | grep ^commit | cut --characters=8-17)\n \
	IP eth0:    $(/sbin/ifconfig eth0 | grep 'inet ' | awk '{ print $2}')\n \
	IP wlan0:   $(/sbin/ifconfig wlan0 | grep 'inet ' | awk '{ print $2}')\n \
	" 15 50
}

function submenu_settings() {
	### display settings menu ###
	dialog --nocancel --backtitle ${BACKTITLE} \
	--title "[ S Y S T E M ]" \
	--begin 3 4 \
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
    dialog --nocancel --backtitle ${BACKTITLE} \
	--title "[ S Y S T E M ]" \
	--begin 3 4 \
	--default-item ${XCSOAR_LANG:=system} \
	--menu "\nSelect Language:" 16 50 8 \
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

    if [ ${menuitem} = ${XCSOAR_LANG} ]; then
	echo No change.
	sleep 5
	return
    fi

    # update config
    if [ -f ${XCSOAR_CONF} ]; then
	sudo sed -ie 's/^XCSOAR_LANG=.*/XCSOAR_LANG='${menuitem}'/' ${XCSOAR_CONF}
    else
	[ -d ${XCSOAR_CONF_DIR} ] || sudo mkdir ${XCSOAR_CONF_DIR}
	sudo sh -c "echo XCSOAR_LANG=${menuitem} >${XCSOAR_CONF}"
    fi
    dialog --msgbox "Language is ${menuitem}.\nReboot is required." 10 50
}

function submenu_rotation() {
    local ROTATION

    ROTATION=$(grep "^display_rotate=" ${BOOT_CONFIG_TXT} | cut -d" " -f1 | cut -d= -f2)
    if [ "${ROTATION}" != 0 ]; then # select 0 if something wrong
	ROTATION=0
    fi
    dialog --backtitle ${BACKTITLE} \
	--title "[ S Y S T E M ]" \
	--begin 3 4 \
	--default-item ${ROTATION} \
	--menu "Select Rotation:" 15 50 4 \
	0 "Landscape 0 deg" \
	1 "Portrait 90 deg" \
	2 "Landscape 180 deg" \
	3 "Portrait 270 deg" 2>"${INPUT}"
    menuitem=$(<"${INPUT}")

    case ${menuitem} in
    0) DEGREE=0;;
    1) DEGREE=90;;
    2) DEGREE=180;;
    3) DEGREE=270;;
    *) return;;
    esac

    # update ${BOOT_CONFIG_TXT} for display
    # commented out all display_rotate=
    sudo sed -ie '/^display_rotate=/s/^/#/' ${BOOT_CONFIG_TXT}
    # enable the selected one
    sudo sed -i "/#display_rotate=.* # ${DEGREE}/s/^#//" ${BOOT_CONFIG_TXT}

    # touch screen
    # commented out all CalibrationMatrix
    sudo sed -ie '/^        .*CalibrationMatrix/s/^/#/' ${LIBINPUT_CONF}
    # enable the selected one
    sudo sed -ie "/#.*CalibrationMatrix.* # ${DEGREE}/s/^#//" ${LIBINPUT_CONF}

    dialog --msgbox "New Setting saved.\n Reboot is required." 10 50
}

function update_system() {

	echo "Updating System ..." > /tmp/tail.$$
	opkg update &>/dev/null
	OPKG_UPDATE=$(opkg list-upgradable)
	
	dialog --backtitle ${BACKTITLE} \
	--begin 3 4 \
	--defaultno \
	--title "Update" --yesno "$OPKG_UPDATE" 15 40
	
	response=$?
	case $response in
	0)
		apt update &>/tmp/tail.$$
		apt upgrade &>>/tmp/tail.$$
		dialog --backtitle ${BACKTITLE} --title "Result" --tailbox /tmp/tail.$$ 30 50
		;;
	esac
}

function calibrate_sensors() {

	dialog --backtitle ${BACKTITLE} \
	--begin 3 4 \
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
		dialog --backtitle ${BACKTITLE} \
		--begin 3 4 \
		--defaultno \
		--title "Init Sensorboard" --yesno "Sensorboard is virgin ! \n Do you want to initialize ??" 10 40
	
		response=$?
		case $response in
			0) /opt/bin/sensorcal -i > /tmp/tail.$$
			;;
		esac
		echo "Please run sensorcal again !!!" > /tmp/tail.$$
	fi
	dialog --backtitle ${BACKTITLE} --title "Result" --tailbox /tmp/tail.$$ 30 50
	systemctl start sensord
}

# Copy /usb/usbstick/openvario/maps to /home/root/.xcsoar
# Copy only xcsoar-maps*.ipk and *.xcm files
function update_maps() {
	echo "Updating Maps ..." > /tmp/tail.$$
	update-maps.sh >> /tmp/tail.$$ 2>/dev/null &
	dialog --backtitle ${BACKTITLE} --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /home/root/.xcsoar to /usb/usbstick/openvario/download/xcsoar
function download_files() {
	echo "Downloading files ..." > /tmp/tail.$$
	download-all.sh >> /tmp/tail.$$ &
	dialog --backtitle ${BACKTITLE} --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /home/root/.xcsoar/logs to /usb/usbstick/openvario/igc
# Copy only *.igc files
function download_igc_files() {
	echo "Downloading IGC files ..." > /tmp/tail.$$
	download-igc.sh >> /tmp/tail.$$ &
	dialog --backtitle ${BACKTITLE} --title "Result" --tailbox /tmp/tail.$$ 30 50
}

# Copy /usb/usbstick/openvario/upload to /home/root/.xcsoar
function upload_files(){
	echo "Uploading files ..." > /tmp/tail.$$
	upload-xcsoar.sh >> /tmp/tail.$$ &
	dialog --backtitle ${BACKTITLE} --title "Result" --tailbox /tmp/tail.$$ 30 50
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
	dialog --backtitle ${BACKTITLE} \
	--begin 3 4 \
	--defaultno \
	--title "Really exit ?" --yesno "Really want to go to console ??" 5 40

	response=$?
	case $response in
		0) echo "Bye";exit 1;;
	esac
}

function yesno_restart(){
	dialog --backtitle ${BACKTITLE} \
	--begin 3 4 \
	--defaultno \
	--title "Really restart ?" --yesno "Really want to restart ??" 5 40

	response=$?
	case $response in
		0) sudo reboot;;
	esac
}

function yesno_power_off(){
	dialog --backtitle ${BACKTITLE} \
	--begin 3 4 \
	--defaultno \
	--title "Really Power-OFF ?" --yesno "Really want to Power-OFF" 5 40

	response=$?
	case $response in
		0) sudo poweroff;;
	esac
}

setfont cp866-8x14.psf.gz

DIALOG_CANCEL=1 dialog --nook --nocancel --pause "Starting XCSoar ... \\n Press [ESC] for menu" 10 30 $TIMEOUT 2>&1

case $? in
	0) start_xcsoar;;
	*) main_menu;;
esac
main_menu

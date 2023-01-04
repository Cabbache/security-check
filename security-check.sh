#!/bin/bash

function check_dep(){
	command -v "$1" > /dev/null || exerr "Dependency '$1' not found"
}

function check_deps(){
	check_dep zenity
	check_dep systemctl
	check_dep date
	check_dep sleep
	check_dep kill
}

function ask_add_bashrc(){
	read -p "Add $install_bin_dir to PATH in .bashrc? [y/n]>> " do_add
	if [[ "$do_add" == "y" ]]
	then
		echo "export PATH=\"\$PATH:$install_bin_dir\"" >> \
		$bashrc_path
	fi
}

function is_added_to_bashrc(){
	[[ -f "$bashrc_path" ]] &&
	[[ -z $(grep "$install_dir" "$bashrc_path") ]] &&
	return 1
	return 0
}

function ask_remove(){
	[[ -e "$1" ]] || return
	TYPE="(Unkown type)"
	[[ -d "$1" ]] && TYPE="directory"
	[[ -f "$1" ]] && TYPE="file"
	read -p "Remove $TYPE $1? [y/n]>> " do_delete
	if [[ "$do_delete" == "y" ]]
	then
		rm -r "$1" && echo "Removed $1"
	fi
}

function do_installation(){
	if [[ -f "$service_path" ]]
	then
		echo "Service file already exists"
		read -p 'Overwrite? [y/n]>> ' overwrite
		if [[ "$overwrite" != "y" ]]
		then
			>&2 echo "Not overwriting. Not installing"
			exit 1
		else
			systemctl stop security-check.service
		fi
	fi

	mkdir -p "$install_bin_dir"
	cp security.sh "$install_dir"
	cp config.sh "$install_dir"
	cp secprompt.sh "$install_bin_dir/secprompt"
	chmod +x "$install_bin_dir/secprompt"
	chown -R $SUDO_USER:$SUDO_USER "$install_dir"

	cat << EOF > $service_path
[Unit]
Description=security-check

[Service]
User=$SUDO_USER
ExecStart=bash "$install_dir/security.sh"
Restart=always
RestartSec=1s
Environment="DISPLAY=$DISPLAY"

[Install]
WantedBy=multi-user.target
EOF

	is_added_to_bashrc || ask_add_bashrc

	systemctl daemon-reload
	systemctl enable security-check.service
	systemctl start security-check.service
}

function do_uninstallation(){
	#TODO file exists doesn't mean service exists?
	[[ -f "$service_path" ]] && systemctl stop security-check

	ask_remove "$service_path"
	ask_remove "$install_dir"
	is_added_to_bashrc &&
	echo "You need to manually modify the .bashrc to remove 'export PATH=...'"
}

if [[ "$EUID" -ne 0 ]]
then
	>&2 echo "You must run this as root"
	exit 1
fi

if [[ -z "$SUDO_USER" ]]
then
	>&2 echo "Cannot find SUDO_USER"
	exit 1
fi

service_path="/etc/systemd/system/security-check.service"
install_dir="/home/$SUDO_USER/.security-check"
install_bin_dir="$install_dir/bin"
bashrc_path="/home/$SUDO_USER/.bashrc" 

check_deps

if [[ $# -ne 1 ]]
then
	>&2 echo "Usage: $0 (install|uninstall)"
	exit 1
fi

if [[ "$1" == "install" ]]
then
	do_installation
elif [[ "$1" == "uninstall" ]]
then
	do_uninstallation
else
	>&2 echo "Usage: $0 (install|uninstall)"
	exit 1
fi

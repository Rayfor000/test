#!/bin/bash

SH="/usr/local/bin/1xguard"
[ ! -f "$SH~" ] && { gzexe $SH; rm "$SH~"; touch "$SH~"; }
[ "$(id -u)" -ne 0 ] && { echo -e "\e[31mPlease run this script as root user.\e[0m"; exit 1; }

ADD() {
	[ $# -eq 0 ] && return
	for app in "$@"; do
		echo -e "\e[33mINPUTSTALL [$app]\e[0m"
		case $(command -v apk || command -v apt || command -v dnf || command -v opkg || command -v pacman || command -v yum || command -v zypper) in
			*apk) apk info "$app" &>/dev/null || { apk update && apk add "$app"; };;
			*apt) dpkg -l | grep -qw "$app" || { apt update -y && apt install -y "$app"; };;
			*dnf) dnf list installed "$app" &>/dev/null || { dnf -y update && dnf install -y epel-release "$app"; };;
			*opkg) opkg list-installed | grep -qw "$app" || { opkg update && opkg install "$app"; };;
			*pacman) pacman -Q "$app" &>/dev/null || { pacman -Syu --noconfirm && pacman -S --noconfirm "$app"; };;
			*yum) yum list installed "$app" &>/dev/null || { yum -y update && yum install -y epel-release "$app"; };;
			*zypper) zypper se --installed-only "$app" &>/dev/null || { zypper refresh && zypper install -y "$app"; };;
			*) return;;
		esac
		echo -e "\e[32mFINPUTISHED\e[0m"
		echo
	done
}
DEL() {
	[ $# -eq 0 ] && return
	for app in "$@"; do
		echo -e "\e[33mREMOVE [$app]\e[0m"
		case $(command -v apk || command -v apt || command -v dnf || command -v opkg || command -v pacman || command -v yum || command -v zypper) in
			*apk) apk info "$app" &>/dev/null && apk del "$app";;
			*apt) dpkg -l | grep -q "^ii  $app" && apt purge -y "$app";;
			*dnf) dnf list installed "$app" &>/dev/null && dnf remove -y "$app";;
			*opkg) opkg list-installed | grep -q "$app" && opkg remove "$app";;
			*pacman) pacman -Q "$app" &>/dev/null && pacman -Rns --noconfirm "$app";;
			*yum) yum list installed "$app" &>/dev/null && yum remove -y "$app";;
			*zypper) zypper se --installed-only "$app" | grep -q "$app" && zypper remove -y "$app";;
			*) return;;
		esac
		echo -e "\e[32mFINPUTISHED\e[0m"
		echo
	done
}
R() { echo -e "\e[31m$1\e[0m"; }
G() { echo -e "\e[32m$1\e[0m"; }
Y() { echo -e "\e[33m$1\e[0m"; }
C() { echo -e "\e[96m$1\e[0m"; }
BB() { echo -e "\e[40m$1\e[0m"; }
BR() { echo -e "\e[41m\e[37m\e[1m$1\e[0m"; }
BG() { echo -e "\e[42m\e[90m\e[1m$1\e[0m"; }
CD() { cd ~; clear; }
LI() { C $(printf '%*s' "24" '' | tr ' ' "-"); }
DLI() { C $(printf '%*s' "24" '' | tr ' ' "="); }
INPUT() { read -e -p "Please input: " sel; }
OC() { G "FINISHED"; read -n 1 -s -r -p "Press any key to couture..."; CD; }

ADD sudo tar unzip &>/dev/null

Dis_OPT() {
	local count=1
	local max_cols=1
	local col_options=()
	print_row() {
		for option in "$@"; do
			if [[ $option == @* ]]; then
				printf "     %-16s" "${option#@}"
			elif [[ $option == \#* ]]; then
				printf "%s" "${option#\#}"
			else
				printf "$(C "%3d.") %-16s" "$count" "$option"
				((count++))
			fi
		done
		echo
	}
	for option in "${OPT[@]}"; do
		case "$option" in
			"LI") LI; col_options=() ;;
			"-"*)
				max_cols=${option//[-]/}
				[ ${#col_options[@]} -gt 0 ] && print_row "${col_options[@]}"
				col_options=()
				;;
			*)
				col_options+=("$option")
				[ ${#col_options[@]} -eq $max_cols ] && { print_row "${col_options[@]}"; col_options=(); }
				;;
		esac
	done
	[ ${#col_options[@]} -gt 0 ] && print_row "${col_options[@]}"
}
Run_ACT() {
	local return=${1:-Menu}
	local count=1
	for action in "${ACT[@]}"; do
		[ "$sel" = "$count" ] && { CD; IFS=';' read -ra steps <<< "$action"; for step in "${steps[@]}"; do eval "$step"; done; OC; return 0; }
		((count++))
	done
	[ $count -gt ${#ACT[@]} ] && case $sel in 0) $return;; *) CD;; esac
}

Copyright() {
	C $(printf '%*s' "56" '' | tr ' ' "=")
	Y "\e[1mOG|OS OGATA-Open-Source"
	C $(printf '%*s' "56" '' | tr ' ' "-")
	echo "Copyright (C) 2024 OG|OS OGATA-Open-Source. All Rights Reserved."
	echo "Licensed under the MIT License."
	C $(printf '%*s' "56" '' | tr ' ' "-")
	echo
	G "\e[1mCopyright Notice"
	C $(printf '%*s' "56" '' | tr ' ' "-")
	echo "This script and its related files are developed and maintained by the OG|OS OGATA-Open-Source team,"
	echo "for automated operations in system management, monitoring, and related tools."
	echo
	Y "\e[1mLicense Terms:"
	echo
	echo "This script is released under the $(echo -e "\e[36m\e[1mMIT License\e[0m"). You are free to use, modify, distribute, and reissue this software under the following terms:"
	echo
	echo "1. $(C "\e[1mSource Code Retention"): This copyright notice and the original author information must be retained. Any form of reissue must include this license statement."
	echo
	echo "2. $(C "\e[1mNo Warranty"): This software is provided 'as is', and OG|OS OGATA-Open-Source is not responsible for any issues or damages arising from its use."
	echo
	echo "3. $(C "\e[1mUsage Restrictions"): It can be used for personal, commercial, or academic purposes, but the authors and source of this software must be clearly stated."
	echo
	echo "4. $(C "\e[1mContributor License"): Modified versions can be made public, but the original information must be retained, and personal copyright statements may be added."
	echo
	Y "\e[1mDisclaimer:"
	echo
	echo "Use of this software is at your own risk. OG|OS OGATA-Open-Source or its contributors are not liable for any damages resulting from the use of this software."
	echo
	echo "For more information, please visit:"
	echo -e "\e[36m\e[1mOG|OS OGATA-Open-Source GitHub page: https://github.com/OG-Open-Source\e[0m"
	C $(printf '%*s' "56" '' | tr ' ' "=")
}

Sub_Menu() {
	local return="$1"
	while true; do
		CD
		for text in "${TXT[@]}"; do
			[ "$text" = "LI" ] && LI || [ "$text" = "DLI" ] && DLI ||  C "$text"
		done
		DLI
		Dis_OPT
		DLI
		G "  0. Back"
		DLI
		INPUT
		Run_ACT "$return"
	done
}
Menu() {
	while true; do
		CD
		Y "\e[1m ____   _______                     _       _     "
		Y "\e[1m/_ \ \ / / ____|                   | |     | |    "
		Y "\e[1m | |\ V / |  __ _   _  __ _ _ __ __| |  ___| |__  "
		Y "\e[1m | | > <| | |_ | | | |/ _' | '__/ _' | / __| '_ \ "
		Y "\e[1m | |/ . \ |__| | |_| | (_| | | | (_| |_\__ \ | | |"
		Y "\e[1m |_/_/ \_\_____|\__,_|\__,_|_|  \__,_(_)___/_| |_|"
		DLI
		OPT=(
			"查看守護文件"
			"添加文件守護"
			"移除文件守護"
			LI
			"安全性檢測"
			"安裝 ClamAV"
			"安裝 iptable"
			"安裝 ufw"
			LI
			"腳本版權"
		)
		Dis_OPT
		DLI
		G "  0. Exit"
		DLI
		INPUT
		case $sel in
			8) CD; Copyright; OC; Menu;;
			0) CD; exit;;
			*) CD;;
		esac
	done
}
Menu
#!/bin/bash

SH="$0"
X="/usr/local/bin/x"
[ ! -f "$SH~" ] && { gzexe $SH; rm "$SH~"; touch "$SH~" ; }
cp -f "$SH" "$X" &>/dev/null

FILE="function.sh"
[ ! -f "$FILE" ] && curl -sSL "https://raw.ogtt.tk/shell/function.sh" -o "$FILE"
[ -f "$FILE" ] && source "$FILE"

CHECK_ROOT

CLR1="\033[31m"
CLR2="\033[32m"
CLR3="\033[0;33m"
CLR4="\033[34m"
CLR5="\033[35m"
CLR6="\033[36m"
CLR7="\033[37m"
CLR8="\033[96m"
CLR9="\033[97m"
CLR0="\033[0m"

LI() { echo -e "${CLR8}$(LINE - "24")${CLR0}" ; }
DLI() { echo -e "${CLR8}$(LINE = "24")${CLR0}" ; }
IN() { DLI ; INPUT "請輸入：" sel ; }
INC() { DLI ; INPUT "確認繼續嗎？(Y/N)：" sel ; }
OC() { echo -e "${CLR2}完成${CLR0}" ; read -n 1 -s -r -p "按任意鍵繼續..." ; CLEAN ; }

ADD sudo jq tar unzip &>/dev/null
Dis_TXT() {
	CLEAN
	for i in "${!TXT[@]}"; do
		case "$i" in
			0) echo -e "${CLR3}${TXT[$i]}${CLR0}" ;;
			1) DLI ; echo -e "${CLR8}${TXT[$i]}${CLR0}" ;;
			*) case "${TXT[$i]}" in
				"LI") LI ;;
				*) echo -e "${CLR8}${TXT[$i]}${CLR0}" ;;
			esac ;;
		esac
	done
	DLI
}
Dis_OPT() {
	count=1
	max_cols=1
	col_options=()
	print_row() {
		for option in "$@"; do
			if [[ $option == @* ]]; then
				printf "     %-16s" "${option#@}"
			elif [[ $option == \#* ]]; then
				printf "%s" "${option#\#}"
			else
				printf "$(echo -e "${CLR8}%3d.${CLR0}") %-16s" "$count" "$option"
				((count++))
			fi
		done
		echo
	}
	for option in "${OPT[@]}"; do
		case "$option" in
			"LI") LI ; col_options=() ;;
			"-"*)
				max_cols=${option//[-]/}
				[ ${#col_options[@]} -gt 0 ] && print_row "${col_options[@]}"
				col_options=()
				;;
			*)
				col_options+=("$option")
				[ ${#col_options[@]} -eq $max_cols ] && { print_row "${col_options[@]}" ; col_options=() ; }
				;;
		esac
	done
	[ ${#col_options[@]} -gt 0 ] && print_row "${col_options[@]}"
	DLI
}
Run_ACT() {
	return=${1:-Menu}
	count=1
	for action in "${ACT[@]}"; do
		[ "$sel" = "$count" ] && { CLEAN ; IFS=';' read -ra steps <<< "$action" ; for step in "${steps[@]}" ; do eval "$step" ; done ; OC ; return 0 ; }
		((count++))
	done
	[ $count -gt ${#ACT[@]} ] && case $sel in 0) $return ;; *) CLEAN ;; esac
}

Tools() {
	TXT=(
		" > 安裝工具"
		這裡您可以安裝各種常用的系統工具和軟體
		包括網絡工具、系統監控、文本編輯器等
	)
	OPT=(
		-3-
		"cURL" "Wget" "Socat"
		-2-
		"htop" "iftop"
		"tmux" "FFmpeg"
		LI
		"btop" "ncdu"
		"Ranger" "fzf"
		"Vim" "Nano"
		-1-
		"Git"
		LI
		"安裝以上所有工具"
		"移除以上所有工具"
		LI
		"安裝指定工具"
		"移除指定工具"
	)
	ACT=(
		"ADD curl ; CLEAN ; curl --help"
		"ADD wget ; CLEAN ; wget --help"
		"ADD socat; CLEAN ; socat -help"
		"ADD htop ; CLEAN ; htop"
		"ADD iftop ; CLEAN ; iftop"
		"ADD tmux ; CLEAN ; tmux --help"
		"ADD ffmpeg ; CLEAN ; ffmpeg --help"
		"ADD btop ; CLEAN ; btop"
		"ADD ncdu ; cd / ; CLEAN ; ncdu"
		"ADD ranger ; cd / ; CLEAN ; ranger"
		"ADD fzf ; cd / ; CLEAN ; fzf"
		"ADD vim ; cd / ; CLEAN ; vim -h"
		"ADD nano ; cd / ; CLEAN ; nano -h"
		"ADD git ; cd / ; CLEAN ; git --help"
		"ADD curl wget socat htop iftop tmux ffmpeg btop ncdu ranger fzf vim nano git"
		"DEL curl wget socat htop iftop tmux ffmpeg btop ncdu ranger fzf vim nano git"
		"Install_Tool"
		"Remove_Tool"
	)
	Install_Tool() { INPUT 請輸入欲安裝工具： Tools && ADD $Tools ; }
	Remove_Tool() { INPUT 請輸入欲移除工具： Tools && DEL $Tools ; }
	Sub_Menu
}
Setting() {
	TXT=(
		" > 腳本設定"
		這裡您可以進行腳本的相關設定
		包括更新、卸載等操作
	)
	OPT=(
		"快捷鍵設定"
		"切換腳本語言"
		"腳本版權及授權"
		"卸載腳本"
	)
	ACT=(
		"Hotkey; Sub_Menu 'Setting'"
		"Language; Sub_Menu 'Setting'"
		"Copyright; Sub_Menu 'Setting'"
		"Remove; Sub_Menu 'Setting'"
	)
	Hotkey() {
		TXT=(
			" > > 快捷鍵設定"
			這裡您可以設定腳本的快捷鍵
		)
		OPT=(
			"設置快捷鍵"
			"查看當前快捷鍵"
		)
		ACT=(
			"Set_Hotkey; Sub_Menu 'Hotkey'"
			"Show_Hotkeys; Sub_Menu 'Hotkey'"
		)
		Set_Hotkey() {
			INPUT "請輸入新的快捷鍵：" new_hotkey
			# 假設有一個變量保存當前快捷鍵
			CURRENT_HOTKEY="$new_hotkey"
			echo -e "快捷鍵已設置為: ${CLR2}$CURRENT_HOTKEY${CLR0}"
		}
		Show_Hotkeys() {
			echo -e "當前快捷鍵為: ${CLR2}$CURRENT_HOTKEY${CLR0}"
		}
	}
	Language() {
		TXT=(
			" > > 切換腳本語言"
			這裡您可以選擇腳本的語言
		)
		OPT=(
			"中文"
			"英文"
		)
		ACT=(
			"Set_Language 'zh'; Sub_Menu 'Language'"
			"Set_Language 'en'; Sub_Menu 'Language'"
		)
		Set_Language() {
			lang="$1"
			echo -e "語言已切換為: ${CLR2}$lang${CLR0}"
		}
	}
	Copyright() {
		echo -e "${CLR8}$(LINE = "56")${CLR0}"
		echo -e "${CLR8}OG|OS OGATA-Open-Source${CLR0}"
		echo -e "${CLR8}$(LINE - "56")${CLR0}"
		echo "Copyright (C) 2024 OG|OS OGATA-Open-Source. All Rights Reserved."
		echo "Licensed under the MIT License."
		echo -e "${CLR8}$(LINE - "56")${CLR0}"
		echo -e "\n${CLR2}版權聲明 (Copyright Notice)${CLR0}"
		echo -e "${CLR8}$(LINE - "56")${CLR0}"
		echo "本腳本及其相關文件由 OG|OS OGATA-Open-Source 團隊開發和維護，"
		echo "用於系統管理、監控及相關工具的自動化操作。"
		echo -e "\n${CLR3}授權條款：${CLR0}"
		echo -e "\n本腳本基於 ${CLR6}MIT 許可證${CLR0} 發佈。您有權在遵循以下條款的前提下自由使用、修改、分發和再發行本軟件："
		echo -e "\n1. ${CLR8}源代碼的保留${CLR0}：必須保留此版權聲明及原始作者信息。任何形式的再發行必須包含此許可證聲明。"
		echo -e "\n2. ${CLR8}不提供擔保${CLR0}：本軟件按「現狀」提供，OG|OS OGATA-Open-Source 不對其使用過程中的任何問題或損害負責。"
		echo -e "\n3. ${CLR8}用途限制${CLR0}：可用於個人、商業或學術用途，但必須明確聲明本軟件的作者和來源。"
		echo -e "\n4. ${CLR8}貢獻者許可${CLR0}：修改版可公開，但必須保留原始信息並可添加個人版權聲明。"
		echo -e "\n${CLR3}免責聲明：${CLR0}"
		echo -e "\n使用本軟件時，風險自負。OG|OS OGATA-Open-Source 或其貢獻者不對使用本軟件導致的任何損害承擔責任。"
		echo -e "\n更多信息，請訪問："
		echo -e "${CLR8}OG|OS OGATA-Open-Source GitHub 頁面：${CLR0}https://github.com/OG-Open-Source"
		echo -e "${CLR8}$(LINE = "56")${CLR0}"
		OC
	}
	Remove() {
		TXT=(
			" > > 卸載腳本"
			這裡您可以卸載腳本
		)
		OPT=(
			"確認卸載"
		)
		ACT=(
			"Confirm_Remove; Sub_Menu 'Remove'"
		)
		Confirm_Remove() {
			INC
			if [[ $sel =~ ^[Yy]$ ]]; then
				echo -e "${CLR2}腳本已卸載。${CLR0}"
				exit
			else
				echo -e "${CLR2}卸載已取消。${CLR0}"
			fi
		}
	}
	Sub_Menu
}
SYS_Setting() {
	TXT=(
		" > 系統設定"
		這裡您可以進行系統的相關設定
		包括網絡配置、用戶管理、安全設置等操作
	)
	OPT=(
		"網路管理"
		"用戶管理"
		"安全性"
	)
	ACT=(
		"Network_Manger; Sub_Menu 'SYS_Setting'"
		"User_Manger; Sub_Menu 'SYS_Setting'"
		"Security_Manger; Sub_Menu 'SYS_Setting'"
	)
	Network_Manger() {
		TXT=(
			" > > 網路管理"
			這裡您可以進行網路相關的設定
		)
		OPT=(
			"查看網路配置"
			"修改IP地址"
			"設置DNS"
		)
		ACT=(
			"ifconfig"
			"Edit_IP"
			"Edit_DNS"
		)
	}
	User_Manger() {
		TXT=(
			" > > 用戶管理"
			這裡您可以進行用戶相關的操作
		)
		OPT=(
			"添加用戶"
			"刪除用戶"
			"修改用戶密碼"
		)
		ACT=(
			"Add_User"
			"Del_User"
			"Change_Password"
		)
	}
	Security_Manger() {
		TXT=(
			" > > 安全性"
			這裡您可以進行系統安全相關的設置
		)
		OPT=(
			"防火牆設置"
			"SSH設置"
			"系統更新"
		)
		ACT=(
			"Firewall_Settings"
			"SSH_Settings"
			"System_Update"
		)
	}
	Sub_Menu
}
File_Manager() {
	ip=20
	c=0
	s=""
	d=$(pwd)
	f() {
		a=$1
		b=$2
		r=$3
		CLEAN
		echo -e "${CLR8}Current Directory: ${CLR3}$d${CLR0}"
		printf "${CLR8}%89s\n" | tr ' ' '-'
		printf "${CLR2}%-28s %-20s %-14s %-10s %s${CLR0}\n" "Name" "Modification Date" "Size" "Type" "Permissions"
		printf "${CLR8}%89s\n" | tr ' ' '-'
		find "$d" -maxdepth 1 | tail -n +2 | awk -v a="$a" -v b="$b" -v r="$r" '
		NR > a && NR <= b {
			cmd = "stat --format=\"%y\" \""$0"\" | cut -d \".\" -f 1 | cut -c1-16"
			cmd | getline dt
			close(cmd)
			cmd = "stat --format=\"%A %s %n\" \""$0"\""
			cmd | getline fi
			close(cmd)
			split(fi, ia, " ")
			p = ia[1]
			sz = ia[2]
			n = gensub(/.*\//, "", "g", $0)
			if (r == "" || tolower(n) ~ tolower(r)) {
				t = (p ~ /^d/) ? "Directory" : (p ~ /^l/) ? "Link" : "File"
				tc = (p ~ /^d/) ? "'$CLR4'" : (p ~ /^l/) ? "'$CLR6'" : "'$CLR2'"
				if (length(n) > 28) n = substr(n, 1, 25) "...";
				u = (sz >= 1048576) ? "MiB" : (sz >= 1024) ? "KiB" : "Bytes"
				nm = (sz >= 1048576) ? sz/1048576 : (sz >= 1024) ? sz/1024 : sz
				printf "'$CLR9'%-28s'$CLR0' '$CLR3'%-16s'$CLR0' '$CLR6'%8.2f %-6s'$CLR0'    %s%-10s'$CLR0' '$CLR2'%s'$CLR0'\n", \
					n, dt, nm, u, tc, t, p
			}
		}'
		i=$(find "$d" -maxdepth 1 | tail -n +2 | awk -v a="$a" -v b="$b" -v r="$r" 'NR > a && NR <= b && (r == "" || tolower($0) ~ tolower(r)) {print}' | wc -l)
		for (( j=i; j<ip; j++ )); do
			printf "%-28s %-20s %-14s %-10s %s\n" "" "" "" "" ""
		done
		printf "${CLR8}%89s\n" | tr ' ' '-'
		echo -e "${CLR2}Page: ${CLR3}$((c + 1))/${t}${CLR0}"
		printf "${CLR8}%89s\n" | tr ' ' '-'
	}
	r() {
		o=$(find "$d" -maxdepth 1 | tail -n +2 | wc -l)
		t=$(( (o + ip - 1) / ip ))
		f $((c * ip)) $(( (c + 1) * ip )) "$s"
	}
	n() {
		eval "$@"
		r
	}
	r
	OPT=(
		-2-
		"Up" "Down"
		-2-
		"Prev" "Next"
		LI
		-2-
		"Search" "Refresh"
		-3-
		"New File" "New Dir" "Delete"
		"Rename" "Permissions" "Edit"
		LI
		"Copy" "Move" "Tar/Untar"
	)
	while true; do
		Dis_OPT
		echo -e "${CLR2}  0. 返回${CLR0}"
		IN
		case "$sel" in
			1) n "d=$(dirname "$d")" ;;
			2) n "read -e -p '輸入目錄：' sd && [[ -d \"\$d/\$sd\" ]] && d=\$(realpath \"\$d/\$sd\") || { echo '目錄「\$sd」不存在。'; sleep 1; }" ;;
			3) n "((c > 0)) && ((c--))" ;;
			4) n "((c < t - 1)) && ((c++))" ;;
			5) n "read -e -p '輸入搜尋詞：' s" ;;
			6) n "s=""";;
			7) n "read -e -p '輸入新檔案名稱：' nf && touch \"\$d/\$nf\"" ;;
			8) n "read -e -p '輸入新資料夾名稱：' nd && mkdir -p \"\$d/\$nd\"" ;;
			9) n "read -e -p '輸入要刪除的檔案（以逗號分隔，或輸入「/all」刪除所有檔案）：' del_files && del_files=\${del_files// /} && if [[ \"\$del_files\" == \"/all\" ]]; then rm -rf \"\$d\"/*; else IFS=',' read -ra files <<< \"\$del_files\" && for file in \"\${files[@]}\"; do rm -rf \"\$d/\$file\"; done; fi" ;;
			10) n "read -e -p '輸入要重新命名的檔案：' old_name && read -e -p '輸入新名稱：' new_name && mv \"\$d/\$old_name\" \"\$d/\$new_name\"" ;;
			11) n "read -e -p '輸入要更改權限的檔案（以逗號分隔，或輸入「/all」更改所有檔案）：' perm_files && perm_files=\${perm_files// /} && read -e -p '輸入新權限：' perms && if [[ \"\$perm_files\" == \"/all\" ]]; then chmod -R \"\$perms\" \"\$d\"; else IFS=',' read -ra files <<< \"\$perm_files\" && for file in \"\${files[@]}\"; do chmod \"\$perms\" \"\$d/\$file\"; done; fi" ;;
			12) n "read -e -p '輸入要編輯的檔案：' edit_file && nano \"\$d/\$edit_file\"" ;;
			13) n "read -e -p '輸入要複製的檔案（以逗號分隔，或輸入「/all」複製所有檔案）：' copy_files && copy_files=\${copy_files// /} && read -e -p '輸入目標目錄：' dest && if [[ \"\$copy_files\" == \"/all\" ]]; then cp -r \"\$d\"/* \"\$dest\"; else IFS=',' read -ra files <<< \"\$copy_files\" && for file in \"\${files[@]}\"; do cp -r \"\$d/\$file\" \"\$dest\"; done; fi" ;;
			14) n "read -e -p '輸入要移動的檔案（以逗號分隔，或輸入「/all」移動所有檔案）：' move_files && move_files=\${move_files// /} && read -e -p '輸入目標目錄：' dest && if [[ \"\$move_files\" == \"/all\" ]]; then mv \"\$d\"/* \"\$dest\"; else IFS=',' read -ra files <<< \"\$move_files\" && for file in \"\${files[@]}\"; do mv \"\$d/\$file\" \"\$dest\"; done; fi" ;;
			15) n "read -e -p '輸入要壓縮／解壓縮的檔案（以逗號分隔，或輸入「/all」壓縮／解壓縮所有檔案）：' tar_files && tar_files=\${tar_files// /} && if [[ \"\$tar_files\" == \"/all\" ]]; then tar -czf \"\$d/all_files.tar.gz\" -C \"\$d\" .; else IFS=',' read -ra files <<< \"\$tar_files\" && for file in \"\${files[@]}\"; do if [[ \$file == *.tar.gz ]]; then tar -xzf \"\$d/\$file\" -C \"\$d\"; else tar -czf \"\$d/\$file.tar.gz\" -C \"\$d\" \"\$file\"; fi; done; fi" ;;
			0) break ;;
			*) n ;;
		esac
	done
}

Sub_Menu() {
	return="$1"
	while true ; do
		Dis_TXT
		Dis_OPT
		echo -e "${CLR2}  0. 返回${CLR0}"
		IN
		Run_ACT "$return"
	done
}
Menu() {
	while true ; do
		TXT=(
			" ____   __                        _
/_ \ \ / /                       | |
 | |\ V / ___ ___  _ __ ___   ___| |__
 | | ) ( / __/ _ \| '__/ _ \ / __| '_ \ 
 | |/ . \ (_| (_) | | |  __/_\__ \ | | |
 |_/_/ \_\___\___/|_|  \___(_)___/_| |_|"
			"本腳本採用 ${CLR3}1XGuard${CLR8} 以確保安全性，防止未經授權的訪問${CLR0}"
			"快捷鍵 ${CLR3}'x'${CLR8}: 您可以在任何目錄中輸入 ${CLR3}'x'${CLR8} 以快速啟動此腳本。${CLR0}"
		)
		OPT=(
			"系統資訊"
			"更新軟體"
			"清理系統"
			LI
			"安裝工具"
			"檔案管理器"
			LI
			"腳本設定"
			"系統設定"
		)
		Dis_TXT
		Dis_OPT
		echo -e "${CLR2}  0. 退出${CLR0}"
		IN
		case $sel in
			1) CLEAN ; SYS_INFO ; OC ; Menu ;;
			2) CLEAN ; SYS_UPDATE ; OC ; Menu ;;
			3) CLEAN ; SYS_CLEAN ; OC ; Menu ;;
			4) Tools ; Sub_Menu ;;
			5) File_Manager ;;
			6) Setting ; Sub_Menu ;;
			7) SYS_Setting ; Sub_Menu ;;
			0) CLEAN ; exit ;;
			*) CLEAN ;;
		esac
	done
}
Menu
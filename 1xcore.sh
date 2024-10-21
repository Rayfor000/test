#!/bin/bash
# Description: 1xcore.sh is a shell script for installing and managing 1xcore.
# Author: OGATA Open-Source
# Version: 1.001.001

SH="1xcore.sh"
X="/usr/local/bin/x"
cp -f "$SH" "$X" &>/dev/null

[ -f ~/function.sh ] && source ~/function.sh || bash <(curl -sL raw.ogtt.tk/shell/update-function.sh)

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

LI() { echo -e "${CLR8}$(LINE - "24")${CLR0}"; }
DLI() { echo -e "${CLR8}$(LINE = "24")${CLR0}"; }
IN() { DLI; INPUT "請輸入：" sel; }
INC() { DLI; INPUT "確認繼續嗎？(Y/N)：" sel; }
OC() { echo -e "${CLR2}完成${CLR0}"; read -n 1 -s -r -p "按任意鍵繼續..."; CLEAN; }

ADD curl jq sudo tar unzip wget &>/dev/null

Dis_TXT() {
	CLEAN
	for i in "${!TXT[@]}"; do
		case "$i" in
			0) echo -e "${CLR3}${TXT[$i]}${CLR0}";;
			1) DLI; echo -e "${CLR8}${TXT[$i]}${CLR0}";;
			*) case "${TXT[$i]}" in
				"LI") LI;;
				*) echo -e "${CLR8}${TXT[$i]}${CLR0}";;
			esac;;
		esac
	done
	DLI
}
Dis_OPT() {
	count=1
	max_cols=1
	col_options=()
	string_width() {
		str="$1"
		width=0
		for (( i=0; i<${#str}; i++ )); do
			char="${str:$i:1}"
			if [[ $char =~ [[:print:]] ]]; then
				if [[ $char =~ [[:ascii:]] ]]; then
					((width++))
				else
					((width+=2))
				fi
			fi
		done
		echo $width
	}
	print_row() {
		max_width=20
		for option in "$@"; do
			option_width=$(string_width "$option")
			padding=$((max_width - option_width))
			printf "$(echo -e "${CLR8}%3d.${CLR0}") %s%*s" "$count" "$option" $padding " "
			((count++))
		done
		echo
	}
	for option in "${OPT[@]}"; do
		case "$option" in
			"LI") LI; col_options=();;
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
	DLI
}
Run_ACT() {
	return=${1:-Menu}
	count=1
	for action in "${ACT[@]}"; do
		[ "$sel" = "$count" ] && { CLEAN; IFS=';' read -ra steps <<< "$action"; for step in "${steps[@]}"; do eval "$step"; done; return 0; }
		((count++))
	done
	[ $count -gt ${#ACT[@]} ] && case $sel in 0) $return;; *) CLEAN;; esac
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
		"ADD curl; CLEAN; curl --help; OC"
		"ADD wget; CLEAN; wget --help; OC"
		"ADD socat; CLEAN; socat -help; OC"
		"ADD htop; CLEAN; htop; OC"
		"ADD iftop; CLEAN; iftop; OC"
		"ADD tmux; CLEAN; tmux --help; OC"
		"ADD ffmpeg; CLEAN; ffmpeg --help; OC"
		"ADD btop; CLEAN; btop; OC"
		"ADD ncdu; cd /; CLEAN; ncdu; OC"
		"ADD ranger; cd /; CLEAN; ranger; OC"
		"ADD fzf; cd /; CLEAN; fzf; OC"
		"ADD vim; cd /; CLEAN; vim -h; OC"
		"ADD nano; cd /; CLEAN; nano -h; OC"
		"ADD git; cd /; CLEAN; git --help; OC"
		"ADD curl wget socat htop iftop tmux ffmpeg btop ncdu ranger fzf vim nano git; OC"
		"DEL curl wget socat htop iftop tmux ffmpeg btop ncdu ranger fzf vim nano git; OC"
		"Install_Tool; OC"
		"Remove_Tool; OC"
	)
	Install_Tool() { INPUT 請輸入欲安裝工具： Tools && ADD $Tools; }
	Remove_Tool() { INPUT 請輸入欲移除工具： Tools && DEL $Tools; }
	Sub_Menu
}
Setting() {
	TXT=(
		" > 腳本設定"
		這裡您可以進行腳本的相關設定
		包括更新、卸載等操作
	)
	OPT=(
		"腳本版權及授權"
		"卸載腳本"
	)
	ACT=(
		"Copyright"
		"rm -f $SH; rm -f $X"
	)
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
	Sub_Menu
}
File_Manager() {
	items_per_page=15
	current_page=0
	search_term=""
	current_dir=$(pwd)
	dis_files() {
		start=$1
		end=$2
		regex=$3
		CLEAN
		echo -e "${CLR8}當前目錄：${CLR3}$current_dir${CLR0}"
		echo -e "${CLR8}$(LINE - "89")"
		printf "${CLR2}%-30s %-24s %-20s %-10s %s${CLR0}\n" "名稱" "修改日期" "大小" "種類" "權限"
		echo -e "${CLR8}$(LINE - "89")"
		find "$current_dir" -maxdepth 1 | tail -n +2 | awk -v start="$start" -v end="$end" -v regex="$regex" '
		NR > start && NR <= end {
			cmd = "stat --format=\"%y\" \""$0"\" | cut -d \".\" -f 1 | cut -c1-16"
			cmd | getline dt
			close(cmd)
			cmd = "stat --format=\"%A %s %n\" \""$0"\""
			cmd | getline fi
			close(cmd)
			split(fi, ia, " ")
			p = ia[1]
			sz = ia[2]
			n = $0
			gsub(/.*\//, "", n)
			if (regex == "" || tolower(n) ~ tolower(regex)) {
				t = (p ~ /^d/) ? "目錄" : (p ~ /^l/) ? "連結" : "文件"
				tc = (p ~ /^d/) ? "'$CLR4'" : (p ~ /^l/) ? "'$CLR6'" : "'$CLR2'"
				if (length(n) > 28) n = substr(n, 1, 25) "...";
				u = (sz >= 1048576) ? "MiB" : (sz >= 1024) ? "KiB" : "Bytes"
				nm = (sz >= 1048576) ? sz/1048576 : (sz >= 1024) ? sz/1024 : sz
				printf "'$CLR9'%-28s'$CLR0' '$CLR3'%-20s'$CLR0' '$CLR6'%8.2f %-9s'$CLR0' %s%-10s'$CLR0' '$CLR2'%s'$CLR0'\n", \
					n, dt, nm, u, tc, t, p
			}
		}'
		items=$(find "$current_dir" -maxdepth 1 | tail -n +2 | awk -v start="$start" -v end="$end" -v regex="$regex" 'NR > start && NR <= end && (regex == "" || tolower($0) ~ tolower(regex)) {print}' | wc -l)
		for (( j=items; j<items_per_page; j++ )); do
			printf "%-28s %-20s %-14s %-10s %s\n" "" "" "" "" ""
		done
		echo -e "${CLR8}$(LINE - "89")"
		echo -e "${CLR2}頁面：${CLR3}$((current_page + 1))/${total_pages}${CLR0}"
		echo -e "${CLR8}$(LINE - "89")"
	}
	refresh() {
		total_items=$(find "$current_dir" -maxdepth 1 | tail -n +2 | wc -l)
		total_pages=$(( (total_items + items_per_page - 1) / items_per_page ))
		dis_files $((current_page * items_per_page)) $(( (current_page + 1) * items_per_page )) "$search_term"
	}
	run_and_refresh() {
		eval "$@"
		refresh
	}
	refresh
	OPT=(
		-2-
		"上級目錄" "下級目錄"
		-2-
		"上一頁" "下一頁"
		LI
		-2-
		"搜尋" "刷新"
		-3-
		"創建文件" "創建目錄" "刪除"
		"重命名" "權限調整" "編輯文件"
		LI
		"複製" "移動" "壓縮/解壓縮"
	)
	while true; do
		Dis_OPT
		echo -e "${CLR2}  0. 返回${CLR0}"
		IN
		case "$sel" in
			1) run_and_refresh "current_dir=$(dirname "$current_dir")";;
			2) run_and_refresh "read -e -p '輸入目錄：' sub_dir && [[ -d \"\$current_dir/\$sub_dir\" ]] && current_dir=\$(realpath \"\$current_dir/\$sub_dir\") || { echo '目錄「\$sub_dir」不存在。'; sleep 1; }";;
			3) run_and_refresh "((current_page > 0)) && ((current_page--))";;
			4) run_and_refresh "((current_page < total_pages - 1)) && ((current_page++))";;
			5) run_and_refresh "read -e -p '輸入搜尋詞：' search_term";;
			6) run_and_refresh "search_term=""";;
			7) run_and_refresh "read -e -p '輸入新檔案名稱：' new_file && cmds=(\"touch \\\"\$current_dir/\$new_file\\\"\")";;
			8) run_and_refresh "read -e -p '輸入新資料夾名稱：' new_dir && cmds=(\"mkdir -p \\\"\$current_dir/\$new_dir\\\"\")";;
			9) run_and_refresh "read -e -p '輸入要刪除的檔案（以逗號分隔，或輸入「/all」刪除所有檔案）：' del_files && del_files=\${del_files// /} && if [[ \"\$del_files\" == \"/all\" ]]; then cmds=(\"rm -rf \\\"\$current_dir\\\"/*\"); else IFS=',' read -ra files <<< \"\$del_files\" && cmds=(); for file in \"\${files[@]}\"; do cmds+=(\"rm -rf \\\"\$current_dir/\$file\\\"\"); done; fi";;
			10) run_and_refresh "read -e -p '輸入要重新命名的檔案：' old_name && read -e -p '輸入新名稱：' new_name && cmds=(\"mv \\\"\$current_dir/\$old_name\\\" \\\"\$current_dir/\$new_name\\\"\")";;
			11) run_and_refresh "read -e -p '輸入要更改權限的檔案（以逗號分隔，或輸入「/all」更改所有檔案）：' perm_files && perm_files=\${perm_files// /} && read -e -p '輸入新權限：' perms && if [[ \"\$perm_files\" == \"/all\" ]]; then cmds=(\"chmod -R \\\"\$perms\\\" \\\"\$current_dir\\\"\"); else IFS=',' read -ra files <<< \"\$perm_files\" && cmds=(); for file in \"\${files[@]}\"; do cmds+=(\"chmod \\\"\$perms\\\" \\\"\$current_dir/\$file\\\"\"); done; fi";;
			12) run_and_refresh "read -e -p '輸入要編輯的檔案：' edit_file && nano \"\$current_dir/\$edit_file\"";;
			13) run_and_refresh "read -e -p '輸入要複製的檔案（以逗號分隔，或輸入「/all」複製所有檔案）：' copy_files && copy_files=\${copy_files// /} && read -e -p '輸入目標目錄：' dest && if [[ \"\$copy_files\" == \"/all\" ]]; then cmds=(\"cp -r \\\"\$current_dir\\\"/* \\\"\$dest\\\"\"); else IFS=',' read -ra files <<< \"\$copy_files\" && cmds=(); for file in \"\${files[@]}\"; do cmds+=(\"cp -r \\\"\$current_dir/\$file\\\" \\\"\$dest\\\"\"); done; fi";;
			14) run_and_refresh "read -e -p '輸入要移動的檔案（以逗號分隔，或輸入「/all」移動所有檔案）：' move_files && move_files=\${move_files// /} && read -e -p '輸入目標目錄：' dest && if [[ \"\$move_files\" == \"/all\" ]]; then cmds=(\"mv \\\"\$current_dir\\\"/* \\\"\$dest\\\"\"); else IFS=',' read -ra files <<< \"\$move_files\" && cmds=(); for file in \"\${files[@]}\"; do cmds+=(\"mv \\\"\$current_dir/\$file\\\" \\\"\$dest\\\"\"); done; fi";;
			15) run_and_refresh "read -e -p '輸入要壓縮／解壓縮的檔案（以逗號分隔，或輸入「/all」壓縮／解壓縮所有檔案）：' tar_files && tar_files=\${tar_files// /} && if [[ \"\$tar_files\" == \"/all\" ]]; then cmds=(\"tar -czf \\\"\$current_dir/all_files.tar.gz\\\" -C \\\"\$current_dir\\\" .\"); else IFS=',' read -ra files <<< \"\$tar_files\" && cmds=(); for file in \"\${files[@]}\"; do if [[ \$file == *.tar.gz ]]; then cmds+=(\"tar -xzf \\\"\$current_dir/\$file\\\" -C \\\"\$current_dir\\\"\"); else cmds+=(\"tar -czf \\\"\$current_dir/\$file.tar.gz\\\" -C \\\"\$current_dir\\\" \\\"\$file\\\"\"); fi; done; fi";;
			0) break;;
			*) run_and_refresh;;
		esac
		PROGRESS
	done
}

Sub_Menu() {
	return="$1"
	while true; do
		Dis_TXT
		Dis_OPT
		echo -e "${CLR2}  0. 返回${CLR0}"
		IN
		Run_ACT "$return"
	done
}
Menu() {
	while true; do
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
			1) CLEAN; SYS_INFO; OC; Menu;;
			2) CLEAN; SYS_UPDATE; OC; Menu;;
			3) CLEAN; SYS_CLEAN; OC; Menu;;
			4) Tools; Sub_Menu;;
			5) File_Manager;;
			6) Setting; Sub_Menu;;
			0) CLEAN; exit;;
			*) CLEAN;;
		esac
	done
}
Menu
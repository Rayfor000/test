#!/bin/bash

# Color definitions
CLR0="\033[0m"      # Reset
CLR1="\033[32m"     # Green
CLR2="\033[33m"     # Yellow
CLR3="\033[34m"     # Blue
CLR4="\033[36m"     # Cyan
CLR5="\033[97m"     # White

# Initialize variables
ITEMS_PER_PAGE=15
current_page=0
search_term=""
current_dir=$(pwd)

# Display files function
display_files() {
	start=$1
	end=$2
	regex=$3

	clear
	echo -e "${CLR4}當前目錄：${CLR2}$current_dir${CLR0}"
	echo -e "${CLR4}----------------------------------------------------------------------------------------${CLR0}"
	printf "${CLR1}%-30s %-24s %-20s %-10s %s${CLR0}\n" "名稱" "修改日期" "大小" "種類" "權限"
	echo -e "${CLR4}----------------------------------------------------------------------------------------${CLR0}"

	# List files with details
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
			tc = (p ~ /^d/) ? "'$CLR3'" : (p ~ /^l/) ? "'$CLR4'" : "'$CLR1'"
			if (length(n) > 28) n = substr(n, 1, 25) "...";
			u = (sz >= 1048576) ? "MiB" : (sz >= 1024) ? "KiB" : "Bytes"
			nm = (sz >= 1048576) ? sz/1048576 : (sz >= 1024) ? sz/1024 : sz
			printf "'$CLR5'%-28s'$CLR0' '$CLR2'%-20s'$CLR0' '$CLR4'%8.2f %-9s'$CLR0' %s%-10s'$CLR0' '$CLR1'%s'$CLR0'\n", \
				n, dt, nm, u, tc, t, p
		}
	}'

	# Calculate and display pagination info
	total_items=$(find "$current_dir" -maxdepth 1 | tail -n +2 | wc -l)
	total_pages=$(( (total_items + ITEMS_PER_PAGE - 1) / ITEMS_PER_PAGE ))
	echo -e "${CLR4}----------------------------------------${CLR0}"
	echo -e "${CLR1}頁面：${CLR2}$((current_page + 1))/${total_pages}${CLR0}"
	echo -e "${CLR4}----------------------------------------${CLR0}"
}

# Display menu
show_menu() {
	echo -e "\n${CLR1}操作選項：${CLR0}"
	echo -e "${CLR4}----------------------------------------${CLR0}"
	echo -e "${CLR5} 1.${CLR0} 上級目錄    ${CLR5}2.${CLR0} 進入目錄    ${CLR5}3.${CLR0} 上一頁"
	echo -e "${CLR5} 4.${CLR0} 下一頁      ${CLR5}5.${CLR0} 搜尋        ${CLR5}6.${CLR0} 刷新"
	echo -e "${CLR5} 7.${CLR0} 新建檔案    ${CLR5}8.${CLR0} 新建目錄    ${CLR5}9.${CLR0} 刪除"
	echo -e "${CLR5}10.${CLR0} 重命名     ${CLR5}11.${CLR0} 權限設定   ${CLR5}12.${CLR0} 編輯"
	echo -e "${CLR4}----------------------------------------${CLR0}"
	echo -e "${CLR5} 0.${CLR0} 退出"
	echo -e "${CLR4}----------------------------------------${CLR0}"
	echo -ne "${CLR1}請選擇：${CLR0}"
}

# Main loop
while true; do
	display_files $((current_page * ITEMS_PER_PAGE)) $(( (current_page + 1) * ITEMS_PER_PAGE )) "$search_term"
	show_menu
	read -r choice

	case "$choice" in
		0) clear; exit ;;
		1) current_dir=$(dirname "$current_dir") ;;
		2) read -e -p $'\033[36m輸入目錄名稱：\033[0m' dir_name
		   if [[ -d "$current_dir/$dir_name" ]]; then
			   current_dir="$current_dir/$dir_name"
		   else
			   echo "目錄不存在"; sleep 1
		   fi ;;
		3) ((current_page > 0)) && ((current_page--)) ;;
		4) ((current_page < total_pages - 1)) && ((current_page++)) ;;
		5) read -e -p $'\033[36m輸入搜尋關鍵字：\033[0m' search_term ;;
		6) search_term="" ;;
		7) read -e -p $'\033[36m輸入檔案名稱：\033[0m' file_name
		   touch "$current_dir/$file_name" ;;
		8) read -e -p $'\033[36m輸入目錄名稱：\033[0m' dir_name
		   mkdir -p "$current_dir/$dir_name" ;;
		9) read -e -p $'\033[36m輸入要刪除的檔案/目錄名稱：\033[0m' del_name
		   rm -ri "$current_dir/$del_name" ;;
		10) read -e -p $'\033[36m輸入原檔案名稱：\033[0m' old_name
			read -e -p $'\033[36m輸入新檔案名稱：\033[0m' new_name
			mv "$current_dir/$old_name" "$current_dir/$new_name" ;;
		11) read -e -p $'\033[36m輸入檔案名稱：\033[0m' chmod_file
			read -e -p $'\033[36m輸入權限數字（如：755）：\033[0m' perms
			chmod "$perms" "$current_dir/$chmod_file" ;;
		12) read -e -p $'\033[36m輸入檔案名稱：\033[0m' edit_file
			${EDITOR:-nano} "$current_dir/$edit_file" ;;
		*) echo "無效選項"; sleep 1 ;;
	esac
done
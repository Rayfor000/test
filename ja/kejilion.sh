#!/bin/bash
sh_v="4.2.1"


gl_hui='\e[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'


canshu="default"
permission_granted="false"
ENABLE_STATS="true"


quanju_canshu() {
if [ "$canshu" = "CN" ]; then
	zhushi=0
	gh_proxy="https://gh.kejilion.pro/"
elif [ "$canshu" = "V6" ]; then
	zhushi=1
	gh_proxy="https://gh.kejilion.pro/"
else
	zhushi=1  # 0 表示执行，1 表示不执行
	gh_proxy="https://"
fi

}
quanju_canshu



# 定义一个函数来执行命令
run_command() {
	if [ "$zhushi" -eq 0 ]; then
		"$@"
	fi
}


canshu_v6() {
	if grep -q '^canshu="V6"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/kejilion.sh
	fi
}


CheckFirstRun_true() {
	if grep -q '^permission_granted="true"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
	fi
}



# 收集功能埋点信息的函数，记录当前脚本版本号，使用时间，系统版本，CPU架构，机器所在国家和用户使用的功能名称，绝对不涉及任何敏感信息，请放心！请相信我！
# 为什么要设计这个功能，目的更好的了解用户喜欢使用的功能，进一步优化功能推出更多符合用户需求的功能。
# 全文可搜搜 send_stats 函数调用位置，透明开源，如有顾虑可拒绝使用。



send_stats() {
	if [ "$ENABLE_STATS" == "false" ]; then
		return
	fi

	local country=$(curl -s ipinfo.io/country)
	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')
	local cpu_arch=$(uname -m)

	(
		curl -s -X POST "https://api.kejilion.pro/api/log" \
			-H "Content-Type: application/json" \
			-d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\",\"version\":\"$sh_v\"}" \
		&>/dev/null
	) &

}


yinsiyuanquan2() {

if grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
	sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
fi

}



canshu_v6
CheckFirstRun_true
yinsiyuanquan2


sed -i '/^alias k=/d' ~/.bashrc > /dev/null 2>&1
sed -i '/^alias k=/d' ~/.profile > /dev/null 2>&1
sed -i '/^alias k=/d' ~/.bash_profile > /dev/null 2>&1
cp -f ./kejilion.sh ~/kejilion.sh > /dev/null 2>&1
cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1



CheckFirstRun_false() {
	if grep -q '^permission_granted="false"' /usr/local/bin/k > /dev/null 2>&1; then
		UserLicenseAgreement
	fi
}

# 提示用户同意条款
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}KejiLionスクリプトツールボックスへようこそ${gl_bai}"
	echo "初めてスクリプトを使用する場合、まずユーザーライセンス契約をお読みいただき、同意してください。"
	echo "ユーザーライセンス契約: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "上記規約に同意しますか？ \(y/N\): " user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "许可同意"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "许可拒绝"
		clear
		exit
	fi
}

CheckFirstRun_false





ip_address() {

get_public_ip() {
	curl -s https://ipinfo.io/ip && echo
}

get_local_ip() {
	ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || \
	hostname -I 2>/dev/null | awk '{print $1}' || \
	ifconfig 2>/dev/null | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1
}

public_ip=$(get_public_ip)
isp_info=$(curl -s --max-time 3 http://ipinfo.io/org)


if echo "$isp_info" | grep -Eiq 'mobile|unicom|telecom'; then
  ipv4_address=$(get_local_ip)
else
  ipv4_address="$public_ip"
fi


# ipv4_address=$(curl -s https://ipinfo.io/ip && echo)
ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)

}



install() {
	if [ $# -eq 0 ]; then
		echo "パッケージパラメータが提供されていません！"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}$package をインストールしています...${gl_bai}"
			if command -v dnf &>/dev/null; then
				dnf -y update
				dnf install -y epel-release
				dnf install -y "$package"
			elif command -v yum &>/dev/null; then
				yum -y update
				yum install -y epel-release
				yum install -y "$package"
			elif command -v apt &>/dev/null; then
				apt update -y
				apt install -y "$package"
			elif command -v apk &>/dev/null; then
				apk update
				apk add "$package"
			elif command -v pacman &>/dev/null; then
				pacman -Syu --noconfirm
				pacman -S --noconfirm "$package"
			elif command -v zypper &>/dev/null; then
				zypper refresh
				zypper install -y "$package"
			elif command -v opkg &>/dev/null; then
				opkg update
				opkg install "$package"
			elif command -v pkg &>/dev/null; then
				pkg update
				pkg install -y "$package"
			else
				echo "不明なパッケージマネージャー！"
				return 1
			fi
		fi
	done
}


check_disk_space() {
	local required_gb=$1
	local path=${2:-/}

	mkdir -p "$path"

	local required_space_mb=$((required_gb * 1024))
	local available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

	if [ "$available_space_mb" -lt "$required_space_mb" ]; then
		echo -e "${gl_huang}ヒント: ${gl_bai}ディスク容量が不足しています！ "
		echo "利用可能容量: $((available_space_mb/1024))G"
		echo "最小必要スペース: ${required_gb}G"
		echo "インストールを続行できません。ディスクスペースをクリーンアップしてから再試行してください。"
		send_stats "磁盘空间不足"
		break_end
		kejilion
	fi
}



install_dependency() {
	install wget unzip tar jq grep

	check_swap
	auto_optimize_dns
	prefer_ipv4

}

remove() {
	if [ $# -eq 0 ]; then
		echo "パッケージパラメータが提供されていません！"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}$package をアンインストールしています...${gl_bai}"
		if command -v dnf &>/dev/null; then
			dnf remove -y "$package"
		elif command -v yum &>/dev/null; then
			yum remove -y "$package"
		elif command -v apt &>/dev/null; then
			apt purge -y "$package"
		elif command -v apk &>/dev/null; then
			apk del "$package"
		elif command -v pacman &>/dev/null; then
			pacman -Rns --noconfirm "$package"
		elif command -v zypper &>/dev/null; then
			zypper remove -y "$package"
		elif command -v opkg &>/dev/null; then
			opkg remove "$package"
		elif command -v pkg &>/dev/null; then
			pkg delete -y "$package"
		else
			echo "不明なパッケージマネージャー！"
			return 1
		fi
	done
}


# 通用 systemctl 函数，适用于各种发行版
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# 重启服务
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1 サービスが再起動しました。"
	else
		echo "エラー: $1 サービスの再起動に失敗しました。"
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1 サービスが起動しました。"
	else
		echo "エラー: $1 サービスの起動に失敗しました。"
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1 サービスが停止しました。"
	else
		echo "エラー: $1 サービスの停止に失敗しました。"
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1 サービスのステータスが表示されました。"
	else
		echo "エラー: $1 サービスのステータスを表示できませんでした。"
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME は自動起動に設定されました。"
}



break_end() {
	  echo -e "${gl_lv}操作が完了しました${gl_bai}"
	  echo "続行するには任意のキーを押してください..."
	  read -n 1 -s -r -p ""
	  echo ""
	  clear
}

kejilion() {
			cd ~
			kejilion_sh
}




stop_containers_or_kill_process() {
	local port=$1
	local containers=$(docker ps --filter "publish=$port" --format "{{.ID}}" 2>/dev/null)

	if [ -n "$containers" ]; then
		docker stop $containers
	else
		install lsof
		for pid in $(lsof -t -i:$port); do
			kill -9 $pid
		done
	fi
}


check_port() {
	stop_containers_or_kill_process 80
	stop_containers_or_kill_process 443
}


install_add_docker_cn() {

local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
	"https://docker.1ms.run",
	"https://docker.m.ixdev.cn",
	"https://hub.rat.dev",
	"https://dockerproxy.net",
	"https://docker-registry.nmqu.com",
	"https://docker.amingg.com",
	"https://docker.hlmirror.com",
	"https://hub1.nat.tf",
	"https://hub2.nat.tf",
	"https://hub3.nat.tf",
	"https://docker.m.daocloud.io",
	"https://docker.kejilion.pro",
	"https://docker.367231.xyz",
	"https://hub.1panel.dev",
	"https://dockerproxy.cool",
	"https://docker.apiba.cn",
	"https://proxy.vvvv.ee"
  ]
}
EOF
fi


enable docker
start docker
restart docker

}


install_add_docker_guanfang() {
local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	cd ~
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/install && chmod +x install
	sh install --mirror Aliyun
	rm -f install
else
	curl -fsSL https://get.docker.com | sh
fi
install_add_docker_cn


}



install_add_docker() {
	echo -e "${gl_huang}Docker 環境をインストールしています...${gl_bai}"
	if  [ -f /etc/os-release ] && grep -q "Fedora" /etc/os-release; then
		install_add_docker_guanfang
	elif command -v dnf &>/dev/null; then
		dnf update -y
		dnf install -y yum-utils device-mapper-persistent-data lvm2
		rm -f /etc/yum.repos.d/docker*.repo > /dev/null
		country=$(curl -s ipinfo.io/country)
		arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo | tee /etc/yum.repos.d/docker-ce.repo > /dev/null
		else
			yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null
		fi
		dnf install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn

	elif [ -f /etc/os-release ] && grep -q "Kali" /etc/os-release; then
		apt update
		apt upgrade -y
		apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
		rm -f /usr/share/keyrings/docker-archive-keyring.gpg
		local country=$(curl -s ipinfo.io/country)
		local arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			fi
		else
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			fi
		fi
		apt update
		apt install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn


	elif command -v apt &>/dev/null || command -v yum &>/dev/null; then
		install_add_docker_guanfang
	else
		install docker docker-compose
		install_add_docker_cn

	fi
	sleep 2
}


install_docker() {
	if ! command -v docker &>/dev/null; then
		install_add_docker
	fi
}


docker_ps() {
while true; do
	clear
	send_stats "Docker容器管理"
	echo "Dockerコンテナ一覧"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "コンテナ操作"
	echo "------------------------"
	echo "1. 新規コンテナ作成"
	echo "------------------------"
	echo "2. 指定コンテナ起動             6. 全コンテナ起動"
	echo "3. 指定コンテナ停止             7. 全コンテナ停止"
	echo "4. 指定コンテナ削除             8. 全コンテナ削除"
	echo "5. 指定コンテナ再起動         9. 全コンテナ再起動"
	echo "------------------------"
	echo "11. 指定コンテナに入る             12. コンテナログ表示"
	echo "13. コンテナネットワーク表示             14. コンテナ使用量表示"
	echo "------------------------"
	echo "15. コンテナポートアクセスを有効にする       16. コンテナポートアクセスを無効にする"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " sub_choice
	case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "作成コマンドを入力してください: " dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			read -e -p "コンテナ名を入力してください（複数のコンテナ名の場合はスペースで区切ってください）: " dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "コンテナ名を入力してください（複数のコンテナ名の場合はスペースで区切ってください）: " dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			read -e -p "コンテナ名を入力してください（複数のコンテナ名の場合はスペースで区切ってください）: " dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			read -e -p "コンテナ名を入力してください（複数のコンテナ名の場合はスペースで区切ってください）: " dockername
			docker restart $dockername
			;;
		6)
			send_stats "启动所有容器"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "停止所有容器"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "删除所有容器"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}すべてのコンテナを削除しますか? \(y/N\): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "無効な選択です。Y または N を入力してください。"
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			read -e -p "コンテナ名を入力してください: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			read -e -p "コンテナ名を入力してください: " dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "查看容器网络"
			echo ""
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"
			for container_id in $container_ids; do
				local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")
				local container_name=$(echo "$container_info" | awk '{print $1}')
				local network_info=$(echo "$container_info" | cut -d' ' -f2-)
				while IFS= read -r line; do
					local network_name=$(echo "$line" | awk '{print $1}')
					local ip_address=$(echo "$line" | awk '{print $2}')
					printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
				done <<< "$network_info"
			done
			break_end
			;;
		14)
			send_stats "查看容器占用"
			docker stats --no-stream
			break_end
			;;

		15)
			send_stats "允许容器端口访问"
			read -e -p "コンテナ名を入力してください: " docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "阻止容器端口访问"
			read -e -p "コンテナ名を入力してください: " docker_name
			ip_address
			block_container_port "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done
}


docker_image() {
while true; do
	clear
	send_stats "Docker镜像管理"
	echo "Dockerイメージ一覧"
	docker image ls
	echo ""
	echo "イメージ操作"
	echo "------------------------"
	echo "1. 指定イメージの取得 2. 指定イメージの更新"
	echo "3. 指定イメージの削除 4. 全イメージの削除"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " sub_choice
	case $sub_choice in
		1)
			send_stats "拉取镜像"
			read -e -p "イメージ名を入力してください（複数のイメージ名の場合はスペースで区切ってください）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}イメージを取得しています: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			read -e -p "イメージ名を入力してください（複数のイメージ名の場合はスペースで区切ってください）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}イメージを更新しています: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			read -e -p "イメージ名を入力してください（複数のイメージ名の場合はスペースで区切ってください）: " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}すべてのイメージを削除しますか? \(y/N\): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "無効な選択です。Y または N を入力してください。"
				;;
			esac
			;;
		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done


}





check_crontab_installed() {
	if ! command -v crontab >/dev/null 2>&1; then
		install_crontab
	fi
}



install_crontab() {

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
			ubuntu|debian|kali)
				apt update
				apt install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			centos|rhel|almalinux|rocky|fedora)
				yum install -y cronie
				systemctl enable crond
				systemctl start crond
				;;
			alpine)
				apk add --no-cache cronie
				rc-update add crond
				rc-service crond start
				;;
			arch|manjaro)
				pacman -S --noconfirm cronie
				systemctl enable cronie
				systemctl start cronie
				;;
			opensuse|suse|opensuse-tumbleweed)
				zypper install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			iStoreOS|openwrt|ImmortalWrt|lede)
				opkg update
				opkg install cron
				/etc/init.d/cron enable
				/etc/init.d/cron start
				;;
			FreeBSD)
				pkg install -y cronie
				sysrc cron_enable="YES"
				service cron start
				;;
			*)
				echo "サポートされていないディストリビューション: $ID"
				return
				;;
		esac
	else
		echo "オペレーティングシステムを特定できません。"
		return
	fi

	echo -e "${gl_lv}crontab はインストールされており、cron サービスは実行中です。${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 检查配置文件是否存在，如果不存在则创建文件并写入默认设置
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# 使用jq处理配置文件的更新
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 检查当前配置是否已经有 ipv6 设置
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 更新配置，开启 IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 对比原始配置与新配置
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}現在 IPv6 アクセスが有効になっています${gl_bai}"
		else
			echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
			restart docker
		fi
	fi
}


docker_ipv6_off() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"

	# 检查配置文件是否存在
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}設定ファイルが存在しません${gl_bai}"
		return
	fi

	# 读取当前配置
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# 使用jq处理配置文件的更新
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 检查当前的 ipv6 状态
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 对比原始配置与新配置
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}現在 IPv6 アクセスは無効になっています${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}IPv6 アクセスを正常に無効にしました${gl_bai}"
	fi
}



save_iptables_rules() {
	mkdir -p /etc/iptables
	touch /etc/iptables/rules.v4
	iptables-save > /etc/iptables/rules.v4
	check_crontab_installed
	crontab -l | grep -v 'iptables-restore' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot iptables-restore < /etc/iptables/rules.v4') | crontab - > /dev/null 2>&1

}




iptables_open() {
	install iptables
	save_iptables_rules
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	ip6tables -P INPUT ACCEPT
	ip6tables -P FORWARD ACCEPT
	ip6tables -P OUTPUT ACCEPT
	ip6tables -F

}



open_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "少なくとも1つのポート番号を指定してください"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的关闭规则
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 添加打开规则
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "ポート $port を開きました"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "少なくとも1つのポート番号を指定してください"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的打开规则
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 添加关闭规则
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "ポート $port を閉じました"
		fi
	done

	# 删除已存在的规则（如果有）
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 插入新规则到第一条
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "已关闭端口"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "少なくとも1つのIPアドレスまたはIPセグメントを指定してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP $ip を許可しました"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "少なくとも1つのIPアドレスまたはIPセグメントを指定してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP $ip をブロックしました"
		fi
	done

	save_iptables_rules
	send_stats "已阻止IP"
}







enable_ddos_defense() {
	# 开启防御 DDoS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "开启DDoS防御"
}

# 关闭DDoS防御
disable_ddos_defense() {
	# 关闭防御 DDoS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "关闭DDoS防御"
}





# 管理国家IP规则的函数
manage_country_rules() {
	local action="$1"
	shift  # 去掉第一个参数，剩下的全是国家代码

	install ipset

	for country_code in "$@"; do
		local ipset_name="${country_code,,}_block"
		local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

		case "$action" in
			block)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "エラー: $country_code のIP地域ファイルをダウンロードできませんでした"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "$country_code のIPアドレスをブロックしました"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "エラー: $country_code のIP地域ファイルをダウンロードできませんでした"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "$country_code のIPアドレスを許可しました"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "$country_code のIPアドレス制限を解除しました"
				;;

			*)
				echo "使用法: manage_country_rules {block|allow|unblock} <country_code...>"
				;;
		esac
	done
}










iptables_panel() {
  root_use
  install iptables
  save_iptables_rules
  while true; do
		  clear
		  echo "高度なファイアウォール管理"
		  send_stats "高级防火墙管理"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "ファイアウォール管理"
		  echo "------------------------"
		  echo "1. 指定ポートを開く 2. 指定ポートを閉じる"
		  echo "3. 全ポートを開く 4. 全ポートを閉じる"
		  echo "------------------------"
		  echo "5. IPホワイトリスト 6. IPブラックリスト"
		  echo "7. 指定IPをクリア"
		  echo "------------------------"
		  echo "11. PINGを許可 12. PINGを禁止"
		  echo "------------------------"
		  echo "13. DDOS防御を起動 14. DDOS防御を閉じる"
		  echo "------------------------"
		  echo "15. 指定国のIPをブロック 16. 指定国のIPのみを許可"
		  echo "17. 指定国のIP制限を解除"
		  echo "------------------------"
		  echo "0. 前のメニューに戻る"
		  echo "------------------------"
		  read -e -p "選択を入力してください: " sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "開放するポート番号を入力してください: " o_port
				  open_port $o_port
				  send_stats "开放指定端口"
				  ;;
			  2)
				  read -e -p "閉鎖するポート番号を入力してください: " c_port
				  close_port $c_port
				  send_stats "关闭指定端口"
				  ;;
			  3)
				  # 开放所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT ACCEPT
				  iptables -P FORWARD ACCEPT
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "开放所有端口"
				  ;;
			  4)
				  # 关闭所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT DROP
				  iptables -P FORWARD DROP
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "关闭所有端口"
				  ;;

			  5)
				  # IP 白名单
				  read -e -p "許可するIPまたはIPセグメントを入力してください: " o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP 黑名单
				  read -e -p "ブロックするIPまたはIPセグメントを入力してください: " c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 清除指定 IP
				  read -e -p "クリアするIPを入力してください: " d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "清除指定IP"
				  ;;
			  11)
				  # 允许 PING
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "允许PING"
				  ;;
			  12)
				  # 禁用 PING
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "禁用PING"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "ブロックする国コードを入力してください（複数の国コードの場合はスペースで区切ってください。例: CN US JP）: " country_code
				  manage_country_rules block $country_code
				  send_stats "允许国家 $country_code 的IP"
				  ;;
			  16)
				  read -e -p "許可する国コードを入力してください（複数の国コードの場合はスペースで区切ってください。例: CN US JP）: " country_code
				  manage_country_rules allow $country_code
				  send_stats "阻止国家 $country_code 的IP"
				  ;;

			  17)
				  read -e -p "クリアする国コードを入力してください（複数の国コードの場合はスペースで区切ってください。例: CN US JP）: " country_code
				  manage_country_rules unblock $country_code
				  send_stats "清除国家 $country_code 的IP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}






add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 获取当前系统中所有的 swap 分区
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 遍历并删除所有的 swap 分区
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# 确保 /swapfile 不再被使用
	swapoff /swapfile

	# 删除旧的 /swapfile
	rm -f /swapfile

	# 创建新的 swap 分区
	fallocate -l ${new_swap}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile

	sed -i '/\/swapfile/d' /etc/fstab
	echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

	if [ -f /etc/alpine-release ]; then
		echo "nohup swapon /swapfile" > /etc/local.d/swap.start
		chmod +x /etc/local.d/swap.start
		rc-update add local
	fi

	echo -e "仮想メモリサイズを ${gl_huang}${new_swap}${gl_bai}M に調整しました"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 判断是否需要创建虚拟内存
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # 获取nginx版本
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # 获取mysql版本
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # 获取php版本
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # 获取redis版本
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 创建必要的目录和文件
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/stream.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf

  default_server_ssl

  # 下载 docker-compose.yml 文件并进行替换
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # 在 docker-compose.yml 文件中进行替换
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}


update_docker_compose_with_db_creds() {

  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

  if ! grep -q "stream" /home/web/docker-compose.yml; then
	wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml

  	dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
  	dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
  	dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')

	sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
	sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
	sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml
  fi

  if grep -q "kjlion/nginx:alpine" /home/web/docker-compose1.yml; then
  	sed -i 's|kjlion/nginx:alpine|nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
	sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
  fi

}





auto_optimize_dns() {
	# 获取国家代码（如 CN、US 等）
	local country=$(curl -s ipinfo.io/country)

	# 根据国家设置 DNS
	if [ "$country" = "CN" ]; then
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
	else
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
	fi

	# 调用设置 DNS 的函数（需你定义）
	set_dns "$dns1_ipv4" "$dns2_ipv4" "$dns1_ipv6" "$dns2_ipv6"


}


prefer_ipv4() {
grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null \
	|| echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
echo "IPv4優先に切り替えました"
send_stats "已切换为 IPv4 优先"
}




install_ldnmp() {

	  update_docker_compose_with_db_creds

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -

	  fix_phpfpm_conf php
	  fix_phpfpm_conf php74
	  restart_ldnmp


	  clear
	  echo "LDNMP環境のインストールが完了しました"
	  echo "------------------------"
	  ldnmp_v

}


install_certbot() {

	cd ~
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
	chmod +x auto_cert_renewal.sh

	check_crontab_installed
	local cron_job="0 0 * * * ~/auto_cert_renewal.sh"
	crontab -l 2>/dev/null | grep -vF "$cron_job" | crontab -
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "更新タスクが更新されました"
}


install_ssltls() {
	  docker stop nginx > /dev/null 2>&1
	  check_port > /dev/null 2>&1
	  cd ~

	  local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	  if [ ! -f "$file_path" ]; then
		 	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
			local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'
			# local ipv6_pattern='^([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}$'
	  		# local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
			if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
				mkdir -p /etc/letsencrypt/live/$yuming/
				if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
					openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				else
					openssl genpkey -algorithm Ed25519 -out /etc/letsencrypt/live/$yuming/privkey.pem
					openssl req -x509 -key /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				fi
			else
				docker run -it --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
			fi
	  fi
	  mkdir -p /home/web/certs/
	  cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
	  cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

	  docker start nginx > /dev/null 2>&1
}



install_ssltls_text() {
	echo -e "${gl_huang}$yuming 公開鍵情報${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming 秘密鍵情報${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}証明書保管パス${gl_bai}"
	echo "公開鍵: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "秘密鍵: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}SSL 証明書を迅速に申請し、有効期限前に自動更新します${gl_bai}"
yuming="${1:-}"
if [ -z "$yuming" ]; then
	add_yuming
fi
install_docker
install_certbot
docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
install_ssltls
certs_status
install_ssltls_text
ssl_ps
}


ssl_ps() {
	echo -e "${gl_huang}申請された証明書の有効期限${gl_bai}"
	echo "サイト情報 証明書の有効期限"
	echo "------------------------"
	for cert_dir in /etc/letsencrypt/live/*; do
	  local cert_file="$cert_dir/fullchain.pem"
	  if [ -f "$cert_file" ]; then
		local domain=$(basename "$cert_dir")
		local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
		local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
		printf "%-30s%s\n" "$domain" "$formatted_date"
	  fi
	done
	echo ""
}




default_server_ssl() {
install openssl

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
else
	openssl genpkey -algorithm Ed25519 -out /home/web/certs/default_server.key
	openssl req -x509 -key /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
fi

openssl rand -out /home/web/certs/ticket12.key 48
openssl rand -out /home/web/certs/ticket13.key 80

}


certs_status() {

	sleep 1

	local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	if [ -f "$file_path" ]; then
		send_stats "域名证书申请成功"
	else
		send_stats "域名证书申请失败"
		echo -e "${gl_hong}注意: ${gl_bai}証明書の申請に失敗しました。以下の原因を確認し、再試行してください:"
		echo -e "1. ドメイン名のスペルミス ➠ ドメイン名の入力が正しいか確認してください"
		echo -e "2. DNS解決の問題 ➠ ドメイン名が正しくこのサーバーIPに解決されているか確認してください"
		echo -e "3. ネットワーク設定の問題 ➠ Cloudflare Warpなどの仮想ネットワークを使用している場合は一時的に無効にしてください"
		echo -e "4. ファイアウォール制限 ➠ 80/443ポートが開いているか確認し、検証がアクセス可能であることを確認してください"
		echo -e "5. 申請回数超過 ➠ Let's Encryptには週ごとの制限があります (1ドメインあたり週5回)"
		echo -e "6. 中国地区の备案制限 ➠ 中国本土の環境では、ドメイン名が备案されているか確認してください"
		break_end
		clear
		echo "$webname のデプロイをもう一度お試しください"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "域名重复使用"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "まずドメイン名をローカルIPに解決してください: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "IPまたは解決済みのドメイン名を入力してください: " yuming
}


add_db() {
	  dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
	  dbname="${dbname}"

	  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}

reverse_proxy() {
	  ip_address
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|0000|$duankou|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on
	  docker exec nginx nginx -s reload
}


restart_redis() {
  rm -rf /home/web/redis/*
  docker exec redis redis-cli FLUSHALL > /dev/null 2>&1
  # docker exec -it redis redis-cli CONFIG SET maxmemory 1gb > /dev/null 2>&1
  # docker exec -it redis redis-cli CONFIG SET maxmemory-policy allkeys-lru > /dev/null 2>&1
}



restart_ldnmp() {
	  restart_redis
	  docker exec nginx chown -R nginx:nginx /var/www/html > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec php chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  docker exec php74 chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  cd /home/web && docker compose restart nginx php php74

}

nginx_upgrade() {

  local ldnmp_pods="nginx"
  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker images --filter=reference="${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker compose up -d --force-recreate $ldnmp_pods
  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -
  docker exec nginx chown -R nginx:nginx /var/www/html
  docker exec nginx mkdir -p /var/cache/nginx/proxy
  docker exec nginx mkdir -p /var/cache/nginx/fastcgi
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi
  docker restart $ldnmp_pods > /dev/null 2>&1

  send_stats "更新$ldnmp_pods"
  echo "更新${ldnmp_pods}完了"

}

phpmyadmin_upgrade() {
  local ldnmp_pods="phpmyadmin"
  local local docker_port=8877
  local dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
  local dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  curl -sS -O https://raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
  docker compose -f docker-compose.phpmyadmin.yml up -d
  clear
  ip_address

  check_docker_app_ip
  echo "ログイン情報: "
  echo "ユーザー名: $dbuse"
  echo "パスワード: $dbusepasswd"
  echo
  send_stats "启动$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 检查配置文件是否存在
  if [ -f "$CONFIG_FILE" ]; then
	# 从配置文件读取 API_TOKEN 和 zone_id
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# 将 ZONE_IDS 转换为数组
	ZONE_IDS=($ZONE_IDS)
  else
	# 提示用户是否清理缓存
	read -e -p "Cloudflareのキャッシュをクリアしますか？ (y/N) : " answer
	if [[ "$answer" == "y" ]]; then
	  echo "Cloudflare情報は$CONFIG_FILEに保存されており、後でCloudflare情報を変更できます。"
	  read -e -p "API_TOKENを入力してください: " API_TOKEN
	  read -e -p "Cloudflareのユーザー名を入力してください: " EMAIL
	  read -e -p "zone_idを入力してください（複数指定の場合はスペースで区切ってください）: " -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 循环遍历每个 zone_id 并执行清除缓存命令
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "ゾーンIDのキャッシュをクリアしています: $ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "キャッシュクリアリクエストが送信されました。"
}



web_cache() {
  send_stats "清理站点缓存"
  cf_purge_cache
  cd /home/web && docker compose restart
  restart_redis
}



web_del() {

	send_stats "删除站点数据"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "サイトデータを削除します。ドメイン名を入力してください（複数のドメイン名の場合はスペースで区切ってください）: " yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "ドメインの削除中: $yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "データベースの削除中: $dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 根据 mode 参数来决定开启或关闭 WAF
	if [ "$mode" == "on" ]; then
		# 开启 WAF：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# 关闭 WAF：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "無効なパラメータ: 'on' または 'off' を使用してください"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

check_waf_status() {
	if grep -q "^\s*#\s*modsecurity on;" /home/web/nginx.conf; then
		waf_status=""
	elif grep -q "modsecurity on;" /home/web/nginx.conf; then
		waf_status=" WAF已开启"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/etc/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage=" cf模式已开启"
	else
		CFmessage=""
	fi
}


nginx_http_on() {

local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
	sed -i '/if (\$scheme = http) {/,/}/s/^/#/' /home/web/conf.d/${yuming}.conf
fi

}


patch_wp_memory_limit() {
  local MEMORY_LIMIT="${1:-256M}"      # 第一个参数，默认256M
  local MAX_MEMORY_LIMIT="${2:-256M}"  # 第二个参数，默认256M
  local TARGET_DIR="/home/web/html"    # 路径写死

  find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
	# 删除旧定义
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# 插入新定义，放在含 "Happy publishing" 的行前
	awk -v insert="define('WP_MEMORY_LIMIT', '$MEMORY_LIMIT');\ndefine('WP_MAX_MEMORY_LIMIT', '$MAX_MEMORY_LIMIT');" \
	'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Replaced WP_MEMORY_LIMIT in $FILE"
  done
}




patch_wp_debug() {
  local DEBUG="${1:-false}"           # 第一个参数，默认false
  local DEBUG_DISPLAY="${2:-false}"   # 第二个参数，默认false
  local DEBUG_LOG="${3:-false}"       # 第三个参数，默认false
  local TARGET_DIR="/home/web/html"   # 路径写死

  find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
	# 删除旧定义
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# 插入新定义，放在含 "Happy publishing" 的行前
	awk -v insert="define('WP_DEBUG_DISPLAY', $DEBUG_DISPLAY);\ndefine('WP_DEBUG_LOG', $DEBUG_LOG);" \
	'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Replaced WP_DEBUG settings in $FILE"
  done
}


nginx_br() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 开启 Brotli：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)# brotli on;|\1brotli on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_static on;|\1brotli_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_comp_level \(.*\);|\1brotli_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_buffers \(.*\);|\1brotli_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_min_length \(.*\);|\1brotli_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_window \(.*\);|\1brotli_window \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_types \(.*\);|\1brotli_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/brotli_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf

	elif [ "$mode" == "off" ]; then
		# 关闭 Brotli：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)brotli on;|\1# brotli on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_static on;|\1# brotli_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_comp_level \(.*\);|\1# brotli_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_buffers \(.*\);|\1# brotli_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_min_length \(.*\);|\1# brotli_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_window \(.*\);|\1# brotli_window \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_types \(.*\);|\1# brotli_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/brotli_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf

	else
		echo "無効なパラメータ: 'on' または 'off' を使用してください"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi


}



nginx_zstd() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 开启 Zstd：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)# zstd on;|\1zstd on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_static on;|\1zstd_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_comp_level \(.*\);|\1zstd_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_buffers \(.*\);|\1zstd_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_min_length \(.*\);|\1zstd_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_types \(.*\);|\1zstd_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/zstd_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf



	elif [ "$mode" == "off" ]; then
		# 关闭 Zstd：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)zstd on;|\1# zstd on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_static on;|\1# zstd_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_comp_level \(.*\);|\1# zstd_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_buffers \(.*\);|\1# zstd_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_min_length \(.*\);|\1# zstd_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_types \(.*\);|\1# zstd_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/zstd_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf


	else
		echo "無効なパラメータ: 'on' または 'off' を使用してください"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi



}








nginx_gzip() {

	local mode=$1
	if [ "$mode" == "on" ]; then
		sed -i 's|^\(\s*\)# gzip on;|\1gzip on;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		sed -i 's|^\(\s*\)gzip on;|\1# gzip on;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "無効なパラメータ: 'on' または 'off' を使用してください"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP环境防御"
	  while true; do
		check_f2b_status
		check_waf_status
		check_cf_mode
			  clear
			  echo -e "サーバーウェブサイト防御プログラム ${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 防御プログラムのインストール"
			  echo "------------------------"
			  echo "5. SSHブロックログの表示 6. Webサイトブロックログの表示"
			  echo "7. 防御ルールリストの表示 8. ログリアルタイム監視の表示"
			  echo "------------------------"
			  echo "11. ブロックパラメータの設定 12. すべてのブロックされたIPのクリア"
			  echo "------------------------"
			  echo "21. Cloudflareモード 22. 高負荷時5秒シールド有効"
			  echo "------------------------"
			  echo "31. WAFを有効にする 32. WAFを無効にする"
			  echo "33. DDOS防御を有効にする 34. DDOS防御を無効にする"
			  echo "------------------------"
			  echo "9. 防御プログラムの削除"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択を入力してください: " sub_choice
			  case $sub_choice in
				  1)
					  f2b_install_sshd
					  cd /etc/fail2ban/filter.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-418.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-deny.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-unauthorized.conf
					  wget ${gh_proxy}https://raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-bad-request.conf

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf
					  sed -i "/cloudflare/d" /etc/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  ;;
				  5)
					  echo "------------------------"
					  f2b_sshd
					  echo "------------------------"
					  ;;
				  6)

					  echo "------------------------"
					  local xxx="fail2ban-nginx-cc"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-418"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-bad-request"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-badbots"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-botsearch"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-deny"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-http-auth"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-unauthorized"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="php-url-fopen"
					  f2b_status_xxx
					  echo "------------------------"

					  ;;

				  7)
					  fail2ban-client status
					  ;;
				  8)
					  tail -f /var/log/fail2ban.log

					  ;;
				  9)
					  remove fail2ban
					  rm -rf /etc/fail2ban
					  crontab -l | grep -v "CF-Under-Attack.sh" | crontab - 2>/dev/null
					  echo "Fail2ban防御プログラムが削除されました"
					  break
					  ;;

				  11)
					  install nano
					  nano /etc/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  break
					  ;;

				  12)
					  fail2ban-client unban --all
					  ;;

				  21)
					  send_stats "cloudflare模式"
					  echo "Cloudflareのバックエンドで右上角のマイプロフィールに移動し、左側のAPIトークンを選択して、Global API Keyを取得します"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "Cloudflareのアカウントを入力してください: " cfuser
					  read -e -p "Cloudflare のグローバル API キーを入力してください: " cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /etc/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "Cloudflareモードが設定されました。Cloudflareのバックエンド、サイト-セキュリティ-イベントでブロックログを確認できます"
					  ;;

				  22)
					  send_stats "高负载开启5秒盾"
					  echo -e "${gl_huang}ウェブサイトは5分ごとに自動検出され、高負荷が検出されると自動的にシールドが有効になり、低負荷の場合は5秒後にシールドが自動的に閉じられます。${gl_bai}"
					  echo "--------------"
					  echo "Cloudflareパラメータの取得:"
					  echo -e "Cloudflareのバックエンドの右上にあるマイプロフィールに移動し、左側のAPIトークンを選択して、${gl_huang}Global API Key${gl_bai}を取得してください"
					  echo -e "Cloudflareのバックエンドのドメイン概要ページの下部右側にある${gl_huang}ゾーンID${gl_bai}を取得してください"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "Cloudflareのアカウントを入力してください: " cfuser
					  read -e -p "Cloudflare のグローバル API キーを入力してください: " cftoken
					  read -e -p "Cloudflare のドメインのリージョン ID を入力してください: " cfzonID

					  cd ~
					  install jq bc
					  check_crontab_installed
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh
					  chmod +x CF-Under-Attack.sh
					  sed -i "s/AAAA/$cfuser/g" ~/CF-Under-Attack.sh
					  sed -i "s/BBBB/$cftoken/g" ~/CF-Under-Attack.sh
					  sed -i "s/CCCC/$cfzonID/g" ~/CF-Under-Attack.sh

					  local cron_job="*/5 * * * * ~/CF-Under-Attack.sh"

					  local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

					  if [ -z "$existing_cron" ]; then
						  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
						  echo "高負荷時自動シールドスクリプトが追加されました"
					  else
						  echo "自動シールドスクリプトは既に存在するため、追加する必要はありません"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "サイトWAFが有効になりました"
					  send_stats "站点WAF已开启"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "サイトWAFが無効になりました"
					  send_stats "站点WAF已关闭"
					  ;;

				  33)
					  enable_ddos_defense
					  ;;

				  34)
					  disable_ddos_defense
					  ;;

				  *)
					  break
					  ;;
			  esac
	  break_end
	  done
}



check_nginx_mode() {

CONFIG_FILE="/home/web/nginx.conf"

# 获取当前的 worker_processes 设置值
current_value=$(grep -E '^\s*worker_processes\s+[0-9]+;' "$CONFIG_FILE" | awk '{print $2}' | tr -d ';')

# 根据值设置模式信息
if [ "$current_value" = "8" ]; then
	mode_info=" 高性能模式"
else
	mode_info=" 标准模式"
fi



}


check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# 检查 zstd 是否开启且未被注释（整行以 zstd on; 开头）
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status=" zstd压缩已开启"
	else
		zstd_status=""
	fi

	# 检查 brotli 是否开启且未被注释
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status=" br压缩已开启"
	else
		br_status=""
	fi

	# 检查 gzip 是否开启且未被注释
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status=" gzip压缩已开启"
	else
		gzip_status=""
	fi
}




web_optimization() {
		  while true; do
		  	  check_nginx_mode
			  check_nginx_compression
			  clear
			  send_stats "优化LDNMP环境"
			  echo -e "LDNMP環境の最適化 ${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 標準モード 2. 高性能モード(2H4G以上を推奨)"
			  echo "------------------------"
			  echo "3. gzip圧縮を有効にする        4. gzip圧縮を無効にする"
			  echo "5. br圧縮を有効にする          6. br圧縮を無効にする"
			  echo "7. zstd圧縮を有効にする        8. zstd圧縮を無効にする"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択を入力してください: " sub_choice
			  case $sub_choice in
				  1)
				  send_stats "站点标准模式"

				  local cpu_cores=$(nproc)
				  local connections=$((1024 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf


				  # php调优
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php调优
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql调优
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced


				  echo "LDNMP環境は標準モードに設定されています"

					  ;;
				  2)
				  send_stats "站点高性能模式"

				  # nginx调优
				  local cpu_cores=$(nproc)
				  local connections=$((2048 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf

				  # php调优
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php调优
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit 512M 512M
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql调优
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

				  echo "LDNMP環境は高性能モードに設定されています"

					  ;;
				  3)
				  send_stats "nginx_gzip on"
				  nginx_gzip on
					  ;;
				  4)
				  send_stats "nginx_gzip off"
				  nginx_gzip off
					  ;;
				  5)
				  send_stats "nginx_br on"
				  nginx_br on
					  ;;
				  6)
				  send_stats "nginx_br off"
				  nginx_br off
					  ;;
				  7)
				  send_stats "nginx_zstd on"
				  nginx_zstd on
					  ;;
				  8)
				  send_stats "nginx_zstd off"
				  nginx_zstd off
					  ;;
				  *)
					  break
					  ;;
			  esac
			  break_end

		  done


}










check_docker_app() {
	if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name" ; then
		check_docker="${gl_lv}已安装${gl_bai}"
	else
		check_docker="${gl_hui}未安装${gl_bai}"
	fi
}



# check_docker_app() {

# if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
# 	check_docker="${gl_lv}已安装${gl_bai}"
# else
# 	check_docker="${gl_hui}未安装${gl_bai}"
# fi

# }


check_docker_app_ip() {
echo "------------------------"
echo "アクセスアドレス:"
ip_address



if [ -n "$ipv4_address" ]; then
	echo "http://$ipv4_address:${docker_port}"
fi

if [ -n "$ipv6_address" ]; then
	echo "http://[$ipv6_address]:${docker_port}"
fi

local search_pattern1="$ipv4_address:${docker_port}"
local search_pattern2="127.0.0.1:${docker_port}"

for file in /home/web/conf.d/*; do
	if [ -f "$file" ]; then
		if grep -q "$search_pattern1" "$file" 2>/dev/null || grep -q "$search_pattern2" "$file" 2>/dev/null; then
			echo "https://$(basename "$file" | sed 's/\.conf$//')"
		fi
	fi
done


}


check_docker_image_update() {

	local container_name=$1

	local country=$(curl -s ipinfo.io/country)
	if [[ "$country" == "CN" ]]; then
		update_status=""
		return
	fi

	# 获取容器的创建时间和镜像名称
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# 提取镜像仓库和标签
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# 默认标签为 latest
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# 添加对官方镜像的支持
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# 从 Docker Hub API 获取镜像发布时间
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# 验证获取的时间
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# 比较时间戳
		if [[ $container_created_ts -lt $last_updated_ts ]]; then
			update_status="${gl_huang}发现新版本!${gl_bai}"
		else
			update_status=""
		fi
	else
		update_status=""
	fi

}




block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 检查并封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 检查并放行指定 IP
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 检查并放行本地网络 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# 检查并封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 检查并放行指定 IP
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 检查并放行本地网络 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ポートがこのサービスへのアクセスをブロックしました"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 清除封禁其他所有 IP 的规则
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的规则
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地网络 127.0.0.0/8 的规则
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# 清除封禁其他所有 IP 的规则
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的规则
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地网络 127.0.0.0/8 的规则
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ポートがこのサービスへのアクセスを許可しました"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "エラー: ポート番号と許可されたIPを提供してください。"
		echo "使用法: block_host_port <ポート番号> <許可IP>"
		return 1
	fi

	install iptables


	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 允许已建立和相关连接的流量
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "IP+ポートがこのサービスへのアクセスをブロックしました"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "エラー: ポート番号と許可されたIPを提供してください。"
		echo "使用法: clear_host_port_rules <ポート番号> <許可IP>"
		return 1
	fi

	install iptables


	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "IP+ポートがこのサービスへのアクセスを許可しました"
	save_iptables_rules

}



setup_docker_dir() {

	mkdir -p /home /home/docker 2>/dev/null

	if [ -d "/vol1/1000/" ] && [ ! -d "/vol1/1000/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /vol1/1000/docker 2>/dev/null
		ln -s /vol1/1000/docker /home/docker 2>/dev/null
	fi

	if [ -d "/volume1/" ] && [ ! -d "/volume1/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /volume1/docker 2>/dev/null
		ln -s /volume1/docker /home/docker 2>/dev/null
	fi


}


add_app_id() {
mkdir -p /home/docker
touch /home/docker/appno.txt
grep -qxF "${app_id}" /home/docker/appno.txt || echo "${app_id}" >> /home/docker/appno.txt

}



docker_app() {
send_stats "${docker_name}管理"

while true; do
	clear
	check_docker_app
	check_docker_image_update $docker_name
	echo -e "$docker_name $check_docker $update_status"
	echo "$docker_describe"
	echo "$docker_url"
	if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
		if [ ! -f "/home/docker/${docker_name}_port.conf" ]; then
			local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
			docker_port=${docker_port:-0000}
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"
		fi
		local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
		check_docker_app_ip
	fi
	echo ""
	echo "------------------------"
	echo "1. インストール                  2. 更新                  3. 削除"
	echo "------------------------"
	echo "5. ドメイン名アクセス追加      6. ドメイン名アクセス削除"
	echo "7. IP+ポートアクセス許可       8. IP+ポートアクセスブロック"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " choice
	 case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "アプリケーションの外部サービスポートを入力してください。デフォルトでは ${docker_port} ポートが使用されます: " app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_name のインストールが完了しました"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "安装$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum

			add_app_id

			clear
			echo "$docker_name のインストールが完了しました"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "更新$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			rm -f /home/docker/${docker_name}_port.conf

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "アプリケーションが削除されました"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "${docker_name} ドメイン名アクセス設定"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "ドメイン名形式 example.com （https://なし）"
			web_del
			;;

		7)
			send_stats "允许IP访问 ${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问 ${docker_name}"
			block_container_port "$docker_name" "$ipv4_address"
			;;

		*)
			break
			;;
	 esac
	 break_end
done

}





docker_app_plus() {
	send_stats "$app_name"
	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "$app_name $check_docker $update_status"
		echo "$app_text"
		echo "$app_url"
		if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
			if [ ! -f "/home/docker/${docker_name}_port.conf" ]; then
				local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
				docker_port=${docker_port:-0000}
				echo "$docker_port" > "/home/docker/${docker_name}_port.conf"
			fi
			local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
			check_docker_app_ip
		fi
		echo ""
		echo "------------------------"
		echo "1. インストール                  2. 更新                  3. 削除"
		echo "------------------------"
		echo "5. ドメイン名アクセス追加      6. ドメイン名アクセス削除"
		echo "7. IP+ポートアクセス許可       8. IP+ポートアクセスブロック"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1)
				setup_docker_dir
				check_disk_space $app_size /home/docker
				read -e -p "アプリケーションの外部サービスポートを入力してください。デフォルトでは ${docker_port} ポートが使用されます: " app_port
				local app_port=${app_port:-${docker_port}}
				local docker_port=$app_port
				install jq
				install_docker
				docker_app_install
				echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

				add_app_id
				;;
			2)
				docker_app_update

				add_app_id
				;;
			3)
				docker_app_uninstall
				rm -f /home/docker/${docker_name}_port.conf

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt

				;;
			5)
				echo "${docker_name} ドメイン名アクセス設定"
				send_stats "${docker_name}域名访问设置"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "ドメイン名形式 example.com （https://なし）"
				web_del
				;;
			7)
				send_stats "允许IP访问 ${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "阻止IP访问 ${docker_name}"
				block_container_port "$docker_name" "$ipv4_address"
				;;
			*)
				break
				;;
		esac
		break_end
	done
}





prometheus_install() {

local PROMETHEUS_DIR="/home/docker/monitoring/prometheus"
local GRAFANA_DIR="/home/docker/monitoring/grafana"
local NETWORK_NAME="monitoring"

# Create necessary directories
mkdir -p $PROMETHEUS_DIR
mkdir -p $GRAFANA_DIR

# Set correct ownership for Grafana directory
chown -R 472:472 $GRAFANA_DIR

if [ ! -f "$PROMETHEUS_DIR/prometheus.yml" ]; then
	curl -o "$PROMETHEUS_DIR/prometheus.yml" ${gh_proxy}raw.githubusercontent.com/kejilion/config/refs/heads/main/prometheus/prometheus.yml
fi

# Create Docker network for monitoring
docker network create $NETWORK_NAME

# Run Node Exporter container
docker run -d \
  --name=node-exporter \
  --network $NETWORK_NAME \
  --restart=always \
  prom/node-exporter

# Run Prometheus container
docker run -d \
  --name prometheus \
  -v $PROMETHEUS_DIR/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $PROMETHEUS_DIR/data:/prometheus \
  --network $NETWORK_NAME \
  --restart=always \
  --user 0:0 \
  prom/prometheus:latest

# Run Grafana container
docker run -d \
  --name grafana \
  -p ${docker_port}:3000 \
  -v $GRAFANA_DIR:/var/lib/grafana \
  --network $NETWORK_NAME \
  --restart=always \
  grafana/grafana:latest

}




tmux_run() {
	# Check if the session already exists
	tmux has-session -t $SESSION_NAME 2>/dev/null
	# $? is a special variable that holds the exit status of the last executed command
	if [ $? != 0 ]; then
	  # Session doesn't exist, create a new one
	  tmux new -s $SESSION_NAME
	else
	  # Session exists, attach to it
	  tmux attach-session -t $SESSION_NAME
	fi
}


tmux_run_d() {

local base_name="tmuxd"
local tmuxd_ID=1

# 检查会话是否存在的函数
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 循环直到找到一个不存在的会话名称
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 创建新的 tmux 会话
tmux new -d -s "$base_name-$tmuxd_ID" "$tmuxd"


}



f2b_status() {
	 fail2ban-client reload
	 sleep 3
	 fail2ban-client status
}

f2b_status_xxx() {
	fail2ban-client status $xxx
}

check_f2b_status() {
	if command -v fail2ban-client >/dev/null 2>&1; then
		check_f2b_status="${gl_lv}已安装${gl_bai}"
	else
		check_f2b_status="${gl_hui}未安装${gl_bai}"
	fi
}

f2b_install_sshd() {

	docker rm -f fail2ban >/dev/null 2>&1
	install fail2ban
	start fail2ban
	enable fail2ban

	if command -v dnf &>/dev/null; then
		cd /etc/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf
	fi

}

f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	else
		xxx=sshd
		f2b_status_xxx
	fi
}




server_reboot() {

	read -e -p "$(echo -e "${gl_huang}ヒント: ${gl_bai}サーバーを今すぐ再起動しますか? \(y/N\): ")" rboot
	case "$rboot" in
	  [Yy])
		echo "再起動しました"
		reboot
		;;
	  *)
		echo "キャンセルしました"
		;;
	esac


}





output_status() {
	output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
		$1 ~ /^(eth|ens|enp|eno)[0-9]+/ {
			rx_total += $2
			tx_total += $10
		}
		END {
			rx_units = "Bytes";
			tx_units = "Bytes";
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "K"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "M"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "G"; }

			if (tx_total > 1024) { tx_total /= 1024; tx_units = "K"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "M"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "G"; }

			printf("%.2f%s %.2f%s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)

	rx=$(echo "$output" | awk '{print $1}')
	tx=$(echo "$output" | awk '{print $2}')

}




ldnmp_install_status_one() {

   if docker inspect "php" &>/dev/null; then
	clear
	send_stats "无法再次安装LDNMP环境"
	echo -e "${gl_huang}ヒント: ${gl_bai}ウェブサイト構築環境はインストールされています。再度インストールする必要はありません! "
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "安装LDNMP环境"
root_use
clear
echo -e "${gl_huang}LDNMP環境はインストールされていません。LDNMP環境のインストールを開始します...${gl_bai}"
check_disk_space 3 /home
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "安装nginx环境"
root_use
clear
echo -e "${gl_huang}Nginxはインストールされていません。Nginx環境のインストールを開始します...${gl_bai}"
check_disk_space 1 /home
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "Nginx のインストールが完了しました"
echo -e "現在のバージョン: ${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "请先安装LDNMP环境"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "请先安装nginx环境"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "あなたの $webname が構築されました！"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webname のインストール情報は以下の通りです："

}

nginx_web_on() {
	  clear
	  echo "あなたの $webname が構築されました！"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "安装$webname"
  echo "$webname のデプロイを開始"
  if [ -z "$yuming" ]; then
	add_yuming
  fi
  repeat_add_yuming
  ldnmp_install_status
  install_ssltls
  certs_status
  add_db
  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
  nginx_http_on

  cd /home/web/html
  mkdir $yuming
  cd $yuming
  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip
  unzip latest.zip
  rm latest.zip
  echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379'); define('WP_REDIS_MAXTTL', 86400); define('WP_CACHE_KEY_SALT', '${yuming}_');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|database_name_here|$dbname|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|username_here|$dbuse|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|password_here|$dbusepasswd|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|localhost|mysql|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  cp /home/web/html/$yuming/wordpress/wp-config-sample.php /home/web/html/$yuming/wordpress/wp-config.php

  restart_ldnmp
  nginx_web_on

}


ldnmp_Proxy() {
	clear
	webname="リバースプロキシ-IP+ポート"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "$webname のデプロイを開始"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "リバースプロキシ IP を入力してください: " reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "リバースプロキシ ポートを入力してください: " port
	fi
	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0.0.0.0/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	sed -i "s|0000|$port|g" /home/web/conf.d/$yuming.conf
	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}



ldnmp_Proxy_backend() {
	clear
	webname="リバースプロキシ-ロードバランシング"

	send_stats "安装$webname"
	echo "$webname のデプロイを開始"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "複数のリバースプロキシ IP+ポートをスペースで区切って入力してください (例: 127.0.0.1:3000 127.0.0.1:3002): " reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}






list_stream_services() {

	STREAM_DIR="/home/web/stream.d"
	printf "%-25s %-18s %-25s %-20s\n" "服务名" "通信类型" "本机地址" "后端地址"

	if [ -z "$(ls -A "$STREAM_DIR")" ]; then
		return
	fi

	for conf in "$STREAM_DIR"/*; do
		# 服务名取文件名
		service_name=$(basename "$conf" .conf)

		# 获取 upstream 块中的 server 后端 IP:端口
		backend=$(grep -Po '(?<=server )[^;]+' "$conf" | head -n1)

		# 获取 listen 端口
		listen_port=$(grep -Po '(?<=listen )[^;]+' "$conf" | head -n1)

		# 默认本地 IP
		ip_address
		local_ip="$ipv4_address"

		# 获取通信类型，优先从文件名后缀或内容判断
		if grep -qi 'udp;' "$conf"; then
			proto="udp"
		else
			proto="tcp"
		fi

		# 拼接监听 IP:端口
		local_addr="$local_ip:$listen_port"

		printf "%-22s %-14s %-21s %-20s\n" "$service_name" "$proto" "$local_addr" "$backend"
	done
}









stream_panel() {
	send_stats "Stream四层代理"
	local app_id="104"
	local docker_name="nginx"

	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "Streamレイヤー4プロキシ転送ツール $check_docker $update_status"
		echo "Nginx Stream は Nginx の TCP/UDP プロキシモジュールであり、高性能なトランスポート層トラフィック転送とロードバランシングを実現するために使用されます。"
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. インストール                  2. 更新                  3. 削除"
		echo "------------------------"
		echo "4. 転送サービスを追加 5. 転送サービスを変更 6. 転送サービスを削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1)
				nginx_install_status
				add_app_id
				send_stats "安装Stream四层代理"
				;;
			2)
				update_docker_compose_with_db_creds
				nginx_upgrade
				add_app_id
				send_stats "更新Stream四层代理"
				;;
			3)
				read -e -p "Nginx コンテナを削除してもよろしいですか？ ウェブサイトの機能に影響を与える可能性があります！ \(y/N\): " confirm
				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					docker rm -f nginx
					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					send_stats "更新Stream四层代理"
					echo "Nginx コンテナが削除されました。"
				else
					echo "操作はキャンセルされました。"
				fi

				;;

			4)
				ldnmp_Proxy_backend_stream
				add_app_id
				send_stats "添加四层代理"
				;;
			5)
				send_stats "编辑转发配置"
				read -e -p "編集したいサービス名を入力してください: " stream_name
				install nano
				nano /home/web/stream.d/$stream_name.conf
				docker restart nginx
				send_stats "修改四层代理"
				;;
			6)
				send_stats "删除转发配置"
				read -e -p "削除したいサービス名を入力してください: " stream_name
				rm /home/web/stream.d/$stream_name.conf > /dev/null 2>&1
				docker restart nginx
				send_stats "删除四层代理"
				;;
			*)
				break
				;;
		esac
		break_end
	done
}



ldnmp_Proxy_backend_stream() {
	clear
	webname="Stream レイヤ4プロキシ-ロードバランシング"

	send_stats "安装$webname"
	echo "$webname のデプロイを開始"

	# 获取代理名称
	read -rp "プロキシ転送名を入力してください（例: mysql_proxy） : " proxy_name
	if [ -z "$proxy_name" ]; then
		echo "名前は空にできません"; return 1
	fi

	# 获取监听端口
	read -rp "ローカルリスニングポートを入力してください（例: 3306） : " listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "ポートは数字である必要があります"; return 1
	fi

	echo "プロトコルタイプを選択してください："
	echo "1. TCP    2. UDP"
	read -rp "シリアル番号を入力してください [1-2]: " proto_choice

	case "$proto_choice" in
		1) proto="tcp"; listen_suffix="" ;;
		2) proto="udp"; listen_suffix=" udp" ;;
		*) echo "無効な選択"; return 1 ;;
	esac

	read -e -p "1 つ以上のバックエンド IP+ポートをスペースで区切って入力してください (例: 10.13.0.2:3306 10.13.0.3:3306): " reverseproxy_port

	nginx_install_status
	cd /home && mkdir -p web/stream.d
	grep -q '^[[:space:]]*stream[[:space:]]*{' /home/web/nginx.conf || echo -e '\nstream {\n    include /etc/nginx/stream.d/*.conf;\n}' | tee -a /home/web/nginx.conf
	wget -O /home/web/stream.d/$proxy_name.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend-stream.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/${proxy_name}_${backend}/g" /home/web/stream.d/"$proxy_name".conf
	sed -i "s|listen 80|listen $listen_port $listen_suffix|g" /home/web/stream.d/$proxy_name.conf
	sed -i "s|listen \[::\]:|listen [::]:${listen_port} ${listen_suffix}|g" "/home/web/stream.d/${proxy_name}.conf"

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/stream.d/$proxy_name.conf

	docker exec nginx nginx -s reload
	clear
	echo "あなたの $webname が構築されました！"
	echo "------------------------"
	echo "アクセスアドレス:"
	ip_address
	if [ -n "$ipv4_address" ]; then
		echo "$ipv4_address:${listen_port}"
	fi
	if [ -n "$ipv6_address" ]; then
		echo "$ipv6_address:${listen_port}"
	fi
	echo ""
}





find_container_by_host_port() {
	port="$1"
	docker_name=$(docker ps --format '{{.ID}} {{.Names}}' | while read id name; do
		if docker port "$id" | grep -q ":$port"; then
			echo "$name"
			break
		fi
	done)
}




ldnmp_web_status() {
	root_use
	while true; do
		local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
		local output="${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
		echo "LDNMP 環境"
		echo "------------------------"
		ldnmp_v

		echo -e "サイト: ${output}                      証明書の有効期限"
		echo -e "------------------------"
		for cert_file in /home/web/certs/*_cert.pem; do
		  local domain=$(basename "$cert_file" | sed 's/_cert.pem//')
		  if [ -n "$domain" ]; then
			local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
			local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
			printf "%-30s%s\n" "$domain" "$formatted_date"
		  fi
		done

		echo "------------------------"
		echo ""
		echo -e "データベース: ${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "サイトディレクトリ"
		echo "------------------------"
		echo -e "データ ${gl_hui}/home/web/html${gl_bai}     証明書 ${gl_hui}/home/web/certs${gl_bai}     設定 ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "操作"
		echo "------------------------"
		echo "1. ドメイン証明書を申請/更新 2. サイトドメインをコピー"
		echo "3. サイトキャッシュをクリア 4. 関連サイトを作成"
		echo "5. アクセスログを表示 6. エラーログを表示"
		echo "7. グローバル設定を編集 8. サイト設定を編集"
		echo "9. サイトデータベースを管理 10. サイト分析レポートを表示"
		echo "------------------------"
		echo "20. 指定サイトのデータを削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " sub_choice
		case $sub_choice in
			1)
				send_stats "申请域名证书"
				read -e -p "ドメイン名を入力してください: " yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "克隆站点域名"
				read -e -p "古いドメイン名を入力してください: " oddyuming
				read -e -p "新しいドメイン名を入力してください: " yuming
				install_certbot
				install_ssltls
				certs_status

				# mysql替换
				add_db

				local odd_dbname=$(echo "$oddyuming" | sed -e 's/[^A-Za-z0-9]/_/g')
				local odd_dbname="${odd_dbname}"

				docker exec mysql mysqldump -u root -p"$dbrootpasswd" $odd_dbname | docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname
				# docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $odd_dbname;"


				local tables=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW TABLES;" | awk '{ if (NR>1) print $1 }')
				for table in $tables; do
					columns=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW COLUMNS FROM $table;" | awk '{ if (NR>1) print $1 }')
					for column in $columns; do
						docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "UPDATE $table SET $column = REPLACE($column, '$oddyuming', '$yuming') WHERE $column LIKE '%$oddyuming%';"
					done
				done

				# 网站目录替换
				cp -r /home/web/html/$oddyuming /home/web/html/$yuming

				find /home/web/html/$yuming -type f -exec sed -i "s/$odd_dbname/$dbname/g" {} +
				find /home/web/html/$yuming -type f -exec sed -i "s/$oddyuming/$yuming/g" {} +

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf

				# rm /home/web/certs/${oddyuming}_key.pem
				# rm /home/web/certs/${oddyuming}_cert.pem

				cd /home/web && docker compose restart

				;;


			3)
				web_cache
				;;
			4)
				send_stats "创建关联站点"
				echo -e "既存のサイトに新しいドメインを関連付けてアクセスする"
				read -e -p "既存のドメイン名を入力してください: " oddyuming
				read -e -p "新しいドメイン名を入力してください: " yuming
				install_certbot
				install_ssltls
				certs_status

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s|server_name $oddyuming|server_name $yuming|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_cert.pem|/etc/nginx/certs/${yuming}_cert.pem|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_key.pem|/etc/nginx/certs/${yuming}_key.pem|g" /home/web/conf.d/$yuming.conf

				docker exec nginx nginx -s reload

				;;
			5)
				send_stats "查看访问日志"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "查看错误日志"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "编辑全局配置"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "编辑站点配置"
				read -e -p "サイト設定を編集します。編集したいドメイン名を入力してください: " yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "查看站点数据"
				install goaccess
				goaccess --log-format=COMBINED /home/web/log/nginx/access.log
				;;

			20)
				web_del
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null

				;;
			*)
				break  # 跳出循环，退出菜单
				;;
		esac
	done


}


check_panel_app() {
if $lujing > /dev/null 2>&1; then
	check_panel="${gl_lv}已安装${gl_bai}"
else
	check_panel=""
fi
}



install_panel() {
send_stats "${panelname}管理"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname} は、現在人気があり強力な運用保守管理パネルです。"
	echo "公式サイト紹介: $panelurl"

	echo ""
	echo "------------------------"
	echo "1. インストール 2. 管理 3. 削除"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install

			add_app_id
			send_stats "${panelname}安装"
			;;
		2)
			panel_app_manage

			add_app_id
			send_stats "${panelname}控制"

			;;
		3)
			panel_app_uninstall

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			send_stats "${panelname}卸载"
			;;
		*)
			break
			;;
	 esac
	 break_end
done

}



check_frp_app() {

if [ -d "/home/frp/" ]; then
	check_frp="${gl_lv}已安装${gl_bai}"
else
	check_frp="${gl_hui}未安装${gl_bai}"
fi

}



donlond_frp() {
  role="$1"
  config_file="/home/frp/${role}.toml"

  docker run -d \
	--name "$role" \
	--restart=always \
	--network host \
	-v "$config_file":"/frp/${role}.toml" \
	kjlion/frp:alpine \
	"/frp/${role}" -c "/frp/${role}.toml"

}




generate_frps_config() {

	send_stats "安装frp服务端"
	# 生成随机端口和凭证
	local bind_port=8055
	local dashboard_port=8056
	local token=$(openssl rand -hex 16)
	local dashboard_user="user_$(openssl rand -hex 4)"
	local dashboard_pwd=$(openssl rand -hex 8)

	mkdir -p /home/frp
	touch /home/frp/frps.toml
	cat <<EOF > /home/frp/frps.toml
[common]
bind_port = $bind_port
authentication_method = token
token = $token
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
EOF

	donlond_frp frps

	# 输出生成的信息
	ip_address
	echo "------------------------"
	echo "クライアント展開時に使用するパラメータ"
	echo "サービスIP: $ipv4_address"
	echo "token: $token"
	echo
	echo "FRPパネル情報"
	echo "FRPパネルアドレス: http://$ipv4_address:$dashboard_port"
	echo "FRPパネルユーザー名: $dashboard_user"
	echo "FRPパネルパスワード: $dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "安装frp客户端"
	read -e -p "外部 IP を入力してください: " server_addr
	read -e -p "外部接続トークンを入力してください: " token
	echo

	mkdir -p /home/frp
	touch /home/frp/frpc.toml
	cat <<EOF > /home/frp/frpc.toml
[common]
server_addr = ${server_addr}
server_port = 8055
token = ${token}

EOF

	donlond_frp frpc

	open_port 8055

}

add_forwarding_service() {
	send_stats "添加frp内网服务"
	# 提示用户输入服务名称和转发信息
	read -e -p "サービス名を入力してください: " service_name
	read -e -p "転送タイプ (tcp/udp) を入力してください [デフォルトは tcp]: " service_type
	local service_type=${service_type:-tcp}
	read -e -p "内部IPを入力してください [デフォルト 127.0.0.1]: " local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "内部ポート番号を入力してください: " local_port
	read -e -p "外部ポート番号を入力してください: " remote_port

	# 将用户输入写入配置文件
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 输出生成的信息
	echo "サービス $service_name が frpc.toml に正常に追加されました"

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	read -e -p "削除するサービス名を入力してください: " service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "サービス $service_name が frpc.toml から正常に削除されました"

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# 打印表头
	printf "%-20s %-25s %-30s %-10s\n" "服务名称" "内网地址" "外网地址" "协议"

	awk '
	BEGIN {
		server_addr=""
		server_port=""
		current_service=""
	}

	/^server_addr = / {
		gsub(/"|'"'"'/, "", $3)
		server_addr=$3
	}

	/^server_port = / {
		gsub(/"|'"'"'/, "", $3)
		server_port=$3
	}

	/^\[.*\]/ {
		# 如果已有服务信息，在处理新服务之前打印当前服务
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 更新当前服务名称
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# 清除之前的值
			local_ip=""
			local_port=""
			remote_port=""
			type=""
		}
	}

	/^local_ip = / {
		gsub(/"|'"'"'/, "", $3)
		local_ip=$3
	}

	/^local_port = / {
		gsub(/"|'"'"'/, "", $3)
		local_port=$3
	}

	/^remote_port = / {
		gsub(/"|'"'"'/, "", $3)
		remote_port=$3
	}

	/^type = / {
		gsub(/"|'"'"'/, "", $3)
		type=$3
	}

	END {
		# 打印最后一个服务的信息
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# 获取 FRP 服务端端口
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# 生成访问地址
generate_access_urls() {
	# 首先获取所有端口
	get_frp_ports

	# 检查是否有非 8055/8056 的端口
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# 只在有有效端口时显示标题和内容
	if [ "$has_valid_ports" = true ]; then
		echo "FRPサービス外部アクセスアドレス: "

		# 处理 IPv4 地址
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# 处理 IPv6 地址（如果存在）
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# 处理 HTTPS 配置
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				local frps_search_pattern="${ipv4_address}:${port}"
				local frps_search_pattern2="127.0.0.1:${port}"
				for file in /home/web/conf.d/*.conf; do
					if [ -f "$file" ]; then
						if grep -q "$frps_search_pattern" "$file" 2>/dev/null || grep -q "$frps_search_pattern2" "$file" 2>/dev/null; then
							echo "https://$(basename "$file" .conf)"
						fi
					fi
				done
			fi
		done
	fi
}


frps_main_ports() {
	ip_address
	generate_access_urls
}




frps_panel() {
	send_stats "FRP服务端"
	local app_id="55"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRPサーバー $check_frp $update_status"
		echo "FRP内部ネットワーク透過サービス環境を構築し、パブリックIPを持たないデバイスをインターネットに公開します"
		echo "公式サイト紹介: https://github.com/fatedier/frp/"
		echo "動画チュートリアル: https://youtu.be/Z3Z4OoaV2cw?t=124"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. インストール                  2. 更新                  3. 削除"
		echo "------------------------"
		echo "5. 内部サービスドメインアクセス 6. ドメインアクセス削除"
		echo "------------------------"
		echo "7. IP+ポートアクセス許可 8. IP+ポートアクセスブロック"
		echo "------------------------"
		echo "00. サービス状態の更新 0. 前のレベルのメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config

				add_app_id
				echo "FRPサーバーのインストールが完了しました"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps

				add_app_id
				echo "FRPサーバーの更新が完了しました"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "アプリケーションが削除されました"
				;;
			5)
				echo "内部ネットワークトンネリングサービスをドメインアクセスにリバースプロキシする"
				send_stats "FRP对外域名访问"
				add_yuming
				read -e -p "内部ネットワーク貫通サービスポート番号を入力してください: " frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "ドメイン名形式 example.com （https://なし）"
				web_del
				;;

			7)
				send_stats "允许IP访问"
				read -e -p "解放するポート番号を入力してください: " frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "阻止IP访问"
				echo "すでにドメインアクセスをリバースプロキシしている場合は、この機能を使用してIP+ポートアクセスをブロックできます。これにより、より安全になります。"
				read -e -p "ブロックするポート番号を入力してください: " frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "刷新FRP服务状态"
				echo "FRPサービスの状態をリフレッシュしました"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRP客户端"
	local app_id="56"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRPクライアント $check_frp $update_status"
		echo "サーバーと接続し、接続後、内部ネットワークトンネリングサービスをインターネットアクセス用に作成できます"
		echo "公式サイト紹介: https://github.com/fatedier/frp/"
		echo "ビデオチュートリアル: https://youtu.be/Z3Z4OoaV2cw?t=174"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. インストール                  2. 更新                  3. 削除"
		echo "------------------------"
		echo "4. 外部サービスを追加          5. 外部サービスを削除          6. サービスを手動で構成"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc

				add_app_id
				echo "FRPクライアントのインストールが完了しました"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc

				add_app_id
				echo "FRPクライアントの更新が完了しました"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "アプリケーションが削除されました"
				;;

			4)
				add_forwarding_service
				;;

			5)
				delete_forwarding_service
				;;

			6)
				install nano
				nano /home/frp/frpc.toml
				docker restart frpc
				;;

			*)
				break
				;;
		esac
		break_end
	done
}




yt_menu_pro() {

	local app_id="66"
	local VIDEO_DIR="/home/yt-dlp"
	local URL_FILE="$VIDEO_DIR/urls.txt"
	local ARCHIVE_FILE="$VIDEO_DIR/archive.txt"

	mkdir -p "$VIDEO_DIR"

	while true; do

		if [ -x "/usr/local/bin/yt-dlp" ]; then
		   local YTDLP_STATUS="${gl_lv}已安装${gl_bai}"
		else
		   local YTDLP_STATUS="${gl_hui}未安装${gl_bai}"
		fi

		clear
		send_stats "yt-dlp 下载工具"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlpは、YouTube、BiliBili、X（旧Twitter）など、数千のサイトをサポートする強力なビデオダウンロードツールです。"
		echo -e "公式サイト: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "ダウンロード済みビデオリスト:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(なし) "
		echo "-------------------------"
		echo "1. インストール                  2. 更新                  3. 削除"
		echo "-------------------------"
		echo "5. 個別ビデオダウンロード          6. 一括ビデオダウンロード          7. カスタムパラメータダウンロード"
		echo "8. MP3オーディオとしてダウンロード       9. ビデオディレクトリを削除          10. Cookie管理 (開発中)"
		echo "-------------------------"
		echo "0. 前のメニューに戻る"
		echo "-------------------------"
		read -e -p "オプション番号を入力してください: " choice

		case $choice in
			1)
				send_stats "正在安装 yt-dlp..."
				echo "yt-dlpをインストールしています..."
				install ffmpeg
				curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				chmod a+rx /usr/local/bin/yt-dlp

				add_app_id
				echo "インストール完了。続行するには任意のキーを押してください..."
				read ;;
			2)
				send_stats "正在更新 yt-dlp..."
				echo "yt-dlpを更新しています..."
				yt-dlp -U

				add_app_id
				echo "更新完了。続行するには任意のキーを押してください..."
				read ;;
			3)
				send_stats "正在卸载 yt-dlp..."
				echo "yt-dlpをアンインストールしています..."
				rm -f /usr/local/bin/yt-dlp

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "アンインストール完了。続行するには任意のキーを押してください..."
				read ;;
			5)
				send_stats "单个视频下载"
				read -e -p "ビデオリンクを入力してください: " url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "ダウンロード完了、任意のキーを押して続行してください..." ;;
			6)
				send_stats "批量视频下载"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# 複数のビデオリンクを入力する\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "バッチダウンロードを開始します..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "一括ダウンロード完了、任意のキーを押して続行してください..." ;;
			7)
				send_stats "自定义视频下载"
				read -e -p "yt-dlp パラメータ全体を入力してください( yt-dlp は含みません) : " custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "実行完了、任意のキーを押して続行してください..." ;;
			8)
				send_stats "MP3下载"
				read -e -p "ビデオリンクを入力してください: " url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "オーディオダウンロード完了、任意のキーを押して続行してください..." ;;

			9)
				send_stats "删除视频"
				read -e -p "削除する動画名を入力してください: " rmdir
				rm -rf "$VIDEO_DIR/$rmdir"
				;;
			*)
				break ;;
		esac
	done
}





current_timezone() {
	if grep -q 'Alpine' /etc/issue; then
	   date +"%Z %z"
	else
	   timedatectl | grep "Time zone" | awk '{print $3}'
	fi

}


set_timedate() {
	local shiqu="$1"
	if grep -q 'Alpine' /etc/issue; then
		install tzdata
		cp /usr/share/zoneinfo/${shiqu} /etc/localtime
		hwclock --systohc
	else
		timedatectl set-timezone ${shiqu}
	fi
}



# 修复dpkg中断问题
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}システムアップデート中です...${gl_bai}"
	if command -v dnf &>/dev/null; then
		dnf -y update
	elif command -v yum &>/dev/null; then
		yum -y update
	elif command -v apt &>/dev/null; then
		fix_dpkg
		DEBIAN_FRONTEND=noninteractive apt update -y
		DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
	elif command -v apk &>/dev/null; then
		apk update && apk upgrade
	elif command -v pacman &>/dev/null; then
		pacman -Syu --noconfirm
	elif command -v zypper &>/dev/null; then
		zypper refresh
		zypper update
	elif command -v opkg &>/dev/null; then
		opkg update
	else
		echo "不明なパッケージマネージャー！"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}システムクリーニング中です...${gl_bai}"
	if command -v dnf &>/dev/null; then
		rpm --rebuilddb
		dnf autoremove -y
		dnf clean all
		dnf makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v yum &>/dev/null; then
		rpm --rebuilddb
		yum autoremove -y
		yum clean all
		yum makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apt &>/dev/null; then
		fix_dpkg
		apt autoremove --purge -y
		apt clean -y
		apt autoclean -y
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apk &>/dev/null; then
		echo "パッケージマネージャーのキャッシュをクリア..."
		apk cache clean
		echo "システムログを削除..."
		rm -rf /var/log/*
		echo "APKキャッシュを削除..."
		rm -rf /var/cache/apk/*
		echo "一時ファイルを削除..."
		rm -rf /tmp/*

	elif command -v pacman &>/dev/null; then
		pacman -Rns $(pacman -Qdtq) --noconfirm
		pacman -Scc --noconfirm
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v zypper &>/dev/null; then
		zypper clean --all
		zypper refresh
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v opkg &>/dev/null; then
		echo "システムログを削除..."
		rm -rf /var/log/*
		echo "一時ファイルを削除..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "未使用の依存関係をクリーンアップ..."
		pkg autoremove -y
		echo "パッケージマネージャーのキャッシュをクリア..."
		pkg clean -y
		echo "システムログを削除..."
		rm -rf /var/log/*
		echo "一時ファイルを削除..."
		rm -rf /tmp/*

	else
		echo "不明なパッケージマネージャー！"
		return
	fi
	return
}



bbr_on() {

cat > /etc/sysctl.conf << EOF
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl -p

}


set_dns() {

ip_address

chattr -i /etc/resolv.conf
rm /etc/resolv.conf
touch /etc/resolv.conf


if [ -n "$ipv4_address" ]; then
	echo "nameserver $dns1_ipv4" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv4" >> /etc/resolv.conf
fi

if [ -n "$ipv6_address" ]; then
	echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
fi

chattr +i /etc/resolv.conf

}


set_dns_ui() {
root_use
send_stats "优化DNS"
while true; do
	clear
	echo "DNSアドレスを最適化"
	echo "------------------------"
	echo "現在のDNSアドレス"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 中国本土外DNS最適化:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 中国本土DNS最適化:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. DNS設定を手動編集"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "国外DNS优化"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "国内DNS优化"
		;;
	  3)
		install nano
		chattr -i /etc/resolv.conf
		nano /etc/resolv.conf
		chattr +i /etc/resolv.conf
		send_stats "手动编辑DNS配置"
		;;
	  *)
		break
		;;
	esac
done

}



restart_ssh() {
	restart sshd ssh > /dev/null 2>&1

}



correct_ssh_config() {

	local sshd_config="/etc/ssh/sshd_config"

	# 如果找到 PasswordAuthentication 设置为 yes
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# 如果找到 PubkeyAuthentication 设置为 yes
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# 如果 PasswordAuthentication 和 PubkeyAuthentication 都没有匹配，则设置默认值
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # 备份 SSH 配置文件
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSHポートを以下に変更しました: $new_port"

  sleep 1

}



add_sshkey() {
	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""
	cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	ip_address
	echo -e "秘密鍵情報が生成されました。必ずコピーして保存してください。後でSSHログインに使用するために、${gl_huang}${ipv4_address}_ssh.key${gl_bai} ファイルとして保存できます。"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}root秘密鍵ログインが有効になりました。rootパスワードログインは無効になりました。再接続すると有効になります${gl_bai}"

}


import_sshkey() {

	read -e -p "SSH公開鍵の内容を入力してください( 通常は 'ssh-rsa' または 'ssh-ed25519' で始まります) : " public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}エラー: 公開鍵の内容が入力されていません。${gl_bai}"
		return 1
	fi

	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	echo "$public_key" >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}公開鍵のインポートに成功しました。root秘密鍵ログインが有効になり、rootパスワードログインは無効になりました。再接続すると有効になります${gl_bai}"

}




add_sshpasswd() {

echo "rootパスワードを設定"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}rootログイン設定完了！ ${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}ヒント: ${gl_bai}この機能はrootユーザーで実行する必要があります！" && break_end && kejilion
}



dd_xitong() {
		send_stats "重装系统"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "再インストール後の初期ユーザー名: ${gl_huang}root${gl_bai}  初期パスワード: ${gl_huang}LeitboGi0ro${gl_bai}  初期ポート: ${gl_huang}22${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "再インストール後の初期ユーザー名: ${gl_huang}Administrator${gl_bai}  初期パスワード: ${gl_huang}Teddysun.com${gl_bai}  初期ポート: ${gl_huang}3389${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "再インストール後の初期ユーザー名: ${gl_huang}root${gl_bai} 初期パスワード: ${gl_huang}123@@@${gl_bai} 初期ポート: ${gl_huang}22${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "再インストール後の初期ユーザー名: ${gl_huang}Administrator${gl_bai} 初期パスワード: ${gl_huang}123@@@${gl_bai} 初期ポート: ${gl_huang}3389${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "システムを再インストール"
			echo "--------------------------------"
			echo -e "${gl_hong}注意: ${gl_bai}再インストールには切断のリスクが伴います。不安な場合は慎重に使用してください。再インストールには約15分かかります。事前にデータをバックアップしてください。"
			echo -e "${gl_hui}script support from leitbogioro and bin456789! ${gl_bai}"
			echo "------------------------"
			echo "1. Debian 13                  2. Debian 12"
			echo "3. Debian 11                  4. Debian 10"
			echo "------------------------"
			echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
			echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
			echo "------------------------"
			echo "21. Rocky Linux 10            22. Rocky Linux 9"
			echo "23. Alma Linux 10             24. Alma Linux 9"
			echo "25. oracle Linux 10           26. oracle Linux 9"
			echo "27. Fedora Linux 42           28. Fedora Linux 41"
			echo "29. CentOS 10                 30. CentOS 9"
			echo "------------------------"
			echo "31. Alpine Linux              32. Arch Linux"
			echo "33. Kali Linux                34. openEuler"
			echo "35. openSUSE Tumbleweed       36. fnos 飛牛公測版"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2025"
			echo "45. Windows Server 2022       46. Windows Server 2019"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "再インストールするシステムを選択してください: " sys_choice
			case "$sys_choice" in


			  1)
				send_stats "重装debian 13"
				dd_xitong_3
				bash reinstall.sh debian 13
				reboot
				exit
				;;

			  2)
				send_stats "重装debian 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  3)
				send_stats "重装debian 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  4)
				send_stats "重装debian 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  11)
				send_stats "重装ubuntu 24.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "重装ubuntu 22.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "重装ubuntu 20.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "重装ubuntu 18.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "重装rockylinux10"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "重装rockylinux9"
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				send_stats "重装alma10"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "重装alma9"
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				send_stats "重装oracle10"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "重装oracle9"
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				send_stats "重装fedora42"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "重装fedora41"
				dd_xitong_3
				bash reinstall.sh fedora 41
				reboot
				exit
				;;

			  29)
				send_stats "重装centos10"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "重装centos9"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "重装alpine"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "重装arch"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "重装kali"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "重装openeuler"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "重装opensuse"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "重装飞牛"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;

			  41)
				send_stats "重装windows11"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;

			  42)
				dd_xitong_2
				send_stats "重装windows10"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;

			  43)
				send_stats "重装windows7"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "重装windows server 25"
				dd_xitong_2
				bash InstallNET.sh -windows 2025 -lang "cn"
				reboot
				exit
				;;

			  45)
				send_stats "重装windows server 22"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;

			  46)
				send_stats "重装windows server 19"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "重装windows11 ARM"
				dd_xitong_4
				bash reinstall.sh dd --img https://r2.hotdog.eu.org/win11-arm-with-pagefile-15g.xz
				reboot
				exit
				;;

			  *)
				break
				;;
			esac
		  done
}


bbrv3() {
		  root_use
		  send_stats "bbrv3管理"

		  local cpu_arch=$(uname -m)
		  if [ "$cpu_arch" = "aarch64" ]; then
			bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)
			break_end
			linux_Settings
		  fi

		  if dpkg -l | grep -q 'linux-xanmod'; then
			while true; do
				  clear
				  local kernel_version=$(uname -r)
				  echo "XanModのBBRv3カーネルがインストールされています"
				  echo "現在のカーネルバージョン: $kernel_version"

				  echo ""
				  echo "カーネル管理"
				  echo "------------------------"
				  echo "1. BBRv3カーネルを更新              2. BBRv3カーネルを削除"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# 步骤3：添加存储库
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "XanModカーネルが更新されました。再起動後に有効になります"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "XanModカーネルが削除されました。再起動後に有効になります"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "BBRv3アクセラレーションの設定"
		  echo "ビデオ紹介: https://youtu.be/ua2_hmCRL4E"
		  echo "------------------------------------------------"
		  echo "Debian/Ubuntuのみサポート"
		  echo "データをバックアップしてください。LinuxカーネルをアップグレードしてBBRv3を有効にします。"
		  echo "------------------------------------------------"
		  read -e -p "続行してもよろしいですか？ \(y/N\): " choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "現在の環境はサポートされていません。DebianおよびUbuntuシステムのみサポートしています。"
					break_end
					linux_Settings
				fi
			else
				echo "オペレーティングシステムのタイプを特定できません"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# 步骤3：添加存储库
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "XanModカーネルがインストールされ、BBRv3が正常に有効化されました。再起動後に有効になります。"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "キャンセルしました"
			  ;;
			*)
			  echo "無効な選択です。Y または N を入力してください。"
			  ;;
		  esac
		fi

}


elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "ELRepo GPG公開鍵をインポート中..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "サポートされていないオペレーティングシステム: $os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "検出されたオペレーティングシステム: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ "$os_version" == 8 ]]; then
		echo "ELRepoリポジトリ設定をインストール中 (バージョン8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "ELRepoリポジトリ設定をインストール中 (バージョン9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "ELRepoリポジトリ設定をインストール中 (バージョン10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "サポートされていないシステムバージョン: $os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "ELRepoカーネルリポジトリを有効にして、最新のメラインカーネルをインストールします..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "ELRepoリポジトリ設定がインストールされ、最新のメラインカーネルに更新されました。"
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "红帽内核管理"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "ELRepoカーネルがインストールされています"
				  echo "現在のカーネルバージョン: $kernel_version"

				  echo ""
				  echo "カーネル管理"
				  echo "------------------------"
				  echo "1. ELRepoカーネルを更新する 2. ELRepoカーネルを削除する"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "更新红帽内核"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "ELRepoカーネルが削除されました。再起動後に有効になります。"
						send_stats "卸载红帽内核"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "データをバックアップしてください。Linuxカーネルをアップグレードします。"
		  echo "ビデオ紹介: https://youtu.be/wamvDukHzUg?t=529"
		  echo "------------------------------------------------"
		  echo "Red Hat系ディストリビューション CentOS/RedHat/Alma/Rocky/oracle のみサポート"
		  echo "Linuxカーネルのアップグレードは、システムのパフォーマンスとセキュリティを向上させることができます。条件が許せば試すことをお勧めしますが、本番環境でのアップグレードは慎重に行ってください。"
		  echo "------------------------------------------------"
		  read -e -p "続行してもよろしいですか？ \(y/N\): " choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "升级红帽内核"
			  server_reboot
			  ;;
			[Nn])
			  echo "キャンセルしました"
			  ;;
			*)
			  echo "無効な選択です。Y または N を入力してください。"
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}ウイルスの定義ファイルを更新中...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "スキャンするディレクトリを指定してください。"
		return
	fi

	echo -e "${gl_huang}ディレクトリ "$@" をスキャン中... ${gl_bai}"

	# 构建 mount 参数
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# 构建 clamscan 命令参数
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# 执行 Docker 命令
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}"$@" のスキャンが完了しました。ウイルスのレポートは ${gl_huang}/home/docker/clamav/log/scan.log${gl_bai} に保存されています。"
	echo -e "${gl_lv}ウイルスがある場合は、${gl_huang}scan.log${gl_lv}ファイルで FOUND キーワードを検索してウイルスの位置を確認してください。${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "病毒扫描管理"
		  while true; do
				clear
				echo "clamav ウイルススキャンツール"
				echo "ビデオ紹介: https://youtu.be/UQglgnv-aLU"
				echo "------------------------"
				echo "は、さまざまな種類のマルウェアを検出および削除するために主に利用される、オープンソースのウイルス対策ソフトウェアツールです。"
				echo "ウイルス、トロイの木馬、スパイウェア、悪意のあるスクリプト、その他の有害なソフトウェアが含まれます。"
				echo "------------------------"
				echo -e "${gl_lv}1. フルディスクスキャン ${gl_bai}             ${gl_huang}2. 重要ディレクトリのスキャン ${gl_bai}            ${gl_kjlan} 3. カスタムディレクトリのスキャン ${gl_bai}"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択を入力してください: " sub_choice
				case $sub_choice in
					1)
					  send_stats "全盘扫描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "重要目录扫描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "自定义目录扫描"
					  read -e -p "スキャンするディレクトリを入力してください。スペースで区切ってください( 例: /etc /var /usr /home /root) : " directories
					  install_docker
					  clamav_freshclam
					  clamav_scan $directories
					  break_end
						;;
					*)
					  break  # 跳出循环，退出菜单
						;;
				esac
		  done

}




# 高性能模式优化函数
optimize_high_performance() {
	echo -e "${gl_lv}切り替え中 ${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを最適化中...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}仮想メモリを最適化中...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化中...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=250000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

	echo -e "${gl_lv}キャッシュ管理を最適化中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}その他の最適化...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv}バランスモードに切り替え中...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを最適化中...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}仮想メモリを最適化中...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化中...${gl_bai}"
	sysctl -w net.core.rmem_max=8388608 2>/dev/null
	sysctl -w net.core.wmem_max=8388608 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=125000 2>/dev/null
	sysctl -w net.core.somaxconn=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 32768 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 49151' 2>/dev/null

	echo -e "${gl_lv}キャッシュ管理を最適化中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}その他の最適化...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}デフォルト設定に復元中...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを復元中...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}仮想メモリを復元中...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を復元中...${gl_bai}"
	sysctl -w net.core.rmem_max=212992 2>/dev/null
	sysctl -w net.core.wmem_max=212992 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=1000 2>/dev/null
	sysctl -w net.core.somaxconn=128 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 6291456' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 16384 4194304' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=0 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='32768 60999' 2>/dev/null

	echo -e "${gl_lv}キャッシュ管理を復元中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}CPU設定を復元中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}その他の最適化を復元中...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}ウェブサイト構築最適化モードに切り替えます...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを最適化中...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}仮想メモリを最適化中...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化中...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

	echo -e "${gl_lv}キャッシュ管理を最適化中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}その他の最適化...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux内核调优管理"
	  echo "Linux システムカーネルパラメータ最適化"
	  echo "ビデオ紹介: https://youtu.be/TCsd0pepBac"
	  echo "------------------------------------------------"
	  echo "複数のシステムパラメータチューニングモードを提供し、ユーザーは自身の使用シナリオに応じて選択・切り替えが可能です。"
	  echo -e "${gl_huang}ヒント: ${gl_bai}本番環境では慎重に使用してください！"
	  echo "--------------------"
	  echo "1. 高パフォーマンス最適化モード: ファイルディスクリプタ、仮想メモリ、ネットワーク設定、キャッシュ管理、CPU設定を最適化し、システムパフォーマンスを最大化します。"
	  echo "2. バランス最適化モード: パフォーマンスとリソース消費のバランスを取り、日常の使用に適しています。"
	  echo "3. ウェブサイト最適化モード: ウェブサイトサーバー向けに最適化され、同時接続処理能力、応答速度、全体的なパフォーマンスを向上させます。"
	  echo "4. ライブストリーム最適化モード: ライブストリームプッシュの特別なニーズに合わせて最適化され、遅延を削減し、転送パフォーマンスを向上させます。"
	  echo "5. ゲームサーバー最適化モード: ゲームサーバー向けに最適化され、同時処理能力と応答速度を向上させます。"
	  echo "6. デフォルト設定に戻す: システム設定をデフォルト構成に戻します。"
	  echo "--------------------"
	  echo "0. 前のメニューに戻る"
	  echo "--------------------"
	  read -e -p "選択を入力してください: " sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "高性能模式优化"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "均衡模式优化"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "网站优化模式"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "直播推流优化"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "游戏服优化"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "还原默认设置"
			  ;;
		  *)
			  break
			  ;;
	  esac
	  break_end
	done
}





update_locale() {
	local lang=$1
	local locale_file=$2

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case $ID in
			debian|ubuntu|kali)
				install locales
				sed -i "s/^\s*#\?\s*${locale_file}/${locale_file}/" /etc/locale.gen
				locale-gen
				echo "LANG=${lang}" > /etc/default/locale
				export LANG=${lang}
				echo -e "${gl_lv}システム言語が $lang に変更されました。SSH接続を再確立すると有効になります。${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}システム言語が $lang に変更されました。SSH接続を再確立すると有効になります。${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "サポートされていないシステム: $ID"
				break_end
				;;
		esac
	else
		echo "サポートされていないシステム、システムタイプを認識できません。"
		break_end
	fi
}




linux_language() {
root_use
send_stats "切换系统语言"
while true; do
  clear
  echo "現在のシステム言語: $LANG"
  echo "------------------------"
  echo "1. English          2. 简体中文          3. 繁體中文"
  echo "------------------------"
  echo "0. 前のメニューに戻る"
  echo "------------------------"
  read -e -p "選択を入力してください: " choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "切换到英文"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "切换到简体中文"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "切换到繁体中文"
		  ;;
	  *)
		  break
		  ;;
  esac
done
}



shell_bianse_profile() {

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	sed -i '/^PS1=/d' ~/.bashrc
	echo "${bianse}" >> ~/.bashrc
	# source ~/.bashrc
else
	sed -i '/^PS1=/d' ~/.profile
	echo "${bianse}" >> ~/.profile
	# source ~/.profile
fi
echo -e "${gl_lv}変更が完了しました。SSH接続を再確立すると変更を確認できます！${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "命令行美化工具"
  while true; do
	clear
	echo "コマンドライン整形ツール"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " choice

	case $choice in
	  1)
		local bianse="PS1='\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;31m\]\w\[\033[0m\] # '"
		shell_bianse_profile

		;;
	  2)
		local bianse="PS1='\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;36m\]\h\[\033[0m\] \[\033[1;33m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  3)
		local bianse="PS1='\[\033[1;31m\]\u\[\033[0m\]@\[\033[1;32m\]\h\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  4)
		local bianse="PS1='\[\033[1;36m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\] \[\033[1;37m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  5)
		local bianse="PS1='\[\033[1;37m\]\u\[\033[0m\]@\[\033[1;31m\]\h\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  6)
		local bianse="PS1='\[\033[1;33m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;35m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  7)
		local bianse=""
		shell_bianse_profile
		;;
	  *)
		break
		;;
	esac

  done
}




linux_trash() {
  root_use
  send_stats "系统回收站"

  local bashrc_profile="/root/.bashrc"
  local TRASH_DIR="$HOME/.local/share/Trash/files"

  while true; do

	local trash_status
	if ! grep -q "trash-put" "$bashrc_profile"; then
		trash_status="${gl_hui}未启用${gl_bai}"
	else
		trash_status="${gl_lv}已启用${gl_bai}"
	fi

	clear
	echo -e "現在のゴミ箱 ${trash_status}"
	echo -e "有効にすると、rm による削除ファイルはまずゴミ箱に入り、誤って重要なファイルを削除することを防ぎます！"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "ごみ箱は空です"
	echo "------------------------"
	echo "1. ごみ箱を有効にする 2. ごみ箱を無効にする"
	echo "3. コンテンツを復元する 4. ごみ箱を空にする"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "ごみ箱が有効になり、削除されたファイルはごみ箱に移動されます。"
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "ごみ箱が無効になり、ファイルは直接削除されます。"
		sleep 2
		;;
	  3)
		read -e -p "復元するファイル名を入力してください: " file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restore をホームディレクトリに復元しました。"
		else
		  echo "ファイルが存在しません。"
		fi
		;;
	  4)
		read -e -p "ゴミ箱を空にする確認（y/N）：" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "ごみ箱は空になりました。"
		fi
		;;
	  *)
		break
		;;
	esac
  done
}

linux_fav() {
send_stats "命令收藏夹"
bash <(curl -l -s ${gh_proxy}raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh)
}

# 创建备份
create_backup() {
	send_stats "创建备份"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# 提示用户输入备份目录
	echo "バックアップ例の作成: "
	echo "- 単一ディレクトリのバックアップ: /var/www"
	echo "- 複数のディレクトリのバックアップ: /etc /home /var/log"
	echo "- Enter を直接押すと、デフォルトのディレクトリ (/etc /usr /home) が使用されます。"
	read -r -p "バックアップするディレクトリを入力してください(複数のディレクトリはスペースで区切ってください、直接Enterを押すとデフォルトのディレクトリが使用されます) : " input

	# 如果用户没有输入目录，则使用默认目录
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# 将用户输入的目录按空格分隔成数组
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# 生成备份文件前缀
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# 提取目录名称并去除斜杠
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 去除最后一个下划线
	local PREFIX=${PREFIX%_}

	# 生成备份文件名
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# 打印用户选择的目录
	echo "選択されたバックアップディレクトリは次のとおりです: "
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "バックアップ $BACKUP_NAME を作成中..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "バックアップが正常に作成されました: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "バックアップの作成に失敗しました！ "
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	read -e -p "復元するバックアップファイル名を入力してください:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルが存在しません！ "
		exit 1
	fi

	echo "バックアップ $BACKUP_NAME を復元中..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "バックアップの復元に成功しました！"
	else
		echo "バックアップの復元に失敗しました！"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "利用可能なバックアップ:"
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	read -e -p "削除するバックアップファイル名を入力してください:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルが存在しません！ "
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "バックアップの削除に成功しました！"
	else
		echo "バックアップの削除に失敗しました！"
		exit 1
	fi
}

# 备份主菜单
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "系统备份功能"
		echo "システムバックアップ機能"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. バックアップ作成 2. バックアップ復元 3. バックアップ削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "続行するにはEnterキーを押してください..."
	done
}









# 显示连接列表
list_connections() {
	echo "保存済みの接続:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "新規接続作成例:"
	echo "  - 接続名: my_server"
	echo "  - IPアドレス: 192.168.1.100"
	echo "  - ユーザー名: root"
	echo "  - ポート: 22"
	echo "------------------------"
	read -e -p "接続名を入力してください:" name
	read -e -p "IPアドレスを入力してください:" ip
	read -e -p "ユーザー名を入力してください (デフォルト root) :" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "ポート番号を入力してください (デフォルト 22) :" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "認証方式を選択してください:"
	echo "1. パスワード"
	echo "2. キー"
	read -e -p "選択を入力してください (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "请输入密码: " password_or_key
			echo  # 换行
			;;
		2)
			echo "キーの内容を貼り付けてください (貼り付け後、Enterを2回押してください):"
			local password_or_key=""
			while IFS= read -r line; do
				# 如果输入为空行且密钥内容已经包含了开头，则结束输入
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 如果是第一行或已经开始输入密钥内容，则继续添加
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# 检查是否是密钥内容
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "無効な選択です！"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "接続が保存されました！"
}



# 删除连接
delete_connection() {
	send_stats "删除连接"
	read -e -p "削除する接続番号を入力してください:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "エラー: 対応する接続が見つかりませんでした。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "接続が削除されました！ "
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	read -e -p "使用する接続番号を入力してください:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "エラー: 対応する接続が見つかりませんでした。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "$name ($ip) に接続しています..."
	if [[ -f "$password_or_key" ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました！ 以下を確認してください:"
			echo "1. キーファイルパスは正しいですか: $password_or_key"
			echo "2. キーファイルの権限は正しいですか (600 である必要があります)。"
			echo "3. ターゲットサーバーがキーログインを許可していますか。"
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &> /dev/null; then
			echo "エラー: sshpass がインストールされていません。sshpass をインストールしてください。"
			echo "インストール方法:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました！ 以下を確認してください:"
			echo "1. ユーザー名とパスワードは正しいですか。"
			echo "2. ターゲットサーバーがパスワードログインを許可していますか。"
			echo "3. ターゲットサーバーの SSH サービスは正常に動作していますか。"
		fi
	fi
}


ssh_manager() {
	send_stats "ssh远程连接工具"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 检查配置文件和密钥目录是否存在，如果不存在则创建
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "SSH リモート接続ツール"
		echo "SSH を使用して他の Linux システムに接続できます"
		echo "------------------------"
		list_connections
		echo "1. 新規接続を作成する 2. 接続を使用する 3. 接続を削除する"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "無効な選択です。再試行してください。" ;;
		esac
	done
}












# 列出可用的硬盘分区
list_partitions() {
	echo "利用可能なハードディスクパーティション:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	read -e -p "マウントするパーティション名を入力してください (例: sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションが存在しません！ "
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションは既にマウントされています！ "
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "パーティションのマウントに成功しました: $MOUNT_POINT"
	else
		echo "パーティションのマウントに失敗しました！ "
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	read -e -p "削除するパーティション名を入力してください (例: sda1):" PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "パーティションがマウントされていません！"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティションのマウント解除に成功しました: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "パーティションのマウント解除に失敗しました！"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "マウントされたパーティション:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	read -e -p "フォーマットするパーティション名を入力してください (例: sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションが存在しません！ "
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションは既にマウントされています。先にマウント解除してください！"
		return
	fi

	# 选择文件系统类型
	echo "ファイルシステムタイプを選択してください:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "選択を入力してください: " FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "無効な選択です！"; return ;;
	esac

	# 确认格式化
	read -e -p "/dev/$PARTITION を $FS_TYPE でフォーマットすることを確認しますか? (y/N):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "操作はキャンセルされました。"
		return
	fi

	# 格式化分区
	echo "パーティション /dev/$PARTITION を $FS_TYPE としてフォーマットしています..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティションのフォーマットに成功しました！"
	else
		echo "パーティションのフォーマットに失敗しました！"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	read -e -p "チェックするパーティション名を入力してください (例: sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションが存在しません！ "
		return
	fi

	# 检查分区状态
	echo "パーティション /dev/$PARTITION の状態を確認しています:"
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "ハードディスクパーティション管理"
		echo -e "${gl_huang}この機能は内部テスト段階です。本番環境では使用しないでください。${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. パーティションのマウント 2. パーティションのマウント解除 3. マウントされたパーティションの表示"
		echo "4. パーティションのフォーマット 5. パーティション状態の確認"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "続行するにはEnterキーを押してください..."
	done
}




# 显示任务列表
list_tasks() {
	echo "保存された同期タスク:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
	echo "新しい同期タスクの例を作成します:"
	echo " - タスク名: backup_www"
	echo " - ローカルディレクトリ: /var/www"
	echo " - リモートアドレス: user@192.168.1.100"
	echo " - リモートディレクトリ: /backup/www"
	echo " - ポート番号(デフォルト 22)"
	echo "---------------------------------"
	read -e -p "タスク名を入力してください:" name
	read -e -p "ローカルディレクトリを入力してください:" local_path
	read -e -p "リモートディレクトリを入力してください:" remote_path
	read -e -p "リモートユーザー@IPを入力してください:" remote
	read -e -p "SSHポートを入力してください (デフォルト 22): " port
	port=${port:-22}

	echo "認証方式を選択してください:"
	echo "1. パスワード"
	echo "2. キー"
	read -e -p "選択してください (1/2): " auth_choice

	case $auth_choice in
		1)
			read -s -p "请输入密码: " password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "キーの内容を貼り付けてください (貼り付け後、Enterを2回押してください):"
			local password_or_key=""
			while IFS= read -r line; do
				# 如果输入为空行且密钥内容已经包含了开头，则结束输入
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 如果是第一行或已经开始输入密钥内容，则继续添加
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# 检查是否是密钥内容
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "無効なキーコンテンツ!"
				return
			fi
			;;
		*)
			echo "無効な選択です！"
			return
			;;
	esac

	echo "同期モードを選択してください:"
	echo "1. 標準モード (-avz)"
	echo "2. ターゲットファイルを削除 (-avz --delete)"
	read -e -p "選択してください (1/2): " mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "無効な選択です。デフォルトの-avzを使用します"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "タスクが保存されました!"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	read -e -p "削除するタスク番号を入力してください: " num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "エラー: 対応するタスクが見つかりません。"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "タスクが削除されました!"
}


run_task() {
	send_stats "执行同步任务"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# 解析参数
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 如果没有传入任务编号，提示用户输入
	if [[ -z "$num" ]]; then
		read -e -p "実行するタスク番号を入力してください: " num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "エラー: このタスクが見つかりません!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 根据同步方向调整源和目标路径
	if [[ "$direction" == "pull" ]]; then
		echo "同期中、リモートからローカルへ: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "同期中、ローカルからリモートへ: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "エラー: sshpass がインストールされていません。sshpass をインストールしてください。"
			echo "インストール方法:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f "$password_or_key" ]]; then
			echo "エラー: キーファイルが存在しません: $password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "警告: キーファイルの権限が正しくありません。修正中です..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "同期が完了しました!"
	else
		echo "同期に失敗しました! 以下を確認してください:"
		echo "1. ネットワーク接続は正常ですか"
		echo "2. リモートホストにアクセスできますか"
		echo "3. 認証情報は正しいですか"
		echo "4. ローカルおよびリモートディレクトリには正しいアクセス権がありますか"
	fi
}


# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	read -e -p "定期同期するタスク番号を入力してください: " num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "エラー: 有効なタスク番号を入力してください!"
		return
	fi

	echo "実行間隔を選択してください："
	echo "1. 1時間ごとに実行"
	echo "2. 1日ごとに実行"
	echo "3. 1週間ごとに実行"
	read -e -p "オプションを選択してください (1/2/3): " interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "エラー：有効なオプションを入力してください！" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "エラー：このタスクの定時同期は既に存在します！"
		return
	fi

	# 创建到用户的 crontab
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "定時タスクが作成されました：$cron_job"
}

# 查看定时任务
view_tasks() {
	echo "現在の定時タスク："
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	read -e -p "削除するタスク番号を入力してください: " num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "エラー: 有効なタスク番号を入力してください!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "タスク番号 $num の定時タスクを削除しました"
}


# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync リモート同期ツール"
		echo "リモートディレクトリ間の同期、増分同期をサポートし、効率的で安定しています。"
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 新規タスク作成           2. タスク削除"
		echo "3. ローカル同期からリモートへ実行   4. リモート同期からローカルへ実行"
		echo "5. 定時タスク作成         6. 定時タスク削除"
		echo "---------------------------------"
		echo "0. 前のメニューに戻る"
		echo "---------------------------------"
		read -e -p "選択を入力してください: " choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "無効な選択です。再試行してください。" ;;
		esac
		read -e -p "続行するにはEnterキーを押してください..."
	done
}









linux_info() {

	clear
	send_stats "系统信息查询"

	ip_address

	local cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')

	local cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
		<(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))

	local cpu_cores=$(nproc)

	local cpu_freq=$(cat /proc/cpuinfo | grep "MHz" | head -n 1 | awk '{printf "%.1f GHz\n", $4/1000}')

	local mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2fM (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

	local disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

	local ipinfo=$(curl -s ipinfo.io)
	local country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
	local city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
	local isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')

	local load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
	local dns_addresses=$(awk '/^nameserver/{printf "%s ", $2} END {print ""}' /etc/resolv.conf)


	local cpu_arch=$(uname -m)

	local hostname=$(uname -n)

	local kernel_version=$(uname -r)

	local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
	local queue_algorithm=$(sysctl -n net.core.default_qdisc)

	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')

	output_status

	local current_time=$(date "+%Y-%m-%d %I:%M %p")


	local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

	local runtime=$(uptime -p | sed 's/up //')

	local timezone=$(current_timezone)


	echo ""
	echo -e "システム情報クエリ"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ホスト名:                   ${gl_bai}$hostname"
	echo -e "${gl_kjlan}システムバージョン:         ${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linuxバージョン:            ${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPUアーキテクチャ:          ${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPUモデル:                  ${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPUコア数:                  ${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU周波数:                  ${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU使用率:                  ${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}システム負荷:               ${gl_bai}$load"
	echo -e "${gl_kjlan}物理メモリ:                 ${gl_bai}$mem_info"
	echo -e "${gl_kjlan}仮想メモリ:                 ${gl_bai}$swap_info"
	echo -e "${gl_kjlan}ディスク使用率:             ${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}合計受信:                   ${gl_bai}$rx"
	echo -e "${gl_kjlan}合計送信:                   ${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ネットワークアルゴリズム:   ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ISP:                        ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4 アドレス:              ${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6 アドレス:              ${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS アドレス:               ${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}地理位置:                   ${gl_bai}$country $city"
	echo -e "${gl_kjlan}システム時間:               ${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}稼働時間:                   ${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "基础工具"
	  echo -e "基本ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}curl ダウンロードツール ${gl_huang}★${gl_bai}               ${gl_kjlan}2.   ${gl_bai}wget ダウンロードツール ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo スーパー管理者権限ツール           ${gl_kjlan}4.   ${gl_bai}socat 通信接続ツール"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop システム監視ツール                 ${gl_kjlan}6.   ${gl_bai}iftop ネットワークトラフィック監視ツール"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP 圧縮解凍ツール                ${gl_kjlan}8.   ${gl_bai}tar GZ 圧縮解凍ツール"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux マルチバックグラウンド実行ツール   ${gl_kjlan}10.  ${gl_bai}ffmpeg オーディオ/ビデオエンコーディングライブストリームプッシュツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop 現代的な監視ツール ${gl_huang}★${gl_bai}               ${gl_kjlan}12.  ${gl_bai}ranger ファイル管理ツール"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu ディスク使用率確認ツール           ${gl_kjlan}14.  ${gl_bai}fzf グローバル検索ツール"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim テキストエディタ                    ${gl_kjlan}16.  ${gl_bai}nano テキストエディタ ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}git バージョン管理システム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}ハッカーミッション スクリーンセーバー   ${gl_kjlan}22.  ${gl_bai}ヘビ スクリーンセーバー"
	  echo -e "${gl_kjlan}26.  ${gl_bai}テトリス ミニゲーム                     ${gl_kjlan}27.  ${gl_bai}ヘビ ミニゲーム"
	  echo -e "${gl_kjlan}28.  ${gl_bai}スペースインベーダー ミニゲーム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}すべてインストール                      ${gl_kjlan}32.  ${gl_bai}すべてインストール (スクリーンセーバーとゲームを除く) ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}すべてアンインストール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}指定されたツールをインストール          ${gl_kjlan}42.  ${gl_bai}指定されたツールをアンインストール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  curl --help
			  send_stats "安装curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  wget --help
			  send_stats "安装wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  sudo --help
			  send_stats "安装sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  socat -h
			  send_stats "安装socat"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "安装htop"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "安装iftop"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  unzip
			  send_stats "安装unzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  tar --help
			  send_stats "安装tar"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  tmux --help
			  send_stats "安装tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "ツールがインストールされました。使用方法は次のとおりです。"
			  ffmpeg --help
			  send_stats "安装ffmpeg"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "安装btop"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "安装ranger"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "安装ncdu"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "安装fzf"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "安装vim"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "安装nano"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "安装git"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "安装cmatrix"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "安装sl"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "安装bastet"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "安装nsnake"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "安装ninvaders"
			  ;;

		  31)
			  clear
			  send_stats "全部安装"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "全部安装（不含游戏和屏保）"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "全部卸载"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "インストールするツール名を入力してください ( wget curl sudo htop) : " installname
			  install $installname
			  send_stats "安装指定软件"
			  ;;
		  42)
			  clear
			  read -e -p "アンインストールするツール名を入力してください ( htop ufw tmux cmatrix) : " removename
			  remove $removename
			  send_stats "卸载指定软件"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "bbr管理"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			  echo "現在のTCP輻輳制御アルゴリズム：$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR管理"
			  echo "------------------------"
			  echo "1. BBRv3を有効にする        2. BBRv3を無効にする（再起動します）"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択を入力してください: " sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "alpine开启bbr3"
					  ;;
				  2)
					sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf
					sysctl -p
					server_reboot
					  ;;
				  *)
					  break  # 跳出循环，退出菜单
					  ;;

			  esac
		done
	else
		install wget
		wget --no-check-certificate -O tcpx.sh ${gh_proxy}raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
		chmod +x tcpx.sh
		./tcpx.sh
	fi


}





docker_ssh_migration() {

	GREEN='\033[0;32m'
	RED='\033[0;31m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;36m'
	NC='\033[0m'

	is_compose_container() {
		local container=$1
		docker inspect "$container" | jq -e '.[0].Config.Labels["com.docker.compose.project"]' >/dev/null 2>&1
	}

	list_backups() {
		local BACKUP_ROOT="/tmp"
		echo -e "${BLUE}現在のバックアップリスト:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "バックアップなし"
	}



	# ----------------------------
	# 备份
	# ----------------------------
	backup_docker() {
		send_stats "Docker备份"

		echo -e "${YELLOW}Docker コンテナをバックアップ中...${NC}"
		docker ps --format '{{.Names}}'
		read -e -p  "请输入要备份的容器名（多个空格分隔，回车备份全部运行中容器）: " containers

		install tar jq gzip
		install_docker

		local BACKUP_ROOT="/tmp"
		local DATE_STR=$(date +%Y%m%d_%H%M%S)
		local TARGET_CONTAINERS=()
		if [ -z "$containers" ]; then
			mapfile -t TARGET_CONTAINERS < <(docker ps --format '{{.Names}}')
		else
			read -ra TARGET_CONTAINERS <<< "$containers"
		fi
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && { echo -e "${RED}コンテナが見つかりません${NC}"; return; }

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" > "$RESTORE_SCRIPT"
		echo "set -e" >> "$RESTORE_SCRIPT"
		echo "# 自動生成された復元スクリプト" >> "$RESTORE_SCRIPT"

		# 记录已打包过的 Compose 项目路径，避免重复打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN}コンテナをバックアップ: $c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" > "$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE}検出された $c は Docker Compose コンテナです${NC}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p  "未检测到 compose 目录，请手动输入路径: " project_dir
				fi

				# 如果该 Compose 项目已经打包过，跳过
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}Compose プロジェクト [$project_name] はすでにバックアップされているため、重複パッケージをスキップします...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" > "${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" > "${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# docker-compose 復元: $project_name" >> "$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >> "$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}Compose プロジェクト [$project_name] はパッケージ化されました: ${project_dir}${NC}"
				else
					echo -e "${RED}docker-compose.yml が見つかりませんでした。このコンテナはスキップします...${NC}"
				fi
			else
				# 普通容器备份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "ボリュームのパッケージ化: $path"
					tar -czpf "${BACKUP_DIR}/${c}_$(basename $path).tar.gz" -C / "$(echo $path | sed 's/^\///')"
				done

				# 端口
				local PORT_ARGS=""
				mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[] | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$inspect_file" 2>/dev/null)
				for p in "${PORTS[@]}"; do PORT_ARGS+="-p $p "; done

				# 环境变量
				local ENV_VARS=""
				mapfile -t ENVS < <(jq -r '.[0].Config.Env[] | @sh' "$inspect_file")
				for e in "${ENVS[@]}"; do ENV_VARS+="-e $e "; done

				# 卷映射
				local VOL_ARGS=""
				for path in $VOL_PATHS; do VOL_ARGS+="-v $path:$path "; done

				# 镜像
				local IMAGE
				IMAGE=$(jq -r '.[0].Config.Image' "$inspect_file")

				echo -e "\n# コンテナを復元: $c" >> "$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >> "$RESTORE_SCRIPT"
			fi
		done


		# 备份 /home/docker 下的所有文件（不含子目录）
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE} /home/docker のファイルをバックアップ中...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${GREEN} /home/docker のファイルは以下にアーカイブされました: ${BACKUP_DIR}/home_docker_files.tar.gz${NC}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN} バックアップ完了: ${BACKUP_DIR}${NC}"
		echo -e "${GREEN} リストアスクリプトが利用可能です: ${RESTORE_SCRIPT}${NC}"


	}

	# ----------------------------
	# 还原
	# ----------------------------
	restore_docker() {

		send_stats "Docker还原"
		read -e -p  "请输入要还原的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED} バックアップディレクトリが存在しません${NC}"; return; }

		echo -e "${BLUE} リストア操作を開始します...${NC}"

		install tar jq gzip
		install_docker

		# --------- 优先还原 Compose 项目 ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p  "未找到原始路径，请输入还原目录路径: " original_path

				# 检查该 compose 项目的容器是否已经在运行
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${YELLOW} Compose プロジェクト [$project_name] はすでにコンテナが実行中なので、リストアをスキップします...${NC}"
					continue
				fi

				read -e -p  "确认还原 Compose 项目 [$project_name] 到路径 [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p  "请输入新的还原路径: " original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN} Compose プロジェクト [$project_name] は以下に展開されました: $original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN} Compose プロジェクト [$project_name] のリストアが完了しました! ${NC}"
			fi
		done

		# --------- 继续还原普通容器 ---------
		echo -e "${BLUE} 通常の Docker コンテナをチェックしてリストアします...${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${GREEN} コンテナを処理中: $container${NC}"

			# 检查容器是否已经存在且正在运行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW} コンテナ [$container] はすでに実行中なので、リストアをスキップします...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && { echo -e "${RED} イメージ情報が見つかりませんでした、スキップします: $container${NC}"; continue; }

			# 端口映射
			PORT_ARGS=""
			mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[]? | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$json")
			for p in "${PORTS[@]}"; do
				[[ -n "$p" ]] && PORT_ARGS="$PORT_ARGS -p $p"
			done

			# 环境变量
			ENV_ARGS=""
			mapfile -t ENVS < <(jq -r '.[0].Config.Env[]' "$json")
			for e in "${ENVS[@]}"; do
				ENV_ARGS="$ENV_ARGS -e \"$e\""
			done

			# 卷映射 + 卷数据恢复
			VOL_ARGS=""
			mapfile -t VOLS < <(jq -r '.[0].Mounts[] | "\(.Source):\(.Destination)"' "$json")
			for v in "${VOLS[@]}"; do
				VOL_SRC=$(echo "$v" | cut -d':' -f1)
				VOL_DST=$(echo "$v" | cut -d':' -f2)
				mkdir -p "$VOL_SRC"
				VOL_ARGS="$VOL_ARGS -v $VOL_SRC:$VOL_DST"

				VOL_FILE="$BACKUP_DIR/${container}_$(basename $VOL_SRC).tar.gz"
				if [[ -f "$VOL_FILE" ]]; then
					echo "ボリュームデータの復元: $VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 删除已存在但未运行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW} コンテナ [$container] は存在しますが実行されていません。古いコンテナを削除します...${NC}"
				docker rm -f "$container"
			fi

			# 启动容器
			echo "復元コマンドの実行: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW} 通常コンテナのバックアップ情報が見つかりません${NC}"

		# 还原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE} /home/docker のファイルをリストアしています...${NC}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${GREEN} /home/docker のファイルのリストアが完了しました${NC}"
		else
			echo -e "${YELLOW} /home/docker のファイルのバックアップが見つかりませんでした、スキップします...${NC}"
		fi


	}


	# ----------------------------
	# 迁移
	# ----------------------------
	migrate_docker() {
		send_stats "Docker迁移"
		install jq
		read -e -p  "请输入要迁移的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED} バックアップディレクトリが存在しません${NC}"; return; }

		read -e -p  "目标服务器IP: " TARGET_IP
		read -e -p  "目标服务器SSH用户名: " TARGET_USER
		read -e -p "ターゲットサーバーSSHポート [デフォルト 22]: " TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW} バックアップを転送中...${NC}"
		if [[ -z "$TARGET_PASS" ]]; then
			# 使用密钥登录
			scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no -r "$LATEST_TAR" "$TARGET_USER@$TARGET_IP:/tmp/"
		fi

	}

	# ----------------------------
	# 删除备份
	# ----------------------------
	delete_backup() {
		send_stats "Docker备份文件删除"
		read -e -p  "请输入要删除的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED} バックアップディレクトリが存在しません${NC}"; return; }
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN} バックアップを削除しました: ${BACKUP_DIR}${NC}"
	}

	# ----------------------------
	# 主菜单
	# ----------------------------
	main_menu() {
		send_stats "Docker备份迁移还原"
		while true; do
			clear
			echo "------------------------"
			echo -e "Docker バックアップ/移行/復元ツール"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. Docker プロジェクトのバックアップ"
			echo -e "2. Docker プロジェクトの移行"
			echo -e "3. Docker プロジェクトの復元"
			echo -e "4. Docker プロジェクトのバックアップファイルを削除"
			echo "------------------------"
			echo -e "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p  "请选择: " choice
			case $choice in
				1) backup_docker ;;
				2) migrate_docker ;;
				3) restore_docker ;;
				4) delete_backup ;;
				0) return ;;
				*) echo -e "${RED}無効なオプション${NC}" ;;
			esac
		break_end
		done
	}

	main_menu
}





linux_docker() {

	while true; do
	  clear
	  # send_stats "docker管理"
	  echo -e "Docker 管理"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Docker 環境のインストールと更新 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Docker グローバル状態の確認 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Docker コンテナ管理 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker イメージ管理"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker ネットワーク管理"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker ボリューム管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}未使用の Docker コンテナ、イメージ、ネットワーク、ボリュームのクリーンアップ"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Docker リポジトリの変更"
	  echo -e "${gl_kjlan}9.   ${gl_bai}daemon.json ファイルの編集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Docker IPv6 アクセスの有効化"
	  echo -e "${gl_kjlan}12.  ${gl_bai}Docker IPv6 アクセスの無効化"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Docker 環境のバックアップ/移行/復元"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Docker 環境のアンインストール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "安装docker环境"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "docker全局状态"
			  echo "Docker バージョン"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Dockerイメージ: ${gl_lv}$image_count${gl_bai}"
			  docker image ls
			  echo ""
			  echo -e "Dockerコンテナ: ${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Dockerボリューム: ${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Dockerネットワーク: ${gl_lv}$network_count${gl_bai}"
			  docker network ls
			  echo ""

			  ;;
		  3)
			  docker_ps
			  ;;
		  4)
			  docker_image
			  ;;

		  5)
			  while true; do
				  clear
				  send_stats "Docker网络管理"
				  echo "Docker ネットワークリスト"
				  echo "------------------------------------------------------------"
				  docker network ls
				  echo ""

				  echo "------------------------------------------------------------"
				  container_ids=$(docker ps -q)
				  printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

				  for container_id in $container_ids; do
					  local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

					  local container_name=$(echo "$container_info" | awk '{print $1}')
					  local network_info=$(echo "$container_info" | cut -d' ' -f2-)

					  while IFS= read -r line; do
						  local network_name=$(echo "$line" | awk '{print $1}')
						  local ip_address=$(echo "$line" | awk '{print $2}')

						  printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
					  done <<< "$network_info"
				  done

				  echo ""
				  echo "ネットワーク操作"
				  echo "------------------------"
				  echo "1. ネットワークの作成"
				  echo "2. ネットワークへの参加"
				  echo "3. ネットワークからの退出"
				  echo "4. ネットワークの削除"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "创建网络"
						  read -e -p "新しいネットワーク名を設定: " dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "加入网络"
						  read -e -p "ネットワーク名を追加: " dockernetwork
						  read -e -p "そのコンテナをネットワークに追加します（複数のコンテナ名はスペースで区切ってください）: " dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "加入网络"
						  read -e -p "ネットワーク名から退出: " dockernetwork
						  read -e -p "そのコンテナをネットワークから退出させます（複数のコンテナ名はスペースで区切ってください）: " dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "删除网络"
						  read -e -p "削除するネットワーク名を入力してください: " dockernetwork
						  docker network rm $dockernetwork
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  6)
			  while true; do
				  clear
				  send_stats "Docker卷管理"
				  echo "Docker ボリュームリスト"
				  docker volume ls
				  echo ""
				  echo "ボリューム操作"
				  echo "------------------------"
				  echo "1. 新しいボリュームの作成"
				  echo "2. 指定したボリュームの削除"
				  echo "3. 全ボリュームの削除"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "新建卷"
						  read -e -p "新しいボリューム名を設定: " dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "削除するボリューム名を入力してください（複数のボリューム名はスペースで区切ってください）: " dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "删除所有卷"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}未使用ボリュームをすべて削除しますか？ \(y/N\): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "無効な選択です。Y または N を入力してください。"
							  ;;
						  esac
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;
		  7)
			  clear
			  send_stats "Docker清理"
			  read -e -p "$(echo -e "${gl_huang}ヒント: ${gl_bai}無効なイメージ、コンテナ、ネットワーク（停止中のコンテナを含む）をクリーンアップします。クリーンアップしますか？ \(y/N\): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "無効な選択です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "Docker源"
			  bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
			  ;;

		  9)
			  clear
			  install nano
			  mkdir -p /etc/docker && nano /etc/docker/daemon.json
			  restart docker
			  ;;




		  11)
			  clear
			  send_stats "Docker v6 开"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker v6 关"
			  docker_ipv6_off
			  ;;

		  19)
			  docker_ssh_migration
			  ;;


		  20)
			  clear
			  send_stats "Docker卸载"
			  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}Docker 環境をアンインストールしますか？ \(y/N\): ")" choice
			  case "$choice" in
				[Yy])
				  docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				  remove docker docker-compose docker-ce docker-ce-cli containerd.io
				  rm -f /etc/docker/daemon.json
				  hash -r
				  ;;
				[Nn])
				  ;;
				*)
				  echo "無効な選択です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "测试脚本合集"
	  echo -e "テストスクリプトコレクション"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IPロック解除ステータスチェック"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPTロック解除ステータスチェック"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Region ストリーミングロック解除テスト"
	  echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu ストリーミングロック解除チェック"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP品質ヘルスチェックスクリプト ${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "ネットワーク回線速度テスト"
	  echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 3つのネットワークバックグラウンド遅延ルーティングテスト"
	  echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace 3つのネットワークバックグラウンド回線テスト"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 3つのネットワーク速度テスト"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 高速バックグラウンドテストスクリプト"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace 指定IPバックグラウンドテストスクリプト"
	  echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 三ネットワーク回線テスト"
	  echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 多機能スピードテストスクリプト"
	  echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality ネットワーク品質健康診断スクリプト ${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "ハードウェアパフォーマンステスト"
	  echo -e "${gl_kjlan}21.  ${gl_bai}yabs パフォーマンス テスト"
	  echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU パフォーマンス テスト スクリプト"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "総合テスト"
	  echo -e "${gl_kjlan}31.  ${gl_bai}bench パフォーマンス テスト"
	  echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx 融合モンスター評価 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "ChatGPT解锁状态检测"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "Region流媒体解锁测试"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "yeahwu流媒体解锁检测"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_IP质量体检脚本"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "besttrace三网回程延迟路由测试"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "mtr_trace三网回程线路测试"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "Superspeed三网测速"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace快速回程测试脚本"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace指定IP回程测试脚本"
			  echo "参考IPリスト"
			  echo "------------------------"
			  echo "北京テレコム: 219.141.136.12"
			  echo "北京ユニコム: 202.106.50.1"
			  echo "北京移動: 221.179.155.161"
			  echo "上海電信: 202.96.209.133"
			  echo "上海聯通: 210.22.97.1"
			  echo "上海移動: 211.136.112.200"
			  echo "廣州電信: 58.60.188.222"
			  echo "廣州聯通: 210.21.196.6"
			  echo "廣州移動: 120.196.165.24"
			  echo "成都電信: 61.139.2.69"
			  echo "成都聯通: 119.6.6.6"
			  echo "成都移動: 211.137.96.205"
			  echo "湖南電信: 36.111.200.100"
			  echo "湖南聯通: 42.48.16.100"
			  echo "湖南移動: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "特定のIPアドレスを入力してください: " testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "ludashi2020三网线路测试"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc多功能测速脚本"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "网络质量测试脚本"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "yabs性能测试"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "icu/gb5 CPU性能测试脚本"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "bench性能测试"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "spiritysdx融合怪测评"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "甲骨文云脚本合集"
	  echo -e "甲骨文クラウドスクリプトコレクション"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}アイドルマシンのアクティブスクリプトのインストール"
	  echo -e "${gl_kjlan}2.   ${gl_bai}アイドルマシンのアクティブスクリプトのアンインストール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD システム再インストールスクリプト"
	  echo -e "${gl_kjlan}4.   ${gl_bai}R 探偵起動スクリプト"
	  echo -e "${gl_kjlan}5.   ${gl_bai}root パスワードログインモードを有効にする"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPv6 回復ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "アクティブスクリプト：CPU使用率 10-20% メモリ使用率 20%"
			  read -e -p "インストールしてもよろしいですか？ \(y/N\): " choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # 设置默认值
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				  read -e -p "CPUコア数を入力してください [デフォルト: $DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "CPU使用率の範囲を入力してください（例：10-20） [デフォルト: $DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "メモリ使用率を入力してください [デフォルト: $DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "Speedtestの間隔時間を入力してください（秒） [デフォルト: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # 运行Docker容器
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "甲骨文云安装活跃脚本"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "無効な選択です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "甲骨文云卸载活跃脚本"
			  ;;

		  3)
		  clear
		  echo "システムを再インストール"
		  echo "--------------------------------"
		  echo -e "${gl_hong}注意: ${gl_bai}再インストールには切断のリスクが伴います。不安な場合は慎重に使用してください。再インストールには約15分かかります。事前にデータをバックアップしてください。"
		  read -e -p "続行してもよろしいですか？ \(y/N\): " choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "再インストールするシステムを選択してください: 1. Debian 12 | 2. Ubuntu 20.04 : " sys_choice

				case "$sys_choice" in
				  1)
					local xitong="-d 12"
					break  # 结束循环
					;;
				  2)
					local xitong="-u 20.04"
					break  # 结束循环
					;;
				  *)
					echo "無効な選択です。再入力してください。"
					;;
				esac
			  done

			  read -e -p "再インストール後のパスワードを入力してください: " vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "甲骨文云重装系统脚本"
			  ;;
			[Nn])
			  echo "キャンセルしました"
			  ;;
			*)
			  echo "無効な選択です。Y または N を入力してください。"
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  send_stats "R探长开机脚本"
			  bash <(wget -qO- ${gh_proxy}github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh)
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "この機能はjhbの神によって提供されました。感謝します！"
			  send_stats "ipv6修复"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done



}


docker_tato() {

	local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
	local image_count=$(docker images -q 2>/dev/null | wc -l)
	local network_count=$(docker network ls -q 2>/dev/null | wc -l)
	local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

	if command -v docker &> /dev/null; then
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_lv}環境はインストール済み${gl_bai}  コンテナ: ${gl_lv}$container_count${gl_bai}  イメージ: ${gl_lv}$image_count${gl_bai}  ネットワーク: ${gl_lv}$network_count${gl_bai}  ボリューム: ${gl_lv}$volume_count${gl_bai}"
	fi
}



ldnmp_tato() {
local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
local output="${gl_lv}${cert_count}${gl_bai}"

local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
if [ -n "$dbrootpasswd" ]; then
	local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
fi

local db_output="${gl_lv}${db_count}${gl_bai}"


if command -v docker &>/dev/null; then
	if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_lv}環境はインストール済み${gl_bai}  サイト: $output  データベース: $db_output"
	fi
fi

}


fix_phpfpm_conf() {
	local container_name=$1
	docker exec "$container_name" sh -c "mkdir -p /run/$container_name && chmod 777 /run/$container_name"
	docker exec "$container_name" sh -c "sed -i '1i [global]\\ndaemonize = no' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "sed -i '/^listen =/d' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "echo -e '\nlisten = /run/$container_name/php-fpm.sock\nlisten.owner = www-data\nlisten.group = www-data\nlisten.mode = 0777' >> /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "rm -f /usr/local/etc/php-fpm.d/zz-docker.conf"

	find /home/web/conf.d/ -type f -name "*.conf" -exec sed -i "s#fastcgi_pass ${container_name}:9000;#fastcgi_pass unix:/run/${container_name}/php-fpm.sock;#g" {} \;

}






linux_ldnmp() {
  while true; do

	clear
	# send_stats "LDNMP建站"
	echo -e "${gl_huang}LDNMP サイト構築"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}LDNMP 環境のインストール ${gl_huang}★${gl_bai}                              ${gl_huang}2.   ${gl_bai}WordPress のインストール ${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}Discuzフォーラムのインストール                          ${gl_huang}4.   ${gl_bai}KODExplorerのインストール"
	echo -e "${gl_huang}5.   ${gl_bai}Apple CMS映画サイトのインストール                       ${gl_huang}6.   ${gl_bai}Unicornカード発行サイトのインストール"
	echo -e "${gl_huang}7.   ${gl_bai}Flarumフォーラムサイトのインストール                    ${gl_huang}8.   ${gl_bai}Typecho軽量ブログサイトのインストール"
	echo -e "${gl_huang}9.   ${gl_bai}LinkStack共有リンクプラットフォームのインストール       ${gl_huang}20.  ${gl_bai}カスタムダイナミックサイト"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}Nginxのみインストール ${gl_huang}★${gl_bai}                                 ${gl_huang}22.  ${gl_bai}サイトリダイレクト"
	echo -e "${gl_huang}23.  ${gl_bai}サイトリバースプロキシ-IP+ポート ${gl_huang}★${gl_bai}                      ${gl_huang}24.  ${gl_bai}サイトリバースプロキシ-ドメイン名"
	echo -e "${gl_huang}25.  ${gl_bai}Bitwardenパスワード管理プラットフォームのインストール   ${gl_huang}26.  ${gl_bai}Haloブログサイトのインストール"
	echo -e "${gl_huang}27.  ${gl_bai}AI描画プロンプトジェネレーターのインストール            ${gl_huang}28.  ${gl_bai}サイトリバースプロキシ-ロードバランシング"
	echo -e "${gl_huang}29.  ${gl_bai}Streamレイヤー4プロキシ転送                             ${gl_huang}30.  ${gl_bai}カスタム静的サイト"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}サイトデータ管理 ${gl_huang}★${gl_bai}                                      ${gl_huang}32.  ${gl_bai}全サイトデータのバックアップ"
	echo -e "${gl_huang}33.  ${gl_bai}定期リモートバックアップ                                ${gl_huang}34.  ${gl_bai}全サイトデータの復元"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}LDNMP環境の保護                                         ${gl_huang}36.  ${gl_bai}LDNMP環境の最適化"
	echo -e "${gl_huang}37.  ${gl_bai}LDNMP環境の更新                                         ${gl_huang}38.  ${gl_bai}LDNMP環境の削除"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}メインメニューに戻る"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "選択を入力してください: " sub_choice


	case $sub_choice in
	  1)
	  ldnmp_install_status_one
	  ldnmp_install_all
		;;
	  2)
	  ldnmp_wp
		;;

	  3)
	  clear
	  # Discuz论坛
	  webname="Discuz フォーラム"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20250901.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "データベース名: $dbname"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
	  echo "テーブルプレフィックス: discuz_"


		;;

	  4)
	  clear
	  # 可道云桌面
	  webname="Kanbox デスクトップ"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/kalcaddle/kodbox/archive/refs/tags/1.50.02.zip
	  unzip -o latest.zip
	  rm latest.zip
	  mv /home/web/html/$yuming/kodbox* /home/web/html/$yuming/kodbox
	  restart_ldnmp

	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
	  echo "データベース名: $dbname"
	  echo "Redis ホスト: redis"

		;;

	  5)
	  clear
	  # 苹果CMS
	  webname="Apple CMS"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  # wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
	  wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && mv maccms10-*/* . && rm -r maccms10-* && rm maccms10.zip
	  cd /home/web/html/$yuming/template/ && wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/template/DYXS2.zip
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/application/admin/controller
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/application/admin/view/system
	  mv /home/web/html/$yuming/admin.php /home/web/html/$yuming/vip.php && wget -O /home/web/html/$yuming/application/extra/maccms.php ${gh_proxy}raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php

	  restart_ldnmp


	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "データベースポート: 3306"
	  echo "データベース名: $dbname"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
	  echo "データベースプレフィックス: mac_"
	  echo "------------------------"
	  echo "インストール成功後にバックエンドにログインするアドレス"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 独脚数卡
	  webname="独脚数卡"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget ${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

	  restart_ldnmp


	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "データベースポート: 3306"
	  echo "データベース名: $dbname"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
	  echo ""
	  echo "Redis アドレス: redis"
	  echo "Redis パスワード: デフォルトでは何も入力しません"
	  echo "Redis ポート: 6379"
	  echo ""
	  echo "ウェブサイトURL: https://$yuming"
	  echo "バックエンドログインパス: /admin"
	  echo "------------------------"
	  echo "ユーザー名: admin"
	  echo "パスワード: admin"
	  echo "------------------------"
	  echo "ログイン時に右上隅に赤い error0 が表示された場合は、次のコマンドを使用してください:"
	  echo "ユニコーンカードがなぜそんなに面倒なのか、このような問題があるのか、私もとても腹が立っています！"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # flarum论坛
	  webname="Flarum フォーラム"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
	  docker exec php sh -c "php composer-setup.php"
	  docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
	  docker exec php sh -c "mv composer.phar /usr/local/bin/composer"

	  docker exec php composer create-project flarum/flarum /var/www/html/$yuming
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum/extension-manager:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/sitemap"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/oauth"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/best-answer:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"

	  restart_ldnmp


	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "データベース名: $dbname"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
	  echo "テーブルプレフィックス: flarum_"
	  echo "管理者情報はご自身で設定してください"

		;;

	  8)
	  clear
	  # typecho
	  webname="Typecho"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/typecho/typecho/releases/latest/download/typecho.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "データベースプレフィックス: typecho_"
	  echo "データベースアドレス: mysql"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
	  echo "データベース名: $dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf
	  sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" /home/web/conf.d/$yuming.conf
	  sed -i "s|yuming.com|$yuming|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "データベースポート: 3306"
	  echo "データベース名: $dbname"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP動的ウェブサイト"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  clear
	  echo -e "[${gl_huang}1/6${gl_bai}] PHPソースコードのアップロード"
	  echo "-------------"
	  echo "現在、zip形式のソースコードパッケージのみアップロードできます。ソースコードパッケージを /home/web/html/${yuming} ディレクトリに配置してください。"
	  read -e -p "ダウンロードリンクを入力することもできます。リモートでソースコードパッケージをダウンロードします。Enterキーを押すとリモートダウンロードはスキップされます: " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] index.phpのパス"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "index.phpのパスを入力してください（例：/home/web/html/$yuming/wordpress/）: " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] PHPバージョンの選択"
	  echo "-------------"
	  read -e -p "1. 最新版のphp | 2. php 7.4 : " pho_v
	  case "$pho_v" in
		1)
		  sed -i "s#php:9000#php:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php"
		  ;;
		2)
		  sed -i "s#php:9000#php74:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php74"
		  ;;
		*)
		  echo "無効な選択です。再入力してください。"
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] 指定された拡張機能のインストール"
	  echo "-------------"
	  echo "インストール済みの拡張機能"
	  docker exec php php -m

	  read -e -p "$(echo -e "インストールしたい拡張機能の名前を入力してください。例: ${gl_huang}SourceGuardian imap ftp${gl_bai} など。直接Enterを押すとスキップされます : ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] サイト設定の編集"
	  echo "-------------"
	  echo "任意のキーを押して続行してください。サイト設定（静的コンテンツなど）の詳細設定が可能です。"
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] データベース管理"
	  echo "-------------"
	  read -e -p "1. 新しいサイトを構築する 2. データベースバックアップのある古いサイトを構築する: " use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "データベースバックアップは .gz で終わる圧縮ファイルである必要があります。 /home ディレクトリに配置してください。宝塔 /1panel のバックアップデータインポートをサポートします。"
			  read -e -p "ダウンロードリンクを入力して、リモートからバックアップデータをダウンロードすることもできます。Enterキーを押すとリモートダウンロードはスキップされます:" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "データベースインポートテーブルデータ"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "データベースのインポートが完了しました"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "データベースアドレス: mysql"
	  echo "データベース名: $dbname"
	  echo "ユーザー名: $dbuse"
	  echo "パスワード: $dbusepasswd"
	  echo "テーブルプレフィックス: $prefix"
	  echo "管理者ログイン情報をご自身で設定してください"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="サイトのリダイレクト"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  read -e -p "リダイレクトドメインを入力してください:" reverseproxy
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on


		;;

	  23)
	  ldnmp_Proxy
	  find_container_by_host_port "$port"
	  if [ -z "$docker_name" ]; then
		close_port "$port"
		echo "IP+ポートがこのサービスへのアクセスをブロックしました"
	  else
	  	ip_address
		block_container_port "$docker_name" "$ipv4_address"
	  fi

		;;

	  24)
	  clear
	  webname="リバースプロキシ - ドメイン"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  echo -e "ドメイン形式: ${gl_huang}google.com${gl_bai}"
	  read -e -p "プロキシドメインを入力してください:" fandai_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|fandaicom|$fandai_yuming|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;


	  25)
	  clear
	  webname="Bitwarden"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  docker run -d \
		--name bitwarden \
		--restart=always \
		-p 3280:80 \
		-v /home/web/html/$yuming/bitwarden/data:/data \
		vaultwarden/server
	  duankou=3280
	  reverse_proxy

	  nginx_web_on

		;;

	  26)
	  clear
	  webname="Halo"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  docker run -d --name halo --restart=always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2
	  duankou=8010
	  reverse_proxy

	  nginx_web_on

		;;

	  27)
	  clear
	  webname="AI画像生成プロンプトジェネレーター"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/ai_prompt_generator.zip
	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;

	  28)
	  ldnmp_Proxy_backend
		;;


	  29)
	  stream_panel
		;;

	  30)
	  clear
	  webname="静的サイト"
	  send_stats "安装$webname"
	  echo "$webname のデプロイを開始"
	  add_yuming
	  repeat_add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming


	  clear
	  echo -e "[${gl_huang}1/2${gl_bai}] 静的ソースコードをアップロード"
	  echo "-------------"
	  echo "現在、zip形式のソースコードパッケージのみアップロードできます。ソースコードパッケージを /home/web/html/${yuming} ディレクトリに配置してください。"
	  read -e -p "ダウンロードリンクを入力することもできます。リモートでソースコードパッケージをダウンロードします。Enterキーを押すとリモートダウンロードはスキップされます: " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] index.html のパス"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "index.html のパスを入力してください（例： /home/web/html/$yuming/index/）:" index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;







	31)
	  ldnmp_web_status
	  ;;


	32)
	  clear
	  send_stats "LDNMP环境备份"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}$backup_filename をバックアップ中...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "バックアップファイルが作成されました: /home/$backup_filename"
		read -e -p "バックアップデータをリモートサーバーに送信しますか？ (y/N):" choice
		case "$choice" in
		  [Yy])
			read -e -p "リモートサーバーのIPを入力してください:" remote_ip
			read -e -p "ターゲットサーバーSSHポート [デフォルト 22]: " TARGET_PORT
			local TARGET_PORT=${TARGET_PORT:-22}
			if [ -z "$remote_ip" ]; then
			  echo "エラー: リモートサーバーのIPを入力してください。"
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "ファイルはリモートサーバーの/homeディレクトリに転送されました。"
			else
			  echo "転送するファイルが見つかりませんでした。"
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "無効な選択です。Y または N を入力してください。"
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "定时远程备份"
	  read -e -p "リモートサーバーのIPを入力してください:" useip
	  read -e -p "リモートサーバーのパスワードを入力してください:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. 週次バックアップ                 2. 日次バックアップ"
	  read -e -p "選択を入力してください: " dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "毎週のバックアップ曜日を選択してください (0-6、0は日曜日を表します):" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "毎日バックアップする時間を選択してください (時、0-23):" hour
			  (crontab -l ; echo "0 $hour * * * ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  *)
			  break  # 跳出
			  ;;
	  esac

	  install sshpass

	  ;;

	34)
	  root_use
	  send_stats "LDNMP环境还原"
	  echo "利用可能なサイトバックアップ"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # 如果用户没有输入文件名，使用最新的压缩包
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}$filename を展開中...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "圧縮ファイルが見つかりませんでした。"
	  fi

	  ;;

	35)
		web_security
		;;

	36)
		web_optimization
		;;


	37)
	  root_use
	  while true; do
		  clear
		  send_stats "更新LDNMP环境"
		  echo "LDNMP環境の更新"
		  echo "------------------------"
		  ldnmp_v
		  echo "新しいバージョンのコンポーネントが見つかりました"
		  echo "------------------------"
		  check_docker_image_update nginx
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}nginx $update_status${gl_bai}"
		  fi
		  check_docker_image_update php
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}php $update_status${gl_bai}"
		  fi
		  check_docker_image_update mysql
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}mysql $update_status${gl_bai}"
		  fi
		  check_docker_image_update redis
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}redis $update_status${gl_bai}"
		  fi
		  echo "------------------------"
		  echo
		  echo "1. Nginxの更新              2. MySQLの更新             3. PHPの更新              4. redisの更新"
		  echo "------------------------"
		  echo "5. 環境全体の更新"
		  echo "------------------------"
		  echo "0. 前のメニューに戻る"
		  echo "------------------------"
		  read -e -p "選択を入力してください: " sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "${ldnmp_pods} のバージョン番号を入力してください（例： 8.0 8.3 8.4 9.0）（Enterキーで最新版を取得）:" version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完了"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "${ldnmp_pods} のバージョン番号を入力してください（例： 7.4 8.0 8.1 8.2 8.3）（Enterキーで最新版を取得）:" version
			  local version=${version:-8.3}
			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/kjlion\///g" /home/web/docker-compose.yml > /dev/null 2>&1
			  sed -i "s/image: php:fpm-alpine/image: php:${version}-fpm-alpine/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  			  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker exec php chown -R www-data:www-data /var/www/html

			  run_command docker exec php sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories > /dev/null 2>&1

			  docker exec php apk update
			  curl -sL ${gh_proxy}github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions
			  docker exec php mkdir -p /usr/local/bin/
			  docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/
			  docker exec php chmod +x /usr/local/bin/install-php-extensions
			  docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis imagick soap


			  docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/max_input_vars.ini' > /dev/null 2>&1

			  fix_phpfpm_con $ldnmp_pods

			  docker restart $ldnmp_pods > /dev/null 2>&1
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完了"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  restart_redis
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完了"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}ヒント: ${gl_bai}長時間更新されていない環境のユーザーは、LDNMP 環境の更新に注意してください。データベースの更新に失敗するリスクがあります。LDNMP 環境を更新しますか？ \(y/N\): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "完整更新LDNMP环境"
					cd /home/web/
					docker compose down --rmi all

					check_port
					install_dependency
					install_docker
					install_certbot
					install_ldnmp
					;;
				  *)
					;;
				esac
				  ;;
			  *)
				  break
				  ;;
		  esac
		  break_end
	  done


	  ;;

	38)
		root_use
		send_stats "卸载LDNMP环境"
		read -e -p "$(echo -e "${gl_hong}強く推奨: ${gl_bai}すべてのウェブサイトデータをバックアップしてから、LDNMP 環境をアンインストールしてください。すべてのウェブサイトデータを削除しますか？ \(y/N\): ")" choice
		case "$choice" in
		  [Yy])
			cd /home/web/
			docker compose down --rmi all
			docker compose -f docker-compose.phpmyadmin.yml down > /dev/null 2>&1
			docker compose -f docker-compose.phpmyadmin.yml down --rmi all > /dev/null 2>&1
			rm -rf /home/web
			;;
		  [Nn])

			;;
		  *)
			echo "無効な選択です。Y または N を入力してください。"
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "無効な入力！"
	esac
	break_end

  done

}



linux_panel() {


local sub_choice="$1"


while true; do

	if [ -z "$sub_choice" ]; then
	  clear
	  echo -e "アプリケーションマーケット"
	  echo -e "${gl_kjlan}------------------------"

	  local app_numbers=$([ -f /home/docker/appno.txt ] && cat /home/docker/appno.txt || echo "")

	  # 用循环设置颜色
	  for i in {1..150}; do
		  if echo "$app_numbers" | grep -q "^$i$"; then
			  declare "color$i=${gl_lv}"
		  else
			  declare "color$i=${gl_bai}"
		  fi
	  done

	  echo -e "${gl_kjlan}1.   ${color1}宝塔パネル公式版                                     ${gl_kjlan}2.   ${color2}aaPanel 宝塔国際版"
	  echo -e "${gl_kjlan}3.   ${color3}1Panel 新世代管理パネル                              ${gl_kjlan}4.   ${color4}NginxProxyManager 可視化パネル"
	  echo -e "${gl_kjlan}5.   ${color5}OpenList マルチストレージファイルリストプログラム    ${gl_kjlan}6.   ${color6}Ubuntu リモートデスクトップウェブ版"
	  echo -e "${gl_kjlan}7.   ${color7}哪吒探針 VPS 監視パネル                              ${gl_kjlan}8.   ${color8}QB オフライン BT マグネットダウンロードパネル"
	  echo -e "${gl_kjlan}9.   ${color9}Poste.io メールサーバープログラム                    ${gl_kjlan}10.  ${color10}Rocket.Chat マルチプレイヤーオンラインチャットシステム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${color11}禅道プロジェクト管理ソフトウェア                     ${gl_kjlan}12.  ${color12}青龍パネル定時タスク管理プラットフォーム"
	  echo -e "${gl_kjlan}13.  ${color13}Cloudreve ウェブディスク ${gl_huang}★${gl_bai}                           ${gl_kjlan}14.  ${color14}シンプル画像アップローダー画像管理プログラム"
	  echo -e "${gl_kjlan}15.  ${color15}Emby マルチメディア管理システム                      ${gl_kjlan}16.  ${color16}Speedtest スピードテストパネル"
	  echo -e "${gl_kjlan}17.  ${color17}AdGuard Home 広告除去ソフトウェア                    ${gl_kjlan}18.  ${color18}ONLYOFFICE オンラインオフィス Office"
	  echo -e "${gl_kjlan}19.  ${color19}雷池 WAF ファイアウォールパネル                      ${gl_kjlan}20.  ${color20}Portainer コンテナ管理パネル"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${color21}VS Code ウェブ版                                     ${gl_kjlan}22.  ${color22}Uptime Kuma 監視ツール"
	  echo -e "${gl_kjlan}23.  ${color23}Memos ウェブメモ                                     ${gl_kjlan}24.  ${color24}Webtop リモートデスクトップウェブ版 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${color25}Nextcloudクラウドストレージ                          ${gl_kjlan}26.  ${color26}QD 定時タスク管理フレームワーク"
	  echo -e "${gl_kjlan}27.  ${color27}Dockge コンテナスタック管理パネル                    ${gl_kjlan}28.  ${color28}LibreSpeed スピードテストツール"
	  echo -e "${gl_kjlan}29.  ${color29}SearXNG アグリゲート検索エンジン ${gl_huang}★${gl_bai}                   ${gl_kjlan}30.  ${color30}PhotoPrism プライベートフォトアルバムシステム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${color31}Stirling PDF ツールスイート                          ${gl_kjlan}32.  ${color32}draw.io 無料オンライン図表作成ツール ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${color33}Sun-Panel ナビゲーションパネル                       ${gl_kjlan}34.  ${color34}Pingvin Share ファイル共有プラットフォーム"
	  echo -e "${gl_kjlan}35.  ${color35}ミニマルな朋友圈                                     ${gl_kjlan}36.  ${color36}LobeChat AI チャットアグリゲーションサイト"
	  echo -e "${gl_kjlan}37.  ${color37}MyIP ツールボックス ${gl_huang}★${gl_bai}                                ${gl_kjlan}38.  ${color38}小雅 Alist オールインワン"
	  echo -e "${gl_kjlan}39.  ${color39}Bililive ライブ録画ツール                            ${gl_kjlan}40.  ${color40}WebSSH ウェブ版 SSH 接続ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${color41}耗子管理パネル                                       ${gl_kjlan}42.  ${color42}Nexterm リモート接続ツール"
	  echo -e "${gl_kjlan}43.  ${color43}RustDesk リモートデスクトップ(サーバー) ${gl_huang}★${gl_bai}            ${gl_kjlan}44.  ${color44}RustDesk リモートデスクトップ(リレーサーバー) ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${color45}Docker アクセラレーションステーション                ${gl_kjlan}46.  ${color46}GitHub アクセラレーションステーション ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${color47}Prometheus モニタリング                              ${gl_kjlan}48.  ${color48}Prometheus(ホスト監視) "
	  echo -e "${gl_kjlan}49.  ${color49}Prometheus(コンテナ監視)                             ${gl_kjlan}50.  ${color50}補貨監視ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${color51}PVE 小雞パネル                                       ${gl_kjlan}52.  ${color52}DPanel コンテナ管理パネル"
	  echo -e "${gl_kjlan}53.  ${color53}Llama3 チャットAI大規模モデル                        ${gl_kjlan}54.  ${color54}AMH ホスト構築管理パネル"
	  echo -e "${gl_kjlan}55.  ${color55}FRP 内部ネットワーク貫通(サーバー) ${gl_huang}★${gl_bai}                 ${gl_kjlan}56.  ${color56}FRP 内部ネットワーク貫通(クライアント) ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${color57}DeepSeek チャットAI大規模モデル                      ${gl_kjlan}58.  ${color58}Dify 大規模モデル知識ベース ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${color59}NewAPI 大規模モデル資産管理                          ${gl_kjlan}60.  ${color60}JumpServer オープンソース踏み台サーバー"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${color61}オンライン翻訳サーバー                               ${gl_kjlan}62.  ${color62}RAGFlow 大規模モデル知識ベース"
	  echo -e "${gl_kjlan}63.  ${color63}Open WebUI セルフホスティングAIプラットフォーム ${gl_huang}★${gl_bai}    ${gl_kjlan}64.  ${color64}it-tools ツールボックス"
	  echo -e "${gl_kjlan}65.  ${color65}n8n 自動化ワークフロープラットフォーム ${gl_huang}★${gl_bai}             ${gl_kjlan}66.  ${color66}yt-dlp 動画ダウンローダー"
	  echo -e "${gl_kjlan}67.  ${color67}DDNS-GO 動的DNS管理ツール ${gl_huang}★${gl_bai}                          ${gl_kjlan}68.  ${color68}ALLinSSL 証明書管理プラットフォーム"
	  echo -e "${gl_kjlan}69.  ${color69}SFTPGo ファイル転送ツール                            ${gl_kjlan}70.  ${color70}AstrBot チャットボットフレームワーク"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}71.  ${color71}Navidrome プライベート音楽サーバー                   ${gl_kjlan}72.  ${color72}Bitwarden パスワードマネージャー ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${color73}LibreTV プライベート動画・TV                         ${gl_kjlan}74.  ${color74}MoonTV プライベート動画・TV"
	  echo -e "${gl_kjlan}75.  ${color75}Melody ミュージックウィザード                        ${gl_kjlan}76.  ${color76}オンラインDOSレトロゲーム"
	  echo -e "${gl_kjlan}77.  ${color77}迅雷オフラインダウンロードツール                     ${gl_kjlan}78.  ${color78}PandaWiki インテリジェントドキュメント管理システム"
	  echo -e "${gl_kjlan}79.  ${color79}Beszel サーバー監視                                  ${gl_kjlan}80.  ${color80}Linkwarden ブックマーク管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}81.  ${color81}Jitsi Meet ビデオ会議                                ${gl_kjlan}82.  ${color82}GPT-Load 高性能AI透過プロキシ"
	  echo -e "${gl_kjlan}83.  ${color83}Komari サーバー監視ツール                            ${gl_kjlan}84.  ${color84}Wallos 個人財務管理ツール"
	  echo -e "${gl_kjlan}85.  ${color85}Immich 画像・動画マネージャー                        ${gl_kjlan}86.  ${color86}Jellyfin メディア管理システム"
	  echo -e "${gl_kjlan}87.  ${color87}SyncTV 一緒に映画を見る神器                          ${gl_kjlan}88.  ${color88}Owncast セルフホスト型ライブストリーミングプラットフォーム"
	  echo -e "${gl_kjlan}89.  ${color89}FileCodeBox ファイルエクスプレス                     ${gl_kjlan}90.  ${color90}Matrix 分散型チャットプロトコル"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}91.  ${color91}Gitea プライベートコードリポジトリ                   ${gl_kjlan}92.  ${color92}FileBrowser ファイルマネージャー"
	  echo -e "${gl_kjlan}93.  ${color93}Dufs ミニマル静的ファイルサーバー                    ${gl_kjlan}94.  ${color94}Gopeed 高速ダウンロードツール"
	  echo -e "${gl_kjlan}95.  ${color95}Paperless ドキュメント管理プラットフォーム           ${gl_kjlan}96.  ${color96}2FAuth セルフホスト型二要素認証器"
	  echo -e "${gl_kjlan}97.  ${color97}WireGuard ネットワーク構築(サーバー)                 ${gl_kjlan}98.  ${color98}WireGuard ネットワーク構築(クライアント) "
	  echo -e "${gl_kjlan}99.  ${color99}DSM Synology仮想マシン                               ${gl_kjlan}100. ${color100}Syncthing P2Pファイル同期ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}101. ${color101}AI 動画生成ツール                                    ${gl_kjlan}102. ${color102}VoceChat マルチプレイヤーオンラインチャットシステム"
	  echo -e "${gl_kjlan}103. ${color103}Umami ウェブサイト統計ツール                         ${gl_kjlan}104. ${color104}Stream 4層プロキシ転送ツール"
	  echo -e "${gl_kjlan}105. ${color105}思源ノート                                           ${gl_kjlan}106. ${color106}Drawnix オープンソースホワイトボードツール"
	  echo -e "${gl_kjlan}107. ${color107}PanSou クラウドストレージ検索"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}b.   ${gl_bai}全アプリデータをバックアップ                         ${gl_kjlan}r.   ${gl_bai}全アプリデータを復元"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice
	fi

	case $sub_choice in
	  1|bt|baota)
		local app_id="1"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="宝塔面板"
		local panelurl="https://www.bt.cn/new/index.html"

		panel_app_install() {
			if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec
		}

		panel_app_manage() {
			bt
		}

		panel_app_uninstall() {
			curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
			chmod +x bt-uninstall.sh
			./bt-uninstall.sh
		}

		install_panel



		  ;;
	  2|aapanel)


		local app_id="2"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="aapanel"
		local panelurl="https://www.aapanel.com/new/index.html"

		panel_app_install() {
			URL=https://www.aapanel.com/script/install_7.0_en.sh && if [ -f /usr/bin/curl ];then curl -ksSO "$URL" ;else wget --no-check-certificate -O install_7.0_en.sh "$URL";fi;bash install_7.0_en.sh aapanel
		}

		panel_app_manage() {
			bt
		}

		panel_app_uninstall() {
			curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
			chmod +x bt-uninstall.sh
			./bt-uninstall.sh
		}

		install_panel

		  ;;
	  3|1p|1panel)

		local app_id="3"
		local lujing="command -v 1pctl"
		local panelname="1Panel"
		local panelurl="https://1panel.cn/"

		panel_app_install() {
			install bash
			bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"
		}

		panel_app_manage() {
			1pctl user-info
			1pctl update password
		}

		panel_app_uninstall() {
			1pctl uninstall
		}

		install_panel

		  ;;
	  4|npm)

		local app_id="4"
		local docker_name="npm"
		local docker_img="jc21/nginx-proxy-manager:latest"
		local docker_port=81

		docker_rum() {

			docker run -d \
			  --name=$docker_name \
			  -p ${docker_port}:81 \
			  -p 80:80 \
			  -p 443:443 \
			  -v /home/docker/npm/data:/data \
			  -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
			  --restart=always \
			  $docker_img


		}

		local docker_describe="Nginx リバースプロキシツールパネル。ドメイン名でのアクセスはサポートされていません。"
		local docker_url="公式サイト紹介: https://nginxproxymanager.com/"
		local docker_use="echo \"初期ユーザー名: admin@example.com\""
		local docker_passwd="echo \"初期パスワード: changeme\""
		local app_size="1"

		docker_app

		  ;;

	  5|openlist)

		local app_id="5"
		local docker_name="openlist"
		local docker_img="openlistteam/openlist:latest-aria2"
		local docker_port=5244

		docker_rum() {

			mkdir -p /home/docker/openlist
			chmod -R 777 /home/docker/openlist

			docker run -d \
				--restart=always \
				-v /home/docker/openlist:/opt/openlist/data \
				-p ${docker_port}:5244 \
				-e PUID=0 \
				-e PGID=0 \
				-e UMASK=022 \
				--name="openlist" \
				openlistteam/openlist:latest-aria2

		}


		local docker_describe="Gin と Solidjs で駆動される、複数のストレージ、Web ブラウジング、WebDAV をサポートするファイルリストプログラム。"
		local docker_url="公式サイト紹介: https://github.com/OpenListTeam/OpenList"
		local docker_use="docker exec -it openlist ./openlist admin random"
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  6|webtop-ubuntu)

		local app_id="6"
		local docker_name="webtop-ubuntu"
		local docker_img="lscr.io/linuxserver/webtop:ubuntu-kde"
		local docker_port=3006

		docker_rum() {

			read -e -p "ログインユーザー名を設定してください:" admin
			read -e -p "ログインパスワードを設定してください:" admin_password
			docker run -d \
			  --name=webtop-ubuntu \
			  --security-opt seccomp=unconfined \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -e TZ=Etc/UTC \
			  -e SUBFOLDER=/ \
			  -e TITLE=Webtop \
			  -e CUSTOM_USER=${admin} \
			  -e PASSWORD=${admin_password} \
			  -p ${docker_port}:3000 \
			  -v /home/docker/webtop/data:/config \
			  -v /var/run/docker.sock:/var/run/docker.sock \
			  --shm-size="1gb" \
			  --restart=always \
			  lscr.io/linuxserver/webtop:ubuntu-kde


		}


		local docker_describe="Webtop は Ubuntu ベースのコンテナです。IP アドレスでアクセスできない場合は、ドメイン名を追加してアクセスしてください。"
		local docker_url="公式サイト紹介: https://docs.linuxserver.io/images/docker-webtop/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app


		  ;;
	  7|nezha)
		clear
		send_stats "搭建哪吒"

		local app_id="7"
		local docker_name="nezha-dashboard"
		local docker_port=8008
		while true; do
			check_docker_app
			check_docker_image_update $docker_name
			clear
			echo -e "Ne Zha Monitoring $check_docker $update_status"
			echo "オープンソース、軽量、使いやすいサーバー監視・運用ツール"
			echo "公式ウェブサイト構築ドキュメント: https://nezha.wiki/guide/dashboard.html"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
				check_docker_app_ip
			fi
			echo ""
			echo "------------------------"
			echo "1. 使用"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "選択を入力してください: " choice

			case $choice in
				1)
					check_disk_space 1
					install unzip jq
					install_docker
					curl -sL ${gh_proxy}raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && ./nezha.sh
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
					;;

				*)
					break
					;;

			esac
			break_end
		done
		  ;;

	  8|qb|QB)

		local app_id="8"
		local docker_name="qbittorrent"
		local docker_img="lscr.io/linuxserver/qbittorrent:latest"
		local docker_port=8081

		docker_rum() {

			docker run -d \
			  --name=qbittorrent \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -e TZ=Etc/UTC \
			  -e WEBUI_PORT=${docker_port} \
			  -e TORRENTING_PORT=56881 \
			  -p ${docker_port}:${docker_port} \
			  -p 56881:56881 \
			  -p 56881:56881/udp \
			  -v /home/docker/qbittorrent/config:/config \
			  -v /home/docker/qbittorrent/downloads:/downloads \
			  --restart=always \
			  lscr.io/linuxserver/qbittorrent:latest

		}

		local docker_describe="qBittorrent オフラインBTマグネットダウンロードサービス"
		local docker_url="公式サイト紹介: https://hub.docker.com/r/linuxserver/qbittorrent"
		local docker_use="sleep 3"
		local docker_passwd="docker logs qbittorrent"
		local app_size="1"
		docker_app

		  ;;

	  9|mail)
		send_stats "搭建邮局"
		clear
		install telnet
		local app_id="9"
		local docker_name=“mailserver”
		while true; do
			check_docker_app
			check_docker_image_update $docker_name

			clear
			echo -e "郵便局サービス $check_docker $update_status"
			echo "Poste.ioはオープンソースのメールサーバーソリューションです。"
			echo "ビデオ紹介: https://youtu.be/KeqlzO9mPn0"

			echo ""
			echo "ポート検出"
			port=25
			timeout=3
			if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
			  echo -e "${gl_lv}ポート $port 現在利用可能${gl_bai}"
			else
			  echo -e "${gl_hong}ポート $port 現在利用不可${gl_bai}"
			fi
			echo ""

			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				yuming=$(cat /home/docker/mail.txt)
				echo "訪問アドレス:"
				echo "https://$yuming"
			fi

			echo "------------------------"
			echo "1. インストール                  2. 更新                  3. 削除"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "選択を入力してください: " choice

			case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "メールドメインを設定してください。例： mail.yuming.com:" yuming
					mkdir -p /home/docker
					echo "$yuming" > /home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "これらのDNSレコードを解決する"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo ""
					echo "------------------------"
					echo "続行するには任意のキーを押してください..."
					read -n 1 -s -r -p ""

					install jq
					install_docker

					docker run \
						--net=host \
						-e TZ=Europe/Prague \
						-v /home/docker/mail:/data \
						--name "mailserver" \
						-h "$yuming" \
						--restart=always \
						-d analogic/poste.io


					add_app_id

					clear
					echo "Poste.io のインストールが完了しました"
					echo "------------------------"
					echo "Poste.io には以下のURLからアクセスできます:"
					echo "https://$yuming"
					echo ""

					;;

				2)
					docker rm -f mailserver
					docker rmi -f analogic/poste.i
					yuming=$(cat /home/docker/mail.txt)
					docker run \
						--net=host \
						-e TZ=Europe/Prague \
						-v /home/docker/mail:/data \
						--name "mailserver" \
						-h "$yuming" \
						--restart=always \
						-d analogic/poste.i


					add_app_id

					clear
					echo "Poste.io のインストールが完了しました"
					echo "------------------------"
					echo "Poste.io には以下のURLからアクセスできます:"
					echo "https://$yuming"
					echo ""
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "アプリケーションが削除されました"
					;;

				*)
					break
					;;

			esac
			break_end
		done

		  ;;

	  10|rocketchat)

		local app_id="10"
		local app_name="Rocket.Chatチャットシステム"
		local app_text="Rocket.Chatは、リアルタイムチャット、音声/ビデオ通話、ファイル共有など、さまざまな機能をサポートするオープンソースのチームコミュニケーションプラットフォームです。"
		local app_url="公式紹介: https://www.rocket.chat/"
		local docker_name="rocketchat"
		local docker_port="3897"
		local app_size="2"

		docker_app_install() {
			docker run --name db -d --restart=always \
				-v /home/docker/mongo/dump:/dump \
				mongo:latest --replSet rs5 --oplogSize 256
			sleep 1
			docker exec -it db mongosh --eval "printjson(rs.initiate())"
			sleep 5
			docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

			clear
			ip_address
			echo "インストールが完了しました"
			check_docker_app_ip
		}

		docker_app_update() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat:latest
			docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
			clear
			ip_address
			echo "Rocket.Chat のインストールが完了しました"
			check_docker_app_ip
		}

		docker_app_uninstall() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat
			docker rm -f db
			docker rmi -f mongo:latest
			rm -rf /home/docker/mongo
			echo "アプリケーションが削除されました"
		}

		docker_app_plus
		  ;;



	  11|zentao)
		local app_id="11"
		local docker_name="zentao-server"
		local docker_img="idoop/zentao:latest"
		local docker_port=82


		docker_rum() {


			docker run -d -p ${docker_port}:80 \
			  -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
			  -e BIND_ADDRESS="false" \
			  -v /home/docker/zentao-server/:/opt/zbox/ \
			  --add-host smtp.exmail.qq.com:163.177.90.125 \
			  --name zentao-server \
			  --restart=always \
			  idoop/zentao:latest


		}

		local docker_describe="禅道は汎用的なプロジェクト管理ソフトウェアです"
		local docker_url="公式サイト紹介: https://www.zentao.net/"
		local docker_use="echo \"初期ユーザー名: admin\""
		local docker_passwd="echo \"初期パスワード: 123456\""
		local app_size="2"
		docker_app

		  ;;

	  12|qinglong)
		local app_id="12"
		local docker_name="qinglong"
		local docker_img="whyour/qinglong:latest"
		local docker_port=5700

		docker_rum() {


			docker run -d \
			  -v /home/docker/qinglong/data:/ql/data \
			  -p ${docker_port}:5700 \
			  --name qinglong \
			  --hostname qinglong \
			  --restart=always \
			  whyour/qinglong:latest


		}

		local docker_describe="Qinglong Panelは、定期的なタスク管理プラットフォームです"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/whyour/qinglong"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  13|cloudreve)

		local app_id="13"
		local app_name="Cloudreveネットワークドライブ"
		local app_text="Cloudreveは、複数のクラウドストレージをサポートするオンラインハードディスクシステムです"
		local app_url="動画紹介: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
		local docker_name="cloudreve"
		local docker_port="5212"
		local app_size="2"

		docker_app_install() {
			cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
			curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
			sed -i "s/5212:5212/${docker_port}:5212/g" /home/docker/cloud/docker-compose.yml
			cd /home/docker/cloud/
			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			cd /home/docker/cloud/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			rm -rf /home/docker/cloud
			echo "アプリケーションが削除されました"
		}

		docker_app_plus
		  ;;

	  14|easyimage)
		local app_id="14"
		local docker_name="easyimage"
		local docker_img="ddsderek/easyimage:latest"
		local docker_port=8014
		docker_rum() {

			docker run -d \
			  --name easyimage \
			  -p ${docker_port}:80 \
			  -e TZ=Asia/Shanghai \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -v /home/docker/easyimage/config:/app/web/config \
			  -v /home/docker/easyimage/i:/app/web/i \
			  --restart=always \
			  ddsderek/easyimage:latest

		}

		local docker_describe="Simple Image Bedは、シンプルな画像ホスティングプログラムです"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/icret/EasyImages2.0"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  15|emby)
		local app_id="15"
		local docker_name="emby"
		local docker_img="linuxserver/emby:latest"
		local docker_port=8015

		docker_rum() {

			docker run -d --name=emby --restart=always \
				-v /home/docker/emby/config:/config \
				-v /home/docker/emby/share1:/mnt/share1 \
				-v /home/docker/emby/share2:/mnt/share2 \
				-v /mnt/notify:/mnt/notify \
				-p ${docker_port}:8096 \
				-e UID=1000 -e GID=100 -e GIDLIST=100 \
				linuxserver/emby:latest

		}


		local docker_describe="Embyはクライアントデバイスにオーディオおよびビデオをストリーミングして、サーバー上のビデオおよびオーディオを整理するために使用できるクライアントサーバーアーキテクチャのメディアサーバーソフトウェアです"
		local docker_url="公式サイト紹介: https://emby.media/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  16|looking)
		local app_id="16"
		local docker_name="looking-glass"
		local docker_img="wikihostinc/looking-glass-server"
		local docker_port=8016


		docker_rum() {

			docker run -d --name looking-glass --restart=always -p ${docker_port}:80 wikihostinc/looking-glass-server

		}

		local docker_describe="Speedtest Speed Panelは、VPSのネットワーク速度テストツールであり、複数のテスト機能があり、VPSの送受信トラフィックをリアルタイムで監視することもできます"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/wikihost-opensource/als"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  17|adguardhome)

		local app_id="17"
		local docker_name="adguardhome"
		local docker_img="adguard/adguardhome"
		local docker_port=8017

		docker_rum() {

			docker run -d \
				--name adguardhome \
				-v /home/docker/adguardhome/work:/opt/adguardhome/work \
				-v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
				-p 53:53/tcp \
				-p 53:53/udp \
				-p ${docker_port}:3000/tcp \
				--restart=always \
				adguard/adguardhome


		}


		local docker_describe="AdGuard Homeは、ネットワーク全体に広告をブロックし、追跡を防ぐソフトウェアです。将来的には、DNSサーバー以上のものになります。"
		local docker_url="公式サイト紹介: https://hub.docker.com/r/adguard/adguardhome"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  18|onlyoffice)

		local app_id="18"
		local docker_name="onlyoffice"
		local docker_img="onlyoffice/documentserver"
		local docker_port=8018

		docker_rum() {

			docker run -d -p ${docker_port}:80 \
				--restart=always \
				--name onlyoffice \
				-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
				-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
				 onlyoffice/documentserver


		}

		local docker_describe="ONLYOFFICEはオープンソースのオンラインOfficeツールで、非常に強力です！"
		local docker_url="公式サイト紹介: https://www.onlyoffice.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app

		  ;;

	  19|safeline)
		send_stats "搭建雷池"

		local app_id="19"
		local docker_name=safeline-mgt
		local docker_port=9443
		while true; do
			check_docker_app
			clear
			echo -e "Rage Cage Service $check_docker"
			echo "雷池は、長亭科技が開発したWAFウェブサイトファイアウォールプログラムパネルであり、ウェブサイトをプロキシして自動防御を行うことができます。"
			echo "ビデオ紹介: https://youtu.be/_nkZXhnm68Y"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				check_docker_app_ip
			fi
			echo ""

			echo "------------------------"
			echo "1. インストール 2. 更新 3. パスワードリセット 4. 削除"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "選択を入力してください: " choice

			case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "雷池 WAF パネルのインストールが完了しました"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "雷池 WAF パネルの更新が完了しました"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "デフォルトのインストールディレクトリの場合、プロジェクトは削除されました。カスタムインストールディレクトリの場合、インストールディレクトリに移動して手動で実行する必要があります:"
					echo "docker compose down && docker compose down --rmi all"
					;;
				*)
					break
					;;

			esac
			break_end
		done

		  ;;

	  20|portainer)
		local app_id="20"
		local docker_name="portainer"
		local docker_img="portainer/portainer"
		local docker_port=8020

		docker_rum() {

			docker run -d \
				--name portainer \
				-p ${docker_port}:9000 \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-v /home/docker/portainer:/data \
				--restart=always \
				portainer/portainer

		}


		local docker_describe="Portainerは軽量なDockerコンテナ管理パネルです"
		local docker_url="公式サイト紹介: https://www.portainer.io/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  21|vscode)
		local app_id="21"
		local docker_name="vscode-web"
		local docker_img="codercom/code-server"
		local docker_port=8021


		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart=always codercom/code-server

		}


		local docker_describe="VS Codeは強力なオンラインコード作成ツールです"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/coder/code-server"
		local docker_use="sleep 3"
		local docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
		local app_size="1"
		docker_app
		  ;;


	  22|uptime-kuma)
		local app_id="22"
		local docker_name="uptime-kuma"
		local docker_img="louislam/uptime-kuma:latest"
		local docker_port=8022


		docker_rum() {

			docker run -d \
				--name=uptime-kuma \
				-p ${docker_port}:3001 \
				-v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
				--restart=always \
				louislam/uptime-kuma:latest

		}


		local docker_describe="Uptime Kumaは使いやすいセルフホスト監視ツールです"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/louislam/uptime-kuma"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  23|memos)
		local app_id="23"
		local docker_name="memos"
		local docker_img="ghcr.io/usememos/memos:latest"
		local docker_port=8023

		docker_rum() {

			docker run -d --name memos -p ${docker_port}:5230 -v /home/docker/memos:/var/opt/memos --restart=always ghcr.io/usememos/memos:latest

		}

		local docker_describe="Memosは軽量でセルフホスト可能なメモセンターです"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/usememos/memos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  24|webtop)
		local app_id="24"
		local docker_name="webtop"
		local docker_img="lscr.io/linuxserver/webtop:latest"
		local docker_port=8024

		docker_rum() {

			read -e -p "ログインユーザー名を設定してください:" admin
			read -e -p "ログインパスワードを設定してください:" admin_password
			docker run -d \
			  --name=webtop \
			  --security-opt seccomp=unconfined \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -e TZ=Etc/UTC \
			  -e SUBFOLDER=/ \
			  -e TITLE=Webtop \
			  -e CUSTOM_USER=${admin} \
			  -e PASSWORD=${admin_password} \
			  -e LC_ALL=zh_CN.UTF-8 \
			  -e DOCKER_MODS=linuxserver/mods:universal-package-install \
			  -e INSTALL_PACKAGES=font-noto-cjk \
			  -p ${docker_port}:3000 \
			  -v /home/docker/webtop/data:/config \
			  -v /var/run/docker.sock:/var/run/docker.sock \
			  --shm-size="1gb" \
			  --restart=always \
			  lscr.io/linuxserver/webtop:latest

		}


		local docker_describe="Webtop Alpineベースの中国語版コンテナです。IPでアクセスできない場合は、ドメイン名を追加してアクセスしてください。"
		local docker_url="公式サイト紹介: https://docs.linuxserver.io/images/docker-webtop/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app
		  ;;

	  25|nextcloud)
		local app_id="25"
		local docker_name="nextcloud"
		local docker_img="nextcloud:latest"
		local docker_port=8025
		local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

		docker_rum() {

			docker run -d --name nextcloud --restart=always -p ${docker_port}:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud

		}

		local docker_describe="Nextcloudは400,000以上のデプロイメントを持つ、ダウンロード可能な最も人気のあるオンプレミスのコンテンツコラボレーションプラットフォームです"
		local docker_url="公式サイト紹介: https://nextcloud.com/"
		local docker_use="echo \"アカウント: nextcloud  パスワード: $rootpasswd\""
		local docker_passwd=""
		local app_size="3"
		docker_app
		  ;;

	  26|qd)
		local app_id="26"
		local docker_name="qd"
		local docker_img="qdtoday/qd:latest"
		local docker_port=8026

		docker_rum() {

			docker run -d --name qd -p ${docker_port}:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd

		}

		local docker_describe="QDはHTTPリクエストの定期的なタスク自動実行フレームワークです"
		local docker_url="公式サイト紹介：https://qd-today.github.io/qd/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  27|dockge)
		local app_id="27"
		local docker_name="dockge"
		local docker_img="louislam/dockge:latest"
		local docker_port=8027

		docker_rum() {

			docker run -d --name dockge --restart=always -p ${docker_port}:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v  /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge

		}

		local docker_describe="Dockgeは、視覚的なDocker Composeコンテナ管理パネルです"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/louislam/dockge"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  28|speedtest)
		local app_id="28"
		local docker_name="speedtest"
		local docker_img="ghcr.io/librespeed/speedtest"
		local docker_port=8028

		docker_rum() {

			docker run -d -p ${docker_port}:8080 --name speedtest --restart=always ghcr.io/librespeed/speedtest

		}

		local docker_describe="LibreSpeedはJavaScriptで実装された軽量な速度テストツールで、すぐに使用できます"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/librespeed/speedtest"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  29|searxng)
		local app_id="29"
		local docker_name="searxng"
		local docker_img="searxng/searxng"
		local docker_port=8029

		docker_rum() {

			docker run -d \
			  --name searxng \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -v "/home/docker/searxng:/etc/searxng" \
			  searxng/searxng

		}

		local docker_describe="SearXNGは、プライベートでプライベートな検索エンジンサイトです"
		local docker_url="公式サイト紹介: https://hub.docker.com/r/alandoyle/searxng"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  30|photoprism)
		local app_id="30"
		local docker_name="photoprism"
		local docker_img="photoprism/photoprism:latest"
		local docker_port=8030
		local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

		docker_rum() {

			docker run -d \
				--name photoprism \
				--restart=always \
				--security-opt seccomp=unconfined \
				--security-opt apparmor=unconfined \
				-p ${docker_port}:2342 \
				-e PHOTOPRISM_UPLOAD_NSFW="true" \
				-e PHOTOPRISM_ADMIN_PASSWORD="$rootpasswd" \
				-v /home/docker/photoprism/storage:/photoprism/storage \
				-v /home/docker/photoprism/Pictures:/photoprism/originals \
				photoprism/photoprism

		}


		local docker_describe="PhotoPrismは非常に強力なプライベートフォトアルバムシステムです"
		local docker_url="公式サイト紹介: https://www.photoprism.app/"
		local docker_use="echo \"アカウント: admin  パスワード: $rootpasswd\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  31|s-pdf)
		local app_id="31"
		local docker_name="s-pdf"
		local docker_img="frooodle/s-pdf:latest"
		local docker_port=8031

		docker_rum() {

			docker run -d \
				--name s-pdf \
				--restart=always \
				 -p ${docker_port}:8080 \
				 -v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
				 -v /home/docker/s-pdf/extraConfigs:/configs \
				 -v /home/docker/s-pdf/logs:/logs \
				 -e DOCKER_ENABLE_SECURITY=false \
				 frooodle/s-pdf:latest
		}

		local docker_describe="これは、Dockerを使用した強力なオンプレミスでWebベースのPDF操作ツールであり、PDFファイルを分割および結合、変換、再編成、画像の追加、回転、圧縮などのさまざまな操作を実行できます。"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  32|drawio)
		local app_id="32"
		local docker_name="drawio"
		local docker_img="jgraph/drawio"
		local docker_port=8032

		docker_rum() {

			docker run -d --restart=always --name drawio -p ${docker_port}:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio

		}


		local docker_describe="これは強力なグラフ描画ソフトウェアです。マインドマップ、トポロジー図、フローチャートなどを描画できます。"
		local docker_url="公式サイト紹介: https://www.drawio.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  33|sun-panel)
		local app_id="33"
		local docker_name="sun-panel"
		local docker_img="hslr/sun-panel"
		local docker_port=8033

		docker_rum() {

			docker run -d --restart=always -p ${docker_port}:3002 \
				-v /home/docker/sun-panel/conf:/app/conf \
				-v /home/docker/sun-panel/uploads:/app/uploads \
				-v /home/docker/sun-panel/database:/app/database \
				--name sun-panel \
				hslr/sun-panel

		}

		local docker_describe="Sun-Panel サーバー、NAS ナビゲーションパネル、ホームページ、ブラウザのホームページ"
		local docker_url="公式サイト紹介：https://doc.sun-panel.top/"
		local docker_use="echo \"アカウント: admin@sun.cc  パスワード: 12345678\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  34|pingvin-share)
		local app_id="34"
		local docker_name="pingvin-share"
		local docker_img="stonith404/pingvin-share"
		local docker_port=8034

		docker_rum() {

			docker run -d \
				--name pingvin-share \
				--restart=always \
				-p ${docker_port}:3000 \
				-v /home/docker/pingvin-share/data:/opt/app/backend/data \
				stonith404/pingvin-share
		}

		local docker_describe="Pingvin Share は、WeTransfer の代替となる、セルフホスト可能なファイル共有プラットフォームです。"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/stonith404/pingvin-share"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  35|moments)
		local app_id="35"
		local docker_name="moments"
		local docker_img="kingwrcy/moments:latest"
		local docker_port=8035

		docker_rum() {

			docker run -d --restart=always \
				-p ${docker_port}:3000 \
				-v /home/docker/moments/data:/app/data \
				-v /etc/localtime:/etc/localtime:ro \
				-v /etc/timezone:/etc/timezone:ro \
				--name moments \
				kingwrcy/moments:latest
		}


		local docker_describe="ミニマリストな朋友圈、WeChat 朋友圈の模倣、あなたの素晴らしい人生を記録します"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
		local docker_use="echo \"アカウント: admin  パスワード: a123456\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;



	  36|lobe-chat)
		local app_id="36"
		local docker_name="lobe-chat"
		local docker_img="lobehub/lobe-chat:latest"
		local docker_port=8036

		docker_rum() {

			docker run -d -p ${docker_port}:3210 \
				--name lobe-chat \
				--restart=always \
				lobehub/lobe-chat
		}

		local docker_describe="LobeChat は、ChatGPT/Claude/Gemini/Groq/Ollama を含む、市場の主要な AI 大規模モデルを統合します。"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/lobehub/lobe-chat"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app
		  ;;

	  37|myip)
		local app_id="37"
		local docker_name="myip"
		local docker_img="jason5ng32/myip:latest"
		local docker_port=8037

		docker_rum() {

			docker run -d -p ${docker_port}:18966 --name myip jason5ng32/myip:latest

		}


		local docker_describe="多機能 IP ツールボックスで、自身の IP 情報と接続性を確認でき、Web パネルで表示されます。"
		local docker_url="公式 Web サイトの紹介: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README.md"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  38|xiaoya)
		send_stats "小雅全家桶"
		clear
		install_docker
		check_disk_space 1
		bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
		  ;;

	  39|bililive)

		if [ ! -d /home/docker/bililive-go/ ]; then
			mkdir -p /home/docker/bililive-go/ > /dev/null 2>&1
			wget -O /home/docker/bililive-go/config.yml ${gh_proxy}raw.githubusercontent.com/hr3lxphr6j/bililive-go/master/config.yml > /dev/null 2>&1
		fi

		local app_id="39"
		local docker_name="bililive-go"
		local docker_img="chigusa/bililive-go"
		local docker_port=8039

		docker_rum() {

			docker run --restart=always --name bililive-go -v /home/docker/bililive-go/config.yml:/etc/bililive-go/config.yml -v /home/docker/bililive-go/Videos:/srv/bililive -p ${docker_port}:8080 -d chigusa/bililive-go

		}

		local docker_describe="Bililive は、複数のライブストリーミングプラットフォームをサポートするライブストリーミング録画ツールです。"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  40|webssh)
		local app_id="40"
		local docker_name="webssh"
		local docker_img="jrohy/webssh"
		local docker_port=8040
		docker_rum() {
			docker run -d -p ${docker_port}:5032 --restart=always --name webssh -e TZ=Asia/Shanghai jrohy/webssh
		}

		local docker_describe="シンプルなオンライン SSH 接続ツールと SFTP ツール"
		local docker_url="公式サイト紹介: ${gh_proxy}github.com/Jrohy/webssh"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  41|haozi)

		local app_id="41"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="耗子面板"
		local panelurl="官方地址: ${gh_proxy}github.com/TheTNB/panel"

		panel_app_install() {
			mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o install.sh https://dl.cdn.haozi.net/panel/install.sh && bash install.sh
			cd ~
		}

		panel_app_manage() {
			panel-cli
		}

		panel_app_uninstall() {
			mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o uninstall.sh https://dl.cdn.haozi.net/panel/uninstall.sh && bash uninstall.sh
			cd ~
		}

		install_panel

		  ;;


	  42|nexterm)
		local app_id="42"
		local docker_name="nexterm"
		local docker_img="germannewsmaker/nexterm:latest"
		local docker_port=8042

		docker_rum() {

			ENCRYPTION_KEY=$(openssl rand -hex 32)
			docker run -d \
			  --name nexterm \
			  -e ENCRYPTION_KEY=${ENCRYPTION_KEY} \
			  -p ${docker_port}:6989 \
			  -v /home/docker/nexterm:/app/data \
			  --restart=always \
			  germannewsmaker/nexterm:latest

		}

		local docker_describe="Nexterm は、強力なオンライン SSH/VNC/RDP 接続ツールです。"
		local docker_url="官網介紹: ${gh_proxy}github.com/gnmyt/Nexterm"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  43|hbbs)
		local app_id="43"
		local docker_name="hbbs"
		local docker_img="rustdesk/rustdesk-server"
		local docker_port=0000

		docker_rum() {

			docker run --name hbbs -v /home/docker/hbbs/data:/root -td --net=host --restart=always rustdesk/rustdesk-server hbbs

		}


		local docker_describe="RustDesk オープンソースのリモートデスクトップ (サーバー側)、独自の向日葵サーバーのようなものです。"
		local docker_url="公式サイト紹介：https://rustdesk.com/"
		local docker_use="docker logs hbbs"
		local docker_passwd="echo \"IP とキーを記録してください。リモートデスクトップクライアントで使用します。44 番目のオプションでリレーエンドをインストールしてください！\""
		local app_size="1"
		docker_app
		  ;;

	  44|hbbr)
		local app_id="44"
		local docker_name="hbbr"
		local docker_img="rustdesk/rustdesk-server"
		local docker_port=0000

		docker_rum() {

			docker run --name hbbr -v /home/docker/hbbr/data:/root -td --net=host --restart=always rustdesk/rustdesk-server hbbr

		}

		local docker_describe="RustDesk オープンソースのリモートデスクトップ (リレー側)、独自の向日葵サーバーのようなものです。"
		local docker_url="公式サイト紹介：https://rustdesk.com/"
		local docker_use="echo \"公式 Web サイトにアクセスして、リモート デスクトップ クライアントをダウンロードします: https://rustdesk.com/\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  45|registry)
		local app_id="45"
		local docker_name="registry"
		local docker_img="registry:2"
		local docker_port=8045

		docker_rum() {

			docker run -d \
				-p ${docker_port}:5000 \
				--name registry \
				-v /home/docker/registry:/var/lib/registry \
				-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
				--restart=always \
				registry:2

		}

		local docker_describe="Docker Registry は、Docker イメージを保存および配布するためのサービスです。"
		local docker_url="官網介紹: https://hub.docker.com/_/registry"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app
		  ;;

	  46|ghproxy)
		local app_id="46"
		local docker_name="ghproxy"
		local docker_img="wjqserver/ghproxy:latest"
		local docker_port=8046

		docker_rum() {

			docker run -d --name ghproxy --restart=always -p ${docker_port}:8080 -v /home/docker/ghproxy/config:/data/ghproxy/config wjqserver/ghproxy:latest

		}

		local docker_describe="Go で実装された GHProxy は、一部の地域の Github リポジトリのプルを高速化するために使用されます。"
		local docker_url="官網介紹: https://github.com/WJQSERVER-STUDIO/ghproxy"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  47|prometheus|grafana)

		local app_id="47"
		local app_name="Prometheus監視"
		local app_text="Prometheus+Grafanaエンタープライズ級監視システム"
		local app_url="公式サイト紹介: https://prometheus.io"
		local docker_name="grafana"
		local docker_port="8047"
		local app_size="2"

		docker_app_install() {
			prometheus_install
			clear
			ip_address
			echo "インストールが完了しました"
			check_docker_app_ip
			echo "初期ユーザー名とパスワードは両方とも: admin"
		}

		docker_app_update() {
			docker rm -f node-exporter prometheus grafana
			docker rmi -f prom/node-exporter
			docker rmi -f prom/prometheus:latest
			docker rmi -f grafana/grafana:latest
			docker_app_install
		}

		docker_app_uninstall() {
			docker rm -f node-exporter prometheus grafana
			docker rmi -f prom/node-exporter
			docker rmi -f prom/prometheus:latest
			docker rmi -f grafana/grafana:latest

			rm -rf /home/docker/monitoring
			echo "アプリケーションが削除されました"
		}

		docker_app_plus
		  ;;

	  48|node-exporter)
		local app_id="48"
		local docker_name="node-exporter"
		local docker_img="prom/node-exporter"
		local docker_port=8048

		docker_rum() {

			docker run -d \
				--name=node-exporter \
				-p ${docker_port}:9100 \
				--restart=always \
				prom/node-exporter


		}

		local docker_describe="これは Prometheus のホストデータ収集コンポーネントで、監視対象のホストにデプロイしてください。"
		local docker_url="官網介紹: https://github.com/prometheus/node_exporter"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  49|cadvisor)
		local app_id="49"
		local docker_name="cadvisor"
		local docker_img="gcr.io/cadvisor/cadvisor:latest"
		local docker_port=8049

		docker_rum() {

			docker run -d \
				--name=cadvisor \
				--restart=always \
				-p ${docker_port}:8080 \
				--volume=/:/rootfs:ro \
				--volume=/var/run:/var/run:rw \
				--volume=/sys:/sys:ro \
				--volume=/var/lib/docker/:/var/lib/docker:ro \
				gcr.io/cadvisor/cadvisor:latest \
				-housekeeping_interval=10s \
				-docker_only=true

		}

		local docker_describe="これは Prometheus のコンテナデータ収集コンポーネントで、監視対象のホストにデプロイしてください。"
		local docker_url="官網介紹: https://github.com/google/cadvisor"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  50|changedetection)
		local app_id="50"
		local docker_name="changedetection"
		local docker_img="dgtlmoon/changedetection.io:latest"
		local docker_port=8050

		docker_rum() {

			docker run -d --restart=always -p ${docker_port}:5000 \
				-v /home/docker/datastore:/datastore \
				--name changedetection dgtlmoon/changedetection.io:latest

		}

		local docker_describe="これは、Web サイトの変更検出、在庫監視、通知を行うための小さなツールです。"
		local docker_url="官網介紹: https://github.com/dgtlmoon/changedetection.io"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  51|pve)
		clear
		send_stats "PVE开小鸡"
		check_disk_space 1
		curl -L ${gh_proxy}raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
		  ;;


	  52|dpanel)
		local app_id="52"
		local docker_name="dpanel"
		local docker_img="dpanel/dpanel:lite"
		local docker_port=8052

		docker_rum() {

			docker run -it -d --name dpanel --restart=always \
				-p ${docker_port}:8080 -e APP_NAME=dpanel \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-v /home/docker/dpanel:/dpanel \
				dpanel/dpanel:lite

		}

		local docker_describe="Docker 可視化パネルシステムで、完全な Docker 管理機能を提供します。"
		local docker_url="官網介紹: https://github.com/donknap/dpanel"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  53|llama3)
		local app_id="53"
		local docker_name="ollama"
		local docker_img="ghcr.io/open-webui/open-webui:ollama"
		local docker_port=8053

		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart=always ghcr.io/open-webui/open-webui:ollama

		}

		local docker_describe="Open WebUI は、新しい Llama3 大規模言語モデルに接続する大規模言語モデルの Web フレームワークです。"
		local docker_url="官網介紹: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run llama3.2:1b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;

	  54|amh)

		local app_id="54"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="AMH面板"
		local panelurl="官方地址: https://amh.sh/index.htm?amh"

		panel_app_install() {
			cd ~
			wget https://dl.amh.sh/amh.sh && bash amh.sh
		}

		panel_app_manage() {
			panel_app_install
		}

		panel_app_uninstall() {
			panel_app_install
		}

		install_panel
		  ;;


	  55|frps)
		frps_panel
		  ;;

	  56|frpc)
		frpc_panel
		  ;;

	  57|deepseek)
		local app_id="57"
		local docker_name="ollama"
		local docker_img="ghcr.io/open-webui/open-webui:ollama"
		local docker_port=8053

		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart=always ghcr.io/open-webui/open-webui:ollama

		}

		local docker_describe="Open WebUI は、新しい DeepSeek R1 大規模言語モデルに接続する大規模言語モデルの Web フレームワークです。"
		local docker_url="官網介紹: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;


	  58|dify)
		local app_id="58"
		local app_name="Difyナレッジベース"
		local app_text="オープンソースの大規模言語モデル（LLM）アプリケーション開発プラットフォームです。AI生成のための自己ホスティングトレーニングデータを使用します"
		local app_url="公式サイト：https://docs.dify.ai/"
		local docker_name="docker-nginx-1"
		local docker_port="8058"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/langgenius/dify.git && cd dify/docker && cp .env.example .env
			# sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
			sed -i "s/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/" /home/docker/dify/docker/.env

			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/dify/docker/ && docker compose down --rmi all
			cd  /home/docker/dify/
			git pull origin main
			sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=8058/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
			cd  /home/docker/dify/docker/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/dify/docker/ && docker compose down --rmi all
			rm -rf /home/docker/dify
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;

	  59|new-api)
		local app_id="59"
		local app_name="NewAPI"
		local app_text="次世代大規模モデルゲートウェイとAIアセット管理システム"
		local app_url="公式サイト: https://github.com/Calcium-Ion/new-api"
		local docker_name="new-api"
		local docker_port="8059"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/Calcium-Ion/new-api.git && cd new-api

			sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
				   -e 's/container_name: redis/container_name: redis-new-api/g' \
				   -e 's/container_name: mysql/container_name: mysql-new-api/g' \
				   docker-compose.yml


			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			cd  /home/docker/new-api/
			git pull origin main
			sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
				   -e 's/container_name: redis/container_name: redis-new-api/g' \
				   -e 's/container_name: mysql/container_name: mysql-new-api/g' \
				   docker-compose.yml

			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip

		}

		docker_app_uninstall() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			rm -rf /home/docker/new-api
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;


	  60|jms)

		local app_id="60"
		local app_name="JumpServerオープンソース踏み台サーバー"
		local app_text="オープンソースの特権アクセス管理（PAM）ツールであり、このプログラムはポート80を占有し、ドメイン名によるアクセス追加をサポートしていません。"
		local app_url="公式紹介: https://github.com/jumpserver/jumpserver"
		local docker_name="jms_web"
		local docker_port="80"
		local app_size="2"

		docker_app_install() {
			curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
			echo "初期ユーザー名: admin"
			echo "初期パスワード: ChangeMe"
		}


		docker_app_update() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh upgrade
			echo "アプリケーションが更新されました"
		}


		docker_app_uninstall() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh uninstall
			cd /opt
			rm -rf jumpserver-installer*/
			rm -rf jumpserver
			echo "アプリケーションが削除されました"
		}

		docker_app_plus
		  ;;

	  61|libretranslate)
		local app_id="61"
		local docker_name="libretranslate"
		local docker_img="libretranslate/libretranslate:latest"
		local docker_port=8061

		docker_rum() {

			docker run -d \
				-p ${docker_port}:5000 \
				--name libretranslate \
				libretranslate/libretranslate \
				--load-only ko,zt,zh,en,ja,pt,es,fr,de,ru

		}

		local docker_describe="無料のオープンソース機械翻訳 API、完全にセルフホスト可能、翻訳エンジンはオープンソースの Argos Translate ライブラリによってサポートされています。"
		local docker_url="官網介紹: https://github.com/LibreTranslate/LibreTranslate"
		local docker_use=""
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;



	  62|ragflow)
		local app_id="62"
		local app_name="RAGFlowナレッジベース"
		local app_text="深層文書理解に基づくオープンソースRAG（Retrieval Augmented Generation）エンジン"
		local app_url="公式サイト: https://github.com/infiniflow/ragflow"
		local docker_name="ragflow-server"
		local docker_port="8062"
		local app_size="8"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/infiniflow/ragflow.git && cd ragflow/docker
			sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
			cd  /home/docker/ragflow/
			git pull origin main
			cd  /home/docker/ragflow/docker/
			sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
			docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
			rm -rf /home/docker/ragflow
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;


	  63|open-webui)
		local app_id="63"
		local docker_name="open-webui"
		local docker_img="ghcr.io/open-webui/open-webui:main"
		local docker_port=8063

		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/open-webui:/app/backend/data --name open-webui --restart=always ghcr.io/open-webui/open-webui:main

		}

		local docker_describe="Open WebUI 大規模言語モデルのWebUIフレームワーク、公式軽量版、主要モデルAPI接続をサポート"
		local docker_url="官網介紹: https://github.com/open-webui/open-webui"
		local docker_use=""
		local docker_passwd=""
		local app_size="3"
		docker_app
		  ;;

	  64|it-tools)
		local app_id="64"
		local docker_name="it-tools"
		local docker_img="corentinth/it-tools:latest"
		local docker_port=8064

		docker_rum() {
			docker run -d --name it-tools --restart=always -p ${docker_port}:80 corentinth/it-tools:latest
		}

		local docker_describe="開発者やIT担当者にとって非常に役立つツール"
		local docker_url="官網介紹: https://github.com/CorentinTh/it-tools"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  65|n8n)
		local app_id="65"
		local docker_name="n8n"
		local docker_img="docker.n8n.io/n8nio/n8n"
		local docker_port=8065

		docker_rum() {

			add_yuming
			mkdir -p /home/docker/n8n
			chmod -R 777 /home/docker/n8n

			docker run -d --name n8n \
			  --restart=always \
			  -p ${docker_port}:5678 \
			  -v /home/docker/n8n:/home/node/.n8n \
			  -e N8N_HOST=${yuming} \
			  -e N8N_PORT=5678 \
			  -e N8N_PROTOCOL=https \
			  -e WEBHOOK_URL=https://${yuming}/ \
			  docker.n8n.io/n8nio/n8n

			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"

		}

		local docker_describe="強力な自動化ワークフロープラットフォーム"
		local docker_url="官網介紹: https://github.com/n8n-io/n8n"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  66|yt)
		yt_menu_pro
		  ;;


	  67|ddns)
		local app_id="67"
		local docker_name="ddns-go"
		local docker_img="jeessy/ddns-go"
		local docker_port=8067

		docker_rum() {
			docker run -d \
				--name ddns-go \
				--restart=always \
				-p ${docker_port}:9876 \
				-v /home/docker/ddns-go:/root \
				jeessy/ddns-go

		}

		local docker_describe="パブリックIP（IPv4/IPv6）を主要DNSプロバイダーにリアルタイムで自動更新し、動的DNSを実現します。"
		local docker_url="官網介紹: https://github.com/jeessy2/ddns-go"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  68|allinssl)
		local app_id="68"
		local docker_name="allinssl"
		local docker_img="allinssl/allinssl:latest"
		local docker_port=8068

		docker_rum() {
			docker run -itd --name allinssl -p ${docker_port}:8888 -v /home/docker/allinssl/data:/www/allinssl/data -e ALLINSSL_USER=allinssl -e ALLINSSL_PWD=allinssldocker -e ALLINSSL_URL=allinssl allinssl/allinssl:latest
		}

		local docker_describe="オープンソースで無料のSSL証明書自動管理プラットフォーム"
		local docker_url="官網介紹: https://allinssl.com"
		local docker_use="echo \"セキュアな入り口: /allinssl\""
		local docker_passwd="echo \"ユーザー名: allinssl  パスワード: allinssldocker\""
		local app_size="1"
		docker_app
		  ;;


	  69|sftpgo)
		local app_id="69"
		local docker_name="sftpgo"
		local docker_img="drakkan/sftpgo:latest"
		local docker_port=8069

		docker_rum() {

			mkdir -p /home/docker/sftpgo/data
			mkdir -p /home/docker/sftpgo/config
			chown -R 1000:1000 /home/docker/sftpgo

			docker run -d \
			  --name sftpgo \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -p 22022:2022 \
			  --mount type=bind,source=/home/docker/sftpgo/data,target=/srv/sftpgo \
			  --mount type=bind,source=/home/docker/sftpgo/config,target=/var/lib/sftpgo \
			  drakkan/sftpgo:latest

		}

		local docker_describe="オープンソースで無料、いつでもどこでもSFTP、FTP、WebDAVファイル転送ツール"
		local docker_url="官網介紹: https://sftpgo.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  70|astrbot)
		local app_id="70"
		local docker_name="astrbot"
		local docker_img="soulter/astrbot:latest"
		local docker_port=8070

		docker_rum() {

			mkdir -p /home/docker/astrbot/data

			docker run -d \
			  -p ${docker_port}:6185 \
			  -p 6195:6195 \
			  -p 6196:6196 \
			  -p 6199:6199 \
			  -p 11451:11451 \
			  -v /home/docker/astrbot/data:/AstrBot/data \
			  --restart=always \
			  --name astrbot \
			  soulter/astrbot:latest

		}

		local docker_describe="オープンソースAIチャットボットフレームワーク、WeChat、QQ、TGからAI大規模言語モデルへの接続をサポート"
		local docker_url="官網介紹: https://astrbot.app/"
		local docker_use="echo \"ユーザー名: astrbot  パスワード: astrbot\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  71|navidrome)
		local app_id="71"
		local docker_name="navidrome"
		local docker_img="deluan/navidrome:latest"
		local docker_port=8071

		docker_rum() {

			docker run -d \
			  --name navidrome \
			  --restart=always \
			  --user $(id -u):$(id -g) \
			  -v /home/docker/navidrome/music:/music \
			  -v /home/docker/navidrome/data:/data \
			  -p ${docker_port}:4533 \
			  -e ND_LOGLEVEL=info \
			  deluan/navidrome:latest

		}

		local docker_describe="軽量で高性能な音楽ストリーミングサーバー"
		local docker_url="官網介紹: https://www.navidrome.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  72|bitwarden)

		local app_id="72"
		local docker_name="bitwarden"
		local docker_img="vaultwarden/server"
		local docker_port=8072

		docker_rum() {

			docker run -d \
				--name bitwarden \
				--restart=always \
				-p ${docker_port}:80 \
				-v /home/docker/bitwarden/data:/data \
				vaultwarden/server

		}

		local docker_describe="あなたがデータをコントロールできるパスワードマネージャー"
		local docker_url="官網介紹: https://bitwarden.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app


		  ;;



	  73|libretv)

		local app_id="73"
		local docker_name="libretv"
		local docker_img="bestzwei/libretv:latest"
		local docker_port=8073

		docker_rum() {

			read -e -p "LibreTV のログインパスワードを設定してください:" app_passwd

			docker run -d \
			  --name libretv \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -e PASSWORD=${app_passwd} \
			  bestzwei/libretv:latest

		}

		local docker_describe="無料オンラインビデオ検索および視聴プラットフォーム"
		local docker_url="官網介紹: https://github.com/LibreSpark/LibreTV"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  74|moontv)

		local app_id="74"

		local app_name="moontvプライベートムービー"
		local app_text="無料オンラインビデオ検索および視聴プラットフォーム"
		local app_url="動画紹介: https://github.com/MoonTechLab/LunaTV"
		local docker_name="moontv-core"
		local docker_port="8074"
		local app_size="2"

		docker_app_install() {
			read -e -p "ログインユーザー名を設定してください:" admin
			read -e -p "ログインパスワードを設定してください:" admin_password
			read -e -p "ライセンスコードを入力してください:" shouquanma


			mkdir -p /home/docker/moontv
			mkdir -p /home/docker/moontv/config
			mkdir -p /home/docker/moontv/data
			cd /home/docker/moontv

			curl -o /home/docker/moontv/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/moontv-docker-compose.yml
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/moontv/docker-compose.yml
			sed -i "s|admin_password|${admin_password}|g" /home/docker/moontv/docker-compose.yml
			sed -i "s|admin|${admin}|g" /home/docker/moontv/docker-compose.yml
			sed -i "s|shouquanma|${shouquanma}|g" /home/docker/moontv/docker-compose.yml
			cd /home/docker/moontv/
			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			cd /home/docker/moontv/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			rm -rf /home/docker/moontv
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;


	  75|melody)

		local app_id="75"
		local docker_name="melody"
		local docker_img="foamzou/melody:latest"
		local docker_port=8075

		docker_rum() {

			docker run -d \
			  --name melody \
			  --restart=always \
			  -p ${docker_port}:5566 \
			  -v /home/docker/melody/.profile:/app/backend/.profile \
			  foamzou/melody:latest


		}

		local docker_describe="あなたの音楽の精霊、音楽をより良く管理するお手伝いをします。"
		local docker_url="官網介紹: https://github.com/foamzou/melody"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app


		  ;;


	  76|dosgame)

		local app_id="76"
		local docker_name="dosgame"
		local docker_img="oldiy/dosgame-web-docker:latest"
		local docker_port=8076

		docker_rum() {
			docker run -d \
				--name dosgame \
				--restart=always \
				-p ${docker_port}:262 \
				oldiy/dosgame-web-docker:latest

		}

		local docker_describe="中国語のDOSゲームコレクションサイト"
		local docker_url="公式サイト紹介: https://github.com/rwv/chinese-dos-games"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app


		  ;;

	  77|xunlei)

		local app_id="77"
		local docker_name="xunlei"
		local docker_img="cnk3x/xunlei"
		local docker_port=8077

		docker_rum() {

			read -e -p "ログインユーザー名を設定してください:" app_use
			read -e -p "ログインパスワードを設定してください:" app_passwd

			docker run -d \
			  --name xunlei \
			  --restart=always \
			  --privileged \
			  -e XL_DASHBOARD_USERNAME=${app_use} \
			  -e XL_DASHBOARD_PASSWORD=${app_passwd} \
			  -v /home/docker/xunlei/data:/xunlei/data \
			  -v /home/docker/xunlei/downloads:/xunlei/downloads \
			  -p ${docker_port}:2345 \
			  cnk3x/xunlei

		}

		local docker_describe="迅雷、あなたのオフライン高速BTマグネットダウンロードツール"
		local docker_url="公式サイト紹介: https://github.com/cnk3x/xunlei"
		local docker_use="echo \"Xunleiに携帯電話でログインし、招待コードを入力してください。招待コード: 迅雷牛通\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  78|PandaWiki)

		local app_id="78"
		local app_name="PandaWiki"
		local app_text="PandaWikiは、AI大規模モデル駆動型のオープンソースインテリジェントドキュメント管理システムであり、カスタムポートでのデプロイは強く推奨されません。"
		local app_url="公式紹介: https://github.com/chaitin/PandaWiki"
		local docker_name="panda-wiki-nginx"
		local docker_port="2443"
		local app_size="2"

		docker_app_install() {
			bash -c "$(curl -fsSLk https://release.baizhi.cloud/panda-wiki/manager.sh)"
		}

		docker_app_update() {
			docker_app_install
		}


		docker_app_uninstall() {
			docker_app_install
		}

		docker_app_plus
		  ;;



	  79|beszel)

		local app_id="79"
		local docker_name="beszel"
		local docker_img="henrygd/beszel"
		local docker_port=8079

		docker_rum() {

			mkdir -p /home/docker/beszel && \
			docker run -d \
			  --name beszel \
			  --restart=always \
			  -v /home/docker/beszel:/beszel_data \
			  -p ${docker_port}:8090 \
			  henrygd/beszel

		}

		local docker_describe="Beszel、軽量で使いやすいサーバー監視"
		local docker_url="公式サイト紹介：https://beszel.dev/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  80|linkwarden)

		  local app_id="80"
		  local app_name="linkwardenブックマーク管理"
		  local app_text="タグ、検索、チームコラボレーションをサポートするオープンソースの自己ホスティングブックマーク管理プラットフォーム。"
		  local app_url="公式サイト: https://linkwarden.app/"
		  local docker_name="linkwarden-linkwarden-1"
		  local docker_port="8080"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl
			  mkdir -p /home/docker/linkwarden && cd /home/docker/linkwarden

			  # 下载官方 docker-compose 和 env 文件
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env"

			  # 生成随机密钥与密码
			  local ADMIN_EMAIL="admin@example.com"
			  local ADMIN_PASSWORD=$(openssl rand -hex 8)

			  sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=http://localhost:${docker_port}/api/v1/auth|g" .env
			  sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$(openssl rand -hex 32)|g" .env
			  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 16)|g" .env
			  sed -i "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$(openssl rand -hex 32)|g" .env

			  # 追加管理员账号信息
			  echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >> .env
			  echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> .env

			  sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

			  # 启动容器
			  docker compose up -d

			  clear
			  echo "インストールが完了しました"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
			  cd /home/docker/linkwarden && docker compose down --rmi all
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env.new"

			  # 保留原本的变量
			  source .env
			  mv .env.new .env
			  echo "NEXTAUTH_URL=$NEXTAUTH_URL" >> .env
			  echo "NEXTAUTH_SECRET=$NEXTAUTH_SECRET" >> .env
			  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> .env
			  echo "MEILI_MASTER_KEY=$MEILI_MASTER_KEY" >> .env
			  echo "ADMIN_EMAIL=$ADMIN_EMAIL" >> .env
			  echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> .env
			  sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

			  docker compose up -d
		  }

		  docker_app_uninstall() {
			  cd /home/docker/linkwarden && docker compose down --rmi all
			  rm -rf /home/docker/linkwarden
			  echo "アプリケーションが削除されました"
		  }

		  docker_app_plus

		  ;;



	  81|jitsi)
		  local app_id="81"
		  local app_name="JitsiMeetビデオ会議"
		  local app_text="オープンソースの安全なビデオ会議ソリューションであり、複数人でのオンライン会議、画面共有、暗号化通信をサポートします。"
		  local app_url="公式サイト: https://jitsi.org/"
		  local docker_name="jitsi"
		  local docker_port="8081"
		  local app_size="3"

		  docker_app_install() {

			  add_yuming
			  mkdir -p /home/docker/jitsi && cd /home/docker/jitsi
			  wget $(wget -q -O - https://api.github.com/repos/jitsi/docker-jitsi-meet/releases/latest | grep zip | cut -d\" -f4)
			  unzip "$(ls -t | head -n 1)"
			  cd "$(ls -dt */ | head -n 1)"
			  cp env.example .env
			  ./gen-passwords.sh
			  mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
			  sed -i "s|^HTTP_PORT=.*|HTTP_PORT=${docker_port}|" .env
			  sed -i "s|^#PUBLIC_URL=https://meet.example.com:\${HTTPS_PORT}|PUBLIC_URL=https://$yuming:443|" .env
			  docker compose up -d

			  ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			  block_container_port "$docker_name" "$ipv4_address"

		  }

		  docker_app_update() {
			  cd /home/docker/jitsi
			  cd "$(ls -dt */ | head -n 1)"
			  docker compose down --rmi all
			  docker compose up -d

		  }

		  docker_app_uninstall() {
			  cd /home/docker/jitsi
			  cd "$(ls -dt */ | head -n 1)"
			  docker compose down --rmi all
			  rm -rf /home/docker/jitsi
			  echo "アプリケーションが削除されました"
		  }

		  docker_app_plus

		  ;;



	  82|gpt-load)

		local app_id="82"
		local docker_name="gpt-load"
		local docker_img="tbphp/gpt-load:latest"
		local docker_port=8082

		docker_rum() {

			read -e -p "${docker_name} のログインキーを設定してください（sk-で始まる英数字の組み合わせ）。例： sk-159kejilionyyds163:" app_passwd

			mkdir -p /home/docker/gpt-load && \
			docker run -d --name gpt-load \
				-p ${docker_port}:3001 \
				-e AUTH_KEY=${app_passwd} \
				-v "/home/docker/gpt-load/data":/app/data \
				tbphp/gpt-load:latest

		}

		local docker_describe="高性能AIインターフェース透過プロキシサービス"
		local docker_url="公式サイト紹介: https://www.gpt-load.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  83|komari)

		local app_id="83"
		local docker_name="komari"
		local docker_img="ghcr.io/komari-monitor/komari:latest"
		local docker_port=8083

		docker_rum() {

			mkdir -p /home/docker/komari && \
			docker run -d \
			  --name komari \
			  -p ${docker_port}:25774 \
			  -v /home/docker/komari:/app/data \
			  -e ADMIN_USERNAME=admin \
			  -e ADMIN_PASSWORD=1212156 \
			  --restart=always \
			  ghcr.io/komari-monitor/komari:latest

		}

		local docker_describe="軽量でセルフホスト可能なサーバー監視ツール"
		local docker_url="公式サイト紹介: https://github.com/komari-monitor/komari/tree/main"
		local docker_use="echo \"デフォルトアカウント: admin  デフォルトパスワード: 1212156\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  84|wallos)

		local app_id="84"
		local docker_name="wallos"
		local docker_img="bellamy/wallos:latest"
		local docker_port=8084

		docker_rum() {

			mkdir -p /home/docker/wallos && \
			docker run -d --name wallos \
			  -v /home/docker/wallos/db:/var/www/html/db \
			  -v /home/docker/wallos/logos:/var/www/html/images/uploads/logos \
			  -e TZ=UTC \
			  -p ${docker_port}:80 \
			  --restart=always \
			  bellamy/wallos:latest

		}

		local docker_describe="オープンソースの個人サブスクリプショントラッカー、財務管理に使用可能"
		local docker_url="公式サイト紹介: https://github.com/ellite/Wallos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  85|immich)

		  local app_id="85"
		  local app_name="immich画像/動画マネージャー"
		  local app_text="高性能な自己ホスティング写真およびビデオ管理ソリューション。"
		  local app_url="公式サイト紹介: https://github.com/immich-app/immich"
		  local docker_name="immich_server"
		  local docker_port="8085"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl wget
			  mkdir -p /home/docker/${docker_name} && cd /home/docker/${docker_name}

			  wget -O docker-compose.yml ${gh_proxy}github.com/immich-app/immich/releases/latest/download/docker-compose.yml
			  wget -O .env ${gh_proxy}github.com/immich-app/immich/releases/latest/download/example.env
			  sed -i "s/2283:2283/${docker_port}:2283/g" /home/docker/${docker_name}/docker-compose.yml

			  docker compose up -d

			  clear
			  echo "インストールが完了しました"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
		  }

		  docker_app_uninstall() {
			  cd /home/docker/${docker_name} && docker compose down --rmi all
			  rm -rf /home/docker/${docker_name}
			  echo "アプリケーションが削除されました"
		  }

		  docker_app_plus


		  ;;


	  86|jellyfin)

		local app_id="86"
		local docker_name="jellyfin"
		local docker_img="jellyfin/jellyfin"
		local docker_port=8086

		docker_rum() {

			mkdir -p /home/docker/jellyfin/media
			chmod -R 777 /home/docker/jellyfin

			docker run -d \
			  --name jellyfin \
			  --user root \
			  --volume /home/docker/jellyfin/config:/config \
			  --volume /home/docker/jellyfin/cache:/cache \
			  --mount type=bind,source=/home/docker/jellyfin/media,target=/media \
			  -p ${docker_port}:8096 \
			  -p 7359:7359/udp \
			  --restart=always \
			  jellyfin/jellyfin


		}

		local docker_describe="オープンソースのメディアサーバーソフトウェア"
		local docker_url="公式サイト紹介: https://jellyfin.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  87|synctv)

		local app_id="87"
		local docker_name="synctv"
		local docker_img="synctvorg/synctv"
		local docker_port=8087

		docker_rum() {

			docker run -d \
				--name synctv \
				-v /home/docker/synctv:/root/.synctv \
				-p ${docker_port}:8080 \
				--restart=always \
				synctvorg/synctv

		}

		local docker_describe="映画やライブストリームを一緒にリモートで視聴するプログラム。同期視聴、ライブストリーム、チャットなどの機能を提供します。"
		local docker_url="公式サイト紹介: https://github.com/synctv-org/synctv"
		local docker_use="echo \"初期アカウントとパスワード: root  ログイン後、速やかにログインパスワードを変更してください\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  88|owncast)

		local app_id="88"
		local docker_name="owncast"
		local docker_img="owncast/owncast:latest"
		local docker_port=8088

		docker_rum() {

			docker run -d \
				--name owncast \
				-p ${docker_port}:8080 \
				-p 1935:1935 \
				-v /home/docker/owncast/data:/app/data \
				--restart=always \
				owncast/owncast:latest


		}

		local docker_describe="オープンソース、無料のセルフビルドライブストリームプラットフォーム"
		local docker_url="公式サイト紹介: https://owncast.online"
		local docker_use="echo \"アドレスの後に /admin を付けて管理画面にアクセス\""
		local docker_passwd="echo \"初期アカウント: admin  初期パスワード: abc123  ログイン後、速やかにログインパスワードを変更してください\""
		local app_size="1"
		docker_app

		  ;;



	  89|file-code-box)

		local app_id="89"
		local docker_name="file-code-box"
		local docker_img="lanol/filecodebox:latest"
		local docker_port=8089

		docker_rum() {

			docker run -d \
			  --name file-code-box \
			  -p ${docker_port}:12345 \
			  -v /home/docker/file-code-box/data:/app/data \
			  --restart=always \
			  lanol/filecodebox:latest

		}

		local docker_describe="匿名のパスワードでテキストやファイルを共有、快递のようにファイルを取得"
		local docker_url="公式サイト紹介: https://github.com/vastsa/FileCodeBox"
		local docker_use="echo \"アドレスの後に /#/admin を付けて管理画面にアクセス\""
		local docker_passwd="echo \"管理者パスワード: FileCodeBox2023\""
		local app_size="1"
		docker_app

		  ;;




	  90|matrix)

		local app_id="90"
		local docker_name="matrix"
		local docker_img="matrixdotorg/synapse:latest"
		local docker_port=8090

		docker_rum() {

			add_yuming

			if [ ! -d /home/docker/matrix/data ]; then
				docker run -it --rm \
				  -v /home/docker/matrix/data:/data \
				  -e SYNAPSE_SERVER_NAME=${yuming} \
				  -e SYNAPSE_REPORT_STATS=yes \
				  --name matrix \
				  matrixdotorg/synapse:latest generate
			fi

			docker run -d \
			  --name matrix \
			  -v /home/docker/matrix/data:/data \
			  -p ${docker_port}:8008 \
			  --restart=always \
			  matrixdotorg/synapse:latest

			echo "初期ユーザーまたは管理者を生成します。以下のユーザー名とパスワード、および管理者であるかどうかを設定してください。"
			docker exec -it matrix register_new_matrix_user \
			  http://localhost:8008 \
			  -c /data/homeserver.yaml

			sed -i '/^enable_registration:/d' /home/docker/matrix/data/homeserver.yaml
			sed -i '/^# vim:ft=yaml/i enable_registration: true' /home/docker/matrix/data/homeserver.yaml
			sed -i '/^enable_registration_without_verification:/d' /home/docker/matrix/data/homeserver.yaml
			sed -i '/^# vim:ft=yaml/i enable_registration_without_verification: true' /home/docker/matrix/data/homeserver.yaml

			docker restart matrix

			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"

		}

		local docker_describe="Matrixは分散型チャットプロトコルです"
		local docker_url="公式サイト紹介: https://matrix.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  91|gitea)

		local app_id="91"

		local app_name="giteaプライベートコードリポジトリ"
		local app_text="GitHubに近いユーザーエクスペリエンスを提供する、無料の次世代コードホスティングプラットフォーム。"
		local app_url="動画紹介: https://github.com/go-gitea/gitea"
		local docker_name="gitea"
		local docker_port="8091"
		local app_size="2"

		docker_app_install() {

			mkdir -p /home/docker/gitea
			mkdir -p /home/docker/gitea/gitea
			mkdir -p /home/docker/gitea/data
			mkdir -p /home/docker/gitea/postgres
			cd /home/docker/gitea

			curl -o /home/docker/gitea/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/gitea-docker-compose.yml
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/gitea/docker-compose.yml
			cd /home/docker/gitea/
			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			cd /home/docker/gitea/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			rm -rf /home/docker/gitea
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;




	  92|filebrowser)

		local app_id="92"
		local docker_name="filebrowser"
		local docker_img="hurlenko/filebrowser"
		local docker_port=8092

		docker_rum() {

			docker run -d \
				--name filebrowser \
				--restart=always \
				-p ${docker_port}:8080 \
				-v /home/docker/filebrowser/data:/data \
				-v /home/docker/filebrowser/config:/config \
				-e FB_BASEURL=/filebrowser \
				hurlenko/filebrowser

		}

		local docker_describe="Webベースのファイルマネージャーです"
		local docker_url="公式サイト紹介: https://filebrowser.org/"
		local docker_use="docker logs filebrowser"
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	93|dufs)

		local app_id="93"
		local docker_name="dufs"
		local docker_img="sigoden/dufs"
		local docker_port=8093

		docker_rum() {

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}:/data \
			  -p ${docker_port}:5000 \
			  ${docker_img} /data -A

		}

		local docker_describe="アップロードとダウンロードをサポートするミニマルな静的ファイルサーバー"
		local docker_url="公式サイト紹介: https://github.com/sigoden/dufs"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;

	94|gopeed)

		local app_id="94"
		local docker_name="gopeed"
		local docker_img="liwei2633/gopeed"
		local docker_port=8094

		docker_rum() {

			read -e -p "ログインユーザー名を設定してください:" app_use
			read -e -p "ログインパスワードを設定してください:" app_passwd

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}/downloads:/app/Downloads \
			  -v /home/docker/${docker_name}/storage:/app/storage \
			  -p ${docker_port}:9999 \
			  ${docker_img} -u ${app_use} -p ${app_passwd}

		}

		local docker_describe="複数のプロトコルをサポートする分散型高速ダウンロードツール"
		local docker_url="公式サイト紹介: https://github.com/GopeedLab/gopeed"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;



	  95|paperless)

		local app_id="95"

		local app_name="paperlessドキュメント管理プラットフォーム"
		local app_text="オープンソースの電子ドキュメント管理システムで、主な用途は紙のドキュメントをデジタル化して管理することです。"
		local app_url="動画紹介: https://docs.paperless-ngx.com/"
		local docker_name="paperless-webserver-1"
		local docker_port="8095"
		local app_size="2"

		docker_app_install() {

			mkdir -p /home/docker/paperless
			mkdir -p /home/docker/paperless/export
			mkdir -p /home/docker/paperless/consume
			cd /home/docker/paperless

			curl -o /home/docker/paperless/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/docker-compose.postgres-tika.yml
			curl -o /home/docker/paperless/docker-compose.env ${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/.env

			sed -i "s/8000:8000/${docker_port}:8000/g" /home/docker/paperless/docker-compose.yml
			cd /home/docker/paperless
			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			rm -rf /home/docker/paperless
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;



	  96|2fauth)

		local app_id="96"

		local app_name="2FAuthセルフホスト型二要素認証"
		local app_text="自己ホスティングの二要素認証（2FA）アカウント管理およびコード生成ツール。"
		local app_url="公式サイト: https://github.com/Bubka/2FAuth"
		local docker_name="2fauth"
		local docker_port="8096"
		local app_size="1"

		docker_app_install() {

			add_yuming

			mkdir -p /home/docker/2fauth
			mkdir -p /home/docker/2fauth/data
			chmod -R 777 /home/docker/2fauth/
			cd /home/docker/2fauth

			curl -o /home/docker/2fauth/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/2fauth-docker-compose.yml

			sed -i "s/8000:8000/${docker_port}:8000/g" /home/docker/2fauth/docker-compose.yml
			sed -i "s/yuming.com/${yuming}/g" /home/docker/2fauth/docker-compose.yml
			cd /home/docker/2fauth
			docker compose up -d

			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"

			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			rm -rf /home/docker/2fauth
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;



	97|wgs)

		local app_id="97"
		local docker_name="wireguard"
		local docker_img="lscr.io/linuxserver/wireguard:latest"
		local docker_port=8097

		docker_rum() {

		read -e -p  "请输入组网的客户端数量 (默认 5): " COUNT
		COUNT=${COUNT:-5}
		read -e -p  "请输入 WireGuard 网段 (默认 10.13.13.0): " NETWORK
		NETWORK=${NETWORK:-10.13.13.0}

		PEERS=$(seq -f "wg%02g" 1 "$COUNT" | paste -sd,)

		ip link delete wg0 &>/dev/null

		ip_address
		docker run -d \
		  --name=wireguard \
		  --network host \
		  --cap-add=NET_ADMIN \
		  --cap-add=SYS_MODULE \
		  -e PUID=1000 \
		  -e PGID=1000 \
		  -e TZ=Etc/UTC \
		  -e SERVERURL=${ipv4_address} \
		  -e SERVERPORT=51820 \
		  -e PEERS=${PEERS} \
		  -e INTERNAL_SUBNET=${NETWORK} \
		  -e ALLOWEDIPS=${NETWORK}/24 \
		  -e PERSISTENTKEEPALIVE_PEERS=all \
		  -e LOG_CONFS=true \
		  -v /home/docker/wireguard/config:/config \
		  -v /lib/modules:/lib/modules \
		  --restart=always \
		  lscr.io/linuxserver/wireguard:latest


		sleep 3

		docker exec wireguard sh -c "
		f='/config/wg_confs/wg0.conf'
		sed -i 's/51820/${docker_port}/g' \$f
		"

		docker exec wireguard sh -c "
		for d in /config/peer_*; do
		  sed -i 's/51820/${docker_port}/g' \$d/*.conf
		done
		"

		docker exec wireguard sh -c '
		for d in /config/peer_*; do
		  sed -i "/^DNS/d" "$d"/*.conf
		done
		'

		docker exec wireguard sh -c '
		for d in /config/peer_*; do
		  for f in "$d"/*.conf; do
			grep -q "^PersistentKeepalive" "$f" || \
			sed -i "/^AllowedIPs/ a PersistentKeepalive = 25" "$f"
		  done
		done
		'

		docker exec -it wireguard bash -c '
		for d in /config/peer_*; do
		  cd "$d" || continue
		  conf_file=$(ls *.conf)
		  base_name="${conf_file%.conf}"
		  qrencode -o "$base_name.png" < "$conf_file"
		done
		'

		docker restart wireguard

		sleep 2
		echo
		echo -e "${gl_huang}全クライアント QRコード設定: ${gl_bai}"
		docker exec -it wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
		sleep 2
		echo
		echo -e "${gl_huang}全クライアント設定コード: ${gl_bai}"
		docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
		sleep 2
		echo -e "${gl_lv}${COUNT}クライアント設定をすべて出力します。使用方法は以下の通りです: ${gl_bai}"
		echo -e "${gl_lv}1. スマートフォンでWGのAPPをダウンロードし、上記のQRコードをスキャンすると、ネットワークに素早く接続できます${gl_bai}"
		echo -e "${gl_lv}2. Windowsでクライアントをダウンロードし、設定コードをコピーしてネットワークに接続します。${gl_bai}"
		echo -e "${gl_lv}3. Linuxではスクリプトを使用してWGクライアントをデプロイし、設定コードをコピーしてネットワークに接続します。${gl_bai}"
		echo -e "${gl_lv}公式クライアントダウンロード方法: https://www.wireguard.com/install/${gl_bai}"
		break_end

		}

		local docker_describe="モダンで高性能なVPNツール"
		local docker_url="公式サイト紹介: https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	98|wgc)

		local app_id="98"
		local docker_name="wireguardc"
		local docker_img="kjlion/wireguard:alpine"
		local docker_port=51820

		docker_rum() {

			mkdir -p /home/docker/wireguard/config/

			local CONFIG_FILE="/home/docker/wireguard/config/wg0.conf"

			# 创建目录（如果不存在）
			mkdir -p "$(dirname "$CONFIG_FILE")"

			echo "クライアント構成を貼り付けて、Enterキーを2回押して保存してください:"

			# 初始化变量
			input=""
			empty_line_count=0

			# 逐行读取用户输入
			while IFS= read -r line; do
				if [[ -z "$line" ]]; then
					((empty_line_count++))
					if [[ $empty_line_count -ge 2 ]]; then
						break
					fi
				else
					empty_line_count=0
					input+="$line"$'\n'
				fi
			done

			# 写入配置文件
			echo "$input" > "$CONFIG_FILE"

			echo "クライアント構成は $CONFIG_FILE に保存されました"

			ip link delete wg0 &>/dev/null

			docker run -d \
			  --name wireguardc \
			  --network host \
			  --cap-add NET_ADMIN \
			  --cap-add SYS_MODULE \
			  -v /home/docker/wireguard/config:/config \
			  -v /lib/modules:/lib/modules:ro \
			  --restart=always \
			  kjlion/wireguard:alpine

			sleep 3

			docker logs wireguardc

		break_end

		}

		local docker_describe="モダンで高性能なVPNツール"
		local docker_url="公式サイト紹介: https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  99|dsm)

		local app_id="99"

		local app_name="dsmSynology仮想マシン"
		local app_text="Dockerコンテナ内の仮想DSM"
		local app_url="公式サイト: https://github.com/vdsm/virtual-dsm"
		local docker_name="dsm"
		local docker_port="8099"
		local app_size="16"

		docker_app_install() {

			read -e -p "CPU コア数を設定してください(デフォルト 2) : " CPU_CORES
			local CPU_CORES=${CPU_CORES:-2}

			read -e -p "メモリサイズを設定してください(デフォルト 4G) : " RAM_SIZE
			local RAM_SIZE=${RAM_SIZE:-4}

			mkdir -p /home/docker/dsm
			mkdir -p /home/docker/dsm/dev
			chmod -R 777 /home/docker/dsm/
			cd /home/docker/dsm

			curl -o /home/docker/dsm/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/dsm-docker-compose.yml

			sed -i "s/5000:5000/${docker_port}:5000/g" /home/docker/dsm/docker-compose.yml
			sed -i "s|CPU_CORES: "2"|CPU_CORES: "${CPU_CORES}"|g" /home/docker/dsm/docker-compose.yml
			sed -i "s|RAM_SIZE: "2G"|RAM_SIZE: "${RAM_SIZE}G"|g" /home/docker/dsm/docker-compose.yml
			cd /home/docker/dsm
			docker compose up -d

			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			rm -rf /home/docker/dsm
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;



	100|syncthing)

		local app_id="100"
		local docker_name="syncthing"
		local docker_img="syncthing/syncthing:latest"
		local docker_port=8100

		docker_rum() {
			docker run -d \
			  --name=syncthing \
			  --hostname=my-syncthing \
			  --restart=always \
			  -p ${docker_port}:8384 \
			  -p 22000:22000/tcp \
			  -p 22000:22000/udp \
			  -p 21027:21027/udp \
			  -v /home/docker/syncthing:/var/syncthing \
			  syncthing/syncthing:latest
		}

		local docker_describe="Dropbox、Resilio Syncに似ていますが、完全に分散化されたオープンソースのP2Pファイル同期ツールです。"
		local docker_url="公式サイト紹介: https://github.com/syncthing/syncthing"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  101|moneyprinterturbo)
		local app_id="101"
		local app_name="AI動画生成ツール"
		local app_text="MoneyPrinterTurboは、AI大規模モデルを使用して高解像度の短編ビデオを合成するツールです"
		local app_url="公式サイト: https://github.com/harry0703/MoneyPrinterTurbo"
		local docker_name="moneyprinterturbo"
		local docker_port="8101"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/harry0703/MoneyPrinterTurbo.git && cd MoneyPrinterTurbo/
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml

			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/MoneyPrinterTurbo/ && docker compose down --rmi all
			cd  /home/docker/MoneyPrinterTurbo/
			git pull origin main
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml
			cd  /home/docker/MoneyPrinterTurbo/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/MoneyPrinterTurbo/ && docker compose down --rmi all
			rm -rf /home/docker/MoneyPrinterTurbo
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;



	  102|vocechat)

		local app_id="102"
		local docker_name="vocechat-server"
		local docker_img="privoce/vocechat-server:latest"
		local docker_port=8102

		docker_rum() {

			docker run -d --restart=always \
			  -p ${docker_port}:3000 \
			  --name vocechat-server \
			  -v /home/docker/vocechat/data:/home/vocechat-server/data \
			  privoce/vocechat-server:latest

		}

		local docker_describe="独立してデプロイできる個人向けクラウドソーシャルメディアチャットサービスです"
		local docker_url="公式サイト紹介: https://github.com/Privoce/vocechat-web"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  103|umami)
		local app_id="103"
		local app_name="Umamiウェブサイト統計ツール"
		local app_text="オープンソース、軽量、プライバシーに配慮したウェブサイト分析ツールで、Google Analyticsに似ています。"
		local app_url="公式サイト: https://github.com/umami-software/umami"
		local docker_name="umami-umami-1"
		local docker_port="8103"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/umami-software/umami.git && cd umami
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/umami/docker-compose.yml

			docker compose up -d
			clear
			echo "インストールが完了しました"
			check_docker_app_ip
			echo "初期ユーザー名: admin"
			echo "初期パスワード: umami"
		}

		docker_app_update() {
			cd  /home/docker/umami/ && docker compose down --rmi all
			cd  /home/docker/umami/
			git pull origin main
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/umami/docker-compose.yml
			cd  /home/docker/umami/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/umami/ && docker compose down --rmi all
			rm -rf /home/docker/umami
			echo "アプリケーションが削除されました"
		}

		docker_app_plus

		  ;;

	  104|nginx-stream)
		stream_panel
		  ;;


	  105|siyuan)

		local app_id="105"
		local docker_name="siyuan"
		local docker_img="b3log/siyuan"
		local docker_port=8105

		docker_rum() {

			read -e -p "ログインパスワードを設定してください:" app_passwd

			docker run -d \
			  --name siyuan \
			  --restart=always \
			  -v /home/docker/siyuan/workspace:/siyuan/workspace \
			  -p ${docker_port}:6806 \
			  -e PUID=1001 \
			  -e PGID=1002 \
			  b3log/siyuan \
			  --workspace=/siyuan/workspace/ \
			  --accessAuthCode="${app_passwd}"

		}

		local docker_describe="思源ノートは、プライバシーを重視した知識管理システムです"
		local docker_url="公式サイト紹介: https://github.com/siyuan-note/siyuan"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  106|drawnix)

		local app_id="106"
		local docker_name="drawnix"
		local docker_img="pubuzhixing/drawnix"
		local docker_port=8106

		docker_rum() {

			docker run -d \
			   --restart=always  \
			   --name drawnix \
			   -p ${docker_port}:80 \
			  pubuzhixing/drawnix

		}

		local docker_describe="マインドマップ、フローチャートなどを統合した強力なオープンソースホワイトボードツールです。"
		local docker_url="公式サイト紹介: https://github.com/plait-board/drawnix"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  107|pansou)

		local app_id="107"
		local docker_name="pansou"
		local docker_img="ghcr.io/fish2018/pansou-web"
		local docker_port=8107

		docker_rum() {

			docker run -d \
			  --name pansou \
			  --restart=always \
			  -p ${docker_port}:80 \
			  -v /home/docker/pansou/data:/app/data \
			  -v /home/docker/pansou/logs:/app/logs \
			  -e ENABLED_PLUGINS="hunhepan,jikepan,panwiki,pansearch,panta,qupansou,
susu,thepiratebay,wanou,xuexizhinan,panyq,zhizhen,labi,muou,ouge,shandian,
duoduo,huban,cyg,erxiao,miaoso,fox4k,pianku,clmao,wuji,cldi,xiaozhang,
libvio,leijing,xb6v,xys,ddys,hdmoli,yuhuage,u3c3,javdb,clxiong,jutoushe,
sdso,xiaoji,xdyh,haisou,bixin,djgou,nyaa,xinjuc,aikanzy,qupanshe,xdpan,
discourse,yunsou,ahhhhfs,nsgame,gying" \
			  ghcr.io/fish2018/pansou-web

		}

		local docker_describe="PanSouは、高性能なネットワークディスクリソース検索APIサービスです。"
		local docker_url="公式サイト紹介: https://github.com/fish2018/pansou"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;




	  b)
	  	clear
	  	send_stats "全部应用备份"

	  	local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
	  	echo -e "${gl_huang}$backup_filename をバックアップ中...${gl_bai}"
	  	cd / && tar czvf "$backup_filename" home

	  	while true; do
			clear
			echo "バックアップファイルが作成されました: /$backup_filename"
			read -e -p "バックアップデータをリモートサーバーに送信しますか？ (y/N):" choice
			case "$choice" in
			  [Yy])
				read -e -p "リモートサーバーのIPを入力してください:" remote_ip
				read -e -p "ターゲットサーバーSSHポート [デフォルト 22]: " TARGET_PORT
				local TARGET_PORT=${TARGET_PORT:-22}

				if [ -z "$remote_ip" ]; then
				  echo "エラー: リモートサーバーのIPを入力してください。"
				  continue
				fi
				local latest_tar=$(ls -t /app*.tar.gz | head -1)
				if [ -n "$latest_tar" ]; then
				  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				  sleep 2  # 添加等待时间
				  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
				  echo "ファイルはリモートサーバーのルートディレクトリに転送されました。"
				else
				  echo "転送するファイルが見つかりませんでした。"
				fi
				break
				;;
			  *)
				echo "注意: 現在のバックアップにはDockerプロジェクトのみが含まれており、宝塔、1panelなどのウェブサイト構築パネルのデータバックアップは含まれていません。"
				break
				;;
			esac
	  	done

		  ;;

	  r)
	  	root_use
	  	send_stats "全部应用还原"
	  	echo "利用可能なアプリケーションバックアップ"
	  	echo "-------------------------"
	  	ls -lt /app*.gz | awk '{print $NF}'
	  	echo ""
	  	read -e -p  "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

	  	if [ "$filename" == "0" ]; then
			  break_end
			  linux_panel
	  	fi

	  	# 如果用户没有输入文件名，使用最新的压缩包
	  	if [ -z "$filename" ]; then
			  local filename=$(ls -t /app*.tar.gz | head -1)
	  	fi

	  	if [ -n "$filename" ]; then
		  	  echo -e "${gl_huang}$filename を展開中...${gl_bai}"
		  	  cd / && tar -xzf "$filename"
			  echo "アプリケーションデータは復元されました。現在、指定されたアプリケーションメニューに手動で入り、アプリケーションを更新することで、アプリケーションを復元できます。"
	  	else
			  echo "圧縮ファイルが見つかりませんでした。"
	  	fi

		  ;;


	  0)
		  kejilion
		  ;;
	  *)
		  ;;
	esac
	break_end
	sub_choice=""

done
}


linux_work() {

	while true; do
	  clear
	  send_stats "后台工作区"
	  echo -e "バックグラウンドワークスペース"
	  echo -e "システムはバックグラウンドで常駐実行できるワークスペースを提供し、長時間タスクの実行に使用できます。"
	  echo -e "SSHを切断しても、ワークスペース内のタスクは中断されません。バックグラウンド常駐タスク。"
	  echo -e "${gl_huang}ヒント: ${gl_bai}ワークスペースに入ったらCtrl+bを押し、次にdを単独で押して、ワークスペースを終了してください！ "
	  echo -e "${gl_kjlan}------------------------"
	  echo "現在存在するワークスペースのリスト"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ワークスペース1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}2 ワークスペース"
	  echo -e "${gl_kjlan}3.   ${gl_bai}3 ワークスペース"
	  echo -e "${gl_kjlan}4.   ${gl_bai}4 ワークスペース"
	  echo -e "${gl_kjlan}5.   ${gl_bai}5 ワークスペース"
	  echo -e "${gl_kjlan}6.   ${gl_bai}6 ワークスペース"
	  echo -e "${gl_kjlan}7.   ${gl_bai}7 ワークスペース"
	  echo -e "${gl_kjlan}8.   ${gl_bai}8 ワークスペース"
	  echo -e "${gl_kjlan}9.   ${gl_bai}9 ワークスペース"
	  echo -e "${gl_kjlan}10.  ${gl_bai}10 ワークスペース"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH 常駐モード ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}ワークスペースの作成/入室"
	  echo -e "${gl_kjlan}23.  ${gl_bai}バックグラウンドワークスペースへのコマンド注入"
	  echo -e "${gl_kjlan}24.  ${gl_bai}指定されたワークスペースの削除"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;

		  21)
			while true; do
			  clear
			  if grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc; then
				  local tmux_sshd_status="${gl_lv}开启${gl_bai}"
			  else
				  local tmux_sshd_status="${gl_hui}关闭${gl_bai}"
			  fi
			  send_stats "SSH常驻模式 "
			  echo -e "SSH 常駐モード ${tmux_sshd_status}"
			  echo "開いた後、SSH接続すると直接常駐モードに入り、以前の作業状態に戻ります。"
			  echo "------------------------"
			  echo "1. 有効                  2. 無効"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択を入力してください: " gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "启动工作区$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# 自动进入 tmux 会话\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
				  source ~/.bashrc
			  	  tmux_run
				  ;;
				2)
				  sed -i '/# 自动进入 tmux 会话/,+4d' ~/.bashrc
				  tmux kill-window -t sshd
				  ;;
				*)
				  break
				  ;;
			  esac
			done
			  ;;

		  22)
			  read -e -p "作成または参加するワークスペース名を入力してください。例: 1001 kj001 work1: " SESSION_NAME
			  tmux_run
			  send_stats "自定义工作区"
			  ;;


		  23)
			  read -e -p "バックグラウンドで実行するコマンドを入力してください。例: curl -fsSL https://get.docker.com | sh: " tmuxd
			  tmux_run_d
			  send_stats "注入命令到后台工作区"
			  ;;

		  24)
			  read -e -p "削除するワークスペース名を入力してください: " gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "删除工作区"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # send_stats "系统工具"
	  echo -e "システムツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}スクリプト起動ショートカットの設定                 ${gl_kjlan}2.   ${gl_bai}ログインパスワードの変更"
	  echo -e "${gl_kjlan}3.   ${gl_bai}root パスワードログインモード                      ${gl_kjlan}4.   ${gl_bai}Python の指定バージョンをインストール"
	  echo -e "${gl_kjlan}5.   ${gl_bai}すべてのポートを開放                               ${gl_kjlan}6.   ${gl_bai}SSH ポートの変更"
	  echo -e "${gl_kjlan}7.   ${gl_bai}DNS アドレスの最適化                               ${gl_kjlan}8.   ${gl_bai}ワンクリックシステム再インストール ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}root アカウントによる新規アカウント作成を無効化    ${gl_kjlan}10.  ${gl_bai}優先 IPv4/IPv6 の切り替え"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}ポート占有状態の確認                               ${gl_kjlan}12.  ${gl_bai}仮想メモリサイズの変更"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ユーザー管理                                       ${gl_kjlan}14.  ${gl_bai}ユーザー/パスワードジェネレータ"
	  echo -e "${gl_kjlan}15.  ${gl_bai}システムタイムゾーン調整                           ${gl_kjlan}16.  ${gl_bai}BBRv3アクセラレータの設定"
	  echo -e "${gl_kjlan}17.  ${gl_bai}ファイアウォール高度マネージャー                   ${gl_kjlan}18.  ${gl_bai}ホスト名の変更"
	  echo -e "${gl_kjlan}19.  ${gl_bai}システムアップデートソースの切り替え               ${gl_kjlan}20.  ${gl_bai}定時タスク管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}ローカルHost解析                                   ${gl_kjlan}22.  ${gl_bai}SSH防御プログラム"
	  echo -e "${gl_kjlan}23.  ${gl_bai}レート制限自動シャットダウン                       ${gl_kjlan}24.  ${gl_bai}root秘密鍵ログインモード"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-botシステム監視アラート                         ${gl_kjlan}26.  ${gl_bai}OpenSSH高リスク脆弱性の修復"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat系Linuxカーネルアップグレード               ${gl_kjlan}28.  ${gl_bai}Linuxシステムカーネルパラメータ最適化 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}ウイルススキャンツール ${gl_huang}★${gl_bai}                           ${gl_kjlan}30.  ${gl_bai}ファイルマネージャー"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}システム言語の切り替え                             ${gl_kjlan}32.  ${gl_bai}コマンドライン整形ツール ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}システムゴミ箱の設定                               ${gl_kjlan}34.  ${gl_bai}システムバックアップと復元"
	  echo -e "${gl_kjlan}35.  ${gl_bai}SSHリモート接続ツール                              ${gl_kjlan}36.  ${gl_bai}ディスクパーティション管理ツール"
	  echo -e "${gl_kjlan}37.  ${gl_bai}コマンド履歴                                       ${gl_kjlan}38.  ${gl_bai}rsyncリモート同期ツール"
	  echo -e "${gl_kjlan}39.  ${gl_bai}コマンドお気に入り ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}掲示板                                             ${gl_kjlan}66.  ${gl_bai}ワンストップシステムチューニング ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}サーバー再起動                                     ${gl_kjlan}100. ${gl_bai}プライバシーとセキュリティ"
	  echo -e "${gl_kjlan}101. ${gl_bai}kコマンド高度な使い方 ${gl_huang}★${gl_bai}                            ${gl_kjlan}102. ${gl_bai}KejiLionスクリプトの削除"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "ショートカットキーを入力してください(0 を入力すると終了) : " kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "ショートカットが設定されました"
				  send_stats "脚本快捷键已设置"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "设置你的登录密码"
			  echo "ログインパスワードを設定してください"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "root密码模式"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "py版本管理"
			echo "Pythonバージョン管理"
			echo "ビデオ紹介: https://youtu.be/E4NhofhUlRU"
			echo "---------------------------------------"
			echo "この機能により、Python公式サポートのあらゆるバージョンをシームレスにインストールできます！"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "現在のPythonバージョン: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "推奨バージョン: 3.12    3.11    3.10    3.9    3.8    2.7"
			echo "その他のバージョンの検索: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "インストールする Python のバージョン番号を入力してください(0 を入力すると終了) : " py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "脚本PY管理"
				break_end
				linux_Settings
			fi


			if ! grep -q 'export PYENV_ROOT="\$HOME/.pyenv"' ~/.bashrc; then
				if command -v yum &>/dev/null; then
					yum update -y && yum install git -y
					yum groupinstall "Development Tools" -y
					yum install openssl-devel bzip2-devel libffi-devel ncurses-devel zlib-devel readline-devel sqlite-devel xz-devel findutils -y

					curl -O https://www.openssl.org/source/openssl-1.1.1u.tar.gz
					tar -xzf openssl-1.1.1u.tar.gz
					cd openssl-1.1.1u
					./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
					make
					make install
					echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/openssl-1.1.1u.conf
					ldconfig -v
					cd ..

					export LDFLAGS="-L/usr/local/openssl/lib"
					export CPPFLAGS="-I/usr/local/openssl/include"
					export PKG_CONFIG_PATH="/usr/local/openssl/lib/pkgconfig"

				elif command -v apt &>/dev/null; then
					apt update -y && apt install git -y
					apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev libgdbm-dev libnss3-dev libedit-dev -y
				elif command -v apk &>/dev/null; then
					apk update && apk add git
					apk add --no-cache bash gcc musl-dev libffi-dev openssl-dev bzip2-dev zlib-dev readline-dev sqlite-dev libc6-compat linux-headers make xz-dev build-base  ncurses-dev
				else
					echo "不明なパッケージマネージャー！"
					return
				fi

				curl https://pyenv.run | bash
				cat << EOF >> ~/.bashrc

export PYENV_ROOT="\$HOME/.pyenv"
if [[ -d "\$PYENV_ROOT/bin" ]]; then
  export PATH="\$PYENV_ROOT/bin:\$PATH"
fi
eval "\$(pyenv init --path)"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"

EOF

			fi

			sleep 1
			source ~/.bashrc
			sleep 1
			pyenv install $py_new_v
			pyenv global $py_new_v

			rm -rf /tmp/python-build.*
			rm -rf $(pyenv root)/cache/*

			local VERSION=$(python -V 2>&1 | awk '{print $2}')
			echo -e "現在のPythonバージョン: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			  ;;

		  5)
			  root_use
			  send_stats "开放端口"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "ポートはすべて開放されました"

			  ;;
		  6)
			root_use
			send_stats "修改SSH端口"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# 读取当前的 SSH 端口号
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 打印当前的 SSH 端口号
				echo -e "現在のSSHポート番号は:  ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "ポート番号の範囲は1から65535までの数字です。(0を入力してログアウト)"

				# 提示用户输入新的 SSH 端口号
				read -e -p "新しい SSH ポート番号を入力してください: " new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "ポート番号が無効です。1から65535までの数字を入力してください。"
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "入力が無効です。数字を入力してください。"
					send_stats "输入无效SSH端口"
					break_end
				fi
			done


			  ;;


		  7)
			set_dns_ui
			  ;;

		  8)

			dd_xitong
			  ;;
		  9)
			root_use
			send_stats "新用户禁用root"
			read -e -p "新しいユーザー名を入力してください(0 を入力すると終了) : " new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			install sudo

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "操作が完了しました。"
			;;


		  10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "IPv4/IPv6 優先順位の設定"
				echo "------------------------"


				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "現在のネットワーク優先度設定: ${gl_huang}IPv4${gl_bai} 優先"
				else
					echo -e "現在のネットワーク優先度設定: ${gl_huang}IPv6${gl_bai} 優先"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 優先          2. IPv6 優先          3. IPv6 修復ツール"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "優先ネットワークを選択してください: " choice

				case $choice in
					1)
						prefer_ipv4
						;;
					2)
						rm -f /etc/gai.conf
						echo "IPv6 優先に切り替わりました"
						send_stats "已切换为 IPv6 优先"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "この機能はjhbの神によって提供されました。感謝します！"
						send_stats "ipv6修复"
						;;

					*)
						break
						;;

				esac
			done
			;;

		  11)
			clear
			ss -tulnape
			;;

		  12)
			root_use
			send_stats "设置虚拟内存"
			while true; do
				clear
				echo "仮想メモリの設定"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "現在の仮想メモリ: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 1024M を設定         2. 2048M を設定         3. 4096M を設定         4. カスタムサイズ"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択を入力してください: " choice

				case "$choice" in
				  1)
					send_stats "已设置1G虚拟内存"
					add_swap 1024

					;;
				  2)
					send_stats "已设置2G虚拟内存"
					add_swap 2048

					;;
				  3)
					send_stats "已设置4G虚拟内存"
					add_swap 4096

					;;

				  4)
					read -e -p "仮想メモリサイズを入力してください(単位 M) : " new_swap
					add_swap "$new_swap"
					send_stats "已设置自定义虚拟内存"
					;;

				  *)
					break
					;;
				esac
			done
			;;

		  13)
			  while true; do
				root_use
				send_stats "用户管理"
				echo "ユーザーリスト"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "アカウント操作"
				  echo "------------------------"
				  echo "1. 一般アカウントの作成             2. 上級アカウントの作成"
				  echo "------------------------"
				  echo "3. 最高権限を付与             4. 最高権限を剥奪"
				  echo "------------------------"
				  echo "5. アカウントの削除"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " sub_choice

				  case $sub_choice in
					  1)
					   # 提示用户输入新用户名
					   read -e -p "新しいユーザー名を入力してください: " new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "操作が完了しました。"
						  ;;

					  2)
					   # 提示用户输入新用户名
					   read -e -p "新しいユーザー名を入力してください: " new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # 赋予新用户sudo权限
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo

					   echo "操作が完了しました。"

						  ;;
					  3)
					   read -e -p "ユーザー名を入力してください: " username
					   # 赋予新用户sudo权限
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo
						  ;;
					  4)
					   read -e -p "ユーザー名を入力してください: " username
					   # 从sudoers文件中移除用户的sudo权限
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "削除するユーザー名を入力してください: " username
					   # 删除用户及其主目录
					   userdel -r "$username"
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  14)
			clear
			send_stats "用户信息生成器"
			echo "ランダムなユーザー名"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "ランダムなユーザー名 $i: $username"
			done

			echo ""
			echo "ランダムな名前"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "ランダムなユーザー名 $i: $user_name"
			done

			echo ""
			echo "ランダムな UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "ランダムな UUID $i: $uuid"
			done

			echo ""
			echo "16 文字のランダムなパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "ランダムなパスワード $i: $password"
			done

			echo ""
			echo "32 文字のランダムなパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "ランダムなパスワード $i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "システム時間情報"

				# 获取当前系统时区
				local timezone=$(current_timezone)

				# 获取当前系统时间
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 显示时区和时间
				echo "現在のシステムタイムゾーン: $timezone"
				echo "現在のシステム時刻: $current_time"

				echo ""
				echo "タイムゾーンの切り替え"
				echo "------------------------"
				echo "アジア"
				echo "1. 中国上海時間             2. 中国香港時間"
				echo "3. 日本東京時間             4. 韓国ソウル時間"
				echo "5. シンガポール時間               6. インドコルカタ時間"
				echo "7. UAE ドバイ時間           8. オーストラリア シドニー時間"
				echo "9. タイ バンコク時間"
				echo "------------------------"
				echo "ヨーロッパ"
				echo "11. イギリス ロンドン時間             12. フランス パリ時間"
				echo "13. ドイツ ベルリン時間             14. ロシア モスクワ時間"
				echo "15. オランダ ユトレヒト時間       16. スペイン マドリード時間"
				echo "------------------------"
				echo "アメリカ"
				echo "21. アメリカ 西部時間             22. アメリカ 東部時間"
				echo "23. カナダ 時間               24. メキシコ 時間"
				echo "25. ブラジル 時間                 26. アルゼンチン 時間"
				echo "------------------------"
				echo "31. UTC 世界標準時"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択を入力してください: " sub_choice


				case $sub_choice in
					1) set_timedate Asia/Shanghai ;;
					2) set_timedate Asia/Hong_Kong ;;
					3) set_timedate Asia/Tokyo ;;
					4) set_timedate Asia/Seoul ;;
					5) set_timedate Asia/Singapore ;;
					6) set_timedate Asia/Kolkata ;;
					7) set_timedate Asia/Dubai ;;
					8) set_timedate Australia/Sydney ;;
					9) set_timedate Asia/Bangkok ;;
					11) set_timedate Europe/London ;;
					12) set_timedate Europe/Paris ;;
					13) set_timedate Europe/Berlin ;;
					14) set_timedate Europe/Moscow ;;
					15) set_timedate Europe/Amsterdam ;;
					16) set_timedate Europe/Madrid ;;
					21) set_timedate America/Los_Angeles ;;
					22) set_timedate America/New_York ;;
					23) set_timedate America/Vancouver ;;
					24) set_timedate America/Mexico_City ;;
					25) set_timedate America/Sao_Paulo ;;
					26) set_timedate America/Argentina/Buenos_Aires ;;
					31) set_timedate UTC ;;
					*) break ;;
				esac
			done
			  ;;

		  16)

			bbrv3
			  ;;

		  17)
			  iptables_panel

			  ;;

		  18)
		  root_use
		  send_stats "修改主机名"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "現在のホスト名: ${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "新しいホスト名を入力してください(0 を入力すると終了) : " new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # 其他系统，如 Debian, Ubuntu, CentOS 等
					  hostnamectl set-hostname "$new_hostname"
					  sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
					  systemctl restart systemd-hostnamed
				  fi

				  if grep -q "127.0.0.1" /etc/hosts; then
					  sed -i "s/127.0.0.1 .*/127.0.0.1       $new_hostname localhost localhost.localdomain/g" /etc/hosts
				  else
					  echo "127.0.0.1       $new_hostname localhost localhost.localdomain" >> /etc/hosts
				  fi

				  if grep -q "^::1" /etc/hosts; then
					  sed -i "s/^::1 .*/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/g" /etc/hosts
				  else
					  echo "::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback" >> /etc/hosts
				  fi

				  echo "ホスト名は次のように変更されました: $new_hostname"
				  send_stats "主机名已更改"
				  sleep 1
			  else
				  echo "ログアウトしました。ホスト名は変更されていません。"
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "换系统更新源"
		  clear
		  echo "更新ソースリージョンを選択"
		  echo "LinuxMirrors 接続によるシステム更新ソースの切り替え"
		  echo "------------------------"
		  echo "1. 中国本土【デフォルト】          2. 中国本土【教育網】          3. 中国以外"
		  echo "------------------------"
		  echo "0. 前のメニューに戻る"
		  echo "------------------------"
		  read -e -p "選択を入力してください: " choice

		  case $choice in
			  1)
				  send_stats "中国大陆默认源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "中国大陆教育源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "海外源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
				  echo "キャンセルしました"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "定时任务管理"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "定期タスクリスト"
				  crontab -l
				  echo ""
				  echo "操作"
				  echo "------------------------"
				  echo "1. 定期タスクの追加              2. 定期タスクの削除              3. 定期タスクの編集"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "新しいタスクの実行コマンドを入力してください: " newquest
						  echo "------------------------"
						  echo "1. 毎月タスク                 2. 毎週末タスク"
						  echo "3. 毎日常タスク                 4. 毎時間タスク"
						  echo "------------------------"
						  read -e -p "選択を入力してください: " dingshi

						  case $dingshi in
							  1)
								  read -e -p "毎月何日にタスクを実行しますか? (1-30): " day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "週の何曜日にタスクを実行しますか? ( 0-6、0 は日曜日を表します) : " weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "タスクを実行する時間を指定してください（時、0-23）：" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "タスクを実行する分を指定してください（分、0-60）：" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "添加定时任务"
						  ;;
					  2)
						  read -e -p "削除するタスクのキーワードを入力してください:" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "删除定时任务"
						  ;;
					  3)
						  crontab -e
						  send_stats "编辑定时任务"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "本地host解析"
			  while true; do
				  clear
				  echo "ローカルホスト解析リスト"
				  echo "ここで解析比較を追加すると、動的解析は使用されなくなります。"
				  cat /etc/hosts
				  echo ""
				  echo "操作"
				  echo "------------------------"
				  echo "1.  解析の追加              2. 解析アドレスの削除"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " host_dns

				  case $host_dns in
					  1)
						  read -e -p "新しい解析レコードを入力してください。フォーマット: 110.25.5.33 kejilion.pro :" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "本地host解析新增"

						  ;;
					  2)
						  read -e -p "削除する解析内容のキーワードを入力してください:" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "本地host解析删除"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "ssh防御"
		  while true; do

				check_f2b_status
				echo -e "SSH防御プログラム $check_f2b_status"
				echo "Fail2ban は SSH のブルートフォース攻撃防止ツールです。"
				echo "公式サイト紹介: ${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. 防御プログラムのインストール"
				echo "------------------------"
				echo "2. SSH 遮断記録の表示"
				echo "3. ログのリアルタイム監視"
				echo "------------------------"
				echo "9. 防御プログラムの削除"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択を入力してください: " sub_choice
				case $sub_choice in
					1)
						f2b_install_sshd

						cd ~
						f2b_status
						break_end
						;;
					2)
						echo "------------------------"
						f2b_sshd
						echo "------------------------"
						break_end
						;;
					3)
						tail -f /var/log/fail2ban.log
						break
						;;
					9)
						remove fail2ban
						rm -rf /etc/fail2ban
						echo "Fail2ban防御プログラムが削除されました"
						break
						;;
					*)
						break
						;;
				esac
		  done
			  ;;


		  23)
			root_use
			send_stats "限流关机功能"
			while true; do
				clear
				echo "トラフィック制限シャットダウン機能"
				echo "ビデオ紹介: https://youtu.be/mOKwVzK0U6I"
				echo "------------------------------------------------"
				echo "現在のトラフィック使用状況、サーバー再起動でトラフィック計算はリセットされます！ "
				output_status
				echo -e "${gl_kjlan}合計受信: ${gl_bai}$rx"
				echo -e "${gl_kjlan}合計送信: ${gl_bai}$tx"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}現在の受信流量制限しきい値は: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}現在の送信流量制限しきい値は: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}現在、流量制限シャットダウン機能は無効です${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "システムは毎分実際のトラフィックが閾値に達したか検出します。達した場合、サーバーは自動的にシャットダウンされます！ "
				echo "------------------------"
				echo "1. トラフィック制限シャットダウン機能を有効にする          2. トラフィック制限シャットダウン機能を無効にする"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択を入力してください: " Limiting

				case "$Limiting" in
				  1)
					# 输入新的虚拟内存大小
					echo "実際のサーバーが 100G のトラフィックしかない場合、閾値を 95G に設定することで、トラフィックの誤差やオーバーフローを避けるために早期にシャットダウンできます。"
					read -e -p "インバウンドトラフィックのしきい値を入力してください（単位はG、デフォルトは100G）：" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "アウトバウンドトラフィックのしきい値を入力してください（単位はG、デフォルトは100G）：" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "トラフィックリセット日を入力してください（デフォルトは毎月1日）：" cz_day
					cz_day=${cz_day:-1}

					cd ~
					curl -Ss -o ~/Limiting_Shut_down.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh
					chmod +x ~/Limiting_Shut_down.sh
					sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
					sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					(crontab -l ; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab - > /dev/null 2>&1
					crontab -l | grep -v 'reboot' | crontab -
					(crontab -l ; echo "0 1 $cz_day * * reboot") | crontab - > /dev/null 2>&1
					echo "流量制限シャットダウンが設定されました"
					send_stats "限流关机已设置"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "流量制限シャットダウン機能は無効になりました"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "私钥登录"
			  while true; do
				  clear
			  	  echo "root秘密鍵ログインモード"
			  	  echo "ビデオ紹介: https://youtu.be/4wAUIp7pN6I?t=209"
			  	  echo "------------------------------------------------"
			  	  echo "鍵ペアが生成され、より安全なSSHログイン方法になります"
				  echo "------------------------"
				  echo "1. 新しいキーを生成する 2. 既存のキーをインポートする 3. ローカルキーを表示する"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択を入力してください: " host_dns

				  case $host_dns in
					  1)
				  		send_stats "生成新密钥"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "导入已有公钥"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "查看本机密钥"
						echo "------------------------"
						echo "公開鍵情報"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "秘密鍵情報"
						cat ~/.ssh/sshkey
						echo "------------------------"
						break_end

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  25)
			  root_use
			  send_stats "电报预警"
			  echo "TG-bot監視アラート機能"
			  echo "ビデオ紹介: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "TelegramボットAPIとアラート受信ユーザーIDを設定することで、ローカルCPU、メモリ、ハードディスク、トラフィック、SSHログインのリアルタイム監視アラートを実現できます。"
			  echo "閾値に達するとユーザーにアラートメッセージが送信されます"
			  echo -e "${gl_hui}トラフィックについて、サーバーを再起動すると再計算されます-${gl_bai}"
			  read -e -p "続行してもよろしいですか？ \(y/N\): " choice

			  case "$choice" in
				[Yy])
				  send_stats "电报预警启用"
				  cd ~
				  install nano tmux bc jq
				  check_crontab_installed
				  if [ -f ~/TG-check-notify.sh ]; then
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  else
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-check-notify.sh
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  fi
				  tmux kill-session -t TG-check-notify > /dev/null 2>&1
				  tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
				  crontab -l | grep -v '~/TG-check-notify.sh' | crontab - > /dev/null 2>&1
				  (crontab -l ; echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'") | crontab - > /dev/null 2>&1

				  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "4i$(grep '^CHAT_ID=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh
				  chmod +x ~/TG-SSH-check-notify.sh

				  # 添加到 ~/.profile 文件中
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "TG-botアラートシステムが起動しました"
				  echo -e "${gl_hui}rootディレクトリのTG-check-notify.shアラートファイルを他のマシンに配置して直接使用することもできます! ${gl_bai}"
				  ;;
				[Nn])
				  echo "キャンセルしました"
				  ;;
				*)
				  echo "無効な選択です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "修复SSH高危漏洞"
			  cd ~
			  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/upgrade_openssh9.8p1.sh
			  chmod +x ~/upgrade_openssh9.8p1.sh
			  ~/upgrade_openssh9.8p1.sh
			  rm -f ~/upgrade_openssh9.8p1.sh
			  ;;

		  27)
			  elrepo
			  ;;
		  28)
			  Kernel_optimize
			  ;;

		  29)
			  clamav
			  ;;

		  30)
			  linux_file
			  ;;

		  31)
			  linux_language
			  ;;

		  32)
			  shell_bianse
			  ;;
		  33)
			  linux_trash
			  ;;
		  34)
			  linux_backup
			  ;;
		  35)
			  ssh_manager
			  ;;
		  36)
			  disk_manager
			  ;;
		  37)
			  clear
			  send_stats "命令行历史记录"
			  get_history_file() {
				  for file in "$HOME"/.bash_history "$HOME"/.ash_history "$HOME"/.zsh_history "$HOME"/.local/share/fish/fish_history; do
					  [ -f "$file" ] && { echo "$file"; return; }
				  done
				  return 1
			  }

			  history_file=$(get_history_file) && cat -n "$history_file"
			  ;;

		  38)
			  rsync_manager
			  ;;


		  39)
			  clear
			  linux_fav
			  ;;

		  41)
			clear
			send_stats "留言板"
			echo "KejiLion公式掲示板にアクセスして、スクリプトに関するご意見をお聞かせください！"
			echo "https://board.kejilion.pro"
			echo "公開パスワード: kejilion.sh"
			  ;;

		  66)

			  root_use
			  send_stats "一条龙调优"
			  echo "オールインワンシステムチューニング"
			  echo "------------------------------------------------"
			  echo "以下の内容を操作・最適化します"
			  echo "1. システムを最新版に更新する"
			  echo "2. システムのゴミファイルをクリーンアップする"
			  echo -e "3.  仮想メモリの設定 ${gl_huang}1G${gl_bai}"
			  echo -e "4.  SSHポート番号を ${gl_huang}5522${gl_bai} に設定"
			  echo -e "5.  すべてのポートを開放"
			  echo -e "6.  ${gl_huang}BBR${gl_bai} アクセラレーションを有効にする"
			  echo -e "7.  タイムゾーンを${gl_huang}上海${gl_bai}に設定"
			  echo -e "8.  DNSアドレスの自動最適化 ${gl_huang}中国地域以外: 1.1.1.1 8.8.8.8   中国地域: 223.5.5.5${gl_bai}"
			  echo -e "9.  基本ツールのインストール ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10. Linuxシステムカーネルパラメータの最適化を ${gl_huang}バランス最適化モード${gl_bai} に切り替える"
			  echo "------------------------------------------------"
			  read -e -p "ワンクリックメンテナンスを確定しますか？ \(y/N\):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "一条龙调优启动"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 01/10. システムを最新の状態に更新"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 02/10. システムのジャンクファイルをクリーンアップ"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 03/10. 仮想メモリを${gl_huang}1G${gl_bai}に設定"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 04/10. SSHポートを${gl_huang}5522${gl_bai}に設定"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 05/10. 全ポートを開放"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 06/10. ${gl_huang}BBR${gl_bai}アクセラレーションを有効にする"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 07/10. タイムゾーンを${gl_huang}上海${gl_bai}に設定"

				  echo "------------------------------------------------"
				  auto_optimize_dns
				  echo -e "[${gl_lv}OK${gl_bai}] 08/10. DNSアドレスを自動最適化${gl_huang}中国以外: 1.1.1.1 8.8.8.8   中国: 223.5.5.5${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 09/10. 基本ツールをインストール${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10. Linuxシステムカーネルパラメータの最適化"
				  echo -e "${gl_lv}一元的なシステムチューニングが完了しました${gl_bai}"

				  ;;
				[Nn])
				  echo "キャンセルしました"
				  ;;
				*)
				  echo "無効な選択です。Y または N を入力してください。"
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "重启系统"
			  server_reboot
			  ;;
		  100)

			root_use
			while true; do
			  clear
			  if grep -q '^ENABLE_STATS="true"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_lv}データ収集中${gl_bai}"
			  elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_hui}収集はオフです${gl_bai}"
			  else
			  	local status_message="未定義の状態"
			  fi

			  echo "プライバシーとセキュリティ"
			  echo "スクリプトは、ユーザーの機能使用データを収集し、スクリプト体験を最適化し、より楽しく実用的な機能を作成します。"
			  echo "スクリプトバージョン番号、使用時間、システムバージョン、CPUアーキテクチャ、マシンが属する国、および使用される機能名が収集されます。"
			  echo "------------------------------------------------"
			  echo -e "現在の状態: $status_message"
			  echo "--------------------"
			  echo "1. 収集を開始"
			  echo "2. 収集を停止"
			  echo "--------------------"
			  echo "0. 前のメニューに戻る"
			  echo "--------------------"
			  read -e -p "選択を入力してください: " sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "収集を開始しました"
					  send_stats "隐私与安全已开启采集"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "収集を停止しました"
					  send_stats "隐私与安全已关闭采集"
					  ;;
				  *)
					  break
					  ;;
			  esac
			done
			  ;;

		  101)
			  clear
			  k_info
			  ;;

		  102)
			  clear
			  send_stats "卸载科技lion脚本"
			  echo "KejiLionスクリプトのアンインストール"
			  echo "------------------------------------------------"
			  echo "KejiLionスクリプトを完全にアンインストールしますが、他の機能には影響しません。"
			  read -e -p "続行してもよろしいですか？ \(y/N\): " choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "スクリプトはアンインストールされました。さようなら！"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "キャンセルしました"
				  ;;
				*)
				  echo "無効な選択です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "文件管理器"
	while true; do
		clear
		echo "ファイルマネージャー"
		echo "------------------------"
		echo "現在のパス"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. ディレクトリに入る 2. ディレクトリを作成 3. ディレクトリ権限を変更 4. ディレクトリ名を変更"
		echo "5. ディレクトリを削除 6. 上位メニューディレクトリに戻る"
		echo "------------------------"
		echo "11. ファイルを作成 12. ファイルを編集 13. ファイル権限を変更 14. ファイル名を変更"
		echo "15. ファイルを削除"
		echo "------------------------"
		echo "21. ファイルディレクトリを圧縮 22. ファイルディレクトリを解凍 23. ファイルディレクトリを移動 24. ファイルディレクトリをコピー"
		echo "25. 他のサーバーにファイルを転送"
		echo "------------------------"
		echo "0. 上位メニューに戻る"
		echo "------------------------"
		read -e -p "選択を入力してください: " Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "ディレクトリ名を入力してください:" dirname
				cd "$dirname" 2>/dev/null || echo "ディレクトリに入れません"
				send_stats "进入目录"
				;;
			2)  # 创建目录
				read -e -p "作成するディレクトリ名を入力してください:" dirname
				mkdir -p "$dirname" && echo "ディレクトリが作成されました" || echo "作成失敗"
				send_stats "创建目录"
				;;
			3)  # 修改目录权限
				read -e -p "ディレクトリ名を入力してください:" dirname
				read -e -p "権限を入力してください（例: 755）：" perm
				chmod "$perm" "$dirname" && echo "権限が変更されました" || echo "変更失敗"
				send_stats "修改目录权限"
				;;
			4)  # 重命名目录
				read -e -p "現在のディレクトリ名を入力してください:" current_name
				read -e -p "新しいディレクトリ名を入力してください:" new_name
				mv "$current_name" "$new_name" && echo "ディレクトリがリネームされました" || echo "リネーム失敗"
				send_stats "重命名目录"
				;;
			5)  # 删除目录
				read -e -p "削除するディレクトリ名を入力してください:" dirname
				rm -rf "$dirname" && echo "ディレクトリが削除されました" || echo "削除失敗"
				send_stats "删除目录"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "返回上一级选单目录"
				;;
			11) # 创建文件
				read -e -p "作成するファイル名を入力してください:" filename
				touch "$filename" && echo "ファイルが作成されました" || echo "作成失敗"
				send_stats "创建文件"
				;;
			12) # 编辑文件
				read -e -p "編集するファイル名を入力してください:" filename
				install nano
				nano "$filename"
				send_stats "编辑文件"
				;;
			13) # 修改文件权限
				read -e -p "ファイル名を入力してください:" filename
				read -e -p "権限を入力してください（例: 755）：" perm
				chmod "$perm" "$filename" && echo "権限が変更されました" || echo "変更失敗"
				send_stats "修改文件权限"
				;;
			14) # 重命名文件
				read -e -p "現在のファイル名を入力してください:" current_name
				read -e -p "新しいファイル名を入力してください:" new_name
				mv "$current_name" "$new_name" && echo "ファイルがリネームされました" || echo "リネーム失敗"
				send_stats "重命名文件"
				;;
			15) # 删除文件
				read -e -p "削除するファイル名を入力してください: " filename
				rm -f "$filename" && echo "ファイルが削除されました" || echo "削除失敗"
				send_stats "删除文件"
				;;
			21) # 压缩文件/目录
				read -e -p "圧縮するファイル/ディレクトリ名を入力してください: " name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "$name.tar.gz に圧縮しました" || echo "圧縮失敗"
				send_stats "压缩文件/目录"
				;;
			22) # 解压文件/目录
				read -e -p "解凍するファイル名を入力してください (.tar.gz): " filename
				install tar
				tar -xzvf "$filename" && echo "$filename を解凍しました" || echo "解凍失敗"
				send_stats "解压文件/目录"
				;;

			23) # 移动文件或目录
				read -e -p "移動するファイルまたはディレクトリのパスを入力してください: " src_path
				if [ ! -e "$src_path" ]; then
					echo "エラー: ファイルまたはディレクトリが存在しません。"
					send_stats "移动文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "宛先パスを入力してください（新しいファイル名またはディレクトリ名を含む） : " dest_path
				if [ -z "$dest_path" ]; then
					echo "エラー: 移動先パスを入力してください。"
					send_stats "移动文件或目录失败: 目标路径未指定"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "ファイルまたはディレクトリが $dest_path に移動されました" || echo "ファイルまたはディレクトリの移動に失敗しました"
				send_stats "移动文件或目录"
				;;


		   24) # 复制文件目录
				read -e -p "コピーするファイルまたはディレクトリのパスを入力してください: " src_path
				if [ ! -e "$src_path" ]; then
					echo "エラー: ファイルまたはディレクトリが存在しません。"
					send_stats "复制文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "宛先パスを入力してください（新しいファイル名またはディレクトリ名を含む） : " dest_path
				if [ -z "$dest_path" ]; then
					echo "エラー: 移動先パスを入力してください。"
					send_stats "复制文件或目录失败: 目标路径未指定"
					continue
				fi

				# 使用 -r 选项以递归方式复制目录
				cp -r "$src_path" "$dest_path" && echo "ファイルまたはディレクトリが $dest_path にコピーされました" || echo "ファイルまたはディレクトリのコピーに失敗しました"
				send_stats "复制文件或目录"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "転送するファイルパスを入力してください: " file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "エラー: ファイルが存在しません。"
					send_stats "传送文件失败: 文件不存在"
					continue
				fi

				read -e -p "リモートサーバーのIPを入力してください:" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "エラー: リモートサーバーのIPを入力してください。"
					send_stats "传送文件失败: 未输入远端服务器IP"
					continue
				fi

				read -e -p "リモートサーバーのユーザー名を入力してください（デフォルトはroot） : " remote_user
				remote_user=${remote_user:-root}

				read -e -p "リモートサーバーのパスワードを入力してください: " -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "エラー: リモートサーバーのパスワードを入力してください。"
					send_stats "传送文件失败: 未输入远端服务器密码"
					continue
				fi

				read -e -p "ログインポート番号を入力してください（デフォルトは22） : " remote_port
				remote_port=${remote_port:-22}

				# 清除已知主机的旧条目
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# 使用scp传输文件
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "ファイルはリモートサーバーの/homeディレクトリに転送されました。"
					send_stats "文件传送成功"
				else
					echo "ファイルの転送に失敗しました。"
					send_stats "文件传送失败"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "返回上一级选单菜单"
				break
				;;
			*)  # 处理无效输入
				echo "無効な選択です。再入力してください"
				send_stats "无效选择"
				;;
		esac
	done
}






cluster_python3() {
	install python3 python3-paramiko
	cd ~/cluster/
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
	python3 ~/cluster/$py_task
}


run_commands_on_servers() {

	install sshpass

	local SERVERS_FILE="$HOME/cluster/servers.py"
	local SERVERS=$(grep -oP '{"name": "\K[^"]+|"hostname": "\K[^"]+|"port": \K[^,]+|"username": "\K[^"]+|"password": "\K[^"]+' "$SERVERS_FILE")

	# 将提取的信息转换为数组
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# 遍历服务器并执行命令
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}$name ($hostname) に接続中...${gl_bai}"
		# sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
		sshpass -p "$password" ssh -t -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
	done
	echo
	break_end

}


linux_cluster() {
mkdir cluster
if [ ! -f ~/cluster/servers.py ]; then
	cat > ~/cluster/servers.py << EOF
servers = [

]
EOF
fi

while true; do
	  clear
	  send_stats "集群控制中心"
	  echo "サーバークラスター制御"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}サーバーリスト管理${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}サーバーを追加                           ${gl_kjlan}2.  ${gl_bai}サーバーを削除              ${gl_kjlan}3.  ${gl_bai}サーバーを編集"
	  echo -e "${gl_kjlan}4.  ${gl_bai}クラスターをバックアップ                 ${gl_kjlan}5.  ${gl_bai}クラスターを復元"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}バッチタスクの実行${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}KejiLionスクリプトをインストール         ${gl_kjlan}12. ${gl_bai}システムを更新              ${gl_kjlan}13. ${gl_bai}システムをクリーンアップ"
	  echo -e "${gl_kjlan}14. ${gl_bai}Dockerをインストール                     ${gl_kjlan}15. ${gl_bai}BBRv3をインストール         ${gl_kjlan}16. ${gl_bai} 1G仮想メモリを設定"
	  echo -e "${gl_kjlan}17. ${gl_bai}上海にタイムゾーンを設定                 ${gl_kjlan}18. ${gl_bai}全ポートを開放              ${gl_kjlan}51. ${gl_bai}カスタムコマンド"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください: " sub_choice

	  case $sub_choice in
		  1)
			  send_stats "添加集群服务器"
			  read -e -p "サーバー名: " server_name
			  read -e -p "サーバーIP: " server_ip
			  read -e -p "サーバーポート（22） : " server_port
			  local server_port=${server_port:-22}
			  read -e -p "サーバーユーザー名（root） : " server_username
			  local server_username=${server_username:-root}
			  read -e -p "サーバーパスワード: " server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "删除集群服务器"
			  read -e -p "削除するキーワードを入力してください: " rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "编辑集群服务器"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "备份集群"
			  echo -e "${gl_huang}/root/cluster/servers.py${gl_bai}ファイルをダウンロードして、バックアップを完了してください！ "
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "还原集群"
			  echo "servers.pyをアップロードしてください。何かキーを押すとアップロードが開始されます！"
			  echo -e "${gl_huang}servers.py${gl_bai}ファイルを${gl_huang}/root/cluster/${gl_bai}にアップロードして、復元を完了してください！ "
			  break_end
			  ;;

		  11)
			  local py_task="install_kejilion.py"
			  cluster_python3
			  ;;
		  12)
			  run_commands_on_servers "k update"
			  ;;
		  13)
			  run_commands_on_servers "k clean"
			  ;;
		  14)
			  run_commands_on_servers "k docker install"
			  ;;
		  15)
			  run_commands_on_servers "k bbr3"
			  ;;
		  16)
			  run_commands_on_servers "k swap 1024"
			  ;;
		  17)
			  run_commands_on_servers "k time Asia/Shanghai"
			  ;;
		  18)
			  run_commands_on_servers "k iptables_open"
			  ;;

		  51)
			  send_stats "自定义执行命令"
			  read -e -p "バッチ実行するコマンドを入力してください: " mingling
			  run_commands_on_servers "${mingling}"
			  ;;

		  *)
			  kejilion
			  ;;
	  esac
done

}




kejilion_Affiliates() {

clear
send_stats "广告专栏"
echo "広告コラム"
echo "------------------------"
echo "ユーザーに、よりシンプルでエレガントなプロモーションと購入体験を提供します！"
echo ""
echo -e "サーバー特典"
echo "------------------------"
echo -e "${gl_lan}ライカクラウド 香港CN2 GIA 韓国ISP アメリカCN2 GIA キャンペーン${gl_bai}"
echo -e "${gl_bai}URL: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd 10.99ドル/年 アメリカ 1コア 1Gメモリ 20G HDD 月1Tトラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52.7ドル/年 アメリカ 1コア 4Gメモリ 50G HDD 月4Tトラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}搬瓦工 49ドル/四半期 アメリカCN2GIA 日本ソフトバンク 2コア 1Gメモリ 20G HDD 月1Tトラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT 28ドル/四半期 アメリカCN2GIA 1コア 2Gメモリ 20G HDD 月800Gトラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS 6.9ドル/月 東京ソフトバンク 2コア 1Gメモリ 20G HDD 月1Tトラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}VPSその他の人気オファー${gl_bai}"
echo -e "${gl_bai}URL: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "ドメイン名特典"
echo "------------------------"
echo -e "${gl_lan}GNAME 初年COMドメイン名 8.8ドル 初年CCドメイン名 6.68ドル${gl_bai}"
echo -e "${gl_bai}URL: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "KejiLionグッズ"
echo "------------------------"
echo -e "${gl_kjlan}Bilibili: ${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}YouTube: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}公式サイト: ${gl_bai}https://kejilion.pro/             ${gl_kjlan}ナビゲーション: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}ブログ: ${gl_bai}https://blog.kejilion.pro/            ${gl_kjlan}ソフトウェアセンター: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}スクリプト公式サイト: ${gl_bai}https://kejilion.sh     ${gl_kjlan}GitHubアドレス: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "脚本更新"
cd ~
while true; do
	clear
	echo "更新ログ"
	echo "------------------------"
	echo "全ログ: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}最新バージョンです！ ${gl_huang}v$sh_v${gl_bai}"
		send_stats "脚本已经最新了，无需更新"
	else
		echo "新バージョンが見つかりました！"
		echo -e "現在のバージョン v$sh_v        最新バージョン ${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}自動更新が有効になっています。スクリプトは毎日午前2時に自動更新されます！ ${gl_bai}"
	fi

	echo "------------------------"
	echo "1. 今すぐ更新            2. 自動更新を有効にする            3. 自動更新を無効にする"
	echo "------------------------"
	echo "0. メインメニューに戻る"
	echo "------------------------"
	read -e -p "選択を入力してください: " choice
	case "$choice" in
		1)
			clear
			local country=$(curl -s ipinfo.io/country)
			if [ "$country" = "CN" ]; then
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/cn/kejilion.sh && chmod +x kejilion.sh
			else
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh
			fi
			canshu_v6
			CheckFirstRun_true
			yinsiyuanquan2
			cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1
			echo -e "${gl_lv}スクリプトが最新バージョンに更新されました！ ${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "脚本已经最新$sh_v_new"
			break_end
			~/kejilion.sh
			exit
			;;
		2)
			clear
			local country=$(curl -s ipinfo.io/country)
			local ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
			if [ "$country" = "CN" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"CN\"/g' ./kejilion.sh"
			elif [ -n "$ipv6_address" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"V6\"/g' ./kejilion.sh"
			else
				SH_Update_task="curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh"
			fi
			check_crontab_installed
			(crontab -l | grep -v "kejilion.sh") | crontab -
			# (crontab -l 2>/dev/null; echo "0 2 * * * bash -c \"$SH_Update_task\"") | crontab -
			(crontab -l 2>/dev/null; echo "$(shuf -i 0-59 -n 1) 2 * * * bash -c \"$SH_Update_task\"") | crontab -
			echo -e "${gl_lv}自動更新が有効になっています。スクリプトは毎日午前2時に自動更新されます！ ${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}自動更新がオフになっています${gl_bai}"
			send_stats "关闭脚本自动更新"
			break_end
			;;
		*)
			kejilion_sh
			;;
	esac
done

}





kejilion_sh() {
while true; do
clear
echo -e "${gl_kjlan}"
echo "╦╔═╔═╗ ╦╦╦  ╦╔═╗╔╗╔ ╔═╗╦ ╦"
echo "╠╩╗║╣  ║║║  ║║ ║║║║ ╚═╗╠═╣"
echo "╩ ╩╚═╝╚╝╩╩═╝╩╚═╝╝╚╝o╚═╝╩ ╩"
echo -e "テクノロジー ライオン スクリプト ツールボックス v$sh_v (AI による翻訳)"
echo -e "コマンドラインで ${gl_huang}k${gl_kjlan} と入力すると、スクリプトをすばやく起動できます${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}システム情報クエリ"
echo -e "${gl_kjlan}2.   ${gl_bai}システムアップデート"
echo -e "${gl_kjlan}3.   ${gl_bai}システムクリーニング"
echo -e "${gl_kjlan}4.   ${gl_bai}基本ツール"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR管理"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker管理"
echo -e "${gl_kjlan}7.   ${gl_bai}WARP管理"
echo -e "${gl_kjlan}8.   ${gl_bai}テストスクリプトコレクション"
echo -e "${gl_kjlan}9.   ${gl_bai}甲骨文クラウドスクリプトコレクション"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP サイト構築"
echo -e "${gl_kjlan}11.  ${gl_bai}アプリマーケット"
echo -e "${gl_kjlan}12.  ${gl_bai}バックグラウンドワークスペース"
echo -e "${gl_kjlan}13.  ${gl_bai}システムツール"
echo -e "${gl_kjlan}14.  ${gl_bai}サーバークラスター制御"
echo -e "${gl_kjlan}15.  ${gl_bai}広告コラム"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}幻獣パルワールドサーバー構築スクリプト"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}スクリプト更新"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}スクリプト終了"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "選択を入力してください: " choice

case $choice in
  1) linux_info ;;
  2) clear ; send_stats "系统更新" ; linux_update ;;
  3) clear ; send_stats "系统清理" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "warp管理" ; install wget
	wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh ; bash menu.sh [option] [lisence/url/token]
	;;
  8) linux_test ;;
  9) linux_Oracle ;;
  10) linux_ldnmp ;;
  11) linux_panel ;;
  12) linux_work ;;
  13) linux_Settings ;;
  14) linux_cluster ;;
  15) kejilion_Affiliates ;;
  p) send_stats "幻兽帕鲁开服脚本" ; cd ~
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "無効な入力！" ;;
esac
	break_end
done
}


k_info() {
send_stats "k命令参考用例"
echo "-------------------"
echo "ビデオ紹介: https://youtu.be/wQdmKuL0hdk"
echo "以下にkコマンドの参考例を示します:"
echo "スクリプトの起動                        k"
echo "パッケージのインストール                k install nano wget | k add nano wget"
echo "パッケージのアンインストール            k remove nano wget | k del nano wget | k uninstall nano wget"
echo "システムの更新                          k update"
echo "システムゴミのクリーニング              k clean"
echo "システム再インストールパネル            k dd"
echo "BBRv3 コントロールパネル                k bbr3 | k bbrv3"
echo "コアチューニングパネル                  k nhyh"
echo "仮想メモリ設定                          k swap 2048"
echo "仮想タイムゾーン設定                    k time Asia/Shanghai"
echo "システムゴミ箱                          k trash | k hsz"
echo "システムバックアップ機能                k backup | k bf"
echo "SSHリモート接続ツール                   k ssh"
echo "rsyncリモート同期ツール                 k rsync"
echo "ディスク管理ツール                      k disk"
echo "内部ネットワーク貫通（サーバー側）      k frps"
echo "内部ネットワーク貫通（クライアント側）  k frpc"
echo "ソフトウェア起動                        k start sshd"
echo "ソフトウェア停止                        k stop sshd"
echo "ソフトウェア再起動                      k restart sshd"
echo "ソフトウェア状態確認                    k status sshd"
echo "ソフトウェア起動時自動起動              k enable docker | k autostart docke"
echo "ドメイン証明書申請                      k ssl"
echo "ドメイン証明書有効期限確認              k ssl ps"
echo "Docker管理平面                          k docker"
echo "Docker 環境インストール                 k docker install"
echo "Docker コンテナ管理                     k docker ps"
echo "Docker イメージ管理                     k docker img"
echo "LDNMP サイト管理                        k web"
echo "LDNMP キャッシュクリア                  k web cache"
echo "WordPressのインストール                 k wp |k wordpress |k wp xxx.com"
echo "リバースプロキシのインストール          k fd |k rp |k fd xxx.com"
echo "ロードバランサーのインストール          k loadbalance"
echo "L4ロードバランサーのインストール        k stream"
echo "ファイアウォールパネル                  k fhq"
echo "ポートを開く                            k dkdk 8080"
echo "ポートを閉じる                          k gbdk 7800"
echo "IPを許可する                            k fxip 127.0.0.0/8"
echo "IPをブロックする                        k zzip 177.5.25.36"
echo "コマンドお気に入り                      k fav"
echo "アプリケーションマーケット管理          k app"
echo "アプリケーション番号ショートカット管理  k app 26 | k app 1panel | k app npm"
echo "システム情報表示                        k info"
}



if [ "$#" -eq 0 ]; then
	# 如果没有参数，运行交互式逻辑
	kejilion_sh
else
	# 如果有参数，执行相应函数
	case $1 in
		install|add|安装)
			shift
			send_stats "安装软件"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "卸载软件"
			remove "$@"
			;;
		update|更新)
			linux_update
			;;
		clean|清理)
			linux_clean
			;;
		dd|重装)
			dd_xitong
			;;
		bbr3|bbrv3)
			bbrv3
			;;
		nhyh|内核优化)
			Kernel_optimize
			;;
		trash|hsz|回收站)
			linux_trash
			;;
		backup|bf|备份)
			linux_backup
			;;
		ssh|远程连接)
			ssh_manager
			;;

		rsync|远程同步)
			rsync_manager
			;;

		rsync_run)
			shift
			send_stats "定时rsync同步"
			run_task "$@"
			;;

		disk|硬盘管理)
			disk_manager
			;;

		wp|wordpress)
			shift
			ldnmp_wp "$@"

			;;
		fd|rp|反代)
			shift
			ldnmp_Proxy "$@"
	  		find_container_by_host_port "$port"
	  		if [ -z "$docker_name" ]; then
	  		  close_port "$port"
			  echo "IP+ポートがこのサービスへのアクセスをブロックしました"
	  		else
			  ip_address
	  		  block_container_port "$docker_name" "$ipv4_address"
	  		fi
			;;

		loadbalance|负载均衡)
			ldnmp_Proxy_backend
			;;


		stream|L4负载均衡)
			ldnmp_Proxy_backend_stream
			;;

		swap)
			shift
			send_stats "快速设置虚拟内存"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "快速设置时区"
			set_timedate "$@"
			;;


		iptables_open)
			iptables_open
			;;

		frps)
			frps_panel
			;;

		frpc)
			frpc_panel
			;;


		打开端口|dkdk)
			shift
			open_port "$@"
			;;

		关闭端口|gbdk)
			shift
			close_port "$@"
			;;

		放行IP|fxip)
			shift
			allow_ip "$@"
			;;

		阻止IP|zzip)
			shift
			block_ip "$@"
			;;

		防火墙|fhq)
			iptables_panel
			;;

		命令收藏夹|fav)
			linux_fav
			;;

		status|状态)
			shift
			send_stats "软件状态查看"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "软件启动"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "软件暂停"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "软件重启"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "软件开机自启"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "查看证书状态"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "快速申请证书"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "快速申请证书"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "快捷安装docker"
					install_docker
					;;
				ps|容器)
					send_stats "快捷容器管理"
					docker_ps
					;;
				img|镜像)
					send_stats "快捷镜像管理"
					docker_image
					;;
				*)
					linux_docker
					;;
			esac
			;;

		web)
		   shift
			if [ "$1" = "cache" ]; then
				web_cache
			elif [ "$1" = "sec" ]; then
				web_security
			elif [ "$1" = "opt" ]; then
				web_optimization
			elif [ -z "$1" ]; then
				ldnmp_web_status
			else
				k_info
			fi
			;;


		app)
			shift
			send_stats "应用$@"
			linux_panel "$@"
			;;


		info)
			linux_info
			;;

		*)
			k_info
			;;
	esac
fi
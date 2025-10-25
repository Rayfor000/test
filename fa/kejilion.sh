#!/bin/bash
sh_v="4.2.0"

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
		zhushi=1 # 0 表示执行，1 表示不执行
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
	if grep -q '^canshu="V6"' /usr/local/bin/k >/dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/kejilion.sh
	fi
}

CheckFirstRun_true() {
	if grep -q '^permission_granted="true"' /usr/local/bin/k >/dev/null 2>&1; then
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

	if grep -q '^ENABLE_STATS="false"' /usr/local/bin/k >/dev/null 2>&1; then
		sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
	fi

}

canshu_v6
CheckFirstRun_true
yinsiyuanquan2

sed -i '/^alias k=/d' ~/.bashrc >/dev/null 2>&1
sed -i '/^alias k=/d' ~/.profile >/dev/null 2>&1
sed -i '/^alias k=/d' ~/.bash_profile >/dev/null 2>&1
cp -f ./kejilion.sh ~/kejilion.sh >/dev/null 2>&1
cp -f ~/kejilion.sh /usr/local/bin/k >/dev/null 2>&1

CheckFirstRun_false() {
	if grep -q '^permission_granted="false"' /usr/local/bin/k >/dev/null 2>&1; then
		UserLicenseAgreement
	fi
}

# 提示用户同意条款
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}به جعبه ابزار اسکریپت شیر ​​فناوری خوش آمدید ${gl_bai}"
	echo "هنگام استفاده از اسکریپت برای اولین بار، لطفا توافقنامه مجوز کاربر را بخوانید و با آن موافقت کنید."
	echo "قرارداد مجوز کاربر: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "آیا با شرایط فوق موافقید؟ (y/N):" user_input

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
		ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' ||
			hostname -I 2>/dev/null | awk '{print $1}' ||
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
		echo "هیچ پارامتر بسته ارائه نشده است!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}در حال نصب $package...${gl_bai}"
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
				echo "مدیر بسته ناشناس!"
				return 1
			fi
		fi
	done
}

check_disk_space() {
	local required_gb=$1
	local path=${2:-/}

	local required_space_mb=$((required_gb * 1024))
	local available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

	if [ "$available_space_mb" -lt "$required_space_mb" ]; then
		echo -e "${gl_huang} نکته: ${gl_bai} فضای دیسک کافی نیست!"
		echo "فضای موجود فعلی: $((available_space_mb / 1024))G"
		echo "حداقل فضای مورد نیاز: ${required_gb}G"
		echo "نصب نمی تواند ادامه یابد. لطفاً فضای دیسک را پاک کنید و دوباره امتحان کنید."
		send_stats "磁盘空间不足"
		break_end
		kejilion
	fi
}

install_dependency() {
	install wget unzip tar jq grep
}

remove() {
	if [ $# -eq 0 ]; then
		echo "هیچ پارامتر بسته ارائه نشده است!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang} در حال حذف نصب $package...${gl_bai}"
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
			echo "مدیر بسته ناشناس!"
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
		echo "$1 سرویس دوباره راه اندازی شده است."
	else
		echo "خطا: راه اندازی مجدد سرویس $1 انجام نشد."
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "سرویس $1 شروع شد."
	else
		echo "خطا: سرویس $1 شروع نشد."
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "سرویس $1 متوقف شده است."
	else
		echo "خطا: سرویس $1 متوقف نشد."
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "وضعیت سرویس $1 نشان داده شده است."
	else
		echo "خطا: نمایش وضعیت سرویس $1 ممکن نیست."
	fi
}

enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
		/bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME تنظیم شده است که در هنگام بوت شروع شود."
}

break_end() {
	echo -e "${gl_lv} عملیات تکمیل شد ${gl_bai}"
	echo "برای ادامه هر کلیدی را فشار دهید..."
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
		cat >/etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
	"https://docker-0.unsee.tech",
	"https://docker.1panel.live",
	"https://registry.dockermirror.com",
	"https://docker.imgdb.de",
	"https://docker.m.daocloud.io",
	"https://hub.firefly.store",
	"https://hub.littlediary.cn",
	"https://hub.rat.dev",
	"https://dhub.kubesre.xyz",
	"https://cjie.eu.org",
	"https://docker.1panelproxy.com",
	"https://docker.hlmirror.com",
	"https://hub.fast360.xyz",
	"https://dockerpull.cn",
	"https://cr.laoyou.ip-ddns.com",
	"https://docker.melikeme.cn",
	"https://docker.kejilion.pro"
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
	echo -e "${gl_huang}نصب محیط داکر...${gl_bai}"
	if [ -f /etc/os-release ] && grep -q "Fedora" /etc/os-release; then
		install_add_docker_guanfang
	elif command -v dnf &>/dev/null; then
		dnf update -y
		dnf install -y yum-utils device-mapper-persistent-data lvm2
		rm -f /etc/yum.repos.d/docker*.repo >/dev/null
		country=$(curl -s ipinfo.io/country)
		arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo | tee /etc/yum.repos.d/docker-ce.repo >/dev/null
		else
			yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null
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
				sed -i '/^deb \[arch=amd64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
			fi
		else
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
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
		echo "لیست کانتینر داکر"
		docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
		echo ""
		echo "عملیات کانتینری"
		echo "------------------------"
		echo "1. یک ظرف جدید ایجاد کنید"
		echo "------------------------"
		echo "2. کانتینر مشخص شده را راه اندازی کنید 6. همه کانتینرها را راه اندازی کنید"
		echo "3. کانتینر مشخص شده را متوقف کنید 7. همه کانتینرها را متوقف کنید"
		echo "4. محفظه مشخص شده را حذف کنید 8. همه کانتینرها را حذف کنید"
		echo "5. کانتینر مشخص شده را مجددا راه اندازی کنید. 9. همه کانتینرها را مجددا راه اندازی کنید"
		echo "------------------------"
		echo "11. ظرف مشخص شده را وارد کنید 12. گزارش کانتینر را مشاهده کنید"
		echo "13. بررسی شبکه کانتینر 14. بررسی اشغال کانتینر"
		echo "------------------------"
		echo "15. دسترسی به پورت کانتینر را فعال کنید 16. دسترسی پورت کانتینر را ببندید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "لطفا دستور ایجاد را وارد کنید:" dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			read -e -p "لطفاً نام کانتینر را وارد کنید (لطفاً نام چند کانتینر را با فاصله جدا کنید):" dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "لطفاً نام کانتینر را وارد کنید (لطفاً نام چند کانتینر را با فاصله جدا کنید):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			read -e -p "لطفاً نام کانتینر را وارد کنید (لطفاً نام چند کانتینر را با فاصله جدا کنید):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			read -e -p "لطفاً نام کانتینر را وارد کنید (لطفاً نام چند کانتینر را با فاصله جدا کنید):" dockername
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
			read -e -p "$(echo -e "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می خواهید همه کانتینرها را حذف کنید؟ (y/N):")" choice
			case "$choice" in
			[Yy])
				docker rm -f $(docker ps -a -q)
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			read -e -p "لطفا نام کانتینر را وارد کنید:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			read -e -p "لطفا نام کانتینر را وارد کنید:" dockername
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
				done <<<"$network_info"
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
			read -e -p "لطفا نام کانتینر را وارد کنید:" docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "阻止容器端口访问"
			read -e -p "لطفا نام کانتینر را وارد کنید:" docker_name
			ip_address
			block_container_port "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		*)
			break # 跳出循环，退出菜单
			;;
		esac
	done
}

docker_image() {
	while true; do
		clear
		send_stats "Docker镜像管理"
		echo "لیست تصاویر داکر"
		docker image ls
		echo ""
		echo "عملیات آینه ای"
		echo "------------------------"
		echo "1. تصویر مشخص شده را دریافت کنید 3. تصویر مشخص شده را حذف کنید"
		echo "2. به روز رسانی تصویر مشخص شده 4. حذف تمام تصاویر"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		case $sub_choice in
		1)
			send_stats "拉取镜像"
			read -e -p "لطفا نام تصویر را وارد کنید (لطفا نام چند تصویر را با فاصله جدا کنید):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang} در حال دریافت تصویر است: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			read -e -p "لطفا نام تصویر را وارد کنید (لطفا نام چند تصویر را با فاصله جدا کنید):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang} در حال به روز رسانی تصویر است: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			read -e -p "لطفا نام تصویر را وارد کنید (لطفا نام چند تصویر را با فاصله جدا کنید):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			read -e -p "$(echo -e "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می خواهید همه تصاویر را حذف کنید؟ (y/N):")" choice
			case "$choice" in
			[Yy])
				docker rmi -f $(docker images -q)
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;
		*)
			break # 跳出循环，退出菜单
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
		ubuntu | debian | kali)
			apt update
			apt install -y cron
			systemctl enable cron
			systemctl start cron
			;;
		centos | rhel | almalinux | rocky | fedora)
			yum install -y cronie
			systemctl enable crond
			systemctl start crond
			;;
		alpine)
			apk add --no-cache cronie
			rc-update add crond
			rc-service crond start
			;;
		arch | manjaro)
			pacman -S --noconfirm cronie
			systemctl enable cronie
			systemctl start cronie
			;;
		opensuse | suse | opensuse-tumbleweed)
			zypper install -y cron
			systemctl enable cron
			systemctl start cron
			;;
		iStoreOS | openwrt | ImmortalWrt | lede)
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
			echo "توزیع پشتیبانی نشده: $ID"
			return
			;;
		esac
	else
		echo "قادر به تعیین سیستم عامل نیست."
		return
	fi

	echo -e "${gl_lv}crontab نصب شده است و سرویس cron در حال اجرا است. ${gl_bai}"
}

docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 检查配置文件是否存在，如果不存在则创建文件并写入默认设置
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . >"$CONFIG_FILE"
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
			echo -e "${gl_huang} در حال حاضر دسترسی ipv6 فعال دارد ${gl_bai}"
		else
			echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
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
		echo -e "فایل پیکربندی ${gl_hong} وجود ندارد ${gl_bai}"
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
		echo -e "${gl_huang} دسترسی ipv6 در حال حاضر بسته است ${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang} با موفقیت دسترسی ipv6 به ${gl_bai} را بسته است"
	fi
}

save_iptables_rules() {
	mkdir -p /etc/iptables
	touch /etc/iptables/rules.v4
	iptables-save >/etc/iptables/rules.v4
	check_crontab_installed
	crontab -l | grep -v 'iptables-restore' | crontab - >/dev/null 2>&1
	(
		crontab -l
		echo '@reboot iptables-restore < /etc/iptables/rules.v4'
	) | crontab - >/dev/null 2>&1

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
	local ports=($@) # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "لطفا حداقل یک شماره پورت ارائه دهید"
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
			echo "پورت $port باز شد"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}

close_port() {
	local ports=($@) # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "لطفا حداقل یک شماره پورت ارائه دهید"
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
			echo "پورت $port بسته است"
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
	local ips=($@) # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک آدرس IP یا بخش IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP $ ip منتشر شد"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@) # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک آدرس IP یا بخش IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP مسدود شده $ip"
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
	shift # 去掉第一个参数，剩下的全是国家代码

	install ipset

	for country_code in "$@"; do
		local ipset_name="${country_code,,}_block"
		local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

		case "$action" in
		block)
			if ! ipset list "$ipset_name" &>/dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "خطا: دانلود فایل منطقه IP برای $country_code انجام نشد"
				continue
			fi

			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip" 2>/dev/null
			done <"${country_code,,}.zone"

			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

			echo "آدرس IP $country_code با موفقیت مسدود شد"
			rm "${country_code,,}.zone"
			;;

		allow)
			if ! ipset list "$ipset_name" &>/dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "خطا: دانلود فایل منطقه IP برای $country_code انجام نشد"
				continue
			fi

			ipset flush "$ipset_name"
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip" 2>/dev/null
			done <"${country_code,,}.zone"

			iptables -P INPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

			echo "آدرس IP برای $country_code با موفقیت مجاز شد"
			rm "${country_code,,}.zone"
			;;

		unblock)
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

			if ipset list "$ipset_name" &>/dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "محدودیت آدرس IP برای $country_code با موفقیت حذف شد"
			;;

		*)
			echo "استفاده: manager_country_rules {block|allow|unblock} <country_code...>"
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
		echo "مدیریت فایروال پیشرفته"
		send_stats "高级防火墙管理"
		echo "------------------------"
		iptables -L INPUT
		echo ""
		echo "مدیریت فایروال"
		echo "------------------------"
		echo "1. پورت تعیین شده را باز کنید. 2. پورت تعیین شده را ببندید"
		echo "3. همه پورت ها را باز کنید 4. همه پورت ها را ببندید"
		echo "------------------------"
		echo "5. لیست سفید IP 6. لیست سیاه IP"
		echo "7. IP مشخص شده را پاک کنید"
		echo "------------------------"
		echo "11. Allow PING 12. PING را غیرفعال کنید"
		echo "------------------------"
		echo "13. دفاع DDOS را شروع کنید 14. دفاع DDOS را خاموش کنید"
		echo "------------------------"
		echo "15. مسدود کردن IP های کشور مشخص شده 16. فقط IP های کشور مشخص شده مجاز است"
		echo "17. رفع محدودیت های IP در کشورهای تعیین شده"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		case $sub_choice in
		1)
			read -e -p "لطفا شماره پورت باز را وارد کنید:" o_port
			open_port $o_port
			send_stats "开放指定端口"
			;;
		2)
			read -e -p "لطفا شماره پورت بسته را وارد کنید:" c_port
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
			iptables-save >/etc/iptables/rules.v4
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
			iptables-save >/etc/iptables/rules.v4
			send_stats "关闭所有端口"
			;;

		5)
			# IP 白名单
			read -e -p "لطفاً IP یا بخش IP مجاز را وارد کنید:" o_ip
			allow_ip $o_ip
			;;
		6)
			# IP 黑名单
			read -e -p "لطفاً IP یا محدوده IP مسدود شده را وارد کنید:" c_ip
			block_ip $c_ip
			;;
		7)
			# 清除指定 IP
			read -e -p "لطفا IP پاک شده را وارد کنید:" d_ip
			iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
			iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
			iptables-save >/etc/iptables/rules.v4
			send_stats "清除指定IP"
			;;
		11)
			# 允许 PING
			iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
			iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
			iptables-save >/etc/iptables/rules.v4
			send_stats "允许PING"
			;;
		12)
			# 禁用 PING
			iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
			iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
			iptables-save >/etc/iptables/rules.v4
			send_stats "禁用PING"
			;;
		13)
			enable_ddos_defense
			;;
		14)
			disable_ddos_defense
			;;

		15)
			read -e -p "لطفاً کد کشور مسدود شده را وارد کنید (کدهای چند کشور را می توان با فاصله از هم جدا کرد، مانند CN US JP):" country_code
			manage_country_rules block $country_code
			send_stats "允许国家 $country_code 的IP"
			;;
		16)
			read -e -p "لطفاً کدهای کشور مجاز را وارد کنید (کدهای چند کشور را می توان با فاصله از هم جدا کرد، مانند CN US JP):" country_code
			manage_country_rules allow $country_code
			send_stats "阻止国家 $country_code 的IP"
			;;

		17)
			read -e -p "لطفاً کد کشور پاک شده را وارد کنید (کدهای چند کشور را می توان با فاصله از هم جدا کرد، مانند CN US JP):" country_code
			manage_country_rules unblock $country_code
			send_stats "清除国家 $country_code 的IP"
			;;

		*)
			break # 跳出循环，退出菜单
			;;
		esac
	done

}

add_swap() {
	local new_swap=$1 # 获取传入的参数

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
	echo "/swapfile swap swap defaults 0 0" >>/etc/fstab

	if [ -f /etc/alpine-release ]; then
		echo "nohup swapon /swapfile" >/etc/local.d/swap.start
		chmod +x /etc/local.d/swap.start
		rc-update add local
	fi

	echo -e "اندازه حافظه مجازی روی ${gl_huang}${new_swap}${gl_bai}M تنظیم شده است"
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
	dbrootpasswd=$(openssl rand -base64 16)
	dbuse=$(openssl rand -hex 4)
	dbusepasswd=$(openssl rand -base64 8)

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
		sed -i 's|kjlion/nginx:alpine|nginx:alpine|g' /home/web/docker-compose.yml >/dev/null 2>&1
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml >/dev/null 2>&1
	fi

}

install_ldnmp() {

	check_swap
	update_docker_compose_with_db_creds

	cd /home/web && docker compose up -d
	sleep 1
	crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
	(
		crontab -l 2>/dev/null
		echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf'
	) | crontab -

	fix_phpfpm_conf php
	fix_phpfpm_conf php74
	restart_ldnmp

	clear
	echo "محیط LDNMP نصب شده است"
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
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "وظیفه تمدید به روز شده است"
}

install_ssltls() {
	docker stop nginx >/dev/null 2>&1
	check_port >/dev/null 2>&1
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
	cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1
	cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem >/dev/null 2>&1

	docker start nginx >/dev/null 2>&1
}

install_ssltls_text() {
	echo -e "${gl_huang}$ایجاد اطلاعات کلید عمومی${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$یوامینگ اطلاعات کلید خصوصی${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}مسیر ذخیره گواهی${gl_bai}"
	echo "کلید عمومی: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "کلید خصوصی: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}

add_ssl() {
	echo -e "${gl_huang} به سرعت برای گواهی SSL درخواست دهید و به طور خودکار آن را قبل از انقضا تمدید کنید ${gl_bai}"
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
	echo -e "${gl_huang}وضعیت انقضای گواهی اعمال شده${gl_bai}"
	echo "اطلاعات سایت زمان انقضای گواهینامه"
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
		echo -e "${gl_hong}نکته: ${gl_bai} درخواست گواهی ناموفق بود، لطفاً دلایل احتمالی زیر را بررسی کنید و دوباره امتحان کنید:"
		echo -e "1. املای نام دامنه اشتباه است ➠ لطفا بررسی کنید که آیا نام دامنه به درستی وارد شده است یا خیر"
		echo -e "2. مشکل وضوح DNS ➠ تأیید کنید که نام دامنه به درستی در IP سرور حل شده است"
		echo -e "3. مشکلات پیکربندی شبکه ➠ اگر از شبکه های مجازی مانند Cloudflare Warp استفاده می کنید، لطفاً به طور موقت خاموش کنید"
		echo -e "4. محدودیت های فایروال ➠ بررسی کنید که آیا پورت 80/443 باز است و اطمینان حاصل کنید که در دسترس است"
		echo -e "5. تعداد برنامه ها بیش از حد مجاز است ➠ Let's Encrypt یک محدودیت هفتگی دارد (5 بار/نام دامنه/هفته)"
		echo -e "6. محدودیت های ثبت داخلی ➠ برای محیط سرزمین اصلی چین، لطفاً تأیید کنید که آیا نام دامنه ثبت شده است یا خیر"
		break_end
		clear
		echo "لطفاً $webname را دوباره اجرا کنید"
		add_yuming
		install_ssltls
		certs_status
	fi

}

repeat_add_yuming() {
	if [ -e /home/web/conf.d/$yuming.conf ]; then
		send_stats "域名重复使用"
		web_del "${yuming}" >/dev/null 2>&1
	fi

}

add_yuming() {
	ip_address
	echo -e "ابتدا نام دامنه را به IP محلی حل کنید: ${gl_huang}$ipv4_address $ipv6_address${gl_bai}"
	read -e -p "لطفا IP یا نام دامنه حل شده خود را وارد کنید:" yuming
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
	docker exec redis redis-cli FLUSHALL >/dev/null 2>&1
	# docker exec -it redis redis-cli CONFIG SET maxmemory 1gb > /dev/null 2>&1
	# docker exec -it redis redis-cli CONFIG SET maxmemory-policy allkeys-lru > /dev/null 2>&1
}

restart_ldnmp() {
	restart_redis
	docker exec nginx chown -R nginx:nginx /var/www/html >/dev/null 2>&1
	docker exec nginx mkdir -p /var/cache/nginx/proxy >/dev/null 2>&1
	docker exec nginx mkdir -p /var/cache/nginx/fastcgi >/dev/null 2>&1
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy >/dev/null 2>&1
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi >/dev/null 2>&1
	docker exec php chown -R www-data:www-data /var/www/html >/dev/null 2>&1
	docker exec php74 chown -R www-data:www-data /var/www/html >/dev/null 2>&1
	cd /home/web && docker compose restart nginx php php74

}

nginx_upgrade() {

	local ldnmp_pods="nginx"
	cd /home/web/
	docker rm -f $ldnmp_pods >/dev/null 2>&1
	docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi >/dev/null 2>&1
	docker images --filter=reference="${ldnmp_pods}*" -q | xargs docker rmi >/dev/null 2>&1
	docker compose up -d --force-recreate $ldnmp_pods
	crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
	(
		crontab -l 2>/dev/null
		echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf'
	) | crontab -
	docker exec nginx chown -R nginx:nginx /var/www/html
	docker exec nginx mkdir -p /var/cache/nginx/proxy
	docker exec nginx mkdir -p /var/cache/nginx/fastcgi
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi
	docker restart $ldnmp_pods >/dev/null 2>&1

	send_stats "更新$ldnmp_pods"
	echo "به‌روزرسانی ${ldnmp_pods} تکمیل شد"

}

phpmyadmin_upgrade() {
	local ldnmp_pods="phpmyadmin"
	local local docker_port=8877
	local dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	local dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

	cd /home/web/
	docker rm -f $ldnmp_pods >/dev/null 2>&1
	docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
	curl -sS -O https://raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
	docker compose -f docker-compose.phpmyadmin.yml up -d
	clear
	ip_address

	check_docker_app_ip
	echo "اطلاعات ورود:"
	echo "نام کاربری: $dbuse"
	echo "رمز عبور: $dbususepasswd"
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
		read API_TOKEN EMAIL ZONE_IDS <"$CONFIG_FILE"
		# 将 ZONE_IDS 转换为数组
		ZONE_IDS=($ZONE_IDS)
	else
		# 提示用户是否清理缓存
		read -e -p "آیا نیاز به پاک کردن کش Cloudflare دارید؟ (y/N):" answer
		if [[ "$answer" == "y" ]]; then
			echo "اطلاعات CF در $CONFIG_FILE ذخیره می شود و می توان بعداً آن را تغییر داد."
			read -e -p "لطفاً API_TOKEN خود را وارد کنید:" API_TOKEN
			read -e -p "لطفا نام کاربری CF خود را وارد کنید:" EMAIL
			read -e -p "لطفا zone_id را وارد کنید (چند تایی را با فاصله جدا کنید):" -a ZONE_IDS

			mkdir -p /home/web/config/
			echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" >"$CONFIG_FILE"
		fi
	fi

	# 循环遍历每个 zone_id 并执行清除缓存命令
	for ZONE_ID in "${ZONE_IDS[@]}"; do
		echo "در حال پاک کردن کش برای zone_id: $ZONE_ID"
		curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
			-H "X-Auth-Email: $EMAIL" \
			-H "X-Auth-Key: $API_TOKEN" \
			-H "Content-Type: application/json" \
			--data '{"purge_everything":true}'
	done

	echo "درخواست پاکسازی حافظه پنهان ارسال شده است."
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
		read -e -p "برای حذف داده های سایت، لطفاً نام دامنه خود را وارد کنید (نام دامنه های متعدد را با فاصله از هم جدا کنید):" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "حذف نام دامنه: $yuming"
		rm -r /home/web/html/$yuming >/dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "حذف پایگاه داده: $dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" >/dev/null 2>&1
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
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf >/dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# 关闭 WAF：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf >/dev/null 2>&1
	else
		echo "آرگومان نامعتبر: استفاده از "روشن" یا "خاموش""
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
	local MEMORY_LIMIT="${1:-256M}"     # 第一个参数，默认256M
	local MAX_MEMORY_LIMIT="${2:-256M}" # 第二个参数，默认256M
	local TARGET_DIR="/home/web/html"   # 路径写死

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
	' "$FILE" >"$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

		echo "[+] Replaced WP_MEMORY_LIMIT in $FILE"
	done
}

patch_wp_debug() {
	local DEBUG="${1:-false}"         # 第一个参数，默认false
	local DEBUG_DISPLAY="${2:-false}" # 第二个参数，默认false
	local DEBUG_LOG="${3:-false}"     # 第三个参数，默认false
	local TARGET_DIR="/home/web/html" # 路径写死

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
	' "$FILE" >"$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

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
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)# brotli on;|\1brotli on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_static on;|\1brotli_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_comp_level \(.*\);|\1brotli_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_buffers \(.*\);|\1brotli_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_min_length \(.*\);|\1brotli_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_window \(.*\);|\1brotli_window \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_types \(.*\);|\1brotli_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/brotli_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf

	elif [ "$mode" == "off" ]; then
		# 关闭 Brotli：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)brotli on;|\1# brotli on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_static on;|\1# brotli_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_comp_level \(.*\);|\1# brotli_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_buffers \(.*\);|\1# brotli_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_min_length \(.*\);|\1# brotli_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_window \(.*\);|\1# brotli_window \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_types \(.*\);|\1# brotli_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/brotli_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf

	else
		echo "آرگومان نامعتبر: استفاده از "روشن" یا "خاموش""
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
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)# zstd on;|\1zstd on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_static on;|\1zstd_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_comp_level \(.*\);|\1zstd_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_buffers \(.*\);|\1zstd_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_min_length \(.*\);|\1zstd_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_types \(.*\);|\1zstd_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/zstd_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf

	elif [ "$mode" == "off" ]; then
		# 关闭 Zstd：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)zstd on;|\1# zstd on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_static on;|\1# zstd_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_comp_level \(.*\);|\1# zstd_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_buffers \(.*\);|\1# zstd_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_min_length \(.*\);|\1# zstd_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_types \(.*\);|\1# zstd_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/zstd_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf

	else
		echo "آرگومان نامعتبر: استفاده از "روشن" یا "خاموش""
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
		sed -i 's|^\(\s*\)# gzip on;|\1gzip on;|' /home/web/nginx.conf >/dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		sed -i 's|^\(\s*\)gzip on;|\1# gzip on;|' /home/web/nginx.conf >/dev/null 2>&1
	else
		echo "آرگومان نامعتبر: استفاده از "روشن" یا "خاموش""
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
		echo -e "برنامه دفاع از وب سایت سرور ${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
		echo "------------------------"
		echo "1. یک برنامه دفاعی نصب کنید"
		echo "------------------------"
		echo "5. مشاهده سوابق رهگیری SSH 6. مشاهده سوابق رهگیری وب سایت"
		echo "7. مشاهده لیست قوانین دفاعی 8. مشاهده سیاهههای مربوط برای نظارت در زمان واقعی"
		echo "------------------------"
		echo "11. پیکربندی پارامترهای رهگیری 12. تمام IP های مسدود شده را پاک کنید"
		echo "------------------------"
		echo "21. حالت ابری 22. سپر 5 ثانیه ای را تحت بار زیاد فعال کنید"
		echo "------------------------"
		echo "31. WAF را روشن کنید 32. WAF را خاموش کنید"
		echo "33. دفاع DDOS را روشن کنید 34. دفاع DDOS را خاموش کنید"
		echo "------------------------"
		echo "9. برنامه دفاعی را حذف کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
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
			echo "برنامه دفاعی Fail2Ban حذف نصب شده است"
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
			echo "به نمایه من در گوشه سمت راست بالای باطن cf بروید، نشانه API را در سمت چپ انتخاب کنید و کلید جهانی API را دریافت کنید."
			echo "https://dash.cloudflare.com/login"
			read -e -p "شماره حساب CF را وارد کنید:" cfuser
			read -e -p "کلید جهانی API CF را وارد کنید:" cftoken

			wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
			docker exec nginx nginx -s reload

			cd /etc/fail2ban/jail.d/
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

			cd /etc/fail2ban/action.d
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

			sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
			sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
			f2b_status

			echo "حالت Cloudflare پیکربندی شده است و رکورد رهگیری را می توان در پس‌زمینه cf، سایت-security-events مشاهده کرد."
			;;

		22)
			send_stats "高负载开启5秒盾"
			echo -e "${gl_huang}وب سایت به طور خودکار هر 5 دقیقه یکبار شناسایی می شود. وقتی بار زیاد را تشخیص داد، به طور خودکار سپر را باز می کند. اگر بار کم باشد، به طور خودکار سپر را به مدت 5 ثانیه می بندد. ${gl_bai}"
			echo "--------------"
			echo "دریافت پارامترهای CF:"
			echo -e "به نمایه من در گوشه سمت راست بالای باطن cf بروید، نشانه API را در سمت چپ انتخاب کنید و ${gl_huang}Global API Key${gl_bai} را دریافت کنید."
			echo -e "به سمت راست پایین صفحه خلاصه نام دامنه cf بروید تا ناحیه ${gl_huang} ID${gl_bai} را دریافت کنید."
			echo "https://dash.cloudflare.com/login"
			echo "--------------"
			read -e -p "شماره حساب CF را وارد کنید:" cfuser
			read -e -p "کلید جهانی API CF را وارد کنید:" cftoken
			read -e -p "شناسه منطقه نام دامنه را در CF وارد کنید:" cfzonID

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
				(
					crontab -l 2>/dev/null
					echo "$cron_job"
				) | crontab -
				echo "اسکریپت باز کردن سپر خودکار با بار بالا اضافه شده است"
			else
				echo "اسکریپت باز کردن سپر خودکار از قبل وجود دارد، نیازی به اضافه کردن آن نیست"
			fi

			;;

		31)
			nginx_waf on
			echo "WAF سایت فعال است"
			send_stats "站点WAF已开启"
			;;

		32)
			nginx_waf off
			echo "WAF سایت قطع شده است"
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
		echo -e "بهینه سازی محیط LDNMP${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
		echo "------------------------"
		echo "1. حالت استاندارد 2. حالت عملکرد بالا (2H4G یا بالاتر توصیه می شود)"
		echo "------------------------"
		echo "3. فشرده سازی gzip را روشن کنید 4. فشرده سازی gzip را خاموش کنید"
		echo "5. فشرده سازی br را روشن کنید 6. فشرده سازی br را خاموش کنید"
		echo "7. فشرده سازی zstd را روشن کنید 8. فشرده سازی zstd را خاموش کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		case $sub_choice in
		1)
			send_stats "站点标准模式"

			# nginx调优
			sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
			sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

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

			echo "محیط LDNMP روی حالت استاندارد تنظیم شده است"

			;;
		2)
			send_stats "站点高性能模式"

			# nginx调优
			sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
			sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

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

			echo "محیط LDNMP روی حالت عملکرد بالا تنظیم شده است"

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
	if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
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
	echo "آدرس بازدید:"
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

	echo "IP+پورت دسترسی به سرویس مسدود شده است"
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

	echo "IP+port اجازه دسترسی به این سرویس را دارد"
	save_iptables_rules
}

block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "خطا: لطفا شماره پورت و IP را برای اجازه دسترسی وارد کنید."
		echo "استفاده: block_host_port <شماره پورت> <IP مجاز>"
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

	echo "IP+پورت دسترسی به سرویس مسدود شده است"
	save_iptables_rules
}

clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "خطا: لطفا شماره پورت و IP را برای اجازه دسترسی وارد کنید."
		echo "استفاده: clear_host_port_rules <شماره پورت> <IP مجاز>"
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

	echo "IP+port اجازه دسترسی به این سرویس را دارد"
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
	grep -qxF "${app_id}" /home/docker/appno.txt || echo "${app_id}" >>/home/docker/appno.txt

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
				echo "$docker_port" >"/home/docker/${docker_name}_port.conf"
			fi
			local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
			check_docker_app_ip
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. به روز رسانی 3. حذف"
		echo "------------------------"
		echo "5. اضافه کردن دسترسی به نام دامنه 6. حذف دسترسی به نام دامنه"
		echo "7. اجازه دسترسی IP+پورت 8. مسدود کردن دسترسی IP+port"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "پورت سرویس خارجی برنامه را وارد کنید و Enter را فشار دهید تا به طور پیش‌فرض از پورت ${docker_port} استفاده کنید:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_name نصب شده است"
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
			echo "$docker_name نصب شده است"
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
			echo "برنامه حذف نصب شده است"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "${docker_name}تنظیمات دسترسی به نام دامنه"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "فرمت نام دامنه example.com بدون https://"
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
				echo "$docker_port" >"/home/docker/${docker_name}_port.conf"
			fi
			local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
			check_docker_app_ip
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. به روز رسانی 3. حذف"
		echo "------------------------"
		echo "5. اضافه کردن دسترسی به نام دامنه 6. حذف دسترسی به نام دامنه"
		echo "7. اجازه دسترسی IP+پورت 8. مسدود کردن دسترسی IP+port"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice
		case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "پورت سرویس خارجی برنامه را وارد کنید و Enter را فشار دهید تا به طور پیش‌فرض از پورت ${docker_port} استفاده کنید:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port
			install jq
			install_docker
			docker_app_install
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"

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
			echo "${docker_name}تنظیمات دسترسی به نام دامنه"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;
		6)
			echo "فرمت نام دامنه example.com بدون https://"
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

	read -e -p "$(echo -e "درخواست ${gl_huang}: ${gl_bai} اکنون سرور را مجددا راه اندازی کنید؟ (y/N):")" rboot
	case "$rboot" in
	[Yy])
		echo "دوباره راه اندازی شد"
		reboot
		;;
	*)
		echo "لغو شد"
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
		echo -e "${gl_huang} نکات: ${gl_bai} محیط ساخت وب سایت نصب شده است. نیازی به نصب مجدد نیست!"
		break_end
		linux_ldnmp
	fi

}

ldnmp_install_all() {
	cd ~
	send_stats "安装LDNMP环境"
	root_use
	clear
	echo -e "${gl_huang}محیط LDNMP نصب نشده است، شروع به نصب محیط LDNMP کنید...${gl_bai}"
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
	echo -e "${gl_huang}nginx نصب نیست، شروع به نصب محیط nginx کنید...${gl_bai}"
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
	echo "nginx نصب شده است"
	echo -e "نسخه فعلی: ${gl_huang}v$nginx_version${gl_bai}"
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
	echo "$webname شما راه اندازی شد!"
	echo "https://$yuming"
	echo "------------------------"
	echo "اطلاعات نصب $webname به شرح زیر است:"

}

nginx_web_on() {
	clear
	echo "$webname شما راه اندازی شد!"
	echo "https://$yuming"

}

ldnmp_wp() {
	clear
	# wordpress
	webname="وردپرس"
	yuming="${1:-}"
	send_stats "安装$webname"
	echo "شروع به استقرار $webname کنید"
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
	echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379');" >>/home/web/html/$yuming/wordpress/wp-config-sample.php
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
	webname="معکوس پروکسی-IP + پورت"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "شروع به استقرار $webname کنید"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "لطفا IP ضد نسل خود را وارد کنید:" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "لطفاً پورت ضد نسل خود را وارد کنید:" port
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
	webname="توازن بار پروکسی معکوس"

	send_stats "安装$webname"
	echo "شروع به استقرار $webname کنید"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "لطفاً چندین پورت IP+ ضد نسل خود را که با فاصله از هم جدا شده اند وارد کنید (به عنوان مثال، 127.0.0.1:3000 127.0.0.1:3002):" reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' </dev/urandom | head -c 8)
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
		echo -e "ابزار انتقال پراکسی چهار لایه $check_docker $update_status"
		echo "NGINX Stream ماژول پروکسی TCP/UDP NGINX است که برای دستیابی به حمل و نقل ترافیک لایه حمل و نقل با کارایی بالا و تعادل بار استفاده می شود."
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. به روز رسانی 3. حذف"
		echo "------------------------"
		echo "4. اضافه کردن سرویس حمل و نقل 5. تغییر سرویس حمل و نقل 6. حذف سرویس حمل و نقل"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice
		case $choice in
		1)
			nginx_install_status
			add_app_id
			;;
		2)
			update_docker_compose_with_db_creds
			nginx_upgrade
			add_app_id
			;;
		3)
			read -e -p "آیا مطمئن هستید که می خواهید ظرف nginx را حذف کنید؟ این ممکن است بر عملکرد وب سایت تأثیر بگذارد! (y/N):" confirm
			if [[ "$confirm" =~ ^[Yy]$ ]]; then
				docker rm -f nginx
				echo "ظرف nginx حذف شده است."
			else
				echo "عملیات لغو شده است."
			fi
			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			;;

		4)
			ldnmp_Proxy_backend_stream
			add_app_id
			;;
		5)
			send_stats "编辑转发配置"
			read -e -p "لطفاً نام سرویس مورد نظر برای ویرایش را وارد کنید:" stream_name
			install nano
			nano /home/web/stream.d/$stream_name.conf
			docker restart nginx
			;;
		6)
			send_stats "删除转发配置"
			read -e -p "لطفاً نام سرویسی را که می خواهید حذف کنید وارد کنید:" stream_name
			rm /home/web/stream.d/$stream_name.conf >/dev/null 2>&1
			docker restart nginx
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
	webname="متعادل‌سازی بار پروکسی چهار لایه جریان"

	send_stats "安装$webname"
	echo "شروع به استقرار $webname کنید"

	# 获取代理名称
	read -rp "请输入代理转发名称 (如 mysql_proxy): " proxy_name
	if [ -z "$proxy_name" ]; then
		echo "نام نمی تواند خالی باشد"
		return 1
	fi

	# 获取监听端口
	read -rp "请输入本机监听端口 (如 3306): " listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "پورت باید عددی باشد"
		return 1
	fi

	echo "لطفا نوع قرارداد را انتخاب کنید:"
	echo "1. TCP    2. UDP"
	read -rp "请输入序号 [1-2]: " proto_choice

	case "$proto_choice" in
	1)
		proto="tcp"
		listen_suffix=""
		;;
	2)
		proto="udp"
		listen_suffix=" udp"
		;;
	*)
		echo "انتخاب نامعتبر است"
		return 1
		;;
	esac

	read -e -p "لطفاً یک یا چند پورت IP + Backend خود را که با فاصله از هم جدا شده اند وارد کنید (به عنوان مثال 10.13.0.2:3306 10.13.0.3:3306):" reverseproxy_port

	nginx_install_status
	cd /home && mkdir -p web/stream.d
	grep -q '^[[:space:]]*stream[[:space:]]*{' /home/web/nginx.conf || echo -e '\nstream {\n    include /etc/nginx/stream.d/*.conf;\n}' | tee -a /home/web/nginx.conf
	wget -O /home/web/stream.d/$proxy_name.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend-stream.conf

	backend=$(tr -dc 'A-Za-z' </dev/urandom | head -c 8)
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
	echo "$webname شما راه اندازی شد!"
	echo "------------------------"
	echo "آدرس بازدید:"
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
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
		echo "محیط LDNMP"
		echo "------------------------"
		ldnmp_v

		echo -e "سایت: ${output} زمان انقضای گواهی"
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
		echo -e "پایگاه داده: ${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "دایرکتوری سایت"
		echo "------------------------"
		echo -e "داده ${gl_hui}/home/web/html${gl_bai} گواهی ${gl_hui}/home/web/certs${gl_bai} پیکربندی ${gl_hui}/home/web/conf.d__PROTECT_1_"
		echo "------------------------"
		echo ""
		echo "عمل کنند"
		echo "------------------------"
		echo "1. درخواست/به روز رسانی گواهی نام دامنه 2. کلون کردن نام دامنه سایت"
		echo "3. کش سایت را پاک کنید 4. سایت مرتبط ایجاد کنید"
		echo "5. مشاهده گزارش دسترسی 6. مشاهده گزارش خطا"
		echo "7. ویرایش پیکربندی جهانی 8. ویرایش پیکربندی سایت"
		echo "9. مدیریت پایگاه داده سایت 10. مشاهده گزارش تجزیه و تحلیل سایت"
		echo "------------------------"
		echo "20. داده های سایت مشخص شده را حذف کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		case $sub_choice in
		1)
			send_stats "申请域名证书"
			read -e -p "لطفا نام دامنه خود را وارد کنید:" yuming
			install_certbot
			docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
			install_ssltls
			certs_status

			;;

		2)
			send_stats "克隆站点域名"
			read -e -p "لطفا نام دامنه قدیمی را وارد کنید:" oddyuming
			read -e -p "لطفا نام دامنه جدید را وارد کنید:" yuming
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
			echo -e "برای دسترسی، یک نام دامنه جدید را با سایت موجود مرتبط کنید"
			read -e -p "لطفا یک نام دامنه موجود وارد کنید:" oddyuming
			read -e -p "لطفا نام دامنه جدید را وارد کنید:" yuming
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
			read -e -p "برای ویرایش پیکربندی سایت، لطفاً نام دامنه ای را که می خواهید ویرایش کنید وارد کنید:" yuming
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
			break # 跳出循环，退出菜单
			;;
		esac
	done

}

check_panel_app() {
	if $lujing >/dev/null 2>&1; then
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
		echo "${panelname} یک پنل مدیریت عملیات و نگهداری محبوب و قدرتمند است."
		echo "معرفی وب سایت رسمی: $panelurl"

		echo ""
		echo "------------------------"
		echo "1. نصب 2. مدیریت 3. حذف"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
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
	cat <<EOF >/home/frp/frps.toml
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
	echo "پارامترهای مورد نیاز برای استقرار کلاینت"
	echo "IP سرویس: $ipv4_address"
	echo "token: $token"
	echo
	echo "اطلاعات پنل FRP"
	echo "آدرس پنل FRP: http://$ipv4_address:$dashboard_port"
	echo "نام کاربری پنل FRP: $dashboard_user"
	echo "رمز عبور پنل FRP: $dashboard_pwd"
	echo

	open_port 8055 8056

}

configure_frpc() {
	send_stats "安装frp客户端"
	read -e -p "لطفاً IP اتصال شبکه خارجی را وارد کنید:" server_addr
	read -e -p "لطفاً رمز اتصال شبکه خارجی را وارد کنید:" token
	echo

	mkdir -p /home/frp
	touch /home/frp/frpc.toml
	cat <<EOF >/home/frp/frpc.toml
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
	read -e -p "لطفا نام سرویس را وارد کنید:" service_name
	read -e -p "لطفاً نوع ارسال (tcp/udp) را وارد کنید [به پیش‌فرض tcp را وارد کنید]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "لطفاً IP اینترانت را وارد کنید [پیش‌فرض با فشار دادن Enter 127.0.0.1 است]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "لطفا پورت اینترانت را وارد کنید:" local_port
	read -e -p "لطفا پورت شبکه خارجی را وارد کنید:" remote_port

	# 将用户输入写入配置文件
	cat <<EOF >>/home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 输出生成的信息
	echo "سرویس $service_name با موفقیت به frpc.toml اضافه شد"

	docker restart frpc

	open_port $local_port

}

delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	read -e -p "لطفاً نام سرویس را برای حذف وارد کنید:" service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "سرویس $service_name با موفقیت از frpc.toml حذف شد"

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
		echo "آدرس دسترسی خارجی سرویس FRP:"

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
		echo -e "سرور FRP $check_frp $update_status"
		echo "یک محیط سرویس نفوذ اینترانت FRP بسازید و دستگاه های بدون IP عمومی را در معرض اینترنت قرار دهید"
		echo "معرفی وب سایت رسمی: https://github.com/fatedier/frp/"
		echo "فیلم آموزشی: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. به روز رسانی 3. حذف"
		echo "------------------------"
		echo "5. دسترسی به نام دامنه سرویس اینترانت 6. دسترسی به نام دامنه را حذف کنید"
		echo "------------------------"
		echo "7. اجازه دسترسی IP+پورت 8. مسدود کردن دسترسی IP+port"
		echo "------------------------"
		echo "00. بازخوانی وضعیت سرویس 0. به منوی قبلی بازگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			generate_frps_config

			add_app_id
			echo "سرور FRP نصب شده است"
			;;
		2)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
			donlond_frp frps

			add_app_id
			echo "سرور FRP به روز شده است"
			;;
		3)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine
			rm -rf /home/frp

			close_port 8055 8056

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "برنامه حذف نصب شده است"
			;;
		5)
			echo "سرویس نفوذ معکوس اینترانت به دسترسی به نام دامنه"
			send_stats "FRP对外域名访问"
			add_yuming
			read -e -p "لطفاً پورت سرویس نفوذ اینترانت خود را وارد کنید:" frps_port
			ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
			block_host_port "$frps_port" "$ipv4_address"
			;;
		6)
			echo "فرمت نام دامنه example.com بدون https://"
			web_del
			;;

		7)
			send_stats "允许IP访问"
			read -e -p "لطفا پورتی را که باید آزاد شود وارد کنید:" frps_port
			clear_host_port_rules "$frps_port" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问"
			echo "اگر دسترسی به نام دامنه را معکوس کرده‌اید، می‌توانید از این تابع برای مسدود کردن دسترسی IP+port استفاده کنید که ایمن‌تر است."
			read -e -p "لطفا پورتی را وارد کنید که بلاک می شود:" frps_port
			block_host_port "$frps_port" "$ipv4_address"
			;;

		00)
			send_stats "刷新FRP服务状态"
			echo "وضعیت سرویس FRP به روز شده است"
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
		echo -e "کلاینت FRP $check_frp $update_status"
		echo "با سرور ارتباط برقرار کنید. پس از اتصال، می توانید یک سرویس نفوذ اینترانت برای دسترسی به اینترنت ایجاد کنید."
		echo "معرفی وب سایت رسمی: https://github.com/fatedier/frp/"
		echo "فیلم آموزشی: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. به روز رسانی 3. حذف"
		echo "------------------------"
		echo "4. اضافه کردن خدمات خارجی 5. حذف سرویس های خارجی 6. پیکربندی دستی سرویس ها"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			configure_frpc

			add_app_id
			echo "کلاینت FRP نصب شده است"
			;;
		2)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			donlond_frp frpc

			add_app_id
			echo "مشتری FRP به روز شده است"
			;;

		3)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine
			rm -rf /home/frp
			close_port 8055

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "برنامه حذف نصب شده است"
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
		echo -e "yt-dlp یک ابزار قدرتمند دانلود ویدیو است که از هزاران سایت مانند YouTube، Bilibili، Twitter و غیره پشتیبانی می کند."
		echo -e "آدرس وب سایت رسمی: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "لیست ویدیوهای دانلود شده:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(هنوز هیچ کدام)"
		echo "-------------------------"
		echo "1. نصب 2. به روز رسانی 3. حذف"
		echo "-------------------------"
		echo "5. دانلود تک ویدیو 6. دانلود دسته ای ویدیو 7. دانلود پارامتر سفارشی"
		echo "8. دانلود به صورت صوتی MP3 9. حذف فهرست ویدیویی 10. مدیریت کوکی (در حال توسعه)"
		echo "-------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "-------------------------"
		read -e -p "لطفا شماره گزینه را وارد کنید:" choice

		case $choice in
		1)
			send_stats "正在安装 yt-dlp..."
			echo "در حال نصب yt-dlp..."
			install ffmpeg
			curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
			chmod a+rx /usr/local/bin/yt-dlp

			add_app_id
			echo "نصب کامل شده است. برای ادامه هر کلیدی را فشار دهید..."
			read
			;;
		2)
			send_stats "正在更新 yt-dlp..."
			echo "در حال به روز رسانی yt-dlp..."
			yt-dlp -U

			add_app_id
			echo "به روز رسانی تکمیل شد. برای ادامه هر کلیدی را فشار دهید..."
			read
			;;
		3)
			send_stats "正在卸载 yt-dlp..."
			echo "در حال حذف yt-dlp..."
			rm -f /usr/local/bin/yt-dlp

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "حذف نصب انجام شد. برای ادامه هر کلیدی را فشار دهید..."
			read
			;;
		5)
			send_stats "单个视频下载"
			read -e -p "لطفا لینک ویدیو را وارد کنید:" url
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			read -e -p "دانلود کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;
		6)
			send_stats "批量视频下载"
			install nano
			if [ ! -f "$URL_FILE" ]; then
				echo -e "# آدرس های پیوند ویدیوی متعدد را وارد کنید\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" >"$URL_FILE"
			fi
			nano $URL_FILE
			echo "دانلود دسته ای را هم اکنون شروع کنید..."
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-a "$URL_FILE" \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			read -e -p "دانلود دسته ای کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;
		7)
			send_stats "自定义视频下载"
			read -e -p "لطفاً پارامترهای کامل yt-dlp (به استثنای yt-dlp) را وارد کنید:" custom
			yt-dlp -P "$VIDEO_DIR" $custom \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			read -e -p "اجرا به پایان رسید، برای ادامه هر کلید را فشار دهید..."
			;;
		8)
			send_stats "MP3下载"
			read -e -p "لطفا لینک ویدیو را وارد کنید:" url
			yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			read -e -p "دانلود صدا کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;

		9)
			send_stats "删除视频"
			read -e -p "لطفا نام ویدیوی حذف شده را وارد کنید:" rmdir
			rm -rf "$VIDEO_DIR/$rmdir"
			;;
		*)
			break
			;;
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
	echo -e "${gl_huang}به روز رسانی سیستم در حال انجام است...${gl_bai}"
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
		echo "مدیر بسته ناشناس!"
		return
	fi
}

linux_clean() {
	echo -e "${gl_huang} در حال تمیز کردن سیستم است... ${gl_bai}"
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
		echo "پاک کردن حافظه پنهان مدیر بسته..."
		apk cache clean
		echo "حذف گزارش سیستم..."
		rm -rf /var/log/*
		echo "حذف حافظه پنهان APK..."
		rm -rf /var/cache/apk/*
		echo "حذف فایل های موقت ..."
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
		echo "حذف گزارش سیستم..."
		rm -rf /var/log/*
		echo "حذف فایل های موقت ..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "وابستگی های استفاده نشده را پاک کنید..."
		pkg autoremove -y
		echo "پاک کردن حافظه پنهان مدیر بسته..."
		pkg clean -y
		echo "حذف گزارش سیستم..."
		rm -rf /var/log/*
		echo "حذف فایل های موقت ..."
		rm -rf /tmp/*

	else
		echo "مدیر بسته ناشناس!"
		return
	fi
	return
}

bbr_on() {

	cat >/etc/sysctl.conf <<EOF
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
		echo "nameserver $dns1_ipv4" >>/etc/resolv.conf
		echo "nameserver $dns2_ipv4" >>/etc/resolv.conf
	fi

	if [ -n "$ipv6_address" ]; then
		echo "nameserver $dns1_ipv6" >>/etc/resolv.conf
		echo "nameserver $dns2_ipv6" >>/etc/resolv.conf
	fi

	chattr +i /etc/resolv.conf

}

set_dns_ui() {
	root_use
	send_stats "优化DNS"
	while true; do
		clear
		echo "آدرس DNS را بهینه کنید"
		echo "------------------------"
		echo "آدرس DNS فعلی"
		cat /etc/resolv.conf
		echo "------------------------"
		echo ""
		echo "1. بهینه سازی DNS خارجی:"
		echo " v4: 1.1.1.1 8.8.8.8"
		echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
		echo "2. بهینه سازی DNS داخلی:"
		echo " v4: 223.5.5.5 183.60.83.19"
		echo " v6: 2400:3200::1 2400:da00::6666"
		echo "3. پیکربندی DNS را به صورت دستی ویرایش کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" Limiting
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
	restart sshd ssh >/dev/null 2>&1

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
	remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1

	echo "پورت SSH به $new_port تغییر یافته است"

	sleep 1

}

add_sshkey() {
	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""
	cat ~/.ssh/sshkey.pub >>~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	ip_address
	echo -e "اطلاعات کلید خصوصی ایجاد شده است. حتما کپی و ذخیره کنید. می توان آن را به عنوان فایل ${gl_huang}${ipv4_address}_ssh.key${gl_bai} برای ورود به سیستم SSH در آینده ذخیره کرد."

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ورود با کلید خصوصی ROOT روشن شده است، ورود رمز عبور ROOT خاموش شده است، اتصال مجدد اعمال می شود ${gl_bai}"

}

import_sshkey() {

	read -e -p "لطفاً محتویات کلید عمومی SSH خود را وارد کنید (معمولاً با 'ssh-rsa' یا 'ssh-ed25519' شروع می شود):" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong} خطا: محتوای کلید عمومی وارد نشده است. ${gl_bai}"
		return 1
	fi

	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	echo "$public_key" >>~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}کلید عمومی با موفقیت وارد شد، ورود کلید خصوصی ROOT فعال شد، ورود رمز عبور ROOT بسته شد، و اتصال مجدد اعمال خواهد شد${gl_bai}"

}

add_sshpasswd() {

	echo "رمز عبور ROOT خود را تنظیم کنید"
	passwd
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}تنظیم ورود به سیستم ROOT تکمیل شد! ${gl_bai}"

}

root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${gl_huang} نکته: ${gl_bai} این تابع برای اجرا به کاربر root نیاز دارد!" && break_end && kejilion
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
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}root${gl_bai} رمز عبور اولیه: ${gl_huang}LeitboGi0ro${gl_bai} پورت اولیه: ${gl_huang}22${gl_bai}"
		echo -e "برای ادامه هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_2() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}Administrator${gl_bai} رمز عبور اولیه: ${gl_huang}Teddysun.com${gl_bai} درگاه اولیه: ${gl_huang}3389__PROTECT__"
		echo -e "برای ادامه هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_3() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}root${gl_bai} رمز عبور اولیه: ${gl_huang}123@@@${gl_bai} پورت اولیه: ${gl_huang}22${gl_bai}"
		echo -e "برای ادامه هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		dd_xitong_bin456789
	}

	dd_xitong_4() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}Administrator${gl_bai} رمز عبور اولیه: ${gl_huang}123@@@${gl_bai} پورت اولیه: ${gl_huang}3389${gl_bai}"
		echo -e "برای ادامه هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		dd_xitong_bin456789
	}

	while true; do
		root_use
		echo "سیستم را دوباره نصب کنید"
		echo "--------------------------------"
		echo -e "${gl_hong} توجه: ${gl_bai} نصب مجدد ممکن است باعث قطع اتصال شود، اگر نگران هستید با احتیاط استفاده کنید. انتظار می رود نصب مجدد 15 دقیقه طول بکشد، لطفاً از اطلاعات خود از قبل نسخه پشتیبان تهیه کنید."
		echo -e "${gl_hui} از boss leitbogioro و boss bin456789 برای پشتیبانی از اسکریپت متشکریم! ${gl_bai}"
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
		echo "35. openSUSE Tumbleweed 36. fnos Feiniu نسخه بتای عمومی"
		echo "------------------------"
		echo "41. Windows 11                42. Windows 10"
		echo "43. Windows 7                 44. Windows Server 2025"
		echo "45. Windows Server 2022       46. Windows Server 2019"
		echo "47. Windows 11 ARM"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفاً سیستمی را که می خواهید دوباره نصب کنید انتخاب کنید:" sys_choice
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
			echo "شما هسته BBRv3 xanmod را نصب کرده اید"
			echo "نسخه هسته فعلی: $kernel_version"

			echo ""
			echo "مدیریت کرنل"
			echo "------------------------"
			echo "1. هسته BBRv3 را به روز کنید. 2. هسته BBRv3 را حذف کنید"
			echo "------------------------"
			echo "0. به منوی قبلی برگردید"
			echo "------------------------"
			read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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

				echo "هسته XanMod به روز شده است. پس از راه اندازی مجدد اعمال شود"
				rm -f /etc/apt/sources.list.d/xanmod-release.list
				rm -f check_x86-64_psabi.sh*

				server_reboot

				;;
			2)
				apt purge -y 'linux-*xanmod1*'
				update-grub
				echo "هسته XanMod حذف نصب شده است. پس از راه اندازی مجدد اعمال شود"
				server_reboot
				;;

			*)
				break # 跳出循环，退出菜单
				;;

			esac
		done
	else

		clear
		echo "شتاب BBR3 را تنظیم کنید"
		echo "معرفی ویدیو: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		echo "------------------------------------------------"
		echo "فقط از Debian/Ubuntu پشتیبانی می کند"
		echo "لطفاً از اطلاعات خود نسخه پشتیبان تهیه کنید و ما هسته لینوکس شما را ارتقا داده و BBR3 را فعال می کنیم."
		echo "------------------------------------------------"
		read -e -p "آیا مطمئن هستید که می خواهید ادامه دهید؟ (y/N):" choice

		case "$choice" in
		[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "محیط فعلی آن را پشتیبانی نمی کند. فقط سیستم های دبیان و اوبونتو پشتیبانی می شوند."
					break_end
					linux_Settings
				fi
			else
				echo "نمی توان نوع سیستم عامل را تعیین کرد"
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

			echo "هسته XanMod نصب شد و BBR3 با موفقیت فعال شد. پس از راه اندازی مجدد اعمال شود"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			;;
		[Nn])
			echo "لغو شد"
			;;
		*)
			echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
			;;
		esac
	fi

}

elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "وارد کردن کلید عمومی ELRepo GPG..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "سیستم عامل های پشتیبانی نشده: $os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "سیستم عامل شناسایی شده: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ "$os_version" == 8 ]]; then
		echo "در حال نصب پیکربندی مخزن ELRepo (نسخه 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "در حال نصب پیکربندی مخزن ELRepo (نسخه 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "در حال نصب پیکربندی مخزن ELRepo (نسخه 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "نسخه سیستم پشتیبانی نشده: $os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "مخزن هسته ELRepo را فعال کنید و آخرین هسته اصلی را نصب کنید..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "پیکربندی مخزن ELRepo را نصب کرد و به آخرین هسته اصلی به روز شد."
	server_reboot

}

elrepo() {
	root_use
	send_stats "红帽内核管理"
	if uname -r | grep -q 'elrepo'; then
		while true; do
			clear
			kernel_version=$(uname -r)
			echo "شما هسته elrepo را نصب کرده اید"
			echo "نسخه هسته فعلی: $kernel_version"

			echo ""
			echo "مدیریت کرنل"
			echo "------------------------"
			echo "1. به روز رسانی هسته elrepo 2. حذف elrepo kernel"
			echo "------------------------"
			echo "0. به منوی قبلی برگردید"
			echo "------------------------"
			read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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
				echo "هسته elrepo حذف نصب شده است. پس از راه اندازی مجدد اعمال شود"
				send_stats "卸载红帽内核"
				server_reboot

				;;
			*)
				break # 跳出循环，退出菜单
				;;

			esac
		done
	else

		clear
		echo "لطفا از اطلاعات خود نسخه پشتیبان تهیه کنید و ما هسته لینوکس را برای شما ارتقا می دهیم."
		echo "معرفی ویدیو: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		echo "------------------------------------------------"
		echo "فقط از توزیع های سری Red Hat CentOS/RedHat/Alma/Rocky/oracle پشتیبانی می کند"
		echo "ارتقاء هسته لینوکس می تواند عملکرد و امنیت سیستم را بهبود بخشد. توصیه می شود در صورت امکان آن را امتحان کنید و محیط تولید را با احتیاط ارتقا دهید!"
		echo "------------------------------------------------"
		read -e -p "آیا مطمئن هستید که می خواهید ادامه دهید؟ (y/N):" choice

		case "$choice" in
		[Yy])
			check_swap
			elrepo_install
			send_stats "升级红帽内核"
			server_reboot
			;;
		[Nn])
			echo "لغو شد"
			;;
		*)
			echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
			;;
		esac
	fi

}

clamav_freshclam() {
	echo -e "${gl_huang}به روز رسانی پایگاه داده ویروس...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "لطفا دایرکتوری ها را برای اسکن مشخص کنید."
		return
	fi

	echo -e "${gl_huang} اسکن دایرکتوری $@... ${gl_bai}"

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

	mkdir -p /home/docker/clamav/log/ >/dev/null 2>&1
	>/home/docker/clamav/log/scan.log >/dev/null 2>&1

	# 执行 Docker 命令
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ اسکن کامل شد و گزارش ویروس در ${gl_huang}/home/docker/clamav/log/scan.log${gl_bai} ذخیره می شود"
	echo -e "${gl_lv} اگر ویروسی وجود دارد، لطفاً کلمه کلیدی FOUND را در فایل ${gl_huang}scan.log${gl_lv} جستجو کنید تا مکان ویروس ${gl_bai} را تأیید کنید."

}

clamav() {
	root_use
	send_stats "病毒扫描管理"
	while true; do
		clear
		echo "ابزار اسکن ویروس clamav"
		echo "معرفی ویدیو: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
		echo "------------------------"
		echo "این یک ابزار نرم افزار آنتی ویروس منبع باز است که عمدتا برای شناسایی و حذف انواع مختلف بدافزار استفاده می شود."
		echo "شامل ویروس ها، اسب های تروجان، جاسوس افزارها، اسکریپت های مخرب و سایر نرم افزارهای مضر است."
		echo "------------------------"
		echo -e "${gl_lv}1. اسکن کامل ${gl_bai} ${gl_huang}2. اسکن دایرکتوری مهم ${gl_bai} ${gl_kjlan} 3. اسکن فهرست سفارشی ${gl_bai}"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		case $sub_choice in
		1)
			send_stats "全盘扫描"
			install_docker
			docker volume create clam_db >/dev/null 2>&1
			clamav_freshclam
			clamav_scan /
			break_end

			;;
		2)
			send_stats "重要目录扫描"
			install_docker
			docker volume create clam_db >/dev/null 2>&1
			clamav_freshclam
			clamav_scan /etc /var /usr /home /root
			break_end
			;;
		3)
			send_stats "自定义目录扫描"
			read -e -p "لطفاً دایرکتوری هایی را که باید اسکن شوند، با فاصله از هم جدا کنید (به عنوان مثال: /etc /var /usr /home /root):" directories
			install_docker
			clamav_freshclam
			clamav_scan $directories
			break_end
			;;
		*)
			break # 跳出循环，退出菜单
			;;
		esac
	done

}

# 高性能模式优化函数
optimize_high_performance() {
	echo -e "${gl_lv} به ${tiaoyou_moshi}...${gl_bai} تغییر می کند"

	echo -e "${gl_lv} بهینه سازی توصیفگر فایل...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv} بهینه سازی حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv} بهینه سازی مدیریت حافظه پنهان...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv} بهینه سازی تنظیمات CPU... ${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv} تغییر به حالت یکسان سازی...${gl_bai}"

	echo -e "${gl_lv} بهینه سازی توصیفگر فایل...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv} بهینه سازی حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv} بهینه سازی مدیریت حافظه پنهان...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv} بهینه سازی تنظیمات CPU... ${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}بازیابی به تنظیمات پیش فرض...${gl_bai}"

	echo -e "${gl_lv}بازیابی توصیفگر فایل...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}بازیابی حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}بازیابی تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv}بازیابی مدیریت حافظه پنهان...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}بازیابی تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}بازیابی بهینه سازی های دیگر...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}به حالت بهینه سازی ساخت وب سایت بروید...${gl_bai}"

	echo -e "${gl_lv} بهینه سازی توصیفگر فایل...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv} بهینه سازی حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv} بهینه سازی مدیریت حافظه پنهان...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv} بهینه سازی تنظیمات CPU... ${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

Kernel_optimize() {
	root_use
	while true; do
		clear
		send_stats "Linux内核调优管理"
		echo "بهینه سازی پارامتر هسته سیستم لینوکس"
		echo "معرفی ویدیو: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
		echo "------------------------------------------------"
		echo "انواع حالت‌های تنظیم پارامترهای سیستم را ارائه می‌دهد و کاربران می‌توانند با توجه به سناریوهای استفاده خود تغییر کنند."
		echo -e "${gl_huang} نکات: ${gl_bai} لطفاً در محیط تولید با احتیاط از آن استفاده کنید!"
		echo "--------------------"
		echo "1. حالت بهینه سازی با کارایی بالا: عملکرد سیستم را به حداکثر برسانید و توصیفگرهای فایل، حافظه مجازی، تنظیمات شبکه، مدیریت کش و تنظیمات CPU را بهینه کنید."
		echo "2. حالت بهینه سازی متعادل: تعادلی بین عملکرد و مصرف منابع ایجاد می کند، مناسب برای استفاده روزانه."
		echo "3. حالت بهینه سازی وب سایت: بهینه سازی سرور وب سایت برای بهبود قابلیت های پردازش اتصال همزمان، سرعت پاسخگویی و عملکرد کلی."
		echo "4. حالت بهینه سازی پخش زنده: نیازهای ویژه پخش زنده را برای کاهش تأخیرها و بهبود عملکرد انتقال بهینه کنید."
		echo "5. حالت بهینه سازی سرور بازی: سرور بازی را برای بهبود قابلیت های پردازش همزمان و سرعت پاسخگویی بهینه کنید."
		echo "6. بازیابی تنظیمات پیش فرض: تنظیمات سیستم را به تنظیمات پیش فرض بازگردانید."
		echo "--------------------"
		echo "0. به منوی قبلی برگردید"
		echo "--------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
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
		debian | ubuntu | kali)
			install locales
			sed -i "s/^\s*#\?\s*${locale_file}/${locale_file}/" /etc/locale.gen
			locale-gen
			echo "LANG=${lang}" >/etc/default/locale
			export LANG=${lang}
			echo -e "${gl_lv}زبان سیستم به: $lang تغییر یافته است پس از اتصال مجدد SSH اعمال می شود. ${gl_bai}"
			hash -r
			break_end

			;;
		centos | rhel | almalinux | rocky | fedora)
			install glibc-langpack-zh
			localectl set-locale LANG=${lang}
			echo "LANG=${lang}" | tee /etc/locale.conf
			echo -e "${gl_lv}زبان سیستم به: $lang تغییر یافته است پس از اتصال مجدد SSH اعمال می شود. ${gl_bai}"
			hash -r
			break_end
			;;
		*)
			echo "سیستم های پشتیبانی نشده: $ID"
			break_end
			;;
		esac
	else
		echo "سیستم پشتیبانی نشده، نوع سیستم قابل شناسایی نیست."
		break_end
	fi
}

linux_language() {
	root_use
	send_stats "切换系统语言"
	while true; do
		clear
		echo "زبان سیستم فعلی: $LANG"
		echo "------------------------"
		echo "1. انگلیسی 2. چینی ساده شده 3. چینی سنتی"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice

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
		echo "${bianse}" >>~/.bashrc
		# source ~/.bashrc
	else
		sed -i '/^PS1=/d' ~/.profile
		echo "${bianse}" >>~/.profile
		# source ~/.profile
	fi
	echo -e "${gl_lv} تغییر تکمیل شد. دوباره به SSH متصل شوید تا تغییرات را ببینید! ${gl_bai}"

	hash -r
	break_end

}

shell_bianse() {
	root_use
	send_stats "命令行美化工具"
	while true; do
		clear
		echo "ابزار زیباسازی خط فرمان"
		echo "------------------------"
		echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
		echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
		echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
		echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
		echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
		echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
		echo -e "7. root localhost ~ #"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice

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
		echo -e "سطل بازیافت فعلی ${trash_status}"
		echo -e "پس از فعال سازی، فایل های حذف شده توسط rm ابتدا در سطل بازیافت قرار می گیرند تا از حذف تصادفی فایل های مهم جلوگیری شود!"
		echo "------------------------------------------------"
		ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "سطل بازیافت خالی است"
		echo "------------------------"
		echo "1. Recycle Bin را فعال کنید. 2. Recycle Bin را ببندید"
		echo "3. بازیابی محتوا 4. خالی کردن سطل بازیافت"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice

		case $choice in
		1)
			install trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='trash-put'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "سطل بازیافت فعال است، فایل های حذف شده به سطل بازیافت منتقل می شوند."
			sleep 2
			;;
		2)
			remove trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='rm -i'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "سطل بازیافت بسته می شود و فایل ها مستقیماً حذف می شوند."
			sleep 2
			;;
		3)
			read -e -p "نام فایل مورد نظر برای بازیابی را وارد کنید:" file_to_restore
			if [ -e "$TRASH_DIR/$file_to_restore" ]; then
				mv "$TRASH_DIR/$file_to_restore" "$HOME/"
				echo "$file_to_restore به فهرست اصلی بازیابی شد."
			else
				echo "فایل وجود ندارد."
			fi
			;;
		4)
			read -e -p "آیا مطمئن هستید که می خواهید سطل بازیافت را خالی کنید؟ [y/N]:" confirm
			if [[ "$confirm" == "y" ]]; then
				trash-empty
				echo "سطل بازیافت خالی شده است."
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
	echo "نمونه ای از ایجاد یک نسخه پشتیبان:"
	echo "- از یک دایرکتوری بک آپ بگیرید: /var/www"
	echo "- از چندین دایرکتوری پشتیبان تهیه کنید: /etc /home /var/log"
	echo "- برای استفاده از دایرکتوری پیش فرض، Enter را فشار دهید (/etc /usr /home)"
	read -r -p "لطفاً دایرکتوری مورد نظر برای تهیه نسخه پشتیبان را وارد کنید (چند دایرکتوری را با فاصله جدا کنید و برای استفاده از دایرکتوری پیش فرض Enter را فشار دهید):" input

	# 如果用户没有输入目录，则使用默认目录
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"  # 配置文件和软件包配置
			"/usr"  # 已安装的软件文件
			"/home" # 用户数据
		)
	else
		# 将用户输入的目录按空格分隔成数组
		IFS=' ' read -r -a BACKUP_PATHS <<<"$input"
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
	echo "دایرکتوری پشتیبان که انتخاب کردید این است:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "در حال ایجاد نسخه پشتیبان $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "پشتیبان گیری با موفقیت ایجاد شد: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "ایجاد پشتیبان انجام نشد!"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	read -e -p "لطفاً نام فایل پشتیبان را برای بازیابی وارد کنید:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "فایل پشتیبان وجود ندارد!"
		exit 1
	fi

	echo "در حال بازیابی نسخه پشتیبان $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "پشتیبان گیری و بازیابی با موفقیت انجام شد!"
	else
		echo "بازیابی نسخه پشتیبان انجام نشد!"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "پشتیبان های موجود:"
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	read -e -p "لطفا نام فایل پشتیبان را برای حذف وارد کنید:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "فایل پشتیبان وجود ندارد!"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "نسخه پشتیبان با موفقیت حذف شد!"
	else
		echo "حذف پشتیبان انجام نشد!"
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
		echo "عملکرد پشتیبان گیری سیستم"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. ایجاد پشتیبان 2. بازیابی نسخه پشتیبان 3. حذف پشتیبان"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
		1) create_backup ;;
		2) restore_backup ;;
		3) delete_backup ;;
		*) break ;;
		esac
		read -e -p "برای ادامه Enter را فشار دهید..."
	done
}

# 显示连接列表
list_connections() {
	echo "اتصالات ذخیره شده:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}

# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "نمونه ای از ایجاد یک اتصال جدید:"
	echo "- نام اتصال: my_server"
	echo "- آدرس IP: 192.168.1.100"
	echo "- نام کاربری: root"
	echo "- بندر: 22"
	echo "------------------------"
	read -e -p "لطفاً یک نام اتصال وارد کنید:" name
	read -e -p "لطفا آدرس IP را وارد کنید:" ip
	read -e -p "لطفا نام کاربری را وارد کنید (پیش‌فرض: root):" user
	local user=${user:-root} # 如果用户未输入，则使用默认值 root
	read -e -p "لطفا شماره پورت را وارد کنید (پیش فرض: 22):" port
	local port=${port:-22} # 如果用户未输入，则使用默认值 22

	echo "لطفاً یک روش احراز هویت را انتخاب کنید:"
	echo "1. رمز عبور"
	echo "2. کلید"
	read -e -p "لطفا انتخاب خود را وارد کنید (1/2):" auth_choice

	case $auth_choice in
	1)
		read -s -p "请输入密码: " password_or_key
		echo # 换行
		;;
	2)
		echo "لطفاً محتوای کلید را جایگذاری کنید (بعد از چسباندن دوبار Enter را فشار دهید):"
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
			echo -n "$password_or_key" >"$key_file"
			chmod 600 "$key_file"
			local password_or_key="$key_file"
		fi
		;;
	*)
		echo "انتخاب نامعتبر!"
		return
		;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >>"$CONFIG_FILE"
	echo "اتصال ذخیره شد!"
}

# 删除连接
delete_connection() {
	send_stats "删除连接"
	read -e -p "لطفا شماره اتصال را که باید حذف شود وارد کنید:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "خطا: اتصال مربوطه پیدا نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "اتصال حذف شد!"
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	read -e -p "لطفا شماره اتصال را برای استفاده وارد کنید:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "خطا: اتصال مربوطه پیدا نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	echo "در حال اتصال به $name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال ناموفق بود! لطفا موارد زیر را بررسی کنید:"
			echo "1. آیا مسیر فایل کلید درست است: $password_or_key"
			echo "2. آیا مجوزهای فایل کلیدی صحیح است (باید 600 باشد)."
			echo "3. آیا سرور مورد نظر اجازه ورود با استفاده از یک کلید را می دهد یا خیر."
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &>/dev/null; then
			echo "خطا: sshpass نصب نشده است، لطفا ابتدا sshpass را نصب کنید."
			echo "روش نصب:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال ناموفق بود! لطفا موارد زیر را بررسی کنید:"
			echo "1. نام کاربری و رمز عبور صحیح است؟"
			echo "2. آیا سرور مورد نظر اجازه ورود رمز عبور را می دهد یا خیر."
			echo "3. آیا سرویس SSH سرور هدف به طور عادی در حال اجرا است یا خیر."
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
		echo "ابزار اتصال از راه دور SSH"
		echo "می تواند از طریق SSH به سایر سیستم های لینوکس متصل شود"
		echo "------------------------"
		list_connections
		echo "1. ایجاد یک اتصال جدید 2. استفاده از اتصال 3. حذف اتصال"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
		1) add_connection ;;
		2) use_connection ;;
		3) delete_connection ;;
		0) break ;;
		*) echo "انتخاب نامعتبر است، لطفاً دوباره امتحان کنید." ;;
		esac
	done
}

# 列出可用的硬盘分区
list_partitions() {
	echo "پارتیشن های موجود در هارد:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	read -e -p "لطفاً نام پارتیشنی که قرار است نصب شود را وارد کنید (به عنوان مثال sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن نصب شده است!"
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "پارتیشن با موفقیت نصب شد: $MOUNT_POINT"
	else
		echo "نصب پارتیشن ناموفق بود!"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	read -e -p "لطفاً نام پارتیشنی که قرار است خارج شود را وارد کنید (به عنوان مثال sda1):" PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "پارتیشن نصب نشده است!"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "پارتیشن با موفقیت خارج شد: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "حذف پارتیشن ناموفق بود!"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "پارتیشن های نصب شده:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	read -e -p "لطفاً نام پارتیشن مورد نظر را وارد کنید (به عنوان مثال sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن نصب شده است، لطفا ابتدا آن را جدا کنید!"
		return
	fi

	# 选择文件系统类型
	echo "لطفاً یک نوع سیستم فایل را انتخاب کنید:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "لطفا انتخاب خود را وارد کنید:" FS_CHOICE

	case $FS_CHOICE in
	1) FS_TYPE="ext4" ;;
	2) FS_TYPE="xfs" ;;
	3) FS_TYPE="ntfs" ;;
	4) FS_TYPE="vfat" ;;
	*)
		echo "انتخاب نامعتبر!"
		return
		;;
	esac

	# 确认格式化
	read -e -p "تأیید می کنید که پارتیشن فرمت شده /dev/$PARTITION $FS_TYPE است؟ (y/N):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "عملیات لغو شده است."
		return
	fi

	# 格式化分区
	echo "در حال قالب‌بندی پارتیشن /dev/$PARTITION به $FS_TYPE..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "پارتیشن با موفقیت فرمت شد!"
	else
		echo "قالب بندی پارتیشن ناموفق بود!"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	read -e -p "لطفاً نام پارتیشن را برای بررسی وارد کنید (به عنوان مثال sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# 检查分区状态
	echo "وضعیت پارتیشن /dev/$PARTITION را بررسی کنید:"
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "مدیریت پارتیشن هارد دیسک"
		echo -e "${gl_huang} این عملکرد در مرحله آزمایش داخلی است، لطفاً از آن در محیط تولید استفاده نکنید. ${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. پارتیشن را سوار کنید 2. پارتیشن را جدا کنید 3. پارتیشن نصب شده را مشاهده کنید"
		echo "4. قالب بندی پارتیشن 5. وضعیت پارتیشن را بررسی کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
		1) mount_partition ;;
		2) unmount_partition ;;
		3) list_mounted_partitions ;;
		4) format_partition ;;
		5) check_partition ;;
		*) break ;;
		esac
		read -e -p "برای ادامه Enter را فشار دهید..."
	done
}

# 显示任务列表
list_tasks() {
	echo "وظایف همگام سازی ذخیره شده:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
	echo "نمونه ای از ایجاد یک کار همگام سازی جدید:"
	echo "- نام وظیفه: backup_www"
	echo "- دایرکتوری محلی: /var/www"
	echo "- آدرس راه دور: user@192.168.1.100"
	echo "- دایرکتوری راه دور: /backup/www"
	echo "- شماره پورت (پیش‌فرض 22)"
	echo "---------------------------------"
	read -e -p "لطفا نام کار را وارد کنید:" name
	read -e -p "لطفا دایرکتوری محلی را وارد کنید:" local_path
	read -e -p "لطفا دایرکتوری راه دور را وارد کنید:" remote_path
	read -e -p "لطفا از راه دور user@IP را وارد کنید:" remote
	read -e -p "لطفاً پورت SSH را وارد کنید (پیش‌فرض 22):" port
	port=${port:-22}

	echo "لطفاً یک روش احراز هویت را انتخاب کنید:"
	echo "1. رمز عبور"
	echo "2. کلید"
	read -e -p "لطفاً (1/2) را انتخاب کنید:" auth_choice

	case $auth_choice in
	1)
		read -s -p "请输入密码: " password_or_key
		echo # 换行
		auth_method="password"
		;;
	2)
		echo "لطفاً محتوای کلید را جایگذاری کنید (بعد از چسباندن دوبار Enter را فشار دهید):"
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
			echo -n "$password_or_key" >"$key_file"
			chmod 600 "$key_file"
			password_or_key="$key_file"
			auth_method="key"
		else
			echo "محتوای کلیدی نامعتبر است!"
			return
		fi
		;;
	*)
		echo "انتخاب نامعتبر!"
		return
		;;
	esac

	echo "لطفا حالت همگام سازی را انتخاب کنید:"
	echo "1. حالت استاندارد (-avz)"
	echo "2. فایل مورد نظر را حذف کنید (-avz --delete)"
	read -e -p "لطفاً (1/2) را انتخاب کنید:" mode
	case $mode in
	1) options="-avz" ;;
	2) options="-avz --delete" ;;
	*)
		echo "انتخاب نامعتبر است، از پیش فرض -avz استفاده کنید"
		options="-avz"
		;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >>"$CONFIG_FILE"

	install rsync rsync

	echo "ماموریت نجات یافت!"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	read -e -p "لطفا شماره کار را که باید حذف شود وارد کنید:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "خطا: وظیفه مربوطه پیدا نشد."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "وظیفه حذف شد!"
}

run_task() {
	send_stats "执行同步任务"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# 解析参数
	local direction="push" # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 如果没有传入任务编号，提示用户输入
	if [[ -z "$num" ]]; then
		read -e -p "لطفاً شماره کار مورد نظر را وارد کنید:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "خطا: کار پیدا نشد!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 根据同步方向调整源和目标路径
	if [[ "$direction" == "pull" ]]; then
		echo "کشیدن و همگام سازی با محلی: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "فشار دادن و همگام سازی به انتهای راه دور: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &>/dev/null; then
			echo "خطا: sshpass نصب نشده است، لطفا ابتدا sshpass را نصب کنید."
			echo "روش نصب:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f "$password_or_key" ]]; then
			echo "خطا: فایل کلیدی وجود ندارد: $password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "هشدار: مجوزهای فایل کلیدی نادرست، رفع..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "همگام سازی کامل شد!"
	else
		echo "همگام سازی انجام نشد! لطفا موارد زیر را بررسی کنید:"
		echo "1. آیا اتصال به شبکه عادی است؟"
		echo "2. آیا میزبان راه دور قابل دسترسی است؟"
		echo "3. آیا اطلاعات احراز هویت صحیح است؟"
		echo "4. آیا دایرکتوری های محلی و راه دور دارای مجوزهای دسترسی صحیح هستند؟"
	fi
}

# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	read -e -p "لطفاً شماره کار را وارد کنید تا مرتباً همگام شود:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً یک شماره کار معتبر وارد کنید!"
		return
	fi

	echo "لطفا فاصله اجرای برنامه ریزی شده را انتخاب کنید:"
	echo "1) هر ساعت یک بار اجرا کنید"
	echo "2) یک بار در روز اجرا کنید"
	echo "3) هفته ای یکبار اجرا کنید"
	read -e -p "لطفا گزینه ها را وارد کنید (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1) # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
	1) cron_time="$random_minute * * * *" ;; # 每小时，随机分钟执行
	2) cron_time="$random_minute 0 * * *" ;; # 每天，随机分钟执行
	3) cron_time="$random_minute 0 * * 1" ;; # 每周，随机分钟执行
	*)
		echo "خطا: لطفا گزینه های معتبر را وارد کنید!"
		return
		;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "خطا: همگام سازی برنامه ریزی شده برای این کار از قبل وجود دارد!"
		return
	fi

	# 创建到用户的 crontab
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "وظیفه برنامه ریزی شده ایجاد شده است: $cron_job"
}

# 查看定时任务
view_tasks() {
	echo "وظایف برنامه ریزی شده فعلی:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	read -e -p "لطفا شماره کار را که باید حذف شود وارد کنید:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً یک شماره کار معتبر وارد کنید!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "کار برنامه ریزی شده با شماره کار $num حذف شده است"
}

# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "ابزار همگام سازی از راه دور Rsync"
		echo "همگام سازی بین دایرکتوری های راه دور از همگام سازی افزایشی پشتیبانی می کند که کارآمد و پایدار است."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. ایجاد یک کار جدید 2. حذف یک کار"
		echo "3. انجام همگام سازی محلی با سایت راه دور 4. انجام همگام سازی از راه دور با سایت محلی"
		echo "5. ایجاد یک کار برنامه ریزی شده 6. حذف یک کار زمان بندی شده"
		echo "---------------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "---------------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
		1) add_task ;;
		2) delete_task ;;
		3) run_task push ;;
		4) run_task pull ;;
		5) schedule_task ;;
		6) delete_task_schedule ;;
		0) break ;;
		*) echo "انتخاب نامعتبر است، لطفاً دوباره امتحان کنید." ;;
		esac
		read -e -p "برای ادامه Enter را فشار دهید..."
	done
}

linux_info() {

	clear
	send_stats "系统信息查询"

	ip_address

	local cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')

	local cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
		<(grep 'cpu ' /proc/stat) <(
			sleep 1
			grep 'cpu ' /proc/stat
		))

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

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

	local timezone=$(current_timezone)

	echo ""
	echo -e "پرس و جو اطلاعات سیستم"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}hostname: ${gl_bai}$hostname"
	echo -e "${gl_kjlan}نسخه سیستم: ${gl_bai}$os_info"
	echo -e "${gl_kjlan}نسخه لینوکس: ${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}معماری CPU: ${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}مدل CPU: ${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}تعداد هسته های CPU: ${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}فرکانس CPU: ${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}مصرف CPU: ${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan} بار سیستم: ${gl_bai}$load"
	echo -e "${gl_kjlan}حافظه فیزیکی: ${gl_bai}$mem_info"
	echo -e "${gl_kjlan}حافظه مجازی: ${gl_bai}$swap_info"
	echo -e "${gl_kjlan}مصرف هارد دیسک: ${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}مجموع دریافت: ${gl_bai}$rx"
	echo -e "${gl_kjlan}مجموع ارسال شده: ${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}الگوریتم شبکه: ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}اپراتور: ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}آدرس IPv4: ${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}آدرس IPv6: ${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}آدرس های DNS: ${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}موقعیت جغرافیایی: ${gl_bai}$country $city"
	echo -e "${gl_kjlan}زمان سیستم: ${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan} زمان اجرا: ${gl_bai}$runtime"
	echo

}

linux_tools() {

	while true; do
		clear
		# send_stats "基础工具"
		echo -e "ابزارهای اساسی"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ابزار دانلود ${gl_bai}curl ${gl_huang}★${gl_bai} ${gl_kjlan}2. ${gl_bai}wget ابزار دانلود ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}3. ${gl_bai}ابزار امتیاز مدیریت فوق العاده sudo ${gl_kjlan}4. ${gl_bai}ابزار ارتباطی socat"
		echo -e "${gl_kjlan}5. ${gl_bai}ابزار نظارت بر سیستم htop ${gl_kjlan}6. ${gl_bai}iftop ابزار نظارت بر ترافیک شبکه"
		echo -e "${gl_kjlan}7. ${gl_bai} فشرده سازی و فشرده سازی ZIP را از حالت فشرده خارج کنید ${gl_kjlan}8. ${gl_bai}tar GZ فشرده سازی و فشرده سازی ابزار"
		echo -e "${gl_kjlan}9. ${gl_bai}tmux ابزار اجرای پس زمینه چند کاناله ${gl_kjlan}10. ${gl_bai}ffmpeg ابزار پخش زنده رمزگذاری ویدیو"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11. ${gl_bai}btop ابزار نظارت مدرن ${gl_huang}★${gl_bai} ${gl_kjlan}12. ${gl_bai}ranger ابزار مدیریت فایل"
		echo -e "${gl_kjlan}13. ${gl_bai}ncdu ابزار مشاهده استفاده از دیسک ${gl_kjlan}14. ${gl_bai}fzf ابزار جستجوی جهانی"
		echo -e "${gl_kjlan}15. ${gl_bai}ویرایشگر متن vim ${gl_kjlan}16. ${gl_bai} ویرایشگر متن نانو ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}17. ${gl_bai}سیستم کنترل نسخه git"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21. ${gl_bai} محافظ صفحه نمایش ماتریس ${gl_kjlan}22. ${gl_bai} محافظ صفحه نمایش قطار"
		echo -e "${gl_kjlan}26. ${gl_bai} بازی کوچک تتریس ${gl_kjlan}27. ${gl_bai} بازی کوچک مار"
		echo -e "${gl_kjlan}28. ${gl_bai} مینی بازی Space Invaders"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31. ${gl_bai}همه نصب شده ${gl_kjlan}32. ${gl_bai}همه نصب شده (به استثنای محافظ های صفحه و بازی ها) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33. ${gl_bai}همه را حذف نصب کنید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41. ${gl_bai}ابزار مشخص شده ${gl_kjlan}42 را نصب کنید. ${gl_bai}ابزار مشخص شده را حذف نصب کنید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

		case $sub_choice in
		1)
			clear
			install curl
			clear
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
			curl --help
			send_stats "安装curl"
			;;
		2)
			clear
			install wget
			clear
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
			wget --help
			send_stats "安装wget"
			;;
		3)
			clear
			install sudo
			clear
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
			sudo --help
			send_stats "安装sudo"
			;;
		4)
			clear
			install socat
			clear
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
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
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
			unzip
			send_stats "安装unzip"
			;;
		8)
			clear
			install tar
			clear
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
			tar --help
			send_stats "安装tar"
			;;
		9)
			clear
			install tmux
			clear
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
			tmux --help
			send_stats "安装tmux"
			;;
		10)
			clear
			install ffmpeg
			clear
			echo "ابزار نصب شده است و به شرح زیر استفاده می شود:"
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
			read -e -p "لطفاً نام ابزار نصب شده (wget curl sudo htop) را وارد کنید:" installname
			install $installname
			send_stats "安装指定软件"
			;;
		42)
			clear
			read -e -p "لطفاً نام ابزار حذف شده (htop ufw tmux cmatrix) را وارد کنید:" removename
			remove $removename
			send_stats "卸载指定软件"
			;;

		0)
			kejilion
			;;

		*)
			echo "ورودی نامعتبر است!"
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
			echo "الگوریتم مسدود کردن TCP فعلی: $congestion_algorithm $queue_algorithm"

			echo ""
			echo "مدیریت BBR"
			echo "------------------------"
			echo "1. BBRv3 را روشن کنید 2. BBRv3 را خاموش کنید (باز راه اندازی می شود)"
			echo "------------------------"
			echo "0. به منوی قبلی برگردید"
			echo "------------------------"
			read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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
				break # 跳出循环，退出菜单
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
		echo -e "${BLUE}لیست پشتیبان فعلی:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "بدون پشتیبان"
	}

	# ----------------------------
	# 备份
	# ----------------------------
	backup_docker() {
		send_stats "Docker备份"

		echo -e "${YELLOW} پشتیبان گیری از ظرف Docker...${NC}"
		docker ps --format '{{.Names}}'
		read -e -p "لطفاً نام کانتینری که قرار است از آن نسخه پشتیبان تهیه شود را وارد کنید (فضاهای متعدد را جدا کرده و Enter را فشار دهید تا از همه کانتینرهای در حال اجرا نسخه پشتیبان تهیه کنید):" containers

		install tar jq gzip
		install_docker

		local BACKUP_ROOT="/tmp"
		local DATE_STR=$(date +%Y%m%d_%H%M%S)
		local TARGET_CONTAINERS=()
		if [ -z "$containers" ]; then
			mapfile -t TARGET_CONTAINERS < <(docker ps --format '{{.Names}}')
		else
			read -ra TARGET_CONTAINERS <<<"$containers"
		fi
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && {
			echo -e "${RED} ظرف ${NC} یافت نشد"
			return
		}

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" >"$RESTORE_SCRIPT"
		echo "set -e" >>"$RESTORE_SCRIPT"
		echo "# اسکریپت بازیابی به صورت خودکار ایجاد می شود" >>"$RESTORE_SCRIPT"

		# 记录已打包过的 Compose 项目路径，避免重复打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN} ظرف پشتیبان: $c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" >"$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE} تشخیص داد که $c یک محفظه docker-compose ${NC} است"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p "دایرکتوری نوشتن شناسایی نشد، لطفا مسیر را به صورت دستی وارد کنید:" project_dir
				fi

				# 如果该 Compose 项目已经打包过，跳过
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}نوشتن پروژه [$project_name] پشتیبان‌گیری شده است، از بسته‌بندی مکرر بگذرید...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" >"${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" >"${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# بازیابی docker-compose: $project_name" >>"$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >>"$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}نوشتن پروژه [$project_name] بسته بندی شده: ${project_dir}${NC}"
				else
					echo -e "${RED} docker-compose.yml یافت نشد، از این ظرف صرفنظر می کنم... ${NC}"
				fi
			else
				# 普通容器备份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "حجم بسته بندی شده: $path"
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

				echo -e "\n# ظرف را بازیابی کنید: $c" >>"$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >>"$RESTORE_SCRIPT"
			fi
		done

		# 备份 /home/docker 下的所有文件（不含子目录）
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE} پشتیبان‌گیری از فایل‌ها در /home/docker...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "فایل‌های زیر ${GREEN}/home/docker به این آدرس بسته‌بندی شده‌اند: ${BACKUP_DIR}/home_docker_files.tar.gz${NC}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN} پشتیبان گیری تکمیل شد: ${BACKUP_DIR}${NC}"
		echo -e "${GREEN}اسکریپت های بازیابی موجود: ${RESTORE_SCRIPT}${NC}"

	}

	# ----------------------------
	# 还原
	# ----------------------------
	restore_docker() {

		send_stats "Docker还原"
		read -e -p "لطفاً دایرکتوری پشتیبان را برای بازیابی وارد کنید:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}دایرکتوری پشتیبان وجود ندارد${NC}"
			return
		}

		echo -e "${BLUE} عملیات بازیابی را آغاز می کند...${NC}"

		install tar jq gzip
		install_docker

		# --------- 优先还原 Compose 项目 ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p "مسیر اصلی پیدا نشد، لطفا مسیر بازیابی دایرکتوری را وارد کنید:" original_path

				# 检查该 compose 项目的容器是否已经在运行
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${YELLOW}Compose پروژه [$project_name] از قبل دارای یک محفظه در حال اجرا است، از بازیابی رد می شود...${NC}"
					continue
				fi

				read -e -p "بازیابی پروژه نوشتن [$project_name] در مسیر [$original_path] را تأیید می‌کنید؟ (y/N):" confirm
				[[ "$confirm" != "y" ]] && read -e -p "لطفا یک مسیر بازیابی جدید وارد کنید:" original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN}Compose پروژه [$project_name] استخراج شده است: $original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN}نوشتن پروژه [$project_name] بازیابی کامل شد! ${NC}"
			fi
		done

		# --------- 继续还原普通容器 ---------
		echo -e "${BLUE} ظروف Docker معمولی را بررسی و بازیابی کنید... ${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "ظرف پردازش ${GREEN}: $container${NC}"

			# 检查容器是否已经存在且正在运行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}Container [$container] از قبل در حال اجرا است، از بازیابی رد می شود...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && {
				echo -e "${RED} اطلاعات آینه یافت نشد، صرفنظر شد: $container${NC}"
				continue
			}

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
					echo "بازیابی اطلاعات حجم: $VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 删除已存在但未运行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}Container [$container] وجود دارد اما در حال اجرا نیست، ظرف قدیمی را حذف کنید...${NC}"
				docker rm -f "$container"
			fi

			# 启动容器
			echo "دستور restore را اجرا کنید: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW} هیچ اطلاعات پشتیبان برای کانتینرهای رایج یافت نشد ${NC}"

		# 还原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE} در حال بازیابی فایل ها در /home/docker...${NC} است"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "فایل‌های زیر ${GREEN}/home/docker بازیابی شدند ${NC}"
		else
			echo -e "${YELLOW} پشتیبان‌گیری از فایل‌های زیر /home/docker یافت نشد، پرش... ${NC}"
		fi

	}

	# ----------------------------
	# 迁移
	# ----------------------------
	migrate_docker() {
		send_stats "Docker迁移"
		install jq
		read -e -p "لطفاً دایرکتوری پشتیبان برای انتقال را وارد کنید:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}دایرکتوری پشتیبان وجود ندارد${NC}"
			return
		}

		read -e -p "IP سرور هدف:" TARGET_IP
		read -e -p "نام کاربری SSH سرور هدف:" TARGET_USER
		read -e -p "پورت SSH سرور هدف [پیش‌فرض 22]:" TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW}در حال انتقال نسخه پشتیبان...${NC}"
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
		read -e -p "لطفا دایرکتوری پشتیبان را وارد کنید تا حذف شود:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}دایرکتوری پشتیبان وجود ندارد${NC}"
			return
		}
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN} نسخه پشتیبان حذف شده: ${BACKUP_DIR}${NC}"
	}

	# ----------------------------
	# 主菜单
	# ----------------------------
	main_menu() {
		send_stats "Docker备份迁移还原"
		while true; do
			clear
			echo "------------------------"
			echo -e "ابزار پشتیبان گیری / مهاجرت / بازیابی Docker"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. از پروژه داکر نسخه پشتیبان تهیه کنید"
			echo -e "2. مهاجرت پروژه داکر"
			echo -e "3. پروژه docker را بازیابی کنید"
			echo -e "4. فایل پشتیبان پروژه docker را حذف کنید"
			echo "------------------------"
			echo -e "0. به منوی قبلی برگردید"
			echo "------------------------"
			read -e -p "لطفا انتخاب کنید:" choice
			case $choice in
			1) backup_docker ;;
			2) migrate_docker ;;
			3) restore_docker ;;
			4) delete_backup ;;
			0) return ;;
			*) echo -e "${RED}گزینه نامعتبر ${NC}" ;;
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
		echo -e "مدیریت داکر"
		docker_tato
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai}نصب و به روز رسانی محیط Docker ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}2. ${gl_bai} مشاهده وضعیت جهانی Docker ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3. ${gl_bai}مدیریت کانتینر داکر ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}4. ${gl_bai}مدیریت تصویر داکر"
		echo -e "${gl_kjlan}5. ${gl_bai}مدیریت شبکه Docker"
		echo -e "${gl_kjlan}6. ${gl_bai}مدیریت حجم داکر"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}7. ${gl_bai} محفظه های بی فایده docker را تمیز کنید و حجم داده های شبکه را منعکس کنید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}8. ${gl_bai}منبع Docker را جایگزین کنید"
		echo -e "${gl_kjlan}9. ${gl_bai}ویرایش فایل daemon.json"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11. ${gl_bai} دسترسی Docker-ipv6 را فعال کنید"
		echo -e "${gl_kjlan}12. ${gl_bai}دسترسی Docker-ipv6 را ببندید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}19. ${gl_bai} پشتیبان گیری/ مهاجرت/بازیابی محیط Docker"
		echo -e "${gl_kjlan}20. ${gl_bai}محیط Docker را حذف نصب کنید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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
			echo "نسخه داکر"
			docker -v
			docker compose version

			echo ""
			echo -e "تصویر داکر: ${gl_lv}$image_count${gl_bai}"
			docker image ls
			echo ""
			echo -e "ظرف داکر: ${gl_lv}$container_count${gl_bai}"
			docker ps -a
			echo ""
			echo -e "حجم داکر: ${gl_lv}$volume_count${gl_bai}"
			docker volume ls
			echo ""
			echo -e "شبکه داکر: ${gl_lv}$network_count${gl_bai}"
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
				echo "لیست شبکه داکر"
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
					done <<<"$network_info"
				done

				echo ""
				echo "عملیات شبکه"
				echo "------------------------"
				echo "1. یک شبکه ایجاد کنید"
				echo "2. به شبکه بپیوندید"
				echo "3. از شبکه خارج شوید"
				echo "4. شبکه را حذف کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				case $sub_choice in
				1)
					send_stats "创建网络"
					read -e -p "تنظیم نام شبکه جدید:" dockernetwork
					docker network create $dockernetwork
					;;
				2)
					send_stats "加入网络"
					read -e -p "اضافه کردن نام شبکه:" dockernetwork
					read -e -p "کدام کانتینرها به شبکه می پیوندند (لطفاً نام چند کانتینر را با فاصله جدا کنید):" dockernames

					for dockername in $dockernames; do
						docker network connect $dockernetwork $dockername
					done
					;;
				3)
					send_stats "加入网络"
					read -e -p "خروج از نام شبکه:" dockernetwork
					read -e -p "آن کانتینرها از شبکه خارج می شوند (لطفاً نام چند کانتینر را با فاصله جدا کنید):" dockernames

					for dockername in $dockernames; do
						docker network disconnect $dockernetwork $dockername
					done

					;;

				4)
					send_stats "删除网络"
					read -e -p "لطفاً نام شبکه ای که باید حذف شود را وارد کنید:" dockernetwork
					docker network rm $dockernetwork
					;;

				*)
					break # 跳出循环，退出菜单
					;;
				esac
			done
			;;

		6)
			while true; do
				clear
				send_stats "Docker卷管理"
				echo "لیست حجم داکر"
				docker volume ls
				echo ""
				echo "عملیات حجمی"
				echo "------------------------"
				echo "1. یک جلد جدید ایجاد کنید"
				echo "2. حجم مشخص شده را حذف کنید"
				echo "3. تمام جلدها را حذف کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				case $sub_choice in
				1)
					send_stats "新建卷"
					read -e -p "تنظیم نام حجم جدید:" dockerjuan
					docker volume create $dockerjuan

					;;
				2)
					read -e -p "نام جلد حذف را وارد کنید (لطفا نام چندین جلد را با فاصله جدا کنید):" dockerjuans

					for dockerjuan in $dockerjuans; do
						docker volume rm $dockerjuan
					done

					;;

				3)
					send_stats "删除所有卷"
					read -e -p "$(echo -e "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می خواهید تمام جلدهای استفاده نشده را حذف کنید؟ (y/N):")" choice
					case "$choice" in
					[Yy])
						docker volume prune -f
						;;
					[Nn]) ;;
					*)
						echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
						;;
					esac
					;;

				*)
					break # 跳出循环，退出菜单
					;;
				esac
			done
			;;
		7)
			clear
			send_stats "Docker清理"
			read -e -p "$(echo -e "${gl_huang} نکته: ${gl_bai} شبکه محفظه تصویر بی فایده، از جمله کانتینرهای متوقف شده را پاکسازی می کند. مطمئنی پاکش می کنی؟ (y/N):")" choice
			case "$choice" in
			[Yy])
				docker system prune -af --volumes
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			read -e -p "$(echo -e "${gl_hong}نکته: ${gl_bai}آیا مطمئن هستید که محیط docker را حذف نصب می کنید؟ (y/N):")" choice
			case "$choice" in
			[Yy])
				docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				remove docker docker-compose docker-ce docker-ce-cli containerd.io
				rm -f /etc/docker/daemon.json
				hash -r
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion
			;;
		*)
			echo "ورودی نامعتبر است!"
			;;
		esac
		break_end

	done

}

linux_test() {

	while true; do
		clear
		# send_stats "测试脚本合集"
		echo -e "مجموعه اسکریپت تست"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}IP و باز کردن قفل تشخیص وضعیت"
		echo -e "${gl_kjlan}1. ${gl_bai}تشخیص وضعیت باز کردن قفل ChatGPT"
		echo -e "${gl_kjlan}2. ${gl_bai}آزمون باز کردن قفل رسانه جریانی منطقه"
		echo -e "${gl_kjlan}3. ${gl_bai}yeahwu تشخیص باز کردن قفل رسانه جریانی"
		echo -e "${gl_kjlan}4. ${gl_bai}xykt اسکریپت بازرسی کیفیت IP ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}آزمایش سرعت خط شبکه"
		echo -e "${gl_kjlan}11. ${gl_bai}besttrace تست مسیریابی تاخیر بک هال سه شبکه"
		echo -e "${gl_kjlan}12. ${gl_bai}mtr_trace تست خط بک هال سه شبکه"
		echo -e "${gl_kjlan}13. ${gl_bai}تست سرعت سه شبکه سوپرسرعت"
		echo -e "${gl_kjlan}14. ${gl_bai}nxtrace اسکریپت تست بازگشت سریع"
		echo -e "${gl_kjlan}15. ${gl_bai}nxtrace اسکریپت تست IP Backhaul را مشخص می کند"
		echo -e "${gl_kjlan}16. ${gl_bai}ludashi2020 تست سه خط شبکه"
		echo -e "${gl_kjlan}17. اسکریپت تست سرعت چند منظوره ${gl_bai}i-abc"
		echo -e "${gl_kjlan}18. ${gl_bai}NetQuality اسکریپت بررسی کیفیت شبکه ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}تست عملکرد سخت افزار"
		echo -e "${gl_kjlan}21. تست عملکرد ${gl_bai}yabs"
		echo -e "${gl_kjlan}22. اسکریپت تست عملکرد CPU ${gl_bai}icu/gb5"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan} آزمون جامع"
		echo -e "${gl_kjlan}31. ${gl_bai}تست عملکرد نیمکت"
		echo -e "${gl_kjlan}32. ${gl_bai}spiritsdx Fusion Monster Evaluation ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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
			curl nxtrace.org/nt | bash
			nexttrace --fast-trace --tcp
			;;
		15)
			clear
			send_stats "nxtrace指定IP回程测试脚本"
			echo "لیست IP مرجع"
			echo "------------------------"
			echo "Beijing Telecom: 219.141.136.12"
			echo "Beijing Unicom: 202.106.50.1"
			echo "پکن موبایل: 221.179.155.161"
			echo "مخابرات شانگهای: 202.96.209.133"
			echo "Shanghai Unicom: 210.22.97.1"
			echo "شانگهای موبایل: 211.136.112.200"
			echo "گوانگژو مخابرات: 58.60.188.222"
			echo "Guangzhou China Unicom: 210.21.196.6"
			echo "تلفن همراه گوانگژو: 120.196.165.24"
			echo "Chengdu Telecom: 61.139.2.69"
			echo "چنگدو چین Unicom: 119.6.6.6"
			echo "موبایل چنگدو: 211.137.96.205"
			echo "هونان مخابرات: 36.111.200.100"
			echo "Hunan Unicom: 42.48.16.100"
			echo "هونان موبایل: 39.134.254.6"
			echo "------------------------"

			read -e -p "یک IP خاص وارد کنید:" testip
			curl nxtrace.org/nt | bash
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
			echo "ورودی نامعتبر است!"
			;;
		esac
		break_end

	done

}

linux_Oracle() {

	while true; do
		clear
		send_stats "甲骨文云脚本合集"
		echo -e "مجموعه اسکریپت ابری اوراکل"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai} اسکریپت فعال ماشین بیکار را نصب کنید"
		echo -e "${gl_kjlan}2. ${gl_bai} اسکریپت فعال را از دستگاه بیکار حذف نصب کنید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3. ${gl_bai}DD اسکریپت سیستم را دوباره نصب کنید"
		echo -e "${gl_kjlan}4. ${gl_bai}R اسکریپت راه اندازی کارآگاه"
		echo -e "${gl_kjlan}5. ${gl_bai} حالت ورود رمز عبور ROOT را روشن کنید"
		echo -e "${gl_kjlan}6. ${gl_bai}ابزار بازیابی IPV6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

		case $sub_choice in
		1)
			clear
			echo "اسکریپت فعال: مصرف CPU 10-20% مصرف حافظه 20%"
			read -e -p "آیا مطمئن هستید که می خواهید آن را نصب کنید؟ (y/N):" choice
			case "$choice" in
			[Yy])

				install_docker

				# 设置默认值
				local DEFAULT_CPU_CORE=1
				local DEFAULT_CPU_UTIL="10-20"
				local DEFAULT_MEM_UTIL=20
				local DEFAULT_SPEEDTEST_INTERVAL=120

				# 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				read -e -p "لطفاً تعداد هسته‌های CPU را وارد کنید [پیش‌فرض: $DEFAULT_CPU_CORE]:" cpu_core
				local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				read -e -p "لطفاً محدوده درصد استفاده از CPU را وارد کنید (مثلاً 10-20) [پیش‌فرض: $DEFAULT_CPU_UTIL]:" cpu_util
				local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				read -e -p "لطفاً درصد مصرف حافظه را وارد کنید [پیش‌فرض: $DEFAULT_MEM_UTIL]:" mem_util
				local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				read -e -p "لطفاً زمان بازه تست سرعت (ثانیه) را وارد کنید [پیش‌فرض: $DEFAULT_SPEEDTEST_INTERVAL]:" speedtest_interval
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
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			echo "سیستم را دوباره نصب کنید"
			echo "--------------------------------"
			echo -e "${gl_hong} توجه: ${gl_bai} نصب مجدد ممکن است باعث قطع اتصال شود، اگر نگران هستید با احتیاط استفاده کنید. انتظار می رود نصب مجدد 15 دقیقه طول بکشد، لطفاً از اطلاعات خود از قبل نسخه پشتیبان تهیه کنید."
			read -e -p "آیا مطمئن هستید که می خواهید ادامه دهید؟ (y/N):" choice

			case "$choice" in
			[Yy])
				while true; do
					read -e -p "لطفاً سیستمی را که می خواهید دوباره نصب کنید انتخاب کنید: 1. Debian12 | 2. Ubuntu20.04:" sys_choice

					case "$sys_choice" in
					1)
						local xitong="-d 12"
						break # 结束循环
						;;
					2)
						local xitong="-u 20.04"
						break # 结束循环
						;;
					*)
						echo "انتخاب نامعتبر است، لطفاً دوباره وارد کنید."
						;;
					esac
				done

				read -e -p "لطفا پس از نصب مجدد رمز عبور خود را وارد کنید:" vpspasswd
				install wget
				bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
				send_stats "甲骨文云重装系统脚本"
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			echo "این تابع توسط jhb ارائه شده است، از او متشکرم!"
			send_stats "ipv6修复"
			;;
		0)
			kejilion

			;;
		*)
			echo "ورودی نامعتبر است!"
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

	if command -v docker &>/dev/null; then
		echo -e "${gl_kjlan}------------------------"
		echo -e "محیط ${gl_lv} نصب کرده است ${gl_bai} ظرف: ${gl_lv}$container_count${gl_bai} تصویر: ${gl_lv}$image_count${gl_bai} شبکه: ${gl_lv}_PROTECT_0___$Network ${gl_lv}$volume_count${gl_bai}"
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
			echo -e "محیط ${gl_lv} نصب شده است ${gl_bai} سایت: $output پایگاه داده: $db_output"
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
		echo -e "${gl_huang}ساخت وب سایت LDNMP"
		ldnmp_tato
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}1. ${gl_bai}محیط LDNMP ${gl_huang}★${gl_bai} ${gl_huang}2 را نصب کنید. ${gl_bai}وردپرس را نصب کنید ${gl_huang}★${gl_bai}"
		echo -e "${gl_huang}3. ${gl_bai} Forum Discuz ${gl_huang}4 را نصب کنید. ${gl_bai} Kedao Cloud Desktop را نصب کنید"
		echo -e "${gl_huang}5. ${gl_bai}Apple CMS Movie and TV Station ${gl_huang}6 را نصب کنید. ${gl_bai}شبکه کارت دیجیتال Unicorn را نصب کنید"
		echo -e "${gl_huang}7. ${gl_bai}وب سایت انجمن flarum ${gl_huang}8 را نصب کنید. ${gl_bai}وبسایت وبلاگ سبک وزن typecho را نصب کنید"
		echo -e "${gl_huang}9. ${gl_bai}پلتفرم پیوند اشتراک گذاری LinkStack ${gl_huang}20 را نصب کنید. ${gl_bai}سایت پویا را سفارشی کنید"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}21. ${gl_bai} فقط nginx ${gl_huang}★${gl_bai} ${gl_huang}22 را نصب کنید. ${gl_bai}تغییر مسیر سایت"
		echo -e "${gl_huang}23. ${gl_bai}پراکسی معکوس سایت + درگاه ${gl_huang}★${gl_bai} ${gl_huang}24. ${gl_bai}نام دامنه معکوس پروکسی سایت"
		echo -e "${gl_huang}25. ${gl_bai}پلتفرم مدیریت رمز عبور Bitwarden ${gl_huang}26 را نصب کنید. ${gl_bai}وب سایت وبلاگ Halo را نصب کنید"
		echo -e "${gl_huang}27. ${gl_bai}نصب AI painting prompt word generator ${gl_huang}28. ${gl_bai}معادل بار پراکسی معکوس سایت"
		echo -e "${gl_huang}29. ${gl_bai} انتقال پراکسی چهار لایه جریانی ${gl_huang}30. ${gl_bai}سایت استاتیک سفارشی شده"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}31. ${gl_bai}مدیریت داده های سایت ${gl_huang}★${gl_bai} ${gl_huang}32. ${gl_bai} از تمام داده های سایت پشتیبان تهیه کنید"
		echo -e "${gl_huang}33. ${gl_bai} پشتیبان گیری از راه دور برنامه ریزی شده ${gl_huang}34. ${gl_bai} کل داده های سایت را بازیابی کنید"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}35. ${gl_bai} محافظت از محیط LDNMP ${gl_huang}36. ${gl_bai} محیط LDNMP را بهینه کنید"
		echo -e "${gl_huang}37. ${gl_bai}محیط LDNMP ${gl_huang}38 را به‌روزرسانی کنید. ${gl_bai}محیط LDNMP را حذف نصب کنید"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_huang}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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
			webname="انجمن Discuz"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo "آدرس پایگاه داده: mysql"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			echo "پیشوند جدول: discuz_"

			;;

		4)
			clear
			# 可道云桌面
			webname="دسکتاپ ابری Kedao"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo "آدرس پایگاه داده: mysql"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			echo "نام پایگاه داده: $dbname"
			echo "میزبان redis: redis"

			;;

		5)
			clear
			# 苹果CMS
			webname="AppleCMS"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo "آدرس پایگاه داده: mysql"
			echo "پورت پایگاه داده: 3306"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			echo "پیشوند پایگاه داده: mac_"
			echo "------------------------"
			echo "پس از نصب موفقیت آمیز، وارد آدرس Backend شوید"
			echo "https://$yuming/vip.php"

			;;

		6)
			clear
			# 独脚数卡
			webname="کارت شماره یک پا"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo "آدرس پایگاه داده: mysql"
			echo "پورت پایگاه داده: 3306"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			echo ""
			echo "آدرس redis: redis"
			echo "رمز عبور redis: به طور پیش فرض پر نشده است"
			echo "پورت redis: 6379"
			echo ""
			echo "آدرس وب سایت: https://$yuming"
			echo "مسیر ورود به سیستم Backend: /admin"
			echo "------------------------"
			echo "نام کاربری: ادمین"
			echo "رمز عبور: admin"
			echo "------------------------"
			echo "اگر هنگام ورود به سیستم یک خطای قرمز رنگ ۰ در گوشه سمت راست بالا ظاهر شد، لطفا از دستور زیر استفاده کنید:"
			echo "من هم خیلی عصبانی هستم که چرا کارت شماره تک شاخ اینقدر دردسر ساز است و چنین مشکلاتی دارد!"
			echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

			;;

		7)
			clear
			# flarum论坛
			webname="انجمن flarum"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo "آدرس پایگاه داده: mysql"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			echo "پیشوند جدول: flarum_"
			echo "اطلاعات مدیر را می توان توسط شخص تنظیم کرد"

			;;

		8)
			clear
			# typecho
			webname="تایپچو"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo "پیشوند پایگاه داده: typecho_"
			echo "آدرس پایگاه داده: mysql"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			echo "نام پایگاه داده: $dbname"

			;;

		9)
			clear
			# LinkStack
			webname="LinkStack"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo "آدرس پایگاه داده: mysql"
			echo "پورت پایگاه داده: 3306"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			;;

		20)
			clear
			webname="سایت پویا پی اچ پی"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo -e "[${gl_huang}1/6${gl_bai}] کد منبع PHP را آپلود کنید"
			echo "-------------"
			echo "در حال حاضر، فقط بسته های کد منبع با فرمت zip مجاز به آپلود هستند. لطفا بسته های کد منبع را در فهرست /home/web/html/${yuming} قرار دهید."
			read -e -p "همچنین می توانید برای دانلود بسته کد منبع از راه دور، لینک دانلود را وارد کنید. برای رد شدن از دانلود از راه دور، مستقیماً Enter را فشار دهید:" url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/6${gl_bai}] مسیری که index.php در آن قرار دارد"
			echo "-------------"
			# find "$(realpath .)" -name "index.php" -print
			find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

			read -e -p "لطفا مسیر index.php را مشابه (/home/web/html/$yuming/wordpress/) وارد کنید:" index_lujing

			sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
			sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}3/6${gl_bai}] لطفاً نسخه PHP را انتخاب کنید"
			echo "-------------"
			read -e -p "1. php آخرین نسخه | 2. php7.4:" pho_v
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
				echo "انتخاب نامعتبر است، لطفاً دوباره وارد کنید."
				;;
			esac

			clear
			echo -e "[${gl_huang}4/6${gl_bai}] برنامه افزودنی مشخص شده را نصب کنید"
			echo "-------------"
			echo "افزونه های نصب شده"
			docker exec php php -m

			read -e -p "$(echo -e "نام برنامه افزودنی را که باید نصب شود، وارد کنید، مانند ${gl_huang}SourceGuardian imap ftp${gl_bai} و غیره. برای رد شدن از نصب، مستقیماً Enter را فشار دهید:")" php_extensions
			if [ -n "$php_extensions" ]; then
				docker exec $PHP_Version install-php-extensions $php_extensions
			fi

			clear
			echo -e "[${gl_huang}5/6${gl_bai}] ویرایش پیکربندی سایت"
			echo "-------------"
			echo "برای ادامه هر کلید را فشار دهید. می توانید پیکربندی سایت را با جزئیات تنظیم کنید، مانند محتوای شبه استاتیک."
			read -n 1 -s -r -p ""
			install nano
			nano /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}6/6${gl_bai}] مدیریت پایگاه داده"
			echo "-------------"
			read -e -p "1. من یک سایت جدید می سازم 2. من یک سایت قدیمی می سازم و یک نسخه پشتیبان از پایگاه داده دارم:" use_db
			case $use_db in
			1)
				echo
				;;
			2)
				echo "پشتیبان‌گیری از پایگاه داده باید یک بسته فشرده باشد که به .gz ختم می‌شود. لطفاً آن را در دایرکتوری /home/ قرار دهید تا از واردات داده های پشتیبان Pagoda/1panel پشتیبانی کند."
				read -e -p "همچنین می توانید لینک دانلود را وارد کنید تا اطلاعات پشتیبان را از راه دور دانلود کنید. برای رد شدن از دانلود از راه دور، مستقیماً Enter را فشار دهید:" url_download_db

				cd /home/
				if [ -n "$url_download_db" ]; then
					wget "$url_download_db"
				fi
				gunzip $(ls -t *.gz | head -n 1)
				latest_sql=$(ls -t *.sql | head -n 1)
				dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname <"/home/$latest_sql"
				echo "داده های جدول وارد شده توسط پایگاه داده"
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
				rm -f *.sql
				echo "وارد کردن پایگاه داده تکمیل شد"
				;;
			*)
				echo
				;;
			esac

			docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

			restart_ldnmp
			ldnmp_web_on
			prefix="web$(shuf -i 10-99 -n 1)_"
			echo "آدرس پایگاه داده: mysql"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbususepasswd"
			echo "پیشوند جدول: پیشوند $"
			echo "اطلاعات ورود مدیر توسط خودتان تنظیم می شود"

			;;

		21)
			ldnmp_install_status_one
			nginx_install_all
			;;

		22)
			clear
			webname="تغییر مسیر سایت"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
			add_yuming
			read -e -p "لطفاً نام دامنه تغییر مسیر را وارد کنید:" reverseproxy
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
				echo "IP+پورت دسترسی به سرویس مسدود شده است"
			else
				ip_address
				block_container_port "$docker_name" "$ipv4_address"
			fi

			;;

		24)
			clear
			webname="معکوس کردن نام دامنه پروکسی"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
			add_yuming
			echo -e "قالب نام دامنه: ${gl_huang}google.com${gl_bai}"
			read -e -p "لطفا نام دامنه پروکسی معکوس خود را وارد کنید:" fandai_yuming
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
			echo "شروع به استقرار $webname کنید"
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
			webname="هاله"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			webname="مولد کلمه سریع نقاشی هوش مصنوعی"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			webname="سایت استاتیک"
			send_stats "安装$webname"
			echo "شروع به استقرار $webname کنید"
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
			echo -e "[${gl_huang}1/2${gl_bai}] بارگذاری کد منبع ثابت"
			echo "-------------"
			echo "در حال حاضر، فقط بسته های کد منبع با فرمت zip مجاز به آپلود هستند. لطفا بسته های کد منبع را در فهرست /home/web/html/${yuming} قرار دهید."
			read -e -p "همچنین می توانید برای دانلود بسته کد منبع از راه دور، لینک دانلود را وارد کنید. برای رد شدن از دانلود از راه دور، مستقیماً Enter را فشار دهید:" url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/2${gl_bai}] مسیری که index.html در آن قرار دارد"
			echo "-------------"
			# find "$(realpath .)" -name "index.html" -print
			find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

			read -e -p "لطفاً مسیر index.html را مشابه (/home/web/html/$yuming/index/) وارد کنید:" index_lujing

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
			echo -e "${gl_huang} در حال پشتیبان گیری از $backup_filename ...${gl_bai}"
			cd /home/ && tar czvf "$backup_filename" web

			while true; do
				clear
				echo "فایل پشتیبان ایجاد شد: /home/$backup_filename"
				read -e -p "آیا می خواهید اطلاعات پشتیبان را به یک سرور راه دور منتقل کنید؟ (y/N):" choice
				case "$choice" in
				[Yy])
					read -e -p "لطفا IP سرور راه دور را وارد کنید:" remote_ip
					read -e -p "پورت SSH سرور هدف [پیش‌فرض 22]:" TARGET_PORT
					local TARGET_PORT=${TARGET_PORT:-22}
					if [ -z "$remote_ip" ]; then
						echo "خطا: لطفاً IP سرور راه دور را وارد کنید."
						continue
					fi
					local latest_tar=$(ls -t /home/*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
						echo "فایل به فهرست اصلی سرور راه دور منتقل شده است."
					else
						echo "فایلی که قرار است منتقل شود پیدا نشد."
					fi
					break
					;;
				[Nn])
					break
					;;
				*)
					echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
					;;
				esac
			done
			;;

		33)
			clear
			send_stats "定时远程备份"
			read -e -p "IP سرور راه دور را وارد کنید:" useip
			read -e -p "رمز عبور سرور راه دور را وارد کنید:" usepasswd

			cd ~
			wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh >/dev/null 2>&1
			chmod +x ${useip}_beifen.sh

			sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
			sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

			echo "------------------------"
			echo "1. پشتیبان گیری هفتگی 2. پشتیبان گیری روزانه"
			read -e -p "لطفا انتخاب خود را وارد کنید:" dingshi

			case $dingshi in
			1)
				check_crontab_installed
				read -e -p "روز هفته را برای پشتیبان گیری هفتگی انتخاب کنید (0-6، 0 نشان دهنده یکشنبه است):" weekday
				(
					crontab -l
					echo "0 0 * * $weekday ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			2)
				check_crontab_installed
				read -e -p "انتخاب زمان پشتیبان گیری روزانه (ساعت، 0-23):" hour
				(
					crontab -l
					echo "0 $hour * * * ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			*)
				break # 跳出
				;;
			esac

			install sshpass

			;;

		34)
			root_use
			send_stats "LDNMP环境还原"
			echo "بک آپ های سایت موجود"
			echo "-------------------------"
			ls -lt /home/*.gz | awk '{print $NF}'
			echo ""
			read -e -p "برای بازیابی آخرین نسخه پشتیبان، کلید Enter را فشار دهید، نام فایل پشتیبان را برای بازیابی نسخه پشتیبان مشخص شده وارد کنید، برای خروج 0 را وارد کنید:" filename

			if [ "$filename" == "0" ]; then
				break_end
				linux_ldnmp
			fi

			# 如果用户没有输入文件名，使用最新的压缩包
			if [ -z "$filename" ]; then
				local filename=$(ls -t /home/*.tar.gz | head -1)
			fi

			if [ -n "$filename" ]; then
				cd /home/web/ >/dev/null 2>&1
				docker compose down >/dev/null 2>&1
				rm -rf /home/web >/dev/null 2>&1

				echo -e "${gl_huang} $filename را از حالت فشرده خارج می کند ...${gl_bai}"
				cd /home/ && tar -xzf "$filename"

				check_port
				install_dependency
				install_docker
				install_certbot
				install_ldnmp
			else
				echo "بسته فشرده یافت نشد."
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
				echo "محیط LDNMP را به روز کنید"
				echo "------------------------"
				ldnmp_v
				echo "نسخه جدید کامپوننت پیدا شد"
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
				echo "1. به روز رسانی nginx 2. به روز رسانی mysql 3. به روز رسانی php 4. به روز رسانی redis"
				echo "------------------------"
				echo "5. محیط کامل را به روز کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
				case $sub_choice in
				1)
					nginx_upgrade

					;;

				2)
					local ldnmp_pods="mysql"
					read -e -p "لطفاً شماره نسخه ${ldnmp_pods} را وارد کنید (به عنوان مثال: 8.0 8.3 8.4 9.0) (برای دریافت آخرین نسخه، enter را فشار دهید):" version
					local version=${version:-latest}

					cd /home/web/
					cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
					sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
					docker rm -f $ldnmp_pods
					docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
					docker compose up -d --force-recreate $ldnmp_pods
					docker restart $ldnmp_pods
					cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
					send_stats "更新$ldnmp_pods"
					echo "به‌روزرسانی ${ldnmp_pods} تکمیل شد"

					;;
				3)
					local ldnmp_pods="php"
					read -e -p "لطفاً شماره نسخه ${ldnmp_pods} را وارد کنید (به عنوان مثال: 7.4 8.0 8.1 8.2 8.3) (برای دریافت آخرین نسخه، enter را فشار دهید):" version
					local version=${version:-8.3}
					cd /home/web/
					cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
					sed -i "s/kjlion\///g" /home/web/docker-compose.yml >/dev/null 2>&1
					sed -i "s/image: php:fpm-alpine/image: php:${version}-fpm-alpine/" /home/web/docker-compose.yml
					docker rm -f $ldnmp_pods
					docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
					docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi >/dev/null 2>&1
					docker compose up -d --force-recreate $ldnmp_pods
					docker exec php chown -R www-data:www-data /var/www/html

					run_command docker exec php sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories >/dev/null 2>&1

					docker exec php apk update
					curl -sL ${gh_proxy}github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions
					docker exec php mkdir -p /usr/local/bin/
					docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/
					docker exec php chmod +x /usr/local/bin/install-php-extensions
					docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis imagick soap

					docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/max_input_vars.ini' >/dev/null 2>&1

					fix_phpfpm_con $ldnmp_pods

					docker restart $ldnmp_pods >/dev/null 2>&1
					cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
					send_stats "更新$ldnmp_pods"
					echo "به‌روزرسانی ${ldnmp_pods} تکمیل شد"

					;;
				4)
					local ldnmp_pods="redis"
					cd /home/web/
					docker rm -f $ldnmp_pods
					docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
					docker compose up -d --force-recreate $ldnmp_pods
					docker restart $ldnmp_pods >/dev/null 2>&1
					restart_redis
					send_stats "更新$ldnmp_pods"
					echo "به‌روزرسانی ${ldnmp_pods} تکمیل شد"

					;;
				5)
					read -e -p "$(echo -e "${gl_huang} نکته: ${gl_bai} کاربرانی که برای مدت طولانی محیط را به روز نمی کنند، لطفاً محیط LDNMP را با دقت به روز کنند، زیرا خطر خرابی به روز رسانی پایگاه داده وجود دارد. آیا مطمئن هستید که می خواهید محیط LDNMP را به روز کنید؟ (y/N):")" choice
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
					*) ;;
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
			read -e -p "$(echo -e "${gl_hong} اکیداً توصیه می شود: ${gl_bai} ابتدا از تمام داده های وب سایت نسخه پشتیبان تهیه کنید و سپس محیط LDNMP را حذف نصب کنید. آیا مطمئن هستید که می خواهید تمام داده های وب سایت را حذف کنید؟ (y/N):")" choice
			case "$choice" in
			[Yy])
				cd /home/web/
				docker compose down --rmi all
				docker compose -f docker-compose.phpmyadmin.yml down >/dev/null 2>&1
				docker compose -f docker-compose.phpmyadmin.yml down --rmi all >/dev/null 2>&1
				rm -rf /home/web
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion
			;;

		*)
			echo "ورودی نامعتبر است!"
			;;
		esac
		break_end

	done

}

linux_panel() {

	local sub_choice="$1"

	while true; do

		if [ -z "$sub_choice" ]; then
			clear
			echo -e "بازار اپلیکیشن"
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

			echo -e "${gl_kjlan}1. ${color1} Pagoda Panel نسخه رسمی ${gl_kjlan}2. ${color2}aaPanel Pagoda International نسخه"
			echo -e "${gl_kjlan}3. ${color3}1پنل پنل مدیریت نسل جدید ${gl_kjlan}4. پنل بصری ${color4}NginxProxyManager"
			echo -e "${gl_kjlan}5. ${color5}OpenList برنامه فهرست فایل های چند ذخیره سازی ${gl_kjlan}6. ${color6}نسخه وب دسکتاپ راه دور اوبونتو"
			echo -e "${gl_kjlan}7. ${color7}Nezha Probe VPS مانیتورینگ پنل ${gl_kjlan}8. ${color8}QB آفلاین دانلود پنل مغناطیسی BT"
			echo -e "${gl_kjlan}9. ${color9}برنامه سرور ایمیل Poste.io ${gl_kjlan}10. ${color10}سیستم چت آنلاین چند نفره RocketChat"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}11. ${color11} نرم افزار مدیریت پروژه ZenTao ${gl_kjlan}12. ${color12} پلت فرم مدیریت وظیفه برنامه ریزی شده پنل Qinglong"
			echo -e "${gl_kjlan}13. ${color13}دیسک شبکه Cloudreve ${gl_huang}★${gl_bai} ${gl_kjlan}14. ${color14}برنامه مدیریت تصویر تختخواب ساده"
			echo -e "${gl_kjlan}15. ${color15}emby سیستم مدیریت چند رسانه ای ${gl_kjlan}16. ${color16}پنل اندازه گیری سرعت تست سرعت"
			echo -e "${gl_kjlan}17. ${color17}AdGuardHome ابزارهای تبلیغاتی مزاحم ${gl_kjlan}18 را حذف می کند. ${color18}onlyoffice دفتر آنلاین OFFICE"
			echo -e "${gl_kjlan}19. ${color19}پنل فایروال Leichi WAF ${gl_kjlan}20. ${color20}پانل مدیریت کانتینر پورتینر"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}21. ${color21}VScode نسخه وب ${gl_kjlan}22. ${color22}ابزار نظارت بر UptimeKuma"
			echo -e "${gl_kjlan}23. ${color23}یادداشت های وب ${gl_kjlan}24. ${color24}نسخه وب دسکتاپ راه دور وب تاپ ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}25. ${color25}دیسک شبکه Nextcloud ${gl_kjlan}26. ${color26}QD-چارچوب مدیریت کار برنامه ریزی شده امروز"
			echo -e "${gl_kjlan}27. ${color27}پنل مدیریت پشته کانتینر Dockge ${gl_kjlan}28. ${color28}ابزار تست سرعت LibreSpeed"
			echo -e "${gl_kjlan}29. ${color29}searxng ایستگاه جستجوی تجمع ${gl_huang}★${gl_bai} ${gl_kjlan}30. ${color30}سیستم آلبوم عکس خصوصی PhotoPrism"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}31. ${color31}مجموعه ابزار StirlingPDF ${gl_kjlan}32. ${color32}drawio نرم افزار ترسیم نمودار آنلاین رایگان ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}33. ${color33}پانل ناوبری Sun-Panel ${gl_kjlan}34. ${color34}پلتفرم اشتراک فایل Pingvin-Share"
			echo -e "${gl_kjlan}35. ${color35} حلقه دوستان مینیمالیستی ${gl_kjlan}36. ${color36}وب سایت تجمع چت LobeChatAI"
			echo -e "${gl_kjlan}37. ${color37}جعبه ابزار MyIP ${gl_huang}★${gl_bai} ${gl_kjlan}38. ${color38}سطل خانواده Xiaoya alist"
			echo -e "${gl_kjlan}39. ${color39}ابزار ضبط پخش زنده Bililive ${gl_kjlan}40. ${color40}webssh نسخه وب ابزار اتصال SSH"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}41. ${color41}پنل مدیریت ماوس ${gl_kjlan}42. ${color42}ابزار اتصال از راه دور بعدی"
			echo -e "${gl_kjlan}43. ${color43}RustDesk Remote Desktop (سرور) ${gl_huang}★${gl_bai} ${gl_kjlan}44. ${color44}RustDesk Remote Desktop (رله) ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}45. ${color45}ایستگاه شتاب داکر ${gl_kjlan}46. ${color46}ایستگاه شتاب دهی GitHub ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}47. ${color47} نظارت بر پرومتئوس ${gl_kjlan}48. ${color48} Prometheus (نظارت میزبان)"
			echo -e "${gl_kjlan}49. ${color49} پرومتئوس (نظارت کانتینر) ${gl_kjlan}50. ${color50} ابزار نظارت بر پر کردن"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}51. ${color51}PVE پانل مرغ باز ${gl_kjlan}52. ${color52}DP پانل مدیریت کانتینر"
			echo -e "${gl_kjlan}53. ${color53}llama3 چت هوش مصنوعی مدل بزرگ ${gl_kjlan}54. پنل مدیریت ساخت وب سایت میزبان ${color54}AMH"
			echo -e "${gl_kjlan}55. ${color55}نفوذ اینترانت FRP (سرور) ${gl_huang}★${gl_bai} ${gl_kjlan}56. ${color56}نفوذ اینترانت FRP (مشتری) ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}57. ${color57}Deepseek chat AI مدل بزرگ ${gl_kjlan}58. ${color58}تغییر پایگاه دانش مدل بزرگ ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}59. ${color59}NewAPI مدل بزرگ مدیریت دارایی ${gl_kjlan}60. ${color60}JumpServer دستگاه منبع باز استحکامات"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}61. ${color61} سرور ترجمه آنلاین ${gl_kjlan}62. ${color62}RAGFlow پایگاه دانش مدل بزرگ"
			echo -e "${gl_kjlan}63. ${color63}OpenWebUI خود میزبان پلت فرم هوش مصنوعی ${gl_huang}★${gl_bai} ${gl_kjlan}64. ${color64}it-tools جعبه ابزار"
			echo -e "${gl_kjlan}65. ${color65}n8n پلت فرم گردش کار خودکار ${gl_huang}★${gl_bai} ${gl_kjlan}66. ${color66}yt-dlp ابزار دانلود ویدیو"
			echo -e "${gl_kjlan}67. ${color67}ddns-go ابزار مدیریت پویا DNS ${gl_huang}★${gl_bai} ${gl_kjlan}68. ${color68}پلتفرم مدیریت گواهی AllinSSL"
			echo -e "${gl_kjlan}69. ${color69}SFTPGo ابزار انتقال فایل ${gl_kjlan}70. ${color70}چارچوب ربات چت AstrBot"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}71. ${color71}سرور موسیقی خصوصی Navidrome ${gl_kjlan}72. ${color72}bitwarden password manager ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}73. ${color73}فیلم و تلویزیون خصوصی LibreTV ${gl_kjlan}74. ${color74}MoonTV فیلم و تلویزیون خصوصی"
			echo -e "${gl_kjlan}75. ${color75}جادوگر موسیقی ملودی ${gl_kjlan}76. ${color76} بازی های قدیمی DOS آنلاین"
			echo -e "${gl_kjlan}77. ${color77}ابزار دانلود آفلاین Thunder ${gl_kjlan}78. ${color78}سیستم مدیریت اسناد هوشمند PandaWiki"
			echo -e "${gl_kjlan}79. ${color79} نظارت بر سرور Beszel ${gl_kjlan}80. ${color80}linkwarden مدیریت نشانک"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}81. ${color81} کنفرانس ویدئویی JitsiMeet ${gl_kjlan}82. ${color82}gpt پراکسی شفاف هوش مصنوعی با عملکرد بالا را بارگیری می کند"
			echo -e "${gl_kjlan}83. ${color83}ابزار نظارت بر سرور komari ${gl_kjlan}84. ${color84}ابزار مدیریت مالی شخصی Wallos"
			echo -e "${gl_kjlan}85. ${color85}immich تصویر و مدیر ویدیو ${gl_kjlan}86. سیستم مدیریت رسانه ${color86}jellyfin"
			echo -e "${gl_kjlan}87. ${color87}SyncTV، ابزاری برای تماشای فیلم با هم ${gl_kjlan}88. ${color88}سکوی پخش زنده با میزبانی شخصی"
			echo -e "${gl_kjlan}89. ${color89}فایل FileCodeBox اکسپرس ${gl_kjlan}90. ${color90}پروتکل چت غیرمتمرکز ماتریسی"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}91. ${color91} مخزن کد خصوصی gitea ${gl_kjlan}92. ${color92}FileBrowser مدیر فایل"
			echo -e "${gl_kjlan}93. ${color93}سرور فایل استاتیک مینیمالیستی Dufs ${gl_kjlan}94. ${color94}ابزار دانلود پرسرعت Gopeed"
			echo -e "${gl_kjlan}95. ${color95}سکوی مدیریت اسناد بدون کاغذ ${gl_kjlan}96. ${color96}2Auth احراز هویت دو مرحله ای خود میزبانی شده"
			echo -e "${gl_kjlan}97. ${color97}شبکه WireGuard (سرور) ${gl_kjlan}98. ${color98}شبکه WireGuard (مشتری)"
			echo -e "${gl_kjlan}99. ${color99}DSM Synology Virtual Machine ${gl_kjlan}100. ${color100}همگام سازی ابزار همگام سازی فایل های نظیر به نظیر"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}101. ${color101}ابزار تولید ویدئو AI ${gl_kjlan}102. ${color102}سیستم چت آنلاین چند نفره VoceChat"
			echo -e "${gl_kjlan}103. ${color103}ابزار آمار وب سایت Umami ${gl_kjlan}104. ${color104}ابزار انتقال پراکسی چهار لایه استریم"
			echo -e "${gl_kjlan}105. ${color105} یادداشت های سیوان ${gl_kjlan}106. ${color106}ابزار وایت برد منبع باز Drawnix"
			echo -e "${gl_kjlan}107. ${color107}جستجوی دیسک شبکه PanSou"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}b. ${gl_bai} از تمام داده های برنامه پشتیبان تهیه کنید ${gl_kjlan}r. ${gl_bai} همه داده های برنامه را بازیابی کنید"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
			echo -e "${gl_kjlan}------------------------${gl_bai}"
			read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		fi

		case $sub_choice in
		1 | bt | baota)
			local app_id="1"
			local lujing="[ -d "/www/server/panel" ]"
			local panelname="宝塔面板"
			local panelurl="https://www.bt.cn/new/index.html"

			panel_app_install() {
				if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi
				bash install_panel.sh ed8484bec
			}

			panel_app_manage() {
				bt
			}

			panel_app_uninstall() {
				curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh >/dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
				chmod +x bt-uninstall.sh
				./bt-uninstall.sh
			}

			install_panel

			;;
		2 | aapanel)

			local app_id="2"
			local lujing="[ -d "/www/server/panel" ]"
			local panelname="aapanel"
			local panelurl="https://www.aapanel.com/new/index.html"

			panel_app_install() {
				URL=https://www.aapanel.com/script/install_7.0_en.sh && if [ -f /usr/bin/curl ]; then curl -ksSO "$URL"; else wget --no-check-certificate -O install_7.0_en.sh "$URL"; fi
				bash install_7.0_en.sh aapanel
			}

			panel_app_manage() {
				bt
			}

			panel_app_uninstall() {
				curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh >/dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
				chmod +x bt-uninstall.sh
				./bt-uninstall.sh
			}

			install_panel

			;;
		3 | 1p | 1panel)

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
		4 | npm)

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

			local docker_describe="一个Nginx反向代理工具面板，不支持添加域名访问。"
			local docker_url="官网介绍: https://nginxproxymanager.com/"
			local docker_use="echo \"初始用户名: admin@example.com\""
			local docker_passwd="echo \"初始密码: changeme\""
			local app_size="1"

			docker_app

			;;

		5 | openlist)

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

			local docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
			local docker_url="官网介绍: https://github.com/OpenListTeam/OpenList"
			local docker_use="docker exec -it openlist ./openlist admin random"
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		6 | webtop-ubuntu)

			local app_id="6"
			local docker_name="webtop-ubuntu"
			local docker_img="lscr.io/linuxserver/webtop:ubuntu-kde"
			local docker_port=3006

			docker_rum() {

				read -e -p "تنظیم نام کاربری ورود به سیستم:" admin
				read -e -p "تنظیم رمز ورود کاربر:" admin_password
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

			local docker_describe="webtop基于Ubuntu的容器。若IP无法访问，请添加域名访问。"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app

			;;
		7 | nezha)
			clear
			send_stats "搭建哪吒"

			local app_id="7"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "Nezha نظارت بر $check_docker $update_status"
				echo "ابزار مانیتورینگ و بهره برداری و نگهداری سرور منبع باز، سبک وزن و با استفاده آسان"
				echo "مستندات ساخت وب سایت رسمی: https://nezha.wiki/guide/dashboard.html"
				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1. استفاده کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید:" choice

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

		8 | qb | QB)

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

			local docker_describe="qbittorrent离线BT磁力下载服务"
			local docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
			local docker_use="sleep 3"
			local docker_passwd="docker logs qbittorrent"
			local app_size="1"
			docker_app

			;;

		9 | mail)
			send_stats "搭建邮局"
			clear
			install telnet
			local app_id="9"
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "خدمات پستی $check_docker $update_status"
				echo "poste.io یک راه حل منبع باز ایمیل سرور است،"
				echo "معرفی ویدیو: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo ""
				echo "تشخیص پورت"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
					echo -e "پورت ${gl_lv} $port در حال حاضر موجود است ${gl_bai}"
				else
					echo -e "پورت ${gl_hong} $port در حال حاضر در دسترس نیست ${gl_bai}"
				fi
				echo ""

				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					yuming=$(cat /home/docker/mail.txt)
					echo "آدرس بازدید:"
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. نصب 2. به روز رسانی 3. حذف"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید:" choice

				case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "لطفاً نام دامنه ایمیل، به عنوان مثال mail.yuming.com را تنظیم کنید:" yuming
					mkdir -p /home/docker
					echo "$yuming" >/home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "ابتدا این رکوردهای DNS را تجزیه کنید"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo ""
					echo "------------------------"
					echo "برای ادامه هر کلیدی را فشار دهید..."
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
					echo "poste.io نصب شده است"
					echo "------------------------"
					echo "با استفاده از آدرس زیر می توانید به poste.io دسترسی پیدا کنید:"
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
					echo "poste.io نصب شده است"
					echo "------------------------"
					echo "با استفاده از آدرس زیر می توانید به poste.io دسترسی پیدا کنید:"
					echo "https://$yuming"
					echo ""
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "برنامه حذف نصب شده است"
					;;

				*)
					break
					;;

				esac
				break_end
			done

			;;

		10 | rocketchat)

			local app_id="10"
			local app_name="Rocket.Chat聊天系统"
			local app_text="Rocket.Chat 是一个开源的团队通讯平台，支持实时聊天、音视频通话、文件共享等多种功能，"
			local app_url="官方介绍: https://www.rocket.chat/"
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
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "rocket.chat نصب شده است"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus
			;;

		11 | zentao)
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

			local docker_describe="禅道是通用的项目管理软件"
			local docker_url="官网介绍: https://www.zentao.net/"
			local docker_use="echo \"初始用户名: admin\""
			local docker_passwd="echo \"初始密码: 123456\""
			local app_size="2"
			docker_app

			;;

		12 | qinglong)
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

			local docker_describe="青龙面板是一个定时任务管理平台"
			local docker_url="官网介绍: ${gh_proxy}github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;
		13 | cloudreve)

			local app_id="13"
			local app_name="cloudreve网盘"
			local app_text="cloudreve是一个支持多家云存储的网盘系统"
			local app_url="视频介绍: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus
			;;

		14 | easyimage)
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

			local docker_describe="简单图床是一个简单的图床程序"
			local docker_url="官网介绍: ${gh_proxy}github.com/icret/EasyImages2.0"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		15 | emby)
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

			local docker_describe="emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
			local docker_url="官网介绍: https://emby.media/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		16 | looking)
			local app_id="16"
			local docker_name="looking-glass"
			local docker_img="wikihostinc/looking-glass-server"
			local docker_port=8016

			docker_rum() {

				docker run -d --name looking-glass --restart=always -p ${docker_port}:80 wikihostinc/looking-glass-server

			}

			local docker_describe="Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
			local docker_url="官网介绍: ${gh_proxy}github.com/wikihost-opensource/als"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;
		17 | adguardhome)

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

			local docker_describe="AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
			local docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		18 | onlyoffice)

			local app_id="18"
			local docker_name="onlyoffice"
			local docker_img="onlyoffice/documentserver"
			local docker_port=8018

			docker_rum() {

				docker run -d -p ${docker_port}:80 \
					--restart=always \
					--name onlyoffice \
					-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice \
					-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data \
					onlyoffice/documentserver

			}

			local docker_describe="onlyoffice是一款开源的在线office工具，太强大了！"
			local docker_url="官网介绍: https://www.onlyoffice.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app

			;;

		19 | safeline)
			send_stats "搭建雷池"

			local app_id="19"
			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "سرویس تاندرپول $check_docker"
				echo "Leichi یک پنل برنامه فایروال سایت WAF است که توسط Changting Technology توسعه یافته است که می تواند سایت را برای دفاع خودکار معکوس کند."
				echo "معرفی ویدیو: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. نصب 2. به روز رسانی 3. بازنشانی رمز عبور 4. حذف"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید:" choice

				case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "پنل لیچی WAF نصب شده است"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "پنل لیچی WAF به روز شده است"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "اگر در دایرکتوری نصب پیش فرض هستید، پروژه اکنون حذف نصب شده است. اگر دایرکتوری نصب را سفارشی کنید، باید به دایرکتوری نصب بروید و خودتان آن را اجرا کنید:"
					echo "docker compose down && docker compose down --rmi all"
					;;
				*)
					break
					;;

				esac
				break_end
			done

			;;

		20 | portainer)
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

			local docker_describe="portainer是一个轻量级的docker容器管理面板"
			local docker_url="官网介绍: https://www.portainer.io/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		21 | vscode)
			local app_id="21"
			local docker_name="vscode-web"
			local docker_img="codercom/code-server"
			local docker_port=8021

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart=always codercom/code-server

			}

			local docker_describe="VScode是一款强大的在线代码编写工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/coder/code-server"
			local docker_use="sleep 3"
			local docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
			local app_size="1"
			docker_app
			;;

		22 | uptime-kuma)
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

			local docker_describe="Uptime Kuma 易于使用的自托管监控工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/louislam/uptime-kuma"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		23 | memos)
			local app_id="23"
			local docker_name="memos"
			local docker_img="ghcr.io/usememos/memos:latest"
			local docker_port=8023

			docker_rum() {

				docker run -d --name memos -p ${docker_port}:5230 -v /home/docker/memos:/var/opt/memos --restart=always ghcr.io/usememos/memos:latest

			}

			local docker_describe="Memos是一款轻量级、自托管的备忘录中心"
			local docker_url="官网介绍: ${gh_proxy}github.com/usememos/memos"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		24 | webtop)
			local app_id="24"
			local docker_name="webtop"
			local docker_img="lscr.io/linuxserver/webtop:latest"
			local docker_port=8024

			docker_rum() {

				read -e -p "تنظیم نام کاربری ورود به سیستم:" admin
				read -e -p "تنظیم رمز ورود کاربر:" admin_password
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

			local docker_describe="webtop基于Alpine的中文版容器。若IP无法访问，请添加域名访问。"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			;;

		25 | nextcloud)
			local app_id="25"
			local docker_name="nextcloud"
			local docker_img="nextcloud:latest"
			local docker_port=8025
			local rootpasswd=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

			docker_rum() {

				docker run -d --name nextcloud --restart=always -p ${docker_port}:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud

			}

			local docker_describe="Nextcloud拥有超过 400,000 个部署，是您可以下载的最受欢迎的本地内容协作平台"
			local docker_url="官网介绍: https://nextcloud.com/"
			local docker_use="echo \"账号: nextcloud  密码: $rootpasswd\""
			local docker_passwd=""
			local app_size="3"
			docker_app
			;;

		26 | qd)
			local app_id="26"
			local docker_name="qd"
			local docker_img="qdtoday/qd:latest"
			local docker_port=8026

			docker_rum() {

				docker run -d --name qd -p ${docker_port}:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd

			}

			local docker_describe="QD-Today是一个HTTP请求定时任务自动执行框架"
			local docker_url="官网介绍: https://qd-today.github.io/qd/zh_CN/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		27 | dockge)
			local app_id="27"
			local docker_name="dockge"
			local docker_img="louislam/dockge:latest"
			local docker_port=8027

			docker_rum() {

				docker run -d --name dockge --restart=always -p ${docker_port}:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge

			}

			local docker_describe="dockge是一个可视化的docker-compose容器管理面板"
			local docker_url="官网介绍: ${gh_proxy}github.com/louislam/dockge"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		28 | speedtest)
			local app_id="28"
			local docker_name="speedtest"
			local docker_img="ghcr.io/librespeed/speedtest"
			local docker_port=8028

			docker_rum() {

				docker run -d -p ${docker_port}:8080 --name speedtest --restart=always ghcr.io/librespeed/speedtest

			}

			local docker_describe="librespeed是用Javascript实现的轻量级速度测试工具，即开即用"
			local docker_url="官网介绍: ${gh_proxy}github.com/librespeed/speedtest"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		29 | searxng)
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

			local docker_describe="searxng是一个私有且隐私的搜索引擎站点"
			local docker_url="官网介绍: https://hub.docker.com/r/alandoyle/searxng"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		30 | photoprism)
			local app_id="30"
			local docker_name="photoprism"
			local docker_img="photoprism/photoprism:latest"
			local docker_port=8030
			local rootpasswd=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

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

			local docker_describe="photoprism非常强大的私有相册系统"
			local docker_url="官网介绍: https://www.photoprism.app/"
			local docker_use="echo \"账号: admin  密码: $rootpasswd\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		31 | s-pdf)
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

			local docker_describe="这是一个强大的本地托管基于 Web 的 PDF 操作工具，使用 docker，允许您对 PDF 文件执行各种操作，例如拆分合并、转换、重新组织、添加图像、旋转、压缩等。"
			local docker_url="官网介绍: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		32 | drawio)
			local app_id="32"
			local docker_name="drawio"
			local docker_img="jgraph/drawio"
			local docker_port=8032

			docker_rum() {

				docker run -d --restart=always --name drawio -p ${docker_port}:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio

			}

			local docker_describe="这是一个强大图表绘制软件。思维导图，拓扑图，流程图，都能画"
			local docker_url="官网介绍: https://www.drawio.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		33 | sun-panel)
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

			local docker_describe="Sun-Panel服务器、NAS导航面板、Homepage、浏览器首页"
			local docker_url="官网介绍: https://doc.sun-panel.top/zh_cn/"
			local docker_use="echo \"账号: admin@sun.cc  密码: 12345678\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		34 | pingvin-share)
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

			local docker_describe="Pingvin Share 是一个可自建的文件分享平台，是 WeTransfer 的一个替代品"
			local docker_url="官网介绍: ${gh_proxy}github.com/stonith404/pingvin-share"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		35 | moments)
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

			local docker_describe="极简朋友圈，高仿微信朋友圈，记录你的美好生活"
			local docker_url="官网介绍: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use="echo \"账号: admin  密码: a123456\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		36 | lobe-chat)
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

			local docker_describe="LobeChat聚合市面上主流的AI大模型，ChatGPT/Claude/Gemini/Groq/Ollama"
			local docker_url="官网介绍: ${gh_proxy}github.com/lobehub/lobe-chat"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			;;

		37 | myip)
			local app_id="37"
			local docker_name="myip"
			local docker_img="jason5ng32/myip:latest"
			local docker_port=8037

			docker_rum() {

				docker run -d -p ${docker_port}:18966 --name myip jason5ng32/myip:latest

			}

			local docker_describe="是一个多功能IP工具箱，可以查看自己IP信息及连通性，用网页面板呈现"
			local docker_url="官网介绍: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		38 | xiaoya)
			send_stats "小雅全家桶"
			clear
			install_docker
			check_disk_space 1
			bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
			;;

		39 | bililive)

			if [ ! -d /home/docker/bililive-go/ ]; then
				mkdir -p /home/docker/bililive-go/ >/dev/null 2>&1
				wget -O /home/docker/bililive-go/config.yml ${gh_proxy}raw.githubusercontent.com/hr3lxphr6j/bililive-go/master/config.yml >/dev/null 2>&1
			fi

			local app_id="39"
			local docker_name="bililive-go"
			local docker_img="chigusa/bililive-go"
			local docker_port=8039

			docker_rum() {

				docker run --restart=always --name bililive-go -v /home/docker/bililive-go/config.yml:/etc/bililive-go/config.yml -v /home/docker/bililive-go/Videos:/srv/bililive -p ${docker_port}:8080 -d chigusa/bililive-go

			}

			local docker_describe="Bililive-go是一个支持多种直播平台的直播录制工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		40 | webssh)
			local app_id="40"
			local docker_name="webssh"
			local docker_img="jrohy/webssh"
			local docker_port=8040
			docker_rum() {
				docker run -d -p ${docker_port}:5032 --restart=always --name webssh -e TZ=Asia/Shanghai jrohy/webssh
			}

			local docker_describe="简易在线ssh连接工具和sftp工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/Jrohy/webssh"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		41 | haozi)

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

		42 | nexterm)
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

			local docker_describe="nexterm是一款强大的在线SSH/VNC/RDP连接工具。"
			local docker_url="官网介绍: ${gh_proxy}github.com/gnmyt/Nexterm"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		43 | hbbs)
			local app_id="43"
			local docker_name="hbbs"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=0000

			docker_rum() {

				docker run --name hbbs -v /home/docker/hbbs/data:/root -td --net=host --restart=always rustdesk/rustdesk-server hbbs

			}

			local docker_describe="rustdesk开源的远程桌面(服务端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="docker logs hbbs"
			local docker_passwd="echo \"把你的IP和key记录下，会在远程桌面客户端中用到。去44选项装中继端吧！\""
			local app_size="1"
			docker_app
			;;

		44 | hbbr)
			local app_id="44"
			local docker_name="hbbr"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=0000

			docker_rum() {

				docker run --name hbbr -v /home/docker/hbbr/data:/root -td --net=host --restart=always rustdesk/rustdesk-server hbbr

			}

			local docker_describe="rustdesk开源的远程桌面(中继端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="echo \"前往官网下载远程桌面的客户端: https://rustdesk.com/zh-cn/\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		45 | registry)
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

			local docker_describe="Docker Registry 是一个用于存储和分发 Docker 镜像的服务。"
			local docker_url="官网介绍: https://hub.docker.com/_/registry"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			;;

		46 | ghproxy)
			local app_id="46"
			local docker_name="ghproxy"
			local docker_img="wjqserver/ghproxy:latest"
			local docker_port=8046

			docker_rum() {

				docker run -d --name ghproxy --restart=always -p ${docker_port}:8080 -v /home/docker/ghproxy/config:/data/ghproxy/config wjqserver/ghproxy:latest

			}

			local docker_describe="使用Go实现的GHProxy，用于加速部分地区Github仓库的拉取。"
			local docker_url="官网介绍: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		47 | prometheus | grafana)

			local app_id="47"
			local app_name="普罗米修斯监控"
			local app_text="Prometheus+Grafana企业级监控系统"
			local app_url="官网介绍: https://prometheus.io"
			local docker_name="grafana"
			local docker_port="8047"
			local app_size="2"

			docker_app_install() {
				prometheus_install
				clear
				ip_address
				echo "نصب به پایان رسید"
				check_docker_app_ip
				echo "نام کاربری و رمز عبور اولیه عبارتند از: admin"
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
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus
			;;

		48 | node-exporter)
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

			local docker_describe="这是一个普罗米修斯的主机数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/prometheus/node_exporter"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		49 | cadvisor)
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

			local docker_describe="这是一个普罗米修斯的容器数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/google/cadvisor"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		50 | changedetection)
			local app_id="50"
			local docker_name="changedetection"
			local docker_img="dgtlmoon/changedetection.io:latest"
			local docker_port=8050

			docker_rum() {

				docker run -d --restart=always -p ${docker_port}:5000 \
					-v /home/docker/datastore:/datastore \
					--name changedetection dgtlmoon/changedetection.io:latest

			}

			local docker_describe="这是一款网站变化检测、补货监控和通知的小工具"
			local docker_url="官网介绍: https://github.com/dgtlmoon/changedetection.io"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		51 | pve)
			clear
			send_stats "PVE开小鸡"
			check_disk_space 1
			curl -L ${gh_proxy}raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
			;;

		52 | dpanel)
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

			local docker_describe="Docker可视化面板系统，提供完善的docker管理功能。"
			local docker_url="官网介绍: https://github.com/donknap/dpanel"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		53 | llama3)
			local app_id="53"
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart=always ghcr.io/open-webui/open-webui:ollama

			}

			local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的llama3大语言模型"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run llama3.2:1b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		54 | amh)

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

		55 | frps)
			frps_panel
			;;

		56 | frpc)
			frpc_panel
			;;

		57 | deepseek)
			local app_id="57"
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart=always ghcr.io/open-webui/open-webui:ollama

			}

			local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的DeepSeek R1大语言模型"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		58 | dify)
			local app_id="58"
			local app_name="Dify知识库"
			local app_text="是一款开源的大语言模型(LLM) 应用开发平台。自托管训练数据用于AI生成"
			local app_url="官方网站: https://docs.dify.ai/zh-hans"
			local docker_name="docker-nginx-1"
			local docker_port="8058"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/langgenius/dify.git && cd dify/docker && cp .env.example .env
				# sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				sed -i "s/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/" /home/docker/dify/docker/.env

				docker compose up -d
				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/dify/docker/ && docker compose down --rmi all
				cd /home/docker/dify/
				git pull origin main
				sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=8058/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				cd /home/docker/dify/docker/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/dify/docker/ && docker compose down --rmi all
				rm -rf /home/docker/dify
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		59 | new-api)
			local app_id="59"
			local app_name="NewAPI"
			local app_text="新一代大模型网关与AI资产管理系统"
			local app_url="官方网站: https://github.com/Calcium-Ion/new-api"
			local docker_name="new-api"
			local docker_port="8059"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/Calcium-Ion/new-api.git && cd new-api

				sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
					-e 's/container_name: redis/container_name: redis-new-api/g' \
					-e 's/container_name: mysql/container_name: mysql-new-api/g' \
					docker-compose.yml

				docker compose up -d
				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				cd /home/docker/new-api/
				git pull origin main
				sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
					-e 's/container_name: redis/container_name: redis-new-api/g' \
					-e 's/container_name: mysql/container_name: mysql-new-api/g' \
					docker-compose.yml

				docker compose up -d
				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		60 | jms)

			local app_id="60"
			local app_name="JumpServer开源堡垒机"
			local app_text="是一个开源的特权访问管理 (PAM) 工具，该程序占用80端口不支持添加域名访问了"
			local app_url="官方介绍: https://github.com/jumpserver/jumpserver"
			local docker_name="jms_web"
			local docker_port="80"
			local app_size="2"

			docker_app_install() {
				curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip
				echo "نام کاربری اولیه: admin"
				echo "رمز عبور اولیه: ChangeMe"
			}

			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "برنامه به روز شده است"
			}

			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus
			;;

		61 | libretranslate)
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

			local docker_describe="免费开源机器翻译 API，完全自托管，它的翻译引擎由开源Argos Translate库提供支持。"
			local docker_url="官网介绍: https://github.com/LibreTranslate/LibreTranslate"
			local docker_use=""
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		62 | ragflow)
			local app_id="62"
			local app_name="RAGFlow知识库"
			local app_text="基于深度文档理解的开源 RAG（检索增强生成）引擎"
			local app_url="官方网站: https://github.com/infiniflow/ragflow"
			local docker_name="ragflow-server"
			local docker_port="8062"
			local app_size="8"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/infiniflow/ragflow.git && cd ragflow/docker
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/ragflow/docker/ && docker compose down --rmi all
				cd /home/docker/ragflow/
				git pull origin main
				cd /home/docker/ragflow/docker/
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/ragflow/docker/ && docker compose down --rmi all
				rm -rf /home/docker/ragflow
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		63 | open-webui)
			local app_id="63"
			local docker_name="open-webui"
			local docker_img="ghcr.io/open-webui/open-webui:main"
			local docker_port=8063

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/open-webui:/app/backend/data --name open-webui --restart=always ghcr.io/open-webui/open-webui:main

			}

			local docker_describe="OpenWebUI一款大语言模型网页框架，官方精简版本，支持各大模型API接入"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use=""
			local docker_passwd=""
			local app_size="3"
			docker_app
			;;

		64 | it-tools)
			local app_id="64"
			local docker_name="it-tools"
			local docker_img="corentinth/it-tools:latest"
			local docker_port=8064

			docker_rum() {
				docker run -d --name it-tools --restart=always -p ${docker_port}:80 corentinth/it-tools:latest
			}

			local docker_describe="对开发人员和 IT 工作者来说非常有用的工具"
			local docker_url="官网介绍: https://github.com/CorentinTh/it-tools"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		65 | n8n)
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

			local docker_describe="是一款功能强大的自动化工作流平台"
			local docker_url="官网介绍: https://github.com/n8n-io/n8n"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		66 | yt)
			yt_menu_pro
			;;

		67 | ddns)
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

			local docker_describe="自动将你的公网 IP（IPv4/IPv6）实时更新到各大 DNS 服务商，实现动态域名解析。"
			local docker_url="官网介绍: https://github.com/jeessy2/ddns-go"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		68 | allinssl)
			local app_id="68"
			local docker_name="allinssl"
			local docker_img="allinssl/allinssl:latest"
			local docker_port=8068

			docker_rum() {
				docker run -itd --name allinssl -p ${docker_port}:8888 -v /home/docker/allinssl/data:/www/allinssl/data -e ALLINSSL_USER=allinssl -e ALLINSSL_PWD=allinssldocker -e ALLINSSL_URL=allinssl allinssl/allinssl:latest
			}

			local docker_describe="开源免费的 SSL 证书自动化管理平台"
			local docker_url="官网介绍: https://allinssl.com"
			local docker_use="echo \"安全入口: /allinssl\""
			local docker_passwd="echo \"用户名: allinssl  密码: allinssldocker\""
			local app_size="1"
			docker_app
			;;

		69 | sftpgo)
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

			local docker_describe="开源免费随时随地SFTP FTP WebDAV 文件传输工具"
			local docker_url="官网介绍: https://sftpgo.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		70 | astrbot)
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

			local docker_describe="开源AI聊天机器人框架，支持微信，QQ，TG接入AI大模型"
			local docker_url="官网介绍: https://astrbot.app/"
			local docker_use="echo \"用户名: astrbot  密码: astrbot\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		71 | navidrome)
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

			local docker_describe="是一个轻量、高性能的音乐流媒体服务器"
			local docker_url="官网介绍: https://www.navidrome.org/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		72 | bitwarden)

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

			local docker_describe="一个你可以控制数据的密码管理器"
			local docker_url="官网介绍: https://bitwarden.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		73 | libretv)

			local app_id="73"
			local docker_name="libretv"
			local docker_img="bestzwei/libretv:latest"
			local docker_port=8073

			docker_rum() {

				read -e -p "رمز ورود LibreTV را تنظیم کنید:" app_passwd

				docker run -d \
					--name libretv \
					--restart=always \
					-p ${docker_port}:8080 \
					-e PASSWORD=${app_passwd} \
					bestzwei/libretv:latest

			}

			local docker_describe="免费在线视频搜索与观看平台"
			local docker_url="官网介绍: https://github.com/LibreSpark/LibreTV"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		74 | moontv)

			local app_id="74"

			local app_name="moontv私有影视"
			local app_text="免费在线视频搜索与观看平台"
			local app_url="视频介绍: https://github.com/MoonTechLab/LunaTV"
			local docker_name="moontv-core"
			local docker_port="8074"
			local app_size="2"

			docker_app_install() {
				read -e -p "تنظیم نام کاربری ورود به سیستم:" admin
				read -e -p "تنظیم رمز ورود کاربر:" admin_password
				read -e -p "کد مجوز را وارد کنید:" shouquanma

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
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/moontv/ && docker compose down --rmi all
				cd /home/docker/moontv/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/moontv/ && docker compose down --rmi all
				rm -rf /home/docker/moontv
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		75 | melody)

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

			local docker_describe="你的音乐精灵，旨在帮助你更好地管理音乐。"
			local docker_url="官网介绍: https://github.com/foamzou/melody"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		76 | dosgame)

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

			local docker_describe="是一个中文DOS游戏合集网站"
			local docker_url="官网介绍: https://github.com/rwv/chinese-dos-games"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app

			;;

		77 | xunlei)

			local app_id="77"
			local docker_name="xunlei"
			local docker_img="cnk3x/xunlei"
			local docker_port=8077

			docker_rum() {

				read -e -p "تنظیم نام کاربری ورود به سیستم:" app_use
				read -e -p "تنظیم رمز ورود به سیستم:" app_passwd

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

			local docker_describe="迅雷你的离线高速BT磁力下载工具"
			local docker_url="官网介绍: https://github.com/cnk3x/xunlei"
			local docker_use="echo \"手机登录迅雷，再输入邀请码，邀请码: 迅雷牛通\""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		78 | PandaWiki)

			local app_id="78"
			local app_name="PandaWiki"
			local app_text="PandaWiki是一款AI大模型驱动的开源智能文档管理系统，强烈建议不要自定义端口部署。"
			local app_url="官方介绍: https://github.com/chaitin/PandaWiki"
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

		79 | beszel)

			local app_id="79"
			local docker_name="beszel"
			local docker_img="henrygd/beszel"
			local docker_port=8079

			docker_rum() {

				mkdir -p /home/docker/beszel &&
					docker run -d \
						--name beszel \
						--restart=always \
						-v /home/docker/beszel:/beszel_data \
						-p ${docker_port}:8090 \
						henrygd/beszel

			}

			local docker_describe="Beszel轻量易用的服务器监控"
			local docker_url="官网介绍: https://beszel.dev/zh/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		80 | linkwarden)

			local app_id="80"
			local app_name="linkwarden书签管理"
			local app_text="一个开源的自托管书签管理平台，支持标签、搜索和团队协作。"
			local app_url="官方网站: https://linkwarden.app/"
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
				echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >>.env
				echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >>.env

				sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

				# 启动容器
				docker compose up -d

				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip

			}

			docker_app_update() {
				cd /home/docker/linkwarden && docker compose down --rmi all
				curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
				curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env.new"

				# 保留原本的变量
				source .env
				mv .env.new .env
				echo "NEXTAUTH_URL=$NEXTAUTH_URL" >>.env
				echo "NEXTAUTH_SECRET=$NEXTAUTH_SECRET" >>.env
				echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >>.env
				echo "MEILI_MASTER_KEY=$MEILI_MASTER_KEY" >>.env
				echo "ADMIN_EMAIL=$ADMIN_EMAIL" >>.env
				echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >>.env
				sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

				docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/linkwarden && docker compose down --rmi all
				rm -rf /home/docker/linkwarden
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		81 | jitsi)
			local app_id="81"
			local app_name="JitsiMeet视频会议"
			local app_text="一个开源的安全视频会议解决方案，支持多人在线会议、屏幕共享与加密通信。"
			local app_url="官方网站: https://jitsi.org/"
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
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		82 | gpt-load)

			local app_id="82"
			local docker_name="gpt-load"
			local docker_img="tbphp/gpt-load:latest"
			local docker_port=8082

			docker_rum() {

				read -e -p "کلید ورود به سیستم ${docker_name} (ترکیبی از حروف و اعدادی که با sk- شروع می شوند) را تنظیم کنید، مانند: sk-159kejilionyyds163:" app_passwd

				mkdir -p /home/docker/gpt-load &&
					docker run -d --name gpt-load \
						-p ${docker_port}:3001 \
						-e AUTH_KEY=${app_passwd} \
						-v "/home/docker/gpt-load/data":/app/data \
						tbphp/gpt-load:latest

			}

			local docker_describe="高性能AI接口透明代理服务"
			local docker_url="官网介绍: https://www.gpt-load.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		83 | komari)

			local app_id="83"
			local docker_name="komari"
			local docker_img="ghcr.io/komari-monitor/komari:latest"
			local docker_port=8083

			docker_rum() {

				mkdir -p /home/docker/komari &&
					docker run -d \
						--name komari \
						-p ${docker_port}:25774 \
						-v /home/docker/komari:/app/data \
						-e ADMIN_USERNAME=admin \
						-e ADMIN_PASSWORD=1212156 \
						--restart=always \
						ghcr.io/komari-monitor/komari:latest

			}

			local docker_describe="轻量级的自托管服务器监控工具"
			local docker_url="官网介绍: https://github.com/komari-monitor/komari/tree/main"
			local docker_use="echo \"默认账号: admin  默认密码: 1212156\""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		84 | wallos)

			local app_id="84"
			local docker_name="wallos"
			local docker_img="bellamy/wallos:latest"
			local docker_port=8084

			docker_rum() {

				mkdir -p /home/docker/wallos &&
					docker run -d --name wallos \
						-v /home/docker/wallos/db:/var/www/html/db \
						-v /home/docker/wallos/logos:/var/www/html/images/uploads/logos \
						-e TZ=UTC \
						-p ${docker_port}:80 \
						--restart=always \
						bellamy/wallos:latest

			}

			local docker_describe="开源个人订阅追踪器，可用于财务管理"
			local docker_url="官网介绍: https://github.com/ellite/Wallos"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		85 | immich)

			local app_id="85"
			local app_name="immich图片视频管理器"
			local app_text="高性能自托管照片和视频管理解决方案。"
			local app_url="官网介绍: https://github.com/immich-app/immich"
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
				echo "نصب به پایان رسید"
				check_docker_app_ip

			}

			docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				rm -rf /home/docker/${docker_name}
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		86 | jellyfin)

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

			local docker_describe="是一款开源媒体服务器软件"
			local docker_url="官网介绍: https://jellyfin.org/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		87 | synctv)

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

			local docker_describe="远程一起观看电影和直播的程序。它提供了同步观影、直播、聊天等功能"
			local docker_url="官网介绍: https://github.com/synctv-org/synctv"
			local docker_use="echo \"初始账号和密码: root  登陆后请及时修改登录密码\""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		88 | owncast)

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

			local docker_describe="开源、免费的自建直播平台"
			local docker_url="官网介绍: https://owncast.online"
			local docker_use="echo \"访问地址后面带 /admin 访问管理员页面\""
			local docker_passwd="echo \"初始账号: admin  初始密码: abc123  登陆后请及时修改登录密码\""
			local app_size="1"
			docker_app

			;;

		89 | file-code-box)

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

			local docker_describe="匿名口令分享文本和文件，像拿快递一样取文件"
			local docker_url="官网介绍: https://github.com/vastsa/FileCodeBox"
			local docker_use="echo \"访问地址后面带 /#/admin 访问管理员页面\""
			local docker_passwd="echo \"管理员密码: FileCodeBox2023\""
			local app_size="1"
			docker_app

			;;

		90 | matrix)

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

				echo "یک کاربر یا مدیر اولیه ایجاد کنید. لطفاً نام کاربری و رمز عبور زیر و اینکه آیا مدیر هستید یا خیر را تنظیم کنید."
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

			local docker_describe="Matrix是一个去中心化的聊天协议"
			local docker_url="官网介绍: https://matrix.org/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		91 | gitea)

			local app_id="91"

			local app_name="gitea私有代码仓库"
			local app_text="免费新一代的代码托管平台，提供接近 GitHub 的使用体验。"
			local app_url="视频介绍: https://github.com/go-gitea/gitea"
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
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/gitea/ && docker compose down --rmi all
				cd /home/docker/gitea/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/gitea/ && docker compose down --rmi all
				rm -rf /home/docker/gitea
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		92 | filebrowser)

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

			local docker_describe="是一个基于Web的文件管理器"
			local docker_url="官网介绍: https://filebrowser.org/"
			local docker_use="docker logs filebrowser"
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		93 | dufs)

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

			local docker_describe="极简静态文件服务器，支持上传下载"
			local docker_url="官网介绍: https://github.com/sigoden/dufs"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		94 | gopeed)

			local app_id="94"
			local docker_name="gopeed"
			local docker_img="liwei2633/gopeed"
			local docker_port=8094

			docker_rum() {

				read -e -p "تنظیم نام کاربری ورود به سیستم:" app_use
				read -e -p "تنظیم رمز ورود به سیستم:" app_passwd

				docker run -d \
					--name ${docker_name} \
					--restart=always \
					-v /home/docker/${docker_name}/downloads:/app/Downloads \
					-v /home/docker/${docker_name}/storage:/app/storage \
					-p ${docker_port}:9999 \
					${docker_img} -u ${app_use} -p ${app_passwd}

			}

			local docker_describe="分布式高速下载工具，支持多种协议"
			local docker_url="官网介绍: https://github.com/GopeedLab/gopeed"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		95 | paperless)

			local app_id="95"

			local app_name="paperless文档管理平台"
			local app_text="开源的电子文档管理系统，它的主要用途是把你的纸质文件数字化并管理起来。"
			local app_url="视频介绍: https://docs.paperless-ngx.com/"
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
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/paperless/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/paperless/ && docker compose down --rmi all
				rm -rf /home/docker/paperless
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		96 | 2fauth)

			local app_id="96"

			local app_name="2FAuth自托管二步验证器"
			local app_text="自托管的双重身份验证 (2FA) 账户管理和验证码生成工具。"
			local app_url="官网: https://github.com/Bubka/2FAuth"
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
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/2fauth/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/2fauth/ && docker compose down --rmi all
				rm -rf /home/docker/2fauth
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		97 | wgs)

			local app_id="97"
			local docker_name="wireguard"
			local docker_img="lscr.io/linuxserver/wireguard:latest"
			local docker_port=8097

			docker_rum() {

				read -e -p "لطفاً تعداد کلاینت‌های موجود در شبکه را وارد کنید (پیش‌فرض 5):" COUNT
				COUNT=${COUNT:-5}
				read -e -p "لطفاً بخش شبکه WireGuard را وارد کنید (پیش‌فرض 10.13.13.0):" NETWORK
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
				echo -e "${gl_huang}همه پیکربندی کد QR مشتری: ${gl_bai}"
				docker exec -it wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
				sleep 2
				echo
				echo -e "${gl_huang} همه کدهای پیکربندی کلاینت: ${gl_bai}"
				docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
				sleep 2
				echo -e "کلاینت های ${gl_lv}${COUNT} همه خروجی ها را پیکربندی می کنند. روش استفاده به شرح زیر است: ${gl_bai}"
				echo -e "${gl_lv}1. برنامه wg را در تلفن همراه خود دانلود کنید و کد QR بالا را اسکن کنید تا سریع به اینترنت متصل شوید ${gl_bai}"
				echo -e "${gl_lv}2. کلاینت را برای ویندوز دانلود کنید و کد پیکربندی را برای اتصال به شبکه کپی کنید. ${gl_bai}"
				echo -e "${gl_lv}3. لینوکس از یک اسکریپت برای استقرار سرویس گیرنده WG و کپی کردن کد پیکربندی برای اتصال به شبکه استفاده می کند. ${gl_bai}"
				echo -e "${gl_lv}روش دانلود رسمی مشتری: https://www.wireguard.com/install/${gl_bai}"
				break_end

			}

			local docker_describe="现代化、高性能的虚拟专用网络工具"
			local docker_url="官网介绍: https://www.wireguard.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		98 | wgc)

			local app_id="98"
			local docker_name="wireguardc"
			local docker_img="kjlion/wireguard:alpine"
			local docker_port=51820

			docker_rum() {

				mkdir -p /home/docker/wireguard/config/

				local CONFIG_FILE="/home/docker/wireguard/config/wg0.conf"

				# 创建目录（如果不存在）
				mkdir -p "$(dirname "$CONFIG_FILE")"

				echo "لطفاً پیکربندی مشتری خود را جایگذاری کنید و برای ذخیره دوبار Enter را فشار دهید:"

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
				echo "$input" >"$CONFIG_FILE"

				echo "پیکربندی مشتری در $CONFIG_FILE ذخیره شد"

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

			local docker_describe="现代化、高性能的虚拟专用网络工具"
			local docker_url="官网介绍: https://www.wireguard.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		99 | dsm)

			local app_id="99"

			local app_name="dsm群晖虚拟机"
			local app_text="Docker容器中的虚拟DSM"
			local app_url="官网: https://github.com/vdsm/virtual-dsm"
			local docker_name="dsm"
			local docker_port="8099"
			local app_size="16"

			docker_app_install() {

				read -e -p "تعداد هسته های CPU را تنظیم کنید (پیش فرض 2):" CPU_CORES
				local CPU_CORES=${CPU_CORES:-2}

				read -e -p "تنظیم اندازه حافظه (پیش‌فرض 4G):" RAM_SIZE
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
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/dsm/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/dsm/ && docker compose down --rmi all
				rm -rf /home/docker/dsm
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		100 | syncthing)

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

			local docker_describe="开源的点对点文件同步工具，类似于 Dropbox、Resilio Sync，但完全去中心化。"
			local docker_url="官网介绍: https://github.com/syncthing/syncthing"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		101 | moneyprinterturbo)
			local app_id="101"
			local app_name="AI视频生成工具"
			local app_text="MoneyPrinterTurbo是一款使用AI大模型合成高清短视频的工具"
			local app_url="官方网站: https://github.com/harry0703/MoneyPrinterTurbo"
			local docker_name="moneyprinterturbo"
			local docker_port="8101"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/harry0703/MoneyPrinterTurbo.git && cd MoneyPrinterTurbo/
				sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml

				docker compose up -d
				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/MoneyPrinterTurbo/ && docker compose down --rmi all
				cd /home/docker/MoneyPrinterTurbo/
				git pull origin main
				sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml
				cd /home/docker/MoneyPrinterTurbo/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/MoneyPrinterTurbo/ && docker compose down --rmi all
				rm -rf /home/docker/MoneyPrinterTurbo
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		102 | vocechat)

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

			local docker_describe="是一款支持独立部署的个人云社交媒体聊天服务"
			local docker_url="官网介绍: https://github.com/Privoce/vocechat-web"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		103 | umami)
			local app_id="103"
			local app_name="Umami网站统计工具"
			local app_text="开源、轻量、隐私友好的网站分析工具，类似于GoogleAnalytics。"
			local app_url="官方网站: https://github.com/umami-software/umami"
			local docker_name="umami-umami-1"
			local docker_port="8103"
			local app_size="1"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/umami-software/umami.git && cd umami
				sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/umami/docker-compose.yml

				docker compose up -d
				clear
				echo "نصب به پایان رسید"
				check_docker_app_ip
				echo "نام کاربری اولیه: admin"
				echo "رمز اولیه: umami"
			}

			docker_app_update() {
				cd /home/docker/umami/ && docker compose down --rmi all
				cd /home/docker/umami/
				git pull origin main
				sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/umami/docker-compose.yml
				cd /home/docker/umami/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/umami/ && docker compose down --rmi all
				rm -rf /home/docker/umami
				echo "برنامه حذف نصب شده است"
			}

			docker_app_plus

			;;

		104 | nginx-stream)
			stream_panel
			;;

		105 | siyuan)

			local app_id="105"
			local docker_name="siyuan"
			local docker_img="b3log/siyuan"
			local docker_port=8105

			docker_rum() {

				read -e -p "تنظیم رمز ورود به سیستم:" app_passwd

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

			local docker_describe="思源笔记是一款隐私优先的知识管理系统"
			local docker_url="官网介绍: https://github.com/siyuan-note/siyuan"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		106 | drawnix)

			local app_id="106"
			local docker_name="drawnix"
			local docker_img="pubuzhixing/drawnix"
			local docker_port=8106

			docker_rum() {

				docker run -d \
					--restart=always \
					--name drawnix \
					-p ${docker_port}:80 \
					pubuzhixing/drawnix

			}

			local docker_describe="是一款强大的开源白板工具，集成思维导图、流程图等。"
			local docker_url="官网介绍: https://github.com/plait-board/drawnix"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		107 | pansou)

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
					-e ENABLED_PLUGINS="labi,zhizhen,shandian,duoduo,muou,wanou" \
					ghcr.io/fish2018/pansou-web

			}

			local docker_describe="PanSou是一个高性能的网盘资源搜索API服务。"
			local docker_url="官网介绍: https://github.com/fish2018/pansou"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		b)
			clear
			send_stats "全部应用备份"

			local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
			echo -e "${gl_huang} در حال پشتیبان گیری از $backup_filename ...${gl_bai}"
			cd / && tar czvf "$backup_filename" home

			while true; do
				clear
				echo "فایل پشتیبان ایجاد شد: /$backup_filename"
				read -e -p "آیا می خواهید اطلاعات پشتیبان را به یک سرور راه دور منتقل کنید؟ (y/N):" choice
				case "$choice" in
				[Yy])
					read -e -p "لطفا IP سرور راه دور را وارد کنید:" remote_ip
					read -e -p "پورت SSH سرور هدف [پیش‌فرض 22]:" TARGET_PORT
					local TARGET_PORT=${TARGET_PORT:-22}

					if [ -z "$remote_ip" ]; then
						echo "خطا: لطفاً IP سرور راه دور را وارد کنید."
						continue
					fi
					local latest_tar=$(ls -t /app*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
						echo "فایل به دایرکتوری سرور/ریشه راه دور منتقل شد."
					else
						echo "فایلی که قرار است منتقل شود پیدا نشد."
					fi
					break
					;;
				*)
					echo "توجه: نسخه پشتیبان فعلی فقط شامل پروژه‌های docker می‌شود و شامل پشتیبان‌گیری از اطلاعات پنل‌های ساخت وب‌سایت مانند Pagoda و 1panel نمی‌شود."
					break
					;;
				esac
			done

			;;

		r)
			root_use
			send_stats "全部应用还原"
			echo "نسخه پشتیبان از برنامه های موجود"
			echo "-------------------------"
			ls -lt /app*.gz | awk '{print $NF}'
			echo ""
			read -e -p "برای بازیابی آخرین نسخه پشتیبان، کلید Enter را فشار دهید، نام فایل پشتیبان را برای بازیابی نسخه پشتیبان مشخص شده وارد کنید، برای خروج 0 را وارد کنید:" filename

			if [ "$filename" == "0" ]; then
				break_end
				linux_panel
			fi

			# 如果用户没有输入文件名，使用最新的压缩包
			if [ -z "$filename" ]; then
				local filename=$(ls -t /app*.tar.gz | head -1)
			fi

			if [ -n "$filename" ]; then
				echo -e "${gl_huang} $filename را از حالت فشرده خارج می کند ...${gl_bai}"
				cd / && tar -xzf "$filename"
				echo "داده های برنامه بازیابی شده است. در حال حاضر، لطفاً به صورت دستی وارد منوی برنامه مشخص شده شوید و برنامه را برای بازیابی برنامه به روز کنید."
			else
				echo "بسته فشرده یافت نشد."
			fi

			;;

		0)
			kejilion
			;;
		*) ;;
		esac
		break_end
		sub_choice=""

	done
}

linux_work() {

	while true; do
		clear
		send_stats "后台工作区"
		echo -e "فضای کاری Backend"
		echo -e "این سیستم فضای کاری را در اختیار شما قرار می دهد که می تواند به طور دائم در پس زمینه اجرا شود و می توانید از آن برای انجام کارهای طولانی مدت استفاده کنید."
		echo -e "حتی اگر SSH را قطع کنید، وظایف در فضای کاری قطع نمی‌شوند و وظایف در پس‌زمینه باقی می‌مانند."
		echo -e "${gl_huang} نکات: ${gl_bai} پس از ورود به فضای کاری، از Ctrl+b استفاده کنید و سپس d را به تنهایی فشار دهید تا از فضای کاری خارج شوید!"
		echo -e "${gl_kjlan}------------------------"
		echo "فهرست فضاهای کاری موجود"
		echo -e "${gl_kjlan}------------------------"
		tmux list-sessions
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai}فضای کاری شماره 1"
		echo -e "${gl_kjlan}2. ${gl_bai}فضای کاری شماره 2"
		echo -e "${gl_kjlan}3. ${gl_bai}فضای کاری شماره 3"
		echo -e "${gl_kjlan}4. ${gl_bai}فضای کاری شماره 4"
		echo -e "${gl_kjlan}5. ${gl_bai}فضای کاری شماره 5"
		echo -e "${gl_kjlan}6. ${gl_bai}فضای کاری شماره 6"
		echo -e "${gl_kjlan}7. ${gl_bai}فضای کاری شماره 7"
		echo -e "${gl_kjlan}8. ${gl_bai}فضای کاری شماره 8"
		echo -e "${gl_kjlan}9. ${gl_bai}فضای کاری شماره 9"
		echo -e "${gl_kjlan}10. ${gl_bai}فضای کاری شماره 10"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21. ${gl_bai}SSH حالت مقیم ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}22. ${gl_bai}ایجاد/وارد فضای کاری"
		echo -e "${gl_kjlan}23. ${gl_bai} دستورات را به فضای کاری پس‌زمینه تزریق می‌کند"
		echo -e "${gl_kjlan}24. ${gl_bai}حذف فضای کاری مشخص شده"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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
				echo -e "حالت ساکن SSH ${tmux_sshd_status}"
				echo "پس از باز کردن اتصال SSH، مستقیماً وارد حالت مقیم می شود و مستقیماً به حالت کار قبلی باز می گردد."
				echo "------------------------"
				echo "1. روشن 2. خاموش"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" gongzuoqu_del
				case "$gongzuoqu_del" in
				1)
					install tmux
					local SESSION_NAME="sshd"
					send_stats "启动工作区$SESSION_NAME"
					grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# 自动进入 tmux 会话\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >>~/.bashrc
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
			read -e -p "لطفاً نام فضای کاری را که ایجاد کرده یا وارد کرده اید، مانند 1001 kj001 work1 وارد کنید:" SESSION_NAME
			tmux_run
			send_stats "自定义工作区"
			;;

		23)
			read -e -p "لطفاً دستوری را که می خواهید در پس زمینه اجرا کنید وارد کنید، مانند: curl -fsSL https://get.docker.com | sh:" tmuxd
			tmux_run_d
			send_stats "注入命令到后台工作区"
			;;

		24)
			read -e -p "لطفاً نام فضای کاری را که می خواهید حذف کنید وارد کنید:" gongzuoqu_name
			tmux kill-window -t $gongzuoqu_name
			send_stats "删除工作区"
			;;

		0)
			kejilion
			;;
		*)
			echo "ورودی نامعتبر است!"
			;;
		esac
		break_end

	done

}

linux_Settings() {

	while true; do
		clear
		# send_stats "系统工具"
		echo -e "ابزارهای سیستم"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai} کلید میانبر راه اندازی اسکریپت ${gl_kjlan}2 را تنظیم کنید. ${gl_bai} رمز ورود را تغییر دهید"
		echo -e "${gl_kjlan}3. ${gl_bai}حالت ورود رمز عبور ROOT ${gl_kjlan}4. ${gl_bai}نسخه مشخص شده پایتون را نصب کنید"
		echo -e "${gl_kjlan}5. ${gl_bai}همه پورت ها را باز کنید ${gl_kjlan}6. ${gl_bai}درگاه اتصال SSH را تغییر دهید"
		echo -e "${gl_kjlan}7. ${gl_bai}بهینه سازی آدرس DNS ${gl_kjlan}8. ${gl_bai}با یک کلیک سیستم را دوباره نصب کنید ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}9. ${gl_bai} برای ایجاد حساب جدید ${gl_kjlan}10 حساب ROOT را غیرفعال کنید. ${gl_bai} اولویت را به ipv4/ipv6 تغییر دهید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11. ${gl_bai} وضعیت اشغال پورت را بررسی کنید ${gl_kjlan}12. ${gl_bai} اندازه حافظه مجازی را تغییر دهید"
		echo -e "${gl_kjlan}13. ${gl_bai}مدیریت کاربر ${gl_kjlan}14. ${gl_bai}User/Password Generator"
		echo -e "${gl_kjlan}15. ${gl_bai} تنظیم منطقه زمانی سیستم ${gl_kjlan}16. ${gl_bai} شتاب BBR3 را تنظیم کنید"
		echo -e "${gl_kjlan}17. ${gl_bai} Advanced Firewall Manager ${gl_kjlan}18. ${gl_bai} نام میزبان را تغییر دهید"
		echo -e "${gl_kjlan}19. ${gl_bai}منبع به روز رسانی سیستم را تغییر دهید ${gl_kjlan}20. ${gl_bai} مدیریت وظایف برنامه ریزی شده"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21. ${gl_bai} وضوح میزبان اصلی ${gl_kjlan}22. ${gl_bai}برنامه دفاعی SSH"
		echo -e "${gl_kjlan}23. ${gl_bai}خاموش شدن خودکار محدود کننده فعلی ${gl_kjlan}24. حالت ورود به سیستم کلید خصوصی ${gl_bai}ROOT"
		echo -e "${gl_kjlan}25. ${gl_bai}TG-bot سیستم نظارت و هشدار ${gl_kjlan}26. ${gl_bai} آسیب پذیری های پرخطر OpenSSH را تعمیر کنید"
		echo -e "${gl_kjlan}27. ${gl_bai}به‌روزرسانی هسته لینوکس Red Hat ${gl_kjlan}28. ${gl_bai}بهینه سازی پارامتر هسته سیستم لینوکس ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}29. ${gl_bai}ابزار اسکن ویروس ${gl_huang}★${gl_bai} ${gl_kjlan}30. ${gl_bai}مدیر فایل"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31. ${gl_bai}تغییر زبان سیستم ${gl_kjlan}32. ${gl_bai}ابزار زیباسازی خط فرمان ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33. ${gl_bai} سطل بازیافت سیستم ${gl_kjlan}34 را راه اندازی کنید. ${gl_bai} پشتیبان گیری و بازیابی سیستم"
		echo -e "${gl_kjlan}35. ${gl_bai}ssh ابزار اتصال از راه دور ${gl_kjlan}36. ${gl_bai}ابزار مدیریت پارتیشن هارد دیسک"
		echo -e "${gl_kjlan}37. ${gl_bai} سابقه خط فرمان ${gl_kjlan}38. ${gl_bai}rsync ابزار همگام سازی از راه دور"
		echo -e "${gl_kjlan}39. ${gl_bai} دستور موارد دلخواه ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41. ${gl_bai}برد پیام ${gl_kjlan}66. ${gl_bai}تنظیم سیستم یک مرحله ای ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}99. ${gl_bai}راه اندازی مجدد سرور ${gl_kjlan}100. ${gl_bai}حریم خصوصی و امنیت"
		echo -e "${gl_kjlan}101. ${gl_bai}k دستور استفاده پیشرفته ${gl_huang}★${gl_bai} ${gl_kjlan}102. ${gl_bai}اسکریپت شیر ​​فناوری را حذف کنید"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

		case $sub_choice in
		1)
			while true; do
				clear
				read -e -p "لطفا کلیدهای میانبر خود را وارد کنید (برای خروج 0 را وارد کنید):" kuaijiejian
				if [ "$kuaijiejian" == "0" ]; then
					break_end
					linux_Settings
				fi
				find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				echo "کلیدهای میانبر تنظیم شده است"
				send_stats "脚本快捷键已设置"
				break_end
				linux_Settings
			done
			;;

		2)
			clear
			send_stats "设置你的登录密码"
			echo "رمز ورود خود را تنظیم کنید"
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
			echo "مدیریت نسخه پایتون"
			echo "معرفی ویدیو: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "این تابع می تواند به طور یکپارچه هر نسخه ای را که به طور رسمی توسط پایتون پشتیبانی می شود نصب کند!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "شماره نسخه فعلی پایتون: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "نسخه های پیشنهادی: 3.12 3.11 3.10 3.9 3.8 2.7"
			echo "نسخه های بیشتر را بررسی کنید: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "شماره نسخه پایتون را که می خواهید نصب کنید وارد کنید (برای خروج 0 را وارد کنید):" py_new_v

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
					echo "/usr/local/openssl/lib" >/etc/ld.so.conf.d/openssl-1.1.1u.conf
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
					apk add --no-cache bash gcc musl-dev libffi-dev openssl-dev bzip2-dev zlib-dev readline-dev sqlite-dev libc6-compat linux-headers make xz-dev build-base ncurses-dev
				else
					echo "مدیر بسته ناشناس!"
					return
				fi

				curl https://pyenv.run | bash
				cat <<EOF >>~/.bashrc

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
			echo -e "شماره نسخه فعلی پایتون: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			;;

		5)
			root_use
			send_stats "开放端口"
			iptables_open
			remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
			echo "همه پورت ها باز هستند"

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
				echo -e "شماره پورت SSH فعلی: ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "شماره پورت از 1 تا 65535 است. (برای خروج 0 را وارد کنید)"

				# 提示用户输入新的 SSH 端口号
				read -e -p "لطفا شماره پورت SSH جدید را وارد کنید:" new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "شماره پورت نامعتبر است. لطفا عددی بین 1 تا 65535 وارد کنید."
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "ورودی نامعتبر است، لطفاً یک عدد وارد کنید."
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
			read -e -p "لطفا یک نام کاربری جدید وارد کنید (0 را برای خروج وارد کنید):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			install sudo

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "عملیات کامل شده است."
			;;

		10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "اولویت v4/v6 را تنظیم کنید"
				echo "------------------------"

				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "تنظیم اولویت شبکه فعلی: اولویت ${gl_huang}IPv4${gl_bai}"
				else
					echo -e "تنظیم اولویت شبکه فعلی: اولویت ${gl_huang}IPv6${gl_bai}"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 اول 2. IPv6 اول 3. ابزار تعمیر IPv6"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "شبکه مورد نظر خود را انتخاب کنید:" choice

				case $choice in
				1)
					grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null ||
						echo 'precedence ::ffff:0:0/96  100' >>/etc/gai.conf
					echo "به اولویت IPv4 تغییر وضعیت داد"
					send_stats "已切换为 IPv4 优先"
					;;
				2)
					rm -f /etc/gai.conf
					echo "ابتدا به IPv6 سوئیچ شد"
					send_stats "已切换为 IPv6 优先"
					;;

				3)
					clear
					bash <(curl -L -s jhb.ovh/jb/v6.sh)
					echo "این تابع توسط jhb ارائه شده است، از او متشکرم!"
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
				echo "حافظه مجازی را تنظیم کنید"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "حافظه مجازی فعلی: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. اختصاص 1024M 2. اختصاص 2048M 3. اختصاص 4096M 4. اندازه سفارشی"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" choice

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
					read -e -p "لطفاً اندازه حافظه مجازی (واحد M) را وارد کنید:" new_swap
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
				echo "لیست کاربران"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done </etc/passwd

				echo ""
				echo "عملیات حساب"
				echo "------------------------"
				echo "1. ایجاد یک حساب معمولی 2. ایجاد یک حساب حق بیمه"
				echo "------------------------"
				echo "3. اعطای بالاترین مقام 4. حذف بالاترین مقام"
				echo "------------------------"
				echo "5. حذف اکانت"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				case $sub_choice in
				1)
					# 提示用户输入新用户名
					read -e -p "لطفا یک نام کاربری جدید وارد کنید:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					echo "عملیات کامل شده است."
					;;

				2)
					# 提示用户输入新用户名
					read -e -p "لطفا یک نام کاربری جدید وارد کنید:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					# 赋予新用户sudo权限
					echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					install sudo

					echo "عملیات کامل شده است."

					;;
				3)
					read -e -p "لطفا نام کاربری را وارد کنید:" username
					# 赋予新用户sudo权限
					echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					install sudo
					;;
				4)
					read -e -p "لطفا نام کاربری را وارد کنید:" username
					# 从sudoers文件中移除用户的sudo权限
					sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

					;;
				5)
					read -e -p "لطفا نام کاربری را که می خواهید حذف کنید وارد کنید:" username
					# 删除用户及其主目录
					userdel -r "$username"
					;;

				*)
					break # 跳出循环，退出菜单
					;;
				esac
			done
			;;

		14)
			clear
			send_stats "用户信息生成器"
			echo "نام کاربری تصادفی"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(</dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "نام کاربری تصادفی $i: $username"
			done

			echo ""
			echo "نام تصادفی"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "نام کاربری تصادفی $i: $user_name"
			done

			echo ""
			echo "UUID تصادفی"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "UUID تصادفی $i: $uuid"
			done

			echo ""
			echo "رمز عبور تصادفی 16 رقمی"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "رمز عبور تصادفی $i: $password"
			done

			echo ""
			echo "رمز عبور تصادفی 32 بیتی"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "رمز عبور تصادفی $i: $password"
			done
			echo ""

			;;

		15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "اطلاعات زمان سیستم"

				# 获取当前系统时区
				local timezone=$(current_timezone)

				# 获取当前系统时间
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 显示时区和时间
				echo "منطقه زمانی سیستم فعلی: $timezone"
				echo "زمان فعلی سیستم: $current_time"

				echo ""
				echo "سوئیچ منطقه زمانی"
				echo "------------------------"
				echo "آسیا"
				echo "1. شانگهای، به وقت چین 2. به وقت هنگ کنگ، چین"
				echo "3. توکیو، به وقت ژاپن 4. سئول، به وقت کره جنوبی"
				echo "5. به وقت سنگاپور 6. کلکته، به وقت هند"
				echo "7. دبی، زمان امارات متحده عربی 8. سیدنی، به وقت استرالیا"
				echo "9. بانکوک، به وقت تایلند"
				echo "------------------------"
				echo "اروپا"
				echo "11. لندن، به وقت انگلستان 12. پاریس، به وقت فرانسه"
				echo "13. برلین، زمان آلمان 14. به وقت روسیه، مسکو"
				echo "15. وقت اوتراخت، هلند 16. وقت مادرید، اسپانیا"
				echo "------------------------"
				echo "آمریکا"
				echo "21. وقت غربی آمریکا 22. وقت شرقی آمریکا"
				echo "23. وقت کانادا 24. به وقت مکزیک"
				echo "25. وقت برزیل 26. به وقت آرژانتین"
				echo "------------------------"
				echo "31. زمان استاندارد جهانی UTC"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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
				echo -e "نام میزبان فعلی: ${gl_huang}$current_hostname${gl_bai}"
				echo "------------------------"
				read -e -p "لطفاً یک نام میزبان جدید وارد کنید (0 را برای خروج وارد کنید):" new_hostname
				if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
					if [ -f /etc/alpine-release ]; then
						# Alpine
						echo "$new_hostname" >/etc/hostname
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
						echo "127.0.0.1       $new_hostname localhost localhost.localdomain" >>/etc/hosts
					fi

					if grep -q "^::1" /etc/hosts; then
						sed -i "s/^::1 .*/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/g" /etc/hosts
					else
						echo "::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback" >>/etc/hosts
					fi

					echo "نام میزبان به $new_hostname تغییر یافته است"
					send_stats "主机名已更改"
					sleep 1
				else
					echo "بدون تغییر نام میزبان خارج شد."
					break
				fi
			done
			;;

		19)
			root_use
			send_stats "换系统更新源"
			clear
			echo "منطقه منبع به روز رسانی را انتخاب کنید"
			echo "برای تغییر منابع به روز رسانی سیستم به LinuxMirrors دسترسی داشته باشید"
			echo "------------------------"
			echo "1. سرزمین اصلی چین [پیش فرض] 2. سرزمین اصلی چین [شبکه آموزش] 3. مناطق خارج از کشور"
			echo "------------------------"
			echo "0. به منوی قبلی برگردید"
			echo "------------------------"
			read -e -p "انتخاب خود را وارد کنید:" choice

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
				echo "لغو شد"
				;;

			esac

			;;

		20)
			send_stats "定时任务管理"
			while true; do
				clear
				check_crontab_installed
				clear
				echo "لیست وظایف برنامه ریزی شده"
				crontab -l
				echo ""
				echo "عمل کنند"
				echo "------------------------"
				echo "1. اضافه کردن یک کار برنامه ریزی شده 2. حذف یک کار زمان بندی شده 3. ویرایش یک کار برنامه ریزی شده"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				case $sub_choice in
				1)
					read -e -p "لطفا دستور اجرای وظیفه جدید را وارد کنید:" newquest
					echo "------------------------"
					echo "1. وظایف ماهانه 2. وظایف هفتگی"
					echo "3. وظایف روزانه 4. وظایف ساعتی"
					echo "------------------------"
					read -e -p "لطفا انتخاب خود را وارد کنید:" dingshi

					case $dingshi in
					1)
						read -e -p "چه روزی از ماه را برای اجرای کار انتخاب می کنید؟ (1-30):" day
						(
							crontab -l
							echo "0 0 $day * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					2)
						read -e -p "یک روز از هفته را برای انجام کار انتخاب کنید؟ (0-6، 0 نشان دهنده یکشنبه است):" weekday
						(
							crontab -l
							echo "0 0 * * $weekday $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					3)
						read -e -p "هر روز چه ساعتی را برای انجام کار انتخاب می کنید؟ (ساعت 0-23):" hour
						(
							crontab -l
							echo "0 $hour * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					4)
						read -e -p "وارد کنید چه زمانی از ساعت باید کار اجرا شود؟ (دقیقه 0-60):" minute
						(
							crontab -l
							echo "$minute * * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					*)
						break # 跳出
						;;
					esac
					send_stats "添加定时任务"
					;;
				2)
					read -e -p "لطفا کلمه کلیدی کاری که باید حذف شود را وارد کنید:" kquest
					crontab -l | grep -v "$kquest" | crontab -
					send_stats "删除定时任务"
					;;
				3)
					crontab -e
					send_stats "编辑定时任务"
					;;
				*)
					break # 跳出循环，退出菜单
					;;
				esac
			done

			;;

		21)
			root_use
			send_stats "本地host解析"
			while true; do
				clear
				echo "لیست وضوح میزبان بومی"
				echo "اگر تطبیق تجزیه را در اینجا اضافه کنید، تجزیه پویا دیگر استفاده نخواهد شد"
				cat /etc/hosts
				echo ""
				echo "عمل کنند"
				echo "------------------------"
				echo "1. اضافه کردن وضوح جدید 2. حذف آدرس وضوح"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" host_dns

				case $host_dns in
				1)
					read -e -p "لطفاً فرمت رکورد تجزیه جدیدی را وارد کنید: 110.25.5.33 kejilion.pro:" addhost
					echo "$addhost" >>/etc/hosts
					send_stats "本地host解析新增"

					;;
				2)
					read -e -p "لطفاً کلمات کلیدی محتوای تجزیه شده را که باید حذف شوند وارد کنید:" delhost
					sed -i "/$delhost/d" /etc/hosts
					send_stats "本地host解析删除"
					;;
				*)
					break # 跳出循环，退出菜单
					;;
				esac
			done
			;;

		22)
			root_use
			send_stats "ssh防御"
			while true; do

				check_f2b_status
				echo -e "برنامه دفاعی SSH $check_f2b_status"
				echo "fail2ban یک ابزار SSH برای جلوگیری از شکستن brute force است"
				echo "معرفی وب سایت رسمی: ${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. یک برنامه دفاعی نصب کنید"
				echo "------------------------"
				echo "2. مشاهده سوابق رهگیری SSH"
				echo "3. نظارت بر گزارش بلادرنگ"
				echo "------------------------"
				echo "9. برنامه دفاعی را حذف کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
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
					echo "برنامه دفاعی Fail2Ban حذف نصب شده است"
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
				echo "عملکرد خاموش کردن محدود کننده فعلی"
				echo "معرفی ویدیو: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "استفاده از ترافیک فعلی با راه اندازی مجدد سرور پاک می شود!"
				output_status
				echo -e "${gl_kjlan}مجموع دریافت: ${gl_bai}$rx"
				echo -e "${gl_kjlan}مجموع ارسال شده: ${gl_bai}$tx"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}آستانه محدودیت فعلی ورودی فعلی تنظیم شده است: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}آستانه محدود کننده جریان خروجی فعلی تنظیم شده است: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui} عملکرد محدودکننده خاموش کردن فعلی در حال حاضر فعال نیست ${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "سیستم تشخیص می دهد که آیا ترافیک واقعی در هر دقیقه به آستانه می رسد یا خیر و پس از رسیدن به آستانه به طور خودکار سرور را خاموش می کند!"
				echo "------------------------"
				echo "1. عملکرد خاموش کردن محدود کننده فعلی را فعال کنید. 2. عملکرد خاموش کردن محدود کننده فعلی را غیرفعال کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" Limiting

				case "$Limiting" in
				1)
					# 输入新的虚拟内存大小
					echo "اگر سرور واقعی فقط 100G ترافیک دارد، می توانید آستانه را روی 95G تنظیم کنید و از قبل خاموش کنید تا از خطاهای ترافیکی یا سرریزها جلوگیری کنید."
					read -e -p "لطفاً آستانه ترافیک ورودی را وارد کنید (واحد G، پیش‌فرض 100G است):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "لطفاً آستانه ترافیک خروجی را وارد کنید (واحد G، پیش‌فرض 100G است):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "لطفاً تاریخ بازنشانی ترافیک را وارد کنید (پیش‌فرض در اول هر ماه بازنشانی می‌شود):" cz_day
					cz_day=${cz_day:-1}

					cd ~
					curl -Ss -o ~/Limiting_Shut_down.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh
					chmod +x ~/Limiting_Shut_down.sh
					sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
					sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					(
						crontab -l
						echo "* * * * * ~/Limiting_Shut_down.sh"
					) | crontab - >/dev/null 2>&1
					crontab -l | grep -v 'reboot' | crontab -
					(
						crontab -l
						echo "0 1 $cz_day * * reboot"
					) | crontab - >/dev/null 2>&1
					echo "خاموشی محدود کننده فعلی تنظیم شده است"
					send_stats "限流关机已设置"
					;;
				2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "عملکرد خاموش کردن محدود کننده فعلی خاموش است"
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
				echo "حالت ورود کلید خصوصی ROOT"
				echo "معرفی ویدیو: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
				echo "------------------------------------------------"
				echo "یک جفت کلید ایجاد خواهد شد، راهی امن تر برای ورود از طریق SSH"
				echo "------------------------"
				echo "1. یک کلید جدید ایجاد کنید 2. یک کلید موجود را وارد کنید 3. کلید محلی را مشاهده کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" host_dns

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
					echo "اطلاعات کلید عمومی"
					cat ~/.ssh/authorized_keys
					echo "------------------------"
					echo "اطلاعات کلید خصوصی"
					cat ~/.ssh/sshkey
					echo "------------------------"
					break_end

					;;
				*)
					break # 跳出循环，退出菜单
					;;
				esac
			done

			;;

		25)
			root_use
			send_stats "电报预警"
			echo "عملکرد نظارت و هشدار اولیه TG-bot"
			echo "معرفی ویدیو: https://youtu.be/vLL-eb3Z_TY"
			echo "------------------------------------------------"
			echo "شما باید API ربات tg و شناسه کاربری را پیکربندی کنید تا هشدارها را دریافت کنید تا به نظارت و هشدارهای CPU محلی، حافظه، هارد دیسک، ترافیک و ورود به سیستم SSH در زمان واقعی دست یابید."
			echo "پس از رسیدن به آستانه، یک پیام هشدار برای کاربر ارسال می شود."
			echo -e "${gl_hui} - در مورد ترافیک، راه اندازی مجدد سرور دوباره محاسبه می شود - ${gl_bai}"
			read -e -p "آیا مطمئن هستید که می خواهید ادامه دهید؟ (y/N):" choice

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
				tmux kill-session -t TG-check-notify >/dev/null 2>&1
				tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
				crontab -l | grep -v '~/TG-check-notify.sh' | crontab - >/dev/null 2>&1
				(
					crontab -l
					echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'"
				) | crontab - >/dev/null 2>&1

				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh >/dev/null 2>&1
				sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh >/dev/null 2>&1
				sed -i "4i$(grep '^CHAT_ID=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh
				chmod +x ~/TG-SSH-check-notify.sh

				# 添加到 ~/.profile 文件中
				if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile >/dev/null 2>&1; then
					echo 'bash ~/TG-SSH-check-notify.sh' >>~/.profile
					if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						echo 'source ~/.profile' >>~/.bashrc
					fi
				fi

				source ~/.profile

				clear
				echo "سیستم هشدار اولیه TG-bot فعال شده است"
				echo -e "${gl_hui}همچنین می توانید فایل اخطار TG-check-notify.sh را در دایرکتوری ریشه روی ماشین های دیگر قرار داده و مستقیماً از آن استفاده کنید! ${gl_bai}"
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
					[ -f "$file" ] && {
						echo "$file"
						return
					}
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
			echo "از تابلوی پیام رسمی شیر فناوری دیدن کنید. اگر نظری در مورد فیلمنامه دارید، لطفا برای تبادل پیام بگذارید!"
			echo "https://board.kejilion.pro"
			echo "رمز عبور عمومی: kejilion.sh"
			;;

		66)

			root_use
			send_stats "一条龙调优"
			echo "تنظیم سیستم یک مرحله ای"
			echo "------------------------------------------------"
			echo "محتوای زیر عملیاتی و بهینه خواهد شد"
			echo "1. سیستم را به جدیدترین آپدیت کنید"
			echo "2. فایل های ناخواسته سیستم را پاک کنید"
			echo -e "3. تنظیم حافظه مجازی ${gl_huang}1G${gl_bai}"
			echo -e "4. شماره پورت SSH را روی ${gl_huang}5522${gl_bai} تنظیم کنید"
			echo -e "5. همه پورت ها را باز کنید"
			echo -e "6. شتاب ${gl_huang}BBR${gl_bai} را فعال کنید"
			echo -e "7. منطقه زمانی را روی ${gl_huang}Shanghai${gl_bai} تنظیم کنید"
			echo -e "8. بهینه سازی خودکار آدرس DNS ${gl_huang} خارج از کشور: 1.1.1.1 8.8.8.8 داخلی: 223.5.5.5 ${gl_bai}"
			echo -e "9. ابزارهای اساسی ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai} را نصب کنید"
			echo -e "10. بهینه سازی پارامتر هسته سیستم لینوکس به حالت بهینه سازی متعادل ${gl_huang} ${gl_bai} تغییر می کند."
			echo "------------------------------------------------"
			read -e -p "آیا مطمئن هستید که می خواهید تعمیر و نگهداری با یک کلیک را انجام دهید؟ (y/N):" choice

			case "$choice" in
			[Yy])
				clear
				send_stats "一条龙调优启动"
				echo "------------------------------------------------"
				linux_update
				echo -e "[${gl_lv}OK${gl_bai}] 1/10. سیستم را به جدیدترین آپدیت کنید"

				echo "------------------------------------------------"
				linux_clean
				echo -e "[${gl_lv}OK${gl_bai}] 2/10. فایل های ناخواسته سیستم را پاک کنید"

				echo "------------------------------------------------"
				add_swap 1024
				echo -e "[${gl_lv}OK${gl_bai}] 3/10. تنظیم حافظه مجازی ${gl_huang}1G${gl_bai}"

				echo "------------------------------------------------"
				local new_port=5522
				new_ssh_port
				echo -e "[${gl_lv}OK${gl_bai}] 4/10. شماره پورت SSH را روی ${gl_huang}5522${gl_bai} تنظیم کنید"
				echo "------------------------------------------------"
				echo -e "[${gl_lv}OK${gl_bai}] 5/10. همه پورت ها را باز کنید"

				echo "------------------------------------------------"
				bbr_on
				echo -e "[${gl_lv}OK${gl_bai}] 6/10. شتاب ${gl_huang}BBR${gl_bai} را روشن کنید"

				echo "------------------------------------------------"
				set_timedate Asia/Shanghai
				echo -e "[${gl_lv}OK${gl_bai}] 7/10. تنظیم منطقه زمانی روی ${gl_huang}Shanghai${gl_bai}"

				echo "------------------------------------------------"
				local country=$(curl -s ipinfo.io/country)
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

				set_dns
				echo -e "[${gl_lv}OK${gl_bai}] 8/10. بهینه سازی خودکار آدرس DNS ${gl_huang}${gl_bai}"

				echo "------------------------------------------------"
				install_docker
				install wget sudo tar unzip socat btop nano vim
				echo -e "[${gl_lv}OK${gl_bai}] 9/10. نصب ابزارهای اساسی ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				echo "------------------------------------------------"

				echo "------------------------------------------------"
				optimize_balanced
				echo -e "[${gl_lv}OK${gl_bai}] 10/10. بهینه سازی پارامتر هسته سیستم لینوکس"
				echo -e "${gl_lv}تنظیم سیستم یک مرحله ای تکمیل شد${gl_bai}"

				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
				if grep -q '^ENABLE_STATS="true"' /usr/local/bin/k >/dev/null 2>&1; then
					local status_message="${gl_lv}正在采集数据${gl_bai}"
				elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k >/dev/null 2>&1; then
					local status_message="${gl_hui}采集已关闭${gl_bai}"
				else
					local status_message="无法确定的状态"
				fi

				echo "حریم خصوصی و امنیت"
				echo "این اسکریپت داده هایی را در مورد استفاده کاربران از توابع جمع آوری می کند، تجربه اسکریپت را بهینه می کند و عملکردهای سرگرم کننده و مفیدتری ایجاد می کند."
				echo "شماره نسخه اسکریپت، زمان استفاده، نسخه سیستم، معماری CPU، کشور دستگاه و نام عملکرد مورد استفاده جمع آوری می شود،"
				echo "------------------------------------------------"
				echo -e "وضعیت فعلی: $status_message"
				echo "--------------------"
				echo "1. شروع به جمع آوری"
				echo "2. مجموعه را ببندید"
				echo "--------------------"
				echo "0. به منوی قبلی برگردید"
				echo "--------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
				case $sub_choice in
				1)
					cd ~
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					echo "جمع آوری آغاز شده است"
					send_stats "隐私与安全已开启采集"
					;;
				2)
					cd ~
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					echo "مجموعه بسته شد"
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
			echo "اسکریپت tech lion را حذف نصب کنید"
			echo "------------------------------------------------"
			echo "اسکریپت kejilion به طور کامل بدون تأثیر بر سایر عملکردهای شما حذف خواهد شد."
			read -e -p "آیا مطمئن هستید که می خواهید ادامه دهید؟ (y/N):" choice

			case "$choice" in
			[Yy])
				clear
				(crontab -l | grep -v "kejilion.sh") | crontab -
				rm -f /usr/local/bin/k
				rm ~/kejilion.sh
				echo "اسکریپت حذف شده است، خداحافظ!"
				break_end
				clear
				exit
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion

			;;
		*)
			echo "ورودی نامعتبر است!"
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
		echo "مدیر فایل"
		echo "------------------------"
		echo "مسیر فعلی"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. دایرکتوری را وارد کنید. 2. دایرکتوری را ایجاد کنید. 3. مجوزهای دایرکتوری را تغییر دهید. 4. نام دایرکتوری را تغییر دهید."
		echo "5. دایرکتوری را حذف کنید. 6. به فهرست منوی قبلی بازگردید"
		echo "------------------------"
		echo "11. ایجاد فایل ها 12. ویرایش فایل ها 13. تغییر مجوزهای فایل 14. تغییر نام فایل ها"
		echo "15. فایل ها را حذف کنید"
		echo "------------------------"
		echo "21. فشرده سازی دایرکتوری فایل 22. از حالت فشرده خارج کردن دایرکتوری فایل 23. انتقال دایرکتوری فایل 24. کپی کردن دایرکتوری فایل"
		echo "25. فایل ها را به سرورهای دیگر انتقال دهید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" Limiting

		case "$Limiting" in
		1) # 进入目录
			read -e -p "لطفا نام دایرکتوری را وارد کنید:" dirname
			cd "$dirname" 2>/dev/null || echo "ورود به دایرکتوری امکان پذیر نیست"
			send_stats "进入目录"
			;;
		2) # 创建目录
			read -e -p "لطفاً نام دایرکتوری ایجاد شده را وارد کنید:" dirname
			mkdir -p "$dirname" && echo "دایرکتوری ایجاد شد" || echo "ایجاد ناموفق بود"
			send_stats "创建目录"
			;;
		3) # 修改目录权限
			read -e -p "لطفا نام دایرکتوری را وارد کنید:" dirname
			read -e -p "لطفا مجوزها را وارد کنید (به عنوان مثال 755):" perm
			chmod "$perm" "$dirname" && echo "مجوزها اصلاح شده است" || echo "اصلاح نشد"
			send_stats "修改目录权限"
			;;
		4) # 重命名目录
			read -e -p "لطفاً نام دایرکتوری فعلی را وارد کنید:" current_name
			read -e -p "لطفا یک نام دایرکتوری جدید وارد کنید:" new_name
			mv "$current_name" "$new_name" && echo "دایرکتوری تغییر نام داده است" || echo "تغییر نام انجام نشد"
			send_stats "重命名目录"
			;;
		5) # 删除目录
			read -e -p "لطفاً نام دایرکتوری را برای حذف وارد کنید:" dirname
			rm -rf "$dirname" && echo "دایرکتوری حذف شد" || echo "حذف نشد"
			send_stats "删除目录"
			;;
		6) # 返回上一级选单目录
			cd ..
			send_stats "返回上一级选单目录"
			;;
		11) # 创建文件
			read -e -p "لطفا نام فایل ایجاد شده را وارد کنید:" filename
			touch "$filename" && echo "فایل ایجاد شد" || echo "ایجاد ناموفق بود"
			send_stats "创建文件"
			;;
		12) # 编辑文件
			read -e -p "لطفا نام فایل مورد نظر را برای ویرایش وارد کنید:" filename
			install nano
			nano "$filename"
			send_stats "编辑文件"
			;;
		13) # 修改文件权限
			read -e -p "لطفا یک نام فایل وارد کنید:" filename
			read -e -p "لطفا مجوزها را وارد کنید (به عنوان مثال 755):" perm
			chmod "$perm" "$filename" && echo "مجوزها اصلاح شده است" || echo "اصلاح نشد"
			send_stats "修改文件权限"
			;;
		14) # 重命名文件
			read -e -p "لطفا نام فایل فعلی را وارد کنید:" current_name
			read -e -p "لطفا یک نام فایل جدید وارد کنید:" new_name
			mv "$current_name" "$new_name" && echo "فایل تغییر نام داده است" || echo "تغییر نام انجام نشد"
			send_stats "重命名文件"
			;;
		15) # 删除文件
			read -e -p "لطفا نام فایل را برای حذف وارد کنید:" filename
			rm -f "$filename" && echo "فایل حذف شد" || echo "حذف نشد"
			send_stats "删除文件"
			;;
		21) # 压缩文件/目录
			read -e -p "لطفاً نام فایل/دایرکتوری را برای فشرده سازی وارد کنید:" name
			install tar
			tar -czvf "$name.tar.gz" "$name" && echo "به $name.tar.gz فشرده شده است" || echo "فشرده سازی انجام نشد"
			send_stats "压缩文件/目录"
			;;
		22) # 解压文件/目录
			read -e -p "لطفاً نام فایلی را که باید استخراج شود (.tar.gz) وارد کنید:" filename
			install tar
			tar -xzvf "$filename" && echo "$filename استخراج شد" || echo "رفع فشار ناموفق بود"
			send_stats "解压文件/目录"
			;;

		23) # 移动文件或目录
			read -e -p "لطفاً مسیر فایل یا دایرکتوری را برای جابجایی وارد کنید:" src_path
			if [ ! -e "$src_path" ]; then
				echo "خطا: فایل یا دایرکتوری وجود ندارد."
				send_stats "移动文件或目录失败: 文件或目录不存在"
				continue
			fi

			read -e -p "لطفاً مسیر مقصد (شامل نام فایل یا دایرکتوری جدید) را وارد کنید:" dest_path
			if [ -z "$dest_path" ]; then
				echo "خطا: لطفا مسیر مقصد را وارد کنید."
				send_stats "移动文件或目录失败: 目标路径未指定"
				continue
			fi

			mv "$src_path" "$dest_path" && echo "فایل یا دایرکتوری به $dest_path منتقل شد" || echo "انتقال فایل یا دایرکتوری انجام نشد"
			send_stats "移动文件或目录"
			;;

		24) # 复制文件目录
			read -e -p "لطفا مسیر فایل یا دایرکتوری را برای کپی وارد کنید:" src_path
			if [ ! -e "$src_path" ]; then
				echo "خطا: فایل یا دایرکتوری وجود ندارد."
				send_stats "复制文件或目录失败: 文件或目录不存在"
				continue
			fi

			read -e -p "لطفاً مسیر مقصد (شامل نام فایل یا دایرکتوری جدید) را وارد کنید:" dest_path
			if [ -z "$dest_path" ]; then
				echo "خطا: لطفا مسیر مقصد را وارد کنید."
				send_stats "复制文件或目录失败: 目标路径未指定"
				continue
			fi

			# 使用 -r 选项以递归方式复制目录
			cp -r "$src_path" "$dest_path" && echo "فایل یا دایرکتوری در $dest_path کپی شد" || echo "فایل یا دایرکتوری کپی نشد"
			send_stats "复制文件或目录"
			;;

		25) # 传送文件至远端服务器
			read -e -p "لطفا مسیر فایل مورد نظر برای انتقال را وارد کنید:" file_to_transfer
			if [ ! -f "$file_to_transfer" ]; then
				echo "خطا: فایل وجود ندارد."
				send_stats "传送文件失败: 文件不存在"
				continue
			fi

			read -e -p "لطفا IP سرور راه دور را وارد کنید:" remote_ip
			if [ -z "$remote_ip" ]; then
				echo "خطا: لطفاً IP سرور راه دور را وارد کنید."
				send_stats "传送文件失败: 未输入远端服务器IP"
				continue
			fi

			read -e -p "لطفاً نام کاربری سرور راه دور (ریشه پیش فرض) را وارد کنید:" remote_user
			remote_user=${remote_user:-root}

			read -e -p "لطفا رمز عبور سرور راه دور را وارد کنید:" -s remote_password
			echo
			if [ -z "$remote_password" ]; then
				echo "خطا: لطفا رمز عبور سرور راه دور را وارد کنید."
				send_stats "传送文件失败: 未输入远端服务器密码"
				continue
			fi

			read -e -p "لطفاً پورت ورود را وارد کنید (پیش‌فرض 22):" remote_port
			remote_port=${remote_port:-22}

			# 清除已知主机的旧条目
			ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			sleep 2 # 等待时间

			# 使用scp传输文件
			scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

			if [ $? -eq 0 ]; then
				echo "فایل به فهرست اصلی سرور راه دور منتقل شده است."
				send_stats "文件传送成功"
			else
				echo "انتقال فایل انجام نشد."
				send_stats "文件传送失败"
			fi

			break_end
			;;

		0) # 返回上一级选单
			send_stats "返回上一级选单菜单"
			break
			;;
		*) # 处理无效输入
			echo "انتخاب نامعتبر است، لطفاً دوباره وارد کنید"
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
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<<"$SERVERS"

	# 遍历服务器并执行命令
	for ((i = 0; i < ${#SERVER_ARRAY[@]}; i += 5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i + 1]}
		local port=${SERVER_ARRAY[i + 2]}
		local username=${SERVER_ARRAY[i + 3]}
		local password=${SERVER_ARRAY[i + 4]}
		echo
		echo -e "${gl_huang} به $name ($hostname) متصل می شود...${gl_bai}"
		# sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
		sshpass -p "$password" ssh -t -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
	done
	echo
	break_end

}

linux_cluster() {
	mkdir cluster
	if [ ! -f ~/cluster/servers.py ]; then
		cat >~/cluster/servers.py <<EOF
servers = [

]
EOF
	fi

	while true; do
		clear
		send_stats "集群控制中心"
		echo "کنترل خوشه سرور"
		cat ~/cluster/servers.py
		echo
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}مدیریت لیست سرور${gl_bai}"
		echo -e "${gl_kjlan}1. ${gl_bai}افزودن سرور ${gl_kjlan}2. ${gl_bai}حذف سرور ${gl_kjlan}3. ${gl_bai}ویرایش سرور"
		echo -e "${gl_kjlan}4. ${gl_bai}خوشه پشتیبان ${gl_kjlan}5. ${gl_bai}بازیابی خوشه"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}کارهای اجرای دسته ای${gl_bai}"
		echo -e "${gl_kjlan}11. ${gl_bai}اسکریپت شیر ​​فناوری ${gl_kjlan}12 را نصب کنید. ${gl_bai}سیستم را به روز کنید ${gl_kjlan}13. ${gl_bai}سیستم را تمیز کنید"
		echo -e "${gl_kjlan}14. ${gl_bai}Docker ${gl_kjlan}15 را نصب کنید. ${gl_bai}BBR3 ${gl_kjlan}16 را نصب کنید. ${gl_bai}تنظیم حافظه مجازی 1G"
		echo -e "${gl_kjlan}17. ${gl_bai}منطقه زمانی را روی شانگهای تنظیم کنید ${gl_kjlan}18. ${gl_bai}همه پورت ها را باز کنید ${gl_kjlan}51. ${gl_bai}فرمان سفارشی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0. ${gl_bai} به منوی اصلی بازگردید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

		case $sub_choice in
		1)
			send_stats "添加集群服务器"
			read -e -p "نام سرور:" server_name
			read -e -p "IP سرور:" server_ip
			read -e -p "پورت سرور (22):" server_port
			local server_port=${server_port:-22}
			read -e -p "نام کاربری سرور (ریشه):" server_username
			local server_username=${server_username:-root}
			read -e -p "رمز عبور کاربر سرور:" server_password

			sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			;;
		2)
			send_stats "删除集群服务器"
			read -e -p "لطفا کلمات کلیدی را که باید حذف شوند را وارد کنید:" rmserver
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
			echo -e "لطفاً فایل ${gl_huang}/root/cluster/servers.py${gl_bai} را برای تکمیل نسخه پشتیبان دانلود کنید!"
			break_end
			;;

		5)
			clear
			send_stats "还原集群"
			echo "لطفا servers.py خود را آپلود کنید و هر کلیدی را فشار دهید تا آپلود شروع شود!"
			echo -e "لطفاً فایل ${gl_huang}servers.py${gl_bai} خود را در ${gl_huang}/root/cluster/${gl_bai} آپلود کنید تا بازیابی کامل شود!"
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
			read -e -p "لطفا دستور اجرای دسته ای را وارد کنید:" mingling
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
	echo "ستون تبلیغاتی"
	echo "------------------------"
	echo "این به کاربران یک تبلیغ و تجربه خرید ساده تر و زیباتر را ارائه می دهد!"
	echo ""
	echo -e "تخفیف سرور"
	echo "------------------------"
	echo -e "${gl_lan} Leica Cloud Hong Kong CN2 GIA ISP دوگانه کره ای آمریکایی CN2 GIA تبلیغات ${gl_bai}"
	echo -e "${gl_bai}وب سایت: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}RackNerd 10.99 دلار در سال ایالات متحده آمریکا 1 هسته 1G حافظه 20G هارد دیسک 1T ترافیک در ماه ${gl_bai}"
	echo -e "آدرس ${gl_bai}: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}Hostinger 52.7 دلار در سال ایالات متحده آمریکا 1 هسته حافظه 4G 50G هارد دیسک 4T ترافیک در ماه ${gl_bai}"
	echo -e "آدرس ${gl_bai}: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207___PROTECT_0"
	echo "------------------------"
	echo -e "${gl_huang} Bricklayer 49 دلار در هر سه ماهه آمریکا CN2GIA ژاپن سافت بانک 2 هسته حافظه 1G 20G هارد دیسک 1T ترافیک در ماه ${gl_bai}"
	echo -e "آدرس ${gl_bai}: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}DMIT 28 دلار در هر سه ماهه ایالات متحده CN2GIA 1 هسته حافظه 2G 20G هارد دیسک 800G ترافیک در ماه${gl_bai}"
	echo -e "آدرس ${gl_bai}: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}V.PS 6.9 دلار در ماه توکیو سافت بانک 2 هسته 1G حافظه 20G هارد دیسک 1T ترافیک در ماه ${gl_bai}"
	echo -e "آدرس ${gl_bai}: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}VPS پیشنهادات محبوب بیشتر${gl_bai}"
	echo -e "آدرس ${gl_bai}: https://kejilion.pro/topvps/${gl_bai}"
	echo "------------------------"
	echo ""
	echo -e "تخفیف نام دامنه"
	echo "------------------------"
	echo -e "${gl_lan}GNAME 8.8 دلار نام دامنه COM سال اول 6.68 دلار نام دامنه CC سال اول ${gl_bai}"
	echo -e "آدرس ${gl_bai}: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
	echo "------------------------"
	echo ""
	echo -e "تجهیزات جانبی شیر فناوری"
	echo "------------------------"
	echo -e "${gl_kjlan}B ایستگاه: ${gl_bai}https://b23.tv/2mqnQyh ${gl_kjlan}Youtube: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
	echo -e "وب سایت رسمی ${gl_kjlan}: ${gl_bai}https://kejilion.pro/ ${gl_kjlan} ناوبری: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
	echo -e "${gl_kjlan} وبلاگ: ${gl_bai}https://blog.kejilion.pro/ ${gl_kjlan}مرکز نرم افزار: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}وب سایت رسمی اسکریپت: ${gl_bai}https://kejilion.sh ${gl_kjlan}آدرس GitHub: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
	echo "------------------------"
	echo ""
}

kejilion_update() {

	send_stats "脚本更新"
	cd ~
	while true; do
		clear
		echo "تغییر گزارش"
		echo "------------------------"
		echo "همه گزارش‌ها: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
		echo "------------------------"

		curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
		local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

		if [ "$sh_v" = "$sh_v_new" ]; then
			echo -e "${gl_lv}شما در حال حاضر در آخرین نسخه هستید! ${gl_huang}v$sh_v${gl_bai}"
			send_stats "脚本已经最新了，无需更新"
		else
			echo "نسخه جدید کشف شد!"
			echo -e "نسخه فعلی v$sh_v آخرین نسخه ${gl_huang}v$sh_v_new${gl_bai}"
		fi

		local cron_job="kejilion.sh"
		local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

		if [ -n "$existing_cron" ]; then
			echo "------------------------"
			echo -e "${gl_lv} به‌روزرسانی خودکار روشن است و اسکریپت هر روز ساعت 2 صبح به‌طور خودکار به‌روزرسانی می‌شود! ${gl_bai}"
		fi

		echo "------------------------"
		echo "1. اکنون به روز رسانی کنید 2. به روز رسانی خودکار را روشن کنید 3. به روز رسانی خودکار را خاموش کنید"
		echo "------------------------"
		echo "0. به منوی اصلی بازگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
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
			cp -f ~/kejilion.sh /usr/local/bin/k >/dev/null 2>&1
			echo -e "اسکریپت ${gl_lv} به آخرین نسخه به روز شده است! ${gl_huang}v$sh_v_new${gl_bai}"
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
			(
				crontab -l 2>/dev/null
				echo "$(shuf -i 0-59 -n 1) 2 * * * bash -c \"$SH_Update_task\""
			) | crontab -
			echo -e "${gl_lv} به‌روزرسانی خودکار روشن است و اسکریپت هر روز ساعت 2 صبح به‌طور خودکار به‌روزرسانی می‌شود! ${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}به‌روزرسانی‌های خودکار خاموش هستند${gl_bai}"
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
		echo -e "جعبه ابزار اسکریپت شیر ​​فناوری v$sh_v"
		echo -e "برای شروع سریع اسکریپت ${gl_bai} ${gl_huang}k${gl_kjlan} را در خط فرمان وارد کنید"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}1. ${gl_bai} درخواست اطلاعات سیستم"
		echo -e "${gl_kjlan}2. ${gl_bai} به روز رسانی سیستم"
		echo -e "${gl_kjlan}3. ${gl_bai}پاکسازی سیستم"
		echo -e "${gl_kjlan}4. ${gl_bai}ابزارهای اساسی"
		echo -e "${gl_kjlan}5. ${gl_bai}BBR مدیریت"
		echo -e "${gl_kjlan}6. ${gl_bai}مدیریت داکر"
		echo -e "${gl_kjlan}7. ${gl_bai}WARP مدیریت"
		echo -e "${gl_kjlan}8. ${gl_bai} مجموعه اسکریپت آزمایشی"
		echo -e "${gl_kjlan}9. ${gl_bai}Oracle Cloud Script Collection"
		echo -e "${gl_huang}10. ${gl_bai}ساخت وب سایت LDNMP"
		echo -e "${gl_kjlan}11. ${gl_bai} Application Market"
		echo -e "${gl_kjlan}12. ${gl_bai}فضای کاری Backend"
		echo -e "${gl_kjlan}13. ${gl_bai} ابزارهای سیستم"
		echo -e "${gl_kjlan}14. ${gl_bai} کنترل خوشه سرور"
		echo -e "${gl_kjlan}15. ${gl_bai}ستون تبلیغاتی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}p. ${gl_bai}اسکریپت باز کردن سرور Eudemons Parlu"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}00. به روز رسانی اسکریپت ${gl_bai}"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0. ${gl_bai}خروج از اسکریپت"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice

		case $choice in
		1) linux_info ;;
		2)
			clear
			send_stats "系统更新"
			linux_update
			;;
		3)
			clear
			send_stats "系统清理"
			linux_clean
			;;
		4) linux_tools ;;
		5) linux_bbr ;;
		6) linux_docker ;;
		7)
			clear
			send_stats "warp管理"
			install wget
			wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
			bash menu.sh [option] [lisence/url/token]
			;;
		8) linux_test ;;
		9) linux_Oracle ;;
		10) linux_ldnmp ;;
		11) linux_panel ;;
		12) linux_work ;;
		13) linux_Settings ;;
		14) linux_cluster ;;
		15) kejilion_Affiliates ;;
		p)
			send_stats "幻兽帕鲁开服脚本"
			cd ~
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh
			chmod +x palworld.sh
			./palworld.sh
			exit
			;;
		00) kejilion_update ;;
		0)
			clear
			exit
			;;
		*) echo "ورودی نامعتبر است!" ;;
		esac
		break_end
	done
}

k_info() {
	send_stats "k命令参考用例"
	echo "-------------------"
	echo "معرفی ویدیو: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
	echo "مورد زیر یک مورد استفاده مرجع برای دستور k است:"
	echo "شروع اسکریپت k"
	echo "نصب بسته ها k install nano wget | k افزودن نانو wget | k نانو wget را نصب کنید"
	echo "حذف یک بسته k remove nano wget | k del nano wget | k uninstall nano wget | nano wget را حذف نصب کنید"
	echo "به روز رسانی سیستم k به روز رسانی | k به روز رسانی"
	echo "Clean system junk k clean | k تمیز"
	echo "دوباره پانل سیستم را نصب کنید k dd | k دوباره نصب کنید"
	echo "کنترل پنل bbr3 k bbr3 | k bbrv3"
	echo "پنل تنظیم هسته k nhyh | k بهینه سازی هسته"
	echo "تنظیم حافظه مجازی k swap 2048"
	echo "تنظیم منطقه زمانی مجازی k زمان آسیا/شانگهای | k منطقه زمانی آسیا/شانگهای"
	echo "سطل بازیافت سیستم k trash | k hsz | k سطل بازیافت"
	echo "تابع پشتیبان گیری سیستم k پشتیبان | k bf | k پشتیبان گیری"
	echo "ابزار اتصال از راه دور ssh k ssh | k اتصال از راه دور"
	echo "ابزار همگام سازی از راه دور rsync k rsync | k همگام سازی از راه دور"
	echo "ابزار مدیریت هارد دیسک k disk | k مدیریت هارد دیسک"
	echo "نفوذ اینترانت (سرور) k fps"
	echo "نفوذ اینترانت (کلاینت) k frpc"
	echo "راه اندازی نرم افزار k start sshd | k sshd را شروع کنید"
	echo "نرم افزار stop k stop sshd | k stop sshd"
	echo "راه اندازی مجدد نرم افزار k restart sshd | k sshd را ریستارت کنید"
	echo "بررسی وضعیت نرم افزار k status sshd | k وضعیت sshd"
	echo "k فعال کردن داکر | k autostart docker | k هنگام بوت کردن نرم افزار داکر را فعال کنید"
	echo "درخواست گواهینامه نام دامنه k ssl"
	echo "پرس و جو انقضای گواهی نام دامنه k ssl ps"
	echo "هواپیمای مدیریت بارانداز k docker"
	echo "نصب محیط docker k docker install |k docker install"
	echo "مدیریت کانتینر docker k docker ps |k docker container"
	echo "مدیریت تصویر docker k docker img |k docker image"
	echo "مدیریت سایت LDNMP k وب"
	echo "پاکسازی کش LDNMP k cache وب"
	echo "نصب وردپرس k wp | k وردپرس | k wp xxx.com"
	echo "نصب پراکسی معکوس k fd |k rp |k پراکسی معکوس |k fd xxx.com"
	echo "نصب بار بالانس k loadbalance |k load balancing"
	echo "L4 load balancing k stream |k L4 load balancing را نصب کنید"
	echo "فایروال پنل k fhq |k فایروال"
	echo "پورت باز k dkdk 8080 |k پورت باز 8080"
	echo "بستن پورت k gbdk 7800 |k بستن پورت 7800"
	echo "انتشار IP k fxip 127.0.0.0/8 |k انتشار IP 127.0.0.0/8"
	echo "Block IP k zzip 177.5.25.36 |k Block IP 177.5.25.36"
	echo "دستور موارد دلخواه k fav | دستور k مورد علاقه"
	echo "برنامه مدیریت بازار برنامه k"
	echo "مدیریت سریع شماره برنامه k app 26 | برنامه k 1panel | k برنامه npm"
	echo "نمایش اطلاعات سیستم k اطلاعات"
}

if [ "$#" -eq 0 ]; then
	# 如果没有参数，运行交互式逻辑
	kejilion_sh
else
	# 如果有参数，执行相应函数
	case $1 in
	install | add | 安装)
		shift
		send_stats "安装软件"
		install "$@"
		;;
	remove | del | uninstall | 卸载)
		shift
		send_stats "卸载软件"
		remove "$@"
		;;
	update | 更新)
		linux_update
		;;
	clean | 清理)
		linux_clean
		;;
	dd | 重装)
		dd_xitong
		;;
	bbr3 | bbrv3)
		bbrv3
		;;
	nhyh | 内核优化)
		Kernel_optimize
		;;
	trash | hsz | 回收站)
		linux_trash
		;;
	backup | bf | 备份)
		linux_backup
		;;
	ssh | 远程连接)
		ssh_manager
		;;

	rsync | 远程同步)
		rsync_manager
		;;

	rsync_run)
		shift
		send_stats "定时rsync同步"
		run_task "$@"
		;;

	disk | 硬盘管理)
		disk_manager
		;;

	wp | wordpress)
		shift
		ldnmp_wp "$@"

		;;
	fd | rp | 反代)
		shift
		ldnmp_Proxy "$@"
		find_container_by_host_port "$port"
		if [ -z "$docker_name" ]; then
			close_port "$port"
			echo "IP+پورت دسترسی به سرویس مسدود شده است"
		else
			ip_address
			block_container_port "$docker_name" "$ipv4_address"
		fi
		;;

	loadbalance | 负载均衡)
		ldnmp_Proxy_backend
		;;

	stream | L4负载均衡)
		ldnmp_Proxy_backend_stream
		;;

	swap)
		shift
		send_stats "快速设置虚拟内存"
		add_swap "$@"
		;;

	time | 时区)
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

	打开端口 | dkdk)
		shift
		open_port "$@"
		;;

	关闭端口 | gbdk)
		shift
		close_port "$@"
		;;

	放行IP | fxip)
		shift
		allow_ip "$@"
		;;

	阻止IP | zzip)
		shift
		block_ip "$@"
		;;

	防火墙 | fhq)
		iptables_panel
		;;

	命令收藏夹 | fav)
		linux_fav
		;;

	status | 状态)
		shift
		send_stats "软件状态查看"
		status "$@"
		;;
	start | 启动)
		shift
		send_stats "软件启动"
		start "$@"
		;;
	stop | 停止)
		shift
		send_stats "软件暂停"
		stop "$@"
		;;
	restart | 重启)
		shift
		send_stats "软件重启"
		restart "$@"
		;;

	enable | autostart | 开机启动)
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
		install | 安装)
			send_stats "快捷安装docker"
			install_docker
			;;
		ps | 容器)
			send_stats "快捷容器管理"
			docker_ps
			;;
		img | 镜像)
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

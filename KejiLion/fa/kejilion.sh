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
	echo -e "${gl_kjlan}به KejiLion Script Toolbox خوش آمدید${gl_bai}"
	echo "برای اولین بار از اسکریپت استفاده می‌کنید، لطفاً ابتدا توافقنامه مجوز کاربر را بخوانید و با آن موافقت کنید."
	echo "توافقنامه مجوز کاربر: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "آیا با شرایط فوق موافق هستید؟ \(y/N\): " user_input

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
		echo "پارامتر بسته ارائه نشده است!"
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
				echo "مدیر بسته ناشناخته!"
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
		echo -e "${gl_huang}هشدار: ${gl_bai}فضای دیسک کافی نیست! "
		echo "فضای موجود: $((available_space_mb / 1024))G"
		echo "فضای مورد نیاز حداقل: ${required_gb}G"
		echo "نمی‌توان نصب را ادامه داد، لطفاً پس از پاک کردن فضای دیسک دوباره تلاش کنید."
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
		echo "پارامتر بسته ارائه نشده است!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}در حال حذف نصب $package...${gl_bai}"
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
			echo "مدیر بسته ناشناخته!"
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
		echo "$1 سرویس راه‌اندازی مجدد شد."
	else
		echo "خطا: راه‌اندازی مجدد $1 سرویس با شکست مواجه شد."
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1 سرویس شروع شد."
	else
		echo "خطا: شروع سرویس $1 با شکست مواجه شد."
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1 سرویس متوقف شد."
	else
		echo "خطا: توقف سرویس $1 با شکست مواجه شد."
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1 وضعیت سرویس نمایش داده شد."
	else
		echo "خطا: امکان نمایش وضعیت سرویس $1 وجود ندارد."
	fi
}

enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
		/bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME برای شروع خودکار تنظیم شد."
}

break_end() {
	echo -e "${gl_lv}عملیات تکمیل شد${gl_bai}"
	echo "برای ادامه، هر کلیدی را فشار دهید..."
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
	echo -e "${gl_huang}در حال نصب محیط Docker...${gl_bai}"
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
		echo "لیست کانتینرهای Docker"
		docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
		echo ""
		echo "عملیات کانتینر"
		echo "------------------------"
		echo "1. ایجاد کانتینر جدید"
		echo "------------------------"
		echo "2. شروع کانتینر مشخص شده             6. شروع همه کانتینرها"
		echo "3. توقف کانتینر مشخص شده             7. توقف همه کانتینرها"
		echo "4. حذف کانتینر مشخص شده             8. حذف همه کانتینرها"
		echo "5. راه اندازی مجدد کانتینر مشخص شده         9. راه اندازی مجدد همه کانتینرها"
		echo "------------------------"
		echo "11. ورود به کانتینر مشخص شده             12. مشاهده لاگ کانتینر"
		echo "13. مشاهده شبکه کانتینر             14. مشاهده مصرف کانتینر"
		echo "------------------------"
		echo "15. فعال کردن دسترسی به پورت کانتینر       16. غیرفعال کردن دسترسی به پورت کانتینر"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "لطفاً دستور ایجاد را وارد کنید: " dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			read -e -p "لطفاً نام کانتینر(ها) را وارد کنید (برای چند کانتینر، نام‌ها را با فاصله از هم جدا کنید): " dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "لطفاً نام کانتینر(ها) را وارد کنید (برای چند کانتینر، نام‌ها را با فاصله از هم جدا کنید): " dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			read -e -p "لطفاً نام کانتینر(ها) را وارد کنید (برای چند کانتینر، نام‌ها را با فاصله از هم جدا کنید): " dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			read -e -p "لطفاً نام کانتینر(ها) را وارد کنید (برای چند کانتینر، نام‌ها را با فاصله از هم جدا کنید): " dockername
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
			read -e -p "$(echo -e "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می‌خواهید همه کانتینرها را حذف کنید؟ \(y/N\): ")" choice
			case "$choice" in
			[Yy])
				docker rm -f $(docker ps -a -q)
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			read -e -p "لطفاً نام کانتینر را وارد کنید: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			read -e -p "لطفاً نام کانتینر را وارد کنید: " dockername
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
			read -e -p "لطفاً نام کانتینر را وارد کنید: " docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "阻止容器端口访问"
			read -e -p "لطفاً نام کانتینر را وارد کنید: " docker_name
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
		echo "لیست ایمیج‌های Docker"
		docker image ls
		echo ""
		echo "عملیات آینه"
		echo "------------------------"
		echo "1. دریافت تصویر مشخص شده             2. به‌روزرسانی تصویر مشخص شده"
		echo "3. حذف تصویر مشخص شده             4. حذف همه تصاویر"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			send_stats "拉取镜像"
			read -e -p "لطفاً نام ایمیج(ها) را وارد کنید (برای چند ایمیج، نام‌ها را با فاصله از هم جدا کنید): " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}در حال دریافت تصویر: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			read -e -p "لطفاً نام ایمیج(ها) را وارد کنید (برای چند ایمیج، نام‌ها را با فاصله از هم جدا کنید): " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}در حال به‌روزرسانی تصویر: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			read -e -p "لطفاً نام ایمیج(ها) را وارد کنید (برای چند ایمیج، نام‌ها را با فاصله از هم جدا کنید): " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			read -e -p "$(echo -e "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می‌خواهید همه تصاویر را حذف کنید؟ \(y/N\): ")" choice
			case "$choice" in
			[Yy])
				docker rmi -f $(docker images -q)
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
			echo "نسخه پشتیبانی نمی‌شود: $ID"
			return
			;;
		esac
	else
		echo "تعیین سیستم عامل امکان پذیر نیست."
		return
	fi

	echo -e "${gl_lv}crontab نصب شده و سرویس cron در حال اجرا است.${gl_bai}"
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
			echo -e "${gl_huang}دسترسی IPv6 در حال حاضر فعال است${gl_bai}"
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
		echo -e "${gl_hong}فایل پیکربندی وجود ندارد${gl_bai}"
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
		echo -e "${gl_huang}دسترسی IPv6 در حال حاضر غیرفعال است${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}دسترسی IPv6 با موفقیت غیرفعال شد${gl_bai}"
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
		echo "لطفاً حداقل یک شماره پورت ارائه دهید"
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
		echo "لطفاً حداقل یک شماره پورت ارائه دهید"
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
			echo "پورت $port بسته شد"
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
		echo "لطفاً حداقل یک آدرس IP یا محدوده IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP $ip مجاز شد"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@) # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک آدرس IP یا محدوده IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP $ip مسدود شد"
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
				echo "خطا: دانلود فایل منطقه IP برای $country_code با شکست مواجه شد"
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
				echo "خطا: دانلود فایل منطقه IP برای $country_code با شکست مواجه شد"
				continue
			fi

			ipset flush "$ipset_name"
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip" 2>/dev/null
			done <"${country_code,,}.zone"

			iptables -P INPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

			echo "آدرس IP $country_code با موفقیت مجاز شد"
			rm "${country_code,,}.zone"
			;;

		unblock)
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

			if ipset list "$ipset_name" &>/dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "محدودیت آدرس IP $country_code با موفقیت برداشته شد"
			;;

		*)
			echo "استفاده: manage_country_rules {block|allow|unblock} <country_code...>"
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
		echo "مدیریت پیشرفته فایروال"
		send_stats "高级防火墙管理"
		echo "------------------------"
		iptables -L INPUT
		echo ""
		echo "مدیریت فایروال"
		echo "------------------------"
		echo "1. باز کردن پورت مشخص شده                2. بستن پورت مشخص شده"
		echo "3. باز کردن همه پورت‌ها                4. بستن همه پورت‌ها"
		echo "------------------------"
		echo "5. لیست سفید IP                     6. لیست سیاه IP"
		echo "7. پاک کردن IP مشخص"
		echo "------------------------"
		echo "11. اجازه دادن به PING                     12. ممنوع کردن PING"
		echo "------------------------"
		echo "13. فعال کردن دفاع DDOS                14. غیرفعال کردن دفاع DDOS"
		echo "------------------------"
		echo "15. مسدود کردن IP کشور مشخص               16. اجازه دادن فقط به IP کشور مشخص"
		echo "17. رفع محدودیت IP کشور مشخص"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			read -e -p "لطفاً شماره پورت باز را وارد کنید: " o_port
			open_port $o_port
			send_stats "开放指定端口"
			;;
		2)
			read -e -p "لطفاً شماره پورت بسته را وارد کنید: " c_port
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
			read -e -p "لطفاً IP یا محدوده IP مجاز را وارد کنید: " o_ip
			allow_ip $o_ip
			;;
		6)
			# IP 黑名单
			read -e -p "لطفاً IP یا محدوده IP مسدود شده را وارد کنید: " c_ip
			block_ip $c_ip
			;;
		7)
			# 清除指定 IP
			read -e -p "لطفاً IP برای پاک کردن را وارد کنید: " d_ip
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
			read -e -p "لطفاً کد کشور(های) مسدود شده را وارد کنید (برای چند کشور، کدها را با فاصله از هم جدا کنید مانند CN US JP): " country_code
			manage_country_rules block $country_code
			send_stats "允许国家 $country_code 的IP"
			;;
		16)
			read -e -p "لطفاً کد کشور(های) مجاز را وارد کنید (برای چند کشور، کدها را با فاصله از هم جدا کنید مانند CN US JP): " country_code
			manage_country_rules allow $country_code
			send_stats "阻止国家 $country_code 的IP"
			;;

		17)
			read -e -p "لطفاً کد کشور(های) برای پاک کردن را وارد کنید (برای چند کشور، کدها را با فاصله از هم جدا کنید مانند CN US JP): " country_code
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

	echo -e "اندازه حافظه مجازی به ${gl_huang}${new_swap}${gl_bai}M تنظیم شد"
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
	grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null ||
		echo 'precedence ::ffff:0:0/96  100' >>/etc/gai.conf
	echo "به IPv4 اولویت داده شد"
	send_stats "已切换为 IPv4 优先"
}

install_ldnmp() {

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
	echo "نصب محیط LDNMP به پایان رسید"
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
	echo "وظیفه تمدید به‌روزرسانی شد"
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
	echo -e "${gl_huang}اطلاعات کلید عمومی $yuming${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}اطلاعات کلید خصوصی $yuming${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}مسیر ذخیره گواهی${gl_bai}"
	echo "کلید عمومی: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "کلید خصوصی: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}

add_ssl() {
	echo -e "${gl_huang}درخواست سریع گواهی SSL، تمدید خودکار قبل از انقضا${gl_bai}"
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
	echo -e "${gl_huang}وضع انقضای گواهی‌های اعمال شده${gl_bai}"
	echo "اطلاعات سایت زمان انقضای گواهی"
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
		echo -e "${gl_hong}توجه: ${gl_bai}درخواست گواهی ناموفق بود، لطفاً دلایل احتمالی زیر را بررسی کرده و دوباره تلاش کنید:"
		echo -e "1. غلط املایی دامنه ➠ لطفاً بررسی کنید که آیا ورودی دامنه صحیح است یا خیر"
		echo -e "2. مشکل در حل DNS ➠ تأیید کنید که دامنه به درستی به آدرس IP این سرور تجزیه شده است"
		echo -e "3. مشکل پیکربندی شبکه ➠ اگر از شبکه مجازی مانند Cloudflare Warp استفاده می‌کنید، لطفاً آن را به طور موقت غیرفعال کنید"
		echo -e "4. محدودیت فایروال ➠ بررسی کنید که آیا پورت‌های 80/443 باز هستند و اطمینان حاصل کنید که تأیید قابل دسترسی است"
		echo -e "5. تعداد درخواست‌ها بیش از حد مجاز است ➠ Let's Encrypt محدودیت هفتگی دارد (5 بار در هفته/دامنه)"
		echo -e "6. محدودیت ثبت دامنه در چین ➠ در محیط سرزمین اصلی چین، لطفاً تأیید کنید که آیا دامنه ثبت شده است یا خیر"
		break_end
		clear
		echo "لطفاً دوباره استقرار $webname را امتحان کنید"
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
	echo -e "ابتدا دامنه را به آدرس IP محلی تجزیه کنید: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	read -e -p "لطفاً IP یا دامنه خود را وارد کنید: " yuming
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
	echo "به‌روزرسانی${ldnmp_pods} تکمیل شد"

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
	echo "رمز عبور: $dbusepasswd"
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
		read -e -p "آیا می‌خواهید کش Cloudflare را پاک کنید؟ (y/N): " answer
		if [[ "$answer" == "y" ]]; then
			echo "اطلاعات Cloudflare در $CONFIG_FILE ذخیره شده است و می توانید بعداً اطلاعات Cloudflare را تغییر دهید"
			read -e -p "لطفاً API_TOKEN خود را وارد کنید: " API_TOKEN
			read -e -p "لطفاً نام کاربری Cloudflare خود را وارد کنید: " EMAIL
			read -e -p "لطفاً zone_id(ها) را وارد کنید (برای چند zone، IDها را با فاصله از هم جدا کنید): " -a ZONE_IDS

			mkdir -p /home/web/config/
			echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" >"$CONFIG_FILE"
		fi
	fi

	# 循环遍历每个 zone_id 并执行清除缓存命令
	for ZONE_ID in "${ZONE_IDS[@]}"; do
		echo "در حال پاک کردن کش برای شناسه منطقه: $ZONE_ID"
		curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
			-H "X-Auth-Email: $EMAIL" \
			-H "X-Auth-Key: $API_TOKEN" \
			-H "Content-Type: application/json" \
			--data '{"purge_everything":true}'
	done

	echo "درخواست پاک کردن کش ارسال شد."
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
		read -e -p "برای حذف داده‌های سایت، دامنه(های) خود را وارد کنید (برای چند دامنه، نام‌ها را با فاصله از هم جدا کنید): " yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "در حال حذف دامنه: $yuming"
		rm -r /home/web/html/$yuming >/dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "در حال حذف پایگاه داده: $dbname"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
		echo "1. نصب محافظ"
		echo "------------------------"
		echo "5. مشاهده سوابق رهگیری SSH              6. مشاهده سوابق رهگیری وب‌سایت"
		echo "7. مشاهده لیست قوانین محافظ               8. مشاهده نظارت زنده بر لاگ‌ها"
		echo "------------------------"
		echo "11. تنظیم پارامترهای رهگیری                   12. پاک کردن تمام IP های مسدود شده"
		echo "------------------------"
		echo "21. حالت Cloudflare                22. فعال کردن سپر 5 ثانیه‌ای در بار بالا"
		echo "------------------------"
		echo "31. فعال کردن WAF                       32. غیرفعال کردن WAF"
		echo "33. فعال کردن محافظت DDOS                 34. غیرفعال کردن محافظت DDOS"
		echo "------------------------"
		echo "9. حذف محافظ"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
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
			echo "محافظ Fail2ban حذف شد"
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
			echo "به پنل پشتی Cloudflare، گوشه بالا سمت راست، پروفایل من بروید، API Token را از سمت چپ انتخاب کنید و Global API Key را دریافت کنید"
			echo "https://dash.cloudflare.com/login"
			read -e -p "حساب Cloudflare را وارد کنید: " cfuser
			read -e -p "کلید Global API Cloudflare را وارد کنید: " cftoken

			wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
			docker exec nginx nginx -s reload

			cd /etc/fail2ban/jail.d/
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

			cd /etc/fail2ban/action.d
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

			sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
			sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
			f2b_status

			echo "حالت Cloudflare تنظیم شد، می‌توانید سوابق رهگیری را در Cloudflare، سایت-امنیت-رویدادها مشاهده کنید"
			;;

		22)
			send_stats "高负载开启5秒盾"
			echo -e "${gl_huang}وب سایت به طور خودکار هر 5 دقیقه بررسی می شود، هنگامی که بار بالا تشخیص داده شود، سپر به طور خودکار فعال می شود و سپر با بار کم نیز به طور خودکار پس از 5 ثانیه غیرفعال می شود.${gl_bai}"
			echo "--------------"
			echo "دریافت پارامترهای Cloudflare:"
			echo -e "به صفحه پشتیبان Cloudflare، گوشه بالا سمت راست، اطلاعات شخصی من بروید، توکن API را در سمت چپ انتخاب کنید تا ${gl_huang}کلید API سراسری${gl_bai} را دریافت کنید"
			echo -e "به صفحه نمای کلی دامنه در داشبورد Cloudflare، گوشه پایین سمت راست بروید تا ${gl_huang}شناسه منطقه${gl_bai} را دریافت کنید"
			echo "https://dash.cloudflare.com/login"
			echo "--------------"
			read -e -p "حساب Cloudflare را وارد کنید: " cfuser
			read -e -p "کلید Global API Cloudflare را وارد کنید: " cftoken
			read -e -p "شناسه منطقه دامنه در Cloudflare را وارد کنید: " cfzonID

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
				echo "اسکریپت فعال‌سازی خودکار سپر در بار بالا اضافه شد"
			else
				echo "اسکریپت فعال‌سازی خودکار سپر از قبل وجود دارد، نیازی به اضافه کردن نیست"
			fi

			;;

		31)
			nginx_waf on
			echo "WAF سایت فعال شد"
			send_stats "站点WAF已开启"
			;;

		32)
			nginx_waf off
			echo "WAF سایت غیرفعال شد"
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
		echo -e "بهینه سازی محیط LDNMP ${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
		echo "------------------------"
		echo "1. حالت استاندارد              2. حالت با کارایی بالا (توصیه شده 2H4G یا بیشتر)"
		echo "------------------------"
		echo "3. فعال کردن فشرده‌سازی gzip        4. غیرفعال کردن فشرده‌سازی gzip"
		echo "5. فعال کردن فشرده‌سازی br          6. غیرفعال کردن فشرده‌سازی br"
		echo "7. فعال کردن فشرده‌سازی zstd        8. غیرفعال کردن فشرده‌سازی zstd"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
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

			echo "محیط LDNMP در حالت استاندارد تنظیم شده است"

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

			echo "محیط LDNMP در حالت با کارایی بالا تنظیم شده است"

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
	echo "آدرس دسترسی: "
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

	echo "دسترسی IP+پورت به این سرویس مسدود شد"
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

	echo "دسترسی IP+پورت به این سرویس مجاز است"
	save_iptables_rules
}

block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "خطا: لطفاً شماره پورت و IP مجاز را ارائه دهید."
		echo "نحوه استفاده: block_host_port <شماره پورت> <IP مجاز>"
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

	echo "دسترسی IP+پورت به این سرویس مسدود شد"
	save_iptables_rules
}

clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "خطا: لطفاً شماره پورت و IP مجاز را ارائه دهید."
		echo "نحوه استفاده: clear_host_port_rules <شماره پورت> <IP مجاز>"
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

	echo "دسترسی IP+پورت به این سرویس مجاز است"
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
		echo "1. نصب                  2. به‌روزرسانی                  3. حذف"
		echo "------------------------"
		echo "5. افزودن دسترسی نام دامنه      6. حذف دسترسی نام دامنه"
		echo "7. اجازه دسترسی IP+پورت   8. مسدود کردن دسترسی IP+پورت"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "پورت سرویس خارجی برنامه را وارد کنید، Enter از پورت پیش‌فرض ${docker_port} استفاده می‌کند: " app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_name با موفقیت نصب شد"
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
			echo "$docker_name با موفقیت نصب شد"
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
			echo "برنامه حذف شد"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "تنظیمات دسترسی نام دامنه ${docker_name}"
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
		echo "1. نصب                  2. به‌روزرسانی                  3. حذف"
		echo "------------------------"
		echo "5. افزودن دسترسی نام دامنه      6. حذف دسترسی نام دامنه"
		echo "7. اجازه دسترسی IP+پورت   8. مسدود کردن دسترسی IP+پورت"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "پورت سرویس خارجی برنامه را وارد کنید، Enter از پورت پیش‌فرض ${docker_port} استفاده می‌کند: " app_port
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
			echo "تنظیمات دسترسی نام دامنه ${docker_name}"
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

	read -e -p "$(echo -e "${gl_huang}نکته: ${gl_bai}آیا اکنون سرور را مجدداً راه اندازی کنید؟ \(y/N\): ")" rboot
	case "$rboot" in
	[Yy])
		echo "راه‌اندازی مجدد شد"
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
		echo -e "${gl_huang}نکته: ${gl_bai}محیط ساخت وب سایت نصب شده است. نیازی به نصب مجدد نیست!"
		break_end
		linux_ldnmp
	fi

}

ldnmp_install_all() {
	cd ~
	send_stats "安装LDNMP环境"
	root_use
	clear
	echo -e "${gl_huang}محیط LDNMP نصب نشده است، شروع به نصب محیط LDNMP ...${gl_bai}"
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
	echo -e "${gl_huang}Nginx نصب نشده است، شروع به نصب محیط Nginx ...${gl_bai}"
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
	echo "Nginx با موفقیت نصب شد"
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
	echo "وب‌سایت $webname شما راه‌اندازی شد!"
	echo "https://$yuming"
	echo "------------------------"
	echo "اطلاعات نصب $webname به شرح زیر است:"

}

nginx_web_on() {
	clear
	echo "وب‌سایت $webname شما راه‌اندازی شد!"
	echo "https://$yuming"

}

ldnmp_wp() {
	clear
	# wordpress
	webname="WordPress"
	yuming="${1:-}"
	send_stats "安装$webname"
	echo "شروع استقرار $webname"
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
	echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379'); define('WP_REDIS_MAXTTL', 86400); define('WP_CACHE_KEY_SALT', '${yuming}_');" >>/home/web/html/$yuming/wordpress/wp-config-sample.php
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
	webname="پروکسی معکوس - IP + پورت"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "شروع استقرار $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "لطفاً IP پروکسی خود را وارد کنید: " reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "لطفاً پورت پروکسی خود را وارد کنید: " port
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
	webname="پروکسی معکوس - متعادل کننده بار"

	send_stats "安装$webname"
	echo "شروع استقرار $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "لطفاً IP+پورت پروکسی‌های متعدد خود را با فاصله وارد کنید (مثلاً 127.0.0.1:3000 127.0.0.1:3002): " reverseproxy_port
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
		echo -e "ابزار ارسال پروکسی لایه چهارم Stream $check_docker $update_status"
		echo "Nginx Stream یک ماژول پروکسی TCP/UDP برای Nginx است که برای دستیابی به انتقال و متعادل‌سازی بار ترافیک لایه انتقال با کارایی بالا استفاده می‌شود."
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب                  2. به‌روزرسانی                  3. حذف"
		echo "------------------------"
		echo "4. اضافه کردن سرویس فوروارد          5. ویرایش سرویس فوروارد          6. حذف سرویس فوروارد"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید: " choice
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
			read -e -p "آیا مطمئن هستید که می‌خواهید کانتینر Nginx را حذف کنید؟ این ممکن است بر عملکرد وب‌سایت تأثیر بگذارد! \(y/N\): " confirm
			if [[ "$confirm" =~ ^[Yy]$ ]]; then
				docker rm -f nginx
				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				send_stats "更新Stream四层代理"
				echo "کانتینر Nginx حذف شد."
			else
				echo "عملیات لغو شد."
			fi

			;;

		4)
			ldnmp_Proxy_backend_stream
			add_app_id
			send_stats "添加四层代理"
			;;
		5)
			send_stats "编辑转发配置"
			read -e -p "لطفاً نام سرویسی را که می‌خواهید ویرایش کنید وارد کنید: " stream_name
			install nano
			nano /home/web/stream.d/$stream_name.conf
			docker restart nginx
			send_stats "修改四层代理"
			;;
		6)
			send_stats "删除转发配置"
			read -e -p "لطفاً نام سرویسی را که می‌خواهید حذف کنید وارد کنید: " stream_name
			rm /home/web/stream.d/$stream_name.conf >/dev/null 2>&1
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
	webname="پروکسی لایه چهارم Stream - متعادل کننده بار"

	send_stats "安装$webname"
	echo "شروع استقرار $webname"

	# 获取代理名称
	read -rp "لطفاً نام فوروارد پروکسی را وارد کنید (مثلاً mysql_proxy): " proxy_name
	if [ -z "$proxy_name" ]; then
		echo "نام نمی‌تواند خالی باشد"
		return 1
	fi

	# 获取监听端口
	read -rp "لطفاً پورت گوش دادن محلی را وارد کنید (مثلاً 3306): " listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "پورت باید یک عدد باشد"
		return 1
	fi

	echo "لطفا نوع پروتکل را انتخاب کنید:"
	echo "1. TCP    2. UDP"
	read -rp "لطفاً شماره سریال را وارد کنید [1-2]: " proto_choice

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
		echo "انتخاب نامعتبر"
		return 1
		;;
	esac

	read -e -p "لطفاً یک یا چند IP+پورت بک‌اند را با فاصله وارد کنید (مثلاً 10.13.0.2:3306 10.13.0.3:3306): " reverseproxy_port

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
	echo "وب‌سایت $webname شما راه‌اندازی شد!"
	echo "------------------------"
	echo "آدرس دسترسی: "
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

		echo -e "وب‌سایت: ${output}                      زمان انقضای گواهی‌نامه"
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
		echo -e "داده‌ها ${gl_hui}/home/web/html${gl_bai}     گواهی‌نامه ${gl_hui}/home/web/certs${gl_bai}     پیکربندی ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "عملیات"
		echo "------------------------"
		echo "1. درخواست/به‌روزرسانی گواهی دامنه              2. کپی کردن دامنه سایت"
		echo "3. پاک کردن کش سایت                   4. ایجاد سایت مرتبط"
		echo "5. مشاهده سوابق دسترسی                   6. مشاهده گزارش خطا"
		echo "7. ویرایش تنظیمات سراسری                   8. ویرایش تنظیمات سایت"
		echo "9. مدیریت پایگاه داده سایت                 10. مشاهده گزارش تجزیه و تحلیل سایت"
		echo "------------------------"
		echo "20. حذف داده‌های ایستگاه مشخص‌شده"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			send_stats "申请域名证书"
			read -e -p "لطفاً دامنه خود را وارد کنید: " yuming
			install_certbot
			docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
			install_ssltls
			certs_status

			;;

		2)
			send_stats "克隆站点域名"
			read -e -p "لطفاً دامنه قدیمی را وارد کنید: " oddyuming
			read -e -p "لطفاً دامنه جدید را وارد کنید: " yuming
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
			echo -e "برای وب‌سایت‌های موجود، یک دامنه جدید را برای دسترسی مرتبط کنید"
			read -e -p "لطفاً دامنه موجود را وارد کنید: " oddyuming
			read -e -p "لطفاً دامنه جدید را وارد کنید: " yuming
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
			read -e -p "ویرایش پیکربندی سایت، لطفاً دامنه ای را که می خواهید ویرایش کنید وارد کنید: " yuming
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
		echo "${panelname} یک پنل مدیریت عملیات و نگهداری قدرتمند و محبوب است."
		echo "معرفی وب‌سایت رسمی: $panelurl"

		echo ""
		echo "------------------------"
		echo "1. نصب 2. مدیریت 3. حذف"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice
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
	echo "پارامترهای مورد نیاز هنگام استقرار کلاینت"
	echo "آدرس IP سرویس: $ipv4_address"
	echo "token: $token"
	echo
	echo "اطلاعات پنل FRP"
	echo "آدرس پنل FRP: http://$ipv4_address:$dashboard_port"
	echo "نام کاربری پنل FRP: $dashboard_user"
	echo "گذرواژه پنل FRP: $dashboard_pwd"
	echo

	open_port 8055 8056

}

configure_frpc() {
	send_stats "安装frp客户端"
	read -e -p "لطفاً IP اتصال خارجی را وارد کنید: " server_addr
	read -e -p "لطفاً توکن اتصال خارجی را وارد کنید: " token
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
	read -e -p "لطفاً نام سرویس را وارد کنید: " service_name
	read -e -p "نوع فوروارد (tcp/udp) [پیش‌فرض tcp] را وارد کنید: " service_type
	local service_type=${service_type:-tcp}
	read -e -p "لطفاً IP شبکه داخلی را وارد کنید [پیش‌فرض 127.0.0.1]: " local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "لطفاً شماره پورت شبکه داخلی را وارد کنید: " local_port
	read -e -p "لطفاً شماره پورت شبکه خارجی را وارد کنید: " remote_port

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
	read -e -p "لطفاً نام سرویسی که می‌خواهید حذف کنید را وارد کنید: " service_name
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
		echo "ایجاد محیط سرویس تونل‌زنی داخلی FRP، برای افشای دستگاه‌های بدون IP عمومی به اینترنت"
		echo "معرفی وب‌سایت رسمی: https://github.com/fatedier/frp/"
		echo "آموزش ویدئویی: https://youtu.be/Z3Z4OoaV2cw?t=124"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب                  2. به‌روزرسانی                  3. حذف"
		echo "------------------------"
		echo "5. دسترسی به دامنه‌های سرویس داخلی 6. حذف دسترسی به دامنه‌ها"
		echo "------------------------"
		echo "7. اجازه دسترسی IP+پورت 8. مسدود کردن دسترسی IP+پورت"
		echo "------------------------"
		echo "00. تازه‌سازی وضعیت سرویس 0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			generate_frps_config

			add_app_id
			echo "نصب سمت سرور FRP به پایان رسید"
			;;
		2)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
			donlond_frp frps

			add_app_id
			echo "سرویس FRP با موفقیت به‌روزرسانی شد"
			;;
		3)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine
			rm -rf /home/frp

			close_port 8055 8056

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "برنامه حذف شد"
			;;
		5)
			echo "تبدیل پروکسی معکوس سرویس تونل‌زنی داخلی به دسترسی دامنه"
			send_stats "FRP对外域名访问"
			add_yuming
			read -e -p "لطفاً شماره پورت سرویس تونل‌زنی شبکه داخلی خود را وارد کنید: " frps_port
			ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
			block_host_port "$frps_port" "$ipv4_address"
			;;
		6)
			echo "فرمت نام دامنه example.com بدون https://"
			web_del
			;;

		7)
			send_stats "允许IP访问"
			read -e -p "لطفاً شماره پورتی که می‌خواهید باز کنید را وارد کنید: " frps_port
			clear_host_port_rules "$frps_port" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问"
			echo "اگر قبلاً دسترسی دامنه را پروکسی معکوس کرده‌اید، می‌توانید از این ویژگی برای جلوگیری از دسترسی IP+پورت استفاده کنید که امن‌تر است."
			read -e -p "لطفاً شماره پورتی که می‌خواهید مسدود کنید را وارد کنید: " frps_port
			block_host_port "$frps_port" "$ipv4_address"
			;;

		00)
			send_stats "刷新FRP服务状态"
			echo "وضعیت سرویس FRP تازه‌سازی شد"
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
		echo -e "مشتری FRP $check_frp $update_status"
		echo "اتصال به سرور، پس از اتصال می‌توانید سرویس تونل‌زنی داخلی را برای دسترسی به اینترنت ایجاد کنید"
		echo "معرفی وب‌سایت رسمی: https://github.com/fatedier/frp/"
		echo "آموزش ویدیویی: https://youtu.be/Z3Z4OoaV2cw?t=174"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب                  2. به‌روزرسانی                  3. حذف"
		echo "------------------------"
		echo "4. افزودن سرویس خارجی          5. حذف سرویس خارجی          6. پیکربندی دستی سرویس"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			configure_frpc

			add_app_id
			echo "مشتری FRP با موفقیت نصب شد"
			;;
		2)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			donlond_frp frpc

			add_app_id
			echo "مشتری FRP با موفقیت به‌روزرسانی شد"
			;;

		3)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine
			rm -rf /home/frp
			close_port 8055

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "برنامه حذف شد"
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
		echo -e "yt-dlp یک ابزار قدرتمند دانلود ویدیو است که از یوتیوب، بیلی‌بیلی، X (توییتر سابق) و هزاران وب‌سایت دیگر پشتیبانی می‌کند."
		echo -e "آدرس وب‌سایت رسمی: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "لیست ویدیوهای دانلود شده:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(در حال حاضر خالی)"
		echo "-------------------------"
		echo "1. نصب                  2. به‌روزرسانی                  3. حذف"
		echo "-------------------------"
		echo "5. دانلود ویدیو تکی          6. دانلود ویدیوهای دسته‌ای          7. دانلود با پارامترهای سفارشی"
		echo "8. دانلود به عنوان صدای MP3       9. حذف پوشه ویدیو          10. مدیریت کوکی (در حال توسعه)"
		echo "-------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "-------------------------"
		read -e -p "لطفاً شماره گزینه را وارد کنید: " choice

		case $choice in
		1)
			send_stats "正在安装 yt-dlp..."
			echo "در حال نصب yt-dlp..."
			install ffmpeg
			curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
			chmod a+rx /usr/local/bin/yt-dlp

			add_app_id
			echo "نصب با موفقیت انجام شد. برای ادامه هر کلیدی را فشار دهید..."
			read
			;;
		2)
			send_stats "正在更新 yt-dlp..."
			echo "در حال به‌روزرسانی yt-dlp..."
			yt-dlp -U

			add_app_id
			echo "به‌روزرسانی با موفقیت انجام شد. برای ادامه هر کلیدی را فشار دهید..."
			read
			;;
		3)
			send_stats "正在卸载 yt-dlp..."
			echo "در حال حذف نصب yt-dlp..."
			rm -f /usr/local/bin/yt-dlp

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "حذف نصب با موفقیت انجام شد. برای ادامه هر کلیدی را فشار دهید..."
			read
			;;
		5)
			send_stats "单个视频下载"
			read -e -p "لطفاً لینک ویدیو را وارد کنید: " url
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
				echo -e "# چندین آدرس لینک ویدیو را وارد کنید\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" >"$URL_FILE"
			fi
			nano $URL_FILE
			echo "شروع دانلود دسته‌ای..."
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-a "$URL_FILE" \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			read -e -p "دانلود دسته‌ای کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;
		7)
			send_stats "自定义视频下载"
			read -e -p "لطفاً پارامترهای کامل yt-dlp را وارد کنید (بدون yt-dlp): " custom
			yt-dlp -P "$VIDEO_DIR" $custom \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			read -e -p "اجرا کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;
		8)
			send_stats "MP3下载"
			read -e -p "لطفاً لینک ویدیو را وارد کنید: " url
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
			read -e -p "لطفاً نام ویدیویی که می‌خواهید حذف کنید را وارد کنید: " rmdir
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
	echo -e "${gl_huang}در حال به‌روزرسانی سیستم است...${gl_bai}"
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
		echo "مدیر بسته ناشناخته!"
		return
	fi
}

linux_clean() {
	echo -e "${gl_huang}در حال پاکسازی سیستم است...${gl_bai}"
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
		echo "پاکسازی کش مدیر بسته..."
		apk cache clean
		echo "حذف گزارش‌های سیستم..."
		rm -rf /var/log/*
		echo "حذف کش APK..."
		rm -rf /var/cache/apk/*
		echo "حذف فایل‌های موقت..."
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
		echo "حذف گزارش‌های سیستم..."
		rm -rf /var/log/*
		echo "حذف فایل‌های موقت..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "پاکسازی وابستگی‌های استفاده نشده..."
		pkg autoremove -y
		echo "پاکسازی کش مدیر بسته..."
		pkg clean -y
		echo "حذف گزارش‌های سیستم..."
		rm -rf /var/log/*
		echo "حذف فایل‌های موقت..."
		rm -rf /tmp/*

	else
		echo "مدیر بسته ناشناخته!"
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
		echo "بهینه‌سازی آدرس DNS"
		echo "------------------------"
		echo "آدرس DNS فعلی"
		cat /etc/resolv.conf
		echo "------------------------"
		echo ""
		echo "1. بهینه‌سازی DNS برای مناطق غیر چین: "
		echo " v4: 1.1.1.1 8.8.8.8"
		echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
		echo "2. بهینه‌سازی DNS برای مناطق چین: "
		echo " v4: 223.5.5.5 183.60.83.19"
		echo " v6: 2400:3200::1 2400:da00::6666"
		echo "3. ویرایش دستی پیکربندی DNS"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " Limiting
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

	echo "پورت SSH به: $new_port تغییر یافت"

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
	echo -e "اطلاعات کلید خصوصی تولید شد، حتماً آن را کپی و ذخیره کنید، می‌توانید آن را به صورت ${gl_huang}${ipv4_address}_ssh.key${gl_bai} ذخیره کنید، برای ورود SSH بعدی."

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ورود با کلید خصوصی root فعال شد، ورود با رمز عبور root غیرفعال شد، اتصال مجدد اعمال خواهد شد${gl_bai}"

}

import_sshkey() {

	read -e -p "لطفاً محتوای کلید عمومی SSH خود را وارد کنید (معمولاً با 'ssh-rsa' یا 'ssh-ed25519' شروع می‌شود): " public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}خطا: محتوای کلید عمومی وارد نشده است.${gl_bai}"
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
	echo -e "${gl_lv}کلید عمومی با موفقیت وارد شد، ورود با کلید خصوصی root فعال شد، ورود با رمز عبور root غیرفعال شد، اتصال مجدد اعمال خواهد شد${gl_bai}"

}

add_sshpasswd() {

	echo "تنظیم رمز عبور root خود"
	passwd
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}تنظیمات ورود root تکمیل شد! ${gl_bai}"

}

root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${gl_huang}نکته: ${gl_bai}این ویژگی برای اجرا به کاربر root نیاز دارد!" && break_end && kejilion
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
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}root${gl_bai}  رمز عبور اولیه: ${gl_huang}LeitboGi0ro${gl_bai}  پورت اولیه: ${gl_huang}22${gl_bai}"
		echo -e "برای ادامه، هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_2() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}Administrator${gl_bai}  رمز عبور اولیه: ${gl_huang}Teddysun.com${gl_bai}  پورت اولیه: ${gl_huang}3389${gl_bai}"
		echo -e "برای ادامه، هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_3() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}root${gl_bai} رمز عبور اولیه: ${gl_huang}123@@@${gl_bai} پورت اولیه: ${gl_huang}22${gl_bai}"
		echo -e "برای ادامه، هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		dd_xitong_bin456789
	}

	dd_xitong_4() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}Administrator${gl_bai} رمز عبور اولیه: ${gl_huang}123@@@${gl_bai} پورت اولیه: ${gl_huang}3389${gl_bai}"
		echo -e "برای ادامه، هر کلیدی را فشار دهید..."
		read -n 1 -s -r -p ""
		dd_xitong_bin456789
	}

	while true; do
		root_use
		echo "نصب مجدد سیستم"
		echo "--------------------------------"
		echo -e "${gl_hong}توجه: ${gl_bai} نصب مجدد خطرناک است و ممکن است اتصال قطع شود. اگر نگران هستید از آن استفاده نکنید. نصب مجدد حدود 15 دقیقه طول می کشد، لطفاً از داده های خود پشتیبان تهیه کنید."
		echo -e "${gl_hui}با تشکر از اسکریپت های پشتیبانی leitbogioro و bin456789! ${gl_bai}"
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
		echo "35. openSUSE Tumbleweed       36. fnos نسخه بتا پرنده"
		echo "------------------------"
		echo "41. Windows 11                42. Windows 10"
		echo "43. Windows 7                 44. Windows Server 2025"
		echo "45. Windows Server 2022       46. Windows Server 2019"
		echo "47. Windows 11 ARM"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً سیستمی را که می‌خواهید دوباره نصب کنید انتخاب کنید: " sys_choice
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
			echo "شما هسته BBRv3 XanMod را نصب کرده‌اید"
			echo "نسخه هسته فعلی: $kernel_version"

			echo ""
			echo "مدیریت هسته"
			echo "------------------------"
			echo "1. به‌روزرسانی هسته BBRv3              2. حذف هسته BBRv3"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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

				echo "هسته XanMod به‌روزرسانی شد. پس از راه‌اندازی مجدد اعمال می‌شود"
				rm -f /etc/apt/sources.list.d/xanmod-release.list
				rm -f check_x86-64_psabi.sh*

				server_reboot

				;;
			2)
				apt purge -y 'linux-*xanmod1*'
				update-grub
				echo "هسته XanMod حذف شد. پس از راه‌اندازی مجدد اعمال می‌شود"
				server_reboot
				;;

			*)
				break # 跳出循环，退出菜单
				;;

			esac
		done
	else

		clear
		echo "تنظیم BBRv3 شتاب‌دهنده"
		echo "معرفی ویدیو: https://youtu.be/ua2_hmCRL4E"
		echo "------------------------------------------------"
		echo "فقط از Debian/Ubuntu پشتیبانی می‌کند"
		echo "لطفاً از اطلاعات خود پشتیبان‌گیری کنید، هسته لینوکس شما برای فعال‌سازی BBRv3 ارتقا می‌یابد"
		echo "------------------------------------------------"
		read -e -p "آیا مطمئن هستید؟ \(y/N\): " choice

		case "$choice" in
		[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "محیط فعلی پشتیبانی نمی‌شود، فقط از سیستم‌های Debian و Ubuntu پشتیبانی می‌کند"
					break_end
					linux_Settings
				fi
			else
				echo "تعیین نوع سیستم عامل امکان‌پذیر نیست"
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

			echo "نصب هسته XanMod و فعال‌سازی موفقیت‌آمیز BBRv3. پس از راه‌اندازی مجدد اعمال می‌شود"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			;;
		[Nn])
			echo "لغو شد"
			;;
		*)
			echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
		echo "سیستم عامل پشتیبانی نمی‌شود: $os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "سیستم عامل شناسایی شده: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ "$os_version" == 8 ]]; then
		echo "نصب پیکربندی مخزن ELRepo (نسخه 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "نصب پیکربندی مخزن ELRepo (نسخه 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "نصب پیکربندی مخزن ELRepo (نسخه 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "نسخه سیستم عامل پشتیبانی نمی‌شود: $os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "فعال‌سازی مخزن هسته ELRepo و نصب آخرین هسته اصلی..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "پیکربندی منبع نرم‌افزاری ELRepo نصب و به آخرین هسته اصلی به‌روزرسانی شد."
	server_reboot

}

elrepo() {
	root_use
	send_stats "红帽内核管理"
	if uname -r | grep -q 'elrepo'; then
		while true; do
			clear
			kernel_version=$(uname -r)
			echo "شما هسته ELRepo را نصب کرده‌اید"
			echo "نسخه هسته فعلی: $kernel_version"

			echo ""
			echo "مدیریت هسته"
			echo "------------------------"
			echo "1. به‌روزرسانی هسته ELRepo              2. حذف هسته ELRepo"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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
				echo "هسته ELRepo حذف شد. پس از راه‌اندازی مجدد اعمال می‌شود"
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
		echo "لطفاً از اطلاعات خود پشتیبان‌گیری کنید، هسته لینوکس شما ارتقا می‌یابد"
		echo "معرفی ویدیو: https://youtu.be/wamvDukHzUg?t=529"
		echo "------------------------------------------------"
		echo "فقط از توزیع‌های Red Hat مانند CentOS/RedHat/Alma/Rocky/oracle پشتیبانی می‌کند"
		echo "ارتقاء هسته لینوکس می‌تواند عملکرد و امنیت سیستم را بهبود بخشد. توصیه می‌شود در صورت امکان آن را امتحان کنید، اما در محیط‌های تولید با احتیاط ارتقا دهید!"
		echo "------------------------------------------------"
		read -e -p "آیا مطمئن هستید؟ \(y/N\): " choice

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
			echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
			;;
		esac
	fi

}

clamav_freshclam() {
	echo -e "${gl_huang}به روز رسانی پایگاه داده ویروس ها...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "لطفاً دایرکتوری مورد نظر برای اسکن را مشخص کنید."
		return
	fi

	echo -e "${gl_huang}اسکن دایرکتوری $ @ ... ${gl_bai}"

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

	echo -e "${gl_lv}$ @ اسکن کامل شد، گزارش ویروس در ${gl_huang}/home/docker/clamav/log/scan.log${gl_bai} ذخیره می شود"
	echo -e "${gl_lv}اگر ویروسی وجود دارد، لطفاً در فایل ${gl_huang}scan.log${gl_lv} به دنبال کلمه کلیدی FOUND بگردید تا مکان ویروس را تأیید کنید ${gl_bai}"

}

clamav() {
	root_use
	send_stats "病毒扫描管理"
	while true; do
		clear
		echo "ابزار اسکن ویروس clamav"
		echo "معرفی ویدیو: https://youtu.be/UQglgnv-aLU"
		echo "------------------------"
		echo "یک ابزار نرم‌افزاری ضد ویروس منبع باز است که عمدتاً برای تشخیص و حذف انواع مختلف نرم‌افزارهای مخرب استفاده می‌شود."
		echo "شامل ویروس‌ها، تروجان‌ها، جاسوس‌افزارها، اسکریپت‌های مخرب و سایر نرم‌افزارهای مضر."
		echo "------------------------"
		echo -e "${gl_lv}1. اسکن کامل دیسک ${gl_bai}             ${gl_huang}2. اسکن دایرکتوری های مهم ${gl_bai}            ${gl_kjlan} 3. اسکن دایرکتوری سفارشی ${gl_bai}"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
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
			read -e -p "لطفاً دایرکتوری‌هایی که می‌خواهید اسکن کنید را با فاصله از هم جدا کنید (مثلاً: /etc /var /usr /home /root): " directories
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
	echo -e "${gl_lv}تغییر به ${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}بهینه سازی توصیفگر فایل...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}بهینه سازی حافظه مجازی...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv}تغییر به حالت متعادل...${gl_bai}"

	echo -e "${gl_lv}بهینه سازی توصیفگر فایل...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}بهینه سازی حافظه مجازی...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}بازگرداندن به تنظیمات پیش فرض...${gl_bai}"

	echo -e "${gl_lv}بازگرداندن توصیفگر فایل...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}بازگرداندن حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}بازگرداندن تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv}بازگرداندن مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}بازگرداندن تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}بازگرداندن سایر بهینه‌سازی‌ها...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}تغییر به حالت بهینه‌سازی ساخت وب‌سایت...${gl_bai}"

	echo -e "${gl_lv}بهینه سازی توصیفگر فایل...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}بهینه سازی حافظه مجازی...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات CPU...${gl_bai}"
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
		echo "بهینه‌سازی پارامترهای هسته سیستم لینوکس"
		echo "معرفی ویدیو: https://youtu.be/TCsd0pepBac"
		echo "------------------------------------------------"
		echo "حالت‌های مختلفی برای تنظیم دقیق سیستم ارائه می‌دهد که کاربران می‌توانند بر اساس سناریوی استفاده خود انتخاب و جابجا کنند."
		echo -e "${gl_huang}نکته: ${gl_bai}لطفاً در محیط تولید با احتیاط استفاده کنید!"
		echo "--------------------"
		echo "1. حالت بهینه‌سازی عملکرد بالا: حداکثر کردن عملکرد سیستم، بهینه‌سازی توصیف‌گرهای فایل، حافظه مجازی، تنظیمات شبکه، مدیریت کش و تنظیمات CPU."
		echo "2. حالت بهینه‌سازی متعادل: دستیابی به تعادل بین عملکرد و مصرف منابع، مناسب برای استفاده روزمره."
		echo "3. حالت بهینه‌سازی وب‌سایت: بهینه‌سازی برای سرورهای وب، بهبود توانایی پردازش اتصالات همزمان، سرعت پاسخ و عملکرد کلی."
		echo "4. حالت بهینه‌سازی پخش زنده: بهینه‌سازی برای نیازهای خاص پخش زنده، کاهش تأخیر و بهبود عملکرد انتقال."
		echo "5. حالت بهینه‌سازی سرور بازی: بهینه‌سازی برای سرورهای بازی، بهبود توانایی پردازش همزمان و سرعت پاسخ."
		echo "6. بازگرداندن تنظیمات پیش‌فرض: بازگرداندن تنظیمات سیستم به پیکربندی پیش‌فرض."
		echo "--------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "--------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
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
			echo -e "${gl_lv}زبان سیستم تغییر یافت به: $lang برای اعمال تغییرات SSH را دوباره متصل کنید.${gl_bai}"
			hash -r
			break_end

			;;
		centos | rhel | almalinux | rocky | fedora)
			install glibc-langpack-zh
			localectl set-locale LANG=${lang}
			echo "LANG=${lang}" | tee /etc/locale.conf
			echo -e "${gl_lv}زبان سیستم تغییر یافت به: $lang برای اعمال تغییرات SSH را دوباره متصل کنید.${gl_bai}"
			hash -r
			break_end
			;;
		*)
			echo "سیستم پشتیبانی نمی‌شود: $ID"
			break_end
			;;
		esac
	else
		echo "سیستم پشتیبانی نمی‌شود، نوع سیستم قابل شناسایی نیست."
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
		echo "1. English          2. 简体中文          3. 繁體中文"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید: " choice

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
	echo -e "${gl_lv}تغییرات اعمال شد. برای مشاهده تغییرات SSH را دوباره متصل کنید!${gl_bai}"

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
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید: " choice

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
		echo -e "سطل زباله فعلی ${trash_status}"
		echo -e "با فعال کردن این گزینه، فایل‌های حذف شده با rm ابتدا به سطل زباله منتقل می‌شوند تا از حذف تصادفی فایل‌های مهم جلوگیری شود!"
		echo "------------------------------------------------"
		ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "سطل بازیافت خالی است"
		echo "------------------------"
		echo "1. فعال کردن سطل بازیافت          2. غیرفعال کردن سطل بازیافت"
		echo "3. بازیابی محتوا            4. خالی کردن سطل بازیافت"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید: " choice

		case $choice in
		1)
			install trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='trash-put'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "سطل بازیافت فعال است، فایل‌های حذف شده به سطل بازیافت منتقل می‌شوند."
			sleep 2
			;;
		2)
			remove trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='rm -i'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "سطل بازیافت غیرفعال است، فایل‌ها مستقیماً حذف می‌شوند."
			sleep 2
			;;
		3)
			read -e -p "نام فایل مورد نظر برای بازیابی را وارد کنید: " file_to_restore
			if [ -e "$TRASH_DIR/$file_to_restore" ]; then
				mv "$TRASH_DIR/$file_to_restore" "$HOME/"
				echo "‎$file_to_restore به پوشه اصلی بازگردانده شد."
			else
				echo "فایل وجود ندارد."
			fi
			;;
		4)
			read -e -p "آیا پاک کردن سطل زباله را تایید می‌کنید؟ \(y/N\): " confirm
			if [[ "$confirm" == "y" ]]; then
				trash-empty
				echo "سطل بازیافت خالی شد."
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
	echo "مثال ایجاد پشتیبان: "
	echo "- پشتیبان‌گیری از یک پوشه: /var/www"
	echo "- پشتیبان‌گیری از چند پوشه: /etc /home /var/log"
	echo "- با زدن Enter به طور مستقیم از پوشه پیش‌فرض استفاده می‌شود (/etc /usr /home)"
	read -r -p "لطفاً دایرکتوری‌هایی را که می‌خواهید پشتیبان‌گیری کنید وارد کنید (چندین دایرکتوری را با فاصله جدا کنید، برای استفاده از دایرکتوری پیش‌فرض Enter را فشار دهید) : " input

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
	echo "پوشه پشتیبان‌گیری انتخابی شما: "
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "در حال ایجاد پشتیبان $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "پشتیبان‌گیری با موفقیت ایجاد شد: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "ایجاد پشتیبان‌گیری با خطا مواجه شد! "
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	read -e -p "لطفا نام فایل پشتیبانی که می‌خواهید بازیابی کنید را وارد کنید: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "فایل پشتیبان‌گیری وجود ندارد! "
		exit 1
	fi

	echo "در حال بازیابی پشتیبان $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "پشتیبان‌گیری و بازیابی با موفقیت انجام شد! "
	else
		echo "پشتیبان‌گیری و بازیابی با شکست مواجه شد! "
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "پشتیبان‌های موجود: "
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	read -e -p "لطفا نام فایل پشتیبانی که می‌خواهید حذف کنید را وارد کنید: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "فایل پشتیبان‌گیری وجود ندارد! "
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "حذف پشتیبان با موفقیت انجام شد! "
	else
		echo "حذف پشتیبان با شکست مواجه شد! "
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
		echo "عملکرد پشتیبان‌گیری سیستم"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. ایجاد پشتیبان        2. بازیابی پشتیبان        3. حذف پشتیبان"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice
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
	echo "اتصالات ذخیره شده: "
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}

# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "ایجاد نمونه اتصال جدید: "
	echo "  - نام اتصال: my_server"
	echo "  - آدرس IP: 192.168.1.100"
	echo "  - نام کاربری: root"
	echo "  - پورت: 22"
	echo "------------------------"
	read -e -p "لطفا نام اتصال را وارد کنید: " name
	read -e -p "لطفا آدرس IP را وارد کنید: " ip
	read -e -p "لطفا نام کاربری را وارد کنید (پیش‌فرض root): " user
	local user=${user:-root} # 如果用户未输入，则使用默认值 root
	read -e -p "لطفا شماره پورت را وارد کنید (پیش‌فرض 22): " port
	local port=${port:-22} # 如果用户未输入，则使用默认值 22

	echo "لطفا روش احراز هویت را انتخاب کنید: "
	echo "1. رمز عبور"
	echo "2. کلید"
	read -e -p "لطفا انتخاب خود را وارد کنید (1/2): " auth_choice

	case $auth_choice in
	1)
		read -s -p "请输入密码: " password_or_key
		echo # 换行
		;;
	2)
		echo "لطفا محتوای کلید را کپی کنید (بعد از کپی کردن دو بار Enter را فشار دهید): "
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
		echo "انتخاب نامعتبر! "
		return
		;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >>"$CONFIG_FILE"
	echo "اتصال ذخیره شد! "
}

# 删除连接
delete_connection() {
	send_stats "删除连接"
	read -e -p "لطفا شماره اتصالی که می‌خواهید حذف کنید را وارد کنید: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "خطا: اتصال مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "اتصال قطع شد! "
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	read -e -p "لطفا شماره اتصالی که می‌خواهید استفاده کنید را وارد کنید: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "خطا: اتصال مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	echo "در حال اتصال به $name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال ناموفق! لطفاً موارد زیر را بررسی کنید: "
			echo "1. آیا مسیر فایل کلید صحیح است: $password_or_key"
			echo "2. آیا مجوزهای فایل کلید صحیح است (باید 600 باشد)."
			echo "3. آیا سرور هدف اجازه ورود با کلید را می دهد."
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &>/dev/null; then
			echo "خطا: sshpass نصب نشده است، لطفاً ابتدا sshpass را نصب کنید."
			echo "روش نصب: "
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال ناموفق! لطفاً موارد زیر را بررسی کنید: "
			echo "1. آیا نام کاربری و رمز عبور صحیح است."
			echo "2. آیا سرور هدف اجازه ورود با رمز عبور را می دهد."
			echo "3. آیا سرویس SSH سرور هدف به درستی کار می کند."
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
		echo "می توانید از طریق SSH به سیستم های لینوکس دیگر متصل شوید"
		echo "------------------------"
		list_connections
		echo "1. ایجاد اتصال جدید        2. استفاده از اتصال        3. حذف اتصال"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice
		case $choice in
		1) add_connection ;;
		2) use_connection ;;
		3) delete_connection ;;
		0) break ;;
		*) echo "انتخاب نامعتبر، لطفاً دوباره تلاش کنید." ;;
		esac
	done
}

# 列出可用的硬盘分区
list_partitions() {
	echo "پارتیشن های هارد دیسک موجود: "
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	read -e -p "لطفا نام پارتیشنی که می‌خواهید mount کنید را وارد کنید (مثلا sda1): " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد! "
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن قبلاً نصب شده است! "
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "نصب پارتیشن موفقیت آمیز بود: $MOUNT_POINT"
	else
		echo "نصب پارتیشن ناموفق بود! "
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	read -e -p "لطفا نام پارتیشنی که می‌خواهید unmount کنید را وارد کنید (مثلا sda1): " PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "منطقه نصب نشده است!"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "منطقه با موفقیت جدا شد: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "نصب منطقه با شکست مواجه شد!"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "مناطق نصب شده:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	read -e -p "لطفا نام پارتیشنی که می‌خواهید فرمت کنید را وارد کنید (مثلا sda1): " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد! "
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "منطقه از قبل نصب شده است، ابتدا آن را جدا کنید!"
		return
	fi

	# 选择文件系统类型
	echo "لطفا نوع سیستم فایل را انتخاب کنید:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "لطفاً انتخاب خود را وارد کنید: " FS_CHOICE

	case $FS_CHOICE in
	1) FS_TYPE="ext4" ;;
	2) FS_TYPE="xfs" ;;
	3) FS_TYPE="ntfs" ;;
	4) FS_TYPE="vfat" ;;
	*)
		echo "انتخاب نامعتبر! "
		return
		;;
	esac

	# 确认格式化
	read -e -p "آیا فرمت کردن پارتیشن /dev/$PARTITION با $FS_TYPE را تایید می‌کنید؟ \(y/N\): " CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "عملیات لغو شد."
		return
	fi

	# 格式化分区
	echo "در حال فرمت کردن پارتیشن /dev/$PARTITION به $FS_TYPE..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "فرمت پارتیشن با موفقیت انجام شد!"
	else
		echo "فرمت پارتیشن با شکست مواجه شد!"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	read -e -p "لطفا نام پارتیشنی که می‌خواهید بررسی کنید را وارد کنید (مثلا sda1): " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد! "
		return
	fi

	# 检查分区状态
	echo "بررسی وضعیت پارتیشن /dev/$PARTITION:"
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "مدیریت پارتیشن دیسک سخت"
		echo -e "${gl_huang}این ویژگی در مرحله تست داخلی است، لطفاً در محیط تولید استفاده نکنید.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. نصب پارتیشن 2. جدا کردن پارتیشن 3. مشاهده پارتیشن های نصب شده"
		echo "4. فرمت پارتیشن 5. بررسی وضعیت پارتیشن"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice
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
	echo "ایجاد یک نمونه وظیفه همگام سازی جدید:"
	echo " - نام وظیفه: backup_www"
	echo " - دایرکتوری محلی: /var/www"
	echo " - آدرس راه دور: user@192.168.1.100"
	echo " - دایرکتوری راه دور: /backup/www"
	echo " - شماره پورت (پیش فرض 22)"
	echo "---------------------------------"
	read -e -p "لطفا نام تسک را وارد کنید: " name
	read -e -p "لطفا دایرکتوری محلی را وارد کنید: " local_path
	read -e -p "لطفا دایرکتوری راه دور را وارد کنید: " remote_path
	read -e -p "لطفا کاربر راه دور@IP را وارد کنید: " remote
	read -e -p "لطفاً پورت SSH را وارد کنید (پیش‌فرض 22): " port
	port=${port:-22}

	echo "لطفا روش احراز هویت را انتخاب کنید: "
	echo "1. رمز عبور"
	echo "2. کلید"
	read -e -p "لطفاً انتخاب کنید (1/2): " auth_choice

	case $auth_choice in
	1)
		read -s -p "请输入密码: " password_or_key
		echo # 换行
		auth_method="password"
		;;
	2)
		echo "لطفا محتوای کلید را کپی کنید (بعد از کپی کردن دو بار Enter را فشار دهید): "
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
			echo "محتوای کلید نامعتبر! "
			return
		fi
		;;
	*)
		echo "انتخاب نامعتبر! "
		return
		;;
	esac

	echo "لطفاً حالت همگام‌سازی را انتخاب کنید: "
	echo "1. حالت استاندارد (-avz)"
	echo "2. حذف فایل‌های مقصد (-avz --delete)"
	read -e -p "لطفاً انتخاب کنید (1/2): " mode
	case $mode in
	1) options="-avz" ;;
	2) options="-avz --delete" ;;
	*)
		echo "انتخاب نامعتبر، استفاده از پیش‌فرض -avz"
		options="-avz"
		;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >>"$CONFIG_FILE"

	install rsync rsync

	echo "وظیفه ذخیره شد! "
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	read -e -p "لطفاً شماره‌ی کار برای حذف را وارد کنید: " num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "خطا: وظیفه مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "وظیفه حذف شد! "
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
		read -e -p "لطفاً شماره‌ی کار برای اجرا را وارد کنید: " num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "خطا: این وظیفه یافت نشد! "
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 根据同步方向调整源和目标路径
	if [[ "$direction" == "pull" ]]; then
		echo "در حال دریافت همگام‌سازی به صورت محلی: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "در حال ارسال همگام‌سازی به صورت از راه دور: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &>/dev/null; then
			echo "خطا: sshpass نصب نشده است، لطفاً ابتدا sshpass را نصب کنید."
			echo "روش نصب: "
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f "$password_or_key" ]]; then
			echo "خطا: فایل کلید وجود ندارد: $password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "هشدار: مجوزهای فایل کلید نادرست است، در حال اصلاح..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "همگام‌سازی تکمیل شد! "
	else
		echo "همگام‌سازی با شکست مواجه شد! لطفاً موارد زیر را بررسی کنید: "
		echo "1. آیا اتصال شبکه عادی است"
		echo "2. آیا هاست از راه دور قابل دسترسی است"
		echo "3. آیا اطلاعات احراز هویت صحیح است"
		echo "4. آیا دسترسی صحیح به دایرکتوری‌های محلی و از راه دور وجود دارد"
	fi
}

# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	read -e -p "لطفاً شماره‌ی کار برای همگام‌سازی زمان‌بندی شده را وارد کنید: " num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً شماره وظیفه معتبر را وارد کنید! "
		return
	fi

	echo "لطفاً فاصله اجرای زمان‌بندی شده را انتخاب کنید: "
	echo "1. اجرای هر ساعت یک بار"
	echo "2. اجرای روزانه یک بار"
	echo "3. اجرای هفتگی یک بار"
	read -e -p "لطفاً گزینه را وارد کنید (1/2/3): " interval

	local random_minute=$(shuf -i 0-59 -n 1) # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
	1) cron_time="$random_minute * * * *" ;; # 每小时，随机分钟执行
	2) cron_time="$random_minute 0 * * *" ;; # 每天，随机分钟执行
	3) cron_time="$random_minute 0 * * 1" ;; # 每周，随机分钟执行
	*)
		echo "خطا: لطفاً یک گزینه معتبر وارد کنید!"
		return
		;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "خطا: همگام‌سازی زمان‌بندی شده برای این کار از قبل وجود دارد!"
		return
	fi

	# 创建到用户的 crontab
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "کار زمان‌بندی شده ایجاد شد: $cron_job"
}

# 查看定时任务
view_tasks() {
	echo "کارهای زمان‌بندی شده فعلی: "
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	read -e -p "لطفاً شماره‌ی کار برای حذف را وارد کنید: " num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً شماره وظیفه معتبر را وارد کنید! "
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "کار زمان‌بندی شده با شماره $num حذف شد"
}

# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "ابزار همگام‌سازی از راه دور Rsync"
		echo "همگام‌سازی بین دایرکتوری‌های از راه دور، پشتیبانی از همگام‌سازی افزایشی، کارآمد و پایدار."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. ایجاد کار جدید           2. حذف کار"
		echo "3. اجرای همگام‌سازی محلی به از راه دور   4. اجرای همگام‌سازی از راه دور به محلی"
		echo "5. ایجاد کار زمان‌بندی شده         6. حذف کار زمان‌بندی شده"
		echo "---------------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "---------------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice
		case $choice in
		1) add_task ;;
		2) delete_task ;;
		3) run_task push ;;
		4) run_task pull ;;
		5) schedule_task ;;
		6) delete_task_schedule ;;
		0) break ;;
		*) echo "انتخاب نامعتبر، لطفاً دوباره تلاش کنید." ;;
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

	local runtime=$(uptime -p | sed 's/up //')

	local timezone=$(current_timezone)

	echo ""
	echo -e "جستجوی اطلاعات سیستم"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}نام میزبان:                   ${gl_bai}$hostname"
	echo -e "${gl_kjlan}نسخه سیستم:                   ${gl_bai}$os_info"
	echo -e "${gl_kjlan}نسخه لینوکس:                  ${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}معماری CPU:                   ${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}مدل CPU:                      ${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}تعداد هسته‌های CPU:            ${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}فرکانس CPU:                   ${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}استفاده CPU:                  ${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}بارگذاری سیستم:               ${gl_bai}$load"
	echo -e "${gl_kjlan}حافظه فیزیکی:                 ${gl_bai}$mem_info"
	echo -e "${gl_kjlan}حافظه مجازی:                  ${gl_bai}$swap_info"
	echo -e "${gl_kjlan}فضای دیسک:                    ${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}دریافت کل:                    ${gl_bai}$rx"
	echo -e "${gl_kjlan}ارسال کل:                     ${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}الگوریتم شبکه:                ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ارائه‌دهنده خدمات اینترنت:     ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}آدرس IPv4:                    ${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}آدرس IPv6:                    ${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}آدرس DNS:                     ${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}موقعیت جغرافیایی:             ${gl_bai}$country $city"
	echo -e "${gl_kjlan}زمان سیستم:                   ${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}مدت زمان اجرا:                ${gl_bai}$runtime"
	echo

}

linux_tools() {

	while true; do
		clear
		# send_stats "基础工具"
		echo -e "ابزارهای پایه"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}ابزار دانلود curl ${gl_huang}★${gl_bai}                           ${gl_kjlan}2.   ${gl_bai}ابزار دانلود wget ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}3.   ${gl_bai}ابزار دسترسی ریشه sudo                        ${gl_kjlan}4.   ${gl_bai}ابزار اتصال ارتباطی socat"
		echo -e "${gl_kjlan}5.   ${gl_bai}ابزار نظارت بر سیستم htop                     ${gl_kjlan}6.   ${gl_bai}ابزار نظارت بر ترافیک شبکه iftop"
		echo -e "${gl_kjlan}7.   ${gl_bai}ابزار فشرده‌سازی و استخراج ZIP                ${gl_kjlan}8.   ${gl_bai}ابزار فشرده‌سازی و استخراج GZ tar"
		echo -e "${gl_kjlan}9.   ${gl_bai}ابزار اجرای پس‌زمینه چندگانه tmux             ${gl_kjlan}10.  ${gl_bai}ابزار کدگذاری و پخش زنده صوتی و تصویری ffmpeg"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}ابزار نظارت مدرن btop ${gl_huang}★${gl_bai}                       ${gl_kjlan}12.  ${gl_bai}ابزار مدیریت فایل ranger"
		echo -e "${gl_kjlan}13.  ${gl_bai}ابزار مشاهده میزان استفاده از دیسک ncdu       ${gl_kjlan}14.  ${gl_bai}ابزار جستجوی سراسری fzf"
		echo -e "${gl_kjlan}15.  ${gl_bai}ویرایشگر متن vim                              ${gl_kjlan}16.  ${gl_bai}ویرایشگر متن nano ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}17.  ${gl_bai}سیستم کنترل نسخه git"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}اسکرین‌سیور ماتریکس                           ${gl_kjlan}22.  ${gl_bai}اسکرین‌سیور مار"
		echo -e "${gl_kjlan}26.  ${gl_bai}بازی تتریس                                    ${gl_kjlan}27.  ${gl_bai}بازی مار"
		echo -e "${gl_kjlan}28.  ${gl_bai}بازی مهاجمان فضایی"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}نصب همه                                       ${gl_kjlan}32.  ${gl_bai}نصب همه (بدون اسکرین‌سیور و بازی) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}حذف نصب همه"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}نصب ابزار مشخص                                ${gl_kjlan}42.  ${gl_bai}حذف نصب ابزار مشخص"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			clear
			install curl
			clear
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
			curl --help
			send_stats "安装curl"
			;;
		2)
			clear
			install wget
			clear
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
			wget --help
			send_stats "安装wget"
			;;
		3)
			clear
			install sudo
			clear
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
			sudo --help
			send_stats "安装sudo"
			;;
		4)
			clear
			install socat
			clear
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
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
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
			unzip
			send_stats "安装unzip"
			;;
		8)
			clear
			install tar
			clear
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
			tar --help
			send_stats "安装tar"
			;;
		9)
			clear
			install tmux
			clear
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
			tmux --help
			send_stats "安装tmux"
			;;
		10)
			clear
			install ffmpeg
			clear
			echo "ابزار نصب شده است، روش استفاده به شرح زیر است: "
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
			read -e -p "لطفاً نام ابزار نصب شده را وارد کنید (wget curl sudo htop): " installname
			install $installname
			send_stats "安装指定软件"
			;;
		42)
			clear
			read -e -p "لطفاً نام ابزار برای حذف نصب را وارد کنید (htop ufw tmux cmatrix): " removename
			remove $removename
			send_stats "卸载指定软件"
			;;

		0)
			kejilion
			;;

		*)
			echo "ورودی نامعتبر! "
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
			echo "الگوریتم کنترل ازدحام TCP فعلی: $congestion_algorithm $queue_algorithm"

			echo ""
			echo "مدیریت BBR"
			echo "------------------------"
			echo "1. فعال کردن BBRv3        2. غیرفعال کردن BBRv3 (راه‌اندازی مجدد خواهد شد) "
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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
		echo -e "${BLUE}لیست پشتیبان‌گیری فعلی:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "پشتیبان‌گیری وجود ندارد"
	}

	# ----------------------------
	# 备份
	# ----------------------------
	backup_docker() {
		send_stats "Docker备份"

		echo -e "${YELLOW}در حال پشتیبان‌گیری از کانتینرهای Docker...${NC}"
		docker ps --format '{{.Names}}'
		read -e -p "请输入要备份的容器名（多个空格分隔，回车备份全部运行中容器）: " containers

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
			echo -e "${RED}کانتینری یافت نشد${NC}"
			return
		}

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" >"$RESTORE_SCRIPT"
		echo "set -e" >>"$RESTORE_SCRIPT"
		echo "# اسکریپت بازیابی تولید شده به صورت خودکار" >>"$RESTORE_SCRIPT"

		# 记录已打包过的 Compose 项目路径，避免重复打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN}پشتیبان‌گیری از کانتینر: $c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" >"$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE}تشخیص داده شد که $c یک کانتینر Docker Compose است${NC}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p "未检测到 compose 目录，请手动输入路径: " project_dir
				fi

				# 如果该 Compose 项目已经打包过，跳过
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}پروژه Compose [$project_name] قبلاً پشتیبان‌گیری شده است، از بسته‌بندی مجدد صرف نظر می‌شود...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" >"${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" >"${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# بازیابی docker-compose: $project_name" >>"$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >>"$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}پروژه Compose [$project_name] بسته‌بندی شد: ${project_dir}${NC}"
				else
					echo -e "${RED}docker-compose.yml یافت نشد، از این کانتینر صرف نظر می‌شود...${NC}"
				fi
			else
				# 普通容器备份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "بسته‌بندی حجم دیسک: $path"
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

				echo -e "\n# بازگرداندن کانتینر: $c" >>"$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >>"$RESTORE_SCRIPT"
			fi
		done

		# 备份 /home/docker 下的所有文件（不含子目录）
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE}پشتیبان‌گیری از فایل‌های زیر $(/home/docker)...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${GREEN}فایل‌های زیر $(/home/docker) بسته‌بندی شده‌اند به: ${BACKUP_DIR}/home_docker_files.tar.gz${NC}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN}پشتیبان‌گیری تکمیل شد: ${BACKUP_DIR}${NC}"
		echo -e "${GREEN}اسکریپت بازیابی موجود: ${RESTORE_SCRIPT}${NC}"

	}

	# ----------------------------
	# 还原
	# ----------------------------
	restore_docker() {

		send_stats "Docker还原"
		read -e -p "请输入要还原的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}دایرکتوری پشتیبان‌گیری وجود ندارد${NC}"
			return
		}

		echo -e "${BLUE}شروع عملیات بازیابی...${NC}"

		install tar jq gzip
		install_docker

		# --------- 优先还原 Compose 项目 ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p "未找到原始路径，请输入还原目录路径: " original_path

				# 检查该 compose 项目的容器是否已经在运行
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${YELLOW}پروژه Compose [$project_name] دارای کانتینر در حال اجرا است، بازیابی رد می‌شود...${NC}"
					continue
				fi

				read -e -p "确认还原 Compose 项目 [$project_name] 到路径 [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p "请输入新的还原路径: " original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN}پروژه Compose [$project_name] استخراج شد به: $original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN}پروژه Compose [$project_name] بازیابی شد! ${NC}"
			fi
		done

		# --------- 继续还原普通容器 ---------
		echo -e "${BLUE}بررسی و بازیابی کانتینرهای Docker معمولی...${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${GREEN}در حال پردازش کانتینر: $container${NC}"

			# 检查容器是否已经存在且正在运行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}کانتینر [$container] در حال اجرا است، بازیابی رد می‌شود...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && {
				echo -e "${RED}اطلاعات تصویر یافت نشد، رد می‌شود: $container${NC}"
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
					echo "بازیابی داده‌های حجم دیسک: $VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 删除已存在但未运行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}کانتینر [$container] وجود دارد اما در حال اجرا نیست، حذف کانتینر قدیمی...${NC}"
				docker rm -f "$container"
			fi

			# 启动容器
			echo "اجرای دستور بازیابی: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW}اطلاعات پشتیبان‌گیری کانتینر معمولی یافت نشد${NC}"

		# 还原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE}در حال بازیابی فایل‌های زیر $(/home/docker)...${NC}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${GREEN}فایل‌های زیر $(/home/docker) با موفقیت بازیابی شدند${NC}"
		else
			echo -e "${YELLOW}پشتیبان‌گیری فایل‌های زیر $(/home/docker) یافت نشد، رد می‌شود...${NC}"
		fi

	}

	# ----------------------------
	# 迁移
	# ----------------------------
	migrate_docker() {
		send_stats "Docker迁移"
		install jq
		read -e -p "请输入要迁移的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}دایرکتوری پشتیبان‌گیری وجود ندارد${NC}"
			return
		}

		read -e -p "目标服务器IP: " TARGET_IP
		read -e -p "目标服务器SSH用户名: " TARGET_USER
		read -e -p "پورت SSH سرور هدف [پیش‌فرض 22]: " TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW}انتقال پشتیبان‌گیری در حال انجام است...${NC}"
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
		read -e -p "请输入要删除的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}دایرکتوری پشتیبان‌گیری وجود ندارد${NC}"
			return
		}
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN}پشتیبان‌گیری حذف شد: ${BACKUP_DIR}${NC}"
	}

	# ----------------------------
	# 主菜单
	# ----------------------------
	main_menu() {
		send_stats "Docker备份迁移还原"
		while true; do
			clear
			echo "------------------------"
			echo -e "ابزار پشتیبان‌گیری/انتقال/بازیابی داکر"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. پشتیبان‌گیری از پروژه داکر"
			echo -e "2. انتقال پروژه داکر"
			echo -e "3. بازیابی پروژه داکر"
			echo -e "4. حذف فایل‌های پشتیبان پروژه داکر"
			echo "------------------------"
			echo -e "0. بازگشت به منوی قبلی"
			echo "------------------------"
			read -e -p "请选择: " choice
			case $choice in
			1) backup_docker ;;
			2) migrate_docker ;;
			3) restore_docker ;;
			4) delete_backup ;;
			0) return ;;
			*) echo -e "${RED}گزینه نامعتبر${NC}" ;;
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
		echo -e "${gl_kjlan}1.   ${gl_bai}نصب به‌روزرسانی محیط داکر ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}2.   ${gl_bai}مشاهده وضعیت کلی داکر ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}مدیریت کانتینرهای داکر ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}4.   ${gl_bai}مدیریت ایمیج‌های داکر"
		echo -e "${gl_kjlan}5.   ${gl_bai}مدیریت شبکه‌های داکر"
		echo -e "${gl_kjlan}6.   ${gl_bai}مدیریت حجم‌های داکر"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}7.   ${gl_bai}پاکسازی کانتینرها، ایمیج‌ها و شبکه‌های بلااستفاده داکر"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}8.   ${gl_bai}تغییر منبع داکر"
		echo -e "${gl_kjlan}9.   ${gl_bai}ویرایش فایل daemon.json"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}فعال‌سازی دسترسی Docker-IPv6"
		echo -e "${gl_kjlan}12.  ${gl_bai}غیرفعال‌سازی دسترسی Docker-IPv6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}19.  ${gl_bai}پشتیبان‌گیری/انتقال/بازیابی محیط داکر"
		echo -e "${gl_kjlan}20.  ${gl_bai}حذف نصب Docker"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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
			echo "نسخه Docker"
			docker -v
			docker compose version

			echo ""
			echo -e "تصویر Docker: ${gl_lv}$image_count${gl_bai}"
			docker image ls
			echo ""
			echo -e "کانتینرهای Docker: ${gl_lv}$container_count${gl_bai}"
			docker ps -a
			echo ""
			echo -e "ولوم‌های Docker: ${gl_lv}$volume_count${gl_bai}"
			docker volume ls
			echo ""
			echo -e "شبکه‌های Docker: ${gl_lv}$network_count${gl_bai}"
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
				echo "لیست شبکه‌های Docker"
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
				echo "1. ایجاد شبکه"
				echo "2. پیوستن به شبکه"
				echo "3. خروج از شبکه"
				echo "4. حذف شبکه"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					send_stats "创建网络"
					read -e -p "تنظیم نام شبکه جدید: " dockernetwork
					docker network create $dockernetwork
					;;
				2)
					send_stats "加入网络"
					read -e -p "اضافه کردن نام شبکه: " dockernetwork
					read -e -p "کدام کانتینرها به این شبکه بپیوندند (لطفاً نام کانتینرهای متعدد را با فاصله از هم جدا کنید): " dockernames

					for dockername in $dockernames; do
						docker network connect $dockernetwork $dockername
					done
					;;
				3)
					send_stats "加入网络"
					read -e -p "خروج از نام شبکه: " dockernetwork
					read -e -p "کدام کانتینرها از این شبکه خارج شوند (لطفاً نام کانتینرهای متعدد را با فاصله از هم جدا کنید): " dockernames

					for dockername in $dockernames; do
						docker network disconnect $dockernetwork $dockername
					done

					;;

				4)
					send_stats "删除网络"
					read -e -p "لطفاً نام شبکه برای حذف را وارد کنید: " dockernetwork
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
				echo "لیست حجم‌های Docker"
				docker volume ls
				echo ""
				echo "عملیات حجم"
				echo "------------------------"
				echo "1. ایجاد حجم جدید"
				echo "2. حذف حجم مشخص شده"
				echo "3. حذف همه حجم‌ها"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					send_stats "新建卷"
					read -e -p "تنظیم نام حجم جدید: " dockerjuan
					docker volume create $dockerjuan

					;;
				2)
					read -e -p "نام حجم(های) برای حذف را وارد کنید (لطفاً نام حجم‌های متعدد را با فاصله از هم جدا کنید): " dockerjuans

					for dockerjuan in $dockerjuans; do
						docker volume rm $dockerjuan
					done

					;;

				3)
					send_stats "删除所有卷"
					read -e -p "$(echo -e "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می‌خواهید همه ولوم‌های استفاده نشده را حذف کنید؟ \(y/N\): ")" choice
					case "$choice" in
					[Yy])
						docker volume prune -f
						;;
					[Nn]) ;;
					*)
						echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
			read -e -p "$(echo -e "${gl_huang}راهنما: ${gl_bai}تصاویر، کانتینرها و شبکه‌های غیرضروری، از جمله کانتینرهای متوقف شده را پاک می‌کند. آیا مطمئن هستید که می‌خواهید پاک کنید؟ \(y/N\): ")" choice
			case "$choice" in
			[Yy])
				docker system prune -af --volumes
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
			read -e -p "$(echo -e "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می‌خواهید نصب Docker را حذف کنید؟ \(y/N\): ")" choice
			case "$choice" in
			[Yy])
				docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				remove docker docker-compose docker-ce docker-ce-cli containerd.io
				rm -f /etc/docker/daemon.json
				hash -r
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion
			;;
		*)
			echo "ورودی نامعتبر! "
			;;
		esac
		break_end

	done

}

linux_test() {

	while true; do
		clear
		# send_stats "测试脚本合集"
		echo -e "مجموعه اسکریپت‌های تست"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}بررسی وضعیت باز شدن IP"
		echo -e "${gl_kjlan}1.   ${gl_bai}بررسی وضعیت باز شدن ChatGPT"
		echo -e "${gl_kjlan}2.   ${gl_bai}تست باز شدن استریمینگ منطقه‌ای"
		echo -e "${gl_kjlan}3.   ${gl_bai}بررسی باز شدن استریمینگ yeahwu"
		echo -e "${gl_kjlan}4.   ${gl_bai}اسکریپت بررسی کیفیت IP xykt ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}تست سرعت خط شبکه"
		echo -e "${gl_kjlan}11.  ${gl_bai}تست مسیر تاخیر بازگشت سه شبکه besttrace"
		echo -e "${gl_kjlan}12.  ${gl_bai}تست خط بازگشت سه شبکه mtr_trace"
		echo -e "${gl_kjlan}13.  ${gl_bai}تست سرعت سه شبکه Superspeed"
		echo -e "${gl_kjlan}14.  ${gl_bai}اسکریپت تست سریع بازگشت nxtrace"
		echo -e "${gl_kjlan}15.  ${gl_bai}اسکریپت تست بازگشت IP مشخص nxtrace"
		echo -e "${gl_kjlan}16.  ${gl_bai}تست خطوط شبکه لوداشی 2020"
		echo -e "${gl_kjlan}17.  ${gl_bai}اسکریپت تست سرعت چند منظوره i-abc"
		echo -e "${gl_kjlan}18.  ${gl_bai}اسکریپت بررسی کیفیت شبکه NetQuality ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}تست عملکرد سخت افزار"
		echo -e "${gl_kjlan}21.  ${gl_bai}تست عملکرد yabs"
		echo -e "${gl_kjlan}22.  ${gl_bai}اسکریپت تست عملکرد CPU icu/gb5"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}تست جامع"
		echo -e "${gl_kjlan}31.  ${gl_bai}تست عملکرد bench"
		echo -e "${gl_kjlan}32.  ${gl_bai}بررسی هیبریدی spiritysdx ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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
			echo "لیست IP های مرجع"
			echo "------------------------"
			echo "Beijing Telecom: 219.141.136.12"
			echo "Beijing Unicom: 202.106.50.1"
			echo "پکن موبایل: 221.179.155.161"
			echo "شانگهای تلکام: 202.96.209.133"
			echo "شانگهای یونیکام: 210.22.97.1"
			echo "شانگهای موبایل: 211.136.112.200"
			echo "گوانگژو تلکام: 58.60.188.222"
			echo "گوانگژو یونیکام: 210.21.196.6"
			echo "گوانگژو موبایل: 120.196.165.24"
			echo "چنگدو تلکام: 61.139.2.69"
			echo "چنگدو یونیکام: 119.6.6.6"
			echo "چنگدو موبایل: 211.137.96.205"
			echo "هونان تلکام: 36.111.200.100"
			echo "هونان یونیکام: 42.48.16.100"
			echo "هونان موبایل: 39.134.254.6"
			echo "------------------------"

			read -e -p "یک IP مشخص را وارد کنید: " testip
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
			echo "ورودی نامعتبر! "
			;;
		esac
		break_end

	done

}

linux_Oracle() {

	while true; do
		clear
		send_stats "甲骨文云脚本合集"
		echo -e "مجموعه اسکریپت های Oracle Cloud"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}اسکریپت نصب فعال سازی ماشین های بیکار"
		echo -e "${gl_kjlan}2.   ${gl_bai}اسکریپت حذف نصب فعال سازی ماشین های بیکار"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}اسکریپت نصب مجدد سیستم DD"
		echo -e "${gl_kjlan}4.   ${gl_bai}اسکریپت بوت R Explorer"
		echo -e "${gl_kjlan}5.   ${gl_bai}فعال کردن حالت ورود به سیستم با رمز عبور root"
		echo -e "${gl_kjlan}6.   ${gl_bai}ابزار بازیابی IPv6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			clear
			echo "اسکریپت فعال: استفاده از CPU 10-20% استفاده از حافظه 20%"
			read -e -p "آیا مطمئن هستید که نصب کنید؟ \(y/N\): " choice
			case "$choice" in
			[Yy])

				install_docker

				# 设置默认值
				local DEFAULT_CPU_CORE=1
				local DEFAULT_CPU_UTIL="10-20"
				local DEFAULT_MEM_UTIL=20
				local DEFAULT_SPEEDTEST_INTERVAL=120

				# 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				read -e -p "لطفاً تعداد هسته‌های CPU را وارد کنید [پیش‌فرض: $DEFAULT_CPU_CORE]: " cpu_core
				local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				read -e -p "لطفاً محدوده درصد استفاده CPU را وارد کنید (مثلاً 10-20) [پیش‌فرض: $DEFAULT_CPU_UTIL]: " cpu_util
				local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				read -e -p "لطفاً درصد استفاده حافظه را وارد کنید [پیش‌فرض: $DEFAULT_MEM_UTIL]: " mem_util
				local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				read -e -p "لطفاً فاصله زمانی Speedtest (به ثانیه) را وارد کنید [پیش‌فرض: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
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
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
			echo "نصب مجدد سیستم"
			echo "--------------------------------"
			echo -e "${gl_hong}توجه: ${gl_bai} نصب مجدد خطرناک است و ممکن است اتصال قطع شود. اگر نگران هستید از آن استفاده نکنید. نصب مجدد حدود 15 دقیقه طول می کشد، لطفاً از داده های خود پشتیبان تهیه کنید."
			read -e -p "آیا مطمئن هستید؟ \(y/N\): " choice

			case "$choice" in
			[Yy])
				while true; do
					read -e -p "سیستم مورد نظر برای نصب مجدد را انتخاب کنید: 1. Debian 12 | 2. Ubuntu 20.04 : " sys_choice

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
						echo "انتخاب نامعتبر، لطفاً دوباره وارد کنید."
						;;
					esac
				done

				read -e -p "لطفاً رمز عبور پس از نصب مجدد را وارد کنید: " vpspasswd
				install wget
				bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
				send_stats "甲骨文云重装系统脚本"
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
			echo "این ویژگی توسط jhb ارائه شده است، از او سپاسگزاریم!"
			send_stats "ipv6修复"
			;;
		0)
			kejilion

			;;
		*)
			echo "ورودی نامعتبر! "
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
		echo -e "${gl_lv}محیط نصب شده${gl_bai}  کانتینر: ${gl_lv}$container_count${gl_bai}  تصویر: ${gl_lv}$image_count${gl_bai}  شبکه: ${gl_lv}$network_count${gl_bai}  جلد: ${gl_lv}$volume_count${gl_bai}"
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
			echo -e "${gl_lv}محیط نصب شده${gl_bai}  سایت: $output  پایگاه داده: $db_output"
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
		echo -e "ساخت ایستگاه LDNMP"
		ldnmp_tato
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}1.   ${gl_bai}نصب محیط LDNMP ${gl_huang}★${gl_bai}                           ${gl_huang}2.   ${gl_bai}نصب WordPress ${gl_huang}★${gl_bai}"
		echo -e "${gl_huang}3.   ${gl_bai}نصب انجمن Discuz                           ${gl_huang}4.   ${gl_bai}نصب دسکتاپ کلاود"
		echo -e "${gl_huang}5.   ${gl_bai}نصب ایستگاه فیلم و تلویزیون CMS اپل        ${gl_huang}6.   ${gl_bai}نصب وب‌سایت شارژ یک شاخ"
		echo -e "${gl_huang}7.   ${gl_bai}نصب وب‌سایت انجمن Flarum                   ${gl_huang}8.   ${gl_bai}نصب وب‌سایت وبلاگ سبک Typecho"
		echo -e "${gl_huang}9.   ${gl_bai}نصب پلتفرم اشتراک‌گذاری پیوند LinkStack    ${gl_huang}20.  ${gl_bai}سایت پویا سفارشی"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}21.  ${gl_bai}فقط نصب Nginx ${gl_huang}★${gl_bai}                            ${gl_huang}22.  ${gl_bai}تغییر مسیر سایت"
		echo -e "${gl_huang}23.  ${gl_bai}پروکسی معکوس سایت - IP + پورت ${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}پروکسی معکوس سایت - دامنه"
		echo -e "${gl_huang}25.  ${gl_bai}نصب پلتفرم مدیریت رمز عبور Bitwarden       ${gl_huang}26.  ${gl_bai}نصب وب‌سایت وبلاگ Halo"
		echo -e "${gl_huang}27.  ${gl_bai}نصب تولیدکننده پرامپت نقاشی هوش مصنوعی     ${gl_huang}28.  ${gl_bai}پروکسی معکوس سایت - متعادل‌سازی بار"
		echo -e "${gl_huang}29.  ${gl_bai}ارسال مجدد پروکسی لایه چهارم Stream        ${gl_huang}30.  ${gl_bai}سایت استاتیک سفارشی"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}31.  ${gl_bai}مدیریت داده‌های سایت ${gl_huang}★${gl_bai}                     ${gl_huang}32.  ${gl_bai}پشتیبان‌گیری از تمام داده‌های سایت"
		echo -e "${gl_huang}33.  ${gl_bai}پشتیبان‌گیری از راه دور زمان‌بندی شده      ${gl_huang}34.  ${gl_bai}بازیابی تمام داده‌های سایت"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}35.  ${gl_bai}محافظت از محیط LDNMP                       ${gl_huang}36.  ${gl_bai}بهینه‌سازی محیط LDNMP"
		echo -e "${gl_huang}37.  ${gl_bai}به‌روزرسانی محیط LDNMP                     ${gl_huang}38.  ${gl_bai}حذف محیط LDNMP"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_huang}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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
			webname="Discuz Forum"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند جدول: discuz_"

			;;

		4)
			clear
			# 可道云桌面
			webname="دسکتاپ Keda Cloud"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "رمز عبور: $dbusepasswd"
			echo "نام پایگاه داده: $dbname"
			echo "هاست Redis: redis"

			;;

		5)
			clear
			# 苹果CMS
			webname="سیستم مدیریت محتوای اپل"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند پایگاه داده: mac_"
			echo "------------------------"
			echo "آدرس ورود به پنل مدیریت پس از نصب موفقیت آمیز"
			echo "https://$yuming/vip.php"

			;;

		6)
			clear
			# 独脚数卡
			webname="کارت تک پایی"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "رمز عبور: $dbusepasswd"
			echo ""
			echo "آدرس Redis: redis"
			echo "رمز عبور Redis: به طور پیش فرض خالی بگذارید"
			echo "پورت Redis: 6379"
			echo ""
			echo "آدرس سایت: https://$yuming"
			echo "مسیر ورود به پنل مدیریت: /admin"
			echo "------------------------"
			echo "نام کاربری: admin"
			echo "رمز عبور: admin"
			echo "------------------------"
			echo "اگر در هنگام ورود، خطای قرمز error0 را مشاهده کردید، از دستور زیر استفاده کنید:"
			echo "من هم از پیچیدگی کارت‌های تک‌شاخ عصبانی هستم، این مشکل وجود خواهد داشت!"
			echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

			;;

		7)
			clear
			# flarum论坛
			webname="انجمن Flarum"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند جدول: flarum_"
			echo "اطلاعات مدیر را خودتان تنظیم کنید"

			;;

		8)
			clear
			# typecho
			webname="Typecho"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "رمز عبور: $dbusepasswd"
			echo "نام پایگاه داده: $dbname"

			;;

		9)
			clear
			# LinkStack
			webname="LinkStack"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "رمز عبور: $dbusepasswd"
			;;

		20)
			clear
			webname="وب‌سایت پویا PHP"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo -e "[${gl_huang}1/6${gl_bai}] بارگذاری کد منبع PHP"
			echo "-------------"
			echo "فقط امکان آپلود بسته‌های سورس با فرمت zip وجود دارد، لطفاً بسته سورس را در مسیر /home/web/html/${yuming} قرار دهید"
			read -e -p "همچنین می‌توانید لینک دانلود را وارد کنید، دانلود از راه دور بسته منبع را انجام دهید، با فشردن Enter از دانلود از راه دور صرف نظر کنید: " url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/6${gl_bai}] مسیر index.php"
			echo "-------------"
			# find "$(realpath .)" -name "index.php" -print
			find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

			read -e -p "لطفاً مسیر index.php را وارد کنید، مانند ( /home/web/html/$yuming/wordpress/) : " index_lujing

			sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
			sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}3/6${gl_bai}] لطفا نسخه PHP را انتخاب کنید"
			echo "-------------"
			read -e -p "1. آخرین نسخه php | 2. php 7.4 : " pho_v
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
				echo "انتخاب نامعتبر، لطفاً دوباره وارد کنید."
				;;
			esac

			clear
			echo -e "[${gl_huang}4/6${gl_bai}] نصب افزونه مشخص شده"
			echo "-------------"
			echo "افزونه‌های نصب شده"
			docker exec php php -m

			read -e -p "$(echo -e "نام افزونه‌ای که می‌خواهید نصب کنید را وارد کنید، مانند ${gl_huang}SourceGuardian imap ftp${gl_bai} و غیره. با فشار دادن Enter، نصب رد می‌شود: ")" php_extensions
			if [ -n "$php_extensions" ]; then
				docker exec $PHP_Version install-php-extensions $php_extensions
			fi

			clear
			echo -e "[${gl_huang}5/6${gl_bai}] ویرایش پیکربندی سایت"
			echo "-------------"
			echo "برای ادامه، هر کلیدی را فشار دهید، می‌توانید تنظیمات سایت مانند pseudo-static و غیره را به تفصیل تنظیم کنید"
			read -n 1 -s -r -p ""
			install nano
			nano /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}6/6${gl_bai}] مدیریت پایگاه داده"
			echo "-------------"
			read -e -p "1. من یک سایت جدید ایجاد می‌کنم 2. من یک سایت قدیمی با پشتیبان‌گیری از پایگاه داده دارم: " use_db
			case $use_db in
			1)
				echo
				;;
			2)
				echo "پشتیبان گیری از پایگاه داده باید یک بسته فشرده با پسوند .gz باشد. لطفاً آن را در مسیر /home قرار دهید، از پشتیبان گیری و وارد کردن داده های Baota / 1panel پشتیبانی می کند."
				read -e -p "همچنین می‌توانید لینک دانلود را وارد کنید، دانلود از راه دور داده‌های پشتیبان را انجام دهید، با فشردن Enter از دانلود از راه دور صرف نظر کنید: " url_download_db

				cd /home/
				if [ -n "$url_download_db" ]; then
					wget "$url_download_db"
				fi
				gunzip $(ls -t *.gz | head -n 1)
				latest_sql=$(ls -t *.sql | head -n 1)
				dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname <"/home/$latest_sql"
				echo "داده های جدول وارد شده از پایگاه داده"
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
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند جدول: $prefix"
			echo "اطلاعات ورود مدیر به صورت خودکار تنظیم می‌شود"

			;;

		21)
			ldnmp_install_status_one
			nginx_install_all
			;;

		22)
			clear
			webname="تغییر مسیر سایت"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
			add_yuming
			read -e -p "لطفاً دامنه هدایت را وارد کنید: " reverseproxy
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
				echo "دسترسی IP+پورت به این سرویس مسدود شد"
			else
				ip_address
				block_container_port "$docker_name" "$ipv4_address"
			fi

			;;

		24)
			clear
			webname="پروکسی معکوس - دامنه"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
			add_yuming
			echo -e "فرمت دامنه: ${gl_huang}google.com${gl_bai}"
			read -e -p "لطفاً دامنه پروکسی معکوس خود را وارد کنید: " fandai_yuming
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
			echo "شروع استقرار $webname"
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
			echo "شروع استقرار $webname"
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
			webname="تولیدکننده پرامپت تصویر AI"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			webname="وب‌سایت ایستا"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo -e "[${gl_huang}1/2${gl_bai}] بارگذاری کد منبع استاتیک"
			echo "-------------"
			echo "فقط امکان آپلود بسته‌های سورس با فرمت zip وجود دارد، لطفاً بسته سورس را در مسیر /home/web/html/${yuming} قرار دهید"
			read -e -p "همچنین می‌توانید لینک دانلود را وارد کنید، دانلود از راه دور بسته منبع را انجام دهید، با فشردن Enter از دانلود از راه دور صرف نظر کنید: " url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/2${gl_bai}] مسیر index.html"
			echo "-------------"
			# find "$(realpath .)" -name "index.html" -print
			find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

			read -e -p "لطفاً مسیر index.html را وارد کنید، مانند ( /home/web/html/$yuming/index/) : " index_lujing

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
			echo -e "${gl_huang}در حال پشتیبان‌گیری از $backup_filename ...${gl_bai}"
			cd /home/ && tar czvf "$backup_filename" web

			while true; do
				clear
				echo "فایل پشتیبان ایجاد شد: /home/$backup_filename"
				read -e -p "آیا می‌خواهید داده‌های پشتیبان را به سرور راه دور ارسال کنید؟ \(y/N\): " choice
				case "$choice" in
				[Yy])
					read -e -p "لطفاً IP سرور راه دور را وارد کنید: " remote_ip
					read -e -p "پورت SSH سرور هدف [پیش‌فرض 22]: " TARGET_PORT
					local TARGET_PORT=${TARGET_PORT:-22}
					if [ -z "$remote_ip" ]; then
						echo "خطا: لطفا IP سرور راه دور را وارد کنید."
						continue
					fi
					local latest_tar=$(ls -t /home/*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
						echo "فایل‌ها به دایرکتوری /home سرور راه دور ارسال شد."
					else
						echo "هیچ فایلی برای ارسال پیدا نشد."
					fi
					break
					;;
				[Nn])
					break
					;;
				*)
					echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
					;;
				esac
			done
			;;

		33)
			clear
			send_stats "定时远程备份"
			read -e -p "IP سرور راه دور را وارد کنید: " useip
			read -e -p "رمز عبور سرور راه دور را وارد کنید: " usepasswd

			cd ~
			wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh >/dev/null 2>&1
			chmod +x ${useip}_beifen.sh

			sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
			sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

			echo "------------------------"
			echo "1. پشتیبان‌گیری هفتگی                 2. پشتیبان‌گیری روزانه"
			read -e -p "لطفاً انتخاب خود را وارد کنید: " dingshi

			case $dingshi in
			1)
				check_crontab_installed
				read -e -p "روز هفته را برای پشتیبان‌گیری هفتگی انتخاب کنید (0-6، 0 نشان‌دهنده یکشنبه است): " weekday
				(
					crontab -l
					echo "0 0 * * $weekday ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			2)
				check_crontab_installed
				read -e -p "ساعت پشتیبان‌گیری روزانه را انتخاب کنید (ساعت، 0-23): " hour
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
			echo "پشتیبان‌گیری‌های سایت موجود"
			echo "-------------------------"
			ls -lt /home/*.gz | awk '{print $NF}'
			echo ""
			read -e -p "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

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

				echo -e "${gl_huang}در حال استخراج $filename ...${gl_bai}"
				cd /home/ && tar -xzf "$filename"

				check_port
				install_dependency
				install_docker
				install_certbot
				install_ldnmp
			else
				echo "هیچ بسته‌ای پیدا نشد."
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
				echo "به‌روزرسانی محیط LDNMP"
				echo "------------------------"
				ldnmp_v
				echo "نسخه جدیدی از اجزا یافت شد"
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
				echo "1. به‌روزرسانی Nginx              2. به‌روزرسانی MySQL             3. به‌روزرسانی PHP              4. به‌روزرسانی redis"
				echo "------------------------"
				echo "5. به‌روزرسانی محیط کامل"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
				case $sub_choice in
				1)
					nginx_upgrade

					;;

				2)
					local ldnmp_pods="mysql"
					read -e -p "لطفاً شماره نسخه ${ldnmp_pods} را وارد کنید (مثلاً: 8.0 8.3 8.4 9.0) (فشردن Enter برای دریافت آخرین نسخه): " version
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
					echo "به‌روزرسانی${ldnmp_pods} تکمیل شد"

					;;
				3)
					local ldnmp_pods="php"
					read -e -p "لطفاً شماره نسخه ${ldnmp_pods} را وارد کنید (مثلاً: 7.4 8.0 8.1 8.2 8.3) (برای دریافت آخرین نسخه Enter را بزنید):" version
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
					echo "به‌روزرسانی${ldnmp_pods} تکمیل شد"

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
					echo "به‌روزرسانی${ldnmp_pods} تکمیل شد"

					;;
				5)
					read -e -p "$(echo -e "${gl_huang}نکته: ${gl_bai}کاربرانی که مدت زیادی است محیط را به‌روزرسانی نکرده‌اند، لطفاً با احتیاط محیط LDNMP را به‌روزرسانی کنند، زیرا خطر شکست به‌روزرسانی پایگاه داده وجود دارد. آیا مطمئن هستید که می‌خواهید محیط LDNMP را به‌روزرسانی کنید؟ \(y/N\): ")" choice
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
			read -e -p "$(echo -e "${gl_hong}توصیه اکید: ${gl_bai}ابتدا از تمام داده‌های وب‌سایت پشتیبان‌گیری کنید و سپس محیط LDNMP را حذف نصب کنید. آیا مطمئن هستید که می‌خواهید تمام داده‌های وب‌سایت را حذف کنید؟ \(y/N\): ")" choice
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
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion
			;;

		*)
			echo "ورودی نامعتبر! "
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
			echo -e "بازار برنامه"
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

			echo -e "${gl_kjlan}1.   ${color1}نسخه رسمی Botao Panel                                ${gl_kjlan}2.   ${color2}aaPanel نسخه بین‌المللی Botao"
			echo -e "${gl_kjlan}3.   ${color3}1Panel پنل مدیریت نسل جدید                           ${gl_kjlan}4.   ${color4}NginxProxyManager پنل تجسمی"
			echo -e "${gl_kjlan}5.   ${color5}OpenList برنامه لیست فایل فضای ذخیره‌سازی چندگانه    ${gl_kjlan}6.   ${color6}نسخه وب دسکتاپ از راه دور Ubuntu"
			echo -e "${gl_kjlan}7.   ${color7}پنل نظارت بر VPS Nezha Probe                         ${gl_kjlan}8.   ${color8}پنل دانلود آفلاین BT و مگنتی QB"
			echo -e "${gl_kjlan}9.   ${color9}برنامه سرور ایمیل Poste.io                           ${gl_kjlan}10.  ${color10}سیستم چت آنلاین چند نفره Rocket.Chat"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}11.  ${color11}نرم‌افزار مدیریت پروژه ZenDao                        ${gl_kjlan}12.  ${color12}پلتفرم مدیریت وظایف زمان‌بندی شده Qinglong Panel"
			echo -e "${gl_kjlan}13.  ${color13}Cloudreve فضای ذخیره‌سازی ابری ${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${color14}برنامه مدیریت تصویر Simple Image Bed"
			echo -e "${gl_kjlan}15.  ${color15}سیستم مدیریت چندرسانه‌ای Emby                        ${gl_kjlan}16.  ${color16}پنل تست سرعت Speedtest"
			echo -e "${gl_kjlan}17.  ${color17}نرم‌افزار ضد تبلیغات AdGuard Home                    ${gl_kjlan}18.  ${color18}ONLYOFFICE Office آنلاین"
			echo -e "${gl_kjlan}19.  ${color19}پنل فایروال WAF Leichi                               ${gl_kjlan}20.  ${color20}پنل مدیریت کانتینر Portainer"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}21.  ${color21}نسخه وب VS Code                                      ${gl_kjlan}22.  ${color22}ابزار نظارت Uptime Kuma"
			echo -e "${gl_kjlan}23.  ${color23}یادداشت‌های وب Memos                                 ${gl_kjlan}24.  ${color24}نسخه وب دسکتاپ از راه دور Webtop ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}25.  ${color25}Nextcloud فضای ذخیره‌سازی ابری                       ${gl_kjlan}26.  ${color26}چارچوب مدیریت وظایف زمان‌بندی QD"
			echo -e "${gl_kjlan}27.  ${color27}Dockge پنل مدیریت پشته‌های کانتینری                  ${gl_kjlan}28.  ${color28}ابزار تست سرعت LibreSpeed"
			echo -e "${gl_kjlan}29.  ${color29}SearXNG ایستگاه جستجوی تجمیعی ${gl_huang}★${gl_bai}                      ${gl_kjlan}30.  ${color30}سیستم آلبوم عکس خصوصی PhotoPrism"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}31.  ${color31}Stirling مجموعه ابزارهای PDF                         ${gl_kjlan}32.  ${color32}draw.io نرم‌افزار نمودار آنلاین رایگان ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}33.  ${color33}Sun-Panel پنل ناوبری                                 ${gl_kjlan}34.  ${color34}پلتفرم اشتراک‌گذاری فایل Pingvin Share"
			echo -e "${gl_kjlan}35.  ${color35}دایره دوستان مینیمالیستی                             ${gl_kjlan}36.  ${color36}وب‌سایت تجمیعی چت هوش مصنوعی LobeChat"
			echo -e "${gl_kjlan}37.  ${color37}جعبه ابزار MyIP ${gl_huang}★${gl_bai}                                    ${gl_kjlan}38.  ${color38}Alist مجموعه کامل Xiaoya"
			echo -e "${gl_kjlan}39.  ${color39}Bililive ابزار ضبط پخش زنده                          ${gl_kjlan}40.  ${color40}ابزار اتصال SSH مبتنی بر وب WebSSH"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}41.  ${color41}پنل مدیریت موش                                       ${gl_kjlan}42.  ${color42}ابزار اتصال از راه دور Nexterm"
			echo -e "${gl_kjlan}43.  ${color43}RustDesk دسکتاپ از راه دور (سرور) ${gl_huang}★${gl_bai}                  ${gl_kjlan}44.  ${color44}RustDesk دسکتاپ از راه دور (سرور میانی) ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}45.  ${color45}ایستگاه شتاب‌دهنده Docker                            ${gl_kjlan}46.  ${color46}ایستگاه شتاب‌دهنده GitHub ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}47.  ${color47}نظارت Prometheus                                     ${gl_kjlan}48.  ${color48}Prometheus (نظارت بر هاست)"
			echo -e "${gl_kjlan}49.  ${color49}Prometheus (نظارت بر کانتینر)                        ${gl_kjlan}50.  ${color50}ابزار نظارت بر موجودی"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}51.  ${color51}PVE پنل مدیریت جوجه‌ها                               ${gl_kjlan}52.  ${color52}DPanel پنل مدیریت کانتینر"
			echo -e "${gl_kjlan}53.  ${color53}Llama3 مدل بزرگ هوش مصنوعی چت                        ${gl_kjlan}54.  ${color54}AMH پنل مدیریت ساخت وب‌سایت هاست"
			echo -e "${gl_kjlan}55.  ${color55}FRP تونل‌زنی داخلی (سرور) ${gl_huang}★${gl_bai}                          ${gl_kjlan}56.  ${color56}FRP تونل‌زنی داخلی (مشتری) ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}57.  ${color57}DeepSeek مدل بزرگ هوش مصنوعی چت                      ${gl_kjlan}58.  ${color58}Dify پایگاه دانش مدل بزرگ ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}59.  ${color59}NewAPI مدیریت دارایی مدل بزرگ                        ${gl_kjlan}60.  ${color60}JumpServer ماشین‌برج منبع باز"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}61.  ${color61}سرور ترجمه آنلاین                                    ${gl_kjlan}62.  ${color62}RAGFlow پایگاه دانش مدل بزرگ"
			echo -e "${gl_kjlan}63.  ${color63}Open WebUI پلتفرم هوش مصنوعی میزبانی‌شده ${gl_huang}★${gl_bai}           ${gl_kjlan}64.  ${color64}جعبه ابزار it-tools"
			echo -e "${gl_kjlan}65.  ${color65}پلتفرم گردش کار خودکار n8n ${gl_huang}★${gl_bai}                         ${gl_kjlan}66.  ${color66}ابزار دانلود ویدیو yt-dlp"
			echo -e "${gl_kjlan}67.  ${color67}ابزار مدیریت DNS پویا DDNS-GO ${gl_huang}★${gl_bai}                      ${gl_kjlan}68.  ${color68}پلتفرم مدیریت گواهی ALLinSSL"
			echo -e "${gl_kjlan}69.  ${color69}ابزار انتقال فایل SFTPGo                             ${gl_kjlan}70.  ${color70}چارچوب ربات چت AstrBot"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}71.  ${color71}سرور موسیقی خصوصی Navidrome                          ${gl_kjlan}72.  ${color72}مدیریت کننده رمز عبور Bitwarden ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}73.  ${color73}LibreTV فیلم و تلویزیون خصوصی                        ${gl_kjlan}74.  ${color74}MoonTV فیلم و تلویزیون خصوصی"
			echo -e "${gl_kjlan}75.  ${color75}Melody جادوگر موسیقی                                 ${gl_kjlan}76.  ${color76}بازی های قدیمی DOS آنلاین"
			echo -e "${gl_kjlan}77.  ${color77}ابزار دانلود آفلاین Thunder                          ${gl_kjlan}78.  ${color78}سیستم مدیریت اسناد هوشمند PandaWiki"
			echo -e "${gl_kjlan}79.  ${color79}نظارت بر سرور Beszel                                 ${gl_kjlan}80.  ${color80}مدیریت نشانک Linkwarden"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}81.  ${color81}Jitsi Meet کنفرانس ویدیویی                           ${gl_kjlan}82.  ${color82}GPT-Load پروکسی شفاف هوش مصنوعی با کارایی بالا"
			echo -e "${gl_kjlan}83.  ${color83}Komari ابزار نظارت بر سرور                           ${gl_kjlan}84.  ${color84}ابزار مدیریت مالی شخصی Wallos"
			echo -e "${gl_kjlan}85.  ${color85}Immich مدیر عکس و ویدیو                              ${gl_kjlan}86.  ${color86}سیستم مدیریت رسانه Jellyfin"
			echo -e "${gl_kjlan}87.  ${color87}SyncTV ابزار تماشای فیلم با هم                       ${gl_kjlan}88.  ${color88}پلتفرم پخش زنده میزبانی شده Owncast"
			echo -e "${gl_kjlan}89.  ${color89}FileCodeBox تحویل سریع فایل                          ${gl_kjlan}90.  ${color90}Matrix پروتکل چت غیرمتمرکز"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}91.  ${color91}Gitea مخزن کد خصوصی                                  ${gl_kjlan}92.  ${color92}FileBrowser مدیر فایل"
			echo -e "${gl_kjlan}93.  ${color93}Dufs سرور فایل ایستا مینیمالیستی                     ${gl_kjlan}94.  ${color94}Gopeed ابزار دانلود با سرعت بالا"
			echo -e "${gl_kjlan}95.  ${color95}Paperless پلتفرم مدیریت اسناد                        ${gl_kjlan}96.  ${color96}2FAuth احراز هویت دو مرحله ای میزبانی شده"
			echo -e "${gl_kjlan}97.  ${color97}WireGuard شبکه سازی (سرور)                           ${gl_kjlan}98.  ${color98}WireGuard شبکه سازی (کلاینت) "
			echo -e "${gl_kjlan}99.  ${color99}DSM ماشین مجازی Synology                             ${gl_kjlan}100. ${color100}Syncthing ابزار همگام سازی فایل نقطه به نقطه"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}101. ${color101}ابزار تولید ویدیو هوش مصنوعی                         ${gl_kjlan}102. ${color102}VoceChat سیستم چت آنلاین چند نفره"
			echo -e "${gl_kjlan}103. ${color103}Umami ابزار آمار وب سایت                             ${gl_kjlan}104. ${color104}Stream ابزار انتقال پروکسی لایه چهارم"
			echo -e "${gl_kjlan}105. ${color105}یادداشت‌های سی‌یوان                                  ${gl_kjlan}106. ${color106}ابزار تخته سفید متن‌باز Drawnix"
			echo -e "${gl_kjlan}107. ${color107}جستجوی PanSou فضای ابری"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}b.   ${gl_bai}پشتیبان‌گیری از تمام داده‌های برنامه                 ${gl_kjlan}r.   ${gl_bai}بازگردانی تمام داده‌های برنامه"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
			echo -e "${gl_kjlan}------------------------${gl_bai}"
			read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
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

			local docker_describe="یک پنل پروکسی معکوس Nginx که از افزودن دسترسی به نام دامنه پشتیبانی نمی‌کند."
			local docker_url="معرفی وب سایت رسمی: https://nginxproxymanager.com/"
			local docker_use="echo \"نام کاربری اولیه: admin@example.com\""
			local docker_passwd="echo "رمز عبور اولیه: changeme""
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

			local docker_describe="یک برنامه لیست فایل که از چندین فضای ذخیره‌سازی پشتیبانی می‌کند، از مرور وب و WebDAV پشتیبانی می‌کند و توسط gin و Solidjs پشتیبانی می‌شود"
			local docker_url="معرفی وب سایت رسمی: https://github.com/OpenListTeam/OpenList"
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

				read -e -p "تنظیم نام کاربری ورود:" admin
				read -e -p "تنظیم رمز عبور ورود:" admin_password
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

			local docker_describe="Webtop بر اساس کانتینر Ubuntu است. اگر IP قابل دسترسی نیست، لطفاً دسترسی به نام دامنه را اضافه کنید."
			local docker_url="معرفی وب سایت رسمی: https://docs.linuxserver.io/images/docker-webtop/"
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
				echo -e "نظارت نِتونا $check_docker $update_status"
				echo "ابزار نظارت و نگهداری سرور متن‌باز، سبک و آسان"
				echo "مستندات راه‌اندازی وب‌سایت رسمی: https://nezha.wiki/guide/dashboard.html"
				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1. استفاده"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید: " choice

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

			local docker_describe="سرویس دانلود آفلاین BT و مگنتی qBittorrent"
			local docker_url="معرفی وب سایت رسمی: https://hub.docker.com/r/linuxserver/qbittorrent"
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
				echo -e "سرویس پُست $check_docker $update_status"
				echo "Poste.io یک راه حل سرور ایمیل متن‌باز است،"
				echo "معرفی ویدئویی: https://youtu.be/KeqlzO9mPn0"

				echo ""
				echo "بررسی پورت"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
					echo -e "${gl_lv}پورت $port در حال حاضر در دسترس است${gl_bai}"
				else
					echo -e "${gl_hong}پورت $port در حال حاضر در دسترس نیست${gl_bai}"
				fi
				echo ""

				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					yuming=$(cat /home/docker/mail.txt)
					echo "آدرس بازدید: "
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. نصب                  2. به‌روزرسانی                  3. حذف"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید: " choice

				case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "لطفاً دامنه ایمیل را تنظیم کنید، به عنوان مثال mail.yuming.com:" yuming
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
					echo "برای ادامه، هر کلیدی را فشار دهید..."
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
					echo "Poste.io با موفقیت نصب شد"
					echo "------------------------"
					echo "می‌توانید با آدرس زیر به Poste.io دسترسی پیدا کنید: "
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
					echo "Poste.io با موفقیت نصب شد"
					echo "------------------------"
					echo "می‌توانید با آدرس زیر به Poste.io دسترسی پیدا کنید: "
					echo "https://$yuming"
					echo ""
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "برنامه حذف شد"
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
			local app_name="سیستم چت Rocket.Chat"
			local app_text="Rocket.Chat یک پلتفرم ارتباطی تیمی منبع باز است که از چت فوری، تماس صوتی/تصویری، اشتراک‌گذاری فایل و ویژگی‌های متعدد دیگر پشتیبانی می‌کند."
			local app_url="معرفی رسمی: https://www.rocket.chat/"
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "Rocket.Chat با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "برنامه حذف شد"
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

			local docker_describe="ZenTao یک نرم افزار مدیریت پروژه همه منظوره است"
			local docker_url="معرفی وب‌سایت: https://www.zentao.net/"
			local docker_use="echo \"نام کاربری اولیه: admin\""
			local docker_passwd="echo "رمز عبور اولیه: 123456""
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

			local docker_describe="پنل Qinglong یک پلتفرم مدیریت وظایف زمانبندی شده است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;
		13 | cloudreve)

			local app_id="13"
			local app_name="درایو شبکه Cloudreve"
			local app_text="Cloudreve یک سیستم هارد دیسک شبکه است که از چندین فضای ذخیره‌سازی ابری پشتیبانی می‌کند"
			local app_url="معرفی ویدئویی: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "برنامه حذف شد"
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

			local docker_describe="Simple Image Bed یک برنامه ساده هاستینگ تصویر است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/icret/EasyImages2.0"
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

			local docker_describe="Emby یک نرم افزار سرور رسانه با معماری ارباب-برده است که می تواند برای سازماندهی فیلم ها و صداها در سرور استفاده شود و صدا و فیلم را به دستگاه های کلاینت منتقل کند"
			local docker_url="معرفی وب‌سایت: https://emby.media/"
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

			local docker_describe="پنل Speedtest یک ابزار تست سرعت VPS با عملکردهای تست متعدد است و می تواند ترافیک ورودی و خروجی VPS را به صورت بلادرنگ نظارت کند"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/wikihost-opensource/als"
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

			local docker_describe="AdGuard Home یک نرم افزار مسدود کننده تبلیغات و ضد ردیابی در کل شبکه است و در آینده چیزی فراتر از یک سرور DNS خواهد بود."
			local docker_url="معرفی وب‌سایت: https://hub.docker.com/r/adguard/adguardhome"
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

			local docker_describe="ONLYOFFICE یک ابزار Office آنلاین منبع باز است، بسیار قدرتمند!"
			local docker_url="معرفی وب‌سایت: https://www.onlyoffice.com/"
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
				echo -e "سرویس لِی‌چی $check_docker"
				echo "LeiChi یک پنل برنامه فایروال وب WAF است که توسط Longting Technology توسعه یافته است و می‌تواند وب‌سایت‌ها را برای دفاع خودکار معکوس کند"
				echo "معرفی ویدیو: https://youtu.be/_nkZXhnm68Y"
				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. نصب            2. به‌روزرسانی            3. بازنشانی رمز عبور            4. حذف"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید: " choice

				case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "پنل WAF LeiChi با موفقیت نصب شد"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "پنل WAF LeiChi با موفقیت به‌روزرسانی شد"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "اگر دایرکتوری نصب پیش‌فرض است، پروژه اکنون حذف شده است. اگر دایرکتوری نصب سفارشی است، باید به صورت دستی در دایرکتوری نصب اجرا کنید: "
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

			local docker_describe="Portainer یک پنل مدیریت کانتینر Docker سبک وزن است"
			local docker_url="معرفی وب‌سایت: https://www.portainer.io/"
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

			local docker_describe="VS Code یک ابزار کدنویسی آنلاین قدرتمند است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/coder/code-server"
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

			local docker_describe="Uptime Kuma یک ابزار نظارت سلف هاست شده و آسان برای استفاده است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/louislam/uptime-kuma"
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

			local docker_describe="Memos یک مرکز یادداشت سبک وزن و سلف هاست شده است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/usememos/memos"
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

				read -e -p "تنظیم نام کاربری ورود:" admin
				read -e -p "تنظیم رمز عبور ورود:" admin_password
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

			local docker_describe="Webtop بر اساس کانتینر Alpine چینی است. اگر IP قابل دسترسی نیست، لطفاً دسترسی به نام دامنه را اضافه کنید."
			local docker_url="معرفی وب سایت رسمی: https://docs.linuxserver.io/images/docker-webtop/"
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

			local docker_describe="Nextcloud با بیش از 400000 استقرار، محبوب‌ترین پلتفرم همکاری محتوای محلی است که می‌توانید دانلود کنید"
			local docker_url="معرفی وب‌سایت: https://nextcloud.com/"
			local docker_use="echo \"نام کاربری: nextcloud  رمز عبور: $rootpasswd\""
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

			local docker_describe="QD یک فریم‌ورک خودکار برای اجرای زمان‌بندی شده درخواست‌های HTTP است"
			local docker_url="معرفی وب سایت رسمی: https://qd-today.github.io/qd/"
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

			local docker_describe="Dockge یک پنل مدیریت بصری برای کانتینرهای Docker Compose است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/louislam/dockge"
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

			local docker_describe="LibreSpeed یک ابزار تست سرعت سبک وزن مبتنی بر Javascript است که آماده استفاده است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/librespeed/speedtest"
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

			local docker_describe="SearXNG یک سایت موتور جستجوی خصوصی و حفظ حریم خصوصی است"
			local docker_url="معرفی وب‌سایت: https://hub.docker.com/r/alandoyle/searxng"
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

			local docker_describe="PhotoPrism یک سیستم آلبوم عکس خصوصی بسیار قدرتمند است"
			local docker_url="معرفی وب‌سایت: https://www.photoprism.app/"
			local docker_use="echo \"نام کاربری: admin  رمز عبور: $rootpasswd\""
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

			local docker_describe="این یک ابزار قدرتمند برای کار با PDF مبتنی بر وب است که با استفاده از Docker، به شما امکان می‌دهد عملیات مختلفی مانند تقسیم و ادغام، تبدیل، سازماندهی مجدد، افزودن تصاویر، چرخش، فشرده‌سازی و غیره را روی فایل‌های PDF انجام دهید."
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
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

			local docker_describe="این یک نرم افزار قدرتمند برای ترسیم نمودار است. نقشه های ذهنی، نمودارهای توپولوژیکی و فلوچارت ها را می توان ترسیم کرد"
			local docker_url="معرفی وب‌سایت: https://www.drawio.com/"
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

			local docker_describe="Sun-Panel سرور، پنل ناوبری NAS، صفحه اصلی، صفحه اصلی مرورگر"
			local docker_url="معرفی وب سایت رسمی: https://doc.sun-panel.top/"
			local docker_use="echo \"نام کاربری: admin@sun.cc  رمز عبور: 12345678\""
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

			local docker_describe="Pingvin Share یک پلتفرم اشتراک گذاری فایل خود میزبان است که جایگزینی برای WeTransfer است"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/stonith404/pingvin-share"
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

			local docker_describe="دایره دوستان مینیمالیستی، شبیه به دایره دوستان WeChat، زندگی زیبای خود را ثبت کنید"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use="echo \"نام کاربری: admin  رمز عبور: a123456\""
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

			local docker_describe="LobeChat مدل‌های بزرگ هوش مصنوعی اصلی در بازار را جمع‌آوری می‌کند، از جمله ChatGPT/Claude/Gemini/Groq/Ollama"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/lobehub/lobe-chat"
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

			local docker_describe="این یک جعبه ابزار IP چند منظوره است که می تواند اطلاعات IP و اتصال خود را مشاهده کند و آن را در یک پنل وب ارائه دهد"
			local docker_url="معرفی وب سایت رسمی: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README.md"
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

			local docker_describe="Bililive یک ابزار ضبط پخش زنده است که از پلتفرم‌های پخش زنده متعددی پشتیبانی می‌کند"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
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

			local docker_describe="ابزار آنلاین ساده برای اتصال SSH و SFTP"
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/Jrohy/webssh"
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

			local docker_describe="Nexterm یک ابزار قدرتمند آنلاین برای اتصال SSH/VNC/RDP است."
			local docker_url="معرفی وب‌سایت: ${gh_proxy}github.com/gnmyt/Nexterm"
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

			local docker_describe="RustDesk یک دسکتاپ ریموت متن باز (سرور) است، شبیه به سرور خصوصی خود Sunflower."
			local docker_url="معرفی وب سایت رسمی: https://rustdesk.com/"
			local docker_use="docker logs hbbs"
			local docker_passwd="echo "لطفاً IP و کلید خود را یادداشت کنید، زیرا در کلاینت دسکتاپ از راه دور استفاده می شود. برای نصب رله به گزینه 44 بروید!""
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

			local docker_describe="RustDesk یک دسکتاپ ریموت متن باز (سرور واسط) است، شبیه به سرور خصوصی خود Sunflower."
			local docker_url="معرفی وب سایت رسمی: https://rustdesk.com/"
			local docker_use="echo \"برای دانلود کلاینت دسکتاپ راه دور به وب سایت رسمی بروید: https://rustdesk.com/\""
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

			local docker_describe="Docker Registry یک سرویس برای ذخیره و توزیع تصاویر Docker است."
			local docker_url="معرفی وب‌سایت: https://hub.docker.com/_/registry"
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

			local docker_describe="GHProxy که با Go پیاده‌سازی شده است، برای تسریع در واکشی مخازن Github در برخی مناطق استفاده می‌شود."
			local docker_url="معرفی وب‌سایت: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		47 | prometheus | grafana)

			local app_id="47"
			local app_name="نظارت Prometheus"
			local app_text="سیستم نظارت سازمانی Prometheus+Grafana"
			local app_url="معرفی وب‌سایت رسمی: https://prometheus.io"
			local docker_name="grafana"
			local docker_port="8047"
			local app_size="2"

			docker_app_install() {
				prometheus_install
				clear
				ip_address
				echo "با موفقیت نصب شد"
				check_docker_app_ip
				echo "نام کاربری و رمز عبور اولیه هر دو: admin"
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
				echo "برنامه حذف شد"
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

			local docker_describe="این یک جزء جمع‌آوری داده‌های هاست برای Prometheus است، لطفاً آن را روی هاست تحت نظارت مستقر کنید."
			local docker_url="معرفی وب‌سایت: https://github.com/prometheus/node_exporter"
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

			local docker_describe="این یک جزء جمع‌آوری داده‌های کانتینر Prometheus است، لطفاً آن را روی هاست تحت نظارت مستقر کنید."
			local docker_url="معرفی وب‌سایت: https://github.com/google/cadvisor"
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

			local docker_describe="این یک ابزار کوچک برای تشخیص تغییرات وب‌سایت، نظارت بر موجودی و اعلان‌ها است."
			local docker_url="معرفی وب‌سایت: https://github.com/dgtlmoon/changedetection.io"
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

			local docker_describe="سیستم داشبورد تجسم Docker، ارائه عملکرد کامل مدیریت Docker."
			local docker_url="معرفی وب‌سایت: https://github.com/donknap/dpanel"
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

			local docker_describe="Open WebUI یک فریم‌ورک وب برای مدل‌های زبانی بزرگ است که به مدل زبانی بزرگ جدید Llama3 متصل می‌شود."
			local docker_url="معرفی وب‌سایت: https://github.com/open-webui/open-webui"
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

			local docker_describe="Open WebUI یک فریم‌ورک وب برای مدل‌های زبانی بزرگ است که به مدل زبانی بزرگ جدید DeepSeek R1 متصل می‌شود."
			local docker_url="معرفی وب‌سایت: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		58 | dify)
			local app_id="58"
			local app_name="پایگاه دانش Dify"
			local app_text="یک پلتفرم توسعه برنامه منبع باز برای مدل‌های زبانی بزرگ (LLM) است. داده‌های آموزشی خود میزبانی‌شده برای تولید هوش مصنوعی استفاده می‌شوند"
			local app_url="وب سایت رسمی: https://docs.dify.ai/"
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
				echo "با موفقیت نصب شد"
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
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		59 | new-api)
			local app_id="59"
			local app_name="NewAPI"
			local app_text="دروازه مدل‌های بزرگ نسل جدید و سیستم مدیریت دارایی هوش مصنوعی"
			local app_url="وب‌سایت رسمی: https://github.com/Calcium-Ion/new-api"
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
				echo "با موفقیت نصب شد"
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		60 | jms)

			local app_id="60"
			local app_name="JumpServer ماشین استحکام منبع باز"
			local app_text="یک ابزار مدیریت دسترسی ویژه (PAM) منبع باز است، این برنامه پورت 80 را اشغال می‌کند و از افزودن دامنه برای دسترسی پشتیبانی نمی‌کند"
			local app_url="معرفی رسمی: https://github.com/jumpserver/jumpserver"
			local docker_name="jms_web"
			local docker_port="80"
			local app_size="2"

			docker_app_install() {
				curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
				clear
				echo "با موفقیت نصب شد"
				check_docker_app_ip
				echo "نام کاربری اولیه: admin"
				echo "رمز عبور اولیه: ChangeMe"
			}

			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "برنامه به‌روزرسانی شد"
			}

			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "برنامه حذف شد"
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

			local docker_describe="API ترجمه ماشینی رایگان و متن‌باز، کاملاً خود میزبانی شده است، موتور ترجمه آن توسط کتابخانه متن‌باز Argos Translate ارائه می‌شود."
			local docker_url="معرفی وب‌سایت: https://github.com/LibreTranslate/LibreTranslate"
			local docker_use=""
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		62 | ragflow)
			local app_id="62"
			local app_name="پایگاه دانش RAGFlow"
			local app_text="موتور RAG (تولید افزوده با بازیابی) منبع باز بر اساس درک عمیق سند"
			local app_url="وب‌سایت رسمی: https://github.com/infiniflow/ragflow"
			local docker_name="ragflow-server"
			local docker_port="8062"
			local app_size="8"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/infiniflow/ragflow.git && cd ragflow/docker
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
				clear
				echo "با موفقیت نصب شد"
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
				echo "برنامه حذف شد"
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

			local docker_describe="Open WebUI یک فریم‌ورک وب برای مدل‌های زبانی بزرگ است، نسخه ساده‌شده رسمی، از اتصال API مدل‌های بزرگ پشتیبانی می‌کند."
			local docker_url="معرفی وب‌سایت: https://github.com/open-webui/open-webui"
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

			local docker_describe="ابزاری بسیار مفید برای توسعه‌دهندگان و متخصصان IT."
			local docker_url="معرفی وب‌سایت: https://github.com/CorentinTh/it-tools"
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

			local docker_describe="یک پلتفرم گردش کار خودکار قدرتمند است."
			local docker_url="معرفی وب‌سایت: https://github.com/n8n-io/n8n"
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

			local docker_describe="به طور خودکار IP عمومی شما (IPv4/IPv6) را در زمان واقعی به ارائه‌دهندگان خدمات DNS بزرگ به‌روزرسانی می‌کند و تجزیه دامنه پویا را امکان‌پذیر می‌سازد."
			local docker_url="معرفی وب‌سایت: https://github.com/jeessy2/ddns-go"
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

			local docker_describe="پلتفرم مدیریت خودکار گواهی SSL رایگان و متن‌باز."
			local docker_url="معرفی وب‌سایت: https://allinssl.com"
			local docker_use="echo \"ورودی امن: /allinssl\""
			local docker_passwd="echo "نام کاربری: allinssl رمز عبور: allinssldocker""
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

			local docker_describe="ابزار انتقال فایل SFTP FTP WebDAV در هر زمان و هر مکان، رایگان و متن‌باز."
			local docker_url="معرفی وب‌سایت: https://sftpgo.com/"
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

			local docker_describe="فریم‌ورک ربات چت هوش مصنوعی متن‌باز، پشتیبانی از اتصال مدل‌های بزرگ هوش مصنوعی به وی‌چت، QQ، TG."
			local docker_url="معرفی وب‌سایت: https://astrbot.app/"
			local docker_use="echo \"نام کاربری: astrbot  رمز عبور: astrbot\""
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

			local docker_describe="یک سرور پخش رسانه‌ای موسیقی سبک و با کارایی بالا است."
			local docker_url="معرفی وب‌سایت: https://www.navidrome.org/"
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

			local docker_describe="یک مدیر رمز عبور که می‌توانید داده‌های خود را کنترل کنید."
			local docker_url="معرفی وب‌سایت: https://bitwarden.com/"
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

				read -e -p "تنظیم رمز عبور ورود به LibreTV:" app_passwd

				docker run -d \
					--name libretv \
					--restart=always \
					-p ${docker_port}:8080 \
					-e PASSWORD=${app_passwd} \
					bestzwei/libretv:latest

			}

			local docker_describe="پلتفرم رایگان جستجو و تماشای آنلاین ویدیو"
			local docker_url="معرفی وب‌سایت: https://github.com/LibreSpark/LibreTV"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		74 | moontv)

			local app_id="74"

			local app_name="moontv فیلم و تلویزیون خصوصی"
			local app_text="پلتفرم رایگان جستجو و تماشای آنلاین ویدیو"
			local app_url="معرفی ویدئویی: https://github.com/MoonTechLab/LunaTV"
			local docker_name="moontv-core"
			local docker_port="8074"
			local app_size="2"

			docker_app_install() {
				read -e -p "تنظیم نام کاربری ورود:" admin
				read -e -p "تنظیم رمز عبور ورود:" admin_password
				read -e -p "وارد کردن کد مجوز:" shouquanma

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
				echo "با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/moontv/ && docker compose down --rmi all
				cd /home/docker/moontv/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/moontv/ && docker compose down --rmi all
				rm -rf /home/docker/moontv
				echo "برنامه حذف شد"
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

			local docker_describe="جن موسیقی شما، با هدف کمک به شما در مدیریت بهتر موسیقی."
			local docker_url="معرفی وب‌سایت: https://github.com/foamzou/melody"
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

			local docker_describe="یک وب‌سایت مجموعه بازی‌های DOS چینی است."
			local docker_url="معرفی وب‌سایت: https://github.com/rwv/chinese-dos-games"
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

				read -e -p "تنظیم نام کاربری ورود:" app_use
				read -e -p "تنظیم رمز عبور ورود:" app_passwd

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

			local docker_describe="Xunlei ابزار دانلود سریع BT و مگنتی آفلاین شما."
			local docker_url="معرفی وب‌سایت: https://github.com/cnk3x/xunlei"
			local docker_use="echo "ورود به تلفن همراه از طریق Xunlei، سپس وارد کردن کد دعوت، کد دعوت: 迅雷牛通""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		78 | PandaWiki)

			local app_id="78"
			local app_name="PandaWiki"
			local app_text="PandaWiki یک سیستم مدیریت اسناد هوشمند منبع باز مبتنی بر مدل‌های بزرگ هوش مصنوعی است، اکیداً توصیه می‌شود که پورت سفارشی را مستقر نکنید."
			local app_url="معرفی رسمی: https://github.com/chaitin/PandaWiki"
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

			local docker_describe="Beszel نظارت آسان و کاربردی بر سرور."
			local docker_url="معرفی وب سایت رسمی: https://beszel.dev/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		80 | linkwarden)

			local app_id="80"
			local app_name="مدیریت بوکمارک linkwarden"
			local app_text="یک پلتفرم مدیریت نشانک‌های خود میزبانی‌شده منبع باز که از برچسب‌ها، جستجو و همکاری تیمی پشتیبانی می‌کند."
			local app_url="وب‌سایت رسمی: https://linkwarden.app/"
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
				echo "با موفقیت نصب شد"
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
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		81 | jitsi)
			local app_id="81"
			local app_name="کنفرانس ویدیویی JitsiMeet"
			local app_text="یک راه حل امن کنفرانس ویدیویی منبع باز که از کنفرانس‌های آنلاین چند نفره، اشتراک‌گذاری صفحه نمایش و ارتباط رمزگذاری شده پشتیبانی می‌کند."
			local app_url="وب‌سایت رسمی: https://jitsi.org/"
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
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		82 | gpt-load)

			local app_id="82"
			local docker_name="gpt-load"
			local docker_img="tbphp/gpt-load:latest"
			local docker_port=8082

			docker_rum() {

				read -e -p "تنظیم کلید ورود به ${docker_name} (ترکیبی از حروف و اعداد که با sk شروع می شود)، به عنوان مثال: sk-159kejilionyyds163:" app_passwd

				mkdir -p /home/docker/gpt-load &&
					docker run -d --name gpt-load \
						-p ${docker_port}:3001 \
						-e AUTH_KEY=${app_passwd} \
						-v "/home/docker/gpt-load/data":/app/data \
						tbphp/gpt-load:latest

			}

			local docker_describe="سرویس پروکسی شفاف رابط کاربری هوش مصنوعی با کارایی بالا."
			local docker_url="معرفی وب‌سایت: https://www.gpt-load.com/"
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

			local docker_describe="ابزار نظارت بر سرور خود میزبانی شده و سبک وزن"
			local docker_url="معرفی وب‌سایت: https://github.com/komari-monitor/komari/tree/main"
			local docker_use="echo "نام کاربری پیش فرض: admin رمز عبور پیش فرض: 1212156""
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

			local docker_describe="ردیاب اشتراک شخصی منبع باز، برای مدیریت مالی"
			local docker_url="معرفی وب‌سایت: https://github.com/ellite/Wallos"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		85 | immich)

			local app_id="85"
			local app_name="مدیر تصاویر/فیلم‌های Immich"
			local app_text="راه حل مدیریت عکس و فیلم خود میزبانی‌شده با کارایی بالا."
			local app_url="معرفی وب‌سایت رسمی: https://github.com/immich-app/immich"
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip

			}

			docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				rm -rf /home/docker/${docker_name}
				echo "برنامه حذف شد"
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

			local docker_describe="یک نرم افزار سرور رسانه ای منبع باز است"
			local docker_url="معرفی وب‌سایت: https://jellyfin.org/"
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

			local docker_describe="برنامه ای برای تماشای فیلم و پخش زنده از راه دور با هم. این امکانات تماشای همزمان، پخش زنده، چت و غیره را فراهم می کند"
			local docker_url="معرفی وب‌سایت: https://github.com/synctv-org/synctv"
			local docker_use="echo "نام کاربری و رمز عبور اولیه: root پس از ورود، رمز عبور ورود را در اسرع وقت تغییر دهید""
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

			local docker_describe="پلتفرم پخش زنده منبع باز و رایگان"
			local docker_url="معرفی وب‌سایت: https://owncast.online"
			local docker_use="echo "برای دسترسی به صفحه مدیریت، /admin را به انتهای آدرس اضافه کنید""
			local docker_passwd="echo "نام کاربری اولیه: admin رمز عبور اولیه: abc123 پس از ورود، رمز عبور ورود را در اسرع وقت تغییر دهید""
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

			local docker_describe="به اشتراک گذاری متن و اسناد رمزگذاری شده به صورت ناشناس، مانند تحویل گرفتن بسته"
			local docker_url="معرفی وب‌سایت: https://github.com/vastsa/FileCodeBox"
			local docker_use="echo "برای دسترسی به صفحه مدیریت، /#/admin را به انتهای آدرس اضافه کنید""
			local docker_passwd="echo "رمز عبور مدیر: FileCodeBox2023""
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

				echo "ایجاد کاربر یا مدیر اولیه. لطفاً نام کاربری و رمز عبور و همچنین اینکه آیا مدیر است را تنظیم کنید."
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

			local docker_describe="Matrix یک پروتکل چت غیرمتمرکز است"
			local docker_url="معرفی وب‌سایت: https://matrix.org/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		91 | gitea)

			local app_id="91"

			local app_name="مخزن کد خصوصی Gitea"
			local app_text="پلتفرم میزبانی کد نسل جدید رایگان که تجربه کاربری نزدیک به GitHub را ارائه می‌دهد."
			local app_url="معرفی ویدئویی: https://github.com/go-gitea/gitea"
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/gitea/ && docker compose down --rmi all
				cd /home/docker/gitea/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/gitea/ && docker compose down --rmi all
				rm -rf /home/docker/gitea
				echo "برنامه حذف شد"
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

			local docker_describe="یک مدیر فایل مبتنی بر وب است"
			local docker_url="معرفی وب‌سایت: https://filebrowser.org/"
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

			local docker_describe="سرور فایل استاتیک مینیمالیستی، پشتیبانی از آپلود و دانلود"
			local docker_url="معرفی وب‌سایت: https://github.com/sigoden/dufs"
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

				read -e -p "تنظیم نام کاربری ورود:" app_use
				read -e -p "تنظیم رمز عبور ورود:" app_passwd

				docker run -d \
					--name ${docker_name} \
					--restart=always \
					-v /home/docker/${docker_name}/downloads:/app/Downloads \
					-v /home/docker/${docker_name}/storage:/app/storage \
					-p ${docker_port}:9999 \
					${docker_img} -u ${app_use} -p ${app_passwd}

			}

			local docker_describe="ابزار دانلود توزیع شده با سرعت بالا، پشتیبانی از پروتکل های مختلف"
			local docker_url="معرفی وب‌سایت: https://github.com/GopeedLab/gopeed"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		95 | paperless)

			local app_id="95"

			local app_name="پلتفرم مدیریت اسناد Paperless"
			local app_text="سیستم مدیریت اسناد الکترونیکی متن‌باز، که هدف اصلی آن دیجیتالی کردن و مدیریت اسناد کاغذی شما است."
			local app_url="معرفی ویدئویی: https://docs.paperless-ngx.com/"
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/paperless/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/paperless/ && docker compose down --rmi all
				rm -rf /home/docker/paperless
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		96 | 2fauth)

			local app_id="96"

			local app_name="احراز هویت دو مرحله‌ای خود میزبانی‌شده 2FAuth"
			local app_text="مدیریت حساب و تولید کد تأیید برای احراز هویت دو مرحله‌ای (2FA) با میزبانی خود."
			local app_url="وب‌سایت رسمی: https://github.com/Bubka/2FAuth"
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/2fauth/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/2fauth/ && docker compose down --rmi all
				rm -rf /home/docker/2fauth
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		97 | wgs)

			local app_id="97"
			local docker_name="wireguard"
			local docker_img="lscr.io/linuxserver/wireguard:latest"
			local docker_port=8097

			docker_rum() {

				read -e -p "请输入组网的客户端数量 (默认 5): " COUNT
				COUNT=${COUNT:-5}
				read -e -p "请输入 WireGuard 网段 (默认 10.13.13.0): " NETWORK
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
				echo -e "${gl_huang}پیکربندی QR Code تمام کلاینت‌ها: ${gl_bai}"
				docker exec -it wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
				sleep 2
				echo
				echo -e "${gl_huang}کد پیکربندی تمام کلاینت‌ها: ${gl_bai}"
				docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
				sleep 2
				echo -e "${gl_lv}${COUNT}خروجی تمام پیکربندی‌های کلاینت، روش استفاده به شرح زیر است: ${gl_bai}"
				echo -e "${gl_lv}1. دانلود برنامه wg در تلفن همراه، اسکن QR Code بالا، برای اتصال سریع به شبکه${gl_bai}"
				echo -e "${gl_lv}2. دانلود کلاینت در ویندوز، کپی کد پیکربندی برای اتصال به شبکه.${gl_bai}"
				echo -e "${gl_lv}3. استقرار کلاینت WG در لینوکس با استفاده از اسکریپت، کپی کد پیکربندی برای اتصال به شبکه.${gl_bai}"
				echo -e "${gl_lv}روش دانلود کلاینت رسمی: https://www.wireguard.com/install/${gl_bai}"
				break_end

			}

			local docker_describe="ابزار شبکه خصوصی مجازی مدرن و با کارایی بالا"
			local docker_url="معرفی وب‌سایت: https://www.wireguard.com/"
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

				echo "پیکربندی کلاینت خود را جای‌گذاری کنید، دو بار Enter را به طور متوالی فشار دهید تا ذخیره شود: "

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

				echo "پیکربندی کلاینت در $CONFIG_FILE ذخیره شد"

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

			local docker_describe="ابزار شبکه خصوصی مجازی مدرن و با کارایی بالا"
			local docker_url="معرفی وب‌سایت: https://www.wireguard.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		99 | dsm)

			local app_id="99"

			local app_name="ماشین مجازی Synology DSM"
			local app_text="DSM مجازی در کانتینرهای Docker"
			local app_url="وب‌سایت رسمی: https://github.com/vdsm/virtual-dsm"
			local docker_name="dsm"
			local docker_port="8099"
			local app_size="16"

			docker_app_install() {

				read -e -p "تنظیم تعداد هسته های CPU (پیش فرض 2):" CPU_CORES
				local CPU_CORES=${CPU_CORES:-2}

				read -e -p "تنظیم اندازه حافظه (پیش فرض 4G):" RAM_SIZE
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
				echo "با موفقیت نصب شد"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/dsm/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/dsm/ && docker compose down --rmi all
				rm -rf /home/docker/dsm
				echo "برنامه حذف شد"
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

			local docker_describe="ابزار همگام سازی فایل نقطه به نقطه منبع باز، مشابه Dropbox، Resilio Sync، اما کاملاً غیرمتمرکز."
			local docker_url="معرفی وب‌سایت: https://github.com/syncthing/syncthing"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		101 | moneyprinterturbo)
			local app_id="101"
			local app_name="ابزار تولید ویدئوی هوش مصنوعی"
			local app_text="MoneyPrinterTurbo ابزاری است که از مدل‌های بزرگ هوش مصنوعی برای ترکیب ویدیوهای کوتاه با کیفیت بالا استفاده می‌کند."
			local app_url="وب‌سایت رسمی: https://github.com/harry0703/MoneyPrinterTurbo"
			local docker_name="moneyprinterturbo"
			local docker_port="8101"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/harry0703/MoneyPrinterTurbo.git && cd MoneyPrinterTurbo/
				sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml

				docker compose up -d
				clear
				echo "با موفقیت نصب شد"
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
				echo "برنامه حذف شد"
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

			local docker_describe="یک سرویس چت رسانه اجتماعی ابری شخصی است که از استقرار مستقل پشتیبانی می کند"
			local docker_url="معرفی وب‌سایت: https://github.com/Privoce/vocechat-web"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		103 | umami)
			local app_id="103"
			local app_name="ابزار آمار وب‌سایت Umami"
			local app_text="ابزار تجزیه و تحلیل وب‌سایت سبک، حریم خصوصی‌محور و متن‌باز، مشابه Google Analytics."
			local app_url="وب‌سایت رسمی: https://github.com/umami-software/umami"
			local docker_name="umami-umami-1"
			local docker_port="8103"
			local app_size="1"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone https://github.com/umami-software/umami.git && cd umami
				sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/umami/docker-compose.yml

				docker compose up -d
				clear
				echo "با موفقیت نصب شد"
				check_docker_app_ip
				echo "نام کاربری اولیه: admin"
				echo "رمز عبور اولیه: umami"
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
				echo "برنامه حذف شد"
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

				read -e -p "تنظیم رمز عبور ورود:" app_passwd

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

			local docker_describe="SiYuan Note یک سیستم مدیریت دانش با اولویت حریم خصوصی است"
			local docker_url="معرفی وب‌سایت: https://github.com/siyuan-note/siyuan"
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

			local docker_describe="یک ابزار وایت برد قدرتمند منبع باز است که نقشه های ذهنی، نمودارهای جریان و غیره را ادغام می کند."
			local docker_url="معرفی وب‌سایت: https://github.com/plait-board/drawnix"
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
					-e ENABLED_PLUGINS="hunhepan,jikepan,panwiki,pansearch,panta,qupansou,
susu,thepiratebay,wanou,xuexizhinan,panyq,zhizhen,labi,muou,ouge,shandian,
duoduo,huban,cyg,erxiao,miaoso,fox4k,pianku,clmao,wuji,cldi,xiaozhang,
libvio,leijing,xb6v,xys,ddys,hdmoli,yuhuage,u3c3,javdb,clxiong,jutoushe,
sdso,xiaoji,xdyh,haisou,bixin,djgou,nyaa,xinjuc,aikanzy,qupanshe,xdpan,
discourse,yunsou,ahhhhfs,nsgame,gying" \
					ghcr.io/fish2018/pansou-web

			}

			local docker_describe="PanSou یک سرویس API جستجوی منابع دیسک شبکه با کارایی بالا است."
			local docker_url="معرفی وب‌سایت: https://github.com/fish2018/pansou"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		b)
			clear
			send_stats "全部应用备份"

			local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
			echo -e "${gl_huang}در حال پشتیبان‌گیری از $backup_filename ...${gl_bai}"
			cd / && tar czvf "$backup_filename" home

			while true; do
				clear
				echo "فایل پشتیبان ایجاد شد: /$backup_filename"
				read -e -p "آیا می‌خواهید داده‌های پشتیبان را به سرور راه دور ارسال کنید؟ \(y/N\): " choice
				case "$choice" in
				[Yy])
					read -e -p "لطفاً IP سرور راه دور را وارد کنید: " remote_ip
					read -e -p "پورت SSH سرور هدف [پیش‌فرض 22]: " TARGET_PORT
					local TARGET_PORT=${TARGET_PORT:-22}

					if [ -z "$remote_ip" ]; then
						echo "خطا: لطفا IP سرور راه دور را وارد کنید."
						continue
					fi
					local latest_tar=$(ls -t /app*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
						echo "فایل‌ها به سرور راه دور/دایرکتوری ریشه منتقل شدند."
					else
						echo "هیچ فایلی برای ارسال پیدا نشد."
					fi
					break
					;;
				*)
					echo "توجه: پشتیبان فعلی فقط شامل پروژه‌های Docker است و شامل پشتیبان‌گیری از داده‌های پنل‌های ساخت وب‌سایت مانند Batian، 1panel و غیره نمی‌شود."
					break
					;;
				esac
			done

			;;

		r)
			root_use
			send_stats "全部应用还原"
			echo "پشتیبان‌گیری‌های برنامه موجود"
			echo "-------------------------"
			ls -lt /app*.gz | awk '{print $NF}'
			echo ""
			read -e -p "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

			if [ "$filename" == "0" ]; then
				break_end
				linux_panel
			fi

			# 如果用户没有输入文件名，使用最新的压缩包
			if [ -z "$filename" ]; then
				local filename=$(ls -t /app*.tar.gz | head -1)
			fi

			if [ -n "$filename" ]; then
				echo -e "${gl_huang}در حال استخراج $filename ...${gl_bai}"
				cd / && tar -xzf "$filename"
				echo "داده‌های برنامه بازیابی شده‌اند. لطفاً به صورت دستی وارد منوی برنامه مشخص شده شوید و برنامه را به‌روزرسانی کنید تا برنامه بازیابی شود."
			else
				echo "هیچ بسته‌ای پیدا نشد."
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
		echo -e "فضای کار پس‌زمینه"
		echo -e "سیستم یک فضای کاری را در اختیار شما قرار می‌دهد که می‌تواند به طور مداوم در پس‌زمینه اجرا شود، می‌توانید از آن برای اجرای وظایف طولانی‌مدت استفاده کنید"
		echo -e "حتی اگر SSH را قطع کنید، وظایف موجود در فضای کاری متوقف نمی‌شوند، وظایف پس‌زمینه."
		echo -e "${gl_huang}نکته: ${gl_bai}پس از ورود به فضای کاری، از Ctrl+b و سپس دکمه d به تنهایی برای خروج از فضای کاری استفاده کنید! "
		echo -e "${gl_kjlan}------------------------"
		echo "لیست فضاهای کاری موجود"
		echo -e "${gl_kjlan}------------------------"
		tmux list-sessions
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}فضای کاری شماره 1"
		echo -e "${gl_kjlan}2.   ${gl_bai}2 شماره ناحیه کاری"
		echo -e "${gl_kjlan}3.   ${gl_bai}3 شماره ناحیه کاری"
		echo -e "${gl_kjlan}4.   ${gl_bai}4 شماره ناحیه کاری"
		echo -e "${gl_kjlan}5.   ${gl_bai}5 شماره ناحیه کاری"
		echo -e "${gl_kjlan}6.   ${gl_bai}6 شماره ناحیه کاری"
		echo -e "${gl_kjlan}7.   ${gl_bai}7 شماره ناحیه کاری"
		echo -e "${gl_kjlan}8.   ${gl_bai}8 شماره ناحیه کاری"
		echo -e "${gl_kjlan}9.   ${gl_bai}9 شماره ناحیه کاری"
		echo -e "${gl_kjlan}10.  ${gl_bai}10 شماره ناحیه کاری"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}حالت ماندگار SSH ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}22.  ${gl_bai}ایجاد/ورود به ناحیه کاری"
		echo -e "${gl_kjlan}23.  ${gl_bai}تزریق دستور به ناحیه کاری پس‌زمینه"
		echo -e "${gl_kjlan}24.  ${gl_bai}حذف ناحیه کاری مشخص شده"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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
				echo -e "حالت ماندگار SSH ${tmux_sshd_status}"
				echo "پس از باز شدن، اتصال SSH مستقیماً وارد حالت ماندگار می‌شود و مستقیماً به وضعیت کاری قبلی باز می‌گردد."
				echo "------------------------"
				echo "1. فعال کردن                  2. غیرفعال کردن"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " gongzuoqu_del
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
			read -e -p "لطفاً نام فضای کاری را که ایجاد یا وارد می شوید وارد کنید، به عنوان مثال 1001 kj001 work1:" SESSION_NAME
			tmux_run
			send_stats "自定义工作区"
			;;

		23)
			read -e -p "لطفاً دستوری را که می خواهید در پس زمینه اجرا شود وارد کنید، به عنوان مثال: curl -fsSL https://get.docker.com | sh:" tmuxd
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
			echo "ورودی نامعتبر! "
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
		echo -e "${gl_kjlan}1.   ${gl_bai}تنظیم کلیدهای میانبر برای شروع اسکریپت               ${gl_kjlan}2.   ${gl_bai}تغییر رمز عبور ورود"
		echo -e "${gl_kjlan}3.   ${gl_bai}حالت ورود به سیستم با رمز عبور root                  ${gl_kjlan}4.   ${gl_bai}نصب نسخه مشخص Python"
		echo -e "${gl_kjlan}5.   ${gl_bai}باز کردن همه پورت‌ها                                 ${gl_kjlan}6.   ${gl_bai}تغییر پورت SSH"
		echo -e "${gl_kjlan}7.   ${gl_bai}بهینه‌سازی آدرس DNS                                  ${gl_kjlan}8.   ${gl_bai}نصب مجدد سیستم با یک کلیک ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}9.   ${gl_bai}غیرفعال کردن ایجاد حساب کاربری جدید توسط root        ${gl_kjlan}10.  ${gl_bai}تغییر اولویت IPv4/IPv6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}بررسی وضعیت اشغال پورت‌ها                            ${gl_kjlan}12.  ${gl_bai}تغییر اندازه حافظه مجازی"
		echo -e "${gl_kjlan}13.  ${gl_bai}مدیریت کاربران                                       ${gl_kjlan}14.  ${gl_bai}تولید کننده نام کاربری/رمز عبور"
		echo -e "${gl_kjlan}15.  ${gl_bai}تنظیم منطقه زمانی سیستم                              ${gl_kjlan}16.  ${gl_bai}تنظیم شتاب BBRv3"
		echo -e "${gl_kjlan}17.  ${gl_bai}مدیر پیشرفته فایروال                                 ${gl_kjlan}18.  ${gl_bai}تغییر نام هاست"
		echo -e "${gl_kjlan}19.  ${gl_bai}تغییر منبع بروزرسانی سیستم                           ${gl_kjlan}20.  ${gl_bai}مدیریت وظایف زمان‌بندی شده"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}تجزیه و تحلیل هاست محلی                              ${gl_kjlan}22.  ${gl_bai}دفاع SSH"
		echo -e "${gl_kjlan}23.  ${gl_bai}خاموش شدن خودکار محدود کننده جریان                   ${gl_kjlan}24.  ${gl_bai}حالت ورود کلید خصوصی root"
		echo -e "${gl_kjlan}25.  ${gl_bai}نظارت و هشدار سیستم TG-bot                           ${gl_kjlan}26.  ${gl_bai}رفع آسیب‌پذیری‌های بحرانی OpenSSH"
		echo -e "${gl_kjlan}27.  ${gl_bai}ارتقاء هسته لینوکس مبتنی بر Red Hat                  ${gl_kjlan}28.  ${gl_bai}بهینه‌سازی پارامترهای هسته سیستم لینوکس ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}29.  ${gl_bai}ابزار اسکن ویروس ${gl_huang}★${gl_bai}                                   ${gl_kjlan}30.  ${gl_bai}مدیر فایل"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}تغییر زبان سیستم                                     ${gl_kjlan}32.  ${gl_bai}ابزار زیباسازی خط فرمان ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}تنظیم سطل زباله سیستم                                ${gl_kjlan}34.  ${gl_bai}پشتیبان‌گیری و بازیابی سیستم"
		echo -e "${gl_kjlan}35.  ${gl_bai}ابزار اتصال از راه دور SSH                           ${gl_kjlan}36.  ${gl_bai}ابزار مدیریت پارتیشن دیسک"
		echo -e "${gl_kjlan}37.  ${gl_bai}تاریخچه دستورات خط فرمان                             ${gl_kjlan}38.  ${gl_bai}ابزار همگام‌سازی از راه دور rsync"
		echo -e "${gl_kjlan}39.  ${gl_bai}مجموعه دستورات ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}تابلو اعلانات                                        ${gl_kjlan}66.  ${gl_bai}بهینه‌سازی یکپارچه سیستم ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}99.  ${gl_bai}راه‌اندازی مجدد سرور                                 ${gl_kjlan}100. ${gl_bai}حریم خصوصی و امنیت"
		echo -e "${gl_kjlan}101. ${gl_bai}استفاده پیشرفته از دستور k ${gl_huang}★${gl_bai}                         ${gl_kjlan}102. ${gl_bai}حذف اسکریپت KejiLion"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			while true; do
				clear
				read -e -p "لطفاً کلید میانبر خود را وارد کنید (برای خروج 0 را وارد کنید):" kuaijiejian
				if [ "$kuaijiejian" == "0" ]; then
					break_end
					linux_Settings
				fi
				find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				echo "کلیدهای میانبر تنظیم شده‌اند"
				send_stats "脚本快捷键已设置"
				break_end
				linux_Settings
			done
			;;

		2)
			clear
			send_stats "设置你的登录密码"
			echo "تنظیم رمز عبور ورود خود"
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
			echo "معرفی ویدئویی: https://youtu.be/E4NhofhUlRU"
			echo "---------------------------------------"
			echo "این ویژگی امکان نصب یکپارچه هر نسخه پشتیبانی شده توسط رسمی پایتون را فراهم می‌کند!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "نسخه فعلی پایتون: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "نسخه‌های پیشنهادی: 3.12    3.11    3.10    3.9    3.8    2.7"
			echo "جستجوی نسخه‌های بیشتر: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "وارد کردن شماره نسخه پایتون برای نصب (برای خروج 0 را وارد کنید):" py_new_v

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
					echo "مدیر بسته ناشناخته!"
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
			echo -e "نسخه فعلی پایتون: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			;;

		5)
			root_use
			send_stats "开放端口"
			iptables_open
			remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
			echo "همه پورت‌ها باز شدند"

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
				echo -e "شماره پورت اتصال SSH فعلی:  ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "اعداد بین 1 تا 65535 برای محدوده شماره پورت. (وارد کردن 0 برای خروج)"

				# 提示用户输入新的 SSH 端口号
				read -e -p "لطفاً شماره پورت SSH جدید را وارد کنید:" new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "شماره پورت نامعتبر است، لطفاً عددی بین 1 تا 65535 وارد کنید."
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
			read -e -p "لطفاً نام کاربری جدید را وارد کنید (برای خروج 0 را وارد کنید):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			install sudo

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "عملیات با موفقیت انجام شد."
			;;

		10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "تنظیم اولویت IPv4/IPv6"
				echo "------------------------"

				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "تنظیم اولویت شبکه فعلی: ${gl_huang}IPv4${gl_bai} اولویت"
				else
					echo -e "تنظیم اولویت شبکه فعلی: ${gl_huang}IPv6${gl_bai} اولویت"
				fi

				echo ""
				echo "------------------------"
				echo "1. اولویت IPv4          2. اولویت IPv6          3. ابزار رفع اشکال IPv6"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "انتخاب شبکه اولویت دار:" choice

				case $choice in
				1)
					prefer_ipv4
					;;
				2)
					rm -f /etc/gai.conf
					echo "به IPv6 اولویت داده شد"
					send_stats "已切换为 IPv6 优先"
					;;

				3)
					clear
					bash <(curl -L -s jhb.ovh/jb/v6.sh)
					echo "این ویژگی توسط jhb ارائه شده است، از او سپاسگزاریم!"
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
				echo "تنظیم حافظه مجازی"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "حافظه مجازی فعلی: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. پیکربندی 1024 مگابایت         2. پیکربندی 2048 مگابایت         3. پیکربندی 4096 مگابایت         4. اندازه سفارشی"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " choice

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
					read -e -p "لطفاً اندازه حافظه مجازی را وارد کنید (واحد M):" new_swap
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
				echo "1. ایجاد حساب کاربری عادی             2. ایجاد حساب کاربری پیشرفته"
				echo "------------------------"
				echo "3. اعطای بالاترین امتیاز             4. لغو بالاترین امتیاز"
				echo "------------------------"
				echo "5. حذف حساب"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					# 提示用户输入新用户名
					read -e -p "لطفاً نام کاربری جدید را وارد کنید:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					echo "عملیات با موفقیت انجام شد."
					;;

				2)
					# 提示用户输入新用户名
					read -e -p "لطفاً نام کاربری جدید را وارد کنید:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					# 赋予新用户sudo权限
					echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					install sudo

					echo "عملیات با موفقیت انجام شد."

					;;
				3)
					read -e -p "لطفاً نام کاربری را وارد کنید: " username
					# 赋予新用户sudo权限
					echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					install sudo
					;;
				4)
					read -e -p "لطفاً نام کاربری را وارد کنید: " username
					# 从sudoers文件中移除用户的sudo权限
					sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

					;;
				5)
					read -e -p "لطفاً نام کاربری که می‌خواهید حذف کنید را وارد کنید: " username
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
			echo "رمز عبور تصادفی 16 بیتی"
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
				echo "زمان سیستم فعلی: $current_time"

				echo ""
				echo "تغییر منطقه زمانی"
				echo "------------------------"
				echo "آسیا"
				echo "1. زمان شانگهای چین             2. زمان هنگ کنگ چین"
				echo "3. زمان توکیو ژاپن             4. زمان سئول کره"
				echo "5. زمان سنگاپور               6. زمان کلکته هند"
				echo "7. زمان دبی امارات           8. زمان سیدنی استرالیا"
				echo "9. زمان بانکوک تایلند"
				echo "------------------------"
				echo "اروپا"
				echo "11. زمان لندن انگلستان             12. زمان پاریس فرانسه"
				echo "13. زمان برلین آلمان             14. زمان مسکو روسیه"
				echo "15. زمان اوترخت هلند       16. زمان مادرید اسپانیا"
				echo "------------------------"
				echo "آمریکا"
				echo "21. زمان غرب ایالات متحده             22. زمان شرق ایالات متحده"
				echo "23. زمان کانادا               24. زمان مکزیک"
				echo "25. زمان برزیل                 26. زمان آرژانتین"
				echo "------------------------"
				echo "31. زمان استاندارد جهانی UTC"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

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
				read -e -p "لطفاً نام هاست جدید را وارد کنید (برای خروج 0 را وارد کنید): " new_hostname
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

					echo "نام هاست به: $new_hostname تغییر یافت"
					send_stats "主机名已更改"
					sleep 1
				else
					echo "خروج انجام شد، نام هاست تغییر نکرد."
					break
				fi
			done
			;;

		19)
			root_use
			send_stats "换系统更新源"
			clear
			echo "انتخاب منبع بروزرسانی"
			echo "اتصال به LinuxMirrors برای تغییر منبع بروزرسانی سیستم"
			echo "------------------------"
			echo "1. سرزمین اصلی چین【پیش‌فرض】          2. سرزمین اصلی چین【شبکه آموزشی】          3. مناطق غیر چین"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			read -e -p "انتخاب خود را وارد کنید: " choice

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
				echo "لیست وظایف زمان‌بندی شده"
				crontab -l
				echo ""
				echo "عملیات"
				echo "------------------------"
				echo "1. افزودن وظیفه زمان‌بندی شده              2. حذف وظیفه زمان‌بندی شده              3. ویرایش وظیفه زمان‌بندی شده"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					read -e -p "لطفاً دستور اجرای وظیفه جدید را وارد کنید: " newquest
					echo "------------------------"
					echo "1. وظایف ماهانه                 2. وظایف هفتگی"
					echo "3. وظایف روزانه                 4. وظایف ساعتی"
					echo "------------------------"
					read -e -p "لطفاً انتخاب خود را وارد کنید: " dingshi

					case $dingshi in
					1)
						read -e -p "چه روزی از ماه را برای اجرای وظیفه انتخاب می‌کنید؟ (1-30): " day
						(
							crontab -l
							echo "0 0 $day * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					2)
						read -e -p "چه روزی از هفته را برای اجرای وظیفه انتخاب می‌کنید؟ (0-6، 0 نشان‌دهنده یکشنبه است): " weekday
						(
							crontab -l
							echo "0 0 * * $weekday $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					3)
						read -e -p "چه ساعتی از روز را برای اجرای وظیفه انتخاب می‌کنید؟ (ساعت، 0-23): " hour
						(
							crontab -l
							echo "0 $hour * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					4)
						read -e -p "در هر ساعت، در چه دقیقه‌ای وظیفه را اجرا کنید؟ (دقیقه، 0-60): " minute
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
					read -e -p "لطفاً کلمه کلیدی برای حذف وظیفه را وارد کنید: " kquest
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
				echo "لیست تحلیلگرهای هاست محلی"
				echo "اگر تحلیلگرهایی را در اینجا اضافه کنید، دیگر از تحلیلگرهای پویا استفاده نخواهد شد"
				cat /etc/hosts
				echo ""
				echo "عملیات"
				echo "------------------------"
				echo "1.  افزودن تحلیلگر              2. حذف آدرس تحلیلگر"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " host_dns

				case $host_dns in
				1)
					read -e -p "لطفاً رکورد DNS جدید را با فرمت وارد کنید: 110.25.5.33 kejilion.pro : " addhost
					echo "$addhost" >>/etc/hosts
					send_stats "本地host解析新增"

					;;
				2)
					read -e -p "لطفاً کلمه کلیدی برای حذف محتوای DNS را وارد کنید: " delhost
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
				echo "Fail2ban یک ابزار جلوگیری از حملات brute-force به SSH است"
				echo "معرفی وب‌سایت رسمی: ${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. نصب محافظ"
				echo "------------------------"
				echo "2. مشاهده سوابق مسدودسازی SSH"
				echo "3. نظارت زنده بر لاگ‌ها"
				echo "------------------------"
				echo "9. حذف محافظ"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
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
					echo "محافظ Fail2ban حذف شد"
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
				echo "ویژگی خاموش کردن سرور با محدودیت ترافیک"
				echo "معرفی ویدئویی: https://youtu.be/mOKwVzK0U6I"
				echo "------------------------------------------------"
				echo "وضعیت فعلی استفاده از ترافیک، راه‌اندازی مجدد سرور محاسبات ترافیک را بازنشانی می‌کند!"
				output_status
				echo -e "${gl_kjlan}دریافت کل: ${gl_bai}$rx"
				echo -e "${gl_kjlan}ارسال کل: ${gl_bai}$tx"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}آستانه محدود کردن ورودی تنظیم شده فعلی: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}آستانه محدود کردن خروجی تنظیم شده فعلی: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}ویژگی خاموش شدن محدود کردن در حال حاضر فعال نیست${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "سیستم هر دقیقه بررسی می‌کند که آیا ترافیک واقعی به آستانه رسیده است یا خیر، و پس از رسیدن به آن، سرور را به طور خودکار خاموش می‌کند!"
				echo "------------------------"
				echo "1. فعال کردن ویژگی خاموش کردن سرور با محدودیت ترافیک          2. غیرفعال کردن ویژگی خاموش کردن سرور با محدودیت ترافیک"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " Limiting

				case "$Limiting" in
				1)
					# 输入新的虚拟内存大小
					echo "اگر ترافیک سرور واقعی فقط 100 گیگابایت باشد، می‌توانید آستانه را روی 95 گیگابایت تنظیم کنید تا قبل از بروز خطا یا سرریز ترافیک، سرور خاموش شود."
					read -e -p "لطفاً آستانه ترافیک ورودی را وارد کنید (واحد: G، پیش‌فرض 100G): " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "لطفاً آستانه ترافیک خروجی را وارد کنید (واحد: G، پیش‌فرض 100G): " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "لطفاً تاریخ بازنشانی ترافیک را وارد کنید (پیش‌فرض بازنشانی در روز اول هر ماه است): " cz_day
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
					echo "خاموش شدن محدود شده"
					send_stats "限流关机已设置"
					;;
				2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "خاموش کردن ویژگی محدود شده"
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
				echo "حالت ورود با کلید خصوصی root"
				echo "معرفی ویدیو: https://youtu.be/4wAUIp7pN6I?t=209"
				echo "------------------------------------------------"
				echo "یک جفت کلید تولید می شود، روش امن تر برای ورود SSH"
				echo "------------------------"
				echo "1. تولید کلید جدید              2. وارد کردن کلید موجود              3. مشاهده کلیدهای محلی"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " host_dns

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
			echo "ویژگی نظارت و هشدار TG-bot"
			echo "معرفی ویدیو: https://youtu.be/vLL-eb3Z_TY"
			echo "------------------------------------------------"
			echo "برای دستیابی به نظارت و هشدار بلادرنگ CPU، حافظه، هارد دیسک، ترافیک و ورود SSH محلی، باید API ربات تلگرام و شناسه کاربری دریافت کننده هشدار را پیکربندی کنید"
			echo "پس از رسیدن به آستانه، پیام هشدار به کاربر ارسال می شود"
			echo -e "${gl_hui}- در مورد ترافیک، راه اندازی مجدد سرور محاسبات را دوباره انجام می دهد-${gl_bai}"
			read -e -p "آیا مطمئن هستید؟ \(y/N\): " choice

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
				echo "سیستم هشدار TG-bot راه اندازی شد"
				echo -e "${gl_hui}شما همچنین می توانید فایل هشدار TG-check-notify.sh را در دایرکتوری root به ماشین های دیگر منتقل کرده و مستقیماً از آن استفاده کنید! ${gl_bai}"
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
			echo "از تابلوی پیام رسمی KejiLion دیدن کنید، هر ایده ای در مورد اسکریپت دارید خوشحال می شویم با شما در میان بگذاریم!"
			echo "https://board.kejilion.pro"
			echo "رمز عبور عمومی: kejilion.sh"
			;;

		66)

			root_use
			send_stats "一条龙调优"
			echo "بهینه سازی سیستم جامع"
			echo "------------------------------------------------"
			echo "عملیات و بهینه سازی بر روی موارد زیر انجام می شود"
			echo "1. به روز رسانی سیستم به آخرین نسخه"
			echo "2. پاکسازی فایل های زباله سیستم"
			echo -e "3. تنظیم حافظه مجازی ${gl_huang}1G${gl_bai}"
			echo -e "4. تنظیم شماره پورت SSH به ${gl_huang}5522${gl_bai}"
			echo -e "5. باز کردن همه پورت ها"
			echo -e "6. فعال کردن شتاب ${gl_huang}BBR${gl_bai}"
			echo -e "7. تنظیم منطقه زمانی به ${gl_huang}شانگهای${gl_bai}"
			echo -e "8. بهینه سازی خودکار آدرس DNS ${gl_huang}مناطق غیر چین: 1.1.1.1 8.8.8.8   مناطق چین: 223.5.5.5${gl_bai}"
			echo -e "9. نصب ابزارهای پایه ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			echo -e "10. سوئیچ به حالت بهینه سازی متعادل پارامترهای هسته سیستم Linux ${gl_huang}حالت بهینه سازی متعادل${gl_bai}"
			echo "------------------------------------------------"
			read -e -p "آیا مطمئن هستید که می‌خواهید یک بهینه‌سازی سریع انجام دهید؟ (y/N): " choice

			case "$choice" in
			[Yy])
				clear
				send_stats "一条龙调优启动"
				echo "------------------------------------------------"
				linux_update
				echo -e "[${gl_lv}OK${gl_bai}] 01/10. به‌روزرسانی سیستم به آخرین نسخه"

				echo "------------------------------------------------"
				linux_clean
				echo -e "[${gl_lv}OK${gl_bai}] 02/10. پاکسازی فایل‌های ناخواسته سیستم"

				echo "------------------------------------------------"
				add_swap 1024
				echo -e "[${gl_lv}OK${gl_bai}] 03/10. تنظیم حافظه مجازی ${gl_huang}1G${gl_bai}"

				echo "------------------------------------------------"
				local new_port=5522
				new_ssh_port
				echo -e "[${gl_lv}OK${gl_bai}] 04/10. تنظیم پورت SSH به ${gl_huang}5522${gl_bai}"
				echo "------------------------------------------------"
				echo -e "[${gl_lv}OK${gl_bai}] 05/10. باز کردن همه پورت‌ها"

				echo "------------------------------------------------"
				bbr_on
				echo -e "[${gl_lv}OK${gl_bai}] 06/10. فعال کردن شتاب ${gl_huang}BBR${gl_bai}"

				echo "------------------------------------------------"
				set_timedate Asia/Shanghai
				echo -e "[${gl_lv}OK${gl_bai}] 07/10. تنظیم منطقه زمانی به ${gl_huang}شانگهای${gl_bai}"

				echo "------------------------------------------------"
				auto_optimize_dns
				echo -e "[${gl_lv}OK${gl_bai}] 08/10. بهینه‌سازی خودکار آدرس DNS ${gl_huang}مناطق غیر چین: 1.1.1.1 8.8.8.8   مناطق چین: 223.5.5.5${gl_bai}"

				echo "------------------------------------------------"
				install_docker
				install wget sudo tar unzip socat btop nano vim
				echo -e "[${gl_lv}OK${gl_bai}] 09/10. نصب ابزارهای پایه ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				echo "------------------------------------------------"

				echo "------------------------------------------------"
				optimize_balanced
				echo -e "[${gl_lv}OK${gl_bai}] 10/10. بهینه‌سازی پارامترهای هسته سیستم لینوکس"
				echo -e "${gl_lv}بهینه‌سازی یک مرحله‌ای سیستم انجام شد${gl_bai}"

				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
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
					local status_message="${gl_lv}در حال جمع آوری داده ها${gl_bai}"
				elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k >/dev/null 2>&1; then
					local status_message="${gl_hui}جمع آوری داده ها بسته شد${gl_bai}"
				else
					local status_message="وضعیت نامشخص"
				fi

				echo "حریم خصوصی و امنیت"
				echo "اسکریپت داده‌های استفاده کاربر از ویژگی‌ها را جمع‌آوری می‌کند، تجربه اسکریپت را بهینه‌سازی می‌کند و ویژگی‌های سرگرم‌کننده‌تر و کاربردی‌تری ایجاد می‌کند."
				echo "شماره نسخه اسکریپت، زمان استفاده، نسخه سیستم، معماری CPU، کشور متعلق به دستگاه و نام ویژگی‌های استفاده شده جمع‌آوری خواهد شد."
				echo "------------------------------------------------"
				echo -e "وضعیت فعلی: $status_message"
				echo "--------------------"
				echo "1. فعال کردن جمع‌آوری"
				echo "2. غیرفعال کردن جمع‌آوری"
				echo "--------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "--------------------"
				read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice
				case $sub_choice in
				1)
					cd ~
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					echo "جمع‌آوری فعال شد"
					send_stats "隐私与安全已开启采集"
					;;
				2)
					cd ~
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					echo "جمع‌آوری غیرفعال شد"
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
			echo "حذف نصب اسکریپت KejiLion"
			echo "------------------------------------------------"
			echo "اسکریپت KejiLion به طور کامل حذف نصب می‌شود، و بر سایر ویژگی‌های شما تأثیری نخواهد داشت."
			read -e -p "آیا مطمئن هستید؟ \(y/N\): " choice

			case "$choice" in
			[Yy])
				clear
				(crontab -l | grep -v "kejilion.sh") | crontab -
				rm -f /usr/local/bin/k
				rm ~/kejilion.sh
				echo "اسکریپت حذف نصب شد، خداحافظ!"
				break_end
				clear
				exit
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفا Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion

			;;
		*)
			echo "ورودی نامعتبر! "
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
		echo "1. ورود به دایرکتوری           2. ایجاد دایرکتوری             3. تغییر مجوزهای دایرکتوری         4. تغییر نام دایرکتوری"
		echo "5. حذف دایرکتوری           6. بازگشت به منوی سطح بالاتر"
		echo "------------------------"
		echo "11. ایجاد فایل           12. ویرایش فایل             13. تغییر مجوزهای فایل         14. تغییر نام فایل"
		echo "15. حذف فایل"
		echo "------------------------"
		echo "21. فشرده‌سازی فایل دایرکتوری       22. استخراج فایل دایرکتوری       23. انتقال فایل دایرکتوری         24. کپی فایل دایرکتوری"
		echo "25. انتقال فایل به سرور دیگر"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " Limiting

		case "$Limiting" in
		1) # 进入目录
			read -e -p "لطفاً نام دایرکتوری را وارد کنید: " dirname
			cd "$dirname" 2>/dev/null || echo "امکان ورود به دایرکتوری وجود ندارد"
			send_stats "进入目录"
			;;
		2) # 创建目录
			read -e -p "لطفاً نام دایرکتوری که می‌خواهید ایجاد کنید را وارد کنید: " dirname
			mkdir -p "$dirname" && echo "دایرکتوری ایجاد شد" || echo "ایجاد ناموفق"
			send_stats "创建目录"
			;;
		3) # 修改目录权限
			read -e -p "لطفاً نام دایرکتوری را وارد کنید: " dirname
			read -e -p "لطفاً مجوزها را وارد کنید (مثلاً 755): " perm
			chmod "$perm" "$dirname" && echo "مجوزها تغییر یافت" || echo "تغییر ناموفق"
			send_stats "修改目录权限"
			;;
		4) # 重命名目录
			read -e -p "لطفاً نام دایرکتوری فعلی را وارد کنید: " current_name
			read -e -p "لطفاً نام دایرکتوری جدید را وارد کنید: " new_name
			mv "$current_name" "$new_name" && echo "دایرکتوری تغییر نام داده شد" || echo "تغییر نام ناموفق"
			send_stats "重命名目录"
			;;
		5) # 删除目录
			read -e -p "لطفاً نام پوشه‌ای که می‌خواهید حذف کنید را وارد کنید: " dirname
			rm -rf "$dirname" && echo "دایرکتوری حذف شد" || echo "حذف ناموفق"
			send_stats "删除目录"
			;;
		6) # 返回上一级选单目录
			cd ..
			send_stats "返回上一级选单目录"
			;;
		11) # 创建文件
			read -e -p "لطفاً نام فایلی که می‌خواهید ایجاد کنید را وارد کنید: " filename
			touch "$filename" && echo "فایل ایجاد شد" || echo "ایجاد ناموفق"
			send_stats "创建文件"
			;;
		12) # 编辑文件
			read -e -p "لطفاً نام فایلی که می‌خواهید ویرایش کنید را وارد کنید: " filename
			install nano
			nano "$filename"
			send_stats "编辑文件"
			;;
		13) # 修改文件权限
			read -e -p "لطفاً نام فایل را وارد کنید: " filename
			read -e -p "لطفاً مجوزها را وارد کنید (مثلاً 755): " perm
			chmod "$perm" "$filename" && echo "مجوزها تغییر یافت" || echo "تغییر ناموفق"
			send_stats "修改文件权限"
			;;
		14) # 重命名文件
			read -e -p "لطفاً نام فایل فعلی را وارد کنید: " current_name
			read -e -p "لطفاً نام فایل جدید را وارد کنید: " new_name
			mv "$current_name" "$new_name" && echo "فایل تغییر نام داده شد" || echo "تغییر نام ناموفق"
			send_stats "重命名文件"
			;;
		15) # 删除文件
			read -e -p "لطفاً نام فایلی که می‌خواهید حذف کنید را وارد کنید: " filename
			rm -f "$filename" && echo "فایل حذف شد" || echo "حذف ناموفق"
			send_stats "删除文件"
			;;
		21) # 压缩文件/目录
			read -e -p "لطفاً نام فایل یا پوشه‌ای که می‌خواهید فشرده کنید را وارد کنید: " name
			install tar
			tar -czvf "$name.tar.gz" "$name" && echo "به $name.tar.gz فشرده شد" || echo "فشرده‌سازی ناموفق"
			send_stats "压缩文件/目录"
			;;
		22) # 解压文件/目录
			read -e -p "لطفاً نام فایلی که می‌خواهید از حالت فشرده خارج کنید (.tar.gz) را وارد کنید: " filename
			install tar
			tar -xzvf "$filename" && echo "$filename از حالت فشرده خارج شد" || echo "از حالت فشرده خارج‌سازی ناموفق"
			send_stats "解压文件/目录"
			;;

		23) # 移动文件或目录
			read -e -p "لطفاً مسیر فایل یا پوشه‌ای که می‌خواهید منتقل کنید را وارد کنید: " src_path
			if [ ! -e "$src_path" ]; then
				echo "خطا: فایل یا دایرکتوری وجود ندارد."
				send_stats "移动文件或目录失败: 文件或目录不存在"
				continue
			fi

			read -e -p "لطفاً مسیر مقصد (شامل نام فایل یا پوشه جدید) را وارد کنید: " dest_path
			if [ -z "$dest_path" ]; then
				echo "خطا: لطفاً مسیر مقصد را وارد کنید."
				send_stats "移动文件或目录失败: 目标路径未指定"
				continue
			fi

			mv "$src_path" "$dest_path" && echo "فایل یا دایرکتوری به $dest_path منتقل شد" || echo "انتقال فایل یا دایرکتوری ناموفق"
			send_stats "移动文件或目录"
			;;

		24) # 复制文件目录
			read -e -p "لطفاً مسیر فایل یا پوشه‌ای که می‌خواهید کپی کنید را وارد کنید: " src_path
			if [ ! -e "$src_path" ]; then
				echo "خطا: فایل یا دایرکتوری وجود ندارد."
				send_stats "复制文件或目录失败: 文件或目录不存在"
				continue
			fi

			read -e -p "لطفاً مسیر مقصد (شامل نام فایل یا پوشه جدید) را وارد کنید: " dest_path
			if [ -z "$dest_path" ]; then
				echo "خطا: لطفاً مسیر مقصد را وارد کنید."
				send_stats "复制文件或目录失败: 目标路径未指定"
				continue
			fi

			# 使用 -r 选项以递归方式复制目录
			cp -r "$src_path" "$dest_path" && echo "فایل یا دایرکتوری به $dest_path کپی شد" || echo "کپی کردن فایل یا دایرکتوری ناموفق"
			send_stats "复制文件或目录"
			;;

		25) # 传送文件至远端服务器
			read -e -p "لطفاً مسیر فایلی که می‌خواهید ارسال کنید را وارد کنید: " file_to_transfer
			if [ ! -f "$file_to_transfer" ]; then
				echo "خطا: فایل وجود ندارد."
				send_stats "传送文件失败: 文件不存在"
				continue
			fi

			read -e -p "لطفاً IP سرور راه دور را وارد کنید: " remote_ip
			if [ -z "$remote_ip" ]; then
				echo "خطا: لطفا IP سرور راه دور را وارد کنید."
				send_stats "传送文件失败: 未输入远端服务器IP"
				continue
			fi

			read -e -p "لطفاً نام کاربری سرور راه دور (پیش‌فرض root) را وارد کنید: " remote_user
			remote_user=${remote_user:-root}

			read -e -p "لطفاً رمز عبور سرور راه دور را وارد کنید: " -s remote_password
			echo
			if [ -z "$remote_password" ]; then
				echo "خطا: لطفا رمز عبور سرور راه دور را وارد کنید."
				send_stats "传送文件失败: 未输入远端服务器密码"
				continue
			fi

			read -e -p "لطفاً شماره پورت ورود (پیش‌فرض 22) را وارد کنید: " remote_port
			remote_port=${remote_port:-22}

			# 清除已知主机的旧条目
			ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			sleep 2 # 等待时间

			# 使用scp传输文件
			scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

			if [ $? -eq 0 ]; then
				echo "فایل‌ها به دایرکتوری /home سرور راه دور ارسال شد."
				send_stats "文件传送成功"
			else
				echo "انتقال فایل ناموفق."
				send_stats "文件传送失败"
			fi

			break_end
			;;

		0) # 返回上一级选单
			send_stats "返回上一级选单菜单"
			break
			;;
		*) # 处理无效输入
			echo "انتخاب نامعتبر، لطفا دوباره وارد کنید"
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
		echo -e "${gl_huang}اتصال به $name ($hostname)...${gl_bai}"
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
		echo "کنترل کلاستر سرور"
		cat ~/cluster/servers.py
		echo
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}مدیریت لیست سرورها${gl_bai}"
		echo -e "${gl_kjlan}1.  ${gl_bai}افزودن سرور                       ${gl_kjlan}2.  ${gl_bai}حذف سرور                ${gl_kjlan}3.  ${gl_bai}ویرایش سرور"
		echo -e "${gl_kjlan}4.  ${gl_bai}پشتیبان‌گیری از کلاستر            ${gl_kjlan}5.  ${gl_bai}بازگردانی کلاستر"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}اجرای دسته‌ای وظایف${gl_bai}"
		echo -e "${gl_kjlan}11. ${gl_bai}نصب اسکریپت KejiLion              ${gl_kjlan}12. ${gl_bai}به‌روزرسانی سیستم       ${gl_kjlan}13. ${gl_bai}پاکسازی سیستم"
		echo -e "${gl_kjlan}14. ${gl_bai}نصب Docker                        ${gl_kjlan}15. ${gl_bai}نصب BBRv3               ${gl_kjlan}16. ${gl_bai}تنظیم حافظه مجازی 1G"
		echo -e "${gl_kjlan}17. ${gl_bai}تنظیم منطقه زمانی به شانگهای      ${gl_kjlan}18. ${gl_bai}باز کردن همه پورت‌ها    ${gl_kjlan}51. ${gl_bai}دستور سفارشی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.  ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			send_stats "添加集群服务器"
			read -e -p "نام سرور: " server_name
			read -e -p "آی‌پی سرور: " server_ip
			read -e -p "پورت سرور (22): " server_port
			local server_port=${server_port:-22}
			read -e -p "نام کاربری سرور (root): " server_username
			local server_username=${server_username:-root}
			read -e -p "گذرواژه کاربر سرور: " server_password

			sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			;;
		2)
			send_stats "删除集群服务器"
			read -e -p "لطفاً کلمه کلیدی مورد نظر برای حذف را وارد کنید: " rmserver
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
			echo -e "لطفاً فایل ${gl_huang}/root/cluster/servers.py${gl_bai} را دانلود کنید تا پشتیبان‌گیری تکمیل شود!"
			break_end
			;;

		5)
			clear
			send_stats "还原集群"
			echo "لطفا servers.py خود را آپلود کنید، هر کلیدی را برای شروع آپلود فشار دهید!"
			echo -e "لطفاً فایل ${gl_huang}servers.py${gl_bai} خود را در ${gl_huang}/root/cluster/${gl_bai} بارگذاری کنید تا بازیابی تکمیل شود!"
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
			read -e -p "لطفاً دستور مورد نظر برای اجرای دسته‌ای را وارد کنید: " mingling
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
	echo "ستون تبلیغات"
	echo "------------------------"
	echo "تجربه تبلیغاتی و خرید ساده‌تر و ظریف‌تری را برای کاربران فراهم می‌کند!"
	echo ""
	echo -e "پیشنهادهای سرور"
	echo "------------------------"
	echo -e "${gl_lan}Leica Cloud Hong Kong CN2 GIA Korea Dual ISP USA CN2 GIA پیشنهاد ویژه${gl_bai}"
	echo -e "${gl_bai}آدرس: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}RackNerd 10.99 دلار در سال آمریکا 1 هسته 1 گیگابایت حافظه 20 گیگابایت هارد دیسک 1 ترابایت ترافیک ماهانه${gl_bai}"
	echo -e "${gl_bai}آدرس: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}Hostinger 52.7 دلار در سال آمریکا 1 هسته 4 گیگابایت حافظه 50 گیگابایت هارد دیسک 4 ترابایت ترافیک ماهانه${gl_bai}"
	echo -e "${gl_bai}آدرس: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
	echo "------------------------"
	echo -e "${gl_huang}Bandwagonhost 49 دلار در هر فصل آمریکا CN2GIA ژاپن Softbank 2 هسته 1 گیگابایت حافظه 20 گیگابایت هارد دیسک 1 ترابایت ترافیک ماهانه${gl_bai}"
	echo -e "${gl_bai}آدرس: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}DMIT 28 دلار در هر فصل آمریکا CN2GIA 1 هسته 2 گیگابایت حافظه 20 گیگابایت هارد دیسک 800 گیگابایت ترافیک ماهانه${gl_bai}"
	echo -e "${gl_bai}آدرس: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}V.PS 6.9 دلار در ماه توکیو Softbank 2 هسته 1 گیگابایت حافظه 20 گیگابایت هارد دیسک 1 ترابایت ترافیک ماهانه${gl_bai}"
	echo -e "${gl_bai}آدرس: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}پیشنهادهای محبوب بیشتر VPS${gl_bai}"
	echo -e "${gl_bai}آدرس: https://kejilion.pro/topvps/${gl_bai}"
	echo "------------------------"
	echo ""
	echo -e "پیشنهادهای دامنه"
	echo "------------------------"
	echo -e "${gl_lan}GNAME 8.8 دلار سال اول دامنه COM 6.68 دلار سال اول دامنه CC${gl_bai}"
	echo -e "${gl_bai}آدرس وب‌سایت: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
	echo "------------------------"
	echo ""
	echo -e "اطراف KejiLion"
	echo "------------------------"
	echo -e "${gl_kjlan}Bilibili: ${gl_bai}https://b23.tv/2mqnQyh                ${gl_kjlan}یوتیوب: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
	echo -e "${gl_kjlan}وب‌سایت رسمی: ${gl_bai}https://kejilion.pro/             ${gl_kjlan}راهنما: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
	echo -e "${gl_kjlan}وبلاگ: ${gl_bai}https://blog.kejilion.pro/               ${gl_kjlan}مرکز نرم‌افزار: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}وب‌سایت اسکریپت: ${gl_bai}https://kejilion.sh            ${gl_kjlan}آدرس GitHub: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
	echo "------------------------"
	echo ""
}

kejilion_update() {

	send_stats "脚本更新"
	cd ~
	while true; do
		clear
		echo "لاگ به‌روزرسانی"
		echo "------------------------"
		echo "تمام لاگ‌ها: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
		echo "------------------------"

		curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
		local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

		if [ "$sh_v" = "$sh_v_new" ]; then
			echo -e "${gl_lv}شما از آخرین نسخه استفاده می‌کنید! ${gl_huang}v$sh_v${gl_bai}"
			send_stats "脚本已经最新了，无需更新"
		else
			echo "نسخه جدید یافت شد!"
			echo -e "نسخه فعلی v$sh_v        آخرین نسخه ${gl_huang}v$sh_v_new${gl_bai}"
		fi

		local cron_job="kejilion.sh"
		local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

		if [ -n "$existing_cron" ]; then
			echo "------------------------"
			echo -e "${gl_lv}به‌روزرسانی خودکار فعال است، اسکریپت هر روز ساعت 2 بامداد به‌روزرسانی می‌شود! ${gl_bai}"
		fi

		echo "------------------------"
		echo "1. اکنون به‌روزرسانی کنید            2. به‌روزرسانی خودکار را فعال کنید            3. به‌روزرسانی خودکار را غیرفعال کنید"
		echo "------------------------"
		echo "0. بازگشت به منوی اصلی"
		echo "------------------------"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice
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
			echo -e "${gl_lv}اسکریپت به آخرین نسخه به‌روزرسانی شد! ${gl_huang}v$sh_v_new${gl_bai}"
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
			echo -e "${gl_lv}به‌روزرسانی خودکار فعال است، اسکریپت هر روز ساعت 2 بامداد به‌روزرسانی می‌شود! ${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}به‌روزرسانی خودکار غیرفعال است${gl_bai}"
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
		echo -e "جعبه ابزار اسکریپت شیر ​​فناوری v$sh_v (ترجمه شده توسط هوش مصنوعی)"
		echo -e "برای راه‌اندازی سریع اسکریپت، ${gl_huang}k${gl_kjlan} را در خط فرمان وارد کنید${gl_bai}"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}1.   ${gl_bai}پرس و جو اطلاعات سیستم"
		echo -e "${gl_kjlan}2.   ${gl_bai}به‌روزرسانی سیستم"
		echo -e "${gl_kjlan}3.   ${gl_bai}پاکسازی سیستم"
		echo -e "${gl_kjlan}4.   ${gl_bai}ابزارهای پایه"
		echo -e "${gl_kjlan}5.   ${gl_bai}مدیریت BBR"
		echo -e "${gl_kjlan}6.   ${gl_bai}مدیریت Docker"
		echo -e "${gl_kjlan}7.   ${gl_bai}مدیریت WARP"
		echo -e "${gl_kjlan}8.   ${gl_bai}مجموعه اسکریپت‌های آزمایشی"
		echo -e "${gl_kjlan}9.   ${gl_bai}مجموعه اسکریپت‌های Oracle Cloud"
		echo -e "${gl_huang}10.  ${gl_bai}LDNMP ساخت وب‌سایت"
		echo -e "${gl_kjlan}11.  ${gl_bai}بازار برنامه"
		echo -e "${gl_kjlan}12.  ${gl_bai}فضای کاری پس‌زمینه"
		echo -e "${gl_kjlan}13.  ${gl_bai}ابزارهای سیستم"
		echo -e "${gl_kjlan}14.  ${gl_bai}کنترل کلاستر سرور"
		echo -e "${gl_kjlan}15.  ${gl_bai}ستون تبلیغات"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}p.   ${gl_bai}اسکریپت راه‌اندازی Palworld"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}00.  ${gl_bai}به‌روزرسانی اسکریپت"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.   ${gl_bai}خروج از اسکریپت"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "لطفاً انتخاب خود را وارد کنید: " choice

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
		*) echo "ورودی نامعتبر! " ;;
		esac
		break_end
	done
}

k_info() {
	send_stats "k命令参考用例"
	echo "-------------------"
	echo "معرفی ویدیو: https://youtu.be/wQdmKuL0hdk"
	echo "در اینجا نمونه‌هایی از مرجع دستور k آمده است:"
	echo "شروع اسکریپت            k"
	echo "نصب بسته            k install nano wget | k add nano wget"
	echo "حذف بسته        k remove nano wget | k del nano wget | k uninstall nano wget"
	echo "به‌روزرسانی سیستم            k update"
	echo "پاکسازی زباله‌های سیستم        k clean"
	echo "پنل نصب مجدد سیستم        k dd"
	echo "پنل کنترل BBRv3      k bbr3 | k bbrv3"
	echo "پنل تنظیمات هسته        k nhyh"
	echo "تنظیم حافظه مجازی      k swap 2048"
	echo "تنظیم منطقه زمانی        k time Asia/Shanghai"
	echo "سطل بازیافت سیستم          k trash | k hsz"
	echo "عملکرد پشتیبان‌گیری سیستم        k backup | k bf"
	echo "ابزار اتصال از راه دور SSH    k ssh"
	echo "ابزار همگام‌سازی از راه دور rsync  k rsync"
	echo "ابزار مدیریت هارد دیسک        k disk"
	echo "تونل‌زنی داخلی (سرور)   k frps"
	echo "تونل‌زنی داخلی (مشتری)   k frpc"
	echo "راه‌اندازی نرم‌افزار            k start sshd"
	echo "توقف نرم‌افزار            k stop sshd"
	echo "راه‌اندازی مجدد نرم‌افزار k restart sshd"
	echo "بررسی وضعیت نرم‌افزار        k status sshd"
	echo "راه‌اندازی خودکار نرم‌افزار        k enable docker | k autostart docke"
	echo "درخواست گواهی دامنه        k ssl"
	echo "جستجوی انقضای گواهی دامنه    k ssl ps"
	echo "صفحه مدیریت Docker     k docker"
	echo "نصب محیط Docker     k docker install"
	echo "مدیریت کانتینرهای Docker     k docker ps"
	echo "مدیریت تصاویر Docker     k docker img"
	echo "مدیریت سایت LDNMP      k web"
	echo "پاکسازی کش LDNMP      k web cache"
	echo "نصب WordPress      k wp |k wordpress |k wp xxx.com"
	echo "نصب پروکسی معکوس        k fd |k rp |k fd xxx.com"
	echo "نصب متعادل‌ساز بار        k loadbalance"
	echo "نصب متعادل‌ساز بار L4    k stream"
	echo "پنل فایروال          k fhq"
	echo "باز کردن پورت            k dkdk 8080"
	echo "بستن پورت            k gbdk 7800"
	echo "اجازه دادن به IP             k fxip 127.0.0.0/8"
	echo "مسدود کردن IP             k zzip 177.5.25.36"
	echo "مجموعه دستورات مورد علاقه          k fav"
	echo "مدیریت بازار برنامه        k app"
	echo "مدیریت سریع شماره برنامه    k app 26 | k app 1panel | k app npm"
	echo "نمایش اطلاعات سیستم        k info"
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
			echo "دسترسی IP+پورت به این سرویس مسدود شد"
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

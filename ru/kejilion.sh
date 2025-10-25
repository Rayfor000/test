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
	echo -e "${gl_kjlan}Добро пожаловать в набор инструментов для сценариев технологического льва ${gl_bai}"
	echo "При первом использовании скрипта прочтите и согласитесь с Пользовательским лицензионным соглашением."
	echo "Пользовательское лицензионное соглашение: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "Согласны ли вы с вышеуказанными условиями? (да/нет):" user_input

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
		echo "Параметры пакета не указаны!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}Установка $package...${gl_bai}"
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
				echo "Неизвестный менеджер пакетов!"
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
		echo -e "${gl_huang} Совет: ${gl_bai} Недостаточно места на диске!"
		echo "Текущее доступное пространство: $((available_space_mb / 1024))G"
		echo "Минимально необходимое пространство: ${required_gb}G"
		echo "Установка не может быть продолжена. Пожалуйста, очистите место на диске и повторите попытку."
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
		echo "Параметры пакета не указаны!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang} Удаление $package...${gl_bai}"
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
			echo "Неизвестный менеджер пакетов!"
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
		echo "$1 Служба перезапущена."
	else
		echo "Ошибка: не удалось перезапустить службу $1."
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "Услуга стоимостью 1 доллар запущена."
	else
		echo "Ошибка: не удалось запустить службу $1."
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "Служба $1 остановлена."
	else
		echo "Ошибка: не удалось остановить службу $1."
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "Показан статус услуги $1."
	else
		echo "Ошибка: невозможно отобразить статус услуги $1."
	fi
}

enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
		/bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME настроен на запуск при загрузке."
}

break_end() {
	echo -e "${gl_lv} Операция завершена ${gl_bai}"
	echo "Нажмите любую клавишу, чтобы продолжить..."
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
	echo -e "${gl_huang}Установка среды Docker...${gl_bai}"
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
		echo "Список контейнеров Docker"
		docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
		echo ""
		echo "Контейнерные операции"
		echo "------------------------"
		echo "1. Создайте новый контейнер"
		echo "------------------------"
		echo "2. Запустить указанный контейнер 6. Запустить все контейнеры"
		echo "3. Остановить указанный контейнер 7. Остановить все контейнеры"
		echo "4. Удалить указанный контейнер 8. Удалить все контейнеры"
		echo "5. Перезапустить указанный контейнер. 9. Перезапустить все контейнеры."
		echo "------------------------"
		echo "11. Войдите в указанный контейнер. 12. Просмотрите журнал контейнера."
		echo "13. Проверка контейнерной сети 14. Проверка занятости контейнера"
		echo "------------------------"
		echo "15. Включите доступ к порту контейнера. 16. Закройте доступ к порту контейнера."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
		case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "Введите команду создания:" dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			read -e -p "Введите имя контейнера (разделяйте несколько имен контейнеров пробелами):" dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "Введите имя контейнера (разделяйте несколько имен контейнеров пробелами):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			read -e -p "Введите имя контейнера (разделяйте несколько имен контейнеров пробелами):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			read -e -p "Введите имя контейнера (разделяйте несколько имен контейнеров пробелами):" dockername
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
			read -e -p "$(echo -e "${gl_hong}Примечание: ${gl_bai}Вы уверены, что хотите удалить все контейнеры? (да/нет):")" choice
			case "$choice" in
			[Yy])
				docker rm -f $(docker ps -a -q)
				;;
			[Nn]) ;;
			*)
				echo "Неверный выбор, введите Y или N."
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			read -e -p "Пожалуйста, введите имя контейнера:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			read -e -p "Пожалуйста, введите имя контейнера:" dockername
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
			read -e -p "Пожалуйста, введите имя контейнера:" docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "阻止容器端口访问"
			read -e -p "Пожалуйста, введите имя контейнера:" docker_name
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
		echo "Список образов Docker"
		docker image ls
		echo ""
		echo "Операция зеркала"
		echo "------------------------"
		echo "1. Получить указанное изображение 3. Удалить указанное изображение"
		echo "2. Обновить указанное изображение 4. Удалить все изображения"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
		case $sub_choice in
		1)
			send_stats "拉取镜像"
			read -e -p "Введите название изображения (разделяйте несколько названий изображений пробелами):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang} получает изображение: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			read -e -p "Введите название изображения (разделяйте несколько названий изображений пробелами):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang} обновляет изображение: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			read -e -p "Введите название изображения (разделяйте несколько названий изображений пробелами):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			read -e -p "$(echo -e "${gl_hong}Примечание: ${gl_bai}Вы уверены, что хотите удалить все изображения? (да/нет):")" choice
			case "$choice" in
			[Yy])
				docker rmi -f $(docker images -q)
				;;
			[Nn]) ;;
			*)
				echo "Неверный выбор, введите Y или N."
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
			echo "Неподдерживаемый дистрибутив: $ID"
			return
			;;
		esac
	else
		echo "Невозможно определить операционную систему."
		return
	fi

	echo -e "${gl_lv}crontab установлен и служба cron запущена. ${gl_bai}"
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
			echo -e "${gl_huang} в настоящее время включен доступ по протоколу ipv6 ${gl_bai}"
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
		echo -e "Файл конфигурации ${gl_hong} не существует ${gl_bai}"
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
		echo -e "${gl_huang} доступ к ipv6 в настоящее время закрыт ${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang} успешно закрыл доступ ipv6 к ${gl_bai}."
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
		echo "Укажите хотя бы один номер порта"
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
			echo "Открыт порт $port"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}

close_port() {
	local ports=($@) # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "Укажите хотя бы один номер порта"
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
			echo "Закрытый порт $port"
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
		echo "Укажите хотя бы один IP-адрес или IP-сегмент."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "Выпущен IP $ip"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@) # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "Укажите хотя бы один IP-адрес или IP-сегмент."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "Заблокированный IP $ip"
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
				echo "Ошибка: не удалось загрузить файл IP-зоны для $country_code."
				continue
			fi

			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip" 2>/dev/null
			done <"${country_code,,}.zone"

			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

			echo "IP-адрес для $country_code успешно заблокирован."
			rm "${country_code,,}.zone"
			;;

		allow)
			if ! ipset list "$ipset_name" &>/dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "Ошибка: не удалось загрузить файл IP-зоны для $country_code."
				continue
			fi

			ipset flush "$ipset_name"
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip" 2>/dev/null
			done <"${country_code,,}.zone"

			iptables -P INPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

			echo "IP-адрес для $country_code успешно разрешен."
			rm "${country_code,,}.zone"
			;;

		unblock)
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

			if ipset list "$ipset_name" &>/dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "Ограничение IP-адреса для $country_code успешно снято."
			;;

		*)
			echo "Использование: Manage_country_rules {block|allow|unblock} <код_страны...>"
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
		echo "Расширенное управление брандмауэром"
		send_stats "高级防火墙管理"
		echo "------------------------"
		iptables -L INPUT
		echo ""
		echo "Управление брандмауэром"
		echo "------------------------"
		echo "1. Откройте назначенный порт 2. Закройте назначенный порт"
		echo "3. Откройте все порты 4. Закройте все порты"
		echo "------------------------"
		echo "5. Белый список IP-адресов 6. Черный список IP-адресов"
		echo "7. Очистить указанный IP"
		echo "------------------------"
		echo "11. Разрешить PING 12. Отключить PING"
		echo "------------------------"
		echo "13. Запустить защиту от DDOS 14. Выключить защиту от DDOS"
		echo "------------------------"
		echo "15. Блокировать IP-адреса указанной страны. 16. Разрешить только IP-адреса указанной страны."
		echo "17. Снять ограничения по IP в определенных странах."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
		case $sub_choice in
		1)
			read -e -p "Пожалуйста, введите номер открытого порта:" o_port
			open_port $o_port
			send_stats "开放指定端口"
			;;
		2)
			read -e -p "Пожалуйста, введите номер закрытого порта:" c_port
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
			read -e -p "Пожалуйста, введите разрешенный IP-адрес или сегмент IP:" o_ip
			allow_ip $o_ip
			;;
		6)
			# IP 黑名单
			read -e -p "Пожалуйста, введите заблокированный IP-адрес или диапазон IP-адресов:" c_ip
			block_ip $c_ip
			;;
		7)
			# 清除指定 IP
			read -e -p "Пожалуйста, введите очищенный IP:" d_ip
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
			read -e -p "Введите заблокированный код страны (несколько кодов стран могут быть разделены пробелами, например CN US JP):" country_code
			manage_country_rules block $country_code
			send_stats "允许国家 $country_code 的IP"
			;;
		16)
			read -e -p "Введите разрешенные коды стран (несколько кодов стран могут быть разделены пробелами, например CN US JP):" country_code
			manage_country_rules allow $country_code
			send_stats "阻止国家 $country_code 的IP"
			;;

		17)
			read -e -p "Введите очищенный код страны (несколько кодов стран могут быть разделены пробелами, например CN US JP):" country_code
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

	echo -e "Размер виртуальной памяти изменен на ${gl_huang}${new_swap}${gl_bai}M."
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
	echo "Среда LDNMP установлена."
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
	echo "Задача продления обновлена"
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
	echo -e "${gl_huang}$yuming информация об открытом ключе${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming информация о закрытом ключе${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}Путь хранения сертификата${gl_bai}"
	echo "Открытый ключ: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "Закрытый ключ: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}

add_ssl() {
	echo -e "${gl_huang} Быстро подайте заявку на получение SSL-сертификата и автоматически продлите его до истечения срока действия ${gl_bai}"
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
	echo -e "${gl_huang}Статус срока действия примененного сертификата${gl_bai}"
	echo "Информация о сайте Срок действия сертификата"
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
		echo -e "${gl_hong}Примечание. ${gl_bai} Не удалось применить сертификат. Проверьте следующие возможные причины и повторите попытку:"
		echo -e "1. Доменное имя написано неправильно ➠ Проверьте, правильно ли введено доменное имя."
		echo -e "2. Проблема с разрешением DNS ➠ Убедитесь, что имя домена правильно преобразовано в IP-адрес сервера."
		echo -e "3. Проблемы с конфигурацией сети ➠ Если вы используете виртуальные сети, такие как Cloudflare Warp, временно выключите их."
		echo -e "4. Ограничения брандмауэра ➠ Проверьте, открыт ли порт 80/443, и убедитесь, что он доступен."
		echo -e "5. Количество заявок превышает лимит ➠ Let's Encrypt имеет недельный лимит (5 раз/доменное имя/неделю)."
		echo -e "6. Ограничения на регистрацию внутри страны ➠ Для материкового Китая подтвердите, зарегистрировано ли доменное имя."
		break_end
		clear
		echo "Пожалуйста, попробуйте развернуть $webname еще раз."
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
	echo -e "Сначала преобразуйте имя домена в локальный IP-адрес: ${gl_huang}$ipv4_address $ipv6_address${gl_bai}"
	read -e -p "Пожалуйста, введите свой IP-адрес или разрешенное доменное имя:" yuming
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
	echo "Обновление ${ldnmp_pods} завершено"

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
	echo "Информация для входа:"
	echo "Имя пользователя: $dbuse"
	echo "Пароль: $dbususepasswd"
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
		read -e -p "Хотите очистить кеш Cloudflare? (да/нет):" answer
		if [[ "$answer" == "y" ]]; then
			echo "Информация CF хранится в $CONFIG_FILE и может быть изменена позже."
			read -e -p "Пожалуйста, введите свой API_TOKEN:" API_TOKEN
			read -e -p "Пожалуйста, введите свое имя пользователя CF:" EMAIL
			read -e -p "Пожалуйста, введите Zone_id (разделяйте кратное число пробелами):" -a ZONE_IDS

			mkdir -p /home/web/config/
			echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" >"$CONFIG_FILE"
		fi
	fi

	# 循环遍历每个 zone_id 并执行清除缓存命令
	for ZONE_ID in "${ZONE_IDS[@]}"; do
		echo "Очистка кеша для Zone_id: $ZONE_ID"
		curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
			-H "X-Auth-Email: $EMAIL" \
			-H "X-Auth-Key: $API_TOKEN" \
			-H "Content-Type: application/json" \
			--data '{"purge_everything":true}'
	done

	echo "Запрос на очистку кэша отправлен."
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
		read -e -p "Чтобы удалить данные сайта, введите свое доменное имя (разделяйте несколько доменных имен пробелами):" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "Удаление доменного имени: $yuming"
		rm -r /home/web/html/$yuming >/dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "Удаление базы данных: $dbname"
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
		echo "Неверный аргумент: использование «включено» или «выключено»."
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
		echo "Неверный аргумент: использование «включено» или «выключено»."
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
		echo "Неверный аргумент: использование «включено» или «выключено»."
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
		echo "Неверный аргумент: использование «включено» или «выключено»."
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
		echo -e "Программа защиты сайта сервера ${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
		echo "------------------------"
		echo "1. Установите защитную программу"
		echo "------------------------"
		echo "5. Просмотр записей перехвата SSH 6. Просмотр записей перехвата веб-сайта"
		echo "7. Просмотр списка правил защиты. 8. Просмотр журналов для мониторинга в реальном времени."
		echo "------------------------"
		echo "11. Настроить параметры перехвата 12. Очистить все заблокированные IP-адреса"
		echo "------------------------"
		echo "21. Режим Cloudflare 22. Включить щит на 5 секунд при высокой нагрузке"
		echo "------------------------"
		echo "31. Включите WAF 32. Выключите WAF"
		echo "33. Включить защиту от DDOS 34. Выключить защиту от DDOS"
		echo "------------------------"
		echo "9. Удалите программу защиты."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
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
			echo "Защитная программа Fail2Ban удалена."
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
			echo "Перейдите в мой профиль в правом верхнем углу серверной части cf, выберите токен API слева и получите глобальный ключ API."
			echo "https://dash.cloudflare.com/login"
			read -e -p "Введите номер счета CF:" cfuser
			read -e -p "Введите глобальный ключ API CF:" cftoken

			wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
			docker exec nginx nginx -s reload

			cd /etc/fail2ban/jail.d/
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

			cd /etc/fail2ban/action.d
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

			sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
			sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
			f2b_status

			echo "Режим Cloudflare настроен, и запись перехвата можно просмотреть в фоновом режиме cf, site-security-events."
			;;

		22)
			send_stats "高负载开启5秒盾"
			echo -e "${gl_huang}Веб-сайт автоматически обнаруживает каждые 5 минут. Когда он обнаруживает высокую нагрузку, он автоматически открывает экран. Если нагрузка низкая, щиток автоматически закроется на 5 секунд. ${gl_bai}"
			echo "--------------"
			echo "Получить параметры CF:"
			echo -e "Перейдите в мой профиль в правом верхнем углу серверной части cf, выберите токен API слева и получите ${gl_huang}Global API Key${gl_bai}."
			echo -e "Перейдите в правый нижний угол страницы сводной информации о доменных именах серверной части cf, чтобы получить идентификатор области ${gl_huang} ${gl_bai}."
			echo "https://dash.cloudflare.com/login"
			echo "--------------"
			read -e -p "Введите номер счета CF:" cfuser
			read -e -p "Введите глобальный ключ API CF:" cftoken
			read -e -p "Введите идентификатор зоны доменного имени в CF:" cfzonID

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
				echo "Добавлен скрипт автоматического открытия щита при высокой нагрузке."
			else
				echo "Скрипт автоматического открытия щита уже существует, добавлять его не нужно."
			fi

			;;

		31)
			nginx_waf on
			echo "WAF сайта включен"
			send_stats "站点WAF已开启"
			;;

		32)
			nginx_waf off
			echo "Сайт WAF не работает"
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
		echo -e "Оптимизация среды LDNMP${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
		echo "------------------------"
		echo "1. Стандартный режим 2. Режим высокой производительности (рекомендуется 2H4G или выше)"
		echo "------------------------"
		echo "3. Включите сжатие gzip 4. Отключите сжатие gzip"
		echo "5. Включите сжатие br. 6. Выключите сжатие br."
		echo "7. Включите сжатие zstd 8. Отключите сжатие zstd"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
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

			echo "Среда LDNMP переведена в стандартный режим."

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

			echo "Среда LDNMP переведена в режим высокой производительности."

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
	echo "Адрес посещения:"
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

	echo "IP+порт заблокирован для доступа к сервису"
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

	echo "IP+порту разрешен доступ к сервису"
	save_iptables_rules
}

block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Ошибка: Укажите номер порта и IP-адрес, чтобы разрешить доступ."
		echo "Использование: block_host_port <номер порта> <разрешенный IP>"
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

	echo "IP+порт заблокирован для доступа к сервису"
	save_iptables_rules
}

clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Ошибка: Укажите номер порта и IP-адрес, чтобы разрешить доступ."
		echo "Использование:clear_host_port_rules <номер порта> <разрешенный IP>"
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

	echo "IP+порту разрешен доступ к сервису"
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
		echo "1. Установить 2. Обновить 3. Удалить"
		echo "------------------------"
		echo "5. Добавить доступ к доменному имени 6. Удалить доступ к доменному имени"
		echo "7. Разрешить доступ по IP+порту. 8. Заблокировать доступ по IP+порту."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" choice
		case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "Введите порт внешней службы приложения и нажмите Enter, чтобы использовать порт ${docker_port} по умолчанию:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_name установлен"
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
			echo "$docker_name установлен"
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
			echo "Приложение удалено"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "${docker_name}Настройки доступа к доменному имени"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "Формат доменного имени example.com без https://"
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
		echo "1. Установить 2. Обновить 3. Удалить"
		echo "------------------------"
		echo "5. Добавить доступ к доменному имени 6. Удалить доступ к доменному имени"
		echo "7. Разрешить доступ по IP+порту. 8. Заблокировать доступ по IP+порту."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice
		case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "Введите порт внешней службы приложения и нажмите Enter, чтобы использовать порт ${docker_port} по умолчанию:" app_port
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
			echo "${docker_name}Настройки доступа к доменному имени"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;
		6)
			echo "Формат доменного имени example.com без https://"
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

	read -e -p "$(echo -e "${gl_huang} приглашение: ${gl_bai} Перезапустить сервер сейчас? (да/нет):")" rboot
	case "$rboot" in
	[Yy])
		echo "Перезапущен"
		reboot
		;;
	*)
		echo "Отменено"
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
		echo -e "${gl_huang} Советы: ${gl_bai} среда создания веб-сайтов установлена. Нет необходимости устанавливать снова!"
		break_end
		linux_ldnmp
	fi

}

ldnmp_install_all() {
	cd ~
	send_stats "安装LDNMP环境"
	root_use
	clear
	echo -e "${gl_huang}Среда LDNMP не установлена, начните установку среды LDNMP...${gl_bai}"
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
	echo -e "${gl_huang}nginx не установлен, начните установку среды nginx...${gl_bai}"
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
	echo "nginx установлен"
	echo -e "Текущая версия: ${gl_huang}v$nginx_version${gl_bai}"
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
	echo "Ваше $webname настроено!"
	echo "https://$yuming"
	echo "------------------------"
	echo "Информация об установке $webname следующая:"

}

nginx_web_on() {
	clear
	echo "Ваше $webname настроено!"
	echo "https://$yuming"

}

ldnmp_wp() {
	clear
	# wordpress
	webname="WordPress"
	yuming="${1:-}"
	send_stats "安装$webname"
	echo "Начните развертывание $webname"
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
	webname="Обратный прокси-IP+порт"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "Начните развертывание $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "Пожалуйста, введите свой IP-адрес против поколения:" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "Пожалуйста, введите свой порт антигенерации:" port
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
	webname="Балансировка нагрузки обратного прокси-сервера"

	send_stats "安装$webname"
	echo "Начните развертывание $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "Введите несколько IP+портов для предотвращения генерации, разделенных пробелами (например, 127.0.0.1:3000 127.0.0.1:3002):" reverseproxy_port
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
		echo -e "Инструмент потоковой четырехуровневой переадресации прокси $check_docker $update_status"
		echo "NGINX Stream — это прокси-модуль TCP/UDP NGINX, который используется для обеспечения высокопроизводительной пересылки трафика транспортного уровня и балансировки нагрузки."
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. Установить 2. Обновить 3. Удалить"
		echo "------------------------"
		echo "4. Добавить службу переадресации 5. Изменить службу переадресации 6. Удалить службу переадресации"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice
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
			read -e -p "Вы уверены, что хотите удалить контейнер nginx? Это может повлиять на функциональность сайта! (да/нет):" confirm
			if [[ "$confirm" =~ ^[Yy]$ ]]; then
				docker rm -f nginx
				echo "Контейнер nginx был удален."
			else
				echo "Операция отменена."
			fi
			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			;;

		4)
			ldnmp_Proxy_backend_stream
			add_app_id
			;;
		5)
			send_stats "编辑转发配置"
			read -e -p "Введите название услуги, которую хотите изменить:" stream_name
			install nano
			nano /home/web/stream.d/$stream_name.conf
			docker restart nginx
			;;
		6)
			send_stats "删除转发配置"
			read -e -p "Пожалуйста, введите название службы, которую вы хотите удалить:" stream_name
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
	webname="Потоковая четырехуровневая балансировка нагрузки прокси-сервера"

	send_stats "安装$webname"
	echo "Начните развертывание $webname"

	# 获取代理名称
	read -rp "请输入代理转发名称 (如 mysql_proxy): " proxy_name
	if [ -z "$proxy_name" ]; then
		echo "Имя не может быть пустым"
		return 1
	fi

	# 获取监听端口
	read -rp "请输入本机监听端口 (如 3306): " listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "Порт должен быть числовым"
		return 1
	fi

	echo "Пожалуйста, выберите тип соглашения:"
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
		echo "Неверный выбор"
		return 1
		;;
	esac

	read -e -p "Введите один или несколько внутренних IP+портов, разделенных пробелами (например, 10.13.0.2:3306 10.13.0.3:3306):" reverseproxy_port

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
	echo "Ваше $webname настроено!"
	echo "------------------------"
	echo "Адрес посещения:"
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
		echo "среда LDNMP"
		echo "------------------------"
		ldnmp_v

		echo -e "Сайт: ${output} Срок действия сертификата"
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
		echo -e "База данных: ${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "каталог сайта"
		echo "------------------------"
		echo -e "Данные ${gl_hui}/home/web/html${gl_bai} Сертификат ${gl_hui}/home/web/certs${gl_bai} Конфигурация ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "действовать"
		echo "------------------------"
		echo "1. Примените/обновите сертификат доменного имени. 2. Клонируйте доменное имя сайта."
		echo "3. Очистить кеш сайта. 4. Создать связанный сайт."
		echo "5. Просмотр журнала доступа 6. Просмотр журнала ошибок"
		echo "7. Редактировать глобальную конфигурацию 8. Редактировать конфигурацию сайта"
		echo "9. Управление базой данных сайта. 10. Просмотр отчетов по анализу сайта."
		echo "------------------------"
		echo "20. Удалить указанные данные сайта."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
		case $sub_choice in
		1)
			send_stats "申请域名证书"
			read -e -p "Пожалуйста, введите ваше доменное имя:" yuming
			install_certbot
			docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
			install_ssltls
			certs_status

			;;

		2)
			send_stats "克隆站点域名"
			read -e -p "Пожалуйста, введите старое доменное имя:" oddyuming
			read -e -p "Пожалуйста, введите новое доменное имя:" yuming
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
			echo -e "Свяжите новое доменное имя с существующим сайтом для доступа"
			read -e -p "Пожалуйста, введите существующее доменное имя:" oddyuming
			read -e -p "Пожалуйста, введите новое доменное имя:" yuming
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
			read -e -p "Чтобы изменить конфигурацию сайта, введите доменное имя, которое вы хотите изменить:" yuming
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
		echo "${panelname} — популярная и мощная панель управления эксплуатацией и обслуживанием."
		echo "Официальный сайт: $panelurl"

		echo ""
		echo "------------------------"
		echo "1. Установить 2. Управление 3. Удалить"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" choice
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
	echo "Параметры, необходимые для развертывания клиента"
	echo "IP-адрес службы: $ipv4_address"
	echo "token: $token"
	echo
	echo "Информация о панели FRP"
	echo "Адрес панели FRP: http://$ipv4_address:$dashboard_port"
	echo "Имя пользователя панели FRP: $dashboard_user"
	echo "Пароль панели FRP: $dashboard_pwd"
	echo

	open_port 8055 8056

}

configure_frpc() {
	send_stats "安装frp客户端"
	read -e -p "Пожалуйста, введите IP-адрес док-станции внешней сети:" server_addr
	read -e -p "Введите токен стыковки внешней сети:" token
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
	read -e -p "Пожалуйста, введите название услуги:" service_name
	read -e -p "Пожалуйста, введите тип переадресации (tcp/udp) [Введите значение по умолчанию — TCP]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "Пожалуйста, введите IP-адрес интрасети [по умолчанию — 127.0.0.1 при нажатии Enter]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "Пожалуйста, введите порт интрасети:" local_port
	read -e -p "Пожалуйста, введите порт внешней сети:" remote_port

	# 将用户输入写入配置文件
	cat <<EOF >>/home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 输出生成的信息
	echo "Служба $service_name успешно добавлена ​​в frpc.toml"

	docker restart frpc

	open_port $local_port

}

delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	read -e -p "Пожалуйста, введите название услуги, которую необходимо удалить:" service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "Служба $service_name успешно удалена из frpc.toml."

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
		echo "Адрес внешнего доступа к сервису FRP:"

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
		echo -e "Сервер FRP $check_frp $update_status"
		echo "Создайте среду службы проникновения в интрасеть FRP и предоставьте доступ к Интернету устройствам без общедоступного IP-адреса."
		echo "Официальный сайт: https://github.com/fatedier/frp/"
		echo "Видеоурок: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. Установить 2. Обновить 3. Удалить"
		echo "------------------------"
		echo "5. Доступ к доменному имени службы интрасети. 6. Удаление доступа к доменному имени."
		echo "------------------------"
		echo "7. Разрешить доступ по IP+порту. 8. Заблокировать доступ по IP+порту."
		echo "------------------------"
		echo "00. Обновить статус услуги 0. Возврат в предыдущее меню."
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			generate_frps_config

			add_app_id
			echo "Сервер FRP установлен."
			;;
		2)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
			donlond_frp frps

			add_app_id
			echo "Сервер FRP обновлен."
			;;
		3)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine
			rm -rf /home/frp

			close_port 8055 8056

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "Приложение удалено"
			;;
		5)
			echo "Служба обратного проникновения в интранет для доступа к доменным именам"
			send_stats "FRP对外域名访问"
			add_yuming
			read -e -p "Пожалуйста, введите порт службы проникновения в интранет:" frps_port
			ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
			block_host_port "$frps_port" "$ipv4_address"
			;;
		6)
			echo "Формат доменного имени example.com без https://"
			web_del
			;;

		7)
			send_stats "允许IP访问"
			read -e -p "Пожалуйста, введите порт, который необходимо освободить:" frps_port
			clear_host_port_rules "$frps_port" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问"
			echo "Если у вас отменен доступ к доменному имени, вы можете использовать эту функцию, чтобы заблокировать доступ к порту IP+, что более безопасно."
			read -e -p "Пожалуйста, введите порт, который необходимо заблокировать:" frps_port
			block_host_port "$frps_port" "$ipv4_address"
			;;

		00)
			send_stats "刷新FRP服务状态"
			echo "Статус услуги FRP обновлен."
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
		echo -e "Клиент FRP $check_frp $update_status"
		echo "Подключитесь к серверу. После подключения вы можете создать службу проникновения в интранет для доступа в Интернет."
		echo "Официальный сайт: https://github.com/fatedier/frp/"
		echo "Видеоурок: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. Установить 2. Обновить 3. Удалить"
		echo "------------------------"
		echo "4. Добавить внешние службы 5. Удалить внешние службы 6. Настроить службы вручную"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			configure_frpc

			add_app_id
			echo "Клиент FRP установлен."
			;;
		2)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			donlond_frp frpc

			add_app_id
			echo "Клиент FRP обновлен."
			;;

		3)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine
			rm -rf /home/frp
			close_port 8055

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "Приложение удалено"
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
		echo -e "yt-dlp — это мощный инструмент для загрузки видео, который поддерживает тысячи сайтов, таких как YouTube, Bilibili, Twitter и т. д."
		echo -e "Официальный адрес сайта: https://github.com/yt-dlp/yt-dlp."
		echo "-------------------------"
		echo "Список скачанных видео:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(Пока нет)"
		echo "-------------------------"
		echo "1. Установить 2. Обновить 3. Удалить"
		echo "-------------------------"
		echo "5. Загрузка одного видео 6. Пакетная загрузка видео 7. Загрузка пользовательских параметров"
		echo "8. Загрузить как аудиофайл в формате MP3. 9. Удалить каталог видео. 10. Управление файлами cookie (в разработке)."
		echo "-------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "-------------------------"
		read -e -p "Пожалуйста, введите номер опции:" choice

		case $choice in
		1)
			send_stats "正在安装 yt-dlp..."
			echo "Установка yt-dlp..."
			install ffmpeg
			curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
			chmod a+rx /usr/local/bin/yt-dlp

			add_app_id
			echo "Установка завершена. Нажмите любую клавишу, чтобы продолжить..."
			read
			;;
		2)
			send_stats "正在更新 yt-dlp..."
			echo "Обновление yt-dlp..."
			yt-dlp -U

			add_app_id
			echo "Обновление завершено. Нажмите любую клавишу, чтобы продолжить..."
			read
			;;
		3)
			send_stats "正在卸载 yt-dlp..."
			echo "Удаление yt-dlp..."
			rm -f /usr/local/bin/yt-dlp

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "Удаление завершено. Нажмите любую клавишу, чтобы продолжить..."
			read
			;;
		5)
			send_stats "单个视频下载"
			read -e -p "Пожалуйста, введите ссылку на видео:" url
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			read -e -p "Загрузка завершена. Нажмите любую клавишу, чтобы продолжить..."
			;;
		6)
			send_stats "批量视频下载"
			install nano
			if [ ! -f "$URL_FILE" ]; then
				echo -e "# Введите несколько адресов ссылок на видео\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" >"$URL_FILE"
			fi
			nano $URL_FILE
			echo "Начать пакетную загрузку сейчас..."
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-a "$URL_FILE" \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			read -e -p "Пакетная загрузка завершена. Нажмите любую клавишу, чтобы продолжить..."
			;;
		7)
			send_stats "自定义视频下载"
			read -e -p "Введите полные параметры yt-dlp (за исключением yt-dlp):" custom
			yt-dlp -P "$VIDEO_DIR" $custom \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			read -e -p "Выполнение завершено, нажмите любую клавишу, чтобы продолжить..."
			;;
		8)
			send_stats "MP3下载"
			read -e -p "Пожалуйста, введите ссылку на видео:" url
			yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			read -e -p "Загрузка аудио завершена. Нажмите любую клавишу, чтобы продолжить..."
			;;

		9)
			send_stats "删除视频"
			read -e -p "Пожалуйста, введите название удаленного видео:" rmdir
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
	echo -e "${gl_huang}Выполняется обновление системы...${gl_bai}"
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
		echo "Неизвестный менеджер пакетов!"
		return
	fi
}

linux_clean() {
	echo -e "${gl_huang} очищает систему... ${gl_bai}"
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
		echo "Очистить кеш менеджера пакетов..."
		apk cache clean
		echo "Удалить системный журнал..."
		rm -rf /var/log/*
		echo "Удалить кэш APK..."
		rm -rf /var/cache/apk/*
		echo "Удалить временные файлы..."
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
		echo "Удалить системный журнал..."
		rm -rf /var/log/*
		echo "Удалить временные файлы..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "Очистите неиспользуемые зависимости..."
		pkg autoremove -y
		echo "Очистить кеш менеджера пакетов..."
		pkg clean -y
		echo "Удалить системный журнал..."
		rm -rf /var/log/*
		echo "Удалить временные файлы..."
		rm -rf /tmp/*

	else
		echo "Неизвестный менеджер пакетов!"
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
		echo "Оптимизировать DNS-адрес"
		echo "------------------------"
		echo "Текущий DNS-адрес"
		cat /etc/resolv.conf
		echo "------------------------"
		echo ""
		echo "1. Оптимизация зарубежного DNS:"
		echo " v4: 1.1.1.1 8.8.8.8"
		echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
		echo "2. Внутренняя оптимизация DNS:"
		echo " v4: 223.5.5.5 183.60.83.19"
		echo " v6: 2400:3200::1 2400:da00::6666"
		echo "3. Отредактируйте конфигурацию DNS вручную."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" Limiting
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

	echo "Порт SSH был изменен на: $new_port."

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
	echo -e "Информация о закрытом ключе была сгенерирована. Обязательно скопируйте и сохраните его. Его можно сохранить как файл ${gl_huang}${ipv4_address}_ssh.key${gl_bai} для будущего входа по SSH."

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT-вход с закрытым ключом включен, вход с ROOT-паролем отключен, переподключение вступит в силу ${gl_bai}"

}

import_sshkey() {

	read -e -p "Введите содержимое вашего открытого ключа SSH (обычно начинается с «ssh-rsa» или «ssh-ed25519»):" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong} Ошибка: содержимое открытого ключа не введено. ${gl_bai}"
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
	echo -e "${gl_lv}Открытый ключ успешно импортирован, вход с закрытым ключом ROOT включен, вход с паролем ROOT закрыт, повторное подключение вступит в силу${gl_bai}"

}

add_sshpasswd() {

	echo "Установите свой ROOT-пароль"
	passwd
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}Настройка входа в ROOT завершена! ${gl_bai}"

}

root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${gl_huang} Совет: ${gl_bai} Для запуска этой функции требуется пользователь root!" && break_end && kejilion
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
		echo -e "Начальное имя пользователя после переустановки: ${gl_huang}root${gl_bai} Начальный пароль: ${gl_huang}LeitboGi0ro${gl_bai} Начальный порт: ${gl_huang}22${gl_bai}"
		echo -e "Нажмите любую клавишу, чтобы продолжить..."
		read -n 1 -s -r -p ""
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_2() {
		echo -e "Начальное имя пользователя после переустановки: ${gl_huang}Администратор${gl_bai} Начальный пароль: ${gl_huang}Teddysun.com${gl_bai} Начальный порт: ${gl_huang}3389${gl_bai}"
		echo -e "Нажмите любую клавишу, чтобы продолжить..."
		read -n 1 -s -r -p ""
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_3() {
		echo -e "Начальное имя пользователя после переустановки: ${gl_huang}root${gl_bai} Начальный пароль: ${gl_huang}123@@@${gl_bai} Начальный порт: ${gl_huang}22${gl_bai}"
		echo -e "Нажмите любую клавишу, чтобы продолжить..."
		read -n 1 -s -r -p ""
		dd_xitong_bin456789
	}

	dd_xitong_4() {
		echo -e "Начальное имя пользователя после переустановки: ${gl_huang}Администратор${gl_bai} Начальный пароль: ${gl_huang}123@@@${gl_bai} Начальный порт: ${gl_huang}3389${gl_bai}"
		echo -e "Нажмите любую клавишу, чтобы продолжить..."
		read -n 1 -s -r -p ""
		dd_xitong_bin456789
	}

	while true; do
		root_use
		echo "Переустановите систему"
		echo "--------------------------------"
		echo -e "${gl_hong} Примечание. ${gl_bai} Переустановка может привести к потере соединения. Если вы беспокоитесь, используйте его с осторожностью. Ожидается, что переустановка займет 15 минут. Пожалуйста, заранее сделайте резервную копию данных."
		echo -e "${gl_hui} Спасибо боссу leitbogioro и боссу bin456789 за поддержку сценариев! ${gl_bai}"
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
		echo "35. openSUSE Tumbleweed 36. Публичная бета-версия fnos Feiniu"
		echo "------------------------"
		echo "41. Windows 11                42. Windows 10"
		echo "43. Windows 7                 44. Windows Server 2025"
		echo "45. Windows Server 2022       46. Windows Server 2019"
		echo "47. Windows 11 ARM"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, выберите систему, которую вы хотите переустановить:" sys_choice
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
			echo "У вас установлено ядро ​​xanmod BBRv3."
			echo "Текущая версия ядра: $kernel_version."

			echo ""
			echo "Управление ядром"
			echo "------------------------"
			echo "1. Обновите ядро ​​BBRv3. 2. Удалите ядро ​​BBRv3."
			echo "------------------------"
			echo "0. Вернуться в предыдущее меню"
			echo "------------------------"
			read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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

				echo "Ядро XanMod обновлено. Вступит в силу после перезапуска"
				rm -f /etc/apt/sources.list.d/xanmod-release.list
				rm -f check_x86-64_psabi.sh*

				server_reboot

				;;
			2)
				apt purge -y 'linux-*xanmod1*'
				update-grub
				echo "Ядро XanMod было удалено. Вступит в силу после перезапуска"
				server_reboot
				;;

			*)
				break # 跳出循环，退出菜单
				;;

			esac
		done
	else

		clear
		echo "Настройте ускорение BBR3"
		echo "Видео-знакомство: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		echo "------------------------------------------------"
		echo "Поддерживает только Debian/Ubuntu."
		echo "Пожалуйста, сделайте резервную копию ваших данных, и мы обновим ваше ядро ​​Linux и включим BBR3."
		echo "------------------------------------------------"
		read -e -p "Вы уверены, что хотите продолжить? (да/нет):" choice

		case "$choice" in
		[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "Текущая среда не поддерживает это. Поддерживаются только системы Debian и Ubuntu."
					break_end
					linux_Settings
				fi
			else
				echo "Невозможно определить тип операционной системы"
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

			echo "Ядро XanMod установлено, и BBR3 успешно включен. Вступит в силу после перезапуска"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			;;
		[Nn])
			echo "Отменено"
			;;
		*)
			echo "Неверный выбор, введите Y или N."
			;;
		esac
	fi

}

elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "Импортируйте открытый ключ ELRepo GPG..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "Неподдерживаемые операционные системы: $os_name."
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "Обнаруженная операционная система: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ "$os_version" == 8 ]]; then
		echo "Установка конфигурации репозитория ELRepo (версия 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "Установка конфигурации репозитория ELRepo (версия 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "Установка конфигурации репозитория ELRepo (версия 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "Неподдерживаемая версия системы: $os_version."
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "Включите репозиторий ядра ELRepo и установите последнюю версию основного ядра..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "Установлена ​​конфигурация репозитория ELRepo и обновлена ​​до последней версии основного ядра."
	server_reboot

}

elrepo() {
	root_use
	send_stats "红帽内核管理"
	if uname -r | grep -q 'elrepo'; then
		while true; do
			clear
			kernel_version=$(uname -r)
			echo "Вы установили ядро ​​elrepo"
			echo "Текущая версия ядра: $kernel_version."

			echo ""
			echo "Управление ядром"
			echo "------------------------"
			echo "1. Обновите ядро ​​elrepo 2. Удалите ядро ​​elrepo"
			echo "------------------------"
			echo "0. Вернуться в предыдущее меню"
			echo "------------------------"
			read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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
				echo "Ядро elrepo было удалено. Вступит в силу после перезапуска"
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
		echo "Пожалуйста, сделайте резервную копию ваших данных, и мы обновим ядро ​​Linux для вас."
		echo "Видео-знакомство: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		echo "------------------------------------------------"
		echo "Поддерживается только дистрибутивы серии Red Hat CentOS/RedHat/Alma/Rocky/oracle."
		echo "Обновление ядра Linux может улучшить производительность и безопасность системы. Рекомендуется попробовать, если это возможно, и с осторожностью обновлять производственную среду!"
		echo "------------------------------------------------"
		read -e -p "Вы уверены, что хотите продолжить? (да/нет):" choice

		case "$choice" in
		[Yy])
			check_swap
			elrepo_install
			send_stats "升级红帽内核"
			server_reboot
			;;
		[Nn])
			echo "Отменено"
			;;
		*)
			echo "Неверный выбор, введите Y или N."
			;;
		esac
	fi

}

clamav_freshclam() {
	echo -e "${gl_huang}Обновление вирусных баз...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "Укажите каталоги для сканирования."
		return
	fi

	echo -e "${gl_huang} Каталог сканирования $@... ${gl_bai}"

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

	echo -e "${gl_lv}$@ Сканирование завершено, и отчет о вирусе сохраняется в ${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}."
	echo -e "${gl_lv} Если есть вирус, найдите ключевое слово FOUND в файле ${gl_huang}scan.log${gl_lv}, чтобы подтвердить местонахождение вируса ${gl_bai}"

}

clamav() {
	root_use
	send_stats "病毒扫描管理"
	while true; do
		clear
		echo "инструмент сканирования вирусов clamav"
		echo "Видео-знакомство: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
		echo "------------------------"
		echo "Это антивирусное программное обеспечение с открытым исходным кодом, которое в основном используется для обнаружения и удаления различных типов вредоносных программ."
		echo "Включает вирусы, троянские кони, шпионское ПО, вредоносные сценарии и другое вредоносное программное обеспечение."
		echo "------------------------"
		echo -e "${gl_lv}1. Полная проверка ${gl_bai} ${gl_huang}2. Сканирование важных каталогов ${gl_bai} ${gl_kjlan} 3. Настраиваемое сканирование каталогов ${gl_bai}"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
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
			read -e -p "Введите каталоги для сканирования, разделенные пробелами (например: /etc /var /usr /home /root):" directories
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
	echo -e "${gl_lv} переключается на ${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv} Оптимизировать дескриптор файла...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv} Оптимизация виртуальной памяти...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}Оптимизировать настройки сети...${gl_bai}"
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

	echo -e "${gl_lv} Оптимизация управления кэшем...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv} Оптимизировать настройки ЦП... ${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}Другие оптимизации...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv} Переключиться в режим эквализации...${gl_bai}"

	echo -e "${gl_lv} Оптимизировать дескриптор файла...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv} Оптимизация виртуальной памяти...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}Оптимизировать настройки сети...${gl_bai}"
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

	echo -e "${gl_lv} Оптимизация управления кэшем...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv} Оптимизировать настройки ЦП... ${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}Другие оптимизации...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}Восстановить настройки по умолчанию...${gl_bai}"

	echo -e "${gl_lv}Восстановить дескриптор файла...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}Восстановить виртуальную память...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}Восстановить настройки сети...${gl_bai}"
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

	echo -e "${gl_lv}Восстановить управление кэшем...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}Восстановить настройки ЦП...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}Восстановить другие оптимизации...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}Перейти в режим оптимизации построения сайта...${gl_bai}"

	echo -e "${gl_lv} Оптимизировать дескриптор файла...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv} Оптимизация виртуальной памяти...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}Оптимизировать настройки сети...${gl_bai}"
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

	echo -e "${gl_lv} Оптимизация управления кэшем...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv} Оптимизировать настройки ЦП... ${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}Другие оптимизации...${gl_bai}"
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
		echo "Оптимизация параметров ядра системы Linux"
		echo "Видео-знакомство: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
		echo "------------------------------------------------"
		echo "Предоставляет различные режимы настройки параметров системы, и пользователи могут переключаться в соответствии со своими сценариями использования."
		echo -e "${gl_huang} Советы: ${gl_bai} Используйте его с осторожностью в производственной среде!"
		echo "--------------------"
		echo "1. Режим высокопроизводительной оптимизации: максимизируйте производительность системы и оптимизируйте файловые дескрипторы, виртуальную память, настройки сети, управление кэшем и настройки ЦП."
		echo "2. Режим сбалансированной оптимизации: обеспечивает баланс между производительностью и потреблением ресурсов, подходящий для ежедневного использования."
		echo "3. Режим оптимизации веб-сайта. Оптимизируйте сервер веб-сайта для улучшения возможностей обработки одновременных соединений, скорости ответа и общей производительности."
		echo "4. Режим оптимизации прямой трансляции: оптимизируйте особые потребности прямой трансляции, чтобы уменьшить задержки и улучшить производительность передачи."
		echo "5. Режим оптимизации игрового сервера: оптимизируйте игровой сервер для улучшения возможностей одновременной обработки и скорости ответа."
		echo "6. Восстановить настройки по умолчанию: восстановить настройки системы до конфигурации по умолчанию."
		echo "--------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "--------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
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
			echo -e "${gl_lv}Системный язык был изменен на: $lang. Это вступит в силу после повторного подключения SSH. ${gl_bai}"
			hash -r
			break_end

			;;
		centos | rhel | almalinux | rocky | fedora)
			install glibc-langpack-zh
			localectl set-locale LANG=${lang}
			echo "LANG=${lang}" | tee /etc/locale.conf
			echo -e "${gl_lv}Системный язык был изменен на: $lang. Это вступит в силу после повторного подключения SSH. ${gl_bai}"
			hash -r
			break_end
			;;
		*)
			echo "Неподдерживаемые системы: $ID"
			break_end
			;;
		esac
	else
		echo "Неподдерживаемая система, тип системы не может быть идентифицирован."
		break_end
	fi
}

linux_language() {
	root_use
	send_stats "切换系统语言"
	while true; do
		clear
		echo "Текущий системный язык: $LANG."
		echo "------------------------"
		echo "1. Английский 2. Упрощенный китайский 3. Традиционный китайский"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice

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
	echo -e "${gl_lv} Изменение завершено. Повторно подключитесь к SSH, чтобы увидеть изменения! ${gl_bai}"

	hash -r
	break_end

}

shell_bianse() {
	root_use
	send_stats "命令行美化工具"
	while true; do
		clear
		echo "Инструмент украшения командной строки"
		echo "------------------------"
		echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
		echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
		echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
		echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
		echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
		echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
		echo -e "7. root localhost ~ #"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice

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
		echo -e "Текущая корзина ${trash_status}"
		echo -e "После включения файлы, удаленные rm, сначала будут помещены в корзину, чтобы предотвратить случайное удаление важных файлов!"
		echo "------------------------------------------------"
		ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "Корзина пуста"
		echo "------------------------"
		echo "1. Включить корзину 2. Закрыть корзину"
		echo "3. Восстановить содержимое. 4. Очистить корзину."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice

		case $choice in
		1)
			install trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='trash-put'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "Корзина включена, удаленные файлы будут перемещены в корзину."
			sleep 2
			;;
		2)
			remove trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='rm -i'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "Корзина закрывается, и файлы будут удалены напрямую."
			sleep 2
			;;
		3)
			read -e -p "Введите имя файла, который необходимо восстановить:" file_to_restore
			if [ -e "$TRASH_DIR/$file_to_restore" ]; then
				mv "$TRASH_DIR/$file_to_restore" "$HOME/"
				echo "$file_to_restore восстановлен в домашнем каталоге."
			else
				echo "Файл не существует."
			fi
			;;
		4)
			read -e -p "Вы уверены, что хотите очистить корзину? [да/нет]:" confirm
			if [[ "$confirm" == "y" ]]; then
				trash-empty
				echo "Корзина очищена."
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
	echo "Пример создания резервной копии:"
	echo "- Создайте резервную копию одного каталога: /var/www."
	echo "- Резервное копирование нескольких каталогов: /etc/home/var/log"
	echo "- Нажмите Enter, чтобы использовать каталог по умолчанию (/etc/usr/home)."
	read -r -p "Введите каталог для резервного копирования (разделите несколько каталогов пробелами и нажмите Enter, чтобы использовать каталог по умолчанию):" input

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
	echo "Выбранный вами каталог резервной копии:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "Создание резервной копии $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "Резервная копия успешно создана: $BACKUP_DIR/$BACKUP_NAME."
	else
		echo "Не удалось создать резервную копию!"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	read -e -p "Пожалуйста, введите имя файла резервной копии, который нужно восстановить:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "Файл резервной копии не существует!"
		exit 1
	fi

	echo "Восстановление резервной копии $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "Резервное копирование и восстановление успешно!"
	else
		echo "Восстановление резервной копии не удалось!"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "Доступные резервные копии:"
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	read -e -p "Пожалуйста, введите имя файла резервной копии, который нужно удалить:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "Файл резервной копии не существует!"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "Резервная копия успешно удалена!"
	else
		echo "Удаление резервной копии не удалось!"
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
		echo "Функция резервного копирования системы"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. Создать резервную копию 2. Восстановить резервную копию 3. Удалить резервную копию"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" choice
		case $choice in
		1) create_backup ;;
		2) restore_backup ;;
		3) delete_backup ;;
		*) break ;;
		esac
		read -e -p "Нажмите Enter, чтобы продолжить..."
	done
}

# 显示连接列表
list_connections() {
	echo "Сохраненные соединения:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}

# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "Пример создания нового соединения:"
	echo "- Имя соединения: my_server"
	echo "- IP-адрес: 192.168.1.100"
	echo "- Имя пользователя: root"
	echo "- Порт: 22"
	echo "------------------------"
	read -e -p "Пожалуйста, введите имя подключения:" name
	read -e -p "Пожалуйста, введите IP-адрес:" ip
	read -e -p "Пожалуйста, введите имя пользователя (по умолчанию: root):" user
	local user=${user:-root} # 如果用户未输入，则使用默认值 root
	read -e -p "Пожалуйста, введите номер порта (по умолчанию: 22):" port
	local port=${port:-22} # 如果用户未输入，则使用默认值 22

	echo "Пожалуйста, выберите метод аутентификации:"
	echo "1. Пароль"
	echo "2. Ключ"
	read -e -p "Пожалуйста, введите ваш выбор (1/2):" auth_choice

	case $auth_choice in
	1)
		read -s -p "请输入密码: " password_or_key
		echo # 换行
		;;
	2)
		echo "Вставьте ключевое содержимое (дважды нажмите Enter после вставки):"
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
		echo "Неверный выбор!"
		return
		;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >>"$CONFIG_FILE"
	echo "Соединение сохранено!"
}

# 删除连接
delete_connection() {
	send_stats "删除连接"
	read -e -p "Пожалуйста, введите номер соединения, которое необходимо удалить:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Ошибка: Соответствующее соединение не найдено."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "Соединение удалено!"
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	read -e -p "Пожалуйста, введите номер подключения для использования:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Ошибка: Соответствующее соединение не найдено."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	echo "Подключение к $name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "Соединение не удалось! Пожалуйста, проверьте следующее:"
			echo "1. Правильный ли путь к файлу ключей: $password_or_key"
			echo "2. Правильны ли права доступа к ключевому файлу (должно быть 600)."
			echo "3. Разрешает ли целевой сервер вход в систему с использованием ключа."
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &>/dev/null; then
			echo "Ошибка: sshpass не установлен, сначала установите sshpass."
			echo "Способ установки:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "Соединение не удалось! Пожалуйста, проверьте следующее:"
			echo "1. Правильно ли указаны имя пользователя и пароль?"
			echo "2. Разрешает ли целевой сервер вход по паролю."
			echo "3. Нормально ли работает служба SSH целевого сервера."
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
		echo "Инструмент удаленного подключения SSH"
		echo "Может подключаться к другим системам Linux через SSH."
		echo "------------------------"
		list_connections
		echo "1. Создать новое соединение 2. Использовать соединение 3. Удалить соединение"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" choice
		case $choice in
		1) add_connection ;;
		2) use_connection ;;
		3) delete_connection ;;
		0) break ;;
		*) echo "Неверный выбор, попробуйте еще раз." ;;
		esac
	done
}

# 列出可用的硬盘分区
list_partitions() {
	echo "Доступные разделы жесткого диска:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	read -e -p "Введите имя монтируемого раздела (например, sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "Раздел не существует!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "Раздел смонтирован!"
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "Раздел успешно смонтирован: $MOUNT_POINT"
	else
		echo "Монтирование раздела не удалось!"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	read -e -p "Введите имя раздела, который нужно размонтировать (например, sda1):" PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "Раздел не монтируется!"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "Раздел успешно размонтирован: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "Удаление раздела не удалось!"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "Подключенные разделы:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	read -e -p "Введите имя раздела, который нужно отформатировать (например, sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "Раздел не существует!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "Раздел смонтирован, сначала отключите его!"
		return
	fi

	# 选择文件系统类型
	echo "Пожалуйста, выберите тип файловой системы:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "Пожалуйста, введите ваш выбор:" FS_CHOICE

	case $FS_CHOICE in
	1) FS_TYPE="ext4" ;;
	2) FS_TYPE="xfs" ;;
	3) FS_TYPE="ntfs" ;;
	4) FS_TYPE="vfat" ;;
	*)
		echo "Неверный выбор!"
		return
		;;
	esac

	# 确认格式化
	read -e -p "Подтвердите, что отформатированный раздел /dev/$PARTITION имеет тип $FS_TYPE? (да/нет):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "Операция отменена."
		return
	fi

	# 格式化分区
	echo "Форматирование раздела /dev/$PARTITION в $FS_TYPE..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "Раздел успешно отформатирован!"
	else
		echo "Форматирование раздела не удалось!"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	read -e -p "Введите имя раздела для проверки (например, sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "Раздел не существует!"
		return
	fi

	# 检查分区状态
	echo "Проверьте состояние раздела /dev/$PARTITION:"
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "Управление разделами жесткого диска"
		echo -e "${gl_huang} Эта функция находится на стадии внутреннего тестирования, не используйте ее в производственной среде. ${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. Подключите раздел 2. Отключите раздел 3. Просмотрите смонтированный раздел"
		echo "4. Отформатируйте раздел. 5. Проверьте состояние раздела."
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" choice
		case $choice in
		1) mount_partition ;;
		2) unmount_partition ;;
		3) list_mounted_partitions ;;
		4) format_partition ;;
		5) check_partition ;;
		*) break ;;
		esac
		read -e -p "Нажмите Enter, чтобы продолжить..."
	done
}

# 显示任务列表
list_tasks() {
	echo "Сохраненные задачи синхронизации:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
	echo "Пример создания новой задачи синхронизации:"
	echo "- Имя задачи: backup_www."
	echo "- Локальный каталог: /var/www"
	echo "- Удаленный адрес: user@192.168.1.100."
	echo "- Удаленный каталог: /backup/www."
	echo "- Номер порта (по умолчанию 22)"
	echo "---------------------------------"
	read -e -p "Введите название задачи:" name
	read -e -p "Пожалуйста, введите локальный каталог:" local_path
	read -e -p "Пожалуйста, введите удаленный каталог:" remote_path
	read -e -p "Пожалуйста, введите удаленный user@IP:" remote
	read -e -p "Пожалуйста, введите порт SSH (по умолчанию 22):" port
	port=${port:-22}

	echo "Пожалуйста, выберите метод аутентификации:"
	echo "1. Пароль"
	echo "2. Ключ"
	read -e -p "Пожалуйста, выберите (1/2):" auth_choice

	case $auth_choice in
	1)
		read -s -p "请输入密码: " password_or_key
		echo # 换行
		auth_method="password"
		;;
	2)
		echo "Вставьте ключевое содержимое (дважды нажмите Enter после вставки):"
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
			echo "Неверное содержание ключа!"
			return
		fi
		;;
	*)
		echo "Неверный выбор!"
		return
		;;
	esac

	echo "Пожалуйста, выберите режим синхронизации:"
	echo "1. Стандартный режим (-avz)"
	echo "2. Удалить целевой файл (-avz --delete)"
	read -e -p "Пожалуйста, выберите (1/2):" mode
	case $mode in
	1) options="-avz" ;;
	2) options="-avz --delete" ;;
	*)
		echo "Неверный выбор, используйте -avz по умолчанию."
		options="-avz"
		;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >>"$CONFIG_FILE"

	install rsync rsync

	echo "Миссия сохранена!"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	read -e -p "Пожалуйста, введите номер задачи, которую необходимо удалить:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "Ошибка: Соответствующая задача не найдена."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "Задача удалена!"
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
		read -e -p "Введите номер задачи, которую необходимо выполнить:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "Ошибка: Задача не найдена!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 根据同步方向调整源和目标路径
	if [[ "$direction" == "pull" ]]; then
		echo "Извлечение и синхронизация с локальным: $remote:$local_path -> $remote_path."
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "Отправка и синхронизация с удаленным концом: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &>/dev/null; then
			echo "Ошибка: sshpass не установлен, сначала установите sshpass."
			echo "Способ установки:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f "$password_or_key" ]]; then
			echo "Ошибка: файл ключа не существует: $password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "Предупреждение: неправильные права доступа к файлу ключей, исправление..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "Синхронизация завершена!"
	else
		echo "Синхронизация не удалась! Пожалуйста, проверьте следующее:"
		echo "1. Сетевое соединение нормальное?"
		echo "2. Доступен ли удаленный хост?"
		echo "3. Верна ли информация аутентификации?"
		echo "4. Имеют ли локальный и удаленный каталог правильные права доступа?"
	fi
}

# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	read -e -p "Пожалуйста, введите номер задачи для регулярной синхронизации:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Ошибка: Введите действительный номер задачи!"
		return
	fi

	echo "Пожалуйста, выберите запланированный интервал выполнения:"
	echo "1) Выполнять раз в час"
	echo "2) Выполнять один раз в день"
	echo "3) Выполнять раз в неделю."
	read -e -p "Пожалуйста, введите варианты (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1) # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
	1) cron_time="$random_minute * * * *" ;; # 每小时，随机分钟执行
	2) cron_time="$random_minute 0 * * *" ;; # 每天，随机分钟执行
	3) cron_time="$random_minute 0 * * 1" ;; # 每周，随机分钟执行
	*)
		echo "Ошибка: Введите допустимые параметры!"
		return
		;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "Ошибка: запланированная синхронизация для этой задачи уже существует!"
		return
	fi

	# 创建到用户的 crontab
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "Запланированная задача создана: $cron_job."
}

# 查看定时任务
view_tasks() {
	echo "Текущие запланированные задачи:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	read -e -p "Пожалуйста, введите номер задачи, которую необходимо удалить:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Ошибка: Введите действительный номер задачи!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "Запланированная задача с номером $num удалена."
}

# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Инструмент удаленной синхронизации Rsync"
		echo "Синхронизация между удаленными каталогами поддерживает инкрементную синхронизацию, которая является эффективной и стабильной."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. Создать новую задачу 2. Удалить задачу"
		echo "3. Выполните локальную синхронизацию с удаленным сайтом. 4. Выполните удаленную синхронизацию с локальным сайтом."
		echo "5. Создать запланированное задание 6. Удалить запланированное задание"
		echo "---------------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "---------------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" choice
		case $choice in
		1) add_task ;;
		2) delete_task ;;
		3) run_task push ;;
		4) run_task pull ;;
		5) schedule_task ;;
		6) delete_task_schedule ;;
		0) break ;;
		*) echo "Неверный выбор, попробуйте еще раз." ;;
		esac
		read -e -p "Нажмите Enter, чтобы продолжить..."
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
	echo -e "Запрос информации о системе"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}имя_хоста: ${gl_bai}$имя_хоста"
	echo -e "${gl_kjlan}Версия системы: ${gl_bai}$os_info"
	echo -e "${gl_kjlan}Версия Linux: ${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Архитектура ЦП: ${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}Модель процессора: ${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}Количество ядер ЦП: ${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}Частота процессора: ${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Загрузка ЦП: ${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan} загрузка системы: ${gl_bai}$load"
	echo -e "${gl_kjlan}Физическая память: ${gl_bai}$mem_info"
	echo -e "${gl_kjlan}Виртуальная память: ${gl_bai}$swap_info"
	echo -e "${gl_kjlan}Использование жесткого диска: ${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Всего получено: ${gl_bai}$rx"
	echo -e "${gl_kjlan}Всего отправлено: ${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Сетевой алгоритм: ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Оператор: ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4-адрес: ${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6-адрес: ${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS-адреса: ${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}Географическое положение: ${gl_bai}$country $city"
	echo -e "${gl_kjlan}Системное время: ${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan} время выполнения: ${gl_bai}$время выполнения"
	echo

}

linux_tools() {

	while true; do
		clear
		# send_stats "基础工具"
		echo -e "основные инструменты"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai}curl инструмент загрузки ${gl_huang}★${gl_bai} ${gl_kjlan}2. ${gl_bai}инструмент загрузки wget ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}3. ${gl_bai}sudo инструмент управления привилегиями суперпользователя ${gl_kjlan}4. ${gl_bai}инструмент подключения связи socat"
		echo -e "${gl_kjlan}5. ${gl_bai}htop инструмент мониторинга системы ${gl_kjlan}6. ${gl_bai}iftop инструмент мониторинга сетевого трафика"
		echo -e "${gl_kjlan}7. ${gl_bai}разархивируйте ZIP-архив с помощью инструмента сжатия и распаковки ${gl_kjlan}8. ${gl_bai}tar GZ инструмент сжатия и распаковки"
		echo -e "__ЗАЩИТА_0__9. ${gl_bai}tmux многоканальный инструмент фоновой работы ${gl_kjlan}10. ${gl_bai}ffmpeg инструмент для кодирования видео в реальном времени"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11. ${gl_bai}btop Современный инструмент мониторинга ${gl_huang}★${gl_bai} ${gl_kjlan}12. ${gl_bai}ranger Инструмент управления файлами"
		echo -e "${gl_kjlan}13. ${gl_bai}ncdu инструмент просмотра использования диска ${gl_kjlan}14. ${gl_bai}fzf инструмент глобального поиска"
		echo -e "${gl_kjlan}15. ${gl_bai}текстовый редактор vim ${gl_kjlan}16. ${gl_bai}текстовый редактор nano ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}17. ${gl_bai}git система контроля версий"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21. ${gl_bai}Заставка «Матрица» ${gl_kjlan}22. ${gl_bai}Заставка «Поезд»"
		echo -e "${gl_kjlan}26. ${gl_bai} Мини-игра Тетрис ${gl_kjlan}27. ${gl_bai} Змеиная мини-игра"
		echo -e "${gl_kjlan}28. ${gl_bai} Мини-игра «Космические захватчики»"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31. ${gl_bai}Все установлено ${gl_kjlan}32. ${gl_bai}Все установлено (кроме заставок и игр) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33. ${gl_bai}Удалить все"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41. ${gl_bai}Установите указанный инструмент ${gl_kjlan}42. ${gl_bai}Удалить указанный инструмент"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

		case $sub_choice in
		1)
			clear
			install curl
			clear
			echo "Инструмент установлен и используется следующим образом:"
			curl --help
			send_stats "安装curl"
			;;
		2)
			clear
			install wget
			clear
			echo "Инструмент установлен и используется следующим образом:"
			wget --help
			send_stats "安装wget"
			;;
		3)
			clear
			install sudo
			clear
			echo "Инструмент установлен и используется следующим образом:"
			sudo --help
			send_stats "安装sudo"
			;;
		4)
			clear
			install socat
			clear
			echo "Инструмент установлен и используется следующим образом:"
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
			echo "Инструмент установлен и используется следующим образом:"
			unzip
			send_stats "安装unzip"
			;;
		8)
			clear
			install tar
			clear
			echo "Инструмент установлен и используется следующим образом:"
			tar --help
			send_stats "安装tar"
			;;
		9)
			clear
			install tmux
			clear
			echo "Инструмент установлен и используется следующим образом:"
			tmux --help
			send_stats "安装tmux"
			;;
		10)
			clear
			install ffmpeg
			clear
			echo "Инструмент установлен и используется следующим образом:"
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
			read -e -p "Введите имя установленного инструмента (wget curl sudo htop):" installname
			install $installname
			send_stats "安装指定软件"
			;;
		42)
			clear
			read -e -p "Введите имя удаленного инструмента (htop ufw tmux cmatrix):" removename
			remove $removename
			send_stats "卸载指定软件"
			;;

		0)
			kejilion
			;;

		*)
			echo "Неверный ввод!"
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
			echo "Текущий алгоритм блокировки TCP: $congestion_algorithm $queue_algorithm"

			echo ""
			echo "Управление ББР"
			echo "------------------------"
			echo "1. Включите BBRv3 2. Выключите BBRv3 (он перезагрузится)"
			echo "------------------------"
			echo "0. Вернуться в предыдущее меню"
			echo "------------------------"
			read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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
		echo -e "${BLUE}Текущий резервный список:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "Нет резервной копии"
	}

	# ----------------------------
	# 备份
	# ----------------------------
	backup_docker() {
		send_stats "Docker备份"

		echo -e "${YELLOW} Резервное копирование контейнера Docker...${NC}"
		docker ps --format '{{.Names}}'
		read -e -p "Введите имя контейнера, для которого требуется создать резервную копию (разделите несколько пробелов и нажмите Enter, чтобы создать резервную копию всех работающих контейнеров):" containers

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
			echo -e "${RED} Контейнер ${NC} не найден"
			return
		}

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" >"$RESTORE_SCRIPT"
		echo "set -e" >>"$RESTORE_SCRIPT"
		echo "# Автоматически созданный сценарий восстановления" >>"$RESTORE_SCRIPT"

		# 记录已打包过的 Compose 项目路径，避免重复打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN} Резервный контейнер: $c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" >"$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE} обнаружил, что $c является контейнером для создания Docker ${NC}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p "Каталог создания не обнаружен, введите путь вручную:" project_dir
				fi

				# 如果该 Compose 项目已经打包过，跳过
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}Резервная копия проекта Compose [$project_name], пропустите повторную упаковку...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" >"${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" >"${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# восстановление docker-compose: $project_name" >>"$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >>"$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}Составьте проект [$project_name], упакованный: ${project_dir}${NC}"
				else
					echo -e "${RED} docker-compose.yml не найден, этот контейнер пропускается... ${NC}"
				fi
			else
				# 普通容器备份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "Упакованный объем: $path"
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

				echo -e "\n# Восстановить контейнер: $c" >>"$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >>"$RESTORE_SCRIPT"
			fi
		done

		# 备份 /home/docker 下的所有文件（不含子目录）
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE} Резервное копирование файлов в /home/docker...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "Файлы в папке ${GREEN}/home/docker были упакованы в папку ${BACKUP_DIR}/home_docker_files.tar.gz${NC}."
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN} Резервное копирование завершено: ${BACKUP_DIR}${NC}"
		echo -e "${GREEN}Доступные сценарии восстановления: ${RESTORE_SCRIPT}${NC}"

	}

	# ----------------------------
	# 还原
	# ----------------------------
	restore_docker() {

		send_stats "Docker还原"
		read -e -p "Пожалуйста, введите каталог резервной копии для восстановления:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}Каталог резервного копирования не существует${NC}"
			return
		}

		echo -e "${BLUE} Начинает операцию восстановления...${NC}"

		install tar jq gzip
		install_docker

		# --------- 优先还原 Compose 项目 ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p "Исходный путь не найден, введите путь к каталогу восстановления:" original_path

				# 检查该 compose 项目的容器是否已经在运行
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${YELLOW}В проекте Compose [$project_name] уже запущен контейнер, восстановление отсутствует...${NC}"
					continue
				fi

				read -e -p "Подтвердите восстановление проекта Compose [$project_name] по пути [$original_path]? (да/нет):" confirm
				[[ "$confirm" != "y" ]] && read -e -p "Пожалуйста, введите новый путь восстановления:" original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN}Проект Compose [$project_name] был извлечен в: $original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN}Compose проект [$project_name] восстановление завершено! ${NC}"
			fi
		done

		# --------- 继续还原普通容器 ---------
		echo -e "${BLUE} Проверить и восстановить обычные контейнеры Docker... ${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${GREEN} контейнер обработки: $container${NC}"

			# 检查容器是否已经存在且正在运行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}Контейнер [$container] уже запущен, восстановление не выполняется...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && {
				echo -e "${RED} Зеркальная информация не найдена, пропускаем: $container${NC}"
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
					echo "Восстановить данные тома: $VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 删除已存在但未运行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}Контейнер [$container] существует, но не запущен, удалите старый контейнер...${NC}"
				docker rm -f "$container"
			fi

			# 启动容器
			echo "Выполните команду восстановления: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW} Не найдена резервная информация для общих контейнеров ${NC}"

		# 还原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE} восстанавливает файлы в /home/docker...${NC}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "Файлы в папке ${GREEN}/home/docker восстановлены ${NC}."
		else
			echo -e "${YELLOW} Резервная копия файлов в каталоге /home/docker не найдена, пропуск... ${NC}"
		fi

	}

	# ----------------------------
	# 迁移
	# ----------------------------
	migrate_docker() {
		send_stats "Docker迁移"
		install jq
		read -e -p "Пожалуйста, введите каталог резервной копии для переноса:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}Каталог резервного копирования не существует${NC}"
			return
		}

		read -e -p "IP целевого сервера:" TARGET_IP
		read -e -p "Имя пользователя SSH целевого сервера:" TARGET_USER
		read -e -p "SSH-порт целевого сервера [по умолчанию 22]:" TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW}Перенос резервной копии...${NC}"
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
		read -e -p "Пожалуйста, введите каталог резервной копии, который необходимо удалить:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && {
			echo -e "${RED}Каталог резервного копирования не существует${NC}"
			return
		}
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN} Удалена резервная копия: ${BACKUP_DIR}${NC}."
	}

	# ----------------------------
	# 主菜单
	# ----------------------------
	main_menu() {
		send_stats "Docker备份迁移还原"
		while true; do
			clear
			echo "------------------------"
			echo -e "Инструмент резервного копирования, миграции и восстановления Docker"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. Резервное копирование проекта Docker."
			echo -e "2. Перенос проекта докера"
			echo -e "3. Восстановить проект докера"
			echo -e "4. Удалите файл резервной копии проекта докеров."
			echo "------------------------"
			echo -e "0. Вернуться в предыдущее меню"
			echo "------------------------"
			read -e -p "Пожалуйста, выберите:" choice
			case $choice in
			1) backup_docker ;;
			2) migrate_docker ;;
			3) restore_docker ;;
			4) delete_backup ;;
			0) return ;;
			*) echo -e "${RED}Неверный параметр ${NC}" ;;
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
		echo -e "Управление докером"
		docker_tato
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai}Установите и обновите среду Docker ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}2. ${gl_bai} Просмотр глобального статуса Docker ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3. ${gl_bai}Управление Docker-контейнером ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}4. ${gl_bai}Управление образами Docker"
		echo -e "${gl_kjlan}5. ${gl_bai}Управление сетью Docker"
		echo -e "${gl_kjlan}6. ${gl_bai}Управление томами Docker"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}7. ${gl_bai} Очистите ненужные Docker-контейнеры и создайте зеркальное отображение томов сетевых данных."
		echo -e "${gl_kjlan}------------------------"
		echo -e "__ЗАЩИТА_0__8. ${gl_bai}Заменить исходный код Docker"
		echo -e "__ЗАЩИТА_0__9. ${gl_bai}Изменить файл daemon.json"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11. ${gl_bai} Включить доступ Docker-ipv6"
		echo -e "${gl_kjlan}12. ${gl_bai}Закрыть доступ к Docker-ipv6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}19. ${gl_bai} Резервное копирование, перенос и восстановление среды Docker"
		echo -e "${gl_kjlan}20. ${gl_bai}Удалите среду Docker."
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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
			echo "Докер-версия"
			docker -v
			docker compose version

			echo ""
			echo -e "Образ Docker: ${gl_lv}$image_count${gl_bai}"
			docker image ls
			echo ""
			echo -e "Docker-контейнер: ${gl_lv}$container_count${gl_bai}"
			docker ps -a
			echo ""
			echo -e "Том Docker: ${gl_lv}$volume_count${gl_bai}"
			docker volume ls
			echo ""
			echo -e "Сеть Docker: ${gl_lv}$network_count${gl_bai}"
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
				echo "Список сетей Docker"
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
				echo "сетевые операции"
				echo "------------------------"
				echo "1. Создайте сеть"
				echo "2. Присоединяйтесь к сети"
				echo "3. Выйти из сети"
				echo "4. Удалить сеть"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

				case $sub_choice in
				1)
					send_stats "创建网络"
					read -e -p "Установите новое имя сети:" dockernetwork
					docker network create $dockernetwork
					;;
				2)
					send_stats "加入网络"
					read -e -p "Добавьте имя сети:" dockernetwork
					read -e -p "Какие контейнеры присоединяются к сети (пожалуйста, разделяйте несколько имен контейнеров пробелами):" dockernames

					for dockername in $dockernames; do
						docker network connect $dockernetwork $dockername
					done
					;;
				3)
					send_stats "加入网络"
					read -e -p "Выходное имя сети:" dockernetwork
					read -e -p "Эти контейнеры выходят из сети (пожалуйста, разделяйте несколько имен контейнеров пробелами):" dockernames

					for dockername in $dockernames; do
						docker network disconnect $dockernetwork $dockername
					done

					;;

				4)
					send_stats "删除网络"
					read -e -p "Пожалуйста, введите имя сети, которую необходимо удалить:" dockernetwork
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
				echo "Список томов Docker"
				docker volume ls
				echo ""
				echo "Операции с объемами"
				echo "------------------------"
				echo "1. Создайте новый том."
				echo "2. Удалить указанный том"
				echo "3. Удалить все тома"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

				case $sub_choice in
				1)
					send_stats "新建卷"
					read -e -p "Установите новое имя тома:" dockerjuan
					docker volume create $dockerjuan

					;;
				2)
					read -e -p "Введите имя удаляемого тома (разделяйте несколько имен томов пробелами):" dockerjuans

					for dockerjuan in $dockerjuans; do
						docker volume rm $dockerjuan
					done

					;;

				3)
					send_stats "删除所有卷"
					read -e -p "$(echo -e "${gl_hong}Примечание: ${gl_bai}Вы уверены, что хотите удалить все неиспользуемые тома? (да/нет):")" choice
					case "$choice" in
					[Yy])
						docker volume prune -f
						;;
					[Nn]) ;;
					*)
						echo "Неверный выбор, введите Y или N."
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
			read -e -p "$(echo -e "${gl_huang} Совет: ${gl_bai} очистит ненужную сеть контейнеров образов, включая остановленные контейнеры. Вы уверены, что очистите его? (да/нет):")" choice
			case "$choice" in
			[Yy])
				docker system prune -af --volumes
				;;
			[Nn]) ;;
			*)
				echo "Неверный выбор, введите Y или N."
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
			read -e -p "$(echo -e "${gl_hong}Примечание. ${gl_bai}Вы уверены, что хотите удалить среду Docker? (да/нет):")" choice
			case "$choice" in
			[Yy])
				docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				remove docker docker-compose docker-ce docker-ce-cli containerd.io
				rm -f /etc/docker/daemon.json
				hash -r
				;;
			[Nn]) ;;
			*)
				echo "Неверный выбор, введите Y или N."
				;;
			esac
			;;

		0)
			kejilion
			;;
		*)
			echo "Неверный ввод!"
			;;
		esac
		break_end

	done

}

linux_test() {

	while true; do
		clear
		# send_stats "测试脚本合集"
		echo -e "Коллекция тестовых сценариев"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}IP и определение статуса разблокировки"
		echo -e "${gl_kjlan}1. ${gl_bai}Определение статуса разблокировки ChatGPT"
		echo -e "${gl_kjlan}2. ${gl_bai}Тест разблокировки потокового мультимедиа в регионе"
		echo -e "${gl_kjlan}3. ${gl_bai}yeahwu Обнаружение разблокировки потокового мультимедиа"
		echo -e "${gl_kjlan}4. ${gl_bai}xykt сценарий проверки качества IP ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}Тест скорости сетевой линии"
		echo -e "${gl_kjlan}11. ${gl_bai}besttrace Тест маршрутизации с задержкой транзитного соединения для трех сетей"
		echo -e "${gl_kjlan}12. ${gl_bai}mtr_trace Тест трех транспортных линий сети"
		echo -e "${gl_kjlan}13. ${gl_bai}Сверхскоростной тест скорости трех сетей"
		echo -e "${gl_kjlan}14. ${gl_bai}nxtrace тестовый скрипт быстрого возврата"
		echo -e "${gl_kjlan}15. ${gl_bai}nxtrace указывает сценарий тестирования обратного соединения IP."
		echo -e "${gl_kjlan}16. ${gl_bai}ludashi2020 Тест трех сетевых линий"
		echo -e "${gl_kjlan}17. ${gl_bai}i-abc многофункциональный сценарий проверки скорости"
		echo -e "${gl_kjlan}18. ${gl_bai}Скрипт проверки качества сети NetQuality ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}Тест производительности оборудования"
		echo -e "${gl_kjlan}21. ${gl_bai}yabs тест производительности"
		echo -e "${gl_kjlan}22. ${gl_bai}icu/gb5 Сценарий проверки производительности процессора"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan} Комплексный тест"
		echo -e "${gl_kjlan}31. ${gl_bai}стендовый тест производительности"
		echo -e "${gl_kjlan}32. ${gl_bai}spiritysdx Fusion Monster Оценка ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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
			echo "Список эталонных IP-адресов"
			echo "------------------------"
			echo "Пекин Телеком: 219.141.136.12"
			echo "Пекин Юником: 202.106.50.1"
			echo "Пекин Мобильный: 221.179.155.161"
			echo "Шанхай Телеком: 202.96.209.133"
			echo "Шанхай Юником: 210.22.97.1"
			echo "Шанхай мобильный: 211.136.112.200"
			echo "Гуанчжоу Телеком: 58.60.188.222"
			echo "Гуанчжоу China Unicom: 210.21.196.6"
			echo "Гуанчжоу Мобильный: 120.196.165.24"
			echo "Чэнду Телеком: 61.139.2.69"
			echo "Чэнду Чайна Юником: 119.6.6.6"
			echo "Чэнду мобильный: 211.137.96.205"
			echo "Хунань Телеком: 36.111.200.100"
			echo "Хунань Юником: 42.48.16.100"
			echo "Хунань мобильный: 39.134.254.6"
			echo "------------------------"

			read -e -p "Введите конкретный IP:" testip
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
			echo "Неверный ввод!"
			;;
		esac
		break_end

	done

}

linux_Oracle() {

	while true; do
		clear
		send_stats "甲骨文云脚本合集"
		echo -e "Коллекция сценариев Oracle Cloud"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai} Установить активный сценарий неработающей машины"
		echo -e "${gl_kjlan}2. ${gl_bai} Удалить активный сценарий с простаивающего компьютера."
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3. ${gl_bai}DD скрипт переустановки системы"
		echo -e "${gl_kjlan}4. ${gl_bai}R Сценарий запуска детектива"
		echo -e "${gl_kjlan}5. ${gl_bai} Включите режим входа в систему с паролем ROOT."
		echo -e "__ЗАЩИТА_0__6. ${gl_bai}Инструмент восстановления IPV6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

		case $sub_choice in
		1)
			clear
			echo "Активный сценарий: загрузка процессора 10–20 %, загрузка памяти 20 %."
			read -e -p "Вы уверены, что хотите установить его? (да/нет):" choice
			case "$choice" in
			[Yy])

				install_docker

				# 设置默认值
				local DEFAULT_CPU_CORE=1
				local DEFAULT_CPU_UTIL="10-20"
				local DEFAULT_MEM_UTIL=20
				local DEFAULT_SPEEDTEST_INTERVAL=120

				# 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				read -e -p "Пожалуйста, введите количество ядер ЦП [по умолчанию: $DEFAULT_CPU_CORE]:" cpu_core
				local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				read -e -p "Введите процент использования ЦП (например, 10–20) [по умолчанию: $DEFAULT_CPU_UTIL]:" cpu_util
				local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				read -e -p "Введите процент использования памяти [по умолчанию: $DEFAULT_MEM_UTIL]:" mem_util
				local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				read -e -p "Введите время интервала теста скорости (в секундах) [по умолчанию: $DEFAULT_SPEEDTEST_INTERVAL]:" speedtest_interval
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
				echo "Неверный выбор, введите Y или N."
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
			echo "Переустановите систему"
			echo "--------------------------------"
			echo -e "${gl_hong} Примечание. ${gl_bai} Переустановка может привести к потере соединения. Если вы беспокоитесь, используйте его с осторожностью. Ожидается, что переустановка займет 15 минут. Пожалуйста, заранее сделайте резервную копию данных."
			read -e -p "Вы уверены, что хотите продолжить? (да/нет):" choice

			case "$choice" in
			[Yy])
				while true; do
					read -e -p "Пожалуйста, выберите систему, которую вы хотите переустановить: 1. Debian12 | 2. Ubuntu20.04:" sys_choice

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
						echo "Неверный выбор, пожалуйста, введите еще раз."
						;;
					esac
				done

				read -e -p "Пожалуйста, введите свой пароль после переустановки:" vpspasswd
				install wget
				bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
				send_stats "甲骨文云重装系统脚本"
				;;
			[Nn])
				echo "Отменено"
				;;
			*)
				echo "Неверный выбор, введите Y или N."
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
			echo "Эту функцию предоставил jhb, спасибо ему!"
			send_stats "ipv6修复"
			;;
		0)
			kejilion

			;;
		*)
			echo "Неверный ввод!"
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
		echo -e "В среде ${gl_lv} установлен ${gl_bai} Контейнер: ${gl_lv}$container_count${gl_bai} Образ: ${gl_lv}$image_count${gl_bai} Сеть: ${gl_lv}$network_count${gl_bai} Том: ${gl_lv}$volume_count${gl_bai}"
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
			echo -e "Среда ${gl_lv} установлена ​​${gl_bai} Сайт: $output База данных: $db_output"
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
		echo -e "${gl_huang}Создание сайта LDNMP"
		ldnmp_tato
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}1. ${gl_bai}Установите среду LDNMP ${gl_huang}★${gl_bai} ${gl_huang}2. ${gl_bai}Установить WordPress ${gl_huang}★${gl_bai}"
		echo -e "${gl_huang}3. ${gl_bai}Установите Discuz Forum ${gl_huang}4. ${gl_bai}Установите Kedao Cloud Desktop"
		echo -e "${gl_huang}5. ${gl_bai}Установите Apple CMS Movie and TV Station ${gl_huang}6. ${gl_bai}Установите сеть Unicorn Digital Card Network"
		echo -e "${gl_huang}7. ${gl_bai}Установите сайт форума Flarum ${gl_huang}8. ${gl_bai}Установите облегченный блог-сайт typecho"
		echo -e "__ЗАЩИТА_0__9. ${gl_bai}Установите платформу ссылок общего доступа LinkStack ${gl_huang}20. ${gl_bai}Настройка динамического сайта"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}21. ${gl_bai} Устанавливайте только nginx ${gl_huang}★${gl_bai} ${gl_huang}22. ${gl_bai}Перенаправление сайта"
		echo -e "${gl_huang}23. ${gl_bai}Обратный прокси-сервер-IP+порт сайта ${gl_huang}★${gl_bai} ${gl_huang}24. ${gl_bai}Доменное имя обратного прокси-сервера сайта"
		echo -e "${gl_huang}25. ${gl_bai}Установите платформу управления паролями Bitwarden ${gl_huang}26. ${gl_bai}Установите веб-сайт блога Halo"
		echo -e "${gl_huang}27. ${gl_bai}Установите генератор слов с подсказками для рисования AI ${gl_huang}28. ${gl_bai}Балансировка нагрузки обратного прокси-сервера на сайте"
		echo -e "${gl_huang}29. ${gl_bai}Потоковая четырехуровневая переадресация прокси ${gl_huang}30. ${gl_bai}Индивидуальный статический сайт"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}31. ${gl_bai}Управление данными объекта ${gl_huang}★${gl_bai} ${gl_huang}32. ${gl_bai} Резервное копирование всех данных сайта"
		echo -e "${gl_huang}33. ${gl_bai} Запланированное удаленное резервное копирование ${gl_huang}34. ${gl_bai} Восстановить все данные сайта."
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}35. ${gl_bai} Защита среды LDNMP ${gl_huang}36. ${gl_bai} Оптимизация среды LDNMP"
		echo -e "${gl_huang}37. ${gl_bai}Обновите среду LDNMP ${gl_huang}38. ${gl_bai}Удалить среду LDNMP"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_huang}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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
			webname="Дискуз Форум"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo "Адрес базы данных: mysql"
			echo "Имя базы данных: $dbname"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			echo "Префикс таблицы: Discuz_"

			;;

		4)
			clear
			# 可道云桌面
			webname="Облачный рабочий стол Kedao"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo "Адрес базы данных: mysql"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			echo "Имя базы данных: $dbname"
			echo "Хост Redis: Redis"

			;;

		5)
			clear
			# 苹果CMS
			webname="AppleCMS"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo "Адрес базы данных: mysql"
			echo "Порт базы данных: 3306"
			echo "Имя базы данных: $dbname"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			echo "Префикс базы данных: mac_"
			echo "------------------------"
			echo "После успешной установки войдите на серверный адрес."
			echo "https://$yuming/vip.php"

			;;

		6)
			clear
			# 独脚数卡
			webname="Одноногая номерная карточка"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo "Адрес базы данных: mysql"
			echo "Порт базы данных: 3306"
			echo "Имя базы данных: $dbname"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			echo ""
			echo "адрес Redis: Redis"
			echo "пароль Redis: не заполнен по умолчанию"
			echo "порт Redis: 6379"
			echo ""
			echo "Адрес сайта: https://$yuming"
			echo "Путь входа в серверную часть: /admin"
			echo "------------------------"
			echo "Имя пользователя: admin"
			echo "Пароль: admin"
			echo "------------------------"
			echo "Если при входе в систему в правом верхнем углу появляется красная ошибка error0, используйте следующую команду:"
			echo "Я также очень зол на то, почему Номерная карта Единорога доставляет столько хлопот и вызывает такие проблемы!"
			echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

			;;

		7)
			clear
			# flarum论坛
			webname="фларум форум"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo "Адрес базы данных: mysql"
			echo "Имя базы данных: $dbname"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			echo "Префикс таблицы: flarum_"
			echo "Информация администратора может быть установлена ​​самостоятельно"

			;;

		8)
			clear
			# typecho
			webname="типчо"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo "Префикс базы данных: typecho_"
			echo "Адрес базы данных: mysql"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			echo "Имя базы данных: $dbname"

			;;

		9)
			clear
			# LinkStack
			webname="Стек ссылок"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo "Адрес базы данных: mysql"
			echo "Порт базы данных: 3306"
			echo "Имя базы данных: $dbname"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			;;

		20)
			clear
			webname="динамический сайт PHP"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo -e "[${gl_huang}1/6${gl_bai}] Загрузите исходный код PHP"
			echo "-------------"
			echo "В настоящее время разрешена загрузка только пакетов исходного кода в формате zip. Поместите пакеты исходного кода в каталог /home/web/html/${yuming}."
			read -e -p "Вы также можете ввести ссылку для скачивания, чтобы удаленно загрузить пакет исходного кода. Нажмите Enter напрямую, чтобы пропустить удаленную загрузку:" url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/6${gl_bai}] Путь, по которому находится index.php."
			echo "-------------"
			# find "$(realpath .)" -name "index.php" -print
			find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

			read -e -p "Введите путь к index.php, аналогичный (/home/web/html/$yuming/wordpress/):" index_lujing

			sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
			sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}3/6${gl_bai}] Пожалуйста, выберите версию PHP"
			echo "-------------"
			read -e -p "1. Последняя версия PHP | 2. php7.4:" pho_v
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
				echo "Неверный выбор, пожалуйста, введите еще раз."
				;;
			esac

			clear
			echo -e "[${gl_huang}4/6${gl_bai}] Установите указанное расширение."
			echo "-------------"
			echo "Установленные расширения"
			docker exec php php -m

			read -e -p "$(echo -e "Введите имя расширения, которое необходимо установить, например ${gl_huang}SourceGuardian imap ftp${gl_bai} и т. д. Нажмите Enter, чтобы пропустить установку:")" php_extensions
			if [ -n "$php_extensions" ]; then
				docker exec $PHP_Version install-php-extensions $php_extensions
			fi

			clear
			echo -e "[${gl_huang}5/6${gl_bai}] Изменение конфигурации сайта"
			echo "-------------"
			echo "Нажмите любую клавишу, чтобы продолжить. Вы можете подробно настроить конфигурацию сайта, например псевдостатический контент."
			read -n 1 -s -r -p ""
			install nano
			nano /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}6/6${gl_bai}] Управление базой данных"
			echo "-------------"
			read -e -p "1. Я создаю новый сайт. 2. Я создаю старый сайт и имею резервную копию базы данных:" use_db
			case $use_db in
			1)
				echo
				;;
			2)
				echo "Резервная копия базы данных должна представлять собой сжатый пакет с расширением .gz. Пожалуйста, поместите его в каталог /home/ для поддержки импорта данных резервной копии Pagoda/1panel."
				read -e -p "Вы также можете ввести ссылку для скачивания, чтобы удаленно загрузить данные резервной копии. Нажмите Enter напрямую, чтобы пропустить удаленную загрузку:" url_download_db

				cd /home/
				if [ -n "$url_download_db" ]; then
					wget "$url_download_db"
				fi
				gunzip $(ls -t *.gz | head -n 1)
				latest_sql=$(ls -t *.sql | head -n 1)
				dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname <"/home/$latest_sql"
				echo "Импортированные табличные данные базы данных"
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
				rm -f *.sql
				echo "Импорт базы данных завершен."
				;;
			*)
				echo
				;;
			esac

			docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

			restart_ldnmp
			ldnmp_web_on
			prefix="web$(shuf -i 10-99 -n 1)_"
			echo "Адрес базы данных: mysql"
			echo "Имя базы данных: $dbname"
			echo "Имя пользователя: $dbuse"
			echo "Пароль: $dbususepasswd"
			echo "Префикс таблицы: $prefix"
			echo "Данные для входа администратора задаются самостоятельно."

			;;

		21)
			ldnmp_install_status_one
			nginx_install_all
			;;

		22)
			clear
			webname="перенаправление сайта"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
			add_yuming
			read -e -p "Пожалуйста, введите имя домена для перенаправления:" reverseproxy
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
				echo "IP+порт заблокирован для доступа к сервису"
			else
				ip_address
				block_container_port "$docker_name" "$ipv4_address"
			fi

			;;

		24)
			clear
			webname="Обратное прокси-домен"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
			add_yuming
			echo -e "Формат доменного имени: ${gl_huang}google.com${gl_bai}."
			read -e -p "Пожалуйста, введите доменное имя обратного прокси-сервера:" fandai_yuming
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
			webname="Битварден"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			webname="гало"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			webname="Генератор слов для рисования AI"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			webname="статический сайт"
			send_stats "安装$webname"
			echo "Начните развертывание $webname"
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
			echo -e "[${gl_huang}1/2${gl_bai}] Загрузить статический исходный код"
			echo "-------------"
			echo "В настоящее время разрешена загрузка только пакетов исходного кода в формате zip. Поместите пакеты исходного кода в каталог /home/web/html/${yuming}."
			read -e -p "Вы также можете ввести ссылку для скачивания, чтобы удаленно загрузить пакет исходного кода. Нажмите Enter напрямую, чтобы пропустить удаленную загрузку:" url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/2${gl_bai}] Путь, по которому находится index.html."
			echo "-------------"
			# find "$(realpath .)" -name "index.html" -print
			find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

			read -e -p "Введите путь к index.html, аналогичный (/home/web/html/$yuming/index/):" index_lujing

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
			echo -e "${gl_huang} выполняет резервное копирование $backup_filename ...${gl_bai}"
			cd /home/ && tar czvf "$backup_filename" web

			while true; do
				clear
				echo "Создан файл резервной копии: /home/$backup_filename"
				read -e -p "Хотите перенести резервные данные на удаленный сервер? (да/нет):" choice
				case "$choice" in
				[Yy])
					read -e -p "Пожалуйста, введите IP-адрес удаленного сервера:" remote_ip
					read -e -p "SSH-порт целевого сервера [по умолчанию 22]:" TARGET_PORT
					local TARGET_PORT=${TARGET_PORT:-22}
					if [ -z "$remote_ip" ]; then
						echo "Ошибка: введите IP-адрес удаленного сервера."
						continue
					fi
					local latest_tar=$(ls -t /home/*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
						echo "Файл был перенесен в домашний каталог удаленного сервера."
					else
						echo "Файл для передачи не найден."
					fi
					break
					;;
				[Nn])
					break
					;;
				*)
					echo "Неверный выбор, введите Y или N."
					;;
				esac
			done
			;;

		33)
			clear
			send_stats "定时远程备份"
			read -e -p "Введите IP удаленного сервера:" useip
			read -e -p "Введите пароль удаленного сервера:" usepasswd

			cd ~
			wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh >/dev/null 2>&1
			chmod +x ${useip}_beifen.sh

			sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
			sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

			echo "------------------------"
			echo "1. Еженедельное резервное копирование 2. Ежедневное резервное копирование"
			read -e -p "Пожалуйста, введите ваш выбор:" dingshi

			case $dingshi in
			1)
				check_crontab_installed
				read -e -p "Выберите день недели для еженедельного резервного копирования (0–6, 0 соответствует воскресенью):" weekday
				(
					crontab -l
					echo "0 0 * * $weekday ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			2)
				check_crontab_installed
				read -e -p "Выберите ежедневное время резервного копирования (час, 0–23):" hour
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
			echo "Доступные резервные копии сайта"
			echo "-------------------------"
			ls -lt /home/*.gz | awk '{print $NF}'
			echo ""
			read -e -p "Нажмите клавишу Enter, чтобы восстановить последнюю резервную копию, введите имя файла резервной копии, чтобы восстановить указанную резервную копию, введите 0, чтобы выйти:" filename

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

				echo -e "${gl_huang} распаковывает $filename ...${gl_bai}"
				cd /home/ && tar -xzf "$filename"

				check_port
				install_dependency
				install_docker
				install_certbot
				install_ldnmp
			else
				echo "Сжатый пакет не найден."
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
				echo "Обновить среду LDNMP"
				echo "------------------------"
				ldnmp_v
				echo "Обнаружена новая версия компонента"
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
				echo "1. Обновить nginx 2. Обновить MySQL 3. Обновить php 4. Обновить Redis"
				echo "------------------------"
				echo "5. Обновите всю среду"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
				case $sub_choice in
				1)
					nginx_upgrade

					;;

				2)
					local ldnmp_pods="mysql"
					read -e -p "Введите номер версии ${ldnmp_pods} (например: 8.0 8.3 8.4 9.0) (нажмите Enter, чтобы получить последнюю версию):" version
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
					echo "Обновление ${ldnmp_pods} завершено"

					;;
				3)
					local ldnmp_pods="php"
					read -e -p "Введите номер версии ${ldnmp_pods} (например: 7.4 8.0 8.1 8.2 8.3) (нажмите Enter, чтобы получить последнюю версию):" version
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
					echo "Обновление ${ldnmp_pods} завершено"

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
					echo "Обновление ${ldnmp_pods} завершено"

					;;
				5)
					read -e -p "$(echo -e "${gl_huang} Совет: ${gl_bai} Пользователям, которые не обновляют среду в течение длительного времени, пожалуйста, обновляйте среду LDNMP осторожно, так как существует риск сбоя обновления базы данных. Вы уверены, что хотите обновить среду LDNMP? (да/нет):")" choice
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
			read -e -p "$(echo -e "${gl_hong} Настоятельно рекомендуется: ${gl_bai} Сначала создайте резервную копию всех данных веб-сайта, а затем удалите среду LDNMP. Вы уверены, что хотите удалить все данные сайта? (да/нет):")" choice
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
				echo "Неверный выбор, введите Y или N."
				;;
			esac
			;;

		0)
			kejilion
			;;

		*)
			echo "Неверный ввод!"
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
			echo -e "рынок приложений"
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

			echo -e "${gl_kjlan}1. ${color1} Официальная версия Pagoda Panel ${gl_kjlan}2. ${color2}aaPanel Пагода Международная версия"
			echo -e "${gl_kjlan}3. ${color3}1Панель Панель управления нового поколения ${gl_kjlan}4. ${color4}Визуальная панель NginxProxyManager"
			echo -e "${gl_kjlan}5. ${color5}OpenList программа создания списка файлов для нескольких хранилищ ${gl_kjlan}6. ${color6}Веб-версия удаленного рабочего стола Ubuntu"
			echo -e "${gl_kjlan}7. ${color7}Панель мониторинга Nezha Probe VPS ${gl_kjlan}8. ${color8}QB Автономная магнитная панель загрузки BT"
			echo -e "__ЗАЩИТА_0__9. ${color9}Программа почтового сервера Poste.io ${gl_kjlan}10. ${color10}Система онлайн-чата для нескольких человек RocketChat"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}11. ${color11} Программное обеспечение для управления проектами ZenTao ${gl_kjlan}12. ${color12} Платформа управления запланированными задачами панели Qinglong"
			echo -e "${gl_kjlan}13. ${color13}Сетевой диск Cloudreve ${gl_huang}★${gl_bai} ${gl_kjlan}14. ${color14}Простая программа для управления изображениями на кровати."
			echo -e "${gl_kjlan}15. ${color15}система управления мультимедиа ${gl_kjlan}16. ${color16}Панель измерения скорости Speedtest"
			echo -e "${gl_kjlan}17. ${color17}AdGuardHome удаляет рекламное ПО ${gl_kjlan}18. ${color18}onlyoffice онлайн-офис ОФИС"
			echo -e "${gl_kjlan}19. ${color19}Панель брандмауэра Leichi WAF ${gl_kjlan}20. ${color20}панель управления контейнером porttainer"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}21. ${color21}VScode веб-версия ${gl_kjlan}22. ${color22}Инструмент мониторинга UptimeKuma"
			echo -e "${gl_kjlan}23. ${color23}Веб-заметка «Заметки» ${gl_kjlan}24. ${color24}Веб-версия удаленного рабочего стола Webtop ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}25. ${color25}Сетевой диск Nextcloud ${gl_kjlan}26. ${color26}QD-Сегодняшняя структура управления запланированными задачами"
			echo -e "${gl_kjlan}27. ${color27}Панель управления стеком контейнеров Dockge ${gl_kjlan}28. ${color28}Инструмент проверки скорости LibreSpeed"
			echo -e "${gl_kjlan}29. ${color29}searxng станция поиска агрегации ${gl_huang}★${gl_bai} ${gl_kjlan}30. ${color30}Система личных фотоальбомов PhotoPrism"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}31. ${color31}Коллекция инструментов StirlingPDF ${gl_kjlan}32. ${color32}drawio бесплатное онлайн-программное обеспечение для построения графиков ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}33. ${color33}Навигационная панель Sun-Panel ${gl_kjlan}34. ${color34}Платформа обмена файлами Pingvin-Share"
			echo -e "${gl_kjlan}35. ${color35} Минималистский круг друзей ${gl_kjlan}36. ${color36}Сайт-агрегатор чатов LobeChatAI"
			echo -e "${gl_kjlan}37. ${color37}Панель инструментов MyIP ${gl_huang}★${gl_bai} ${gl_kjlan}38. ${color38}Семейное ведро Xiaoya alist"
			echo -e "${gl_kjlan}39. ${color39}Bililive инструмент для записи прямых трансляций ${gl_kjlan}40. ${color40}webssh веб-версия, инструмент SSH-подключения"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}41. ${color41}Панель управления мышью ${gl_kjlan}42. ${color42}Инструмент удаленного подключения Nextterm"
			echo -e "${gl_kjlan}43. ${color43}RustDesk Удаленный рабочий стол (сервер) ${gl_huang}★${gl_bai} ${gl_kjlan}44. ${color44}Удаленный рабочий стол RustDesk (реле) ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}45. ${color45}Докер-станция ускорения ${gl_kjlan}46. ${color46}Станция ускорения GitHub ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}47. ${color47} Мониторинг Prometheus ${gl_kjlan}48. ${color48} Prometheus (мониторинг хоста)"
			echo -e "${gl_kjlan}49. ${color49} Прометей (мониторинг контейнера) ${gl_kjlan}50. ${color50} Инструмент мониторинга пополнения запасов"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}51. ${color51}PVE открытая куриная панель ${gl_kjlan}52. ${color52}DPanel Панель управления контейнером"
			echo -e "${gl_kjlan}53. ${color53}llama3 чат AI большая модель ${gl_kjlan}54. ${color54}AMH панель управления созданием хост-сайта"
			echo -e "${gl_kjlan}55. ${color55}Проникновение FRP во внутреннюю сеть (сервер) ${gl_huang}★${gl_bai} ${gl_kjlan}56. ${color56}Проникновение FRP во внутреннюю сеть (клиент) ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}57. ${color57}Большая модель чата Deepseek AI ${gl_kjlan}58. ${color58}Dify база знаний большой модели ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}59. ${color59}Новый API управления активами большой модели ${gl_kjlan}60. ${color60}JumpServer машина-бастион с открытым исходным кодом"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}61. ${color61} Сервер онлайн-перевода ${gl_kjlan}62. ${color62}RAGFlow база знаний по большим моделям"
			echo -e "${gl_kjlan}63. ${color63}Автономная платформа искусственного интеллекта OpenWebUI ${gl_huang}★${gl_bai} ${gl_kjlan}64. ${color64}набор инструментов it-tools"
			echo -e "${gl_kjlan}65. ${color65}n8n Платформа автоматизированного рабочего процесса ${gl_huang}★${gl_bai} ${gl_kjlan}66. ${color66}yt-dlp инструмент для загрузки видео"
			echo -e "${gl_kjlan}67. ${color67}ddns-go инструмент управления динамическим DNS ${gl_huang}★${gl_bai} ${gl_kjlan}68. ${color68}Платформа управления сертификатами AllinSSL"
			echo -e "${gl_kjlan}69. ${color69}SFTPGo инструмент передачи файлов ${gl_kjlan}70. ${color70}Среда чат-бота AstrBot"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}71. ${color71}Частный музыкальный сервер Navidrome ${gl_kjlan}72. ${color72}bitwarden менеджер паролей ${gl_huang}★${gl_bai}"
			echo -e "${gl_kjlan}73. ${color73}LibreTV Частное кино и телевидение ${gl_kjlan}74. ${color74}MoonTV Частное кино и телевидение"
			echo -e "${gl_kjlan}75. ${color75}Мастер мелодий ${gl_kjlan}76. ${color76} Старые онлайн-игры для DOS"
			echo -e "${gl_kjlan}77. ${color77}Инструмент автономной загрузки Thunder ${gl_kjlan}78. ${color78}Интеллектуальная система управления документами PandaWiki"
			echo -e "${gl_kjlan}79. ${color79}Мониторинг сервера Beszel ${gl_kjlan}80. ${color80}управление закладками linkwarden"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}81. ${color81}Видеоконференция JitsiMeet ${gl_kjlan}82. ${color82}gpt-load высокопроизводительный прозрачный прокси-сервер AI"
			echo -e "${gl_kjlan}83. ${color83}комари инструмент мониторинга сервера ${gl_kjlan}84. ${color84}Инструмент управления личными финансами Wallos"
			echo -e "${gl_kjlan}85. ${color85}immich менеджер изображений и видео ${gl_kjlan}86. ${color86}jellyfin система управления медиафайлами"
			echo -e "${gl_kjlan}87. ${color87}SyncTV, инструмент для совместного просмотра фильмов ${gl_kjlan}88. ${color88}Собственная платформа прямых трансляций на собственном хостинге"
			echo -e "${gl_kjlan}89. ${color89}FileCodeBox файл выражения ${gl_kjlan}90. ${color90}матричный протокол децентрализованного чата"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}91. ${color91}хранилище частного кода gitea ${gl_kjlan}92. ${color92}Файловый менеджер FileBrowser"
			echo -e "${gl_kjlan}93. ${color93}Минималистический статический файловый сервер Dufs ${gl_kjlan}94. ${color94}Инструмент высокоскоростной загрузки Gopeed"
			echo -e "${gl_kjlan}95. ${color95}платформа безбумажного документооборота ${gl_kjlan}96. ${color96}2FAuth Самостоятельный двухэтапный аутентификатор"
			echo -e "${gl_kjlan}97. ${color97}Сеть WireGuard (сервер) ${gl_kjlan}98. ${color98}Сеть WireGuard (клиент)"
			echo -e "${gl_kjlan}99. ${color99}DSM Виртуальная машина Synology ${gl_kjlan}100. ${color100}Syncthing инструмент одноранговой синхронизации файлов"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}101. ${color101}Инструмент создания видео AI ${gl_kjlan}102. ${color102}VoceChat система онлайн-чата для нескольких человек"
			echo -e "${gl_kjlan}103. ${color103}Инструмент статистики веб-сайта Umami ${gl_kjlan}104. ${color104}Инструмент четырехуровневой переадресации прокси-сервера Stream"
			echo -e "${gl_kjlan}105. ${color105} Заметки Сиюаня ${gl_kjlan}106. ${color106}Drawnix инструмент для доски с открытым исходным кодом"
			echo -e "${gl_kjlan}107. ${color107}Поиск сетевого диска PanSou"
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_kjlan}б. ${gl_bai} Создайте резервную копию всех данных приложения ${gl_kjlan}r. ${gl_bai} Восстановить все данные приложения."
			echo -e "${gl_kjlan}------------------------"
			echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
			echo -e "${gl_kjlan}------------------------${gl_bai}"
			read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
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

				read -e -p "Установите имя пользователя для входа:" admin
				read -e -p "Установите пароль пользователя для входа:" admin_password
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
				echo -e "Нежа мониторинг $check_docker $update_status"
				echo "Легкий и простой в использовании инструмент с открытым исходным кодом для мониторинга, эксплуатации и обслуживания серверов."
				echo "Официальная документация по созданию сайта: https://nezha.wiki/guide/dashboard.html."
				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1. Используйте"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Введите свой выбор:" choice

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
				echo -e "Почтовая служба $check_docker $update_status"
				echo "poste.io — это почтовый сервер с открытым исходным кодом,"
				echo "Видео-знакомство: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo ""
				echo "Обнаружение порта"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
					echo -e "${gl_lv} порт $порт доступен в данный момент ${gl_bai}"
				else
					echo -e "${gl_hong} порт $port в настоящее время недоступен ${gl_bai}"
				fi
				echo ""

				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					yuming=$(cat /home/docker/mail.txt)
					echo "Адрес посещения:"
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. Установить 2. Обновить 3. Удалить"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Введите свой выбор:" choice

				case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "Пожалуйста, укажите доменное имя электронной почты, например mail.yuming.com:" yuming
					mkdir -p /home/docker
					echo "$yuming" >/home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "Сначала проанализируйте эти записи DNS"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo ""
					echo "------------------------"
					echo "Нажмите любую клавишу, чтобы продолжить..."
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
					echo "poste.io установлен."
					echo "------------------------"
					echo "Вы можете получить доступ к poste.io, используя следующий адрес:"
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
					echo "poste.io установлен."
					echo "------------------------"
					echo "Вы можете получить доступ к poste.io, используя следующий адрес:"
					echo "https://$yuming"
					echo ""
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "Приложение удалено"
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
				echo "Установка завершена"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "rocket.chat установлен"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "Приложение удалено"
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
				echo "Установка завершена"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "Приложение удалено"
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
				echo -e "Служба Thunderpool $check_docker"
				echo "Leichi — это программная панель брандмауэра сайта WAF, разработанная Changting Technology, которая может перевернуть сайт для автоматической защиты."
				echo "Видео-знакомство: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. Установить 2. Обновить 3. Сбросить пароль 4. Удалить"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Введите свой выбор:" choice

				case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "Панель Leichi WAF установлена."
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "Панель Leichi WAF обновлена."
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "Если вы находитесь в каталоге установки по умолчанию, проект уже удален. Если вы настраиваете каталог установки, вам нужно перейти в каталог установки и выполнить его самостоятельно:"
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

				read -e -p "Установите имя пользователя для входа:" admin
				read -e -p "Установите пароль пользователя для входа:" admin_password
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
				echo "Установка завершена"
				check_docker_app_ip
				echo "Исходное имя пользователя и пароль: admin."
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
				echo "Приложение удалено"
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
				echo "Установка завершена"
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
				echo "Приложение удалено"
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
				echo "Установка завершена"
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
				echo "Установка завершена"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "Приложение удалено"
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
				echo "Установка завершена"
				check_docker_app_ip
				echo "Первоначальное имя пользователя: admin"
				echo "Начальный пароль: ChangeMe"
			}

			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "Приложение обновлено"
			}

			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "Приложение удалено"
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
				echo "Установка завершена"
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
				echo "Приложение удалено"
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

				read -e -p "Установите пароль для входа в LibreTV:" app_passwd

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
				read -e -p "Установите имя пользователя для входа:" admin
				read -e -p "Установите пароль пользователя для входа:" admin_password
				read -e -p "Введите код авторизации:" shouquanma

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
				echo "Установка завершена"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/moontv/ && docker compose down --rmi all
				cd /home/docker/moontv/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/moontv/ && docker compose down --rmi all
				rm -rf /home/docker/moontv
				echo "Приложение удалено"
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

				read -e -p "Установите имя пользователя для входа:" app_use
				read -e -p "Установить пароль для входа:" app_passwd

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
				echo "Установка завершена"
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
				echo "Приложение удалено"
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
				echo "Приложение удалено"
			}

			docker_app_plus

			;;

		82 | gpt-load)

			local app_id="82"
			local docker_name="gpt-load"
			local docker_img="tbphp/gpt-load:latest"
			local docker_port=8082

			docker_rum() {

				read -e -p "Установите ключ входа ${docker_name} (комбинация букв и цифр, начинающихся с sk-), например: sk-159kejilionyyds163:" app_passwd

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
				echo "Установка завершена"
				check_docker_app_ip

			}

			docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				rm -rf /home/docker/${docker_name}
				echo "Приложение удалено"
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

				echo "Создайте первоначального пользователя или администратора. Пожалуйста, установите следующие имя пользователя и пароль и укажите, являетесь ли вы администратором."
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
				echo "Установка завершена"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/gitea/ && docker compose down --rmi all
				cd /home/docker/gitea/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/gitea/ && docker compose down --rmi all
				rm -rf /home/docker/gitea
				echo "Приложение удалено"
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

				read -e -p "Установите имя пользователя для входа:" app_use
				read -e -p "Установить пароль для входа:" app_passwd

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
				echo "Установка завершена"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/paperless/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/paperless/ && docker compose down --rmi all
				rm -rf /home/docker/paperless
				echo "Приложение удалено"
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
				echo "Установка завершена"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/2fauth/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/2fauth/ && docker compose down --rmi all
				rm -rf /home/docker/2fauth
				echo "Приложение удалено"
			}

			docker_app_plus

			;;

		97 | wgs)

			local app_id="97"
			local docker_name="wireguard"
			local docker_img="lscr.io/linuxserver/wireguard:latest"
			local docker_port=8097

			docker_rum() {

				read -e -p "Введите количество клиентов в сети (по умолчанию 5):" COUNT
				COUNT=${COUNT:-5}
				read -e -p "Пожалуйста, введите сегмент сети WireGuard (по умолчанию 10.13.13.0):" NETWORK
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
				echo -e "${gl_huang}Все конфигурации QR-кода клиента: ${gl_bai}"
				docker exec -it wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
				sleep 2
				echo
				echo -e "${gl_huang} Все коды конфигурации клиента: ${gl_bai}"
				docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
				sleep 2
				echo -e "${gl_lv}${COUNT} клиенты настраивают все выходы. Способ использования следующий: ${gl_bai}"
				echo -e "${gl_lv}1. Загрузите приложение wg на свой мобильный телефон и отсканируйте приведенный выше QR-код, чтобы быстро подключиться к Интернету ${gl_bai}"
				echo -e "${gl_lv}2. Загрузите клиент для Windows и скопируйте код конфигурации для подключения к сети. ${gl_bai}"
				echo -e "${gl_lv}3. Linux использует сценарий для развертывания клиента WG и копирования кода конфигурации для подключения к сети. ${gl_bai}"
				echo -e "${gl_lv}Официальный метод загрузки клиента: https://www.wireguard.com/install/${gl_bai}"
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

				echo "Вставьте конфигурацию клиента и дважды нажмите Enter, чтобы сохранить:"

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

				echo "Конфигурация клиента сохранена в $CONFIG_FILE."

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

				read -e -p "Установите количество ядер процессора (по умолчанию 2):" CPU_CORES
				local CPU_CORES=${CPU_CORES:-2}

				read -e -p "Установить размер памяти (по умолчанию 4G):" RAM_SIZE
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
				echo "Установка завершена"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/dsm/ && docker compose down --rmi all
				docker_app_install
			}

			docker_app_uninstall() {
				cd /home/docker/dsm/ && docker compose down --rmi all
				rm -rf /home/docker/dsm
				echo "Приложение удалено"
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
				echo "Установка завершена"
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
				echo "Приложение удалено"
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
				echo "Установка завершена"
				check_docker_app_ip
				echo "Первоначальное имя пользователя: admin"
				echo "Начальный пароль: умами"
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
				echo "Приложение удалено"
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

				read -e -p "Установить пароль для входа:" app_passwd

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
			echo -e "${gl_huang} выполняет резервное копирование $backup_filename ...${gl_bai}"
			cd / && tar czvf "$backup_filename" home

			while true; do
				clear
				echo "Создан файл резервной копии: /$backup_filename"
				read -e -p "Хотите перенести резервные данные на удаленный сервер? (да/нет):" choice
				case "$choice" in
				[Yy])
					read -e -p "Пожалуйста, введите IP-адрес удаленного сервера:" remote_ip
					read -e -p "SSH-порт целевого сервера [по умолчанию 22]:" TARGET_PORT
					local TARGET_PORT=${TARGET_PORT:-22}

					if [ -z "$remote_ip" ]; then
						echo "Ошибка: введите IP-адрес удаленного сервера."
						continue
					fi
					local latest_tar=$(ls -t /app*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
						echo "Файл перенесен в удаленный сервер/корневой каталог."
					else
						echo "Файл для передачи не найден."
					fi
					break
					;;
				*)
					echo "Примечание. Текущая резервная копия включает только проекты Docker и не включает резервные копии данных панелей создания веб-сайтов, таких как Pagoda и 1panel."
					break
					;;
				esac
			done

			;;

		r)
			root_use
			send_stats "全部应用还原"
			echo "Доступные резервные копии приложений"
			echo "-------------------------"
			ls -lt /app*.gz | awk '{print $NF}'
			echo ""
			read -e -p "Нажмите клавишу Enter, чтобы восстановить последнюю резервную копию, введите имя файла резервной копии, чтобы восстановить указанную резервную копию, введите 0, чтобы выйти:" filename

			if [ "$filename" == "0" ]; then
				break_end
				linux_panel
			fi

			# 如果用户没有输入文件名，使用最新的压缩包
			if [ -z "$filename" ]; then
				local filename=$(ls -t /app*.tar.gz | head -1)
			fi

			if [ -n "$filename" ]; then
				echo -e "${gl_huang} распаковывает $filename ...${gl_bai}"
				cd / && tar -xzf "$filename"
				echo "Данные приложения восстановлены. В настоящее время вручную войдите в указанное меню приложения и обновите приложение, чтобы восстановить его."
			else
				echo "Сжатый пакет не найден."
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
		echo -e "Серверная рабочая область"
		echo -e "Система предоставит вам рабочее пространство, которое может постоянно работать в фоновом режиме и которое вы можете использовать для выполнения долгосрочных задач."
		echo -e "Даже если вы отключите SSH, выполнение задач в рабочей области не будет прерываться, а задачи останутся в фоновом режиме."
		echo -e "${gl_huang} Советы: ${gl_bai} После входа в рабочую область используйте Ctrl+b, а затем нажмите только d, чтобы выйти из рабочей области!"
		echo -e "${gl_kjlan}------------------------"
		echo "Список существующих на данный момент рабочих пространств"
		echo -e "${gl_kjlan}------------------------"
		tmux list-sessions
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai}Рабочее пространство №1"
		echo -e "${gl_kjlan}2. ${gl_bai}Рабочее пространство №2"
		echo -e "${gl_kjlan}3. ${gl_bai}Рабочее пространство №3"
		echo -e "${gl_kjlan}4. ${gl_bai}Рабочее пространство № 4"
		echo -e "${gl_kjlan}5. ${gl_bai}Рабочее пространство №5"
		echo -e "__ЗАЩИТА_0__6. ${gl_bai}Рабочее пространство №6"
		echo -e "${gl_kjlan}7. ${gl_bai}Рабочее пространство №7"
		echo -e "__ЗАЩИТА_0__8. ${gl_bai}Рабочее пространство №8"
		echo -e "__ЗАЩИТА_0__9. ${gl_bai}Рабочее пространство №9"
		echo -e "${gl_kjlan}10. ${gl_bai}Рабочее пространство №10"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21. ${gl_bai}Резидентный режим SSH ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}22. ${gl_bai}Создать/ввести рабочую область"
		echo -e "${gl_kjlan}23. ${gl_bai} вводит команды в фоновую рабочую область."
		echo -e "${gl_kjlan}24. ${gl_bai}Удалить указанное рабочее пространство"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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
				echo -e "Резидентный режим SSH ${tmux_sshd_status}"
				echo "После открытия SSH-соединения он сразу перейдет в резидентный режим и вернется в предыдущее рабочее состояние."
				echo "------------------------"
				echo "1. Вкл. 2. Выкл."
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" gongzuoqu_del
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
			read -e -p "Введите имя рабочей области, которую вы создали или ввели, например 1001 kj001 work1:" SESSION_NAME
			tmux_run
			send_stats "自定义工作区"
			;;

		23)
			read -e -p "Введите команду, которую вы хотите выполнить в фоновом режиме, например: Curl -fsSL https://get.docker.com | ш:" tmuxd
			tmux_run_d
			send_stats "注入命令到后台工作区"
			;;

		24)
			read -e -p "Пожалуйста, введите имя рабочей области, которую вы хотите удалить:" gongzuoqu_name
			tmux kill-window -t $gongzuoqu_name
			send_stats "删除工作区"
			;;

		0)
			kejilion
			;;
		*)
			echo "Неверный ввод!"
			;;
		esac
		break_end

	done

}

linux_Settings() {

	while true; do
		clear
		# send_stats "系统工具"
		echo -e "системные инструменты"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1. ${gl_bai} Установите горячую клавишу запуска сценария ${gl_kjlan}2. ${gl_bai} Изменить пароль для входа"
		echo -e "${gl_kjlan}3. ${gl_bai}Режим входа в систему с паролем ROOT ${gl_kjlan}4. ${gl_bai}Установить указанную версию Python"
		echo -e "${gl_kjlan}5. ${gl_bai}Откройте все порты ${gl_kjlan}6. ${gl_bai}Изменить порт подключения SSH"
		echo -e "${gl_kjlan}7. ${gl_bai}Оптимизируйте DNS-адрес ${gl_kjlan}8. ${gl_bai}Переустановите систему одним щелчком мыши ${gl_huang}★${gl_bai}"
		echo -e "__ЗАЩИТА_0__9. ${gl_bai} Отключите учетную запись ROOT, чтобы создать новую учетную запись ${gl_kjlan}10. ${gl_bai} Переключить приоритет на ipv4/ipv6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11. ${gl_bai} Проверьте состояние занятости порта ${gl_kjlan}12. ${gl_bai} Измените размер виртуальной памяти."
		echo -e "${gl_kjlan}13. ${gl_bai}Управление пользователями ${gl_kjlan}14. ${gl_bai}Генератор пользователя/пароля"
		echo -e "${gl_kjlan}15. ${gl_bai} Настройка часового пояса системы ${gl_kjlan}16. ${gl_bai} Установите ускорение BBR3"
		echo -e "${gl_kjlan}17. ${gl_bai} Расширенный менеджер брандмауэра ${gl_kjlan}18. ${gl_bai} Изменить имя хоста"
		echo -e "${gl_kjlan}19. ${gl_bai}Переключить источник обновления системы ${gl_kjlan}20. ${gl_bai} Управление запланированными задачами"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21. ${gl_bai} Собственное разрешение хоста ${gl_kjlan}22. ${gl_bai}Программа защиты SSH"
		echo -e "${gl_kjlan}23. ${gl_bai}Токоограничивающее автоматическое отключение ${gl_kjlan}24. ${gl_bai}Режим входа в систему с закрытым ключом ROOT"
		echo -e "${gl_kjlan}25. ${gl_bai}TG-бот системы мониторинга и оповещения ${gl_kjlan}26. ${gl_bai} Устранение уязвимостей OpenSSH высокого риска"
		echo -e "${gl_kjlan}27. ${gl_bai}Обновление ядра Red Hat Linux ${gl_kjlan}28. ${gl_bai}Оптимизация параметров ядра системы Linux ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}29. ${gl_bai}Инструмент поиска вирусов ${gl_huang}★${gl_bai} ${gl_kjlan}30. ${gl_bai}Файловый менеджер"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31. ${gl_bai}Переключить язык системы ${gl_kjlan}32. ${gl_bai}Инструмент улучшения командной строки ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33. ${gl_bai} Настройте системную корзину ${gl_kjlan}34. ${gl_bai} Резервное копирование и восстановление системы"
		echo -e "${gl_kjlan}35. ${gl_bai}ssh инструмент удаленного подключения ${gl_kjlan}36. ${gl_bai}Инструмент управления разделами жесткого диска"
		echo -e "${gl_kjlan}37. ${gl_bai} История командной строки ${gl_kjlan}38. ${gl_bai}инструмент удаленной синхронизации rsync"
		echo -e "${gl_kjlan}39. ${gl_bai} Избранные команды ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41. ${gl_bai}Доска объявлений ${gl_kjlan}66. ${gl_bai}Единая настройка системы ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}99. ${gl_bai}Перезапустите сервер ${gl_kjlan}100. ${gl_bai}Конфиденциальность и безопасность"
		echo -e "${gl_kjlan}101. ${gl_bai}k расширенное использование команды ${gl_huang}★${gl_bai} ${gl_kjlan}102. ${gl_bai}Удалить скрипт технологического льва"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_huang}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

		case $sub_choice in
		1)
			while true; do
				clear
				read -e -p "Пожалуйста, введите сочетания клавиш (введите 0 для выхода):" kuaijiejian
				if [ "$kuaijiejian" == "0" ]; then
					break_end
					linux_Settings
				fi
				find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				echo "Сочетания клавиш установлены."
				send_stats "脚本快捷键已设置"
				break_end
				linux_Settings
			done
			;;

		2)
			clear
			send_stats "设置你的登录密码"
			echo "Установите пароль для входа"
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
			echo "управление версиями Python"
			echo "Видео-знакомство: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "Эта функция позволяет легко установить любую версию, официально поддерживаемую Python!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "Текущий номер версии Python: ${gl_huang}$VERSION${gl_bai}."
			echo "------------"
			echo "Рекомендуемые версии: 3.12 3.11 3.10 3.9 3.8 2.7"
			echo "Проверьте другие версии: https://www.python.org/downloads/."
			echo "------------"
			read -e -p "Введите номер версии Python, которую вы хотите установить (введите 0 для выхода):" py_new_v

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
					echo "Неизвестный менеджер пакетов!"
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
			echo -e "Текущий номер версии Python: ${gl_huang}$VERSION${gl_bai}."
			send_stats "脚本PY版本切换"

			;;

		5)
			root_use
			send_stats "开放端口"
			iptables_open
			remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
			echo "Все порты открыты"

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
				echo -e "Текущий номер порта SSH: ${gl_huang}$current_port ${gl_bai}."

				echo "------------------------"
				echo "Номер порта находится в диапазоне от 1 до 65535. (Введите 0 для выхода)"

				# 提示用户输入新的 SSH 端口号
				read -e -p "Пожалуйста, введите новый номер порта SSH:" new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "Номер порта недействителен. Пожалуйста, введите число от 1 до 65535."
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "Неверный ввод, введите число."
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
			read -e -p "Пожалуйста, введите новое имя пользователя (введите 0 для выхода):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			install sudo

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "Операция завершена."
			;;

		10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "Установить приоритет v4/v6"
				echo "------------------------"

				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "Текущая настройка приоритета сети: ${gl_huang}IPv4${gl_bai} приоритет."
				else
					echo -e "Текущая настройка приоритета сети: ${gl_huang}IPv6${gl_bai} приоритет."
				fi

				echo ""
				echo "------------------------"
				echo "1. Сначала IPv4 2. Сначала IPv6 3. Инструмент восстановления IPv6"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Выберите предпочитаемую сеть:" choice

				case $choice in
				1)
					grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null ||
						echo 'precedence ::ffff:0:0/96  100' >>/etc/gai.conf
					echo "Переключен на приоритет IPv4."
					send_stats "已切换为 IPv4 优先"
					;;
				2)
					rm -f /etc/gai.conf
					echo "Сначала перешёл на IPv6"
					send_stats "已切换为 IPv6 优先"
					;;

				3)
					clear
					bash <(curl -L -s jhb.ovh/jb/v6.sh)
					echo "Эту функцию предоставил jhb, спасибо ему!"
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
				echo "Настройка виртуальной памяти"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "Текущая виртуальная память: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. Выделить 1024M 2. Выделить 2048M 3. Выделить 4096M 4. Нестандартный размер"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" choice

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
					read -e -p "Пожалуйста, введите размер виртуальной памяти (единица М):" new_swap
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
				echo "Список пользователей"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done </etc/passwd

				echo ""
				echo "Операции со счетом"
				echo "------------------------"
				echo "1. Создайте обычный аккаунт 2. Создайте премиум-аккаунт"
				echo "------------------------"
				echo "3. Предоставить высшие полномочия 4. Отменить высшие полномочия"
				echo "------------------------"
				echo "5. Удалить аккаунт"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

				case $sub_choice in
				1)
					# 提示用户输入新用户名
					read -e -p "Пожалуйста, введите новое имя пользователя:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					echo "Операция завершена."
					;;

				2)
					# 提示用户输入新用户名
					read -e -p "Пожалуйста, введите новое имя пользователя:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					# 赋予新用户sudo权限
					echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					install sudo

					echo "Операция завершена."

					;;
				3)
					read -e -p "Пожалуйста, введите имя пользователя:" username
					# 赋予新用户sudo权限
					echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					install sudo
					;;
				4)
					read -e -p "Пожалуйста, введите имя пользователя:" username
					# 从sudoers文件中移除用户的sudo权限
					sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

					;;
				5)
					read -e -p "Пожалуйста, введите имя пользователя, которого хотите удалить:" username
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
			echo "случайное имя пользователя"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(</dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "Случайное имя пользователя $i: $username"
			done

			echo ""
			echo "случайное имя"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "Случайное имя пользователя $i: $user_name"
			done

			echo ""
			echo "Случайный UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "Случайный UUID $i: $uuid"
			done

			echo ""
			echo "16-значный случайный пароль"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "Случайный пароль $i: $password"
			done

			echo ""
			echo "32-битный случайный пароль"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "Случайный пароль $i: $password"
			done
			echo ""

			;;

		15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "Информация о системном времени"

				# 获取当前系统时区
				local timezone=$(current_timezone)

				# 获取当前系统时间
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 显示时区和时间
				echo "Текущий часовой пояс системы: $timezone"
				echo "Текущее системное время: $current_time"

				echo ""
				echo "переключатель часового пояса"
				echo "------------------------"
				echo "Азия"
				echo "1. Шанхай, время Китая 2. Время Гонконга, Китай"
				echo "3. Токио, время Японии 4. Сеул, время Южной Кореи"
				echo "5. Сингапурское время 6. Калькутта, индийское время"
				echo "7. Дубай, время Объединенных Арабских Эмиратов 8. Сидней, время Австралии"
				echo "9. Бангкок, время Таиланда."
				echo "------------------------"
				echo "Европа"
				echo "11. Лондон, время Великобритании. 12. Париж, время Франции."
				echo "13. Берлинское время, Германия 14. Московское время, Россия."
				echo "15. Время Утрахта, Нидерланды 16. Время Мадрида, Испания."
				echo "------------------------"
				echo "Америка"
				echo "21. Западное время США 22. Восточное время США"
				echo "23. Время Канады 24. Время Мексики"
				echo "25. Время Бразилии 26. Время Аргентины"
				echo "------------------------"
				echo "31. Глобальное стандартное время UTC."
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

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
				echo -e "Текущее имя хоста: ${gl_huang}$current_hostname${gl_bai}"
				echo "------------------------"
				read -e -p "Пожалуйста, введите новое имя хоста (введите 0 для выхода):" new_hostname
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

					echo "Имя хоста было изменено на: $new_hostname."
					send_stats "主机名已更改"
					sleep 1
				else
					echo "Вышел без изменения имени хоста."
					break
				fi
			done
			;;

		19)
			root_use
			send_stats "换系统更新源"
			clear
			echo "Выберите регион источника обновлений"
			echo "Доступ к LinuxMirrors для переключения источников обновлений системы."
			echo "------------------------"
			echo "1. Материковый Китай [по умолчанию] 2. Материковый Китай [Образовательная сеть] 3. Заморские регионы"
			echo "------------------------"
			echo "0. Вернуться в предыдущее меню"
			echo "------------------------"
			read -e -p "Введите свой выбор:" choice

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
				echo "Отменено"
				;;

			esac

			;;

		20)
			send_stats "定时任务管理"
			while true; do
				clear
				check_crontab_installed
				clear
				echo "Список запланированных задач"
				crontab -l
				echo ""
				echo "действовать"
				echo "------------------------"
				echo "1. Добавить запланированное задание 2. Удалить запланированное задание 3. Изменить запланированное задание"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

				case $sub_choice in
				1)
					read -e -p "Введите команду выполнения новой задачи:" newquest
					echo "------------------------"
					echo "1. Ежемесячные задания 2. Еженедельные задания"
					echo "3. Ежедневные задания 4. Почасовые задания"
					echo "------------------------"
					read -e -p "Пожалуйста, введите ваш выбор:" dingshi

					case $dingshi in
					1)
						read -e -p "В какой день месяца вы выбираете выполнение задачи? (1-30):" day
						(
							crontab -l
							echo "0 0 $day * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					2)
						read -e -p "Выбрать день недели для выполнения задания? (0-6, 0 представляет воскресенье):" weekday
						(
							crontab -l
							echo "0 0 * * $weekday $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					3)
						read -e -p "Какое время вы выбираете для выполнения задания каждый день? (часы, 0-23):" hour
						(
							crontab -l
							echo "0 $hour * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					4)
						read -e -p "Введите, в какое время часа должна быть выполнена задача? (минуты, 0-60):" minute
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
					read -e -p "Введите ключевое слово задачи, которую необходимо удалить:" kquest
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
				echo "Список разрешений собственных хостов"
				echo "Если вы добавите сюда сопоставление синтаксического анализа, динамический синтаксический анализ больше не будет использоваться."
				cat /etc/hosts
				echo ""
				echo "действовать"
				echo "------------------------"
				echo "1. Добавить новое разрешение 2. Удалить адрес разрешения"
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" host_dns

				case $host_dns in
				1)
					read -e -p "Пожалуйста, введите новый формат записи синтаксического анализа: 110.25.5.33 kejilion.pro:" addhost
					echo "$addhost" >>/etc/hosts
					send_stats "本地host解析新增"

					;;
				2)
					read -e -p "Пожалуйста, введите ключевые слова проанализированного контента, который необходимо удалить:" delhost
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
				echo -e "Программа защиты SSH $check_f2b_status"
				echo "Fail2ban — это инструмент SSH для предотвращения взлома методом грубой силы."
				echo "Официальный сайт: ${gh_proxy}github.com/fail2ban/fail2ban."
				echo "------------------------"
				echo "1. Установите защитную программу"
				echo "------------------------"
				echo "2. Просмотр записей перехвата SSH"
				echo "3. Мониторинг журналов в реальном времени."
				echo "------------------------"
				echo "9. Удалите программу защиты."
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
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
					echo "Защитная программа Fail2Ban удалена."
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
				echo "Функция отключения по ограничению тока"
				echo "Видео-знакомство: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "Текущее использование трафика будет очищено при перезапуске сервера!"
				output_status
				echo -e "${gl_kjlan}Всего получено: ${gl_bai}$rx"
				echo -e "${gl_kjlan}Всего отправлено: ${gl_bai}$tx"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}Текущее установленное пороговое значение ограничения входящего тока: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}Текущий установленный порог ограничения исходящего тока: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui} Функция отключения по ограничению тока в настоящее время не активирована ${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "Система будет определять, достигает ли фактический трафик порогового значения каждую минуту, и автоматически отключит сервер после достижения порогового значения!"
				echo "------------------------"
				echo "1. Включите функцию отключения по ограничению тока. 2. Отключите функцию отключения по ограничению тока."
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" Limiting

				case "$Limiting" in
				1)
					# 输入新的虚拟内存大小
					echo "Если фактический сервер имеет трафик только 100 ГБ, вы можете установить пороговое значение 95 ГБ и отключить его заранее, чтобы избежать ошибок трафика или переполнения."
					read -e -p "Введите порог входящего трафика (единица измерения — G, по умолчанию — 100G):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "Введите порог исходящего трафика (единица измерения — G, по умолчанию — 100G):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "Введите дату сброса трафика (по умолчанию сбрасывается 1-го числа каждого месяца):" cz_day
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
					echo "Установлено отключение по ограничению тока."
					send_stats "限流关机已设置"
					;;
				2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "Функция отключения по ограничению тока отключена."
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
				echo "Режим входа в систему с закрытым ключом ROOT"
				echo "Видео-знакомство: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
				echo "------------------------------------------------"
				echo "Будет сгенерирована пара ключей, более безопасный способ входа в систему через SSH."
				echo "------------------------"
				echo "1. Создайте новый ключ. 2. Импортируйте существующий ключ. 3. Просмотрите локальный ключ."
				echo "------------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" host_dns

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
					echo "Информация об открытом ключе"
					cat ~/.ssh/authorized_keys
					echo "------------------------"
					echo "Информация о закрытом ключе"
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
			echo "Мониторинг TG-bot и функция раннего предупреждения"
			echo "Видео-знакомство: https://youtu.be/vLL-eb3Z_TY"
			echo "------------------------------------------------"
			echo "Вам необходимо настроить API-интерфейс tg robot и идентификатор пользователя для получения оповещений для обеспечения мониторинга в реальном времени и оповещений о локальном процессоре, памяти, жестком диске, трафике и входе в систему SSH."
			echo "При достижении порога пользователю будет отправлено предупреждающее сообщение."
			echo -e "${gl_hui} - по трафику, при перезапуске сервера произойдет перерасчет - ${gl_bai}"
			read -e -p "Вы уверены, что хотите продолжить? (да/нет):" choice

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
				echo "Активирована система раннего оповещения TG-bot"
				echo -e "${gl_hui}Вы также можете поместить файл предупреждения TG-check-notify.sh в корневой каталог на других машинах и использовать его напрямую! ${gl_bai}"
				;;
			[Nn])
				echo "Отменено"
				;;
			*)
				echo "Неверный выбор, введите Y или N."
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
			echo "Посетите официальную доску объявлений Technology Lion. Если у вас есть идеи по поводу сценария, оставьте сообщение для обмена!"
			echo "https://board.kejilion.pro"
			echo "Публичный пароль: kejilion.sh"
			;;

		66)

			root_use
			send_stats "一条龙调优"
			echo "Универсальная настройка системы"
			echo "------------------------------------------------"
			echo "Следующий контент будет работать и оптимизироваться"
			echo "1. Обновите систему до последней версии"
			echo "2. Очистите системные ненужные файлы."
			echo -e "3. Установите виртуальную память ${gl_huang}1G${gl_bai}."
			echo -e "4. Установите номер порта SSH на ${gl_huang}5522${gl_bai}."
			echo -e "5. Откройте все порты"
			echo -e "6. Включите ускорение ${gl_huang}BBR${gl_bai}."
			echo -e "7. Установите часовой пояс ${gl_huang}Шанхай${gl_bai}."
			echo -e "8. Автоматическая оптимизация DNS-адреса ${gl_huang} За рубежом: 1.1.1.1 8.8.8.8 Внутри страны: 223.5.5.5 ${gl_bai}"
			echo -e "9. Установите базовые инструменты ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			echo -e "10. Оптимизация параметров ядра системы Linux переключается в режим сбалансированной оптимизации ${gl_huang} ${gl_bai}."
			echo "------------------------------------------------"
			read -e -p "Вы уверены, что хотите обслуживание в один клик? (да/нет):" choice

			case "$choice" in
			[Yy])
				clear
				send_stats "一条龙调优启动"
				echo "------------------------------------------------"
				linux_update
				echo -e "[${gl_lv}OK${gl_bai}] 1/10. Обновите систему до последней версии"

				echo "------------------------------------------------"
				linux_clean
				echo -e "[${gl_lv}OK${gl_bai}] 10.02. Очистите системные ненужные файлы"

				echo "------------------------------------------------"
				add_swap 1024
				echo -e "[${gl_lv}OK${gl_bai}] 3/10. Установить виртуальную память ${gl_huang}1G${gl_bai}"

				echo "------------------------------------------------"
				local new_port=5522
				new_ssh_port
				echo -e "[${gl_lv}OK${gl_bai}] 4/10. Установите номер порта SSH на ${gl_huang}5522${gl_bai}."
				echo "------------------------------------------------"
				echo -e "[${gl_lv}OK${gl_bai}] 5/10. Открыть все порты"

				echo "------------------------------------------------"
				bbr_on
				echo -e "[${gl_lv}OK${gl_bai}] 6/10. Включите ускорение ${gl_huang}BBR${gl_bai}."

				echo "------------------------------------------------"
				set_timedate Asia/Shanghai
				echo -e "[${gl_lv}OK${gl_bai}] 7/10. Установите часовой пояс ${gl_huang}Шанхай${gl_bai}."

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
				echo -e "[${gl_lv}OK${gl_bai}] 8/10. Автоматически оптимизировать DNS-адрес ${gl_huang}${gl_bai}"

				echo "------------------------------------------------"
				install_docker
				install wget sudo tar unzip socat btop nano vim
				echo -e "[${gl_lv}OK${gl_bai}] 9/10. Установите базовые инструменты ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				echo "------------------------------------------------"

				echo "------------------------------------------------"
				optimize_balanced
				echo -e "[${gl_lv}OK${gl_bai}] 10/10. Оптимизация параметров ядра системы Linux"
				echo -e "${gl_lv}Комплексная настройка системы завершена${gl_bai}"

				;;
			[Nn])
				echo "Отменено"
				;;
			*)
				echo "Неверный выбор, введите Y или N."
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

				echo "Конфиденциальность и безопасность"
				echo "Скрипт будет собирать данные об использовании функций пользователями, оптимизировать работу со скриптом и создавать больше интересных и полезных функций."
				echo "Будут собраны номер версии сценария, время использования, версия системы, архитектура ЦП, страна машины и название используемой функции."
				echo "------------------------------------------------"
				echo -e "Текущий статус: $status_message"
				echo "--------------------"
				echo "1. Начать сбор"
				echo "2. Закрыть сбор"
				echo "--------------------"
				echo "0. Вернуться в предыдущее меню"
				echo "--------------------"
				read -e -p "Пожалуйста, введите ваш выбор:" sub_choice
				case $sub_choice in
				1)
					cd ~
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					echo "Сбор начался"
					send_stats "隐私与安全已开启采集"
					;;
				2)
					cd ~
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					echo "Коллекция закрыта"
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
			echo "Удалить скрипт технологического льва"
			echo "------------------------------------------------"
			echo "Скрипт kejilion будет полностью удален, не затрагивая другие ваши функции."
			read -e -p "Вы уверены, что хотите продолжить? (да/нет):" choice

			case "$choice" in
			[Yy])
				clear
				(crontab -l | grep -v "kejilion.sh") | crontab -
				rm -f /usr/local/bin/k
				rm ~/kejilion.sh
				echo "Скрипт удален, до свидания!"
				break_end
				clear
				exit
				;;
			[Nn])
				echo "Отменено"
				;;
			*)
				echo "Неверный выбор, введите Y или N."
				;;
			esac
			;;

		0)
			kejilion

			;;
		*)
			echo "Неверный ввод!"
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
		echo "файловый менеджер"
		echo "------------------------"
		echo "текущий путь"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. Введите каталог 2. Создайте каталог 3. Измените права доступа к каталогу 4. Переименуйте каталог"
		echo "5. Удалить каталог 6. Вернуться в предыдущий каталог меню"
		echo "------------------------"
		echo "11. Создание файлов 12. Редактирование файлов 13. Изменение разрешений файлов 14. Переименование файлов"
		echo "15. Удалить файлы"
		echo "------------------------"
		echo "21. Сжать каталог файлов 22. Разархивировать каталог файлов 23. Переместить каталог файлов 24. Скопировать каталог файлов"
		echo "25. Перенос файлов на другие серверы"
		echo "------------------------"
		echo "0. Вернуться в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" Limiting

		case "$Limiting" in
		1) # 进入目录
			read -e -p "Пожалуйста, введите имя каталога:" dirname
			cd "$dirname" 2>/dev/null || echo "Невозможно войти в каталог"
			send_stats "进入目录"
			;;
		2) # 创建目录
			read -e -p "Введите имя создаваемого каталога:" dirname
			mkdir -p "$dirname" && echo "Каталог создан" || echo "Не удалось создать"
			send_stats "创建目录"
			;;
		3) # 修改目录权限
			read -e -p "Пожалуйста, введите имя каталога:" dirname
			read -e -p "Введите разрешения (например, 755):" perm
			chmod "$perm" "$dirname" && echo "Разрешения были изменены" || echo "Модификация не удалась"
			send_stats "修改目录权限"
			;;
		4) # 重命名目录
			read -e -p "Пожалуйста, введите имя текущего каталога:" current_name
			read -e -p "Пожалуйста, введите новое имя каталога:" new_name
			mv "$current_name" "$new_name" && echo "Каталог переименован" || echo "Переименование не удалось"
			send_stats "重命名目录"
			;;
		5) # 删除目录
			read -e -p "Пожалуйста, введите имя каталога, который нужно удалить:" dirname
			rm -rf "$dirname" && echo "Каталог удален." || echo "Удаление не удалось"
			send_stats "删除目录"
			;;
		6) # 返回上一级选单目录
			cd ..
			send_stats "返回上一级选单目录"
			;;
		11) # 创建文件
			read -e -p "Пожалуйста, введите имя файла, который необходимо создать:" filename
			touch "$filename" && echo "Файл создан" || echo "Не удалось создать"
			send_stats "创建文件"
			;;
		12) # 编辑文件
			read -e -p "Пожалуйста, введите имя файла для редактирования:" filename
			install nano
			nano "$filename"
			send_stats "编辑文件"
			;;
		13) # 修改文件权限
			read -e -p "Пожалуйста, введите имя файла:" filename
			read -e -p "Введите разрешения (например, 755):" perm
			chmod "$perm" "$filename" && echo "Разрешения были изменены" || echo "Модификация не удалась"
			send_stats "修改文件权限"
			;;
		14) # 重命名文件
			read -e -p "Пожалуйста, введите текущее имя файла:" current_name
			read -e -p "Пожалуйста, введите новое имя файла:" new_name
			mv "$current_name" "$new_name" && echo "Файл переименован" || echo "Переименование не удалось"
			send_stats "重命名文件"
			;;
		15) # 删除文件
			read -e -p "Пожалуйста, введите имя файла, который необходимо удалить:" filename
			rm -f "$filename" && echo "Файл удален" || echo "Удаление не удалось"
			send_stats "删除文件"
			;;
		21) # 压缩文件/目录
			read -e -p "Пожалуйста, введите имя файла/каталога для сжатия:" name
			install tar
			tar -czvf "$name.tar.gz" "$name" && echo "Сжат в $name.tar.gz." || echo "Сжатие не удалось"
			send_stats "压缩文件/目录"
			;;
		22) # 解压文件/目录
			read -e -p "Пожалуйста, введите имя файла для извлечения (.tar.gz):" filename
			install tar
			tar -xzvf "$filename" && echo "Извлеченный $filename" || echo "Декомпрессия не удалась"
			send_stats "解压文件/目录"
			;;

		23) # 移动文件或目录
			read -e -p "Пожалуйста, введите путь к файлу или каталогу, который необходимо переместить:" src_path
			if [ ! -e "$src_path" ]; then
				echo "Ошибка: Файл или каталог не существует."
				send_stats "移动文件或目录失败: 文件或目录不存在"
				continue
			fi

			read -e -p "Введите путь назначения (включая имя нового файла или каталога):" dest_path
			if [ -z "$dest_path" ]; then
				echo "Ошибка: введите путь назначения."
				send_stats "移动文件或目录失败: 目标路径未指定"
				continue
			fi

			mv "$src_path" "$dest_path" && echo "Файл или каталог перемещен в $dest_path" || echo "Не удалось переместить файл или каталог"
			send_stats "移动文件或目录"
			;;

		24) # 复制文件目录
			read -e -p "Пожалуйста, введите путь к файлу или каталогу для копирования:" src_path
			if [ ! -e "$src_path" ]; then
				echo "Ошибка: Файл или каталог не существует."
				send_stats "复制文件或目录失败: 文件或目录不存在"
				continue
			fi

			read -e -p "Введите путь назначения (включая имя нового файла или каталога):" dest_path
			if [ -z "$dest_path" ]; then
				echo "Ошибка: введите путь назначения."
				send_stats "复制文件或目录失败: 目标路径未指定"
				continue
			fi

			# 使用 -r 选项以递归方式复制目录
			cp -r "$src_path" "$dest_path" && echo "Файл или каталог скопирован в $dest_path." || echo "Не удалось скопировать файл или каталог"
			send_stats "复制文件或目录"
			;;

		25) # 传送文件至远端服务器
			read -e -p "Пожалуйста, введите путь к файлу для передачи:" file_to_transfer
			if [ ! -f "$file_to_transfer" ]; then
				echo "Ошибка: Файл не существует."
				send_stats "传送文件失败: 文件不存在"
				continue
			fi

			read -e -p "Пожалуйста, введите IP-адрес удаленного сервера:" remote_ip
			if [ -z "$remote_ip" ]; then
				echo "Ошибка: введите IP-адрес удаленного сервера."
				send_stats "传送文件失败: 未输入远端服务器IP"
				continue
			fi

			read -e -p "Пожалуйста, введите имя пользователя удаленного сервера (по умолчанию root):" remote_user
			remote_user=${remote_user:-root}

			read -e -p "Пожалуйста, введите пароль удаленного сервера:" -s remote_password
			echo
			if [ -z "$remote_password" ]; then
				echo "Ошибка: введите пароль удаленного сервера."
				send_stats "传送文件失败: 未输入远端服务器密码"
				continue
			fi

			read -e -p "Пожалуйста, введите порт входа (по умолчанию 22):" remote_port
			remote_port=${remote_port:-22}

			# 清除已知主机的旧条目
			ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			sleep 2 # 等待时间

			# 使用scp传输文件
			scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

			if [ $? -eq 0 ]; then
				echo "Файл был перенесен в домашний каталог удаленного сервера."
				send_stats "文件传送成功"
			else
				echo "Передача файла не удалась."
				send_stats "文件传送失败"
			fi

			break_end
			;;

		0) # 返回上一级选单
			send_stats "返回上一级选单菜单"
			break
			;;
		*) # 处理无效输入
			echo "Неверный выбор, пожалуйста, введите еще раз"
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
		echo -e "${gl_huang} подключается к $name ($hostname)...${gl_bai}"
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
		echo "Управление кластером серверов"
		cat ~/cluster/servers.py
		echo
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}Управление списком серверов${gl_bai}"
		echo -e "${gl_kjlan}1. ${gl_bai}Добавить сервер ${gl_kjlan}2. ${gl_bai}Удалить сервер ${gl_kjlan}3. ${gl_bai}Изменить сервер"
		echo -e "${gl_kjlan}4. ${gl_bai}Резервный кластер ${gl_kjlan}5. ${gl_bai}Восстановить кластер"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}Пакетное выполнение задач${gl_bai}"
		echo -e "${gl_kjlan}11. ${gl_bai}Установите скрипт технологического льва ${gl_kjlan}12. ${gl_bai}Обновите систему ${gl_kjlan}13. ${gl_bai}Очистите систему"
		echo -e "${gl_kjlan}14. ${gl_bai}Установите докер ${gl_kjlan}15. ${gl_bai}Установите BBR3 ${gl_kjlan}16. ${gl_bai}Установить виртуальную память 1 ГБ"
		echo -e "${gl_kjlan}17. ${gl_bai}Установить часовой пояс Шанхай ${gl_kjlan}18. ${gl_bai}Откройте все порты ${gl_kjlan}51. ${gl_bai}Пользовательская команда"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0. ${gl_bai} Вернуться в главное меню"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" sub_choice

		case $sub_choice in
		1)
			send_stats "添加集群服务器"
			read -e -p "Имя сервера:" server_name
			read -e -p "IP сервера:" server_ip
			read -e -p "Порт сервера (22):" server_port
			local server_port=${server_port:-22}
			read -e -p "Имя пользователя сервера (root):" server_username
			local server_username=${server_username:-root}
			read -e -p "Пароль пользователя сервера:" server_password

			sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			;;
		2)
			send_stats "删除集群服务器"
			read -e -p "Пожалуйста, введите ключевые слова, которые необходимо удалить:" rmserver
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
			echo -e "Загрузите файл ${gl_huang}/root/cluster/servers.py${gl_bai}, чтобы завершить резервное копирование!"
			break_end
			;;

		5)
			clear
			send_stats "还原集群"
			echo "Пожалуйста, загрузите свой файл server.py и нажмите любую клавишу, чтобы начать загрузку!"
			echo -e "Загрузите файл ${gl_huang}servers.py${gl_bai} в ${gl_huang}/root/cluster/${gl_bai}, чтобы завершить восстановление!"
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
			read -e -p "Введите команду для пакетного выполнения:" mingling
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
	echo "Рекламная колонка"
	echo "------------------------"
	echo "Это предоставит пользователям более простой и элегантный опыт продвижения и покупок!"
	echo ""
	echo -e "Скидка на сервер"
	echo "------------------------"
	echo -e "${gl_lan} Leica Cloud Гонконг CN2 GIA Корейский двойной интернет-провайдер Американский промоушен CN2 GIA ${gl_bai}"
	echo -e "${gl_bai}Веб-сайт: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}RackNerd $10,99 в год США 1 ядро ​​1 ГБ памяти 20 ГБ жесткого диска 1 ТБ трафика в месяц ${gl_bai}"
	echo -e "${gl_bai} URL-адрес: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}Hostinger $52,7 в год США 1 ядро ​​4G памяти 50G жесткий диск 4T трафика в месяц ${gl_bai}"
	echo -e "${gl_bai} URL-адрес: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
	echo "------------------------"
	echo -e "${gl_huang} Каменщик 49 долларов в квартал США CN2GIA Япония SoftBank 2 ядра 1 ГБ памяти 20 ГБ жесткого диска 1 Т трафика в месяц ${gl_bai}"
	echo -e "${gl_bai} URL: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}DMIT 28 долларов США в квартал, США CN2GIA 1 ядро, память 2 ГБ, жесткий диск 20 ГБ, трафик 800 ГБ в месяц${gl_bai}"
	echo -e "${gl_bai} URL: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}V.PS 6,9 долларов в месяц Tokyo Softbank 2 ядра 1G памяти 20G жесткий диск 1T трафика в месяц ${gl_bai}"
	echo -e "${gl_bai} URL: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}Более популярные предложения VPS${gl_bai}"
	echo -e "${gl_bai} URL: https://kejilion.pro/topvps/${gl_bai}"
	echo "------------------------"
	echo ""
	echo -e "Скидка на доменное имя"
	echo "------------------------"
	echo -e "${gl_lan}GNAME 8,8 долл. США, доменное имя COM на первый год 6,68 долл. США, доменное имя CC на первый год ${gl_bai}"
	echo -e "${gl_bai} URL-адрес: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
	echo "------------------------"
	echo ""
	echo -e "Технологические периферийные устройства льва"
	echo "------------------------"
	echo -e "Станция ${gl_kjlan}B: ${gl_bai}https://b23.tv/2mqnQyh ${gl_kjlan}Youtube: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
	echo -e "Официальный сайт ${gl_kjlan}: ${gl_bai}https://kejilion.pro/ ${gl_kjlan} навигация: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
	echo -e "${gl_kjlan} Блог: ${gl_bai}https://blog.kejilion.pro/ ${gl_kjlan}Центр программного обеспечения: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}Официальный сайт скрипта: ${gl_bai}https://kejilion.sh ${gl_kjlan}Адрес GitHub: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
	echo "------------------------"
	echo ""
}

kejilion_update() {

	send_stats "脚本更新"
	cd ~
	while true; do
		clear
		echo "Журнал изменений"
		echo "------------------------"
		echo "Все журналы: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
		echo "------------------------"

		curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
		local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

		if [ "$sh_v" = "$sh_v_new" ]; then
			echo -e "${gl_lv}Вы уже используете последнюю версию! ${gl_huang}v$sh_v${gl_bai}"
			send_stats "脚本已经最新了，无需更新"
		else
			echo "Обнаружена новая версия!"
			echo -e "Текущая версия v$sh_v Последняя версия ${gl_huang}v$sh_v_new${gl_bai}"
		fi

		local cron_job="kejilion.sh"
		local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

		if [ -n "$existing_cron" ]; then
			echo "------------------------"
			echo -e "${gl_lv} Включено автоматическое обновление, и скрипт будет автоматически обновляться в 2 часа ночи каждый день! ${gl_bai}"
		fi

		echo "------------------------"
		echo "1. Обновить сейчас 2. Включить автоматические обновления 3. Отключить автоматические обновления"
		echo "------------------------"
		echo "0. Вернуться в главное меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите ваш выбор:" choice
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
			echo -e "Скрипт ${gl_lv} обновлен до последней версии! ${gl_huang}v$sh_v_new${gl_bai}"
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
			echo -e "${gl_lv} Включено автоматическое обновление, и скрипт будет автоматически обновляться в 2 часа ночи каждый день! ${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}Автоматические обновления отключены${gl_bai}"
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
		echo -e "Набор инструментов для сценариев Technology Lion v$sh_v"
		echo -e "Введите ${gl_huang}k${gl_kjlan} в командной строке, чтобы быстро запустить скрипт ${gl_bai}."
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}1. ${gl_bai} Запрос информации о системе"
		echo -e "${gl_kjlan}2. ${gl_bai} обновление системы"
		echo -e "${gl_kjlan}3. ${gl_bai}Очистка системы"
		echo -e "${gl_kjlan}4. ${gl_bai}Основные инструменты"
		echo -e "${gl_kjlan}5. ${gl_bai}Управление BBR"
		echo -e "${gl_kjlan}6. ${gl_bai}Управление Docker"
		echo -e "${gl_kjlan}7. ${gl_bai}Управление WARP"
		echo -e "__ЗАЩИТА_0__8. ${gl_bai} Коллекция тестовых сценариев"
		echo -e "__ЗАЩИТА_0__9. ${gl_bai}Коллекция сценариев Oracle Cloud"
		echo -e "${gl_huang}10. ${gl_bai}Создание сайта LDNMP"
		echo -e "${gl_kjlan}11. ${gl_bai} Маркет приложений"
		echo -e "${gl_kjlan}12. ${gl_bai}Внутреннее рабочее пространство"
		echo -e "${gl_kjlan}13. ${gl_bai} Системные инструменты"
		echo -e "${gl_kjlan}14. ${gl_bai} Управление кластером серверов"
		echo -e "${gl_kjlan}15. ${gl_bai}Рекламный столбец"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}стр. ${gl_bai}Скрипт открытия сервера Eudemons Parlu"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}00. ${gl_bai} обновление сценария"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0. ${gl_bai}Выход из сценария"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		read -e -p "Пожалуйста, введите ваш выбор:" choice

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
		*) echo "Неверный ввод!" ;;
		esac
		break_end
	done
}

k_info() {
	send_stats "k命令参考用例"
	echo "-------------------"
	echo "Видео-знакомство: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
	echo "Ниже приведен пример использования команды k:"
	echo "Запустить скрипт k"
	echo "Установить пакеты k установить nano wget | k добавить nano wget | установить nano wget"
	echo "Удалить пакет k удалить nano wget | к дель нано wget | k удалить nano wget | удалить nano wget"
	echo "Обновление системы k обновление | обновление"
	echo "Очистить систему от мусора k очистить | К чистоте"
	echo "Переустановить системную панель k dd | переустановить"
	echo "панель управления bbr3 k bbr3 | к ббрв3"
	echo "Панель настройки ядра k nhyh | k Оптимизация ядра"
	echo "Установить виртуальную память k swap 2048"
	echo "Установить виртуальный часовой пояс k время Азия/Шанхай | k часовой пояс Азия/Шанхай"
	echo "Система Recycle Bin k мусор | к хсз | k Корзина"
	echo "Функция резервного копирования системы k резервное копирование | к бою | резервная копия"
	echo "инструмент удаленного подключения ssh k ssh | к удаленное соединение"
	echo "инструмент удаленной синхронизации rsync k rsync | k удаленная синхронизация"
	echo "Инструмент управления жестким диском k диск | управление жестким диском"
	echo "Проникновение во внутреннюю сеть (сервер) k frps"
	echo "Проникновение во внутреннюю сеть (клиент) k frpc"
	echo "Запуск программного обеспечения k start sshd | начать sshd"
	echo "Программное обеспечение стоп-к-стоп sshd | окей, останови sshd"
	echo "Программный перезапуск k перезапуск sshd | перезапустить sshd"
	echo "Проверьте статус программного обеспечения k status sshd | статус к sshd"
	echo "k включить докер | k автозапуск докера | k включить докер при загрузке программного обеспечения"
	echo "Приложение для получения сертификата доменного имени k SSL"
	echo "Запрос на истечение срока действия сертификата доменного имени k ssl ps"
	echo "плоскость управления Docker K Docker"
	echo "установка среды docker k установка docker | установка k docker"
	echo "управление контейнером docker k docker ps |k docker-контейнер"
	echo "управление образами docker k docker img |k docker image"
	echo "Управление сайтом LDNMP в Интернете"
	echo "Очистка кэша LDNMP и веб-кеша"
	echo "Установите WordPress k wp | к WordPress | к WP xxx.com"
	echo "Установить обратный прокси-сервер k fd |k rp |k обратный прокси-сервер |k fd xxx.com"
	echo "Установите балансировку нагрузки k loadbalance |k load balancing"
	echo "Установите балансировку нагрузки L4 k поток |k балансировку нагрузки L4"
	echo "панель брандмауэра k fhq |k брандмауэр"
	echo "открыть порт k dkdk 8080 |k открыть порт 8080"
	echo "Закрыть порт k gbdk 7800 |k Закрыть порт 7800"
	echo "Версия IP k fxip 127.0.0.0/8 |k Версия IP 127.0.0.0/8"
	echo "Заблокировать IP k zzip 177.5.25.36 |k Заблокировать IP 177.5.25.36"
	echo "избранное команды k fav | k любимые команды"
	echo "Управление рынком приложений k app"
	echo "Быстрое управление номерами заявок в приложении 26 | приложение k 1 панель | приложение k npm"
	echo "Отображение информации о системе k info"
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
			echo "IP+порт заблокирован для доступа к сервису"
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

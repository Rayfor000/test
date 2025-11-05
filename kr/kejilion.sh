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
	echo -e "${gl_kjlan}KejiLion 스크립트 도구 상자 사용에 오신 것을 환영합니다.${gl_bai}"
	echo "스크립트를 처음 사용하는 경우 먼저 사용자 라이선스 계약을 읽고 동의하십시오."
	echo "사용자 라이선스 계약: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "위 약관에 동의하십니까?\(y/N\): " user_input


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
		echo "패키지 매개변수가 제공되지 않았습니다!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}$package 설치 중...${gl_bai}"
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
				echo "알 수 없는 패키지 관리자!"
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
		echo -e "${gl_huang}팁:${gl_bai} 디스크 공간이 부족합니다!"
		echo "현재 사용 가능한 공간: $((available_space_mb/1024))G"
		echo "최소 요구 공간: ${required_gb}G"
		echo "설치를 계속할 수 없습니다. 디스크 공간을 정리하고 다시 시도하십시오."
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
		echo "패키지 매개변수가 제공되지 않았습니다!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}$package 제거 중...${gl_bai}"
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
			echo "알 수 없는 패키지 관리자!"
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
		echo "$1 서비스가 다시 시작되었습니다."
	else
		echo "오류: $1 서비스 다시 시작에 실패했습니다."
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1 서비스가 시작되었습니다."
	else
		echo "오류: $1 서비스 시작에 실패했습니다."
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1 서비스가 중지되었습니다."
	else
		echo "오류: $1 서비스 중지에 실패했습니다."
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1 서비스 상태가 표시되었습니다."
	else
		echo "오류: $1 서비스 상태를 표시할 수 없습니다."
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME이 부팅 시 자동 시작으로 설정되었습니다."
}



break_end() {
	  echo -e "${gl_lv}작업 완료${gl_bai}"
	  echo "아무 키나 눌러 계속..."
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
	echo -e "${gl_huang}Docker 환경 설치 중...${gl_bai}"
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
	echo "Docker 컨테이너 목록"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "컨테이너 작업"
	echo "------------------------"
	echo "1. 새 컨테이너 생성"
	echo "------------------------"
	echo "2. 특정 컨테이너 시작             6. 모든 컨테이너 시작"
	echo "3. 특정 컨테이너 중지             7. 모든 컨테이너 중지"
	echo "4. 특정 컨테이너 삭제             8. 모든 컨테이너 삭제"
	echo "5. 특정 컨테이너 재시작         9. 모든 컨테이너 재시작"
	echo "------------------------"
	echo "11. 특정 컨테이너 접속             12. 컨테이너 로그 보기"
	echo "13. 컨테이너 네트워크 보기             14. 컨테이너 사용량 보기"
	echo "------------------------"
	echo "15. 컨테이너 포트 접근 허용       16. 컨테이너 포트 접근 금지"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요: " sub_choice
	case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "생성 명령을 입력하세요:" dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			read -e -p "컨테이너 이름(여러 컨테이너 이름은 공백으로 구분):" dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "컨테이너 이름(여러 컨테이너 이름은 공백으로 구분):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			read -e -p "컨테이너 이름(여러 컨테이너 이름은 공백으로 구분):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			read -e -p "컨테이너 이름(여러 컨테이너 이름은 공백으로 구분):" dockername
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
			read -e -p "$(echo -e "${gl_hong}주의:${gl_bai} 모든 컨테이너를 삭제하시겠습니까? (y/N):")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			read -e -p "컨테이너 이름을 입력하세요:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			read -e -p "컨테이너 이름을 입력하세요:" dockername
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
			read -e -p "컨테이너 이름을 입력하세요:" docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "阻止容器端口访问"
			read -e -p "컨테이너 이름을 입력하세요:" docker_name
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
	echo "Docker 이미지 목록"
	docker image ls
	echo ""
	echo "미러 작업"
	echo "------------------------"
	echo "1. 지정된 이미지 가져오기             2. 지정된 이미지 업데이트"
	echo "3. 지정된 이미지 삭제             4. 모든 이미지 삭제"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요: " sub_choice
	case $sub_choice in
		1)
			send_stats "拉取镜像"
			read -e -p "이미지 이름(여러 이미지 이름은 공백으로 구분):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}이미지 가져오는 중: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			read -e -p "이미지 이름(여러 이미지 이름은 공백으로 구분):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}이미지 업데이트 중: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			read -e -p "이미지 이름(여러 이미지 이름은 공백으로 구분):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			read -e -p "$(echo -e "${gl_hong}주의:${gl_bai} 모든 이미지를 삭제하시겠습니까? (y/N):")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
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
				echo "지원되지 않는 배포판: $ID"
				return
				;;
		esac
	else
		echo "운영체제를 확인할 수 없습니다."
		return
	fi

	echo -e "${gl_lv}crontab이 설치되어 있고 cron 서비스가 실행 중입니다.${gl_bai}"
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
			echo -e "${gl_huang}현재 IPv6 액세스가 활성화되어 있습니다.${gl_bai}"
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
		echo -e "${gl_hong}설정 파일이 없습니다.${gl_bai}"
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
		echo -e "${gl_huang}현재 IPv6 액세스가 비활성화되어 있습니다.${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}IPv6 액세스가 성공적으로 비활성화되었습니다.${gl_bai}"
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
		echo "최소 하나의 포트 번호를 제공해주세요."
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
			echo "포트 $port 열림"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "최소 하나의 포트 번호를 제공해주세요."
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
			echo "포트 $port 닫힘"
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
		echo "최소 하나의 IP 주소 또는 IP 대역을 제공해주세요."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP $ip 허용됨"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "최소 하나의 IP 주소 또는 IP 대역을 제공해주세요."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP $ip 차단됨"
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
					echo "오류: $country_code의 IP 영역 파일 다운로드 실패"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "$country_code의 IP 주소 차단 성공"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "오류: $country_code의 IP 영역 파일 다운로드 실패"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "$country_code의 IP 주소 허용 성공"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "$country_code의 IP 주소 제한 해제 성공"
				;;

			*)
				echo "사용법: manage_country_rules {block|allow|unblock} <country_code...>"
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
		  echo "고급 방화벽 관리"
		  send_stats "高级防火墙管理"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "방화벽 관리"
		  echo "------------------------"
		  echo "1. 지정된 포트 열기                2. 지정된 포트 닫기"
		  echo "3. 모든 포트 열기                4. 모든 포트 닫기"
		  echo "------------------------"
		  echo "5. IP 화이트리스트                     6. IP 블랙리스트"
		  echo "7. 지정된 IP 삭제"
		  echo "------------------------"
		  echo "11. PING 허용                     12. PING 금지"
		  echo "------------------------"
		  echo "13. DDOS 방어 활성화                14. DDOS 방어 비활성화"
		  echo "------------------------"
		  echo "15. 지정된 국가 IP 차단               16. 지정된 국가 IP만 허용"
		  echo "17. 지정된 국가 IP 제한 해제"
		  echo "------------------------"
		  echo "0. 이전 메뉴로 돌아가기"
		  echo "------------------------"
		  read -e -p "선택을 입력하세요: " sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "열린 포트 번호를 입력하세요:" o_port
				  open_port $o_port
				  send_stats "开放指定端口"
				  ;;
			  2)
				  read -e -p "닫힌 포트 번호를 입력하세요:" c_port
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
				  read -e -p "허용할 IP 또는 IP 범위를 입력하세요:" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP 黑名单
				  read -e -p "차단할 IP 또는 IP 범위를 입력하세요:" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 清除指定 IP
				  read -e -p "지울 IP를 입력하세요:" d_ip
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
				  read -e -p "차단할 국가 코드(여러 국가 코드는 공백으로 구분, 예: CN US JP):" country_code
				  manage_country_rules block $country_code
				  send_stats "允许国家 $country_code 的IP"
				  ;;
			  16)
				  read -e -p "허용할 국가 코드(여러 국가 코드는 공백으로 구분, 예: CN US JP):" country_code
				  manage_country_rules allow $country_code
				  send_stats "阻止国家 $country_code 的IP"
				  ;;

			  17)
				  read -e -p "지울 국가 코드(여러 국가 코드는 공백으로 구분, 예: CN US JP):" country_code
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

	echo -e "가상 메모리 크기가 ${gl_huang}${new_swap}${gl_bai}M로 조정되었습니다."
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
echo "IPv4 우선으로 전환되었습니다."
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
	  echo "LDNMP 환경 설치 완료"
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
	echo "갱신 작업이 업데이트되었습니다."
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
	echo -e "${gl_huang}$yuming 공개 키 정보${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming 개인 키 정보${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}인증서 저장 경로${gl_bai}"
	echo "공개 키: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "개인 키: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}SSL 인증서를 빠르게 신청하고 만료 전에 자동으로 갱신합니다.${gl_bai}"
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
	echo -e "${gl_huang}만료된 인증서${gl_bai}"
	echo "사이트 정보 인증서 만료 시간"
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
		echo -e "${gl_hong}주의:${gl_bai} 인증서 신청에 실패했습니다. 다음 가능한 원인을 확인하고 다시 시도하십시오:"
		echo -e "1. 도메인 철자 오류 ➠ 도메인 입력이 정확한지 확인하십시오."
		echo -e "2. DNS 파싱 문제 ➠ 도메인이 이 서버 IP로 올바르게 파싱되었는지 확인하십시오."
		echo -e "3. 네트워크 구성 문제 ➠ Cloudflare Warp와 같은 가상 네트워크를 사용하는 경우 잠시 끄십시오."
		echo -e "4. 방화벽 제한 ➠ 80/443 포트가 열려 있는지 확인하고 인증서에 액세스할 수 있는지 확인하십시오."
		echo -e "5. 신청 횟수 초과 ➠ Let's Encrypt에는 주당 제한(5회/도메인/주)이 있습니다."
		echo -e "6. 중국 지역 등록 제한 ➠ 중국 본토 환경에서는 도메인이 등록되었는지 확인하십시오."
		break_end
		clear
		echo "$webname 배포를 다시 시도하십시오."
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
	  echo -e "먼저 도메인을 로컬 IP로 파싱하십시오: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "IP 주소 또는 파싱된 도메인을 입력하세요:" yuming
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
  echo "${ldnmp_pods} 업데이트 완료"

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
  echo "로그인 정보:"
  echo "사용자 이름: $dbuse"
  echo "비밀번호: $dbusepasswd"
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
	read -e -p "Cloudflare 캐시를 정리하시겠습니까? (y/N):" answer
	if [[ "$answer" == "y" ]]; then
	  echo "Cloudflare 정보는 $CONFIG_FILE에 저장되며 나중에 Cloudflare 정보를 수정할 수 있습니다."
	  read -e -p "API_TOKEN을 입력하세요:" API_TOKEN
	  read -e -p "Cloudflare 사용자 이름을 입력하세요:" EMAIL
	  read -e -p "zone_id(여러 개는 공백으로 구분):" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 循环遍历每个 zone_id 并执行清除缓存命令
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "영역 ID의 캐시를 삭제하는 중: $ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "캐시 삭제 요청이 완료되었습니다."
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
		read -e -p "사이트 데이터를 삭제하려면 도메인(여러 도메인은 공백으로 구분)을 입력하세요:" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "도메인 삭제 중: $yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "데이터베이스 삭제 중: $dbname"
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
		echo "잘못된 매개변수: 'on' 또는 'off'를 사용하세요"
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
		echo "잘못된 매개변수: 'on' 또는 'off'를 사용하세요"
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
		echo "잘못된 매개변수: 'on' 또는 'off'를 사용하세요"
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
		echo "잘못된 매개변수: 'on' 또는 'off'를 사용하세요"
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
			  echo -e "서버 웹사이트 방어 프로그램 ${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 방어 프로그램 설치"
			  echo "------------------------"
			  echo "5. SSH 가로채기 기록 보기              6. 웹사이트 가로채기 기록 보기"
			  echo "7. 방어 규칙 목록 보기               8. 로그 실시간 모니터링"
			  echo "------------------------"
			  echo "11. 가로채기 매개변수 설정                   12. 모든 블랙리스트 IP 삭제"
			  echo "------------------------"
			  echo "21. Cloudflare 모드                22. 고부하 시 5초 보호 활성화"
			  echo "------------------------"
			  echo "31. WAF 활성화                       32. WAF 비활성화"
			  echo "33. DDOS 방어 활성화                 34. DDOS 방어 비활성화"
			  echo "------------------------"
			  echo "9. 방어 프로그램 제거"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아가기"
			  echo "------------------------"
			  read -e -p "선택을 입력하세요: " sub_choice
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
					  echo "Fail2ban 방어 프로그램이 제거되었습니다"
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
					  echo "Cloudflare 백엔드 오른쪽 상단의 내 프로필로 이동하여 왼쪽의 API 토큰을 선택하여 Global API Key를 얻으세요"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "Cloudflare 계정을 입력하세요:" cfuser
					  read -e -p "Cloudflare Global API 키를 입력하세요:" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /etc/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "Cloudflare 모드가 설정되었습니다. Cloudflare 백엔드의 사이트-보안-이벤트에서 가로채기 기록을 확인할 수 있습니다"
					  ;;

				  22)
					  send_stats "高负载开启5秒盾"
					  echo -e "${gl_huang}사이트는 5분마다 자동으로 검사하며, 높은 부하가 감지되면 자동으로 쉴드를 켜고, 낮은 부하에서는 자동으로 5초 동안 쉴드를 끕니다.${gl_bai}"
					  echo "--------------"
					  echo "Cloudflare 매개변수 가져오기:"
					  echo -e "Cloudflare 백엔드의 오른쪽 상단에 있는 내 프로필로 이동하여 왼쪽의 API 토큰을 선택하여 ${gl_huang}Global API Key${gl_bai}를 얻으십시오."
					  echo -e "Cloudflare 백엔드의 도메인 개요 페이지 오른쪽 하단에서 ${gl_huang}영역 ID${gl_bai}를 얻으십시오."
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "Cloudflare 계정을 입력하세요:" cfuser
					  read -e -p "Cloudflare Global API 키를 입력하세요:" cftoken
					  read -e -p "Cloudflare의 도메인 영역 ID를 입력하세요:" cfzonID

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
						  echo "고부하 자동 보호 스크립트가 추가되었습니다"
					  else
						  echo "자동 보호 스크립트가 이미 존재합니다. 추가할 필요가 없습니다"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "사이트 WAF가 활성화되었습니다"
					  send_stats "站点WAF已开启"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "사이트 WAF가 비활성화되었습니다"
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
			  echo -e "LDNMP 환경 최적화 ${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 표준 모드              2. 고성능 모드 (2H4G 이상 권장)"
			  echo "------------------------"
			  echo "3. gzip 압축 활성화        4. gzip 압축 비활성화"
			  echo "5. br 압축 활성화          6. br 압축 비활성화"
			  echo "7. zstd 압축 활성화        8. zstd 압축 비활성화"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아가기"
			  echo "------------------------"
			  read -e -p "선택을 입력하세요: " sub_choice
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


				  echo "LDNMP 환경이 표준 모드로 설정되었습니다."

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

				  echo "LDNMP 환경이 고성능 모드로 설정되었습니다."

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
echo "접속 주소:"
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


	echo "IP+포트가 이 서비스에 대한 접근을 차단했습니다."
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


	echo "IP+포트가 이 서비스에 대한 접근을 허용했습니다."
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "오류: 포트 번호와 접근을 허용할 IP를 입력해주세요."
		echo "사용법: block_host_port <포트 번호> <허용된 IP>"
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

	echo "IP+포트가 이 서비스에 대한 접근을 차단했습니다."
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "오류: 포트 번호와 접근을 허용할 IP를 입력해주세요."
		echo "사용법: clear_host_port_rules <포트 번호> <허용된 IP>"
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


	echo "IP+포트가 이 서비스에 대한 접근을 허용했습니다."
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
	echo "1. 설치                  2. 업데이트                  3. 제거"
	echo "------------------------"
	echo "5. 도메인 이름 접근 추가      6. 도메인 이름 접근 삭제"
	echo "7. IP+포트 접근 허용   8. IP+포트 접근 차단"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요: " choice
	 case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "애플리케이션 외부 서비스 포트를 입력하세요. Enter는 기본적으로 ${docker_port} 포트를 사용합니다:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_name이(가) 설치 완료되었습니다."
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
			echo "$docker_name이(가) 설치 완료되었습니다."
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
			echo "애플리케이션이 제거되었습니다."
			send_stats "卸载$docker_name"
			;;

		5)
			echo "${docker_name} 도메인 이름 접근 설정"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "도메인 이름 형식 example.com은 https://를 포함하지 않습니다."
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
		echo "1. 설치                  2. 업데이트                  3. 제거"
		echo "------------------------"
		echo "5. 도메인 이름 접근 추가      6. 도메인 이름 접근 삭제"
		echo "7. IP+포트 접근 허용   8. IP+포트 접근 차단"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요:" choice
		case $choice in
			1)
				setup_docker_dir
				check_disk_space $app_size /home/docker
				read -e -p "애플리케이션 외부 서비스 포트를 입력하세요. Enter는 기본적으로 ${docker_port} 포트를 사용합니다:" app_port
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
				echo "${docker_name} 도메인 이름 접근 설정"
				send_stats "${docker_name}域名访问设置"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "도메인 이름 형식 example.com은 https://를 포함하지 않습니다."
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

	read -e -p "$(echo -e "${gl_huang}프롬프트:${gl_bai}지금 서버를 재시작하시겠습니까? (y/N):")" rboot
	case "$rboot" in
	  [Yy])
		echo "재시작되었습니다."
		reboot
		;;
	  *)
		echo "취소되었습니다."
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
	echo -e "${gl_huang}프롬프트:${gl_bai}웹사이트 환경이 이미 설치되어 있습니다. 다시 설치할 필요가 없습니다!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "安装LDNMP环境"
root_use
clear
echo -e "${gl_huang}LDNMP 환경이 설치되지 않았습니다. LDNMP 환경 설치를 시작합니다...${gl_bai}"
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
echo -e "${gl_huang}Nginx가 설치되지 않았습니다. Nginx 환경 설치를 시작합니다...${gl_bai}"
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
echo "Nginx가 설치 완료되었습니다."
echo -e "현재 버전: ${gl_huang}v$nginx_version${gl_bai}"
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
	  echo "{$webname}이(가) 구축되었습니다!"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "{$webname} 설치 정보는 다음과 같습니다:"

}

nginx_web_on() {
	  clear
	  echo "{$webname}이(가) 구축되었습니다!"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "安装$webname"
  echo "{$webname} 배포 시작"
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
	webname="리버스 프록시-IP+포트"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "{$webname} 배포 시작"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "프록시 IP를 입력하세요:" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "프록시 포트를 입력하세요:" port
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
	webname="리버스 프록시-로드 밸런싱"

	send_stats "安装$webname"
	echo "{$webname} 배포 시작"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "프록시 IP+포트를 여러 개 입력하세요 (예: 127.0.0.1:3000 127.0.0.1:3002). 공백으로 구분하세요:" reverseproxy_port
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
		echo -e "Stream 4계층 프록시 전달 도구 $check_docker $update_status"
		echo "Nginx Stream은 Nginx의 TCP/UDP 프록시 모듈로, 고성능 전송 계층 트래픽 전달 및 로드 밸런싱을 구현하는 데 사용됩니다."
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. 설치                  2. 업데이트                  3. 제거"
		echo "------------------------"
		echo "4. 포워딩 서비스 추가          5. 포워딩 서비스 수정          6. 포워딩 서비스 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요:" choice
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
				read -e -p "Nginx 컨테이너를 삭제하시겠습니까? 웹사이트 기능에 영향을 줄 수 있습니다!\(y/N\):" confirm
				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					docker rm -f nginx
					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					send_stats "更新Stream四层代理"
					echo "Nginx 컨테이너가 삭제되었습니다."
				else
					echo "작업이 취소되었습니다."
				fi

				;;

			4)
				ldnmp_Proxy_backend_stream
				add_app_id
				send_stats "添加四层代理"
				;;
			5)
				send_stats "编辑转发配置"
				read -e -p "편집할 서비스 이름을 입력하세요:" stream_name
				install nano
				nano /home/web/stream.d/$stream_name.conf
				docker restart nginx
				send_stats "修改四层代理"
				;;
			6)
				send_stats "删除转发配置"
				read -e -p "삭제할 서비스 이름을 입력하세요:" stream_name
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
	webname="Stream 4계층 프록시-로드 밸런싱"

	send_stats "安装$webname"
	echo "{$webname} 배포 시작"

	# 获取代理名称
	read -rp "프록시 전달 이름을 입력하세요 (예: mysql_proxy):" proxy_name
	if [ -z "$proxy_name" ]; then
		echo "이름은 비워둘 수 없습니다."; return 1
	fi

	# 获取监听端口
	read -rp "로컬 리스닝 포트를 입력하세요 (예: 3306):" listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "포트 번호는 숫자여야 합니다."; return 1
	fi

	echo "프로토콜 유형을 선택하세요:"
	echo "1. TCP    2. UDP"
	read -rp "일련 번호 [1-2]를 입력하세요:" proto_choice

	case "$proto_choice" in
		1) proto="tcp"; listen_suffix="" ;;
		2) proto="udp"; listen_suffix=" udp" ;;
		*) echo "잘못된 선택"; return 1 ;;
	esac

	read -e -p "백엔드 IP+포트를 하나 이상 입력하세요 (예: 10.13.0.2:3306 10.13.0.3:3306). 공백으로 구분하세요:" reverseproxy_port

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
	echo "{$webname}이(가) 구축되었습니다!"
	echo "------------------------"
	echo "접속 주소:"
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
		echo "LDNMP 환경"
		echo "------------------------"
		ldnmp_v

		echo -e "사이트: ${output}                      인증서 만료 시간"
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
		echo -e "데이터베이스: ${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "사이트 디렉토리"
		echo "------------------------"
		echo -e "데이터 ${gl_hui}/home/web/html${gl_bai}     인증서 ${gl_hui}/home/web/certs${gl_bai}     구성 ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "작업"
		echo "------------------------"
		echo "1. 도메인 인증서 신청/갱신              2. 사이트 도메인 복사"
		echo "3. 사이트 캐시 정리                   4. 연결된 사이트 생성"
		echo "5. 액세스 기록 보기                   6. 오류 로그 보기"
		echo "7. 전역 설정 편집                   8. 사이트 설정 편집"
		echo "9. 사이트 데이터베이스 관리                 10. 사이트 분석 보고서 보기"
		echo "------------------------"
		echo "20. 지정된 사이트 데이터 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요: " sub_choice
		case $sub_choice in
			1)
				send_stats "申请域名证书"
				read -e -p "도메인을 입력하세요:" yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "克隆站点域名"
				read -e -p "이전 도메인을 입력하세요:" oddyuming
				read -e -p "새 도메인을 입력하세요:" yuming
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
				echo -e "기존 사이트에 새 도메인을 다시 연결하여 액세스"
				read -e -p "기존 도메인을 입력하세요:" oddyuming
				read -e -p "새 도메인을 입력하세요:" yuming
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
				read -e -p "사이트 구성을 편집하려면 편집할 도메인을 입력하세요:" yuming
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
	echo "${panelname}은 현재 유행하고 강력한 유지보수 관리 패널입니다."
	echo "공식 웹사이트 소개: $panelurl"

	echo ""
	echo "------------------------"
	echo "1. 설치            2. 관리            3. 제거"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요: " choice
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
	echo "클라이언트 배포 시 필요한 매개변수"
	echo "서비스 IP: $ipv4_address"
	echo "token: $token"
	echo
	echo "FRP 패널 정보"
	echo "FRP 패널 주소: http://$ipv4_address:$dashboard_port"
	echo "FRP 패널 사용자 이름: $dashboard_user"
	echo "FRP 패널 비밀번호: $dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "安装frp客户端"
	read -e -p "외부 네트워크 연결 IP를 입력하세요:" server_addr
	read -e -p "외부 네트워크 연결 토큰을 입력하세요:" token
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
	read -e -p "서비스 이름을 입력하세요:" service_name
	read -e -p "전달 유형 (tcp/udp) [기본값 tcp]을 입력하세요:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "내부 네트워크 IP를 입력하세요 [기본값 127.0.0.1]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "내부 네트워크 포트 번호를 입력하세요:" local_port
	read -e -p "외부 네트워크 포트 번호를 입력하세요:" remote_port

	# 将用户输入写入配置文件
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 输出生成的信息
	echo "서비스 $service_name이 frpc.toml에 성공적으로 추가되었습니다."

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	read -e -p "삭제할 서비스 이름을 입력하세요:" service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "서비스 $service_name이 frpc.toml에서 성공적으로 삭제되었습니다."

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
		echo "FRP 서비스 외부 액세스 주소:"

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
		echo -e "FRP 서버 $check_frp $update_status"
		echo "FRP 내부 네트워크 관통 서비스 환경을 구축하여 공용 IP가 없는 장치를 인터넷에 노출합니다."
		echo "공식 웹사이트 소개: https://github.com/fatedier/frp/"
		echo "비디오 튜토리얼: https://youtu.be/Z3Z4OoaV2cw?t=124"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. 설치                  2. 업데이트                  3. 제거"
		echo "------------------------"
		echo "5. 내부 서비스 도메인 액세스      6. 도메인 액세스 삭제"
		echo "------------------------"
		echo "7. IP+포트 액세스 허용     8. IP+포트 액세스 차단"
		echo "------------------------"
		echo "00. 서비스 상태 새로 고침         0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config

				add_app_id
				echo "FRP 서버가 설치되었습니다."
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps

				add_app_id
				echo "FRP 서버가 업데이트되었습니다."
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "애플리케이션이 제거되었습니다."
				;;
			5)
				echo "내부 네트워크 침투 서비스를 도메인 액세스로 리버스 프록시합니다."
				send_stats "FRP对外域名访问"
				add_yuming
				read -e -p "내부 네트워크 터널링 서비스 포트 번호를 입력하세요:" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "도메인 이름 형식 example.com은 https://를 포함하지 않습니다."
				web_del
				;;

			7)
				send_stats "允许IP访问"
				read -e -p "허용할 포트 번호를 입력하세요:" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "阻止IP访问"
				echo "이미 도메인 액세스를 리버스 프록시한 경우 이 기능을 사용하여 IP+포트 액세스를 차단하여 더욱 안전하게 만들 수 있습니다."
				read -e -p "차단할 포트 번호를 입력하세요:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "刷新FRP服务状态"
				echo "FRP 서비스 상태가 새로 고침되었습니다."
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
		echo -e "FRP 클라이언트 $check_frp $update_status"
		echo "서버와 연결하여 인터넷 액세스를 위한 내부 네트워크 침투 서비스를 생성할 수 있습니다."
		echo "공식 웹사이트 소개: https://github.com/fatedier/frp/"
		echo "비디오 튜토리얼: https://youtu.be/Z3Z4OoaV2cw?t=174"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. 설치                  2. 업데이트                  3. 제거"
		echo "------------------------"
		echo "4. 외부 서비스 추가          5. 외부 서비스 삭제          6. 서비스 수동 구성"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc

				add_app_id
				echo "FRP 클라이언트가 설치되었습니다."
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc

				add_app_id
				echo "FRP 클라이언트가 업데이트되었습니다."
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "애플리케이션이 제거되었습니다."
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
		echo -e "yt-dlp는 YouTube, BiliBili, X(구 Twitter) 등 수천 개의 사이트를 지원하는 강력한 비디오 다운로드 도구입니다."
		echo -e "공식 웹사이트 주소: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "다운로드된 비디오 목록:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(없음)"
		echo "-------------------------"
		echo "1. 설치                  2. 업데이트                  3. 제거"
		echo "-------------------------"
		echo "5. 단일 비디오 다운로드          6. 비디오 일괄 다운로드          7. 사용자 지정 매개변수 다운로드"
		echo "8. MP3 오디오로 다운로드       9. 비디오 디렉토리 삭제          10. 쿠키 관리(개발 중)"
		echo "-------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "-------------------------"
		read -e -p "옵션 번호를 입력하세요:" choice

		case $choice in
			1)
				send_stats "正在安装 yt-dlp..."
				echo "yt-dlp를 설치 중..."
				install ffmpeg
				curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				chmod a+rx /usr/local/bin/yt-dlp

				add_app_id
				echo "설치 완료. 아무 키나 눌러 계속..."
				read ;;
			2)
				send_stats "正在更新 yt-dlp..."
				echo "yt-dlp를 업데이트 중..."
				yt-dlp -U

				add_app_id
				echo "업데이트 완료. 아무 키나 눌러 계속..."
				read ;;
			3)
				send_stats "正在卸载 yt-dlp..."
				echo "yt-dlp를 제거 중..."
				rm -f /usr/local/bin/yt-dlp

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "제거 완료. 아무 키나 눌러 계속..."
				read ;;
			5)
				send_stats "单个视频下载"
				read -e -p "비디오 링크를 입력하세요:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "다운로드 완료, 아무 키나 눌러 계속..." ;;
			6)
				send_stats "批量视频下载"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# 여러 비디오 링크 주소를 입력하세요\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "이제 일괄 다운로크를 시작합니다..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "일괄 다운로드 완료, 아무 키나 눌러 계속..." ;;
			7)
				send_stats "自定义视频下载"
				read -e -p "전체 yt-dlp 매개변수를 입력하세요 (yt-dlp 제외):" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "실행 완료, 아무 키나 눌러 계속..." ;;
			8)
				send_stats "MP3下载"
				read -e -p "비디오 링크를 입력하세요:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "오디오 다운로드 완료, 아무 키나 눌러 계속..." ;;

			9)
				send_stats "删除视频"
				read -e -p "삭제할 비디오 이름을 입력하세요:" rmdir
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
	echo -e "${gl_huang}시스템 업데이트 중...${gl_bai}"
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
		echo "알 수 없는 패키지 관리자!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}시스템 정리 중...${gl_bai}"
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
		echo "패키지 관리자 캐시 정리..."
		apk cache clean
		echo "시스템 로그 삭제..."
		rm -rf /var/log/*
		echo "APK 캐시 삭제..."
		rm -rf /var/cache/apk/*
		echo "임시 파일 삭제..."
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
		echo "시스템 로그 삭제..."
		rm -rf /var/log/*
		echo "임시 파일 삭제..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "사용하지 않는 종속성 정리..."
		pkg autoremove -y
		echo "패키지 관리자 캐시 정리..."
		pkg clean -y
		echo "시스템 로그 삭제..."
		rm -rf /var/log/*
		echo "임시 파일 삭제..."
		rm -rf /tmp/*

	else
		echo "알 수 없는 패키지 관리자!"
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
	echo "DNS 주소 최적화"
	echo "------------------------"
	echo "현재 DNS 주소"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 중국 외 지역 DNS 최적화:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 중국 지역 DNS 최적화:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. DNS 구성 수동 편집"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요: " Limiting
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

  echo "SSH 포트가 $new_port(으)로 변경되었습니다."

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
	echo -e "개인 키 정보가 생성되었습니다. 반드시 복사하여 저장하고, ${gl_huang}${ipv4_address}_ssh.key${gl_bai} 파일로 저장하여 향후 SSH 로그인에 사용할 수 있습니다."

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}root 개인 키 로그인이 활성화되었고, root 비밀번호 로그인이 비활성화되었습니다. 다시 연결하면 적용됩니다${gl_bai}"

}


import_sshkey() {

	read -e -p "SSH 공개 키 내용을 입력하세요 (일반적으로 'ssh-rsa' 또는 'ssh-ed25519'로 시작):" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}오류: 공개 키 내용이 입력되지 않았습니다.${gl_bai}"
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
	echo -e "${gl_lv}공개 키가 성공적으로 가져와졌고, root 개인 키 로그인이 활성화되었으며, root 비밀번호 로그인이 비활성화되었습니다. 다시 연결하면 적용됩니다${gl_bai}"

}




add_sshpasswd() {

echo "루트 비밀번호 설정"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}root 로그인 설정 완료!${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}팁:${gl_bai} 이 기능은 root 사용자로 실행해야 합니다!" && break_end && kejilion
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
		  echo -e "재설치 후 초기 사용자 이름: ${gl_huang}root${gl_bai}  초기 비밀번호: ${gl_huang}LeitboGi0ro${gl_bai}  초기 포트: ${gl_huang}22${gl_bai}"
		  echo -e "아무 키나 눌러 계속..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "재설치 후 초기 사용자 이름: ${gl_huang}Administrator${gl_bai}  초기 비밀번호: ${gl_huang}Teddysun.com${gl_bai}  초기 포트: ${gl_huang}3389${gl_bai}"
		  echo -e "아무 키나 눌러 계속..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "재설치 후 초기 사용자 이름: ${gl_huang}root${gl_bai} 초기 비밀번호: ${gl_huang}123@@@${gl_bai} 초기 포트: ${gl_huang}22${gl_bai}"
		  echo -e "아무 키나 눌러 계속..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "재설치 후 초기 사용자 이름: ${gl_huang}Administrator${gl_bai} 초기 비밀번호: ${gl_huang}123@@@${gl_bai} 초기 포트: ${gl_huang}3389${gl_bai}"
		  echo -e "아무 키나 눌러 계속..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "시스템 재설치"
			echo "--------------------------------"
			echo -e "${gl_hong}주의:${gl_bai} 재설치는 위험하며 연결이 끊어질 수 있습니다. 신중하게 사용하십시오. 재설치에는 약 15분이 소요됩니다. 미리 데이터를 백업하십시오."
			echo -e "${gl_hui}leitbogioro님과 bin456789님께 스크립트 지원에 감사드립니다!${gl_bai}"
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
			echo "35. openSUSE Tumbleweed       36. fnos 공개 베타 버전"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2025"
			echo "45. Windows Server 2022       46. Windows Server 2019"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 이전 메뉴로 돌아가기"
			echo "------------------------"
			read -e -p "재설치할 시스템을 선택하세요:" sys_choice
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
				  echo "XanMod의 BBRv3 커널이 설치되었습니다."
				  echo "현재 커널 버전: $kernel_version"

				  echo ""
				  echo "커널 관리"
				  echo "------------------------"
				  echo "1. BBRv3 커널 업데이트              2. BBRv3 커널 제거"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " sub_choice

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

						echo "XanMod 커널이 업데이트되었습니다. 재부팅 후 적용됩니다."
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "XanMod 커널이 제거되었습니다. 재부팅 후 적용됩니다."
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "BBRv3 가속 설정"
		  echo "비디오 소개: https://youtu.be/ua2_hmCRL4E"
		  echo "------------------------------------------------"
		  echo "Debian/Ubuntu만 지원"
		  echo "데이터를 백업하세요. BBRv3를 활성화하기 위해 Linux 커널을 업그레이드합니다."
		  echo "------------------------------------------------"
		  read -e -p "계속하시겠습니까? \(y/N\):" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "현재 환경에서 지원되지 않습니다. Debian 및 Ubuntu 시스템만 지원합니다."
					break_end
					linux_Settings
				fi
			else
				echo "운영체제 유형을 확인할 수 없습니다."
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

			echo "XanMod 커널 설치 및 BBRv3 활성화 성공. 재시작 후 적용됩니다."
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "취소되었습니다."
			  ;;
			*)
			  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
			  ;;
		  esac
		fi

}


elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "ELRepo GPG 공개 키 가져오는 중..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "지원되지 않는 운영체제: $os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "감지된 운영체제: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ "$os_version" == 8 ]]; then
		echo "ELRepo 저장소 구성 설치 (버전 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "ELRepo 저장소 구성 설치 (버전 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "ELRepo 저장소 구성 설치 (버전 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "지원되지 않는 시스템 버전: $os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "ELRepo 커널 저장소를 활성화하고 최신 메인라인 커널을 설치합니다..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "ELRepo 소프트웨어 소스 구성이 설치되었고 최신 메인라인 커널로 업데이트되었습니다."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "红帽内核管理"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "ELRepo 커널이 설치되었습니다."
				  echo "현재 커널 버전: $kernel_version"

				  echo ""
				  echo "커널 관리"
				  echo "------------------------"
				  echo "1. ELRepo 커널 업데이트              2. ELRepo 커널 제거"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " sub_choice

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
						echo "ELRepo 커널이 제거되었습니다. 재시작 후 적용됩니다."
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
		  echo "데이터를 백업하세요. Linux 커널을 업그레이드합니다."
		  echo "동영상 소개: https://youtu.be/wamvDukHzUg?t=529"
		  echo "------------------------------------------------"
		  echo "Red Hat 계열 배포판 CentOS/RedHat/Alma/Rocky/oracle만 지원합니다."
		  echo "Linux 커널 업그레이드는 시스템 성능과 보안을 향상시킬 수 있습니다. 가능하면 시도해 보시고, 프로덕션 환경에서는 신중하게 업그레이드하십시오!"
		  echo "------------------------------------------------"
		  read -e -p "계속하시겠습니까? \(y/N\):" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "升级红帽内核"
			  server_reboot
			  ;;
			[Nn])
			  echo "취소되었습니다."
			  ;;
			*)
			  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}바이러스 데이터베이스 업데이트 중...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "스캔할 디렉토리를 지정하십시오."
		return
	fi

	echo -e "${gl_huang}디렉토리 $ @ 스캔 중 ...${gl_bai}"

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

	echo -e "${gl_lv}$ @ 스캔 완료, 바이러스 보고서는 ${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}에 저장됩니다."
	echo -e "${gl_lv}바이러스가 있는 경우 ${gl_huang}scan.log${gl_lv} 파일에서 FOUND 키워드를 검색하여 바이러스 위치를 확인하십시오.${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "病毒扫描管理"
		  while true; do
				clear
				echo "clamav 바이러스 스캔 도구"
				echo "동영상 소개: https://youtu.be/UQglgnv-aLU"
				echo "------------------------"
				echo "오픈 소스 안티바이러스 도구로, 다양한 유형의 악성 소프트웨어를 탐지하고 제거하는 데 주로 사용됩니다."
				echo "바이러스, 트로이 목마, 스파이웨어, 악성 스크립트 및 기타 유해 소프트웨어가 포함됩니다."
				echo "------------------------"
				echo -e "${gl_lv}1. 전체 디스크 스캔${gl_bai}             ${gl_huang}2. 중요 디렉토리 스캔${gl_bai}            ${gl_kjlan} 3. 사용자 지정 디렉토리 스캔${gl_bai}"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아가기"
				echo "------------------------"
				read -e -p "선택을 입력하세요: " sub_choice
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
					  read -e -p "스캔할 디렉토리를 공백으로 구분하여 입력하세요 (예: /etc /var /usr /home /root):" directories
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
	echo -e "${gl_lv}로 전환 중${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화 중...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}가상 메모리 최적화 중...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화 중...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화 중...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화 중...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}기타 최적화...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv}균형 모드로 전환 중...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화 중...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}가상 메모리 최적화 중...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화 중...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화 중...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화 중...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}기타 최적화...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}기본 설정으로 복원 중...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 복원 중...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}가상 메모리 복원 중...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 복원...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 복원...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}CPU 설정 복원...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}다른 최적화 복원...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}웹사이트 빌드 최적화 모드로 전환...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화 중...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}가상 메모리 최적화 중...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화 중...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화 중...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화 중...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}기타 최적화...${gl_bai}"
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
	  echo "Linux 시스템 커널 파라미터 최적화"
	  echo "동영상 소개: https://youtu.be/TCsd0pepBac"
	  echo "------------------------------------------------"
	  echo "다양한 시스템 파라미터 튜닝 모드를 제공하며, 사용자는 자신의 사용 시나리오에 따라 선택하여 전환할 수 있습니다."
	  echo -e "${gl_huang}주의:${gl_bai} 프로덕션 환경에서는 신중하게 사용하세요!"
	  echo "--------------------"
	  echo "1. 고성능 최적화 모드:     시스템 성능을 최대화하고 파일 설명자, 가상 메모리, 네트워크 설정, 캐시 관리 및 CPU 설정을 최적화합니다."
	  echo "2. 균형 최적화 모드:       성능과 리소스 소비 간의 균형을 유지하며 일상적인 사용에 적합합니다."
	  echo "3. 웹사이트 최적화 모드:       웹 서버를 위해 최적화되어 동시 연결 처리 능력, 응답 속도 및 전반적인 성능을 향상시킵니다."
	  echo "4. 라이브 스트리밍 최적화 모드:       라이브 스트리밍의 특정 요구 사항을 위해 최적화되어 지연 시간을 줄이고 전송 성능을 향상시킵니다."
	  echo "5. 게임 서버 최적화 모드:     게임 서버를 위해 최적화되어 동시 처리 능력과 응답 속도를 향상시킵니다."
	  echo "6. 기본 설정 복원:           시스템 설정을 기본 구성으로 복원합니다."
	  echo "--------------------"
	  echo "0. 이전 메뉴로 돌아가기"
	  echo "--------------------"
	  read -e -p "선택을 입력하세요: " sub_choice
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
				echo -e "${gl_lv}시스템 언어가 $lang로 변경되었습니다. SSH를 다시 연결하면 적용됩니다.${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}시스템 언어가 $lang로 변경되었습니다. SSH를 다시 연결하면 적용됩니다.${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "지원되지 않는 시스템: $ID"
				break_end
				;;
		esac
	else
		echo "지원되지 않는 시스템, 시스템 유형을 식별할 수 없습니다."
		break_end
	fi
}




linux_language() {
root_use
send_stats "切换系统语言"
while true; do
  clear
  echo "현재 시스템 언어: $LANG"
  echo "------------------------"
  echo "1. 영어 2. 중국어 간체 3. 중국어 번체"
  echo "------------------------"
  echo "0. 이전 메뉴로 돌아가기"
  echo "------------------------"
  read -e -p "선택을 입력하세요:" choice

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
echo -e "${gl_lv}변경 사항이 완료되었습니다. SSH를 다시 연결하면 변경 사항을 확인할 수 있습니다!${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "命令行美化工具"
  while true; do
	clear
	echo "명령줄 미화 도구"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요:" choice

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
	echo -e "현재 휴지통 ${trash_status}"
	echo -e "활성화되면 rm으로 삭제된 파일은 먼저 휴지통으로 이동하여 중요한 파일의 실수 삭제를 방지합니다!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "휴지통이 비어 있습니다."
	echo "------------------------"
	echo "1. 휴지통 활성화          2. 휴지통 비활성화"
	echo "3. 내용 복원            4. 휴지통 비우기"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요:" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "휴지통이 활성화되었습니다. 삭제된 파일은 휴지통으로 이동됩니다."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "휴지통이 비활성화되었습니다. 파일은 직접 삭제됩니다."
		sleep 2
		;;
	  3)
		read -e -p "복원할 파일 이름을 입력하세요:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restore이(가) 기본 디렉터리로 복원되었습니다."
		else
		  echo "파일이 존재하지 않습니다."
		fi
		;;
	  4)
		read -e -p "휴지통 비우시겠습니까? (y/N):" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "휴지통이 비워졌습니다."
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
	echo "백업 예제 만들기:"
	echo "- 단일 디렉터리 백업: /var/www"
	echo "- 여러 디렉터리 백업: /etc /home /var/log"
	echo "- 그냥 Enter를 누르면 기본 디렉터리(/etc /usr /home)를 사용합니다."
	read -r -p "백업할 디렉토리를 입력하세요 (여러 디렉토리는 공백으로 구분하고, 기본 디렉토리를 사용하려면 Enter 키를 누르세요):" input

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
	echo "선택한 백업 디렉터리는 다음과 같습니다:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "백업 $BACKUP_NAME 생성 중..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "백업 생성 성공: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "백업 생성 실패!"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	read -e -p "복원할 백업 파일 이름을 입력하세요:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "백업 파일이 존재하지 않습니다!"
		exit 1
	fi

	echo "백업 $BACKUP_NAME 복원 중..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "백업 및 복원 성공!"
	else
		echo "백업 및 복원 실패!"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "사용 가능한 백업:"
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	read -e -p "삭제할 백업 파일 이름을 입력하세요:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "백업 파일이 존재하지 않습니다!"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "백업 삭제 성공!"
	else
		echo "백업 삭제 실패!"
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
		echo "시스템 백업 기능"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. 백업 생성        2. 백업 복원        3. 백업 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요: " choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "Enter 키를 눌러 계속..."
	done
}









# 显示连接列表
list_connections() {
	echo "저장된 연결:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "새 연결 예시:"
	echo "  - 연결 이름: my_server"
	echo "  - IP 주소: 192.168.1.100"
	echo "  - 사용자 이름: root"
	echo "  - 포트: 22"
	echo "------------------------"
	read -e -p "연결 이름을 입력하세요:" name
	read -e -p "IP 주소를 입력하세요:" ip
	read -e -p "사용자 이름(기본값 root)을 입력하세요:" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "포트 번호(기본값 22)를 입력하세요:" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "인증 방법을 선택하세요:"
	echo "1. 비밀번호"
	echo "2. 키"
	read -e -p "선택을 입력하세요 (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "请输入密码: " password_or_key
			echo  # 换行
			;;
		2)
			echo "키 내용을 붙여넣으세요 (붙여넣은 후 Enter 키를 두 번 누르세요):"
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
			echo "잘못된 선택입니다!"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "연결이 저장되었습니다!"
}



# 删除连接
delete_connection() {
	send_stats "删除连接"
	read -e -p "삭제할 연결 번호를 입력하세요:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "오류: 해당 연결을 찾을 수 없습니다."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "연결이 삭제되었습니다!"
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	read -e -p "사용할 연결 번호를 입력하세요:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "오류: 해당 연결을 찾을 수 없습니다."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "$name ($ip)에 연결 중..."
	if [[ -f "$password_or_key" ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "연결 실패! 다음 내용을 확인하세요:"
			echo "1. 키 파일 경로가 올바른지 확인하세요: $password_or_key"
			echo "2. 키 파일 권한이 올바른지 확인하세요 (600이어야 합니다)."
			echo "3. 대상 서버가 키를 사용하여 로그인을 허용하는지 확인하세요."
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &> /dev/null; then
			echo "오류: sshpass가 설치되지 않았습니다. 먼저 sshpass를 설치하세요."
			echo "설치 방법:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "연결 실패! 다음 내용을 확인하세요:"
			echo "1. 사용자 이름과 암호가 올바른지 확인하세요."
			echo "2. 대상 서버가 암호 로그인을 허용하는지 확인하세요."
			echo "3. 대상 서버의 SSH 서비스가 정상적으로 실행 중인지 확인하세요."
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
		echo "SSH 원격 연결 도구"
		echo "SSH를 통해 다른 Linux 시스템에 연결할 수 있습니다."
		echo "------------------------"
		list_connections
		echo "1. 새 연결 생성        2. 연결 사용        3. 연결 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요: " choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "잘못된 선택입니다. 다시 시도하세요." ;;
		esac
	done
}












# 列出可用的硬盘分区
list_partitions() {
	echo "사용 가능한 하드 디스크 파티션:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	read -e -p "마운트할 파티션 이름을 입력하세요 (예: sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 이미 마운트되었습니다!"
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "파티션 마운트 성공: $MOUNT_POINT"
	else
		echo "파티션 마운트 실패!"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	read -e -p "제거할 파티션 이름을 입력하세요 (예: sda1):" PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "파티션이 마운트되지 않았습니다!"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "파티션 언마운트 성공: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "파티션 언마운트 실패!"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "마운트된 파티션:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	read -e -p "포맷할 파티션 이름을 입력하세요 (예: sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 이미 마운트되어 있습니다. 먼저 언마운트하세요!"
		return
	fi

	# 选择文件系统类型
	echo "파일 시스템 유형을 선택하세요:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "선택을 입력하세요: " FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "잘못된 선택입니다!"; return ;;
	esac

	# 确认格式化
	read -e -p "/dev/$PARTITION 파티션을 $FS_TYPE으로 포맷하시겠습니까? (y/N):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "작업이 취소되었습니다."
		return
	fi

	# 格式化分区
	echo "파티션 /dev/$PARTITION을 $FS_TYPE으로 포맷하는 중..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "파티션 포맷 성공!"
	else
		echo "파티션 포맷 실패!"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	read -e -p "검사할 파티션 이름을 입력하세요 (예: sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 检查分区状态
	echo "파티션 /dev/$PARTITION의 상태 확인:"
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "하드 디스크 파티션 관리"
		echo -e "${gl_huang}이 기능은 내부 테스트 단계에 있으며 프로덕션 환경에서는 사용하지 마십시오.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. 파티션 마운트        2. 파티션 언마운트        3. 마운트된 파티션 보기"
		echo "4. 파티션 포맷      5. 파티션 상태 확인"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요: " choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "Enter 키를 눌러 계속..."
	done
}




# 显示任务列表
list_tasks() {
	echo "저장된 동기화 작업:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
	echo "새 동기화 작업 예시:"
	echo "  - 작업 이름: backup_www"
	echo "  - 로컬 디렉토리: /var/www"
	echo "  - 원격 주소: user@192.168.1.100"
	echo "  - 원격 디렉토리: /backup/www"
	echo "  - 포트 번호 (기본값 22)"
	echo "---------------------------------"
	read -e -p "작업 이름을 입력하세요:" name
	read -e -p "로컬 디렉토리를 입력하세요:" local_path
	read -e -p "원격 디렉토리를 입력하세요:" remote_path
	read -e -p "원격 사용자@IP를 입력하세요:" remote
	read -e -p "SSH 포트를 입력하세요 (기본값 22):" port
	port=${port:-22}

	echo "인증 방법을 선택하세요:"
	echo "1. 비밀번호"
	echo "2. 키"
	read -e -p "선택하세요 (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "请输入密码: " password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "키 내용을 붙여넣으세요 (붙여넣은 후 Enter 키를 두 번 누르세요):"
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
				echo "잘못된 키 내용입니다!"
				return
			fi
			;;
		*)
			echo "잘못된 선택입니다!"
			return
			;;
	esac

	echo "동기화 모드를 선택하세요:"
	echo "1. 표준 모드 (-avz)"
	echo "2. 대상 파일 삭제 (-avz --delete)"
	read -e -p "선택하세요 (1/2):" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "잘못된 선택입니다. 기본값 -avz를 사용합니다."; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "작업이 저장되었습니다!"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	read -e -p "삭제할 작업 번호를 입력하세요:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "오류: 해당 작업을 찾을 수 없습니다."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "작업이 삭제되었습니다!"
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
		read -e -p "실행할 작업 번호를 입력하세요:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "오류: 해당 작업을 찾을 수 없습니다!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 根据同步方向调整源和目标路径
	if [[ "$direction" == "pull" ]]; then
		echo "로컬로 동기화를 가져오는 중: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "원격으로 동기화를 푸시하는 중: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "오류: sshpass가 설치되지 않았습니다. 먼저 sshpass를 설치하세요."
			echo "설치 방법:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f "$password_or_key" ]]; then
			echo "오류: 키 파일이 존재하지 않습니다: $password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "경고: 키 파일 권한이 올바르지 않습니다. 수정 중..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "동기화가 완료되었습니다!"
	else
		echo "동기화 실패! 다음을 확인하세요:"
		echo "1. 네트워크 연결 상태"
		echo "2. 원격 호스트 접근 가능 여부"
		echo "3. 인증 정보의 정확성"
		echo "4. 로컬 및 원격 디렉터리에 대한 올바른 접근 권한"
	fi
}


# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	read -e -p "정기적으로 동기화할 작업 번호를 입력하세요:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "오류: 유효한 작업 번호를 입력하세요!"
		return
	fi

	echo "타이밍 실행 간격을 선택하세요:"
	echo "1. 매시간 실행"
	echo "2. 매일 실행"
	echo "3. 매주 실행"
	read -e -p "옵션을 입력하세요 (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "오류: 유효한 옵션을 입력하세요!" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "오류: 해당 작업에 대한 예약 동기화가 이미 존재합니다!"
		return
	fi

	# 创建到用户的 crontab
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "타이밍 작업이 생성되었습니다: $cron_job"
}

# 查看定时任务
view_tasks() {
	echo "현재 타이밍 작업:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	read -e -p "삭제할 작업 번호를 입력하세요:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "오류: 유효한 작업 번호를 입력하세요!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "작업 번호 $num의 타이밍 작업이 삭제되었습니다."
}


# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync 원격 동기화 도구"
		echo "원격 디렉터리 간 동기화, 증분 동기화 지원, 효율적이고 안정적입니다."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 새 작업 생성           2. 작업 삭제"
		echo "3. 로컬 동기화를 원격으로 실행   4. 원격 동기화를 로컬로 실행"
		echo "5. 타이밍 작업 생성         6. 타이밍 작업 삭제"
		echo "---------------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "---------------------------------"
		read -e -p "선택을 입력하세요: " choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "잘못된 선택입니다. 다시 시도하세요." ;;
		esac
		read -e -p "Enter 키를 눌러 계속..."
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
	echo -e "시스템 정보 조회"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}호스트 이름:           ${gl_bai}$hostname"
	echo -e "${gl_kjlan}시스템 버전:           ${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linux 버전:            ${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU 아키텍처:          ${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPU 모델:              ${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPU 코어 수:           ${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU 주파수:            ${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU 사용률:            ${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}시스템 부하:           ${gl_bai}$load"
	echo -e "${gl_kjlan}물리적 메모리:         ${gl_bai}$mem_info"
	echo -e "${gl_kjlan}가상 메모리:           ${gl_bai}$swap_info"
	echo -e "${gl_kjlan}하드 디스크 사용량:    ${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}총 수신:               ${gl_bai}$rx"
	echo -e "${gl_kjlan}총 전송:               ${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}네트워크 알고리즘:     ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}통신사:                ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4 주소:             ${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6 주소:             ${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS 주소:              ${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}지리적 위치:           ${gl_bai}$country $city"
	echo -e "${gl_kjlan}시스템 시간:           ${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}실행 시간:             ${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "基础工具"
	  echo -e "기본 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}curl 다운로드 도구 ${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget 다운로드 도구 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo 슈퍼 관리자 권한 도구             ${gl_kjlan}4.   ${gl_bai}socat 통신 연결 도구"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop 시스템 모니터링 도구              ${gl_kjlan}6.   ${gl_bai}iftop 네트워크 트래픽 모니터링 도구"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP 압축 해제 도구               ${gl_kjlan}8.   ${gl_bai}tar GZ 압축 해제 도구"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux 다중 경로 백그라운드 실행 도구    ${gl_kjlan}10.  ${gl_bai}ffmpeg 비디오/오디오 인코딩 라이브 스트리밍 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop 현대적인 모니터링 도구 ${gl_huang}★${gl_bai}          ${gl_kjlan}12.  ${gl_bai}ranger 파일 관리 도구"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu 디스크 사용량 보기 도구           ${gl_kjlan}14.  ${gl_bai}fzf 전역 검색 도구"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim 텍스트 편집기                      ${gl_kjlan}16.  ${gl_bai}nano 텍스트 편집기 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}git 버전 관리 시스템"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}해커 매트릭스 스크린 세이버            ${gl_kjlan}22.  ${gl_bai}뱀 스크린 세이버"
	  echo -e "${gl_kjlan}26.  ${gl_bai}테트리스 게임                          ${gl_kjlan}27.  ${gl_bai}뱀 게임"
	  echo -e "${gl_kjlan}28.  ${gl_bai}스페이스 인베이더 게임"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}모두 설치                              ${gl_kjlan}32.  ${gl_bai}모두 설치 (스크린 세이버 및 게임 제외)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}모두 제거"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}지정된 도구 설치                       ${gl_kjlan}42.  ${gl_bai}지정된 도구 제거"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
			  curl --help
			  send_stats "安装curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
			  wget --help
			  send_stats "安装wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
			  sudo --help
			  send_stats "安装sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
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
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
			  unzip
			  send_stats "安装unzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
			  tar --help
			  send_stats "安装tar"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
			  tmux --help
			  send_stats "安装tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "도구가 설치되었습니다. 사용 방법은 다음과 같습니다:"
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
			  read -e -p "설치할 도구 이름을 입력하세요 (wget curl sudo htop):" installname
			  install $installname
			  send_stats "安装指定软件"
			  ;;
		  42)
			  clear
			  read -e -p "제거할 도구 이름을 입력하세요 (htop ufw tmux cmatrix):" removename
			  remove $removename
			  send_stats "卸载指定软件"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "잘못된 입력!"
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
			  echo "현재 TCP 혼잡 제어 알고리즘: $congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR 관리"
			  echo "------------------------"
			  echo "1. BBRv3 활성화        2. BBRv3 비활성화 (재시작됨)"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아가기"
			  echo "------------------------"
			  read -e -p "선택을 입력하세요: " sub_choice

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
		echo -e "${BLUE}현재 백업 목록:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "백업 없음"
	}



	# ----------------------------
	# 备份
	# ----------------------------
	backup_docker() {
		send_stats "Docker备份"

		echo -e "${YELLOW}Docker 컨테이너 백업 중...${NC}"
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
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && { echo -e "${RED}컨테이너를 찾을 수 없음${NC}"; return; }

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" > "$RESTORE_SCRIPT"
		echo "set -e" >> "$RESTORE_SCRIPT"
		echo "# 자동으로 생성된 복원 스크립트" >> "$RESTORE_SCRIPT"

		# 记录已打包过的 Compose 项目路径，避免重复打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN}컨테이너 백업: $c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" > "$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE}$c가 Docker Compose 컨테이너로 감지됨${NC}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p  "未检测到 compose 目录，请手动输入路径: " project_dir
				fi

				# 如果该 Compose 项目已经打包过，跳过
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}Compose 프로젝트 [$project_name]는 이미 백업되었으며 중복 패키징을 건너뜁니다...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" > "${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" > "${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# docker-compose 복구: $project_name" >> "$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >> "$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}Compose 프로젝트 [$project_name] 패키징 완료:${project_dir}${NC}"
				else
					echo -e "${RED}docker-compose.yml을 찾을 수 없으므로 이 컨테이너를 건너뜁니다...${NC}"
				fi
			else
				# 普通容器备份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "디스크 볼륨 패키징: $path"
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

				echo -e "\n# 컨테이너 복원: $c" >> "$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >> "$RESTORE_SCRIPT"
			fi
		done


		# 备份 /home/docker 下的所有文件（不含子目录）
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE}/home/docker 아래의 파일을 백업 중...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${GREEN}/home/docker 아래의 파일이 다음으로 패키징되었습니다: ${BACKUP_DIR}/home_docker_files.tar.gz${NC}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN}백업 완료: ${BACKUP_DIR}${NC}"
		echo -e "${GREEN}사용 가능한 복원 스크립트: ${RESTORE_SCRIPT}${NC}"


	}

	# ----------------------------
	# 还原
	# ----------------------------
	restore_docker() {

		send_stats "Docker还原"
		read -e -p  "请输入要还原的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}백업 디렉터리가 존재하지 않습니다${NC}"; return; }

		echo -e "${BLUE}복원 작업 시작...${NC}"

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
					echo -e "${YELLOW}Compose 프로젝트 [$project_name]에 이미 실행 중인 컨테이너가 있습니다. 복원을 건너뜁니다...${NC}"
					continue
				fi

				read -e -p  "确认还原 Compose 项目 [$project_name] 到路径 [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p  "请输入新的还原路径: " original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN}Compose 프로젝트 [$project_name]이 다음으로 압축 해제되었습니다: $original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN}Compose 프로젝트 [$project_name] 복원 완료!${NC}"
			fi
		done

		# --------- 继续还原普通容器 ---------
		echo -e "${BLUE}일반 Docker 컨테이너를 확인하고 복원 중...${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${GREEN}컨테이너 처리 중: $container${NC}"

			# 检查容器是否已经存在且正在运行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}컨테이너 [$container]가 이미 실행 중입니다. 복원을 건너뜁니다...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && { echo -e "${RED}이미지 정보를 찾을 수 없습니다. 건너뜁니다: $container${NC}"; continue; }

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
					echo "디스크 볼륨 데이터 복구: $VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 删除已存在但未运行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}컨테이너 [$container]가 존재하지만 실행 중이 아닙니다. 이전 컨테이너를 삭제 중...${NC}"
				docker rm -f "$container"
			fi

			# 启动容器
			echo "복원 명령어 실행: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW}일반 컨테이너의 백업 정보를 찾을 수 없습니다${NC}"

		# 还原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE}/home/docker 아래의 파일을 복원 중...${NC}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${GREEN}/home/docker 아래의 파일 복원 완료${NC}"
		else
			echo -e "${YELLOW}/home/docker 아래의 파일 백업을 찾을 수 없습니다. 건너뜁니다...${NC}"
		fi


	}


	# ----------------------------
	# 迁移
	# ----------------------------
	migrate_docker() {
		send_stats "Docker迁移"
		install jq
		read -e -p  "请输入要迁移的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}백업 디렉터리가 존재하지 않습니다${NC}"; return; }

		read -e -p  "目标服务器IP: " TARGET_IP
		read -e -p  "目标服务器SSH用户名: " TARGET_USER
		read -e -p "대상 서버 SSH 포트 [기본값 22]:" TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW}백업 전송 중...${NC}"
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
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}백업 디렉터리가 존재하지 않습니다${NC}"; return; }
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN}백업 삭제됨: ${BACKUP_DIR}${NC}"
	}

	# ----------------------------
	# 主菜单
	# ----------------------------
	main_menu() {
		send_stats "Docker备份迁移还原"
		while true; do
			clear
			echo "------------------------"
			echo -e "Docker 백업/이전/복원 도구"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. Docker 프로젝트 백업"
			echo -e "2. Docker 프로젝트 이전"
			echo -e "3. Docker 프로젝트 복원"
			echo -e "4. Docker 프로젝트의 백업 파일 삭제"
			echo "------------------------"
			echo -e "0. 이전 메뉴로 돌아가기"
			echo "------------------------"
			read -e -p  "请选择: " choice
			case $choice in
				1) backup_docker ;;
				2) migrate_docker ;;
				3) restore_docker ;;
				4) delete_backup ;;
				0) return ;;
				*) echo -e "${RED}잘못된 옵션${NC}" ;;
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
	  echo -e "Docker 관리"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Docker 환경 업데이트 설치 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Docker 전체 상태 보기 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Docker 컨테이너 관리 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker 이미지 관리"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker 네트워크 관리"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker 볼륨 관리"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}사용하지 않는 Docker 컨테이너 및 이미지 네트워크 데이터 볼륨 정리"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Docker 소스 변경"
	  echo -e "${gl_kjlan}9.   ${gl_bai}daemon.json 파일 편집"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Docker-IPv6 액세스 켜기"
	  echo -e "${gl_kjlan}12.  ${gl_bai}Docker-IPv6 액세스 끄기"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Docker 환경 백업/이전/복원"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Docker 환경 제거"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice

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
			  echo "Docker 버전"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker 이미지: ${gl_lv}$image_count${gl_bai}"
			  docker image ls
			  echo ""
			  echo -e "Docker 컨테이너: ${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Docker 볼륨: ${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Docker 네트워크: ${gl_lv}$network_count${gl_bai}"
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
				  echo "Docker 네트워크 목록"
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
				  echo "네트워크 작업"
				  echo "------------------------"
				  echo "1. 네트워크 생성"
				  echo "2. 네트워크 참여"
				  echo "3. 네트워크 나가기"
				  echo "4. 네트워크 삭제"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "创建网络"
						  read -e -p "새 네트워크 이름을 설정하세요:" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "加入网络"
						  read -e -p "네트워크 이름을 추가하세요:" dockernetwork
						  read -e -p "해당 네트워크에 참여할 컨테이너를 입력하세요 (여러 컨테이너 이름은 공백으로 구분):" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "加入网络"
						  read -e -p "네트워크 이름을 종료하세요:" dockernetwork
						  read -e -p "해당 네트워크에서 종료할 컨테이너를 입력하세요 (여러 컨테이너 이름은 공백으로 구분):" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "删除网络"
						  read -e -p "삭제할 네트워크 이름을 입력하세요:" dockernetwork
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
				  echo "Docker 볼륨 목록"
				  docker volume ls
				  echo ""
				  echo "볼륨 작업"
				  echo "------------------------"
				  echo "1. 새 볼륨 생성"
				  echo "2. 지정된 볼륨 삭제"
				  echo "3. 모든 볼륨 삭제"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "新建卷"
						  read -e -p "새 디스크 볼륨 이름을 설정하세요:" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "삭제할 디스크 볼륨 이름을 입력하세요 (여러 디스크 볼륨 이름은 공백으로 구분):" dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "删除所有卷"
						  read -e -p "$(echo -e "${gl_hong}주의:${gl_bai}모든 사용하지 않는 볼륨을 삭제하시겠습니까? (y/N):")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
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
			  read -e -p "$(echo -e "${gl_huang}팁:${gl_bai}불필요한 이미지, 컨테이너, 네트워크를 정리합니다. 중지된 컨테이너를 포함하여 정리하시겠습니까? (y/N):")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
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
			  read -e -p "$(echo -e "${gl_hong}주의:${gl_bai}Docker 환경 제거를 확실히 하시겠습니까? (y/N):")" choice
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
				  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "测试脚本合集"
	  echo -e "테스트 스크립트 모음"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IP 잠금 해제 상태 확인"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT 잠금 해제 상태 확인"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Region 스트리밍 잠금 해제 테스트"
	  echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu 스트리밍 잠금 해제 확인"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP 품질 검사 스크립트 ${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}네트워크 회선 속도 측정"
	  echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 삼망 회선 지연 경로 테스트"
	  echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace 삼망 회선 테스트"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 삼망 속도 측정"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 빠른 회선 테스트 스크립트"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace 지정 IP 회선 테스트 스크립트"
	  echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 삼 네트워크 회선 테스트"
	  echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 다기능 속도 측정 스크립트"
	  echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality 네트워크 품질 진단 스크립트 ${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}하드웨어 성능 테스트"
	  echo -e "${gl_kjlan}21.  ${gl_bai}yabs 성능 테스트"
	  echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU 성능 테스트 스크립트"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}종합 테스트"
	  echo -e "${gl_kjlan}31.  ${gl_bai}bench 성능 테스트"
	  echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx 융합 괴도 측정 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice

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
			  echo "참조 가능한 IP 목록"
			  echo "------------------------"
			  echo "베이징 전신: 219.141.136.12"
			  echo "베이징 연통: 202.106.50.1"
			  echo "베이징 모바일: 221.179.155.161"
			  echo "상하이 전신: 202.96.209.133"
			  echo "상하이 연통: 210.22.97.1"
			  echo "상하이 모바일: 211.136.112.200"
			  echo "광저우 전신: 58.60.188.222"
			  echo "광저우 연통: 210.21.196.6"
			  echo "광저우 모바일: 120.196.165.24"
			  echo "성도 전신: 61.139.2.69"
			  echo "성도 연통: 119.6.6.6"
			  echo "성도 모바일: 211.137.96.205"
			  echo "후난 전신: 36.111.200.100"
			  echo "후난 연통: 42.48.16.100"
			  echo "후난 모바일: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "지정된 IP를 입력하세요:" testip
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
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "甲骨文云脚本合集"
	  echo -e "Oracle Cloud 스크립트 모음"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}유휴 머신 활성화 스크립트 설치"
	  echo -e "${gl_kjlan}2.   ${gl_bai}유휴 머신 활성화 스크립트 제거"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD 시스템 재설치 스크립트"
	  echo -e "${gl_kjlan}4.   ${gl_bai}R 탐장 부팅 스크립트"
	  echo -e "${gl_kjlan}5.   ${gl_bai}root 비밀번호 로그인 모드 활성화"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPv6 복구 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "활성 스크립트: CPU 사용량 10-20% 메모리 사용량 20%"
			  read -e -p "설치를 확인하시겠습니까? (y/N):" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # 设置默认值
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				  read -e -p "CPU 코어 수를 입력하세요 [기본값: $DEFAULT_CPU_CORE]:" cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "CPU 사용률 범위를 입력하세요 (예: 10-20) [기본값: $DEFAULT_CPU_UTIL]:" cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "메모리 사용률을 입력하세요 [기본값: $DEFAULT_MEM_UTIL]:" mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "Speedtest 간격 시간(초)을 입력하세요 [기본값: $DEFAULT_SPEEDTEST_INTERVAL]:" speedtest_interval
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
				  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
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
		  echo "시스템 재설치"
		  echo "--------------------------------"
		  echo -e "${gl_hong}주의:${gl_bai} 재설치는 위험하며 연결이 끊어질 수 있습니다. 신중하게 사용하십시오. 재설치에는 약 15분이 소요됩니다. 미리 데이터를 백업하십시오."
		  read -e -p "계속하시겠습니까? \(y/N\):" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "재설치할 시스템을 선택하세요: 1. Debian 12 | 2. Ubuntu 20.04:" sys_choice

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
					echo "잘못된 선택입니다. 다시 입력해주세요."
					;;
				esac
			  done

			  read -e -p "재설치 후 비밀번호를 입력하세요:" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "甲骨文云重装系统脚本"
			  ;;
			[Nn])
			  echo "취소되었습니다."
			  ;;
			*)
			  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
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
			  echo "이 기능은 jhb 대가가 제공했으며, 그에게 감사드립니다!"
			  send_stats "ipv6修复"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "잘못된 입력!"
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
		echo -e "${gl_lv}환경에 설치됨${gl_bai}  컨테이너: ${gl_lv}$container_count${gl_bai}  이미지: ${gl_lv}$image_count${gl_bai}  네트워크: ${gl_lv}$network_count${gl_bai}  볼륨: ${gl_lv}$volume_count${gl_bai}"
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
		echo -e "${gl_lv}환경에 설치됨${gl_bai}  사이트: $output  데이터베이스: $db_output"
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
	echo -e "${gl_huang}LDNMP 웹사이트 구축"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}LDNMP 환경 설치 ${gl_huang}★${gl_bai}                     ${gl_huang}2.   ${gl_bai}WordPress 설치 ${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}Discuz 포럼 설치                      ${gl_huang}4.   ${gl_bai}도도 클라우드 데스크탑 설치"
	echo -e "${gl_huang}5.   ${gl_bai}Apple CMS 영화/TV 사이트 설치         ${gl_huang}6.   ${gl_bai}독각수 발급 웹사이트 설치"
	echo -e "${gl_huang}7.   ${gl_bai}Flarum 포럼 웹사이트 설치             ${gl_huang}8.   ${gl_bai}Typecho 경량 블로그 웹사이트 설치"
	echo -e "${gl_huang}9.   ${gl_bai}LinkStack 공유 링크 플랫폼 설치       ${gl_huang}20.  ${gl_bai}동적 웹사이트 사용자 정의"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}Nginx만 설치 ${gl_huang}★${gl_bai}                        ${gl_huang}22.  ${gl_bai}사이트 리디렉션"
	echo -e "${gl_huang}23.  ${gl_bai}사이트 역방향 프록시 - IP+포트 ${gl_huang}★${gl_bai}      ${gl_huang}24.  ${gl_bai}사이트 역방향 프록시 - 도메인"
	echo -e "${gl_huang}25.  ${gl_bai}Bitwarden 비밀번호 관리 플랫폼 설치   ${gl_huang}26.  ${gl_bai}Halo 블로그 웹사이트 설치"
	echo -e "${gl_huang}27.  ${gl_bai}AI 그림 프롬프트 생성기 설치          ${gl_huang}28.  ${gl_bai}사이트 역방향 프록시 - 로드 밸런싱"
	echo -e "${gl_huang}29.  ${gl_bai}Stream 4계층 프록시 전달              ${gl_huang}30.  ${gl_bai}정적 웹사이트 사용자 정의"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}사이트 데이터 관리 ${gl_huang}★${gl_bai}                  ${gl_huang}32.  ${gl_bai}전체 사이트 데이터 백업"
	echo -e "${gl_huang}33.  ${gl_bai}정기 원격 백업                        ${gl_huang}34.  ${gl_bai}전체 사이트 데이터 복원"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}LDNMP 환경 보호                       ${gl_huang}36.  ${gl_bai}LDNMP 환경 최적화"
	echo -e "${gl_huang}37.  ${gl_bai}LDNMP 환경 업데이트                   ${gl_huang}38.  ${gl_bai}LDNMP 환경 제거"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}메인 메뉴로 돌아가기"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "선택을 입력하세요: " sub_choice


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
	  webname="Discuz 포럼"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo "데이터베이스 주소: mysql"
	  echo "데이터베이스 이름: $dbname"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
	  echo "테이블 접두사: discuz_"


		;;

	  4)
	  clear
	  # 可道云桌面
	  webname="可道雲桌面"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo "데이터베이스 주소: mysql"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
	  echo "데이터베이스 이름: $dbname"
	  echo "Redis 호스트: redis"

		;;

	  5)
	  clear
	  # 苹果CMS
	  webname="Apple CMS"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo "데이터베이스 주소: mysql"
	  echo "데이터베이스 포트: 3306"
	  echo "데이터베이스 이름: $dbname"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
	  echo "데이터베이스 접두사: mac_"
	  echo "------------------------"
	  echo "설치 성공 후 관리자 로그인 주소"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 独脚数卡
	  webname="단일 카드"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo "데이터베이스 주소: mysql"
	  echo "데이터베이스 포트: 3306"
	  echo "데이터베이스 이름: $dbname"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
	  echo ""
	  echo "Redis 주소: redis"
	  echo "Redis 비밀번호: 기본적으로 비워둡니다"
	  echo "Redis 포트: 6379"
	  echo ""
	  echo "웹사이트 URL: https://$yuming"
	  echo "관리자 로그인 경로: /admin"
	  echo "------------------------"
	  echo "사용자 이름: admin"
	  echo "비밀번호: admin"
	  echo "------------------------"
	  echo "로그인 시 오른쪽 상단에 빨간색 error0이 나타나면 다음 명령어를 사용하세요:"
	  echo "저도 유니콘 카드 사용이 왜 이렇게 번거로운지, 이런 문제가 발생할지 매우 화가 납니다!"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # flarum论坛
	  webname="Flarum 포럼"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo "데이터베이스 주소: mysql"
	  echo "데이터베이스 이름: $dbname"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
	  echo "테이블 접두사: flarum_"
	  echo "관리자 정보는 직접 설정하세요"

		;;

	  8)
	  clear
	  # typecho
	  webname="Typecho"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo "데이터베이스 접두사: typecho_"
	  echo "데이터베이스 주소: mysql"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
	  echo "데이터베이스 이름: $dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo "데이터베이스 주소: mysql"
	  echo "데이터베이스 포트: 3306"
	  echo "데이터베이스 이름: $dbname"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP 동적 웹사이트"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo -e "[${gl_huang}1/6${gl_bai}] PHP 소스 코드 업로드"
	  echo "-------------"
	  echo "현재 zip 형식의 소스 코드 패키지만 업로드할 수 있습니다. 소스 코드 패키지를 /home/web/html/${yuming} 디렉토리에 넣으세요."
	  read -e -p "다운로드 링크를 입력하여 원격으로 소스 코드 패키지를 다운로드할 수도 있습니다. Enter 키를 누르면 원격 다운로드를 건너뜁니다:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] index.php 위치 경로"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "index.php의 경로를 입력하세요 (예: /home/web/html/$yuming/wordpress/):" index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] PHP 버전 선택"
	  echo "-------------"
	  read -e -p "1. php 최신 버전 | 2. php 7.4:" pho_v
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
		  echo "잘못된 선택입니다. 다시 입력해주세요."
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] 지정 확장 설치"
	  echo "-------------"
	  echo "설치된 확장"
	  docker exec php php -m

	  read -e -p "$(echo -e "설치할 확장 이름을 입력하세요. 예: ${gl_huang}SourceGuardian imap ftp${gl_bai} 등. Enter 키를 누르면 설치를 건너뜁니다:")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] 사이트 구성 편집"
	  echo "-------------"
	  echo "아무 키나 눌러 계속하고, 가짜 정적 콘텐츠 등 사이트 구성을 자세히 설정할 수 있습니다."
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] 데이터베이스 관리"
	  echo "-------------"
	  read -e -p "1. 새 사이트 구축 | 2. 기존 사이트 구축 (데이터베이스 백업 있음):" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "데이터베이스 백업은 .gz로 끝나는 압축 파일이어야 합니다. /home 디렉토리에 넣으세요. BTPanel / 1panel 백업 데이터 가져오기를 지원합니다."
			  read -e -p "백업 데이터를 원격으로 다운로드하기 위한 다운로드 링크를 입력할 수도 있습니다. Enter 키를 누르면 원격 다운로드를 건너뜁니다:" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "데이터베이스 가져오기 테이블 데이터"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "데이터베이스 가져오기 완료"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "데이터베이스 주소: mysql"
	  echo "데이터베이스 이름: $dbname"
	  echo "사용자 이름: $dbuse"
	  echo "비밀번호: $dbusepasswd"
	  echo "테이블 접두사: $prefix"
	  echo "관리자 로그인 정보는 직접 설정"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="사이트 리디렉션"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
	  add_yuming
	  read -e -p "리디렉션 도메인을 입력하세요:" reverseproxy
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
		echo "IP+포트가 이 서비스에 대한 접근을 차단했습니다."
	  else
	  	ip_address
		block_container_port "$docker_name" "$ipv4_address"
	  fi

		;;

	  24)
	  clear
	  webname="리버스 프록시 - 도메인"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
	  add_yuming
	  echo -e "도메인 형식: ${gl_huang}google.com${gl_bai}"
	  read -e -p "프록시 도메인을 입력하세요:" fandai_yuming
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
	  echo "{$webname} 배포 시작"
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
	  echo "{$webname} 배포 시작"
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
	  webname="AI 이미지 프롬프트 생성기"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  webname="정적 웹사이트"
	  send_stats "安装$webname"
	  echo "{$webname} 배포 시작"
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
	  echo -e "[${gl_huang}1/2${gl_bai}] 정적 소스 코드 업로드"
	  echo "-------------"
	  echo "현재 zip 형식의 소스 코드 패키지만 업로드할 수 있습니다. 소스 코드 패키지를 /home/web/html/${yuming} 디렉토리에 넣으세요."
	  read -e -p "다운로드 링크를 입력하여 원격으로 소스 코드 패키지를 다운로드할 수도 있습니다. Enter 키를 누르면 원격 다운로드를 건너뜁니다:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] index.html 경로"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "index.html의 경로를 입력하세요 (예: /home/web/html/$yuming/index/):" index_lujing

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
	  echo -e "${gl_huang}$backup_filename 백업 중...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "백업 파일 생성됨: /home/$backup_filename"
		read -e -p "백업 데이터를 원격 서버로 전송하시겠습니까? (y/N):" choice
		case "$choice" in
		  [Yy])
			read -e -p "원격 서버 IP를 입력하세요:" remote_ip
			read -e -p "대상 서버 SSH 포트 [기본값 22]:" TARGET_PORT
			local TARGET_PORT=${TARGET_PORT:-22}
			if [ -z "$remote_ip" ]; then
			  echo "오류: 원격 서버 IP를 입력하세요."
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "파일이 원격 서버 /home 디렉터리로 전송됨."
			else
			  echo "전송할 파일이 없습니다."
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "定时远程备份"
	  read -e -p "원격 서버 IP를 입력하세요:" useip
	  read -e -p "원격 서버 비밀번호를 입력하세요:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. 매주 백업                 2. 매일 백업"
	  read -e -p "선택을 입력하세요: " dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "매주 백업할 요일을 선택하세요 (0-6, 0은 일요일):" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "매일 백업할 시간(시간, 0-23)을 선택하세요:" hour
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
	  echo "사용 가능한 사이트 백업"
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

		  echo -e "${gl_huang}$filename 압축 해제 중...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "압축 파일을 찾을 수 없습니다."
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
		  echo "LDNMP 환경 업데이트"
		  echo "------------------------"
		  ldnmp_v
		  echo "새로운 구성 요소 버전 발견"
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
		  echo "1. Nginx 업데이트              2. MySQL 업데이트             3. PHP 업데이트              4. redis 업데이트"
		  echo "------------------------"
		  echo "5. 전체 환경 업데이트"
		  echo "------------------------"
		  echo "0. 이전 메뉴로 돌아가기"
		  echo "------------------------"
		  read -e -p "선택을 입력하세요: " sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "${ldnmp_pods} 버전을 입력하세요 (예: 8.0 8.3 8.4 9.0) (Enter 키를 누르면 최신 버전을 가져옵니다):" version
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
			  echo "${ldnmp_pods} 업데이트 완료"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "${ldnmp_pods} 버전 번호(예: 7.4 8.0 8.1 8.2 8.3)를 입력하세요(Enter를 눌러 최신 버전 획득):" version
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
			  echo "${ldnmp_pods} 업데이트 완료"

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
			  echo "${ldnmp_pods} 업데이트 완료"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}팁:${gl_bai}오랜 시간 동안 환경을 업데이트하지 않은 사용자는 LDNMP 환경을 업데이트할 때 데이터베이스 업데이트가 실패할 위험이 있습니다. LDNMP 환경을 업데이트하시겠습니까? (y/N):")" choice
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
		read -e -p "$(echo -e "${gl_hong}강력히 권장:${gl_bai}모든 웹사이트 데이터를 백업한 후 LDNMP 환경을 제거하십시오. 모든 웹사이트 데이터를 삭제하시겠습니까? (y/N):")" choice
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
			echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "잘못된 입력!"
	esac
	break_end

  done

}



linux_panel() {


local sub_choice="$1"


while true; do

	if [ -z "$sub_choice" ]; then
	  clear
	  echo -e "앱 마켓"
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

	  echo -e "${gl_kjlan}1.   ${color1}宝塔面板 공식 버전                                ${gl_kjlan}2.   ${color2}aaPanel 宝塔 국제 버전"
	  echo -e "${gl_kjlan}3.   ${color3}1Panel 차세대 관리 패널                           ${gl_kjlan}4.   ${color4}NginxProxyManager 시각화 패널"
	  echo -e "${gl_kjlan}5.   ${color5}OpenList 다중 스토리지 공간 파일 목록 프로그램    ${gl_kjlan}6.   ${color6}Ubuntu 원격 데스크톱 웹 버전"
	  echo -e "${gl_kjlan}7.   ${color7}哪吒探针 VPS 모니터링 패널                        ${gl_kjlan}8.   ${color8}QB 오프라인 BT 자력 다운로드 패널"
	  echo -e "${gl_kjlan}9.   ${color9}Poste.io 메일 서버 프로그램                       ${gl_kjlan}10.  ${color10}Rocket.Chat 다인 온라인 채팅 시스템"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${color11}젠도 프로젝트 관리 소프트웨어                     ${gl_kjlan}12.  ${color12}청룡 패널 예약 작업 관리 플랫폼"
	  echo -e "${gl_kjlan}13.  ${color13}Cloudreve 웹 디스크 ${gl_huang}★${gl_bai}                             ${gl_kjlan}14.  ${color14}간단한 이미지 호스팅 이미지 관리 프로그램"
	  echo -e "${gl_kjlan}15.  ${color15}Emby 멀티미디어 관리 시스템                       ${gl_kjlan}16.  ${color16}Speedtest 속도 측정 패널"
	  echo -e "${gl_kjlan}17.  ${color17}AdGuard Home 광고 차단 소프트웨어                 ${gl_kjlan}18.  ${color18}ONLYOFFICE 온라인 오피스 Office"
	  echo -e "${gl_kjlan}19.  ${color19}雷池 WAF 방화벽 패널                              ${gl_kjlan}20.  ${color20}Portainer 컨테이너 관리 패널"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${color21}VS Code 웹 버전                                   ${gl_kjlan}22.  ${color22}Uptime Kuma 모니터링 도구"
	  echo -e "${gl_kjlan}23.  ${color23}Memos 웹 메모                                     ${gl_kjlan}24.  ${color24}Webtop 원격 데스크톱 웹 버전 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${color25}Nextcloud 클라우드 스토리지                       ${gl_kjlan}26.  ${color26}QD 예약 작업 관리 프레임워크"
	  echo -e "${gl_kjlan}27.  ${color27}Dockge 컨테이너 스택 관리 패널                    ${gl_kjlan}28.  ${color28}LibreSpeed 속도 측정 도구"
	  echo -e "${gl_kjlan}29.  ${color29}SearXNG 통합 검색 스테이션 ${gl_huang}★${gl_bai}                      ${gl_kjlan}30.  ${color30}PhotoPrism 개인 앨범 시스템"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${color31}Stirling PDF 도구 모음                            ${gl_kjlan}32.  ${color32}draw.io 무료 온라인 다이어그램 소프트웨어 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${color33}Sun-Panel 내비게이션 패널                         ${gl_kjlan}34.  ${color34}Pingvin Share 파일 공유 플랫폼"
	  echo -e "${gl_kjlan}35.  ${color35}미니멀한 모멘트                                   ${gl_kjlan}36.  ${color36}LobeChat AI 채팅 통합 웹사이트"
	  echo -e "${gl_kjlan}37.  ${color37}MyIP 도구 상자 ${gl_huang}★${gl_bai}                                  ${gl_kjlan}38.  ${color38}샤오야 Alist 올인원"
	  echo -e "${gl_kjlan}39.  ${color39}Bililive 라이브 스트리밍 녹화 도구                ${gl_kjlan}40.  ${color40}WebSSH 웹 기반 SSH 연결 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${color41}쥐 관리 패널                                      ${gl_kjlan}42.  ${color42}Nexterm 원격 연결 도구"
	  echo -e "${gl_kjlan}43.  ${color43}RustDesk 원격 데스크톱 (서버)${gl_huang}★${gl_bai}                    ${gl_kjlan}44.  ${color44}RustDesk 원격 데스크톱 (릴레이)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${color45}Docker 가속 스테이션                              ${gl_kjlan}46.  ${color46}GitHub 가속 스테이션 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${color47}Prometheus 모니터링                               ${gl_kjlan}48.  ${color48}Prometheus (호스트 모니터링)"
	  echo -e "${gl_kjlan}49.  ${color49}Prometheus (컨테이너 모니터링)                    ${gl_kjlan}50.  ${color50}재고 모니터링 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${color51}PVE 작은 닭 패널                                  ${gl_kjlan}52.  ${color52}DPanel 컨테이너 관리 패널"
	  echo -e "${gl_kjlan}53.  ${color53}Llama3 채팅 AI 대규모 언어 모델                   ${gl_kjlan}54.  ${color54}AMH 호스팅 웹사이트 관리 패널"
	  echo -e "${gl_kjlan}55.  ${color55}FRP 내부 네트워크 침투 (서버)${gl_huang}★${gl_bai}                    ${gl_kjlan}56.  ${color56}FRP 내부 네트워크 침투 (클라이언트)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${color57}DeepSeek 채팅 AI 대규모 언어 모델                 ${gl_kjlan}58.  ${color58}Dify 대규모 언어 모델 지식 기반 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${color59}NewAPI 대규모 언어 모델 자산 관리                 ${gl_kjlan}60.  ${color60}JumpServer 오픈 소스 점프 서버"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${color61}온라인 번역 서버                                  ${gl_kjlan}62.  ${color62}RAGFlow 대규모 언어 모델 지식 기반"
	  echo -e "${gl_kjlan}63.  ${color63}Open WebUI 자체 호스팅 AI 플랫폼 ${gl_huang}★${gl_bai}                ${gl_kjlan}64.  ${color64}it-tools 도구 상자"
	  echo -e "${gl_kjlan}65.  ${color65}n8n 자동화 워크플로우 플랫폼 ${gl_huang}★${gl_bai}                    ${gl_kjlan}66.  ${color66}yt-dlp 비디오 다운로드 도구"
	  echo -e "${gl_kjlan}67.  ${color67}DDNS-GO 동적 DNS 관리 도구 ${gl_huang}★${gl_bai}                      ${gl_kjlan}68.  ${color68}ALLinSSL 인증서 관리 플랫폼"
	  echo -e "${gl_kjlan}69.  ${color69}SFTPGo 파일 전송 도구                             ${gl_kjlan}70.  ${color70}AstrBot 챗봇 프레임워크"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}71.  ${color71}Navidrome 개인 음악 서버                          ${gl_kjlan}72.  ${color72}Bitwarden 비밀번호 관리자 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${color73}LibreTV 개인 영화 및 TV 프로그램                  ${gl_kjlan}74.  ${color74}MoonTV 개인 영화 및 TV 프로그램"
	  echo -e "${gl_kjlan}75.  ${color75}Melody 음악 헬퍼                                  ${gl_kjlan}76.  ${color76}온라인 DOS 레트로 게임"
	  echo -e "${gl_kjlan}77.  ${color77}迅雷 오프라인 다운로드 도구                       ${gl_kjlan}78.  ${color78}PandaWiki 스마트 문서 관리 시스템"
	  echo -e "${gl_kjlan}79.  ${color79}Beszel 서버 모니터링                              ${gl_kjlan}80.  ${color80}Linkwarden 북마크 관리"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}81.  ${color81}Jitsi Meet 비디오 회의                            ${gl_kjlan}82.  ${color82}GPT-Load 고성능 AI 투명 프록시"
	  echo -e "${gl_kjlan}83.  ${color83}Komari 서버 모니터링 도구                         ${gl_kjlan}84.  ${color84}Wallos 개인 재무 관리 도구"
	  echo -e "${gl_kjlan}85.  ${color85}Immich 사진 및 비디오 관리자                      ${gl_kjlan}86.  ${color86}Jellyfin 미디어 관리 시스템"
	  echo -e "${gl_kjlan}87.  ${color87}SyncTV 함께 영화 보기 도구                        ${gl_kjlan}88.  ${color88}Owncast 자체 호스팅 라이브 스트리밍 플랫폼"
	  echo -e "${gl_kjlan}89.  ${color89}FileCodeBox 파일 배달                             ${gl_kjlan}90.  ${color90}Matrix 분산 채팅 프로토콜"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}91.  ${color91}Gitea 개인 코드 저장소                            ${gl_kjlan}92.  ${color92}FileBrowser 파일 관리자"
	  echo -e "${gl_kjlan}93.  ${color93}Dufs 미니멀 정적 파일 서버                        ${gl_kjlan}94.  ${color94}Gopeed 고속 다운로드 도구"
	  echo -e "${gl_kjlan}95.  ${color95}Paperless 문서 관리 플랫폼                        ${gl_kjlan}96.  ${color96}2FAuth 자체 호스팅 2단계 인증기"
	  echo -e "${gl_kjlan}97.  ${color97}WireGuard 메시 네트워크(서버)                     ${gl_kjlan}98.  ${color98}WireGuard 메시 네트워크(클라이언트)"
	  echo -e "${gl_kjlan}99.  ${color99}DSM Synology 가상 머신                            ${gl_kjlan}100. ${color100}Syncthing 피어 투 피어 파일 동기화 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}101. ${color101}AI 비디오 생성 도구                               ${gl_kjlan}102. ${color102}VoceChat 다중 사용자 온라인 채팅 시스템"
	  echo -e "${gl_kjlan}103. ${color103}Umami 웹사이트 통계 도구                          ${gl_kjlan}104. ${color104}Stream 4계층 프록시 전달 도구"
	  echo -e "${gl_kjlan}105. ${color105}사원 필기                                         ${gl_kjlan}106. ${color106}Drawnix 오픈 소스 화이트보드 도구"
	  echo -e "${gl_kjlan}107. ${color107}PanSou 웹 디스크 검색"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}b.   ${gl_bai}모든 애플리케이션 데이터 백업                     ${gl_kjlan}r.   ${gl_bai}모든 애플리케이션 데이터 복원"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice
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

		local docker_describe="Nginx 리버스 프록시 도구 패널이며, 도메인 이름 액세스 추가를 지원하지 않습니다."
		local docker_url="공식 웹사이트 소개: https://nginxproxymanager.com/"
		local docker_use="echo \"초기 사용자 이름: admin@example.com\""
		local docker_passwd="echo "초기 비밀번호: changeme""
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


		local docker_describe="gin 및 Solidjs로 구동되는 다양한 스토리지를 지원하고 웹 브라우징 및 WebDAV를 지원하는 파일 목록 프로그램입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/OpenListTeam/OpenList"
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

			read -e -p "로그인 사용자 이름 설정:" admin
			read -e -p "로그인 사용자 비밀번호 설정:" admin_password
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


		local docker_describe="Webtop은 Ubuntu 기반 컨테이너입니다. IP에 액세스할 수 없는 경우 도메인 이름 액세스를 추가하십시오."
		local docker_url="공식 웹사이트 소개: https://docs.linuxserver.io/images/docker-webtop/"
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
			echo -e "나타 감시 $check_docker $update_status"
			echo "오픈 소스, 경량, 사용하기 쉬운 서버 모니터링 및 유지 관리 도구"
			echo "공식 문서: https://nezha.wiki/guide/dashboard.html"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
				check_docker_app_ip
			fi
			echo ""
			echo "------------------------"
			echo "1. 사용법"
			echo "------------------------"
			echo "0. 이전 메뉴로 돌아가기"
			echo "------------------------"
			read -e -p "선택을 입력하세요:" choice

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

		local docker_describe="qBittorrent 오프라인 BT 토렌트 다운로드 서비스"
		local docker_url="공식 웹사이트 소개: https://hub.docker.com/r/linuxserver/qbittorrent"
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
			echo -e "우체국 서비스 $check_docker $update_status"
			echo "Poste.io는 오픈 소스 메일 서버 솔루션입니다."
			echo "비디오 소개: https://youtu.be/KeqlzO9mPn0"

			echo ""
			echo "포트 검사"
			port=25
			timeout=3
			if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
			  echo -e "${gl_lv}포트 $port 현재 사용 가능${gl_bai}"
			else
			  echo -e "${gl_hong}포트 $port 현재 사용 불가능${gl_bai}"
			fi
			echo ""

			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				yuming=$(cat /home/docker/mail.txt)
				echo "방문 주소:"
				echo "https://$yuming"
			fi

			echo "------------------------"
			echo "1. 설치                  2. 업데이트                  3. 제거"
			echo "------------------------"
			echo "0. 이전 메뉴로 돌아가기"
			echo "------------------------"
			read -e -p "선택을 입력하세요:" choice

			case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "이메일 도메인을 설정하세요(예: mail.yuming.com):" yuming
					mkdir -p /home/docker
					echo "$yuming" > /home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "먼저 이러한 DNS 레코드를 분석합니다."
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo ""
					echo "------------------------"
					echo "아무 키나 눌러 계속..."
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
					echo "Poste.io가 설치되었습니다."
					echo "------------------------"
					echo "다음 주소로 Poste.io에 접속할 수 있습니다:"
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
					echo "Poste.io가 설치되었습니다."
					echo "------------------------"
					echo "다음 주소로 Poste.io에 접속할 수 있습니다:"
					echo "https://$yuming"
					echo ""
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "애플리케이션이 제거되었습니다."
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
		local app_name="Rocket.Chat 채팅 시스템"
		local app_text="Rocket.Chat은 실시간 채팅, 오디오/비디오 통화, 파일 공유 등 다양한 기능을 지원하는 오픈 소스 팀 커뮤니케이션 플랫폼입니다."
		local app_url="공식 소개: https://www.rocket.chat/"
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
			echo "설치가 완료되었습니다."
			check_docker_app_ip
		}

		docker_app_update() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat:latest
			docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
			clear
			ip_address
			echo "Rocket.Chat이 설치되었습니다."
			check_docker_app_ip
		}

		docker_app_uninstall() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat
			docker rm -f db
			docker rmi -f mongo:latest
			rm -rf /home/docker/mongo
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="젠도(ZenTao)는 범용 프로젝트 관리 소프트웨어입니다."
		local docker_url="공식 웹사이트 소개: https://www.zentao.net/"
		local docker_use="echo \"초기 사용자 이름: admin\""
		local docker_passwd="echo "초기 비밀번호: 123456""
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

		local docker_describe="청룡 패널은 예약 작업 관리 플랫폼입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/whyour/qinglong"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  13|cloudreve)

		local app_id="13"
		local app_name="Cloudreve 네트워크 하드 드라이브"
		local app_text="Cloudreve는 여러 클라우드 스토리지를 지원하는 네트워크 하드 드라이브 시스템입니다."
		local app_url="비디오 소개: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
			echo "설치가 완료되었습니다."
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			cd /home/docker/cloud/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			rm -rf /home/docker/cloud
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="간단한 이미지 호스팅은 간단한 이미지 호스팅 프로그램입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/icret/EasyImages2.0"
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


		local docker_describe="Emby는 마스터-슬레이브 아키텍처의 미디어 서버 소프트웨어로, 서버의 비디오 및 오디오를 구성하고 오디오 및 비디오를 클라이언트 장치로 스트리밍하는 데 사용할 수 있습니다."
		local docker_url="공식 웹사이트 소개: https://emby.media/"
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

		local docker_describe="Speedtest 속도 테스트 패널은 VPS 네트워크 속도 테스트 도구이며, 다양한 테스트 기능과 VPS의 실시간 인바운드/아웃바운드 트래픽 모니터링을 제공합니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/wikihost-opensource/als"
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


		local docker_describe="AdGuard Home은 전체 네트워크 광고 차단 및 추적 방지 소프트웨어이며, 앞으로 DNS 서버 이상의 역할을 할 것입니다."
		local docker_url="공식 웹사이트 소개: https://hub.docker.com/r/adguard/adguardhome"
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

		local docker_describe="ONLYOFFICE는 오픈 소스 온라인 Office 도구이며, 정말 강력합니다!"
		local docker_url="공식 웹사이트 소개: https://www.onlyoffice.com/"
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
			echo -e "레이치 서비스 $check_docker"
			echo "레치는 장정科技에서 개발한 WAF 웹 방화벽 프로그램 패널로, 웹사이트를 리버스 프록시하여 자동 방어를 수행할 수 있습니다."
			echo "비디오 소개: https://youtu.be/_nkZXhnm68Y"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				check_docker_app_ip
			fi
			echo ""

			echo "------------------------"
			echo "1. 설치            2. 업데이트            3. 비밀번호 재설정            4. 제거"
			echo "------------------------"
			echo "0. 이전 메뉴로 돌아가기"
			echo "------------------------"
			read -e -p "선택을 입력하세요:" choice

			case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "레치 WAF 패널이 설치되었습니다."
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "레치 WAF 패널이 업데이트되었습니다."
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "기본 설치 디렉터리인 경우 현재 프로젝트가 제거되었습니다. 사용자 지정 설치 디렉터리인 경우 설치 디렉터리에서 수동으로 실행해야 합니다:"
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


		local docker_describe="Portainer는 경량 Docker 컨테이너 관리 패널입니다."
		local docker_url="공식 웹사이트 소개: https://www.portainer.io/"
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


		local docker_describe="VS Code는 강력한 온라인 코드 작성 도구입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/coder/code-server"
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


		local docker_describe="Uptime Kuma는 사용하기 쉬운 자체 호스팅 모니터링 도구입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/louislam/uptime-kuma"
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

		local docker_describe="Memos는 경량의 자체 호스팅 메모 센터입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/usememos/memos"
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

			read -e -p "로그인 사용자 이름 설정:" admin
			read -e -p "로그인 사용자 비밀번호 설정:" admin_password
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


		local docker_describe="Webtop은 Alpine 기반의 중국어 버전 컨테이너입니다. IP에 액세스할 수 없는 경우 도메인 이름 액세스를 추가하십시오."
		local docker_url="공식 웹사이트 소개: https://docs.linuxserver.io/images/docker-webtop/"
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

		local docker_describe="Nextcloud는 40만 개 이상의 배포를 보유하고 있으며 다운로드할 수 있는 가장 인기 있는 로컬 콘텐츠 협업 플랫폼입니다."
		local docker_url="공식 웹사이트 소개: https://nextcloud.com/"
		local docker_use="echo \"계정: nextcloud  비밀번호: $rootpasswd\""
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

		local docker_describe="QD는 HTTP 요청을 예약된 작업으로 자동 실행하는 프레임워크입니다."
		local docker_url="공식 홈페이지 소개 : https://qd-today.github.io/qd/"
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

		local docker_describe="Dockge는 시각적인 Docker Compose 컨테이너 관리 패널입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/louislam/dockge"
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

		local docker_describe="LibreSpeed는 Javascript로 구현된 경량 속도 테스트 도구로, 바로 사용할 수 있습니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/librespeed/speedtest"
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

		local docker_describe="SearXNG는 개인 정보 보호를 위한 검색 엔진 사이트입니다."
		local docker_url="공식 웹사이트 소개: https://hub.docker.com/r/alandoyle/searxng"
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


		local docker_describe="PhotoPrism은 매우 강력한 개인 사진 앨범 시스템입니다."
		local docker_url="공식 웹사이트 소개: https://www.photoprism.app/"
		local docker_use="echo \"계정: admin  비밀번호: $rootpasswd\""
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

		local docker_describe="이것은 Docker를 사용하여 PDF 파일을 분할, 병합, 변환, 재구성, 이미지 추가, 회전, 압축 등 다양한 작업을 수행할 수 있는 강력한 로컬 호스팅 웹 기반 PDF 도구입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
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


		local docker_describe="이것은 강력한 차트 그리기 소프트웨어입니다. 마인드 맵, 토폴로지 맵, 흐름도를 그릴 수 있습니다."
		local docker_url="공식 웹사이트 소개: https://www.drawio.com/"
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

		local docker_describe="Sun-Panel 서버, NAS 탐색 패널, 홈페이지, 브라우저 홈 페이지"
		local docker_url="공식 홈페이지 소개 : https://doc.sun-panel.top/"
		local docker_use="echo \"계정: admin@sun.cc  비밀번호: 12345678\""
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

		local docker_describe="Pingvin Share는 자체 구축 가능한 파일 공유 플랫폼으로, WeTransfer의 대안입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/stonith404/pingvin-share"
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


		local docker_describe="미니멀한朋友圈, WeChat朋友圈을 모방하여 당신의 아름다운 삶을 기록합니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
		local docker_use="echo \"계정: admin  비밀번호: a123456\""
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

		local docker_describe="LobeChat은 ChatGPT/Claude/Gemini/Groq/Ollama를 포함하여 시장의 주요 AI 대 모델을 통합합니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/lobehub/lobe-chat"
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


		local docker_describe="다기능 IP 툴박스로, 웹 패널을 통해 자신의 IP 정보 및 연결 상태를 확인할 수 있습니다."
		local docker_url="공식 홈페이지 소개: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README.md"
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

		local docker_describe="Bililive는 다양한 라이브 스트리밍 플랫폼을 지원하는 라이브 스트리밍 녹화 도구입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
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

		local docker_describe="간단한 온라인 SSH 및 SFTP 도구"
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/Jrohy/webssh"
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

		local docker_describe="Nexterm은 강력한 온라인 SSH/VNC/RDP 연결 도구입니다."
		local docker_url="공식 웹사이트 소개: ${gh_proxy}github.com/gnmyt/Nexterm"
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


		local docker_describe="RustDesk는 오픈 소스 원격 데스크톱(서버 측)으로, 자신의 TeamViewer 개인 서버와 유사합니다."
		local docker_url="공식 홈페이지 소개: https://rustdesk.com/"
		local docker_use="docker logs hbbs"
		local docker_passwd="echo "IP 주소와 키를 기록해 두세요. 원격 데스크톱 클라이언트에서 사용됩니다. 44번 옵션에서 릴레이를 설치하세요!""
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

		local docker_describe="RustDesk는 오픈 소스 원격 데스크톱(릴레이 측)으로, 자신의 TeamViewer 개인 서버와 유사합니다."
		local docker_url="공식 홈페이지 소개: https://rustdesk.com/"
		local docker_use="echo \"원격 데스크톱 클라이언트를 다운로드하려면 공식 웹사이트로 이동하세요: https://rustdesk.com/\""
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

		local docker_describe="Docker Registry는 Docker 이미지를 저장하고 배포하는 서비스입니다."
		local docker_url="공식 웹사이트 소개: https://hub.docker.com/_/registry"
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

		local docker_describe="Go로 구현된 GHProxy로, 일부 지역의 Github 저장소 풀을 가속화합니다."
		local docker_url="공식 웹사이트 소개: https://github.com/WJQSERVER-STUDIO/ghproxy"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  47|prometheus|grafana)

		local app_id="47"
		local app_name="Prometheus 모니터링"
		local app_text="Prometheus+Grafana 엔터프라이즈급 모니터링 시스템"
		local app_url="공식 웹사이트 소개: https://prometheus.io"
		local docker_name="grafana"
		local docker_port="8047"
		local app_size="2"

		docker_app_install() {
			prometheus_install
			clear
			ip_address
			echo "설치가 완료되었습니다."
			check_docker_app_ip
			echo "초기 사용자 이름과 비밀번호는 모두 admin입니다."
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
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="이것은 Prometheus의 호스트 데이터 수집 구성 요소로, 모니터링되는 호스트에 배포해야 합니다."
		local docker_url="공식 웹사이트 소개: https://github.com/prometheus/node_exporter"
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

		local docker_describe="이것은 Prometheus의 컨테이너 데이터 수집 컴포넌트이며, 모니터링 대상 호스트에 배포하십시오."
		local docker_url="공식 웹사이트 소개: https://github.com/google/cadvisor"
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

		local docker_describe="이것은 웹사이트 변경 감지, 재고 모니터링 및 알림을 위한 작은 도구입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/dgtlmoon/changedetection.io"
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

		local docker_describe="Docker 시각화 대시보드 시스템으로, 완벽한 Docker 관리 기능을 제공합니다."
		local docker_url="공식 웹사이트 소개: https://github.com/donknap/dpanel"
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

		local docker_describe="Open WebUI는 새로운 Llama3 대규모 언어 모델에 접속하는 웹 프레임워크입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/open-webui/open-webui"
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

		local docker_describe="Open WebUI는 새로운 DeepSeek R1 대규모 언어 모델에 접속하는 웹 프레임워크입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;


	  58|dify)
		local app_id="58"
		local app_name="Dify 지식 베이스"
		local app_text="오픈 소스 대규모 언어 모델(LLM) 애플리케이션 개발 플랫폼입니다. 자체 호스팅 훈련 데이터는 AI 생성에 사용됩니다."
		local app_url="공식 홈페이지: https://docs.dify.ai/"
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
			echo "설치가 완료되었습니다."
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
			echo "애플리케이션이 제거되었습니다."
		}

		docker_app_plus

		  ;;

	  59|new-api)
		local app_id="59"
		local app_name="NewAPI"
		local app_text="차세대 대규모 모델 게이트웨이 및 AI 자산 관리 시스템"
		local app_url="공식 웹사이트: https://github.com/Calcium-Ion/new-api"
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
			echo "설치가 완료되었습니다."
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
			echo "설치가 완료되었습니다."
			check_docker_app_ip

		}

		docker_app_uninstall() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			rm -rf /home/docker/new-api
			echo "애플리케이션이 제거되었습니다."
		}

		docker_app_plus

		  ;;


	  60|jms)

		local app_id="60"
		local app_name="JumpServer 오픈 소스 요새 기계"
		local app_text="오픈 소스 특권 액세스 관리(PAM) 도구이며, 이 프로그램은 80번 포트를 사용하므로 도메인 액세스를 지원하지 않습니다."
		local app_url="공식 소개: https://github.com/jumpserver/jumpserver"
		local docker_name="jms_web"
		local docker_port="80"
		local app_size="2"

		docker_app_install() {
			curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
			clear
			echo "설치가 완료되었습니다."
			check_docker_app_ip
			echo "초기 사용자 이름: admin"
			echo "초기 비밀번호: ChangeMe"
		}


		docker_app_update() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh upgrade
			echo "앱이 업데이트되었습니다."
		}


		docker_app_uninstall() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh uninstall
			cd /opt
			rm -rf jumpserver-installer*/
			rm -rf jumpserver
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="무료 오픈 소스 기계 번역 API로, 완전한 자체 호스팅을 지원하며, 오픈 소스 Argos Translate 라이브러리를 통해 번역 엔진을 제공합니다."
		local docker_url="공식 웹사이트 소개: https://github.com/LibreTranslate/LibreTranslate"
		local docker_use=""
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;



	  62|ragflow)
		local app_id="62"
		local app_name="RAGFlow 지식 베이스"
		local app_text="심층 문서 이해를 기반으로 하는 오픈 소스 RAG(검색 증강 생성) 엔진"
		local app_url="공식 웹사이트: https://github.com/infiniflow/ragflow"
		local docker_name="ragflow-server"
		local docker_port="8062"
		local app_size="8"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/infiniflow/ragflow.git && cd ragflow/docker
			sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
			docker compose up -d
			clear
			echo "설치가 완료되었습니다."
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
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="Open WebUI는 다양한 모델 API 접속을 지원하는 공식 간소화 버전의 대규모 언어 모델 웹 프레임워크입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/open-webui/open-webui"
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

		local docker_describe="개발자와 IT 작업자에게 매우 유용한 도구입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/CorentinTh/it-tools"
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

		local docker_describe="강력한 자동화 워크플로우 플랫폼입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/n8n-io/n8n"
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

		local docker_describe="귀하의 공용 IP(IPv4/IPv6)를 즉시 주요 DNS 서비스 제공업체에 업데이트하여 동적 도메인 해석을 구현합니다."
		local docker_url="공식 웹사이트 소개: https://github.com/jeessy2/ddns-go"
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

		local docker_describe="오픈 소스 무료 SSL 인증서 자동 관리 플랫폼입니다."
		local docker_url="공식 웹사이트 소개: https://allinssl.com"
		local docker_use="echo \"보안 진입점: /allinssl\""
		local docker_passwd="echo "사용자 이름: allinssl  비밀번호: allinssldocker""
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

		local docker_describe="오픈 소스 무료 언제 어디서나 SFTP FTP WebDAV 파일 전송 도구입니다."
		local docker_url="공식 웹사이트 소개: https://sftpgo.com/"
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

		local docker_describe="오픈 소스 AI 챗봇 프레임워크로, WeChat, QQ, TG를 통한 AI 대규모 모델 접속을 지원합니다."
		local docker_url="공식 웹사이트 소개: https://astrbot.app/"
		local docker_use="echo \"사용자 이름: astrbot  비밀번호: astrbot\""
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

		local docker_describe="가볍고 고성능의 음악 스트리밍 미디어 서버입니다."
		local docker_url="공식 웹사이트 소개: https://www.navidrome.org/"
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

		local docker_describe="데이터를 제어할 수 있는 비밀번호 관리자입니다."
		local docker_url="공식 웹사이트 소개: https://bitwarden.com/"
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

			read -e -p "LibreTV 로그인 비밀번호 설정:" app_passwd

			docker run -d \
			  --name libretv \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -e PASSWORD=${app_passwd} \
			  bestzwei/libretv:latest

		}

		local docker_describe="무료 온라인 비디오 검색 및 시청 플랫폼"
		local docker_url="공식 웹사이트 소개: https://github.com/LibreSpark/LibreTV"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  74|moontv)

		local app_id="74"

		local app_name="moontv 개인 영화 및 TV"
		local app_text="무료 온라인 비디오 검색 및 시청 플랫폼"
		local app_url="비디오 소개: https://github.com/MoonTechLab/LunaTV"
		local docker_name="moontv-core"
		local docker_port="8074"
		local app_size="2"

		docker_app_install() {
			read -e -p "로그인 사용자 이름 설정:" admin
			read -e -p "로그인 사용자 비밀번호 설정:" admin_password
			read -e -p "라이선스 키 입력:" shouquanma


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
			echo "설치가 완료되었습니다."
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			cd /home/docker/moontv/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			rm -rf /home/docker/moontv
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="당신의 음악 요정으로, 음악 관리를 더 잘 할 수 있도록 돕습니다."
		local docker_url="공식 웹사이트 소개: https://github.com/foamzou/melody"
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

		local docker_describe="중국 DOS 게임 모음 웹사이트입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/rwv/chinese-dos-games"
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

			read -e -p "로그인 사용자 이름 설정:" app_use
			read -e -p "로그인 비밀번호 설정:" app_passwd

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

		local docker_describe="迅雷는 오프라인 고속 BT 자석 다운로드 도구입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/cnk3x/xunlei"
		local docker_use="echo "휴대폰으로 썬더에 로그인하고, 초대 코드를 입력하세요. 초대 코드: 迅雷牛通""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  78|PandaWiki)

		local app_id="78"
		local app_name="PandaWiki"
		local app_text="PandaWiki는 AI 대규모 모델 기반의 오픈 소스 지능형 문서 관리 시스템이며, 포트를 직접 지정하여 배포하지 않는 것이 좋습니다."
		local app_url="공식 소개: https://github.com/chaitin/PandaWiki"
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

		local docker_describe="Beszel은 가볍고 사용하기 쉬운 서버 모니터링 도구입니다."
		local docker_url="공식 홈페이지 소개 : https://beszel.dev/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  80|linkwarden)

		  local app_id="80"
		  local app_name="linkwarden 북마크 관리"
		  local app_text="오픈 소스 자체 호스팅 북마크 관리 플랫폼으로, 태그, 검색 및 팀 협업을 지원합니다."
		  local app_url="공식 웹사이트: https://linkwarden.app/"
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
			  echo "설치가 완료되었습니다."
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
			  echo "애플리케이션이 제거되었습니다."
		  }

		  docker_app_plus

		  ;;



	  81|jitsi)
		  local app_id="81"
		  local app_name="JitsiMeet 화상 회의"
		  local app_text="오픈 소스 보안 비디오 회의 솔루션으로, 다자간 온라인 회의, 화면 공유 및 암호화 통신을 지원합니다."
		  local app_url="공식 웹사이트: https://jitsi.org/"
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
			  echo "애플리케이션이 제거되었습니다."
		  }

		  docker_app_plus

		  ;;



	  82|gpt-load)

		local app_id="82"
		local docker_name="gpt-load"
		local docker_img="tbphp/gpt-load:latest"
		local docker_port=8082

		docker_rum() {

			read -e -p "${docker_name} 로그인 키(sk로 시작하는 문자 및 숫자 조합) 설정(예: sk-159kejilionyyds163):" app_passwd

			mkdir -p /home/docker/gpt-load && \
			docker run -d --name gpt-load \
				-p ${docker_port}:3001 \
				-e AUTH_KEY=${app_passwd} \
				-v "/home/docker/gpt-load/data":/app/data \
				tbphp/gpt-load:latest

		}

		local docker_describe="고성능 AI 인터페이스 투명 프록시 서비스입니다."
		local docker_url="공식 웹사이트 소개: https://www.gpt-load.com/"
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

		local docker_describe="경량형 자체 호스팅 서버 모니터링 도구"
		local docker_url="공식 웹사이트 소개: https://github.com/komari-monitor/komari/tree/main"
		local docker_use="echo "기본 계정: admin  기본 비밀번호: 1212156""
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

		local docker_describe="오픈 소스 개인 구독 추적기, 재무 관리에 사용 가능"
		local docker_url="공식 웹사이트 소개: https://github.com/ellite/Wallos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  85|immich)

		  local app_id="85"
		  local app_name="immich 이미지/비디오 관리자"
		  local app_text="고성능 자체 호스팅 사진 및 비디오 관리 솔루션."
		  local app_url="공식 웹사이트 소개: https://github.com/immich-app/immich"
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
			  echo "설치가 완료되었습니다."
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
		  }

		  docker_app_uninstall() {
			  cd /home/docker/${docker_name} && docker compose down --rmi all
			  rm -rf /home/docker/${docker_name}
			  echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="오픈 소스 미디어 서버 소프트웨어"
		local docker_url="공식 웹사이트 소개: https://jellyfin.org/"
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

		local docker_describe="원격으로 영화와 라이브 스트리밍을 함께 시청하는 프로그램입니다. 동기화 시청, 라이브 스트리밍, 채팅 등의 기능을 제공합니다."
		local docker_url="공식 웹사이트 소개: https://github.com/synctv-org/synctv"
		local docker_use="echo "초기 계정 및 비밀번호: root  로그인 후 즉시 로그인 비밀번호를 변경하세요""
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

		local docker_describe="오픈 소스, 무료 자체 구축 라이브 스트리밍 플랫폼"
		local docker_url="공식 웹사이트 소개: https://owncast.online"
		local docker_use="echo "접속 주소 뒤에 /admin을 붙여 관리자 페이지에 접속하세요""
		local docker_passwd="echo "초기 계정: admin  초기 비밀번호: abc123  로그인 후 즉시 로그인 비밀번호를 변경하세요""
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

		local docker_describe="익명 비밀번호 공유 텍스트 및 문서, 택배 수령과 같이 문서를 수령"
		local docker_url="공식 웹사이트 소개: https://github.com/vastsa/FileCodeBox"
		local docker_use="echo "접속 주소 뒤에 /#/admin을 붙여 관리자 페이지에 접속하세요""
		local docker_passwd="echo "관리자 비밀번호: FileCodeBox2023""
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

			echo "초기 사용자 또는 관리자를 생성합니다. 다음 내용에 대한 사용자 이름과 비밀번호, 그리고 관리자인지 여부를 설정하십시오."
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

		local docker_describe="Matrix는 탈중앙화된 채팅 프로토콜입니다."
		local docker_url="공식 웹사이트 소개: https://matrix.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  91|gitea)

		local app_id="91"

		local app_name="gitea 비공개 코드 저장소"
		local app_text="무료 차세대 코드 호스팅 플랫폼으로, GitHub와 유사한 사용 경험을 제공합니다."
		local app_url="비디오 소개: https://github.com/go-gitea/gitea"
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
			echo "설치가 완료되었습니다."
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			cd /home/docker/gitea/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			rm -rf /home/docker/gitea
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="웹 기반 문서 관리자"
		local docker_url="공식 웹사이트 소개: https://filebrowser.org/"
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

		local docker_describe="미니멀한 정적 파일 서버, 업로드 및 다운로드 지원"
		local docker_url="공식 웹사이트 소개: https://github.com/sigoden/dufs"
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

			read -e -p "로그인 사용자 이름 설정:" app_use
			read -e -p "로그인 비밀번호 설정:" app_passwd

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}/downloads:/app/Downloads \
			  -v /home/docker/${docker_name}/storage:/app/storage \
			  -p ${docker_port}:9999 \
			  ${docker_img} -u ${app_use} -p ${app_passwd}

		}

		local docker_describe="분산형 고속 다운로드 도구, 다양한 프로토콜 지원"
		local docker_url="공식 웹사이트 소개: https://github.com/GopeedLab/gopeed"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;



	  95|paperless)

		local app_id="95"

		local app_name="paperless 문서 관리 플랫폼"
		local app_text="오픈 소스 전자 문서 관리 시스템으로, 종이 문서를 디지털화하고 관리하는 데 주로 사용됩니다."
		local app_url="비디오 소개: https://docs.paperless-ngx.com/"
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
			echo "설치가 완료되었습니다."
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			rm -rf /home/docker/paperless
			echo "애플리케이션이 제거되었습니다."
		}

		docker_app_plus

		  ;;



	  96|2fauth)

		local app_id="96"

		local app_name="2FAuth 자체 구축 2단계 인증기"
		local app_text="자가 호스팅되는 2단계 인증(2FA) 계정 관리 및 인증 코드 생성 도구입니다."
		local app_url="공식 웹사이트: https://github.com/Bubka/2FAuth"
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
			echo "설치가 완료되었습니다."
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			rm -rf /home/docker/2fauth
			echo "애플리케이션이 제거되었습니다."
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
		echo -e "${gl_huang}모든 클라이언트 QR 코드 구성: ${gl_bai}"
		docker exec -it wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
		sleep 2
		echo
		echo -e "${gl_huang}모든 클라이언트 구성 코드: ${gl_bai}"
		docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
		sleep 2
		echo -e "${gl_lv}${COUNT}개의 클라이언트 구성 전체 출력, 사용 방법은 다음과 같습니다: ${gl_bai}"
		echo -e "${gl_lv}1. 휴대폰에서 wg 앱을 다운로드하고 위의 QR 코드를 스캔하여 네트워크에 빠르게 연결할 수 있습니다${gl_bai}"
		echo -e "${gl_lv}2. Windows에서 클라이언트를 다운로드하고 구성 코드를 복사하여 네트워크에 연결합니다.${gl_bai}"
		echo -e "${gl_lv}3. Linux에서 스크립트를 사용하여 WG 클라이언트를 배포하고 구성 코드를 복사하여 네트워크에 연결합니다.${gl_bai}"
		echo -e "${gl_lv}공식 클라이언트 다운로드 방법: https://www.wireguard.com/install/${gl_bai}"
		break_end

		}

		local docker_describe="현대적이고 고성능의 가상 사설망 도구"
		local docker_url="공식 웹사이트 소개: https://www.wireguard.com/"
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

			echo "클라이언트 구성을 붙여넣고 Enter 키를 두 번 연속으로 눌러 저장하십시오:"

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

			echo "클라이언트 구성이 $CONFIG_FILE에 저장되었습니다."

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

		local docker_describe="현대적이고 고성능의 가상 사설망 도구"
		local docker_url="공식 웹사이트 소개: https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  99|dsm)

		local app_id="99"

		local app_name="dsm Synology 가상 머신"
		local app_text="Docker 컨테이너의 가상 DSM"
		local app_url="공식 웹사이트: https://github.com/vdsm/virtual-dsm"
		local docker_name="dsm"
		local docker_port="8099"
		local app_size="16"

		docker_app_install() {

			read -e -p "CPU 코어 수 설정(기본값 2):" CPU_CORES
			local CPU_CORES=${CPU_CORES:-2}

			read -e -p "메모리 크기 설정(기본값 4G):" RAM_SIZE
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
			echo "설치가 완료되었습니다."
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			rm -rf /home/docker/dsm
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="오픈 소스 P2P 파일 동기화 도구, Dropbox, Resilio Sync와 유사하지만 완전히 탈중앙화됨."
		local docker_url="공식 웹사이트 소개: https://github.com/syncthing/syncthing"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  101|moneyprinterturbo)
		local app_id="101"
		local app_name="AI 비디오 생성 도구"
		local app_text="MoneyPrinterTurbo는 AI 대규모 모델을 사용하여 고화질 짧은 비디오를 합성하는 도구입니다."
		local app_url="공식 웹사이트: https://github.com/harry0703/MoneyPrinterTurbo"
		local docker_name="moneyprinterturbo"
		local docker_port="8101"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/harry0703/MoneyPrinterTurbo.git && cd MoneyPrinterTurbo/
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml

			docker compose up -d
			clear
			echo "설치가 완료되었습니다."
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
			echo "애플리케이션이 제거되었습니다."
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

		local docker_describe="독립적으로 배포할 수 있는 개인 클라우드 소셜 미디어 채팅 서비스"
		local docker_url="공식 웹사이트 소개: https://github.com/Privoce/vocechat-web"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  103|umami)
		local app_id="103"
		local app_name="Umami 웹사이트 통계 도구"
		local app_text="오픈 소스, 경량, 개인 정보 보호 친화적인 웹사이트 분석 도구로, Google Analytics와 유사합니다."
		local app_url="공식 웹사이트: https://github.com/umami-software/umami"
		local docker_name="umami-umami-1"
		local docker_port="8103"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone https://github.com/umami-software/umami.git && cd umami
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/umami/docker-compose.yml

			docker compose up -d
			clear
			echo "설치가 완료되었습니다."
			check_docker_app_ip
			echo "초기 사용자 이름: admin"
			echo "초기 비밀번호: umami"
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
			echo "애플리케이션이 제거되었습니다."
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

			read -e -p "로그인 비밀번호 설정:" app_passwd

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

		local docker_describe="思源 노트는 개인 정보 보호를 우선시하는 지식 관리 시스템입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/siyuan-note/siyuan"
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

		local docker_describe="강력한 오픈 소스 화이트보드 도구, 마인드 맵, 흐름도 등을 통합."
		local docker_url="공식 웹사이트 소개: https://github.com/plait-board/drawnix"
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

		local docker_describe="PanSou는 고성능 웹 디스크 리소스 검색 API 서비스입니다."
		local docker_url="공식 웹사이트 소개: https://github.com/fish2018/pansou"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;




	  b)
	  	clear
	  	send_stats "全部应用备份"

	  	local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
	  	echo -e "${gl_huang}$backup_filename 백업 중...${gl_bai}"
	  	cd / && tar czvf "$backup_filename" home

	  	while true; do
			clear
			echo "백업 파일 생성됨: /$backup_filename"
			read -e -p "백업 데이터를 원격 서버로 전송하시겠습니까? (y/N):" choice
			case "$choice" in
			  [Yy])
				read -e -p "원격 서버 IP를 입력하세요:" remote_ip
				read -e -p "대상 서버 SSH 포트 [기본값 22]:" TARGET_PORT
				local TARGET_PORT=${TARGET_PORT:-22}

				if [ -z "$remote_ip" ]; then
				  echo "오류: 원격 서버 IP를 입력하세요."
				  continue
				fi
				local latest_tar=$(ls -t /app*.tar.gz | head -1)
				if [ -n "$latest_tar" ]; then
				  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				  sleep 2  # 添加等待时间
				  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
				  echo "파일이 원격 서버/루트 디렉터리로 전송되었습니다."
				else
				  echo "전송할 파일이 없습니다."
				fi
				break
				;;
			  *)
				echo "주의: 현재 백업은 Docker 프로젝트만 포함하며, 보타, 1panel 등 웹사이트 구축 패널의 데이터 백업은 포함하지 않습니다."
				break
				;;
			esac
	  	done

		  ;;

	  r)
	  	root_use
	  	send_stats "全部应用还原"
	  	echo "사용 가능한 애플리케이션 백업"
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
		  	  echo -e "${gl_huang}$filename 압축 해제 중...${gl_bai}"
		  	  cd / && tar -xzf "$filename"
			  echo "애플리케이션 데이터가 복원되었습니다. 현재 지정된 애플리케이션 메뉴로 수동으로 들어가 애플리케이션을 업데이트하면 애플리케이션을 복원할 수 있습니다."
	  	else
			  echo "압축 파일을 찾을 수 없습니다."
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
	  echo -e "백그라운드 작업 공간"
	  echo -e "시스템은 백그라운드에서 지속적으로 실행할 수 있는 작업 공간을 제공하며, 장시간 작업을 실행하는 데 사용할 수 있습니다."
	  echo -e "SSH 연결을 끊더라도 작업 공간의 작업은 중단되지 않고 백그라운드에서 지속적으로 실행됩니다."
	  echo -e "${gl_huang}팁: ${gl_bai}작업 공간에 들어간 후 Ctrl+b를 누른 다음 d를 단독으로 눌러 작업 공간을 종료하십시오!"
	  echo -e "${gl_kjlan}------------------------"
	  echo "현재 존재하는 워크스페이스 목록"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}1번 작업 공간"
	  echo -e "${gl_kjlan}2.   ${gl_bai}2번 작업 영역"
	  echo -e "${gl_kjlan}3.   ${gl_bai}3번 작업 영역"
	  echo -e "${gl_kjlan}4.   ${gl_bai}4번 작업 영역"
	  echo -e "${gl_kjlan}5.   ${gl_bai}5번 작업 영역"
	  echo -e "${gl_kjlan}6.   ${gl_bai}6번 작업 영역"
	  echo -e "${gl_kjlan}7.   ${gl_bai}7번 작업 영역"
	  echo -e "${gl_kjlan}8.   ${gl_bai}8번 작업 영역"
	  echo -e "${gl_kjlan}9.   ${gl_bai}9번 작업 영역"
	  echo -e "${gl_kjlan}10.  ${gl_bai}10번 작업 영역"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH 상주 모드 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}작업 영역 생성/진입"
	  echo -e "${gl_kjlan}23.  ${gl_bai}백그라운드 작업 영역에 명령어 주입"
	  echo -e "${gl_kjlan}24.  ${gl_bai}지정된 작업 영역 삭제"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice

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
			  echo -e "SSH 상주 모드 ${tmux_sshd_status}"
			  echo "열면 SSH 연결 후 즉시 상주 모드로 들어가 이전에 작업하던 상태로 돌아갑니다."
			  echo "------------------------"
			  echo "1. 활성화                  2. 비활성화"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아가기"
			  echo "------------------------"
			  read -e -p "선택을 입력하세요: " gongzuoqu_del
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
			  read -e -p "작업 공간 이름을 입력하세요(예: 1001 kj001 work1):" SESSION_NAME
			  tmux_run
			  send_stats "自定义工作区"
			  ;;


		  23)
			  read -e -p "백그라운드에서 실행할 명령을 입력하세요(예: curl -fsSL https://get.docker.com | sh):" tmuxd
			  tmux_run_d
			  send_stats "注入命令到后台工作区"
			  ;;

		  24)
			  read -e -p "삭제할 작업 공간 이름을 입력하세요:" gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "删除工作区"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # send_stats "系统工具"
	  echo -e "시스템 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}스크립트 시작 단축키 설정            ${gl_kjlan}2.   ${gl_bai}로그인 비밀번호 수정"
	  echo -e "${gl_kjlan}3.   ${gl_bai}root 비밀번호 로그인 모드            ${gl_kjlan}4.   ${gl_bai}Python 특정 버전 설치"
	  echo -e "${gl_kjlan}5.   ${gl_bai}모든 포트 열기                       ${gl_kjlan}6.   ${gl_bai}SSH 연결 포트 수정"
	  echo -e "${gl_kjlan}7.   ${gl_bai}DNS 주소 최적화                      ${gl_kjlan}8.   ${gl_bai}원클릭 시스템 재설치 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}root 계정의 새 계정 생성 비활성화    ${gl_kjlan}10.  ${gl_bai}IPv4/IPv6 우선 순위 전환"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}포트 점유 상태 확인                  ${gl_kjlan}12.  ${gl_bai}가상 메모리 크기 변경"
	  echo -e "${gl_kjlan}13.  ${gl_bai}사용자 관리                          ${gl_kjlan}14.  ${gl_bai}사용자/비밀번호 생성기"
	  echo -e "${gl_kjlan}15.  ${gl_bai}시스템 시간대 조정                   ${gl_kjlan}16.  ${gl_bai}BBRv3 가속 설정"
	  echo -e "${gl_kjlan}17.  ${gl_bai}방화벽 고급 관리자                   ${gl_kjlan}18.  ${gl_bai}호스트 이름 변경"
	  echo -e "${gl_kjlan}19.  ${gl_bai}시스템 업데이트 소스 전환            ${gl_kjlan}20.  ${gl_bai}예약 작업 관리"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}로컬 Host 파싱                       ${gl_kjlan}22.  ${gl_bai}SSH 방어 프로그램"
	  echo -e "${gl_kjlan}23.  ${gl_bai}트래픽 제한 자동 종료                ${gl_kjlan}24.  ${gl_bai}root 개인 키 로그인 모드"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot 시스템 모니터링 경고          ${gl_kjlan}26.  ${gl_bai}OpenSSH 심각한 취약점 수정"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat 계열 Linux 커널 업그레이드   ${gl_kjlan}28.  ${gl_bai}Linux 시스템 커널 파라미터 최적화 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}바이러스 스캔 도구 ${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}파일 관리자"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}시스템 언어 전환                     ${gl_kjlan}32.  ${gl_bai}명령줄 꾸미기 도구 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}시스템 휴지통 설정                   ${gl_kjlan}34.  ${gl_bai}시스템 백업 및 복구"
	  echo -e "${gl_kjlan}35.  ${gl_bai}SSH 원격 연결 도구                   ${gl_kjlan}36.  ${gl_bai}하드 디스크 파티션 관리 도구"
	  echo -e "${gl_kjlan}37.  ${gl_bai}명령줄 기록                          ${gl_kjlan}38.  ${gl_bai}rsync 원격 동기화 도구"
	  echo -e "${gl_kjlan}39.  ${gl_bai}명령 즐겨찾기 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}게시판                               ${gl_kjlan}66.  ${gl_bai}원스톱 시스템 최적화 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}서버 재시작                          ${gl_kjlan}100. ${gl_bai}개인 정보 보호 및 보안"
	  echo -e "${gl_kjlan}101. ${gl_bai}k 명령 고급 사용법 ${gl_huang}★${gl_bai}                 ${gl_kjlan}102. ${gl_bai}KejiLion 스크립트 제거"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "단축키를 입력하세요(0을 입력하여 종료):" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "단축키 설정 완료"
				  send_stats "脚本快捷键已设置"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "设置你的登录密码"
			  echo "로그인 비밀번호 설정"
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
			echo "Python 버전 관리"
			echo "비디오 소개: https://youtu.be/E4NhofhUlRU"
			echo "---------------------------------------"
			echo "이 기능을 사용하면 Python 공식에서 지원하는 모든 버전을 원활하게 설치할 수 있습니다!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "현재 Python 버전 번호: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "권장 버전: 3.12    3.11    3.10    3.9    3.8    2.7"
			echo "더 많은 버전 확인: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "설치할 Python 버전 번호를 입력하세요(0을 입력하여 종료):" py_new_v


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
					echo "알 수 없는 패키지 관리자!"
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
			echo -e "현재 Python 버전 번호: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			  ;;

		  5)
			  root_use
			  send_stats "开放端口"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "포트가 모두 열렸습니다"

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
				echo -e "현재 SSH 연결 포트 번호는: ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "포트 번호 범위는 1에서 65535 사이의 숫자입니다. (0을 입력하여 로그아웃합니다)"

				# 提示用户输入新的 SSH 端口号
				read -e -p "새 SSH 포트 번호를 입력하세요:" new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "포트 번호가 유효하지 않습니다. 1에서 65535 사이의 숫자를 입력하십시오."
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "잘못된 입력입니다. 숫자를 입력하십시오."
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
			read -e -p "새 사용자 이름을 입력하세요(0을 입력하여 종료):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			install sudo

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "작업이 완료되었습니다."
			;;


		  10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "IPv4/IPv6 우선 순위 설정"
				echo "------------------------"


				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "현재 네트워크 우선순위 설정: ${gl_huang}IPv4${gl_bai} 우선"
				else
					echo -e "현재 네트워크 우선순위 설정: ${gl_huang}IPv6${gl_bai} 우선"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 우선          2. IPv6 우선          3. IPv6 복구 도구"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아가기"
				echo "------------------------"
				read -e -p "우선 순위 네트워크 선택:" choice

				case $choice in
					1)
						prefer_ipv4
						;;
					2)
						rm -f /etc/gai.conf
						echo "IPv6 우선으로 전환됨"
						send_stats "已切换为 IPv6 优先"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "이 기능은 jhb 대가가 제공했으며, 그에게 감사드립니다!"
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
				echo "가상 메모리 설정"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "현재 가상 메모리: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 1024M 구성         2. 2048M 구성         3. 4096M 구성         4. 사용자 지정 크기"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아가기"
				echo "------------------------"
				read -e -p "선택을 입력하세요: " choice

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
					read -e -p "가상 메모리 크기를 입력하세요(단위 M):" new_swap
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
				echo "사용자 목록"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "계정 작업"
				  echo "------------------------"
				  echo "1. 일반 계정 생성             2. 고급 계정 생성"
				  echo "------------------------"
				  echo "3. 최고 권한 부여             4. 최고 권한 해제"
				  echo "------------------------"
				  echo "5. 계정 삭제"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " sub_choice

				  case $sub_choice in
					  1)
					   # 提示用户输入新用户名
					   read -e -p "새 사용자 이름 입력:" new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "작업이 완료되었습니다."
						  ;;

					  2)
					   # 提示用户输入新用户名
					   read -e -p "새 사용자 이름 입력:" new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # 赋予新用户sudo权限
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo

					   echo "작업이 완료되었습니다."

						  ;;
					  3)
					   read -e -p "사용자 이름을 입력하세요:" username
					   # 赋予新用户sudo权限
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo
						  ;;
					  4)
					   read -e -p "사용자 이름을 입력하세요:" username
					   # 从sudoers文件中移除用户的sudo权限
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "삭제할 사용자 이름을 입력하세요:" username
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
			echo "임의 사용자 이름"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "임의 사용자 이름 $i: $username"
			done

			echo ""
			echo "임의 이름"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "임의 사용자 이름 $i: $user_name"
			done

			echo ""
			echo "임의 UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "임의 UUID $i: $uuid"
			done

			echo ""
			echo "16자리 임의 비밀번호"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "임의 비밀번호 $i: $password"
			done

			echo ""
			echo "32자리 임의 비밀번호"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "임의 비밀번호 $i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "시스템 시간 정보"

				# 获取当前系统时区
				local timezone=$(current_timezone)

				# 获取当前系统时间
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 显示时区和时间
				echo "현재 시스템 시간대: $timezone"
				echo "현재 시스템 시간: $current_time"

				echo ""
				echo "시간대 변경"
				echo "------------------------"
				echo "아시아"
				echo "1. 중국 상하이 시간             2. 홍콩 시간"
				echo "3. 일본 도쿄 시간             4. 한국 서울 시간"
				echo "5. 싱가포르 시간               6. 인도 콜카타 시간"
				echo "7. 아랍에미리트 두바이 시간           8. 호주 시드니 시간"
				echo "9. 태국 방콕 시간"
				echo "------------------------"
				echo "유럽"
				echo "11. 영국 런던 시간             12. 프랑스 파리 시간"
				echo "13. 독일 베를린 시간             14. 러시아 모스크바 시간"
				echo "15. 네덜란드 위트레흐트 시간       16. 스페인 마드리드 시간"
				echo "------------------------"
				echo "아메리카"
				echo "21. 미국 서부 시간             22. 미국 동부 시간"
				echo "23. 캐나다 시간               24. 멕시코 시간"
				echo "25. 브라질 시간                 26. 아르헨티나 시간"
				echo "------------------------"
				echo "31. UTC 세계 표준시"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아가기"
				echo "------------------------"
				read -e -p "선택을 입력하세요: " sub_choice


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
			  echo -e "현재 호스트 이름: ${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "새 호스트 이름을 입력하세요 (0을 입력하여 종료):" new_hostname
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

				  echo "호스트 이름이 $new_hostname으로 변경되었습니다."
				  send_stats "主机名已更改"
				  sleep 1
			  else
				  echo "로그아웃되었습니다. 호스트 이름은 변경되지 않았습니다."
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "换系统更新源"
		  clear
		  echo "업데이트 소스 영역 선택"
		  echo "LinuxMirrors 연결하여 시스템 업데이트 소스 전환"
		  echo "------------------------"
		  echo "1. 중국 본토【기본】          2. 중국 본토【교육망】          3. 중국 외 지역"
		  echo "------------------------"
		  echo "0. 이전 메뉴로 돌아가기"
		  echo "------------------------"
		  read -e -p "선택을 입력하세요:" choice

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
				  echo "취소되었습니다."
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "定时任务管理"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "예약 작업 목록"
				  crontab -l
				  echo ""
				  echo "작업"
				  echo "------------------------"
				  echo "1. 예약 작업 추가              2. 예약 작업 삭제              3. 예약 작업 편집"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "새 작업의 실행 명령을 입력하세요:" newquest
						  echo "------------------------"
						  echo "1. 매월 작업                 2. 매주 작업"
						  echo "3. 매일 작업                 4. 매시간 작업"
						  echo "------------------------"
						  read -e -p "선택을 입력하세요: " dingshi

						  case $dingshi in
							  1)
								  read -e -p "매달 며칠에 작업을 실행하시겠습니까? (1-30):" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "매주 며칠에 작업을 실행하시겠습니까? (0-6, 0은 일요일):" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "매일 몇 시에 작업을 실행하시겠습니까? (시간, 0-23):" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "매시간 몇 분에 작업을 실행하시겠습니까? (분, 0-60):" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "添加定时任务"
						  ;;
					  2)
						  read -e -p "삭제할 작업의 키워드를 입력하세요:" kquest
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
				  echo "로컬 Host 파싱 목록"
				  echo "여기에서 파싱 비교를 추가하면 동적 파싱을 사용하지 않습니다."
				  cat /etc/hosts
				  echo ""
				  echo "작업"
				  echo "------------------------"
				  echo "1.  파싱 추가              2. 파싱 주소 삭제"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " host_dns

				  case $host_dns in
					  1)
						  read -e -p "새 파싱 레코드 형식을 입력하세요: 110.25.5.33 kejilion.pro:" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "本地host解析新增"

						  ;;
					  2)
						  read -e -p "삭제할 파싱 내용 키워드를 입력하세요:" delhost
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
				echo -e "SSH 방어 프로그램 $check_f2b_status"
				echo "Fail2ban은 SSH 무차별 대입 공격 방지 도구입니다."
				echo "공식 웹사이트 소개: ${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. 방어 프로그램 설치"
				echo "------------------------"
				echo "2. SSH 차단 기록 보기"
				echo "3. 로그 실시간 모니터링"
				echo "------------------------"
				echo "9. 방어 프로그램 제거"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아가기"
				echo "------------------------"
				read -e -p "선택을 입력하세요: " sub_choice
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
						echo "Fail2ban 방어 프로그램이 제거되었습니다"
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
				echo "트래픽 제한 종료 기능"
				echo "비디오 소개: https://youtu.be/mOKwVzK0U6I"
				echo "------------------------------------------------"
				echo "현재 트래픽 사용량, 서버 재시작 시 트래픽 계산이 초기화됩니다!"
				output_status
				echo -e "${gl_kjlan}총 수신:${gl_bai}$rx"
				echo -e "${gl_kjlan}총 전송:${gl_bai}$tx"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}현재 설정된 수신 트래픽 제한 임계값은:${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}현재 설정된 전송 트래픽 제한 임계값은:${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}현재 트래픽 제한 종료 기능이 활성화되지 않았습니다.${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "시스템은 매분 실제 트래픽이 임계값에 도달하는지 확인하고, 도달하면 자동으로 서버를 종료합니다!"
				echo "------------------------"
				echo "1. 트래픽 제한 종료 기능 활성화          2. 트래픽 제한 종료 기능 비활성화"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아가기"
				echo "------------------------"
				read -e -p "선택을 입력하세요: " Limiting

				case "$Limiting" in
				  1)
					# 输入新的虚拟内存大小
					echo "실제 서버 트래픽이 100G인 경우 임계값을 95G로 설정하여 트래픽 오차 또는 초과를 방지하기 위해 미리 종료할 수 있습니다."
					read -e -p "유입 트래픽 임계값을 입력하세요 (단위: G, 기본값 100G):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "유출 트래픽 임계값을 입력하세요 (단위: G, 기본값 100G):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "트래픽 재설정 날짜를 입력하세요 (기본값: 매월 1일 재설정):" cz_day
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
					echo "전류 제한 종료가 설정되었습니다."
					send_stats "限流关机已设置"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "전류 제한 종료 기능이 꺼졌습니다."
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
			  	  echo "root 개인 키 로그인 모드"
			  	  echo "비디오 소개: https://youtu.be/4wAUIp7pN6I?t=209"
			  	  echo "------------------------------------------------"
			  	  echo "키 쌍을 생성하여 더 안전한 SSH 로그인을 사용할 수 있습니다."
				  echo "------------------------"
				  echo "1. 새 키 생성              2. 기존 키 가져오기              3. 로컬 키 보기"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택을 입력하세요: " host_dns

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
						echo "공개 키 정보"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "개인 키 정보"
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
			  echo "TG-bot 모니터링 및 경고 기능"
			  echo "비디오 소개: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "Telegram 봇 API와 경고를 받을 사용자 ID를 구성하면 로컬 CPU, 메모리, 하드 디스크, 트래픽, SSH 로그인을 실시간으로 모니터링하고 경고할 수 있습니다."
			  echo "임계값에 도달하면 사용자에게 경고 메시지가 전송됩니다."
			  echo -e "${gl_hui}- 트래픽에 대해 서버를 재시작하면 다시 계산됩니다.-${gl_bai}"
			  read -e -p "계속하시겠습니까? \(y/N\):" choice

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
				  echo "TG-bot 경고 시스템이 시작되었습니다."
				  echo -e "${gl_hui}루트 디렉터리의 TG-check-notify.sh 경고 파일을 다른 장치에 직접 배치하여 사용할 수도 있습니다!${gl_bai}"
				  ;;
				[Nn])
				  echo "취소되었습니다."
				  ;;
				*)
				  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
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
			echo "KejiLion 공식 게시판을 방문하여 스크립트에 대한 아이디어가 있으면 자유롭게 의견을 교환하십시오!"
			echo "https://board.kejilion.pro"
			echo "공용 암호: kejilion.sh"
			  ;;

		  66)

			  root_use
			  send_stats "一条龙调优"
			  echo "원스톱 시스템 최적화"
			  echo "------------------------------------------------"
			  echo "다음 내용에 대한 작업 및 최적화를 수행합니다."
			  echo "1. 시스템을 최신 버전으로 업데이트"
			  echo "2. 시스템 정크 파일 정리"
			  echo -e "3. 가상 메모리 설정 ${gl_huang}1G${gl_bai}"
			  echo -e "4. SSH 포트 번호를 ${gl_huang}5522${gl_bai}로 설정"
			  echo -e "5. 모든 포트 열기"
			  echo -e "6. ${gl_huang}BBR${gl_bai} 가속 켜기"
			  echo -e "7. 시간대를 ${gl_huang}상하이${gl_bai}로 설정"
			  echo -e "8. 자동 DNS 주소 최적화 ${gl_huang}비중국 지역: 1.1.1.1 8.8.8.8   중국 지역: 223.5.5.5${gl_bai}"
			  echo -e "9. 기본 도구 설치 ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10. Linux 시스템 커널 파라미터 최적화를 ${gl_huang}균형 최적화 모드${gl_bai}로 전환"
			  echo "------------------------------------------------"
			  read -e -p "원클릭 유지보수를 진행하시겠습니까? (y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "一条龙调优启动"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 01/10. 시스템을 최신으로 업데이트"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 02/10. 시스템 정크 파일 정리"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 03/10. 가상 메모리 ${gl_huang}1G${gl_bai} 설정"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 04/10. SSH 포트 번호를 ${gl_huang}5522${gl_bai}로 설정"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 05/10. 모든 포트 열기"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 06/10. ${gl_huang}BBR${gl_bai} 가속 활성화"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 07/10. 시간대를 ${gl_huang}상하이${gl_bai}로 설정"

				  echo "------------------------------------------------"
				  auto_optimize_dns
				  echo -e "[${gl_lv}OK${gl_bai}] 08/10. DNS 주소 자동 최적화 ${gl_huang}중국 외 지역: 1.1.1.1 8.8.8.8   중국 지역: 223.5.5.5${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 09/10. 기본 도구 ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai} 설치"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10. Linux 시스템 커널 파라미터 최적화"
				  echo -e "${gl_lv}원스톱 시스템 최적화 완료${gl_bai}"

				  ;;
				[Nn])
				  echo "취소되었습니다."
				  ;;
				*)
				  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
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
			  	local status_message="${gl_lv} 데이터 수집 중 ${gl_bai}"
			  elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_hui} 수집이 닫혔습니다 ${gl_bai}"
			  else
			  	local status_message="알 수 없는 상태"
			  fi

			  echo "개인 정보 보호 및 보안"
			  echo "스크립트는 사용자 기능 사용 데이터를 수집하여 스크립트 경험을 최적화하고 더 재미있고 유용한 기능을 만듭니다."
			  echo "스크립트 버전 번호, 사용 시간, 시스템 버전, CPU 아키텍처, 기기가 속한 국가 및 사용된 기능 이름을 수집합니다."
			  echo "------------------------------------------------"
			  echo -e "현재 상태: $status_message"
			  echo "--------------------"
			  echo "1. 수집 시작"
			  echo "2. 수집 중지"
			  echo "--------------------"
			  echo "0. 이전 메뉴로 돌아가기"
			  echo "--------------------"
			  read -e -p "선택을 입력하세요: " sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "수집이 시작되었습니다."
					  send_stats "隐私与安全已开启采集"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "수집이 중지되었습니다."
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
			  echo "KejiLion 스크립트 제거"
			  echo "------------------------------------------------"
			  echo "KejiLion 스크립트를 완전히 제거하며 다른 기능에는 영향을 미치지 않습니다."
			  read -e -p "계속하시겠습니까? \(y/N\):" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "스크립트가 제거되었습니다. 안녕!"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "취소되었습니다."
				  ;;
				*)
				  echo "잘못된 선택입니다. Y 또는 N을 입력하세요."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "잘못된 입력!"
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
		echo "파일 관리자"
		echo "------------------------"
		echo "현재 경로"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. 디렉토리로 이동           2. 디렉토리 생성             3. 디렉토리 권한 수정         4. 디렉토리 이름 변경"
		echo "5. 디렉토리 삭제           6. 이전 메뉴 디렉토리로 돌아가기"
		echo "------------------------"
		echo "11. 파일 생성           12. 파일 편집             13. 파일 권한 수정         14. 파일 이름 변경"
		echo "15. 파일 삭제"
		echo "------------------------"
		echo "21. 파일/디렉토리 압축       22. 파일/디렉토리 압축 해제       23. 파일/디렉토리 이동         24. 파일/디렉토리 복사"
		echo "25. 다른 서버로 파일 전송"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택을 입력하세요: " Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "디렉토리 이름을 입력하세요:" dirname
				cd "$dirname" 2>/dev/null || echo "디렉토리에 들어갈 수 없습니다."
				send_stats "进入目录"
				;;
			2)  # 创建目录
				read -e -p "생성할 디렉토리 이름을 입력하세요:" dirname
				mkdir -p "$dirname" && echo "디렉토리가 생성되었습니다." || echo "생성 실패"
				send_stats "创建目录"
				;;
			3)  # 修改目录权限
				read -e -p "디렉토리 이름을 입력하세요:" dirname
				read -e -p "권한을 입력하세요 (예: 755):" perm
				chmod "$perm" "$dirname" && echo "권한이 수정되었습니다." || echo "수정 실패"
				send_stats "修改目录权限"
				;;
			4)  # 重命名目录
				read -e -p "현재 디렉토리 이름을 입력하세요:" current_name
				read -e -p "새 디렉토리 이름을 입력하세요:" new_name
				mv "$current_name" "$new_name" && echo "디렉터리가 이름을 변경했습니다." || echo "이름 변경 실패"
				send_stats "重命名目录"
				;;
			5)  # 删除目录
				read -e -p "삭제할 디렉토리 이름을 입력하세요:" dirname
				rm -rf "$dirname" && echo "디렉터리가 삭제되었습니다." || echo "삭제 실패"
				send_stats "删除目录"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "返回上一级选单目录"
				;;
			11) # 创建文件
				read -e -p "생성할 파일 이름을 입력하세요:" filename
				touch "$filename" && echo "파일이 생성되었습니다." || echo "생성 실패"
				send_stats "创建文件"
				;;
			12) # 编辑文件
				read -e -p "편집할 파일 이름을 입력하세요:" filename
				install nano
				nano "$filename"
				send_stats "编辑文件"
				;;
			13) # 修改文件权限
				read -e -p "파일 이름을 입력하세요:" filename
				read -e -p "권한을 입력하세요 (예: 755):" perm
				chmod "$perm" "$filename" && echo "권한이 수정되었습니다." || echo "수정 실패"
				send_stats "修改文件权限"
				;;
			14) # 重命名文件
				read -e -p "현재 파일 이름을 입력하세요:" current_name
				read -e -p "새 파일 이름을 입력하세요:" new_name
				mv "$current_name" "$new_name" && echo "파일이 이름을 변경했습니다." || echo "이름 변경 실패"
				send_stats "重命名文件"
				;;
			15) # 删除文件
				read -e -p "삭제할 파일 이름을 입력하세요:" filename
				rm -f "$filename" && echo "파일이 삭제되었습니다." || echo "삭제 실패"
				send_stats "删除文件"
				;;
			21) # 压缩文件/目录
				read -e -p "압축할 파일/디렉토리 이름을 입력하세요:" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "$name.tar.gz로 압축됨" || echo "압축 실패"
				send_stats "压缩文件/目录"
				;;
			22) # 解压文件/目录
				read -e -p "압축 해제할 파일 이름을 입력하세요 (.tar.gz):" filename
				install tar
				tar -xzvf "$filename" && echo "$filename이 압축 해제됨" || echo "압축 해제 실패"
				send_stats "解压文件/目录"
				;;

			23) # 移动文件或目录
				read -e -p "이동할 파일 또는 디렉토리 경로를 입력하세요:" src_path
				if [ ! -e "$src_path" ]; then
					echo "오류: 파일 또는 디렉터리가 존재하지 않습니다."
					send_stats "移动文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "대상 경로(새 파일 이름 또는 디렉토리 이름 포함)를 입력하세요:" dest_path
				if [ -z "$dest_path" ]; then
					echo "오류: 대상 경로를 입력하세요."
					send_stats "移动文件或目录失败: 目标路径未指定"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "파일 또는 디렉터리가 $dest_path로 이동되었습니다." || echo "파일 또는 디렉터리 이동 실패"
				send_stats "移动文件或目录"
				;;


		   24) # 复制文件目录
				read -e -p "복사할 파일 또는 디렉토리 경로를 입력하세요:" src_path
				if [ ! -e "$src_path" ]; then
					echo "오류: 파일 또는 디렉터리가 존재하지 않습니다."
					send_stats "复制文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "대상 경로(새 파일 이름 또는 디렉토리 이름 포함)를 입력하세요:" dest_path
				if [ -z "$dest_path" ]; then
					echo "오류: 대상 경로를 입력하세요."
					send_stats "复制文件或目录失败: 目标路径未指定"
					continue
				fi

				# 使用 -r 选项以递归方式复制目录
				cp -r "$src_path" "$dest_path" && echo "파일 또는 디렉터리가 $dest_path로 복사되었습니다." || echo "파일 또는 디렉터리 복사 실패"
				send_stats "复制文件或目录"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "전송할 파일 경로를 입력하세요:" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "오류: 파일이 존재하지 않습니다."
					send_stats "传送文件失败: 文件不存在"
					continue
				fi

				read -e -p "원격 서버 IP를 입력하세요:" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "오류: 원격 서버 IP를 입력하세요."
					send_stats "传送文件失败: 未输入远端服务器IP"
					continue
				fi

				read -e -p "원격 서버 사용자 이름을 입력하세요 (기본값 root):" remote_user
				remote_user=${remote_user:-root}

				read -e -p "원격 서버 비밀번호를 입력하세요:" -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "오류: 원격 서버 암호를 입력하십시오."
					send_stats "传送文件失败: 未输入远端服务器密码"
					continue
				fi

				read -e -p "로그인 포트 번호를 입력하세요 (기본값 22):" remote_port
				remote_port=${remote_port:-22}

				# 清除已知主机的旧条目
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# 使用scp传输文件
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "파일이 원격 서버 /home 디렉터리로 전송됨."
					send_stats "文件传送成功"
				else
					echo "파일 전송 실패."
					send_stats "文件传送失败"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "返回上一级选单菜单"
				break
				;;
			*)  # 处理无效输入
				echo "잘못된 선택입니다. 다시 입력하십시오."
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
		echo -e "${gl_huang}$name ($hostname)에 연결 중...${gl_bai}"
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
	  echo "서버 클러스터 제어"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}서버 목록 관리${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}서버 추가                     ${gl_kjlan}2.  ${gl_bai}서버 삭제                  ${gl_kjlan}3.  ${gl_bai}서버 편집"
	  echo -e "${gl_kjlan}4.  ${gl_bai}클러스터 백업                 ${gl_kjlan}5.  ${gl_bai}클러스터 복원"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}일괄 작업 실행${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}KejiLion 스크립트 설치        ${gl_kjlan}12. ${gl_bai}시스템 업데이트            ${gl_kjlan}13. ${gl_bai}시스템 정리"
	  echo -e "${gl_kjlan}14. ${gl_bai}Docker 설치                   ${gl_kjlan}15. ${gl_bai}BBRv3 설치                 ${gl_kjlan}16. ${gl_bai}1G 가상 메모리 설정"
	  echo -e "${gl_kjlan}17. ${gl_bai}시간대를 상하이로 설정        ${gl_kjlan}18. ${gl_bai}모든 포트 열기             ${gl_kjlan}51. ${gl_bai}사용자 지정 명령"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하세요: " sub_choice

	  case $sub_choice in
		  1)
			  send_stats "添加集群服务器"
			  read -e -p "서버 이름:" server_name
			  read -e -p "서버 IP:" server_ip
			  read -e -p "서버 포트(22):" server_port
			  local server_port=${server_port:-22}
			  read -e -p "서버 사용자 이름(root):" server_username
			  local server_username=${server_username:-root}
			  read -e -p "서버 사용자 비밀번호:" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "删除集群服务器"
			  read -e -p "삭제할 키워드를 입력하세요:" rmserver
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
			  echo -e "${gl_huang}/root/cluster/servers.py${gl_bai} 파일을 다운로드하여 백업을 완료하십시오!"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "还原集群"
			  echo "servers.py 파일을 업로드하고 아무 키나 눌러 업로드를 시작하십시오!"
			  echo -e "${gl_huang}servers.py${gl_bai} 파일을 ${gl_huang}/root/cluster/${gl_bai}에 업로드하여 복원을 완료하십시오!"
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
			  read -e -p "일괄 실행할 명령어를 입력하세요:" mingling
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
echo "광고 섹션"
echo "------------------------"
echo "사용자에게 더 쉽고 우아한 홍보 및 구매 경험을 제공합니다!"
echo ""
echo -e "서버 프로모션"
echo "------------------------"
echo -e "${gl_lan}Leaseweb 홍콩 CN2 GIA, 한국 이중 ISP, 미국 CN2 GIA 프로모션${gl_bai}"
echo -e "${gl_bai}URL: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd $10.99/년 미국 1코어 1GB 메모리 20GB 하드 드라이브 1TB 트래픽/월${gl_bai}"
echo -e "${gl_bai}URL: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger $52.7/년 미국 1코어 4GB 메모리 50GB 하드 드라이브 4TB 트래픽/월${gl_bai}"
echo -e "${gl_bai}URL: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}BandwagonHost $49/분기 미국 CN2GIA, 일본 Softbank 2코어 1GB 메모리 20GB 하드 드라이브 1TB 트래픽/월${gl_bai}"
echo -e "${gl_bai}URL: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT $28/분기 미국 CN2GIA 1코어 2GB 메모리 20GB 하드 드라이브 800GB 트래픽/월${gl_bai}"
echo -e "${gl_bai}URL: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS $6.9/월 도쿄 Softbank 2코어 1GB 메모리 20GB 하드 드라이브 1TB 트래픽/월${gl_bai}"
echo -e "${gl_bai}URL: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}VPS 인기 프로모션 더 보기${gl_bai}"
echo -e "${gl_bai}URL: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "도메인 프로모션"
echo "------------------------"
echo -e "${gl_lan}GNAME $8.8 첫해 COM 도메인, $6.68 첫해 CC 도메인${gl_bai}"
echo -e "${gl_bai}URL: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "KejiLion 주변"
echo "------------------------"
echo -e "${gl_kjlan}Bilibili: ${gl_bai}https://b23.tv/2mqnQyh                ${gl_kjlan}YouTube: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}공식 웹사이트: ${gl_bai}https://kejilion.pro/            ${gl_kjlan}내비게이션: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}블로그: ${gl_bai}https://blog.kejilion.pro/              ${gl_kjlan}소프트웨어 센터: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}스크립트 공식 웹사이트: ${gl_bai}https://kejilion.sh     ${gl_kjlan}GitHub 주소: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "脚本更新"
cd ~
while true; do
	clear
	echo "업데이트 로그"
	echo "------------------------"
	echo "전체 로그: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}이미 최신 버전입니다!${gl_huang}v$sh_v${gl_bai}"
		send_stats "脚本已经最新了，无需更新"
	else
		echo "새 버전이 발견되었습니다!"
		echo -e "현재 버전 v$sh_v        최신 버전 ${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}자동 업데이트가 활성화되었습니다. 매일 새벽 2시에 스크립트가 자동으로 업데이트됩니다!${gl_bai}"
	fi

	echo "------------------------"
	echo "1. 지금 업데이트            2. 자동 업데이트 활성화            3. 자동 업데이트 비활성화"
	echo "------------------------"
	echo "0. 메인 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택을 입력하세요: " choice
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
			echo -e "${gl_lv}스크립트가 최신 버전으로 업데이트되었습니다!${gl_huang}v$sh_v_new${gl_bai}"
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
			echo -e "${gl_lv}자동 업데이트가 활성화되었습니다. 매일 새벽 2시에 스크립트가 자동으로 업데이트됩니다!${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}자동 업데이트가 비활성화되었습니다${gl_bai}"
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
echo -e "기술 사자 스크립트 도구 상자 v$sh_v (AI 번역)"
echo -e "명령줄에 ${gl_huang}k${gl_kjlan}를 입력하여 스크립트를 빠르게 시작할 수 있습니다${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}시스템 정보 조회"
echo -e "${gl_kjlan}2.   ${gl_bai}시스템 업데이트"
echo -e "${gl_kjlan}3.   ${gl_bai}시스템 정리"
echo -e "${gl_kjlan}4.   ${gl_bai}기본 도구"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR 관리"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker 관리"
echo -e "${gl_kjlan}7.   ${gl_bai}WARP 관리"
echo -e "${gl_kjlan}8.   ${gl_bai}테스트 스크립트 모음"
echo -e "${gl_kjlan}9.   ${gl_bai}오라클 클라우드 스크립트 모음"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP 웹사이트 구축"
echo -e "${gl_kjlan}11.  ${gl_bai}애플리케이션 마켓"
echo -e "${gl_kjlan}12.  ${gl_bai}백엔드 작업 공간"
echo -e "${gl_kjlan}13.  ${gl_bai}시스템 도구"
echo -e "${gl_kjlan}14.  ${gl_bai}서버 클러스터 제어"
echo -e "${gl_kjlan}15.  ${gl_bai}광고 컬럼"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}팰월드 서버 오픈 스크립트"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}스크립트 업데이트"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}스크립트 종료"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "선택을 입력하세요: " choice

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
  *) echo "잘못된 입력!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k命令参考用例"
echo "-------------------"
echo "비디오 소개: https://youtu.be/wQdmKuL0hdk"
echo "다음은 k 명령어 참조 예시입니다:"
echo "스크립트 시작                       k"
echo "패키지 설치                         k install nano wget | k add nano wget"
echo "패키지 제거                         k remove nano wget | k del nano wget | k uninstall nano wget"
echo "시스템 업데이트                     k update"
echo "시스템 정크 정리                    k clean"
echo "시스템 재설치 패널                  k dd"
echo "BBRv3 제어판                        k bbr3 | k bbrv3"
echo "코어 튜닝 패널                      k nhyh"
echo "가상 메모리 설정                    k swap 2048"
echo "가상 시간대 설정                    k time Asia/Shanghai"
echo "시스템 휴지통                       k trash | k hsz"
echo "시스템 백업 기능                    k backup | k bf"
echo "SSH 원격 연결 도구                  k ssh"
echo "rsync 원격 동기화 도구              k rsync"
echo "하드 디스크 관리 도구               k disk"
echo "내부 네트워크 관통 (서버 측)        k frps"
echo "내부 네트워크 관통 (클라이언트 측)  k frpc"
echo "소프트웨어 시작                     k start sshd"
echo "소프트웨어 중지                     k stop sshd"
echo "소프트웨어 재시작                   k restart sshd"
echo "소프트웨어 상태 확인                k status sshd"
echo "소프트웨어 부팅 시작                k enable docker | k autostart docke"
echo "도메인 인증서 신청                  k ssl"
echo "도메인 인증서 만료 조회             k ssl ps"
echo "Docker 관리 인터페이스              k docker"
echo "Docker 환경 설치                    k docker install"
echo "Docker 컨테이너 관리                k docker ps"
echo "Docker 이미지 관리                  k docker img"
echo "LDNMP 사이트 관리                   k web"
echo "LDNMP 캐시 정리                     k web cache"
echo "WordPress 설치                      k wp |k wordpress |k wp xxx.com"
echo "리버스 프록시 설치                  k fd |k rp |k fd xxx.com"
echo "로드 밸런서 설치                    k loadbalance"
echo "L4 로드 밸런서 설치                 k stream"
echo "방화벽 패널                         k fhq"
echo "포트 열기                           k dkdk 8080"
echo "포트 닫기                           k gbdk 7800"
echo "IP 화이트리스트 추가                k fxip 127.0.0.0/8"
echo "IP 블랙리스트 추가                  k zzip 177.5.25.36"
echo "명령 즐겨찾기                       k fav"
echo "앱 마켓 관리                        k app"
echo "앱 번호 바로 관리                   k app 26 | k app 1panel | k app npm"
echo "시스템 정보 표시                    k info"
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
			  echo "IP+포트가 이 서비스에 대한 접근을 차단했습니다."
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
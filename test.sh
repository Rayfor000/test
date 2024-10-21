CLR1="\033[0;31m"
CLR2="\033[0;32m"
CLR3="\033[0;33m"
CLR4="\033[0;34m"
CLR5="\033[0;35m"
CLR6="\033[0;36m"
CLR7="\033[0;37m"
CLR8="\033[0;96m"
CLR9="\033[0;97m"
CLR0="\033[0m"

error() {
	echo -e "${CLR1}$1${CLR0}"
	[ -s /var/log/ogos-error.log ] && echo "$(date '+%Y-%m-%d %H:%M:%S') | $SH - $Version - $(echo -e "$1" | tr -d '\n')" >> /var/log/ogos-error.log
	return 1
}
LINE() {
	char="${1:--}"
	length="${2:-80}"
	printf '%*s\n' "$length" | tr ' ' "$char"
}
CHECK_OS() {
	if [ -f /etc/debian_version ]; then
		. /etc/os-release
		if [ "$ID" = "ubuntu" ]; then
			grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"'
		else
			echo "$NAME $(cat /etc/debian_version) ($VERSION_CODENAME)"
		fi
	elif [ -f /etc/os-release ]; then
		. /etc/os-release
		echo "$NAME $VERSION"
	elif [ -f /etc/lsb-release ]; then
		. /etc/lsb-release
		echo "$DISTRIB_DESCRIPTION"
	elif [ -f /etc/fedora-release ]; then
		cat /etc/fedora-release
	elif [ -f /etc/centos-release ]; then
		cat /etc/centos-release
	elif [ -f /etc/arch-release ]; then
		echo "Arch Linux"
	elif [ -f /etc/gentoo-release ]; then
		cat /etc/gentoo-release
	elif [ -f /etc/alpine-release ]; then
		echo "Alpine Linux $(cat /etc/alpine-release)"
	elif [ -f /etc/DISTRO_SPECS ]; then
		grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2
	else
		error "Unknown distribution"
		return 1
	fi
}
CPU_MODEL() {
	if command -v lscpu &>/dev/null; then
		lscpu | awk -F': +' '/Model name/ {print $2; exit}'
	elif [ -f /proc/cpuinfo ]; then
		sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n1
	elif command -v sysctl &>/dev/null && sysctl -n machdep.cpu.brand_string &>/dev/null; then
		sysctl -n machdep.cpu.brand_string
	else
		echo -e "${CLR1}Unknown${CLR0}"
		return 1
	fi
}
CPU_FREQ() {
	[ ! -f /proc/cpuinfo ] && { error "Unable to access /proc/cpuinfo"; return 1; }
	cpu_freq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "$cpu_freq" = "N/A" ] && { error "N/A"; return 1; }
	echo "${cpu_freq} GHz"
}
LOAD_AVERAGE() {
	read one_min five_min fifteen_min <<< $(uptime | awk -F'load average:' '{print $2}' | tr -d ',')
	printf "%.2f, %.2f, %.2f (%d cores)" "$one_min" "$five_min" "$fifteen_min" "$(nproc)"
}
PKG_COUNT() {
	pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf 2>/dev/null | head -n1)
	case ${pkg_manager##*/} in
		apk) count_cmd="apk info" ;;
		apt) count_cmd="dpkg --get-selections" ;;
		opkg) count_cmd="opkg list-installed" ;;
		pacman) count_cmd="pacman -Q" ;;
		yum|dnf) count_cmd="rpm -qa" ;;
		zypper) count_cmd="zypper se --installed-only" ;;
		*) error "Unsupported package manager"; return 1 ;;
	esac
	$count_cmd | wc -l || { error "Failed to count packages for ${pkg_manager##*/}"; return 1; }
}
MEM_USAGE() {
	used=$(free -b | awk '/^Mem:/ {print $3}')
	total=$(free -b | awk '/^Mem:/ {print $2}')
	percentage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}')
	echo "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)"
}
SWAP_USAGE() {
	used=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	total=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	percentage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	echo "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)"
}
DISK_USAGE() {
	used=$(df -B1 / | awk 'NR==2 {printf "%.0f", $3}')
	total=$(df -B1 / | awk 'NR==2 {printf "%.0f", $2}')
	percentage=$(df / | awk 'NR==2 {printf "%.2f", $3/$2 * 100}')
	echo "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)"
}
IP_ADDR() {
	version="$1"
	case "$version" in
		-4)
			ipv4_addr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "$ipv4_addr" ] && echo "$ipv4_addr" || { error "N/A"; return 1; }
			;;
		-6)
			ipv6_addr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "$ipv6_addr" ] && echo "$ipv6_addr" || { error "N/A"; return 1; }
			;;
		*)
			ipv4_addr=$(IP_ADDR -4)
			ipv6_addr=$(IP_ADDR -6)
			[ -z "$ipv4_addr$ipv6_addr" ] && { error "N/A"; return 1; }
			[ -n "$ipv4_addr" ] && echo "IPv4: $ipv4_addr"
			[ -n "$ipv6_addr" ] && echo "IPv6: $ipv6_addr"
			return
			;;
	esac
}
DNS_ADDR () {
	[ ! -f /etc/resolv.conf ] && { error "/etc/resolv.conf file not found"; return 1; }
	ipv4_servers=()
	ipv6_servers=()
	while read -r server; do
		if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			ipv4_servers+=("$server")
		elif [[ $server =~ ^[0-9a-fA-F:]+$ ]]; then
			ipv6_servers+=("$server")
		fi
	done < <(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}')
	[[ ${#ipv4_servers[@]} -eq 0 && ${#ipv6_servers[@]} -eq 0 ]] && { error "No DNS servers found in /etc/resolv.conf"; return 1; }
	case "$1" in
		-4)
			[ ${#ipv4_servers[@]} -eq 0 ] && { error "No IPv4 DNS servers found"; return 1; }
			echo "${ipv4_servers[*]}"
			;;
		-6)
			[ ${#ipv6_servers[@]} -eq 0 ] && { error "No IPv6 DNS servers found"; return 1; }
			echo "${ipv6_servers[*]}"
			;;
		*)
			[ ${#ipv4_servers[@]} -eq 0 -a ${#ipv6_servers[@]} -eq 0 ] && { error "No DNS servers found"; return 1; }
			echo "${ipv4_servers[*]}   ${ipv6_servers[*]}"
			;;
	esac
}
NET_PROVIDER() {
	result=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
	result=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
	result=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
	[ -n "$result" ] && echo "$result" || { error "N/A"; return 1; }
}
INTERFACE() {
	interface=""
	Interfaces=()
	allInterfaces=$(cat /proc/net/dev | grep ':' | cut -d':' -f1 | sed 's/\s//g' | grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn\|^warp\|^wgcf\|^wg\|^docker' | sort -n)
	for interfaceItem in $allInterfaces; do
		Interfaces[${#Interfaces[@]}]=$interfaceItem
	done
	interfacesNum="${#Interfaces[*]}"
	default4Route=$(ip -4 route show default | grep -A 3 "^default")
	default6Route=$(ip -6 route show default | grep -A 3 "^default")
	getArrItemIdx() {
		item="$1"
		shift
		arr=("$@")
		for index in "${!arr[@]}"; do
			[[ "$item" == "${arr[index]}" ]] && return "$index"
		done
		return 255
	}
	for item in "${Interfaces[@]}"; do
		[ -z "$item" ] && continue
		if [[ "$default4Route" == *"$item"* ]] && [ -z "$interface4" ]; then
			interface4="$item"
			interface4DeviceOrder=$(getArrItemIdx "$item" "${Interfaces[@]}")
		fi
		if [[ "$default6Route" == *"$item"* ]] && [ -z "$interface6" ]; then
			interface6="$item"
			interface6DeviceOrder=$(getArrItemIdx "$item" "${Interfaces[@]}")
		fi
		[ -n "$interface4" ] && [ -n "$interface6" ] && break
	done
	interface="$interface4 $interface6"
	[[ "$interface4" == "$interface6" ]] && interface=$(echo "$interface" | cut -d' ' -f 1)
	[[ -z "$interface4" || -z "$interface6" ]] && {
		interface=$(echo "$interface" | sed 's/[[:space:]]//g')
		[[ -z "$interface4" ]] && interface4="$interface"
		[[ -z "$interface6" ]] && interface6="$interface"
	}
	if [ "$1" = "-i" ]; then
		for interface in $interface; do
			if stats=$(awk -v iface="$interface" '$1 ~ iface":" {print $2, $10}' /proc/net/dev); then
				read rx_bytes tx_bytes <<< "$stats"
				echo "$interface: RX: $(CONVERT_SIZE $rx_bytes), TX: $(CONVERT_SIZE $tx_bytes)"
			else
				error "No stats found for interface: $interface"
				return 1
			fi
		done
	else
		for interface in $interface; do
			if stats=$(awk -v iface="$interface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev); then
				read rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<< "$stats"
				echo "$interface"
			else
				error "No stats found for interface: $interface"
				return 1
			fi
		done
	fi
}
TIMEZONE() {
	case "$1" in
		-e)
			result=$(timeout 1s curl -sL ipapi.co/timezone) ||
			result=$(timeout 1s curl -sL worldtimeapi.org/api/ip | grep -oP '"timezone":"\K[^"]+') ||
			result=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"timezone":"\K[^"]+') ||
			[ -n "$result" ] && echo "$result" || { error "N/A"; return 1; }
			;;
		-i|*)
			result=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			result=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			result=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "$result" ] && echo "$result" || { error "N/A"; return 1; }
			;;
	esac
}
CONVERT_SIZE() {
	[ -z "$1" ] && return
	size=$1
	unit=${2:-B}
	base=${3:-1024}
	suffixes=("B" "KiB" "MiB" "GiB" "TiB" "PiB" "EiB" "ZiB" "YiB")
	[ "$base" -eq 1000 ] && suffixes=("B" "KB" "MB" "GB" "TB" "PB" "EB" "ZB" "YB")
	i=0
	while (( $(awk "BEGIN {print ($size >= $base)}") )); do
		size=$(awk "BEGIN {printf \"%.2f\", $size / $base}")
		((i++))
	done
	printf "%.2f %s\n" $size "${suffixes[$i]}"
}
SYS_INFO_CN() {
	echo -e "${CLR3}系统信息${CLR0}"
	echo -e "${CLR8}$(LINE = "24")${CLR0}"

	echo -e "- 主机名：\t\t${CLR2}$(hostname)${CLR0}"
	echo -e "- 操作系统：\t\t${CLR2}$(CHECK_OS)${CLR0}"
	echo -e "- 内核版本：\t\t${CLR2}$(uname -r)${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"

	echo -e "- 架构：\t\t${CLR2}$(uname -m)${CLR0}"
	echo -e "- CPU型号：\t\t${CLR2}$(CPU_MODEL)${CLR0}"
	echo -e "- CPU核心数：\t\t${CLR2}$(nproc)${CLR0}"
	echo -e "- CPU频率：\t\t${CLR2}$(CPU_FREQ)${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"

	echo -e "- 平均负载：\t\t${CLR2}$(LOAD_AVERAGE)${CLR0}"
	echo -e "- 进程数：\t\t${CLR2}$(ps aux | wc -l)${CLR0}"
	echo -e "- 已安装包数：\t\t${CLR2}$(PKG_COUNT)${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"

	echo -e "- 内存使用：\t\t${CLR2}$(MEM_USAGE)${CLR0}"
	echo -e "- 交换分区使用：\t${CLR2}$(SWAP_USAGE)${CLR0}"
	echo -e "- 磁盘使用：\t\t${CLR2}$(DISK_USAGE)${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"

	echo -e "- IPv4地址：\t\t${CLR2}$(IP_ADDR -4)${CLR0}"
	echo -e "- IPv6地址：\t\t${CLR2}$(IP_ADDR -6)${CLR0}"
	echo -e "- DNS服务器：\t\t${CLR2}$(DNS_ADDR)${CLR0}"
	echo -e "- 网络拥堵算法：\t${CLR2}$(sysctl -n net.ipv4.tcp_congestion_control) $(sysctl -n net.core.default_qdisc)${CLR0}"
	echo -e "- 网络提供商：\t\t${CLR2}$(NET_PROVIDER)${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"

	echo -e "- 总接收：\t\t${CLR2}$(INTERFACE &>/dev/null && CONVERT_SIZE $rx_bytes)${CLR0}"
	echo -e "- 总发送：\t\t${CLR2}$(INTERFACE &>/dev/null && CONVERT_SIZE  $tx_bytes)${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"

	echo -e "- 系统时区：\t\t${CLR2}$(TIMEZONE)${CLR0}"
	echo -e "- 地理位置：\t\t${CLR2}$(curl -s https://ipinfo.io | grep -E 'city|region|country' | cut -d'"' -f4 | tr '\n' ',' | sed 's/,/, /g' | sed 's/, $//')${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"

	echo -e "- 运行时间：\t\t${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	echo -e "${CLR8}$(LINE = "24")${CLR0}"
	echo -e "来自 github.com/OG-Open-Source 组织"
}
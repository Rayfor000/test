#!/bin/bash

# Written By MoeClub.org
# Blog: https://moeclub.org
# Modified By 秋水逸冰
# Blog: https://teddysun.com/
# Modified By VPS收割者
# Blog: https://www.idcoffer.com/
# Modified By airium
# Blog: https://github.com/airium
# Modified By 王煎饼
# Github: https://github.com/bin456789/
# Modified By nat.ee
# Forum: https://hostloc.com/space-uid-49984.html
# Modified By Bohan Yang
# Twitter: https://twitter.com/brentybh
# Modified By Leitbogioro
# Blog: https://www.zhihu.com/column/originaltechnic
# Modified By OGATA Open-Source
# Github: https://github.com/OG-Open-Source

[ "$(curl -s ipinfo.io/country)" = "CN" ] && cf_proxy="https://proxy.ogtt.tk/" || cf_proxy=""
[ -f ~/function.sh ] && source ~/function.sh || bash <(curl -sL ${cf_proxy}https://raw.githubusercontent.com/OG-Open-Source/raw/refs/heads/main/shell/update-function.sh) && source ~/function.sh

Version="2024.10.25"
License="GPL"
SH="InstallNET.sh"

AddNum="1"
autoPlugAdapter="1"
ddMode="0"
DebianModifiedProcession=""
enableBBR="0"
FindDists="0"
FirmwareImage=""
fileSystem=""
GRUBDIR=""
GRUBFILE=""
GRUBVER=""
IncDisk=""
IncFirmware="0"
interface=""
interfaceSelect=""
ip6Addr=""
ip6Gate=""
ip6Mask=""
ipAddr=""
ipGate=""
ipMask=""
loaderMode="0"
partitionTable="mbr"
Relese=""
setAutoConfig="1"
setAutoReboot="0"
setCloudKernel=""
setCMD=""
setConsole=""
setDHCP=""
setDisk=""
setDns=""
setFail2ban=""
setFileType=""
setInterfaceName="0"
setIPv6="1"
setKejilion=""
setMemCheck="1"
setMirror=""
setMotd=""
setNet="0"
setNetbootXyz="0"
setRaid=""
setRDP="0"
setSwap="0"
setIpStack=""
SpikCheckDIST="0"
sshPORT=""
swapSpace="0"
targetLang="en"
targetRelese=""
TimeZone=""
tmpDIST=""
tmpSetIPv6=""
tmpURL=""
tmpVER=""
tmpWORD=""
UNKNOWHW="0"
UNVER="6.4"
VER=""

while [[ $# -ge 1 ]]; do
	case $1 in
		-debian) shift; Relese="Debian"; tmpDIST="$1"; shift ;;
		-ubuntu) shift; ddMode="1"; finalDIST="$1"; targetRelese="Ubuntu"; shift ;;
		-kali) shift; Relese="Kali"; tmpDIST="$1"; shift ;;
		-centos) shift; Relese="CentOS"; tmpDIST="$1"; shift ;;
		-rocky) shift; Relese="RockyLinux"; tmpDIST="$1"; shift ;;
		-alma) shift; Relese="AlmaLinux"; tmpDIST="$1"; shift ;;
		-fedora) shift; Relese="Fedora"; tmpDIST="$1"; shift ;;
		-alpine) shift; Relese="AlpineLinux"; tmpDIST="$1"; shift ;;
		-windows) shift; ddMode="1"; finalDIST="$1"; targetRelese="Windows"; shift ;;
		-architecture) shift; tmpVER="$1"; shift ;;
		-lang) shift; targetLang="$1"; shift ;;
		-dd) shift; ddMode="1"; tmpURL="$1"; shift ;;
		-mirror) shift; isMirror="1"; tmpMirror="$1"; shift ;;
		-rdp) shift; setRDP="1"; WinRemote="$1"; shift ;;
		-raid) shift; setRaid="$1"; shift ;;
		-setdisk) shift; setDisk="$1"; shift ;;
		-swap) shift; setSwap="$1"; shift ;;
		-partition) shift; partitionTable="$1"; shift ;;
		-filesystem) shift; setFileSystem="$1"; shift ;;
		-timezone) shift; TimeZone="$1"; shift ;;
		-cmd) shift; setCMD="$1"; shift ;;
		-console) shift; setConsole="$1"; shift ;;
		-firmware) shift; IncFirmware="1"; shift ;;
		-pwd) shift; tmpWORD="$1"; shift ;;
		-hostname) shift; tmpHostName="$1"; shift ;;
		-port) shift; sshPORT="$1"; shift ;;
		--networkstack) shift; setIpStack="$1"; shift ;;
		--ip-addr) shift; ipAddr="$1"; shift ;;
		--ip-mask) shift; ipMask="$1"; shift ;;
		--ip-gate) shift; ipGate="$1"; shift ;;
		--ip-dns) shift; ipDNS="$1"; shift ;;
		--ip-set) shift; ipAddr="$1"; ipMask="$2"; ipGate="$3"; shift 3 ;;
		--ip6-addr) shift; ip6Addr="$1"; shift ;;
		--ip6-mask) shift; ip6Mask="$1"; shift ;;
		--ip6-gate) shift; ip6Gate="$1"; shift ;;
		--ip6-dns) shift; ip6DNS="$1"; shift ;;
		--ip6-set) shift; ip6Addr="$1"; ip6Mask="$2"; ip6Gate="$3"; shift 3 ;;
		--network) shift; tmpDHCP="$1"; shift ;;
		--adapter) shift; interfaceSelect="$1"; shift ;;
		--netdevice-unite) shift; setInterfaceName="1" ;;
		--autoplugadapter) shift; autoPlugAdapter="$1"; shift ;;
		--loader) shift; loaderMode="1"; shift ;;
		--motd) shift; setMotd="1"; shift ;;
		--fail2ban) setFail2ban="1"; shift ;;
		--kejilion) setKejilion="1"; shift ;;
		--setdns) shift; setDns="1" ;;
		--cloudkernel) shift; setCloudKernel="$1"; shift ;;
		--cloudimage) shift; useCloudImage="1" ;;
		--filetype) shift; setFileType="$1"; shift ;;
		--setipv6) shift; tmpSetIPv6="$1"; shift ;;
		--bbr) shift; enableBBR="1"; shift ;;
		--allbymyself) shift; setAutoConfig="0"; shift ;;
		--nomemcheck) shift; setMemCheck="0"; shift ;;
		--netbootxyz) shift; setNetbootXyz="1"; shift ;;
		--reboot) shift; setAutoReboot="1" ;;
		*)
			[[ "$1" != "error" ]] && echo -e "\nInvaild option: "$1"\n"
			echo -e "${CLR2}Usage:${CLR0}\n\tbash $(basename $0) [OPTIONS]\n"
			echo -e "${CLR3}Options:${CLR0}"
			echo -e "\t${CLR8}-debian${CLR0}\t\t[7/8/9/10/11/12]\tSpecify Debian distribution (${CLR2}'12'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-ubuntu${CLR0}\t\t[20.04/22.04/24.04]\tSpecify Ubuntu distribution (${CLR2}'24.04'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-kali${CLR0}\t\t[rolling/dev]\t\tSpecify Kali Linux distribution (${CLR2}'rolling'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-centos${CLR0}\t\t[7/8/9]\t\t\tSpecify CentOS distribution (${CLR2}'9'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-rocky${CLR0}\t\t[8/9]\t\t\tSpecify Rocky Linux distribution (${CLR2}'9'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-alma${CLR0}\t\t[8.10/9.4]\t\tSpecify AlmaLinux distribution (${CLR2}'9.4'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-fedora${CLR0}\t\t[39/40]\t\t\tSpecify Fedora Linux distribution (${CLR2}'40'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-alpine${CLR0}\t\t[3.16~3.20/edge]\tSpecify Alpine Linux distribution (${CLR2}'edge'${CLR0} is the stable version)"
			echo -e "\t${CLR8}-windows${CLR0}\t[DIST]\t\t\tSpecify Microsoft Windows distribution"
			echo -e "\t${CLR8}-architecture${CLR0}\t[32/i386|64/amd64|arm/arm64]"
			echo -e "\t${CLR8}-mirror${CLR0}\t\t[URL]"
			echo -e "\t${CLR8}-lang${CLR0}\t\t[LANG]\tNot for Linux, specify language for Windows"
			echo -e "\t${CLR8}-dd${CLR0}\t[URL]"
			echo -e "\t${CLR8}-hostname${CLR0}\t[HOSTNAME]"
			echo -e "\t${CLR8}-pwd${CLR0}\t\t[PASSWORD]"
			echo -e "\t${CLR8}-port${CLR0}\t\t[SSH-PORT]"
			echo -e "\t${CLR8}--ip-addr${CLR0}\t[123.456.789.012] / --ip-mask [24-32] / --ip-gate [123.456.789.012]"
			echo -e "\t${CLR8}--ip-set${CLR0}\t[123.456.789.012] [24-32] [123.456.789.1]"
			echo -e "\t${CLR8}--ip6-addr${CLR0}\t[1234:5678:90ab:cdef:1234:5678:90ab:cdef] / --ip6-mask [1-128] / --ip6-gate [1234:5678:90ab:cdef:1234:5678:90ab:cdef]"
			echo -e "\t${CLR8}--ip6-set${CLR0}\t[1234:5678:90ab:cdef:1234:5678:90ab:cdef] [1-128] [1234:5678:90ab:cdef:1234:5678:90ab:cdef]"
			echo -e "\t${CLR8}--setipv6${CLR0}\tAuto set IPv6 address"
			echo -e "\t${CLR8}--bbr${CLR0}\t\tEnable BBR congestion control algorithm"
			echo -e "\t${CLR8}--fail2ban${CLR0}\tInstall and configure fail2ban"
			echo -e "\t${CLR8}--kejilion${CLR0}\tInstall and configure Kejilion.sh"
			echo -e "\t${CLR8}--reboot${CLR0}\tAuto reboot after preparation"
			echo -e "\n${CLR6}LAST UPDATE: 2024/10/24${CLR0}"
			exit 1
			;;
	esac
done

CHECK_ROOT

if [ "$(curl -s ipinfo.io/country)" = "CN" ]; then
	IsCN="1"
	ipDNS="119.29.29.29 223.6.6.6"
	ip6DNS="2402:4e00:: 2400:3200::1"
else
	IsCN="0"
	ipDNS="1.1.1.1 8.8.8.8"
	ip6DNS="2606:4700:4700::1111 2001:4860:4860::8888"
fi

checkDNS() {
	if [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
		tmpDNS=$(echo $1 | sed 's/ /,/g')
		echo "$tmpDNS"
	else
		echo "$1"
	fi
}

selectMirror() {
	[ $# -ge 3 ] || exit 1
	Relese=$(echo "$1" | sed -r 's/(.*)/\L\1/')
	DIST=$(echo "$2" | sed 's/\ //g' | sed -r 's/(.*)/\L\1/')
	VER=$(echo "$3" | sed 's/\ //g' | sed -r 's/(.*)/\L\1/')
	New=$(echo "$4" | sed 's/\ //g')
	[ -n "$Relese" ] && [ -n "$DIST" ] && [ -n "$VER" ] || exit 1
	if [ "$Relese" == "debian" ] || [ "$Relese" == "ubuntu" ] || [ "$Relese" == "kali" ]; then
		[ "$DIST" == "focal" ] && legacy="legacy-" || legacy=""
		TEMP="SUB_MIRROR/dists/${DIST}/main/installer-${VER}/current/${legacy}images/netboot/${Relese}-installer/${VER}/initrd.gz"
		[[ "$Relese" == "kali" ]] && TEMP="SUB_MIRROR/dists/${DIST}/main/installer-${VER}/current/images/netboot/debian-installer/${VER}/initrd.gz"
	elif [ "$Relese" == "centos" ] || [ "$Relese" == "rockylinux" ] || [ "$Relese" == "almalinux" ]; then
		if [ "$Relese" == "centos" ] && [[ "$RedHatSeries" -le "7" ]]; then
			TEMP="SUB_MIRROR/${DIST}/os/${VER}/images/pxeboot/initrd.img"
		else
			TEMP="SUB_MIRROR/${DIST}/BaseOS/${VER}/os/images/pxeboot/initrd.img"
		fi
	elif [ "$Relese" == "fedora" ]; then
		TEMP="SUB_MIRROR/releases/${DIST}/Server/${VER}/os/images/pxeboot/initrd.img"
	elif [ "$Relese" == "alpinelinux" ]; then
		TEMP="SUB_MIRROR/${DIST}/releases/${VER}/netboot/${InitrdName}"
	fi
	[ -n "$TEMP" ] || exit 1
	mirrorStatus=0
	declare -A MirrorBackup
	if [[ "$IsCN" == "1" ]]; then
		MirrorBackup=(
			["debian"]="http://mirrors.ustc.edu.cn/debian http://mirror.nju.edu.cn/debian https://mirrors.tuna.tsinghua.edu.cn/debian https://mirrors.aliyun.com/debian-archive/debian"
			["ubuntu"]="https://mirrors.ustc.edu.cn/ubuntu http://mirrors.xjtu.edu.cn/ubuntu"
			["kali"]="https://mirrors.tuna.tsinghua.edu.cn/kali http://mirrors.zju.edu.cn/kali"
			["alpinelinux"]="http://mirror.nju.edu.cn/alpine http://mirrors.tuna.tsinghua.edu.cn/alpine"
			["centos"]="https://mirrors.ustc.edu.cn/centos-stream https://mirrors.bfsu.edu.cn/centos-stream https://mirrors.tuna.tsinghua.edu.cn/centos http://mirror.nju.edu.cn/centos-altarch https://mirrors.tuna.tsinghua.edu.cn/centos-vault"
			["fedora"]="https://mirrors.tuna.tsinghua.edu.cn/fedora https://mirrors.bfsu.edu.cn/fedora"
			["rockylinux"]="http://mirror.nju.edu.cn/rocky http://mirrors.sdu.edu.cn/rocky"
			["almalinux"]="https://mirror.sjtu.edu.cn/almalinux http://mirrors.neusoft.edu.cn/almalinux"
		)
	else
		MirrorBackup=(
			["debian"]="http://deb.debian.org/debian http://mirrors.ocf.berkeley.edu/debian http://ftp.yz.yamagata-u.ac.jp/pub/linux/debian http://archive.debian.org/debian"
			["ubuntu"]="http://archive.ubuntu.com/ubuntu http://ports.ubuntu.com"
			["kali"]="https://mirrors.ocf.berkeley.edu/kali http://ftp.yz.yamagata-u.ac.jp/pub/linux/kali"
			["alpinelinux"]="http://dl-cdn.alpinelinux.org/alpine https://mirrors.edge.kernel.org/alpine"
			["centos"]="http://mirror.stream.centos.org http://mirrors.ocf.berkeley.edu/centos-stream http://mirror.centos.org/centos http://mirror.centos.org/altarch http://vault.centos.org"
			["fedora"]="http://mirrors.rit.edu/fedora/fedora/linux http://ftp.iij.ad.jp/pub/linux/Fedora/fedora/linux"
			["rockylinux"]="http://download.rockylinux.org/pub/rocky http://mirrors.iu13.net/rocky"
			["almalinux"]="http://repo.almalinux.org/almalinux http://ftp.iij.ad.jp/pub/linux/almalinux"
		)
	fi
	[[ "$New" =~ ^https?:// ]] && MirrorBackup[$Relese]="${New%*/} ${MirrorBackup[$Relese]}"
	IFS=' ' read -ra mirrors <<< "${MirrorBackup[$Relese]}"
	for mirror in "${mirrors[@]}"; do
		Current="$mirror"
		[ -n "$Current" ] || continue
		MirrorURL=$(echo "$TEMP" | sed "s#SUB_MIRROR#${Current}#g")
		curl -ksI --connect-timeout 3 "$MirrorURL" >/dev/null
		[ $? -eq 0 ] && mirrorStatus=1 && break
	done
	[ $mirrorStatus -eq 1 ] && echo "$Current" || exit 1
}

getIPv4Address() {
	allI4Addrs=$(ip -4 addr show | grep -wA 1024 "$interface4" | grep -w "$interface4" | grep -wv "lo\|host" | grep -w "inet" | grep -w "scope global*\|link*" | awk -F " " '{for (i=2;i<=NF;i++)printf("%s ", $i);print ""}' | awk '{print$1}')
	[[ -z "$allI4Addrs" ]] && allI4Addrs=$(ip -4 addr show | grep -wA 1024 "$interface4" | grep -wv "lo\|host" | grep -w "inet" | grep -w "scope global*\|link*" | awk -F " " '{for (i=2;i<=NF;i++)printf("%s ", $i);print ""}' | awk '{print$1}')
	iAddr=$(echo "$allI4Addrs" | head -n 1)
	iAddrNum=$(echo "$allI4Addrs" | wc -l)
	collectAllIpv4Addresses "$iAddrNum"
	ipAddr=$(echo ${iAddr} | cut -d'/' -f1)
	ipPrefix=$(echo ${iAddr} | cut -d'/' -f2)
	ipMask=$(netmask "$ipPrefix")
	ip4RouteScopeLink=$(ip -4 route show scope link | grep -iv "warp\|wgcf\|wg[0-9]\|docker[0-9]" | grep -w "$interface4" | grep -w "$ipAddr" | grep -m1 -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1)
	actualIp4Prefix=$(ip -4 route show scope link | grep -iv "warp\|wgcf\|wg[0-9]\|docker[0-9]" | grep -w "$interface4" | grep -w "$ip4RouteScopeLink" | head -n 1 | awk '{print $1}' | awk -F '/' '{print $2}')
	[[ -z "$actualIp4Prefix" ]] && actualIp4Prefix="$ipPrefix"
	actualIp4Subnet=$(netmask "$actualIp4Prefix")
	FirstRoute=$(ip -4 route show default | grep -iv "warp\|wgcf\|wg[0-9]\|docker[0-9]" | grep -w "via" | grep -w "dev $interface4*" | head -n 1 | awk -F " " '{for (i=3;i<=NF;i++)printf("%s ", $i);print ""}' | awk '{print$1}')
	RouterMac=$(arp -n | grep "$FirstRoute" | awk '{print$3}')
	FrFirst=$(echo "$FirstRoute" | cut -d'.' -f 1,2)
	FrThird=$(echo "$FirstRoute" | cut -d'.' -f 3)
	ipGates=$(ip -4 route show | grep -iv "warp\|wgcf\|wg[0-9]\|docker[0-9]" | grep -v "via" | grep -w "dev $interface4*" | grep -w "proto*" | grep -w "scope global\|link src $ipAddr*" | awk '{print$1}')
	ipGateLine=$(echo "$ipGates" | wc -l)
	for ((i = 1; i <= "$ipGateLine"; i++)); do
		tmpIpGate=$(echo "$ipGates" | sed -n ''$i'p')
		tmpIgAddr=$(echo $tmpIpGate | cut -d'/' -f1)
		tmpIgPrefix=$(echo $tmpIpGate | cut -d'/' -f2)
		minIpGate=$(ipv4Calc "$tmpIgAddr" "$tmpIgPrefix" | grep "FirstIP:" | awk '{print$2}')
		tmpIpGateFirst=$(echo "$minIpGate" | cut -d'.' -f 1,2)
		tmpIpGateThird=$(echo "$minIpGate" | cut -d'.' -f 3)
		[[ "$FrFirst" == "$tmpIpGateFirst" ]] && {
			if [[ "$FrThird" == "$tmpIpGateThird" ]]; then
				ipGate="$FirstRoute"
				break
			elif [[ "$FrThird" != "$tmpIpGateThird" ]]; then
				tmpMigFirst=$(echo $minIpGate | cut -d'.' -f 1,2,3)
				ipGate=$(arp -n | grep "$tmpMigFirst" | grep "$RouterMac" | awk '{print$1}')
				break
			fi
		}
	done
	[[ "$ipGates" == "" || "$ipGate" == "" ]] && ipGate="$FirstRoute"
	transferIPv4AddressFormat "$ipAddr" "$ipGate"
}

transferIPv4AddressFormat() {
	ipv4SubnetCertificate "$1" "$2"
	ipPrefix="$tmpIpMask"
	ipMask=$(netmask "$tmpIpMask")
	ip4AddrFirst=$(echo $1 | cut -d'.' -f1)
	ip4AddrSecond=$(echo $1 | cut -d'.' -f2)
	ip4GateFirst=$(echo $2 | cut -d'.' -f1)
	ip4GateSecond=$(echo $2 | cut -d'.' -f2)
	[[ "$ip4AddrFirst""$ip4AddrSecond" != "$ip4GateFirst""$ip4GateSecond" ]] && {
		checkIfIpv4AndIpv6IsLocalOrPublic "$2" ""
		[[ "$ipv4LocalOrPublicStatus" == '1' ]] || [[ "$ip4AddrFirst" != "$ip4GateFirst" ]] || [[ "$ip4AddrSecond" != "$ip4GateSecond" ]] && {
			if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]] || [[ "$linux_release" == 'alpinelinux' ]]; then
				ipPrefix="$actualIp4Prefix"
				ipMask="$actualIp4Subnet"
				Network4Config="isStatic"
				setInterfaceName='1'
			fi
			[[ "$IPStackType" == "BiStack" ]] && {
				[[ "$linux_release" == 'debian' || "$linux_release" == 'kali' ]] && {
					BiStackPreferIpv6Status='1'
				}
			}
			[[ "$IPStackType" == "IPv4Stack" || "$linux_release" == 'alpinelinux' ]] && BurnIrregularIpv4Status='1'
		}
	}
	[[ "$interfacesNum" -ge "2" && "$linux_release" == 'alpinelinux' ]] && Network4Config="isStatic"
}

netmask() {
	n="${1:-32}"
	b=""
	m=""
	for ((i = 0; i < 32; i++)); do
		[ $i -lt $n ] 2>/dev/null && b="${b}1" || b="${b}0"
	done
	for ((i = 0; i < 4; i++)); do
		s=$(echo "$b" | cut -c$(($(($i * 8)) + 1))-$(($(($i + 1)) * 8)))
		[ "$m" == "" ] && m="$((2#${s}))" || m="${m}.$((2#${s}))"
	done
	echo "$m"
}

ipv4Calc() {
	tmpIp4="$1"
	tmpIp4Mask=$(netmask "$2")

	IFS=. read -r i1 i2 i3 i4 <<<"$tmpIp4"
	IFS=. read -r m1 m2 m3 m4 <<<"$tmpIp4Mask"

	tmpNetwork="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"
	tmpBroadcast="$((i1 & m1 | 255 - m1)).$((i2 & m2 | 255 - m2)).$((i3 & m3 | 255 - m3)).$((i4 & m4 | 255 - m4))"
	tmpFirstIP="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4) + 1))"
	tmpFiLast="$(echo "$tmpFirstIP" | cut -d'.' -f 4)"
	FirstIP="$tmpFirstIP"
	tmpLastIP="$((i1 & m1 | 255 - m1)).$((i2 & m2 | 255 - m2)).$((i3 & m3 | 255 - m3)).$(((i4 & m4 | 255 - m4) - 1))"
	tmpLiLast="$(echo "$tmpLastIP" | cut -d'.' -f 4)"
	LastIP="$tmpLastIP"
	[[ "$tmpFiLast" > "$tmpLiLast" ]] && {
		FirstIP="$tmpLastIP"
		LastIP="$tmpFirstIP"
	}
	[[ "$2" > "31" ]] && {
		FirstIP="$tmpNetwork"
		LastIP="$tmpNetwork"
	}
	echo -e "Network:   $tmpNetwork\nBroadcast: $tmpBroadcast\nFirstIP:   $FirstIP\nLastIP:    $LastIP\n"
}

ipv4SubnetCertificate() {
	[[ $(echo $1 | cut -d'.' -f 1) != $(echo $2 | cut -d'.' -f 1) ]] && tmpIpMask="1"
	[[ $(echo $1 | cut -d'.' -f 1) == $(echo $2 | cut -d'.' -f 1) ]] && tmpIpMask="8"
	[[ $(echo $1 | cut -d'.' -f 1,2) == $(echo $2 | cut -d'.' -f 1,2) ]] && tmpIpMask="16"
	[[ $(echo $1 | cut -d'.' -f 1,2,3) == $(echo $2 | cut -d'.' -f 1,2,3) ]] && tmpIpMask="24"
}

getDisk() {
	rootPart=$(lsblk -ip | grep -v "fd[0-9]*\|sr[0-9]*\|ram[0-9]*\|loop[0-9]*" | sed 's/[[:space:]]*$//g' | grep -w "part /\|part /boot" | head -n 1 | cut -d' ' -f1 | sed 's/..//')
	diskSuffix=${rootPart: -4}
	[[ -n $(echo $diskSuffix | grep -o "[0-9]p[0-9]") ]] && disks=$(echo $rootPart | sed 's/p[0-9]*.$//') || disks=$(echo $rootPart | sed 's/[0-9]*.$//')
	[[ -z "$disks" ]] && disks=$(lsblk -ip | grep -v "fd[0-9]*\|sr[0-9]*\|ram[0-9]*\|loop[0-9]*" | sed 's/[[:space:]]*$//g' | grep -w "disk /\|disk /boot" | head -n 1 | cut -d' ' -f1)
	[[ -z "$disks" ]] && disks=$(lsblk -ip | grep -v "fd[0-9]*\|sr[0-9]*\|ram[0-9]*\|loop[0-9]*" | sed 's/[[:space:]]*$//g' | grep -w "disk" | grep -i "[0-9]g\|[0-9]t\|[0-9]p\|[0-9]e\|[0-9]z\|[0-9]y" | head -n 1 | cut -d' ' -f1)
	[ -n "$disks" ] || echo ""
	echo "$disks" | grep -q "/dev"
	[ $? -eq 0 ] && IncDisk="$disks" || IncDisk="/dev/$disks"
	AllDisks=""
	for Count in $(lsblk -ipd | grep -v "fd[0-9]*\|sr[0-9]*\|ram[0-9]*\|loop[0-9]*" | sed 's/[[:space:]]*$//g' | grep -w "disk" | grep -i "[0-9]g\|[0-9]t\|[0-9]p\|[0-9]e\|[0-9]z\|[0-9]y" | cut -d' ' -f1); do
		AllDisks+="$Count "
	done
	AllDisks=$(echo "$AllDisks" | sed 's/.$//')
	disksNum=$(echo $AllDisks | grep -o "/dev/*" | wc -l)

	for ((d = 1; d <= $disksNum; d++)); do
		currentDisk=$(echo "$AllDisks" | cut -d' ' -f$d)
		checkIfIsoPartition=$(lsblk -ipf | grep "$currentDisk" | head -n 1 | awk '{print $2}' | grep -i "iso")
		[[ -z "$checkIfIsoPartition" ]] && tmpAllDisks+="$currentDisk "
	done
	tmpAllDisks=$(echo "$tmpAllDisks" | sed 's/.$//')

	[[ "$AllDisks" != "$tmpAllDisks" ]] && {
		AllDisks="$tmpAllDisks"
		disksNum=$(echo $AllDisks | grep -o "/dev/*" | wc -l)
		[[ "$IncDisk" =~ "$AllDisks" ]] || IncDisk=$(echo "$AllDisks" | cut -d' ' -f1)
	}

	[[ -n "$1" && "$1" != "all" && "$(echo $1 | cut -d '/' -f 3)" =~ ^[a-z0-9]+$ || "$(echo $1 | cut -d '/' -f 3)" =~ ^[a-z]+$ ]] && {
		[[ "$1" =~ "/dev/" ]] && IncDisk="$1" || IncDisk="/dev/$1"
	}

	[[ -z "$1" && "$disksNum" -ge "2" && -n $(lsblk -ip | awk '{print $6}' | grep -io "lvm") ]] && {
		[[ "$2" == 'debian' || "$2" == 'kali' ]] && setDisk="all"
	}

	diskCapacity=$(lsblk -ipb | grep -w "$IncDisk" | awk {'print $4'})
}

detectCloudinit() {
	internalCloudinitStatus="0"
	[[ $(blkid -tTYPE=iso9660 -odevice) ]] && {
		umount /mnt 2>/dev/null
		for cloudinitCdDrive in $(blkid -tTYPE=iso9660 -odevice); do
			mount $cloudinitCdDrive /mnt 2>/dev/null
			[[ $(find /mnt -name "meta_data*" -print -or -name "user_data*" -print -or -name "meta-data*" -print -or -name "user-data*" -print) ]] && {
				internalCloudinitStatus="1"
				umount /mnt 2>/dev/null
				break
			}
			umount /mnt 2>/dev/null
		done
	}
}

setNormalRecipe() {
	[[ -n "$3" && $(echo "$3" | grep -o '[0-9]') ]] && swapSpace="$setSwap" || swapSpace='0'
	if [[ "$1" == 'debian' ]] || [[ "$1" == 'kali' ]]; then
		[[ "$lowMemMode" == "1" ]] && {
			[[ -z "$swapSpace" || "$swapSpace" -lt "512" ]] && swapSpace="512"
		}
		if [[ -n "$swapSpace" && "$swapSpace" -gt "0" ]]; then
			swapSpace=$(awk 'BEGIN{print '${swapSpace}'*1.05078125 }' | cut -d '.' -f '1')
			swapRecipe=''${swapSpace}' 200 '${swapSpace}' linux-swap method{ swap } format{ } .'
		else
			swapRecipe=""
		fi
		if [[ "$6" == "xfs" ]]; then
			fileSystem="xfs"
		else
			fileSystem="ext4"
		fi
		defaultFileSystem='d-i partman/default_filesystem string '${fileSystem}''
		mainRecipe='1076 150 -1 '${fileSystem}' method{ format } format{ } use_filesystem{ } filesystem{ '${fileSystem}' } mountpoint{ / } .'
		if [[ "$2" -gt "1" && "$4" == "all" ]]; then
			PartmanEarlyCommand='debconf-set partman-auto/disk '${10}';'
			selectDisks='d-i partman-auto/disk string '${10}''
		else
			PartmanEarlyCommand='debconf-set partman-auto/disk "$(list-devices disk | grep '${9}' | head -n 1)";'
			selectDisks='d-i partman-auto/disk string '${9}''
		fi
		if [[ "$5" == "gpt" || "$7" == "enabled" || "$8" -ge "2199023255552" ]]; then
			gptPartitionPreseed=$(echo -e "d-i partman-basicfilesystems/choose_label string gpt
d-i partman-basicfilesystems/default_label string gpt
d-i partman-partitioning/choose_label string gpt
d-i partman-partitioning/default_label string gpt
d-i partman/choose_label string gpt
d-i partman/default_label string gpt")
			gptForBios='1 100 1 free $iflabel{ gpt } $reusemethod{ } method{ biosgrub } .'
		else
			gptPartitionPreseed=""
			gptForBios=""
		fi
		if [[ "$7" == "enabled" ]]; then
			normalRecipes=$(echo -e "d-i partman-auto/choose_recipe select normal
d-i partman-auto/expert_recipe string normal ::                                   \
	538 100 1076 free \$iflabel{ gpt } \$reusemethod{ } method{ efi } format{ } . \
	$swapRecipe                                                                   \
	$mainRecipe
d-i partman-efi/non_efi_system boolean true")
		else
			normalRecipes=$(echo -e "d-i partman-auto/choose_recipe select normal
d-i partman-auto/expert_recipe string normal :: \
	$gptForBios                                 \
	$swapRecipe                                 \
	$mainRecipe
")
		fi
		FormatDisk=$(echo -e "$selectDisks
d-i partman-auto/method string regular
d-i partman-basicfilesystems/no_swap boolean false
$normalRecipes
$gptPartitionPreseed
")
	elif [[ "$1" == 'centos' ]] || [[ "$1" == 'rockylinux' ]] || [[ "$1" == 'almalinux' ]] || [[ "$1" == 'fedora' ]]; then
		ksIncDisk=$(echo $9 | cut -d'/' -f 3)
		ksAllDisks=$(echo ${10} | sed 's/\/dev\///g' | sed 's/ /,/g')
		if [[ -n "$swapSpace" && "$swapSpace" -gt "512" ]]; then
			swapRecipe='part swap --ondisk='${ksIncDisk}' --size='${swapSpace}'\n'
		elif [[ -z "$swapSpace" || "$swapSpace" -le "512" ]]; then
			swapRecipe='part swap --ondisk='${ksIncDisk}' --size=512\n'
		fi
		[[ "$2" -le "1" || "$4" != "all" ]] && {
			clearPart="clearpart --drives=${ksIncDisk} --all --initlabel"
			if [[ "$7" == "enabled" ]]; then
				FormatDisk=$(echo -e "part / --fstype="xfs" --ondisk="$ksIncDisk" --grow --size="0"\n${swapRecipe}part /boot --fstype="xfs" --ondisk="$ksIncDisk" --size="1024"\npart /boot/efi --fstype="efi" --ondisk="$ksIncDisk" --size="512"")
			else
				FormatDisk=$(echo -e "part / --fstype="xfs" --ondisk="$ksIncDisk" --grow --size="0"\n${swapRecipe}part /boot --fstype="xfs" --ondisk="$ksIncDisk" --size="1024"\npart biosboot --fstype=biosboot --ondisk="$ksIncDisk" --size=1")
			fi
		}
		[[ "$4" == "all" || -n "$setRaid" ]] && {
			clearPart="clearpart --all --initlabel"
			FormatDisk="autopart"
		}
	fi
}

setRaidRecipe() {
	[[ -n "$1" ]] && {
		if [[ "$1" == "0" || "$1" == "1" || "$1" == "5" || "$1" == "6" || "$1" == "10" ]]; then
			[[ "$1" == "0" || "$1" == "1" ]] && [[ "$2" -lt "2" ]] && {
				error "There are $2 drives on your machine, Raid $1 partition recipe only supports a basic set of dual drive or more!\n"
				exit 1
			}
			[[ "$1" == "5" ]] && [[ "$2" -lt "3" ]] && {
				error "There are $2 drives on your machine, Raid $1 partition recipe only supports a basic set of triple drive or more!\n"
				exit 1
			}
			[[ "$1" == "6" || "$1" == "10" ]] && [[ "$2" -lt "4" ]] && {
				error "There are $2 drives on your machine, Raid $1 partition recipe only supports a basic set of quad drive or more!\n"
				exit 1
			}
		else
			error "Raid $1 partition recipe is not suitable, only Raid 0, 1, 5, 6 or 10 is supported!\n"
			exit 1
		fi
		if [[ "$4" == 'debian' ]] || [[ "$4" == 'kali' ]]; then
			defaultFileSystem='d-i partman/default_filesystem string ext4'
			for ((r = 1; r <= "$2"; r++)); do
				tmpAllDisksPart=$(echo "$3" | cut -d ' ' -f"$r")
				echo "${tmpAllDisksPart: -1}" | [[ -n "$(sed -n '/^[0-9][0-9]*$/p')" ]] && tmpAllDisksPart="$tmpAllDisksPart""p" || tmpAllDisksPart="$tmpAllDisksPart"
				AllDisksPart1+="$tmpAllDisksPart""1#"
				AllDisksPart2+="$tmpAllDisksPart""2#"
				AllDisksPart3+="$tmpAllDisksPart""3#"
			done
			AllDisksPart1=$(echo "$AllDisksPart1" | sed 's/.$//')
			AllDisksPart2=$(echo "$AllDisksPart2" | sed 's/.$//')
			AllDisksPart3=$(echo "$AllDisksPart3" | sed 's/.$//')
			RaidRecipes=$(echo -e "d-i partman-md/confirm boolean true
d-i partman-md/confirm_nooverwrite boolean true
d-i partman-md/confirm_nochanges boolean false
d-i partman-basicfilesystems/no_swap boolean false
d-i partman-auto/method string raid
d-i partman-auto/disk string $3
d-i mdadm/boot_degraded boolean true")
			if [[ "$EfiSupport" == "enabled" ]]; then
				FormatDisk=$(echo -e "$RaidRecipes
d-i partman-auto-raid/recipe string     \
	1  $2 0 ext4 /boot $AllDisksPart2 . \
	$1 $2 0 ext4 /     $AllDisksPart3 .
d-i partman-auto/expert_recipe string multiraid ::                                                            \
	538  100 1076 free \$bootable{ } \$primary{ } method{ efi } \$iflabel{ gpt } \$reusemethod{ } format{ } . \
	1076 150 2152 raid               \$primary{ } method{ raid } .                                            \
	100  200 -1   raid               \$primary{ } method{ raid } .
d-i partman-efi/non_efi_system boolean true
d-i partman-partitioning/choose_label select gpt
d-i partman-partitioning/default_label string gpt")
			else
				FormatDisk=$(echo -e "$RaidRecipes
d-i partman-auto-raid/recipe string     \
	1  $2 0 ext4 /boot $AllDisksPart1 . \
	$1 $2 0 ext4 /     $AllDisksPart2 .
d-i partman-auto/expert_recipe string multiraid ::                 \
	1076 100 2152 raid \$bootable{ } \$primary{ } method{ raid } . \
	100  200 -1   raid               \$primary{ } method{ raid } .
")
			fi
		elif [[ "$4" == 'centos' ]] || [[ "$4" == 'rockylinux' ]] || [[ "$4" == 'almalinux' ]] || [[ "$4" == 'fedora' ]]; then
			tmpKsAllDisks=$(echo "$3" | sed 's/\/dev\///g')
			ksRaidVolumes=()
			ksRaidConfigs=""
			ksRaidRecipes=""
			if [[ "$EfiSupport" == "enabled" ]]; then
				for ((partitionIndex = 0; partitionIndex <= "2"; partitionIndex++)); do
					disksIndex="1"
					for currentDisk in $tmpKsAllDisks; do
						tmpKsRaidVolumes="raid."$partitionIndex""$disksIndex""
						if [[ "$partitionIndex" == "0" ]]; then
							tmpKsRaidConfigs="part "$tmpKsRaidVolumes" --size="1024" --ondisk="$currentDisk""
						elif [[ "$partitionIndex" == "1" ]]; then
							tmpKsRaidConfigs="part "$tmpKsRaidVolumes" --size="512" --ondisk="$currentDisk""
						elif [[ "$partitionIndex" == "2" ]]; then
							tmpKsRaidConfigs="part "$tmpKsRaidVolumes" --size="0" --grow --ondisk="$currentDisk""
						fi
						disksIndex=$(expr "$disksIndex" + 1)
						ksRaidVolumes[$partitionIndex]+=""$tmpKsRaidVolumes" "
						ksRaidConfigs+=""$tmpKsRaidConfigs"\n"
					done
				done
				ksRaidConfigs=$(echo -e "$ksRaidConfigs")
				ksRaidRecipes=$(echo -e "raid /boot --fstype="xfs" --device="boot" --level="1" ${ksRaidVolumes[0]}
raid /boot/efi --fstype="efi" --device="boot-efi" --level="1" ${ksRaidVolumes[1]}
raid / --fstype="xfs" --device="root" --level="$1" ${ksRaidVolumes[2]}
")
			else
				for ((partitionIndex = 0; partitionIndex <= "2"; partitionIndex++)); do
					disksIndex="1"
					for currentDisk in $tmpKsAllDisks; do
						tmpKsRaidVolumes="raid."$partitionIndex""$disksIndex""
						if [[ "$partitionIndex" == "0" ]]; then
							tmpKsRaidConfigs="part biosboot --fstype="biosboot" --size="1" --ondisk="$currentDisk""
						elif [[ "$partitionIndex" == "1" ]]; then
							tmpKsRaidConfigs="part "$tmpKsRaidVolumes" --size="1024" --ondisk="$currentDisk""
						elif [[ "$partitionIndex" == "2" ]]; then
							tmpKsRaidConfigs="part "$tmpKsRaidVolumes" --size="0" --grow --ondisk="$currentDisk""
						fi
						disksIndex=$(expr "$disksIndex" + 1)
						ksRaidVolumes[$partitionIndex]+=""$tmpKsRaidVolumes" "
						ksRaidConfigs+=""$tmpKsRaidConfigs"\n"
					done
				done
				ksRaidConfigs=$(echo -e "$ksRaidConfigs")
				ksRaidRecipes=$(echo -e "raid /boot --fstype="xfs" --device="boot" --level="1" ${ksRaidVolumes[1]}
raid / --fstype="xfs" --device="root" --level="$1" ${ksRaidVolumes[2]}
")
			fi
			FormatDisk="${ksRaidConfigs}
${ksRaidRecipes}"
		else
			echo -e "\n${CLR1}[Warning]${CLR0} Raid $1 recipe is not supported by target system!"
			exit 1
		fi
	}
}

getUserTimeZone() {
	if [[ ! "$TimeZone" =~ ^[a-zA-Z] ]]; then
		loginUser=$(who am i | awk '{print $1}' | sed 's/(//g' | sed 's/)//g')
		[[ -z "$loginUser" ]] && loginUser="root"
		[[ "${#loginUser}" -ge "7" ]] && loginUser=$(echo ${loginUser:0:7})
		GuestIP=$(netstat -naputeoW | grep -i 'established' | grep -i 'sshd: '$loginUser'' | grep -iw '^tcp\|udp' | awk '{print $3,$5}' | sort -t ' ' -k 1 -rn | awk '{print $2}' | head -n 1 | cut -d':' -f'1')
		if [[ ! -z "$GuestIP" ]]; then
			checkIfIpv4AndIpv6IsLocalOrPublic "$GuestIP" ""
			[[ "$ipv4LocalOrPublicStatus" == '1' ]] && {
				GuestIP=$(timeout 0.3s dig -4 TXT +short o-o.myaddr.l.google.com @ns3.google.com | sed 's/\"//g')
				[[ "$GuestIP" == "" ]] && GuestIP=$(timeout 0.3s dig -4 TXT CH +short whoami.cloudflare @1.0.0.3 | sed 's/\"//g')
			}
		else
			GuestIP=$(netstat -naputeoW | grep -i 'established' | grep -i 'sshd: '$loginUser'' | grep -iw '^tcp6\|udp6' | awk '{print $3,$5}' | sort -t ' ' -k 1 -rn | awk '{print $2}' | head -n 1 | awk -F':' '{for (i=1;i<=NF-1;i++)printf("%s:", $i);print ""}' | sed 's/.$//')
			checkIfIpv4AndIpv6IsLocalOrPublic "" "$GuestIP"
			[[ "$ipv6LocalOrPublicStatus" == '1' ]] && {
				GuestIP=$(timeout 0.3s dig -6 TXT +short o-o.myaddr.l.google.com @ns3.google.com | sed 's/\"//g')
				[[ "$GuestIP" == "" ]] && GuestIP=$(timeout 0.3s dig -6 TXT CH +short whoami.cloudflare @2606:4700:4700::1003 | sed 's/\"//g')
			}
		fi
		for Count in "$2$GuestIP" "$3$GuestIP" "$4$GuestIP" "$5$GuestIP/json/" "$6" "$7" "$8"; do
			[[ "$TimeZone" == "Asia/Shanghai" ]] && break
			if [[ "$Count" =~ ^[a-zA-Z0-9]+$ ]]; then
				tmpApi=$(echo -n "$Count" | base64 -d)
				Count="https://api.ipgeolocation.io/timezone?apiKey=$tmpApi&ip=$GuestIP"
			fi
			TimeZone=$(curl -s "$Count" -A firefox 2>/dev/null | jq '.timezone, .time_zone' 2>/dev/null | grep -v "null" | tr -d '"')
			checkTz=$(echo $TimeZone | cut -d'/' -f 1)
			[[ -n "$checkTz" && "$checkTz" =~ ^[a-zA-Z] ]] && break
		done
		[[ -z "$TimeZone" ]] && TimeZone="Asia/Tokyo"
	else
		echo $(timedatectl list-timezones) >>"$1"
		[[ $(grep -c "$TimeZone" "$1") == "0" || ! "/usr/share/zoneinfo/$1" ]] && TimeZone="Asia/Tokyo"
		rm -rf "$1"
	fi
}

checkEfi() {
	EfiStatus=$(efibootmgr l)
	EfiVars=""
	for Count in "$1" "$2" "$3" "$4"; do
		EfiVars=$(ls -Sa $Count | wc -l)
		[[ "$EfiVars" -ge "1" ]] && break
	done
	if [[ "$EfiStatus" == "" ]] || [[ "$EfiVars" == "0" ]]; then
		EfiSupport="disabled"
	elif [[ -n $(echo "$EfiStatus" | grep -i "bootcurrent" | awk '{print $2}' | sed -n '/^[[:xdigit:]]*$/p' | head -n 1) || -n $(echo "$EfiStatus" | grep -i "bootorder" | awk '{print $2}' | awk -F ',' '{print $NF}' | sed -n '/^[[:xdigit:]]*$/p' | head -n 1) ]] && [[ "$EfiVars" != "0" ]]; then
		EfiSupport="enabled"
	else
		error "UEFI boot firmware of your system could not be confirmed!\n"
		exit 1
	fi
}

checkGrub() {
	GRUBDIR=""
	GRUBFILE=""
	for Count in "$4" "$5"; do
		GRUBFILE=$(find "$6" -name "$Count")
		if [[ -n "$GRUBFILE" ]]; then
			GRUBDIR=$(echo "$GRUBFILE" | sed "s/$Count//g")
			GRUBFILE="$Count"
			break
		fi
	done
	GRUBDIR=$(echo $GRUBDIR | awk '{print $1}')
	if [[ -z "$GRUBFILE" ]] || [[ $(grep -c "insmod*" $GRUBDIR$GRUBFILE) == "0" ]] || [[ -n "$GRUBFILE" && $(grep -c "insmod*" $GRUBDIR$GRUBFILE) != "0" && "$EfiSupport" == "disabled" ]]; then
		for Count in "$1" "$2" "$3"; do
			if [[ -f "$Count""$4" ]] && [[ $(grep -c "insmod*" $Count$4) -ge "1" ]]; then
				GRUBDIR="$Count"
				GRUBFILE="$4"
			elif [[ -f "$Count""$5" ]] && [[ $(grep -c "insmod*" $Count$5) -ge "1" ]]; then
				GRUBDIR="$Count"
				GRUBFILE="$5"
			fi
		done
	fi
	GRUBDIR=$(echo ${GRUBDIR%?})
	if [[ $(awk '/menuentry*/{print NF}' $GRUBDIR/$GRUBFILE | head -n 1) -ge "1" ]] || [[ $(awk '/feature*/{print $a}' $GRUBDIR/$GRUBFILE | head -n 1) != "" ]] || [[ $(awk '/insmod*/{print $a}' $GRUBDIR/$GRUBFILE | head -n 1) != "" ]]; then
		if [[ -n $(grep -w "grub2-.*" $GRUBDIR/$GRUBFILE) ]] || [[ $(type grub2-mkconfig) != "" ]]; then
			GRUBTYPE="isGrub2"
		elif [[ -n $(grep -w "grub-.*" $GRUBDIR/$GRUBFILE) ]] || [[ $(type grub-mkconfig) != "" ]]; then
			GRUBTYPE="isGrub1"
		elif [[ "$CurrentOS" == "CentOS" || "$CurrentOS" == "OracleLinux" ]] && [[ "$CurrentOSVer" -le "6" ]]; then
			GRUBTYPE="isGrub1"
		fi
	fi
}

checkAndReplaceEfiGrub() {
	if [[ "$VER" == "aarch64" || "$VER" == "arm64" ]] && [[ "$EfiSupport" == "enabled" ]] && [[ "$linux_release" == 'alpinelinux' ]]; then
		[[ "$AlpineVer1" == "3" && "$AlpineVer2" -ge "19" ]] || [[ "$DIST" == "edge" ]] && {
			efiGrubFull=$(find "/boot/efi/EFI/" -name "*.efi" | grep -i "grub" | head -n 1)
			[[ -z "$efiGrubFull" ]] && {
				grub-install
				efiGrubFull=$(find "/boot/efi/EFI/" -name "*.efi" | grep -i "grub" | head -n 1)
			}
			efiGrubDir=$(echo ${efiGrubFull%/*}"/")
			efiGrubFile=$(echo $efiGrubFull | awk -F "/" '{print $NF}')
			mv "$efiGrubFull" "$efiGrubFull"".bak"
			if [[ "$IsCN" == "1" ]]; then
				aarch64EfiGrubMirror="https://mirrors.tuna.tsinghua.edu.cn/opensuse/ports/aarch64/tumbleweed/repo/oss/EFI/BOOT/"
			else
				aarch64EfiGrubMirror="http://download.opensuse.org/ports/aarch64/tumbleweed/repo/oss/EFI/BOOT/"
			fi
			aarch64EfiGrubUrl="$aarch64EfiGrubMirror""grub.efi"
			curl -ksLo "$efiGrubDir$efiGrubFile" "$aarch64EfiGrubUrl"
		}
	fi
}

checkConsole() {
	for ttyItems in "console=tty" "console=ttyAMA" "console=ttyS"; do
		[[ $(grep "$ttyItems" $GRUBDIR/$GRUBFILE) ]] && {
			ttyConsole+="${ttyItems}0 "
		}
	done
	if [[ "$1" == "aarch64" || "$1" == "arm64" ]]; then
		[[ ! "$ttyConsole" =~ "ttyS" ]] && {
			if [[ $(echo "$ttyConsole" | grep "tty[0-9]") ]]; then
				ttyConsole="${ttyConsole} console=ttyS0 "
			else
				ttyConsole="${ttyConsole} console=tty1 console=ttyS0 "
			fi
		}
	fi
	ttyConsole=$(echo "$ttyConsole" | sed 's/console=tty[0-9]/console=tty1/g' | sed 's/console=ttyAMA[0-9]/console=ttyAMA0,115200n8/g' | sed 's/console=ttyS[0-9]/console=ttyS0,115200n8/g' | sed 's/.$//')
	[[ "$ttyConsole" =~ "ttyS" ]] && serialConsolePropertiesForGrub="$ttyConsole earlyprintk=ttyS0,115200n8 consoleblank=0"
	[[ "$1" == "aarch64" || "$1" == "arm64" ]] || ttyConsole=""
}

checkMem() {
	TotalMem=$(($(dmesg | grep -i 'memory' | grep -i 'available' | awk -F ':' '{print $2}' | awk '{print $1}' | cut -d '/' -f 2 | tr -d "a-zA-Z") / 1024))
	[[ -z "$TotalMem" ]] && TotalMem=$(lsmem -b | grep -i "online memory" | awk '{print $NF/1024/1024}')
	[[ -z "$TotalMem" ]] && TotalMem=$(($(cat /proc/meminfo | grep "^MemTotal:" | sed 's/kb//i' | grep -o "[0-9]*" | awk -F' ' '{print $NF}') / 1024))
	[[ -z "$TotalMem" ]] && TotalMem=$(free -m | grep -wi "mem*" | awk '{printf $2}')

	[[ "$1" == 'debian' ]] || [[ "$1" == 'ubuntu' ]] || [[ "$1" == 'kali' ]] && {
		[[ "$TotalMem" -le "672" ]] && lowMemMode="1"
		if [[ "$TotalMem" -le "448" ]]; then
			lowmemLevel="lowmem=+1"
		elif [[ "$TotalMem" -le "1500" ]]; then
			lowmemLevel="lowmem=+0"
		else
			lowmemLevel=""
		fi
		[[ "$setMemCheck" == '1' ]] && {
			[[ "$TotalMem" -le "336" ]] && {
				error "Minimum system memory requirement is 384 MB!\n"
				exit 1
			}
		}
	}
	[[ "$setMemCheck" == '1' ]] && {
		[[ "$1" == 'fedora' || "$1" == 'rockylinux' || "$1" == 'almalinux' || "$1" == 'centos' ]] && {
			[[ "$TotalMem" -le "448" ]] && {
				error "Minimum system memory requirement is 512 MB!\n"
				exit 1
			}
			if [[ "$1" == 'rockylinux' || "$1" == 'almalinux' || "$1" == 'centos' ]]; then
				if [[ "$2" == "8" ]] || [[ "$2" == "9" ]]; then
					[[ "$TotalMem" -le "2228" ]] && {
						echo -e "\n${CLR1}[Warning]${CLR0} Minimum system memory requirement is 2.2 GiB for ${CLR6}KickStart${CLR0} native method."
						lowMemMode="1"
						if [[ "$2" == "8" ]]; then
							echo -e "\nSwitching to ${CLR3}Rocky $2${CLR0} by ${CLR6}Cloud Init${CLR0} Installation..."
						elif [[ "$2" == "9" ]]; then
							echo -e "\nSwitching to ${CLR6}Cloud Init${CLR0} Installation..."
						fi
					}
				elif [[ "$2" == "7" ]]; then
					[[ "$TotalMem" -le "1500" ]] && {
						error "Minimum system memory requirement is 1.5 GiB!\n"
						exit 1
					}
				fi
			elif [[ "$1" == 'fedora' ]]; then
				[[ "$TotalMem" -le "1722" ]] && {
					error "Minimum system memory requirement is 1.7 GiB!\n"
					exit 1
				}
			fi
		}
		[[ "$1" == 'alpinelinux' || "$3" == 'Ubuntu' ]] && {
			if [[ "$3" == 'Ubuntu' ]]; then
				[[ "$TotalMem" -le "448" ]] && {
					error "Minimum system memory requirement is 512 MB!\n"
					exit 1
				}
			elif [[ "$1" == 'alpinelinux' ]]; then
				[[ "$TotalMem" -le "228" ]] && {
					error "Minimum system memory requirement is 256 MB!\n"
					exit 1
				}
				[[ "$TotalMem" -le "736" ]] && {
					lowMemMode="1"
					setMotd="0"
				}
			fi
		}
		[[ "$linux_release" == 'debian' && "$DebianDistNum" -le "8" ]] && setFail2banStatus="0"
	}
}

updateStatus() {
	statusVar="$1"
	configFlag="$2"
	if [[ "$configFlag" == "1" ]]; then
		eval "$statusVar=1"
		echo -e "${CLR2}$statusVar=1${CLR0}"
	else
		eval "$statusVar=0"
		echo -e "${CLR1}$statusVar=0${CLR0}"
	fi
}
updateStatus "setFail2banStatus" "$setFail2ban"
updateStatus "setKejilionStatus" "$setKejilion"
[[ "$setKejilionStatus" == "1" ]] && {
	DebianEnableKejilion="in-target curl -sS -o /usr/local/bin/k https://kejilion.pro/kejilion.sh; in-target chmod +x /usr/local/bin/k;"
	CentosEnableKejilion="curl -sS -o /usr/local/bin/k https://kejilion.pro/kejilion.sh; chmod +x /usr/local/bin/k;"
} || {
	DebianEnableKejilion=""
	CentosEnableKejilion=""
}

checkVirt() {
	virtWhat=""
	virtType=""
	[[ -n $(virt-what) ]] && {
		for virtItem in $(virt-what); do
			virtWhat+="$virtItem "
		done
		[[ $(echo $virtWhat | grep -i "openvz") || $(echo $virtWhat | grep -i "lxc") ]] && {
			error "Virtualization of ${CLR3}$virtWhat${CLR0}could not be supported!\n"
			echo -e "\nTry to refer to the ${CLR6}following project${CLR0}: \n\n${underLine}https://github.com/LloydAsp/OsMutation${CLR0} \n\nfor learning more and then execute it as the re-installation."
			exit 1
		}
	}
	for virtItem in $(dmidecode -s system-manufacturer | sed 's/[[:space:]]//g' | sed 's/[A-Z]/\l&/g') $(systemd-detect-virt | sed 's/[A-Z]/\l&/g') $(lscpu | grep -i "hypervisor vendor" | cut -d ':' -f 2 | sed 's/^[ \t]*//g' | sed 's/[A-Z]/\l&/g'); do
		virtType+="$virtItem "
	done
	showAllVirts=$(echo "$virtType$virtWhat" | sed 's/[[:space:]]/\n/g' | sort -u | tr -s '\n' ' ' | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g')
}

checkSys() {
	aliyundunProcess=$(ps -ef | grep -i 'aegis\|aliyun\|aliyundun\|assist-daemon' | grep -v 'grep\|-i' | awk -F ' ' '{print $NF}')
	[[ -n "$aliyundunProcess" ]] && {
		timeout 5s curl -ksLo /root/Fuck_Aliyun.sh 'https://git.io/fpN6E' && chmod a+x /root/Fuck_Aliyun.sh
		if [[ $? -ne 0 ]]; then
			curl -ksLo /root/Fuck_Aliyun.sh 'https://gitee.com/mb9e8j2/Fuck_Aliyun/raw/master/Fuck_Aliyun.sh' && sed -i 's/\r//g' /root/Fuck_Aliyun.sh && chmod a+x /root/Fuck_Aliyun.sh
		fi
		bash /root/Fuck_Aliyun.sh
		rm -rf /root/Fuck_Aliyun.sh
	}

	rm -rf /swapspace
	if [[ ! -e "/swapspace" ]]; then
		fallocate -l 512M /swapspace
		chmod 600 /swapspace
		mkswap /swapspace
		swapon /swapspace
		[[ $(cat /proc/sys/vm/swappiness | sed 's/[^0-9]//g') -lt "70" ]] && sysctl vm.swappiness=70
	fi

	sed -i 's/^\(deb.*security.debian.org\/\)\(.*\)\/updates/\1debian-security\2-security/g' /etc/apt/sources.list

	CurrentOSVer=$(cat /etc/os-release | grep -w "VERSION_ID=*" | awk -F '=' '{print $2}' | sed 's/\"//g' | cut -d'.' -f 1)

	apt update -y
	if [[ $? -ne 0 ]]; then
		apt update -y >/root/apt_execute.log
		if [[ $(grep -i "debian" /root/apt_execute.log) ]] && [[ $(grep -i "err:[0-9]" /root/apt_execute.log) || $(grep -i "404  not found" /root/apt_execute.log) ]]; then
			currentDebianMirror=$(sed -n '/^deb /'p /etc/apt/sources.list | head -n 1 | awk '{print $2}' | sed -e 's|^[^/]*//||' -e 's|/.*$||')
			if [[ "$CurrentOSVer" -gt "9" ]]; then
				sed -ri "s/$currentDebianMirror/deb.debian.org/g" /etc/apt/sources.list
			else
				sed -ri "s/$currentDebianMirror/archive.debian.org/g" /etc/apt/sources.list
			fi
			sed -ri 's/^deb-src/# deb-src/g' /etc/apt/sources.list
			apt update -y
		fi
		rm -rf /root/apt_execute.log
	fi
	apt install lsb-release -y

	[[ $(grep -wri "elrepo.org" /etc/yum.repos.d/) != "" ]] && {
		elrepoFile=$(grep -wri "elrepo.org" /etc/yum.repos.d/ | head -n 1 | cut -d':' -f 1)
		mv "$elrepoFile" "$elrepoFile.bak"
	}
	yum install redhat-lsb -y
	OsLsb=$(lsb_release -d | awk '{print$2}')

	RedHatRelease=""
	for Count in $(cat /etc/redhat-release | awk '{print$1}') $(cat /etc/system-release | awk '{print$1}') $(cat /etc/os-release | grep -w "ID=*" | awk -F '=' '{print $2}' | sed 's/\"//g') "$OsLsb"; do
		[[ -n "$Count" ]] && RedHatRelease=$(echo -e "$Count")"$RedHatRelease"
	done

	DebianRelease=""
	IsUbuntu=$(uname -a | grep -i "ubuntu")
	IsDebian=$(uname -a | grep -i "debian")
	IsKali=$(uname -a | grep -i "kali")
	for Count in $(cat /etc/os-release | grep -w "ID=*" | awk -F '=' '{print $2}') $(cat /etc/issue | awk '{print $1}') "$OsLsb"; do
		[[ -n "$Count" ]] && DebianRelease=$(echo -e "$Count")"$DebianRelease"
	done

	AlpineRelease=""
	apk update
	for Count in $(cat /etc/os-release | grep -w "ID=*" | awk -F '=' '{print $2}') $(cat /etc/issue | awk '{print $3}' | head -n 1) $(uname -v | awk '{print $1}' | sed 's/[^a-zA-Z]//g'); do
		[[ -n "$Count" ]] && AlpineRelease=$(echo -e "$Count")"$AlpineRelease"
	done

	if [[ $(echo "$RedHatRelease" | grep -i 'centos') != "" ]]; then
		CurrentOS="CentOS"
	elif [[ $(echo "$RedHatRelease" | grep -i 'cloudlinux') != "" ]]; then
		CurrentOS="CloudLinux"
	elif [[ $(echo "$RedHatRelease" | grep -i 'alma') != "" ]]; then
		CurrentOS="AlmaLinux"
	elif [[ $(echo "$RedHatRelease" | grep -i 'rocky') != "" ]]; then
		CurrentOS="RockyLinux"
	elif [[ $(echo "$RedHatRelease" | grep -i 'fedora') != "" ]]; then
		CurrentOS="Fedora"
	elif [[ $(echo "$RedHatRelease" | grep -i 'virtuozzo') != "" ]]; then
		CurrentOS="Vzlinux"
	elif [[ $(echo "$RedHatRelease" | grep -i 'ol\|oracle') != "" ]]; then
		CurrentOS="OracleLinux"
	elif [[ $(echo "$RedHatRelease" | grep -i 'opencloud') != "" ]]; then
		CurrentOS="OpenCloudOS"
	elif [[ $(echo "$RedHatRelease" | grep -i 'alibaba\|alinux\|aliyun') != "" ]]; then
		CurrentOS="AlibabaCloudLinux"
	elif [[ $(echo "$RedHatRelease" | grep -i 'amazon\|amzn') != "" ]]; then
		CurrentOS="AmazonLinux"
		amazon-linux-extras install epel -y
	elif [[ $(echo "$RedHatRelease" | grep -i 'red\|rhel') != "" ]]; then
		CurrentOS="RedHatEnterpriseLinux"
	elif [[ $(echo "$RedHatRelease" | grep -i 'anolis') != "" ]]; then
		CurrentOS="OpenAnolis"
	elif [[ $(echo "$RedHatRelease" | grep -i 'scientific') != "" ]]; then
		CurrentOS="ScientificLinux"
	elif [[ $(echo "$AlpineRelease" | grep -i 'alpine') != "" ]]; then
		CurrentOS="AlpineLinux"
	elif [[ "$IsUbuntu" ]] || [[ $(echo "$DebianRelease" | grep -i 'ubuntu') != "" ]]; then
		CurrentOS="Ubuntu"
		CurrentOSVer=$(lsb_release -r | awk '{print$2}' | cut -d'.' -f1)
	elif [[ "$IsDebian" ]] || [[ $(echo "$DebianRelease" | grep -i 'debian') != "" ]]; then
		CurrentOS="Debian"
		CurrentOSVer=$(lsb_release -r | awk '{print$2}' | cut -d'.' -f1)
	elif [[ "$IsKali" ]] || [[ $(echo "$DebianRelease" | grep -i 'kali') != "" ]]; then
		CurrentOS="Kali"
		CurrentOSVer=$(lsb_release -r | awk '{print$2}' | cut -d'.' -f1)
	else
		error "Does't support your system!\n"
		exit 1
	fi
	if [[ "$CurrentOS" == "CentOS" || "$CurrentOS" == "OracleLinux" ]] && [[ "$CurrentOSVer" -le "6" ]]; then
		echo -e "Does't support your system!\n"
		exit 1
	fi

	apt purge inetutils-ping kdump-tools kexec-tools -y
	apt install cpio curl dmidecode dnsutils efibootmgr fdisk file gzip iputils-ping jq net-tools openssl tuned util-linux virt-what wget xz-utils -y

	yum install dnf -y
	if [[ $? -eq 0 ]]; then
		[[ "$CurrentOS" == "CentOS" && "$CurrentOSVer" == "8" ]] && dnf install python3-librepo -y
		dnf install epel-release -y
		dnf install bind-utils cpio curl dmidecode dnsutils efibootmgr file gzip jq net-tools openssl redhat-lsb syslinux tuned util-linux virt-what wget xz --skip-broken -y
	else
		yum install dnf -y >/root/yum_execute.log 2>&1
		if [[ $(grep -i "failed to\|no urls in mirrorlist" /root/yum_execute.log) ]]; then
			if [[ "$CurrentOS" == "CentOS" ]]; then
				cd /etc/yum.repos.d/
				sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
				baseRepo=$(ls /etc/yum.repos.d/ | grep -i "base\|cr" | head -n 1)
				currentRedhatMirror=$(sed -n '/^#baseurl=\|^baseurl=/'p /etc/yum.repos.d/$baseRepo | head -n 1 | awk -F '=' '{print $2}' | sed -e 's|^[^/]*//||' -e 's|/.*$||')
				sed -ri 's/#baseurl/baseurl/g' /etc/yum.repos.d/CentOS-*
				sed -ri 's/'$currentRedhatMirror'/vault.centos.org/g' /etc/yum.repos.d/CentOS-*
				[[ "$CurrentOSVer" == "8" ]] && dnf install python3-librepo -y
			fi
			yum install dnf -y
			dnf install epel-release -y
			dnf install bind-utils cpio curl dmidecode dnsutils efibootmgr file gzip jq net-tools openssl redhat-lsb syslinux tuned util-linux virt-what wget xz --skip-broken -y
		elif [[ $(grep -i "no package" /root/yum_execute.log) ]]; then
			yum install epel-release -y
			yum install bind-utils cpio curl dmidecode dnsutils efibootmgr file gzip jq net-tools openssl redhat-lsb syslinux tuned util-linux virt-what wget xz --skip-broken -y
		fi
		rm -rf /root/yum_execute.log
	fi

	[[ "$CurrentOS" == "AlpineLinux" ]] && {
		CurrentAlpineVer=$(cut -d. -f1,2 </etc/alpine-release)
		sed -i 's/#//' /etc/apk/repositories
		[[ ! $(grep -i "community" /etc/apk/repositories) ]] && sed -i '$a\http://dl-cdn.alpinelinux.org/alpine/v'${CurrentAlpineVer}'/community' /etc/apk/repositories
		apk update
		apk add bash bind-tools coreutils cpio curl dmidecode efibootmgr file gawk grep gzip jq lsblk net-tools openssl sed shadow tzdata util-linux virt-what wget xz
		sed -i 's/root:\/bin\/ash/root:\/bin\/bash/g' /etc/passwd
	}
}

checkVER() {
	ArchName=$(uname -m)
	[[ -z "$ArchName" ]] && ArchName=$(echo $(hostnamectl status | grep "Architecture" | cut -d':' -f 2))
	case $ArchName in
		arm64) VER="arm64" ;;
		aarch64) VER="aarch64" ;;
		x86 | i386 | i686) VER="i386" ;;
		x86_64) VER="x86_64" ;;
		x86-64) VER="x86-64" ;;
		amd64) VER="amd64" ;;
		*) VER="" ;;
	esac
	if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'ubuntu' ]] || [[ "$linux_release" == 'kali' ]]; then
		if [[ "$VER" == "x86_64" ]] || [[ "$VER" == "x86-64" ]]; then
			VER="amd64"
		elif [[ "$VER" == "aarch64" ]]; then
			VER="arm64"
		fi
	elif [[ "$linux_release" == 'alpinelinux' ]] || [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
		if [[ "$VER" == "amd64" ]] || [[ "$VER" == "x86-64" ]]; then
			VER="x86_64"
		elif [[ "$VER" == "arm64" ]]; then
			VER="aarch64"
		fi
	fi

	tmpVER="$(echo "$tmpVER" | sed -r 's/(.*)/\L\1/')"
	if [[ -n "$tmpVER" ]]; then
		case "$tmpVER" in
		i386 | i686 | x86 | 32)
			VER="i386"
			;;
		amd64 | x86_64 | x64 | 64)
			[[ "$linux_release" == 'alpinelinux' ]] || [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]] && VER='x86_64' || VER='amd64'
			;;
		aarch64 | arm64 | arm)
			[[ "$linux_release" == 'alpinelinux' ]] || [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]] && VER='aarch64' || VER='arm64'
			;;
		*)
			VER=''
			;;
		esac
	fi

	[[ ! -n "$VER" ]] && {
		error "Unknown architecture.\n"
		bash $0 error
		exit 1
	}
}

checkDIST() {
	if [[ "$Relese" == 'Debian' ]]; then
		SpikCheckDIST='0'
		DIST="$(echo "$tmpDIST" | sed -r 's/(.*)/\L\1/')"
		DebianDistNum="${DIST}"
		echo "$DIST" | grep -q '[0-9]'
		[[ $? -eq '0' ]] && {
			isDigital="$(echo "$DIST" | grep -o '[\.0-9]\{1,\}' | sed -n '1h;1!H;$g;s/\n//g;$p' | cut -d'.' -f1)"
			[[ -n $isDigital ]] && {
				[[ "$isDigital" == '7' ]] && DIST='wheezy'
				[[ "$isDigital" == '8' ]] && DIST='jessie'
				[[ "$isDigital" == '9' ]] && DIST='stretch'
				[[ "$isDigital" == '10' ]] && DIST='buster'
				[[ "$isDigital" == '11' ]] && DIST='bullseye'
				[[ "$isDigital" == '12' ]] && DIST='bookworm'
				# [[ "$isDigital" == '13' ]] && DIST='trixie'
			}
		}
		LinuxMirror=$(selectMirror "$Relese" "$DIST" "$VER" "$tmpMirror")
	fi
	if [[ "$Relese" == 'Kali' ]]; then
		SpikCheckDIST='0'
		DIST="$(echo "$tmpDIST" | sed -r 's/(.*)/\L\1/')"
		[[ ! "$DIST" =~ "kali-" ]] && DIST="kali-""$DIST"
		LinuxMirror=$(selectMirror "$Relese" "$DIST" "$VER" "$tmpMirror")
	fi
	if [[ "$Relese" == 'AlpineLinux' ]]; then
		SpikCheckDIST='0'
		DIST="$(echo "$tmpDIST" | sed -r 's/(.*)/\L\1/')"
		AlpineVer1=$(echo "$DIST" | sed 's/[a-z][A-Z]*//g' | cut -d"." -f 1)
		AlpineVer2=$(echo "$DIST" | sed 's/[a-z][A-Z]*//g' | cut -d"." -f 2)
		if [[ "$AlpineVer1" -lt "3" || "$AlpineVer2" -le "15" ]] && [[ "$DIST" != "edge" ]]; then
			echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DIST is not supported!"
			exit 1
		fi
		[[ "$DIST" != "edge" && ! "$DIST" =~ "v" ]] && DIST="v""$DIST"
		if [[ "$setCloudKernel" == "" ]]; then
			[[ -n "$virtWhat" ]] && virtualizationStatus='1' || virtualizationStatus='0'
		elif [[ "$setCloudKernel" == "1" ]]; then
			virtualizationStatus='1'
		fi
		if [[ "$virtualizationStatus" == "1" && "$IPStackType" != "IPv6Stack" ]]; then
			InitrdName="initramfs-virt"
			VmLinuzName="vmlinuz-virt"
			ModLoopName="modloop-virt"
		else
			InitrdName="initramfs-lts"
			VmLinuzName="vmlinuz-lts"
			ModLoopName="modloop-lts"
		fi
		LinuxMirror=$(selectMirror "$Relese" "$DIST" "$VER" "$tmpMirror")
	fi
	if [[ "$Relese" == 'CentOS' ]] || [[ "$Relese" == 'RockyLinux' ]] || [[ "$Relese" == 'AlmaLinux' ]] || [[ "$Relese" == 'Fedora' ]]; then
		SpikCheckDIST='1'
		DISTCheck="$(echo "$tmpDIST" | grep -o '[\.0-9]\{1,\}' | head -n1)"
		RedHatSeries=$(echo "$tmpDIST" | cut -d"." -f 1 | cut -d"-" -f 1)
		if [[ "$linux_release" == 'centos' ]]; then
			[[ "$RedHatSeries" =~ [0-9]{${#1}} ]] && {
				if [[ "$RedHatSeries" == "6" ]]; then
					DISTCheck="6.10"
					echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DISTCheck is not supported!"
					exit 1
				elif [[ "$RedHatSeries" == "7" ]]; then
					DISTCheck="7.9.2009"
				elif [[ "$RedHatSeries" -ge "8" ]] && [[ ! "$RedHatSeries" =~ "-stream" ]]; then
					DISTCheck="$RedHatSeries""-stream"
				elif [[ "$RedHatSeries" -le "5" ]]; then
					echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DISTCheck is not supported!"
				else
					error "Invaild $DIST! version!\n"
				fi
			}
			LinuxMirror=$(selectMirror "$Relese" "$DISTCheck" "$VER" "$tmpMirror")
			DIST="$DISTCheck"
		fi
		if [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
			[[ "$RedHatSeries" =~ [0-9]{${#1}} ]] && {
				if [[ "$linux_release" == 'rockylinux' || "$linux_release" == 'almalinux' ]] && [[ "$RedHatSeries" -le "7" ]]; then
					echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DISTCheck is not supported!"
					exit 1
				elif [[ "$linux_release" == 'fedora' ]] && [[ "$RedHatSeries" -le "37" ]]; then
					echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DISTCheck is not supported!"
					exit 1
				fi
			}
			LinuxMirror=$(selectMirror "$Relese" "$DISTCheck" "$VER" "$tmpMirror")
			DIST="$DISTCheck"
		fi
		[[ -z "$DIST" ]] && {
			echo -e "\nThe dists version not found in this mirror, Please check it!\n"
			bash $0 error
			exit 1
		}
		if [[ "$linux_release" == 'centos' ]] && [[ "$RedHatSeries" -le "7" ]]; then
			curl -ksL "$LinuxMirror/$DIST/os/$VER/.treeinfo" | grep -q 'general'
			[[ $? != '0' ]] && {
				echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DISTCheck was not found in this mirror, Please change mirror try again!"
				exit 1
			}
		elif [[ "$linux_release" == 'centos' && "$RedHatSeries" -ge "8" ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]]; then
			curl -ksL "$LinuxMirror/$DIST/BaseOS/$VER/os/media.repo" | grep -q 'mediaid'
			[[ $? != '0' ]] && {
				echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DISTCheck was not found in this mirror, Please change mirror try again!"
				exit 1
			}
		elif [[ "$linux_release" == 'fedora' ]]; then
			curl -ksL "$LinuxMirror/releases/$DIST/Server/$VER/os/media.repo" | grep -q 'mediaid'
			[[ $? != '0' ]] && {
				echo -e "\n${CLR1}[Warning]${CLR0} $Relese $DISTCheck was not found in this mirror, Please change mirror try again!"
				exit 1
			}
		fi
	fi
}

checkIpv4OrIpv6() {
	for ((w = 1; w <= 2; w++)); do
		IPv4DNSLookup=$(timeout 0.3s dig -4 TXT +short o-o.myaddr.l.google.com @ns3.google.com | sed 's/\"//g')
		[[ "$IPv4DNSLookup" == "" ]] && IPv4DNSLookup=$(timeout 0.3s dig -4 TXT CH +short whoami.cloudflare @1.0.0.3 | sed 's/\"//g')
		[[ "$IPv4DNSLookup" != "" ]] && break
	done
	for ((x = 1; x <= 2; x++)); do
		IPv6DNSLookup=$(timeout 0.3s dig -6 TXT +short o-o.myaddr.l.google.com @ns3.google.com | sed 's/\"//g')
		[[ "$IPv6DNSLookup" == "" ]] && IPv6DNSLookup=$(timeout 0.3s dig -6 TXT CH +short whoami.cloudflare @2606:4700:4700::1003 | sed 's/\"//g')
		[[ "$IPv6DNSLookup" != "" ]] && break
	done
	for y in "$3" "$4" "$5" "$6"; do
		IPv4PingDNS=$(timeout 0.3s ping -4 -c 1 "$y" | grep "rtt\|round-trip" | cut -d'/' -f5 | awk -F'.' '{print $NF}' | sed -E '/^[0-9]\+\(\.[0-9]\+\)\?$/p')"$IPv4PingDNS"
		[[ "$IPv4PingDNS" != "" ]] && break
	done
	for z in "$7" "$8" "$9" "${10}"; do
		IPv6PingDNS=$(timeout 0.3s ping -6 -c 1 "$z" | grep "rtt\|round-trip" | cut -d'/' -f5 | awk -F'.' '{print $NF}' | sed -E '/^[0-9]\+\(\.[0-9]\+\)\?$/p')"$IPv6PingDNS"
		[[ "$IPv6PingDNS" != "" ]] && break
	done

	[[ "$IPv4PingDNS" =~ ^[0-9] && "$IPv6PingDNS" =~ ^[0-9] ]] && IPStackType="BiStack"
	[[ "$IPv4PingDNS" =~ ^[0-9] && ! "$IPv6PingDNS" =~ ^[0-9] ]] && IPStackType="IPv4Stack"
	[[ ! "$IPv4PingDNS" =~ ^[0-9] && "$IPv6PingDNS" =~ ^[0-9] ]] && IPStackType="IPv6Stack"
	[[ -n "$1" || -n "$2" ]] && {
		if [[ -n "$1" && -z "$2" ]]; then
			for ipCheck in "$1" "$ipGate"; do
				verifyIPv4FormatLawfulness "$ipCheck"
			done
		elif [[ -n "$1" && -n "$2" ]]; then
			for ipCheck in "$1" "$ipGate"; do
				verifyIPv4FormatLawfulness "$ipCheck"
			done
			for ipCheck in "$2" "$ip6Gate"; do
				verifyIPv6FormatLawfulness "$ipCheck"
			done
			IPStackType="BiStack"
		elif [[ -z "$1" && -n "$2" ]]; then
			for ipCheck in "$2" "$ip6Gate"; do
				verifyIPv6FormatLawfulness "$ipCheck"
			done
		fi
	}

	[[ $(echo "$setIpStack" | grep -i "bi\|bistack\|dual\|two") ]] && IPStackType="BiStack"
	[[ $(echo "$setIpStack" | grep -i "4\|i4\|ip4\|ipv4") ]] && IPStackType="IPv4Stack"
	[[ $(echo "$setIpStack" | grep -i "6\|i6\|ip6\|ipv6") ]] && IPStackType="IPv6Stack"

	[[ "$tmpSetIPv6" == "0" ]] && setIPv6="0" || setIPv6="1"
}

verifyIPv4FormatLawfulness() {
	[[ -n "$1" ]] && IP_Check="$1"
	if expr "$IP_Check" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
		for i in 1 2 3 4; do
			if [ $(echo "$IP_Check" | cut -d. -f$i) -gt 255 ]; then
				echo "fail ($IP_Check)"
				exit 1
			fi
		done
		IP_Check="isIPv4"
	fi
	[[ "$IP_Check" != "isIPv4" ]] && {
		error "Invalid inputted IPv4 format!\n"
		exit 1
	}
}

verifyIPv6FormatLawfulness() {
	[[ -n "$1" ]] && IPv6_Check="$1"
	[[ "${IPv6_Check: -1}" == ":" ]] && IPv6_Check=$(echo "$IPv6_Check" | sed 's/.$/0/')
	[[ "${IPv6_Check:0:1}" == ":" ]] && IPv6_Check=$(echo "$IPv6_Check" | sed 's/^./0/')
	IP6_Check_Temp="$IPv6_Check"":"
	IP6_Hex_Num=$(echo "$IP6_Check_Temp" | tr -cd ":" | wc -c)
	IP6_Hex_Abbr="0"
	if [[ $(echo "$IPv6_Check" | grep -i '[[:xdigit:]]' | grep ':') ]] && [[ "$IP6_Hex_Num" -le "8" ]]; then
		[[ $(echo "$1" | grep -o ":::" | wc -l) -gt "0" ]] || [[ $(echo "$1" | grep -o "::" | wc -l) -gt "1" || $(echo "$1" | grep -o ":" | wc -l) -gt "7" ]] || [[ "$IP6_Hex_Num" -le "7" && $(echo "$1" | grep -o "::" | wc -l) -lt "1" ]] || [[ "${1: -2}" != "::" && "${1: -1}" == ":" ]] && {
			error "Invalid inputted IPv6 format!\n"
			exit 1
		}
		for ((i = 1; i <= "$IP6_Hex_Num"; i++)); do
			IP6_Hex=$(echo "$IP6_Check_Temp" | cut -d: -f$i)
			[[ "$IP6_Hex" == "" ]] && IP6_Hex_Abbr=$(expr $IP6_Hex_Abbr + 1)
			if [[ $(echo "$IP6_Hex" | wc -m) -le "5" ]]; then
				[[ $(echo "$IP6_Hex" | grep -iE '[^0-9a-f]') || "$IP6_Hex_Abbr" -gt "1" ]] && {
					error "Invalid inputted IPv6 format!\n"
					exit 1
				}
			else
				error "Invalid inputted IPv6 format!\n"
				exit 1
			fi
		done
		IP6_Check="isIPv6"
	fi
	[[ "$IP6_Check" != "isIPv6" ]] && {
		error "Invalid inputted IPv6 format!\n"
		exit 1
	}
}

checkIfIpv4AndIpv6IsLocalOrPublic() {
	ipv4LocalOrPublicStatus=''
	ipv6LocalOrPublicStatus=''
	ip4CertFirst=''
	ip4CertSecond=''
	ip4CertThird=''
	ip6CertAddrWhole=''
	ip6CertAddrFirst=''
	[[ -n "$1" ]] && {
		ip4CertFirst=$(echo $1 | cut -d'.' -f1)
		ip4CertSecond=$(echo $1 | cut -d'.' -f2)
		ip4CertThird=$(echo $1 | cut -d'.' -f3)
		[[ "$ip4CertFirst" == "169" && "$ip4CertSecond" == "254" ]] || [[ "$ip4CertFirst" == "172" && "$ip4CertSecond" -ge "16" && "$ip4CertSecond" -le "31" ]] || [[ "$ip4CertFirst" == "192" && "$ip4CertSecond" == "168" ]] || [[ "$ip4CertFirst" == "100" && "$ip4CertSecond" -ge "64" && "$ip4CertSecond" -le "127" ]] || [[ "$ip4CertFirst" == "10" && "$ip4CertSecond" -ge "0" && "$ip4CertSecond" -le "255" ]] || [[ "$ip4CertFirst" == "127" && "$ip4CertSecond" -ge "0" && "$ip4CertSecond" -le "255" ]] || [[ "$ip4CertFirst" == "198" && "$ip4CertSecond" -ge "18" && "$ip4CertSecond" -le "19" ]] || [[ "$ip4CertFirst" == "192" && "$ip4CertSecond" == "0" && "$ip4CertThird" == "0" || "$ip4CertThird" == "2" ]] || [[ "$ip4CertFirst" == "198" && "$ip4CertSecond" == "51" && "$ip4CertThird" == "100" ]] || [[ "$ip4CertFirst" == "203" && "$ip4CertSecond" == "0" && "$ip4CertThird" == "113" ]] && {
			ipv4LocalOrPublicStatus='1'
		}
	}
	[[ -n "$2" ]] && {
		ip6CertAddrWhole=$(ultimateFormatOfIpv6 "$2")
		ip6CertAddrFirst=$(echo $ip6CertAddrWhole | sed 's/\(.\{4\}\).*/\1/' | sed 's/[a-z]/\u&/g')
		[[ "$((16#$ip6CertAddrFirst))" -ge "$((16#FE80))" && "$((16#$ip6CertAddrFirst))" -le "$((16#FEBF))" ]] || [[ "$((16#$ip6CertAddrFirst))" -ge "$((16#FC00))" && "$((16#$ip6CertAddrFirst))" -le "$((16#FDFF))" ]] && {
			ipv6LocalOrPublicStatus='1'
		}
	}
}

checkWarp() {
	warpConfFiles=$(find / -maxdepth 6 -name "$1" -print -or -name "$2" -print -or -name "$3" -print)
	sysctlWarpProcess=$(systemctl 2>&1 | grep -i "$4\|$5\|$6" | wc -l)
	rcWarpProcess=$(rc-status 2>&1 | grep -i "$4\|$5\|$6" | wc -l)
	[[ "$IPStackType" == "BiStack" ]] && {
		[[ -n "$warpConfFiles" ]] && {
			for warpConfFile in $(find / -maxdepth 6 -name "$1" -print -or -name "$2" -print -or -name "$3" -print); do
				if [[ $(grep -ic "$7" "$warpConfFile") -ge "1" || $(grep -ic "$8" "$warpConfFile") -ge "1" ]]; then
					warpStatic="1"
					break
				fi
			done
		}
		[[ "$sysctlWarpProcess" -gt "0" || "$rcWarpProcess" -gt "0" ]] && warpStatic="1"
	}
	[[ "$warpStatic" == "1" ]] && {
		[[ -z "$ipGate" ]] && IPStackType="IPv6Stack"
		[[ -z "$ip6Gate" ]] && IPStackType="IPv4Stack"
	}
}

fillAbbrOfIpv6() {
	inputIpv6="$1"
	delimiterNum=$(echo $inputIpv6 | awk '{print gsub(/:/, "")}')
	replaceStr=""
	for ((i = 0; i <= $((7 - $delimiterNum)); i++)); do
		replaceStr="$replaceStr"":0"
	done
	replaceStr="$replaceStr"":"
	ipv6Expanded=${inputIpv6/::/$replaceStr}
	[[ "$ipv6Expanded" == *: ]] && ipv6Expanded="$ipv6Expanded""0"
	[[ "$ipv6Expanded" == :* ]] && ipv6Expanded="0""$ipv6Expanded"
	echo "$ipv6Expanded"
}

ultimateFormatOfIpv6() {
	abbrExpandedOfIpv6=$(fillAbbrOfIpv6 "$1")
	ipv6Hex=(${abbrExpandedOfIpv6//:/ })
	for ((j = 0; j < 8; j++)); do
		length="${#ipv6Hex[j]}"
		for ((k = 4; k > $length; k--)); do
			ipv6Hex[j]="0${ipv6Hex[j]}"
		done
	done
	echo ${ipv6Hex[@]} | sed 's/ /\:/g'
}

getIPv6Address() {
	allI6Addrs=$(ip -6 addr show | grep -wA 32768 "$interface6" | grep -wv "lo" | grep -wv "link\|host" | grep -w "inet6" | grep "scope" | grep "global" | awk -F " " '{for (i=2;i<=NF;i++)printf("%s ", $i);print ""}' | awk '{print $1}')
	i6Addr=$(echo "$allI6Addrs" | head -n 1)
	i6AddrNum=$(echo "$allI6Addrs" | wc -l)
	collectAllIpv6Addresses "$i6AddrNum"
	ip6Addr=$(echo ${i6Addr} | cut -d'/' -f1)
	ip6Mask=$(echo ${i6Addr} | cut -d'/' -f2)
	ip6Gate=$(ip -6 route show default | grep -iv "warp\|wgcf\|wg[0-9]\|docker[0-9]" | grep -w "$interface6" | grep -w "via" | grep "dev" | head -n 1 | awk -F " " '{for (i=3;i<=NF;i++)printf("%s ", $i);print ""}' | awk '{print$1}')
	actualIp6Prefix=$(ip -6 route show | grep -iv "warp\|wgcf\|wg[0-9]\|docker[0-9]" | grep -w "$interface6" | grep -v "default" | grep -v "multicast" | grep -P '../[0-9]{1,3}' | head -n 1 | awk '{print $1}' | awk -F '/' '{print $2}')
	[[ -z "$actualIp6Prefix" || "$i6AddrNum" -ge "2" ]] && actualIp6Prefix="$ip6Mask"
	transferIPv6AddressFormat "$ip6Addr" "$ip6Gate"
}

transferIPv6AddressFormat() {
	[[ "$BiStackPreferIpv6Status" == "1" ]] && Network6Config="isStatic"
	[[ "$Network6Config" == "isStatic" ]] && {
		ip6AddrWhole=$(ultimateFormatOfIpv6 "$1")
		ip6GateWhole=$(ultimateFormatOfIpv6 "$2")
		tmpIp6AddrFirst=$(echo $ip6AddrWhole | sed 's/\(.\{4\}\).*/\1/' | sed 's/[a-z]/\u&/g')
		tmpIp6GateFirst=$(echo $ip6GateWhole | sed 's/\(.\{4\}\).*/\1/' | sed 's/[a-z]/\u&/g')
		if [[ "$tmpIp6AddrFirst" != "$tmpIp6GateFirst" ]]; then
			checkIfIpv4AndIpv6IsLocalOrPublic "" "$2"
			if [[ "$ipv6LocalOrPublicStatus" == '1' ]]; then
				tmpIp6Mask="64"
				[[ "$linux_release" == 'debian' && -n $(echo $tmpDIST | grep -o "[0-9]") && "$tmpDIST" -le "11" && "$IPStackType" == "IPv6Stack" && "$Network6Config" == "isStatic" ]] && BurnIrregularIpv6Status='1'
			else
				tmpIp6Mask="1"
			fi
		else
			ipv6SubnetCertificate "$ip6AddrWhole" "$ip6GateWhole"
		fi
		[[ "$tmpIp6Mask" -le "16" ]] && {
			[[ "$BiStackPreferIpv6Status" == "1" ]] || [[ "$linux_release" == 'debian' || "$linux_release" == 'kali' && "$IPStackType" == "IPv6Stack" && "$Network6Config" == "isStatic" ]] && BurnIrregularIpv6Status='1'
		}
		ip6Mask="$tmpIp6Mask"
		ipv6SubnetCalc "$ip6Mask"
	}
}

ipv6SubnetCertificate() {
	[[ $(echo $1 | cut -d':' -f 1) == $(echo $2 | cut -d':' -f 1) ]] && tmpIp6Mask="16"
	[[ $(echo $1 | cut -d':' -f 1,2) == $(echo $2 | cut -d':' -f 1,2) ]] && tmpIp6Mask="32"
	[[ $(echo $1 | cut -d':' -f 1,2,3) == $(echo $2 | cut -d':' -f 1,2,3) ]] && tmpIp6Mask="48"
	[[ $(echo $1 | cut -d':' -f 1,2,3,4) == $(echo $2 | cut -d':' -f 1,2,3,4) ]] && tmpIp6Mask="64"
	[[ $(echo $1 | cut -d':' -f 1,2,3,4,5) == $(echo $2 | cut -d':' -f 1,2,3,4,5) ]] && tmpIp6Mask="80"
	[[ $(echo $1 | cut -d':' -f 1,2,3,4,5,6) == $(echo $2 | cut -d':' -f 1,2,3,4,5,6) ]] && tmpIp6Mask="96"
	[[ $(echo $1 | cut -d':' -f 1,2,3,4,5,6,7) == $(echo $2 | cut -d':' -f 1,2,3,4,5,6,7) ]] && tmpIp6Mask="112"
}

ipv6SubnetCalc() {
	tmpIp6Subnet=""
	ip6Subnet=""
	ip6SubnetEleNum=$(expr $1 / 4)
	ip6SubnetEleNumRemain=$(expr $1 - $ip6SubnetEleNum \* 4)
	if [[ "$ip6SubnetEleNumRemain" == 0 ]]; then
		ip6SubnetHex="0"
	elif [[ "$ip6SubnetEleNumRemain" == 1 ]]; then
		ip6SubnetHex="8"
	elif [[ "$ip6SubnetEleNumRemain" == 2 ]]; then
		ip6SubnetHex="c"
	elif [[ "$ip6SubnetEleNumRemain" == 3 ]]; then
		ip6SubnetHex="e"
	fi
	for ((i = 1; i <= "$ip6SubnetEleNum"; i++)); do
		tmpIp6Subnet+="f"
	done
	tmpIp6Subnet=$tmpIp6Subnet$ip6SubnetHex
	for ((j = 1; j <= $(expr 32 - $ip6SubnetEleNum); j++)); do
		tmpIp6Subnet+="0"
	done
	if [[ $(echo $tmpIp6Subnet | wc -c) -ge "33" ]]; then
		tmpIp6Subnet=$(echo $tmpIp6Subnet | sed 's/.$//')
	fi
	for ((k = 0; k <= 7; k++)); do
		ip6Subnet+=$(echo ${tmpIp6Subnet:$(expr $k \* 4):4})":"
	done
	ip6Subnet=$(echo ${ip6Subnet%?})
}

collectAllIpv4Addresses() {
	[[ "$1" -ge "2" && "$IPStackType" != "IPv6Stack" ]] && {
		Network4Config="isStatic"
		iAddrs=()
		for tmpIp in $allI4Addrs; do
			iAddrs[${#iAddrs[@]}]=$tmpIp
		done
	}
}

writeMultipleIpv4Addresses() {
	[[ "$1" -ge "2" && "$IPStackType" != "IPv6Stack" ]] && {
		if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]]; then
			unset iAddrs[0]
			for writeIps in ${iAddrs[@]}; do
				ipAddrItem="up ip addr add $writeIps dev $interface4"
				tmpWriteIpsCmd+=''$2' sed -i '\''$a\\t'$ipAddrItem''\'' '$3'; '
			done
			writeIpsCmd=$(echo $tmpWriteIpsCmd)
			SupportMultipleIPv4="$writeIpsCmd"
		elif [[ "$targetRelese" == 'Ubuntu' ]] || [[ "$targetRelese" == 'AlmaLinux' ]] || [[ "$targetRelese" == 'Rocky' ]]; then
			for writeIps in ${iAddrs[@]}; do
				ipAddrItem="$writeIps"
				tmpWriteIpsCmd+=''$ipAddrItem','
			done
			writeIpsCmd=$(echo ''$tmpWriteIpsCmd'' | sed 's/.$//')
		elif [[ "$linux_release" == 'alpinelinux' ]]; then
			unset iAddrs[0]
			for writeIps in ${iAddrs[@]}; do
				ipAddrItem="up ip addr add $writeIps dev $interface4"
				tmpWriteIpsCmd+='\t'$ipAddrItem'\n'
			done
			writeIpsCmd=$(echo $tmpWriteIpsCmd | sed 's/..$//')
		elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
			for ((tmpIpIndex = "0"; tmpIpIndex < "$1"; tmpIpIndex++)); do
				writeIps="${iAddrs[$tmpIpIndex]}"
				ipv4AddressOrder=$(expr $tmpIpIndex + 1)
				ipAddrItem+='address'$ipv4AddressOrder'='$writeIps','$ipGate'\n'
			done
			ipAddrItem=$(echo ''$ipAddrItem'' | sed 's/..$//')
			deleteOriginalIpv4Coning='sed -ri '\''/address1.*/d'\'' '$3''
			addIpv4AddrsForRedhat='sed -i '\''/\[ipv4\]/a\'$ipAddrItem''\'' '$3''
		fi
	}
}

collectAllIpv6Addresses() {
	[[ "$1" -ge "2" && "$IPStackType" != "IPv4Stack" ]] && {
		Network6Config="isStatic"
		i6Addrs=()
		for tmpIp6 in $allI6Addrs; do
			i6Addrs[${#i6Addrs[@]}]=$tmpIp6
		done
		if [[ "$IPStackType" == "IPv6Stack" ]] || [[ "$IPStackType" == "BiStack" && -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]]; then
			allI6AddrsWithoutSuffix=()
			for tmpIp6 in ${i6Addrs[@]}; do
				tmpIp6=$(echo $tmpIp6 | cut -d'/' -f1)
				allI6AddrsWithoutSuffix[${#allI6AddrsWithoutSuffix[@]}]=$tmpIp6
			done
			allI6AddrsWithUltimateFormat=()
			for tmpIp6 in ${allI6AddrsWithoutSuffix[@]}; do
				tmpIp6=$(ultimateFormatOfIpv6 "$tmpIp6")
				allI6AddrsWithUltimateFormat[${#allI6AddrsWithUltimateFormat[@]}]=$tmpIp6
			done
			allI6AddrsWithOmittedClassesNum=()
			for tmpIp6 in ${allI6AddrsWithUltimateFormat[@]}; do
				tmpIp6=$(echo $tmpIp6 | grep -oi "0000" | wc -l)
				allI6AddrsWithOmittedClassesNum[${#allI6AddrsWithOmittedClassesNum[@]}]=$tmpIp6
			done
			omittedClassesMaxNum=${allI6AddrsWithOmittedClassesNum[0]}
			for tmpIp6 in ${!allI6AddrsWithOmittedClassesNum[@]}; do
				if [[ "$omittedClassesMaxNum" -le "${allI6AddrsWithOmittedClassesNum[${tmpIp6}]}" ]]; then
					omittedClassesMaxNum=${allI6AddrsWithOmittedClassesNum[${tmpIp6}]}
				fi
			done
			getArrItemIdx "${allI6AddrsWithOmittedClassesNum[*]}" "$omittedClassesMaxNum"
			mainIp6Index="$index"
			i6Addr=${i6Addrs[$mainIp6Index]}
		fi
	}
}

writeMultipleIpv6Addresses() {
	[[ "$1" -ge "2" && "$IPStackType" != "IPv4Stack" ]] && {
		if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]]; then
			if [[ "$IPStackType" == "IPv6Stack" ]] || [[ "$IPStackType" == "BiStack" && -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]]; then
				unset i6Addrs[$mainIp6Index]
			fi
			for writeIp6s in ${i6Addrs[@]}; do
				[[ "$IPStackType" == "BiStack" && -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]] && ip6AddrItem="up ip -6 addr add $writeIp6s dev $interface6" || ip6AddrItem="up ip addr add $writeIp6s dev $interface6"
				tmpWriteIp6sCmd+=''$2' sed -i '\''$a\\t'$ip6AddrItem''\'' '$3'; '
			done
			writeIp6sCmd=$(echo $tmpWriteIp6sCmd)
			writeIp6GateCmd=''$2' sed -i '\''$a\\tup ip -6 route add '$ip6Gate' dev '$interface6''\'' '$3'; '$2' sed -i '\''$a\\tup ip -6 route add default via '$ip6Gate' dev '$interface6''\'' '$3';'
			addIpv6DnsForPreseed=''$2' sed -ri '\''s/'$ipDNS'/'$ipDNS' '$ip6DNS'/g'\'' '$3';'
			preferIpv6Access=''$2' sed -i '\''$alabel 2002::/16'\'' /etc/gai.conf; '$2' sed -i '\''$alabel 2001:0::/32'\'' /etc/gai.conf;'
			SupportMultipleIPv6=''$writeIp6sCmd' '$writeIp6GateCmd' '$addIpv6DnsForPreseed' '$preferIpv6Access''
			[[ "$IPStackType" == "IPv6Stack" ]] && SupportIPv6orIPv4=''$writeIp6sCmd' '$preferIpv6Access''
			[[ "$IPStackType" == "BiStack" && -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]] && {
				addIpv6Adapter=''$2' sed -i '\''$a\ '\'' '$3'; '$2' sed -i '\''$aallow-hotplug '$interface6''\'' '$3';'
				addFirstIpv6Config=''$2' sed -i '\''$aiface '$interface6' inet6 static'\'' '$3'; '$2' sed -i '\''$a\\taddress '$i6Addr''\'' '$3'; '$2' sed -i '\''$a\\tgateway '$ip6Gate''\'' '$3'; '$2' sed -i '\''$a\\tdns-nameservers '$ip6DNS''\'' '$3';'
				SupportMultipleIPv6=''$addIpv6Adapter' '$addFirstIpv6Config' '$writeIp6sCmd' '$preferIpv6Access''
			}
		elif [[ "$targetRelese" == 'Ubuntu' ]] || [[ "$targetRelese" == 'AlmaLinux' ]] || [[ "$targetRelese" == 'Rocky' ]]; then
			for writeIp6s in ${i6Addrs[@]}; do
				ip6AddrItem="$writeIp6s"
				tmpWriteIp6sCmd+=''$ip6AddrItem','
			done
			writeIp6sCmd=$(echo ''$tmpWriteIp6sCmd'' | sed 's/.$//')
		elif [[ "$linux_release" == 'alpinelinux' ]]; then
			[[ "$IPStackType" == "IPv6Stack" ]] && unset i6Addrs[$mainIp6Index]
			for writeIp6s in ${i6Addrs[@]}; do
				if [[ "$IPStackType" == "BiStack" ]]; then
					ip6AddrItem="up ip addr add $writeIp6s dev $interface6"
					tmpWriteIp6sCmd+='\t'$ip6AddrItem'\n'
				elif [[ "$IPStackType" == "IPv6Stack" ]]; then
					ip6AddrItem="up ip -6 addr add $writeIp6s dev $interface6"
					tmpWriteIp6sCmd+='\t'$ip6AddrItem'\n'
				fi
			done
			if [[ "$IPStackType" == "BiStack" ]]; then
				writeIp6sCmd=''$tmpWriteIp6sCmd'\tup ip -6 route add '$ip6Gate' dev '$interface6'\n\tup ip -6 route add default via '$ip6Gate' dev '$interface6''
			elif [[ "$IPStackType" == "IPv6Stack" ]]; then
				writeIp6sCmd=$(echo $tmpWriteIp6sCmd | sed 's/..$//')
			fi
		elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
			for ((tmpI6Index = "0"; tmpI6Index < "$1"; tmpI6Index++)); do
				writeIp6s="${i6Addrs[$tmpI6Index]}"
				ipv6AddressOrder=$(expr $tmpI6Index + 1)
				ip6AddrItem+='address'$ipv6AddressOrder'='$writeIp6s','$ip6Gate'\n'
			done
			ip6AddrItems=''$ip6AddrItem''
			addIpv6DnsForRedhat='dns='$ip6DNS1';'$ip6DNS2';'
			addIpv6AddrsForRedhat='sed -i '\''/addr-gen-mode=eui64/a\'$ip6AddrItems''$addIpv6DnsForRedhat''\'' '$3''
			setIpv6ConfigMethodForRedhat='sed -ri '\'':label;N;s/addr-gen-mode=eui64\nmethod=auto/addr-gen-mode=eui64\nmethod=manual/;b label'\'' '$3''
			[[ "$IPStackType" == "IPv6Stack" ]] && {
				ip6AddrItems=$(echo $ip6AddrItem | sed 's/..$//')
				deleteOriginalIpv6Coning='sed -ri '\''/address1.*/d'\'' '$3''
				addIpv6AddrsForRedhat='sed -i '\''/addr-gen-mode=eui64/a\'$ip6AddrItems''\'' '$3''
				setIpv6ConfigMethodForRedhat=""
			}
		fi
	}
}

sortFileSize() {
	FilesDirArr=()
	FilesLineArr=()
	FilesDir="$1"

	for Count in $FilesDir; do
		FilesDirArr+=($Count)
		FilesDirNum=$(cat $Count | wc -c)
		FilesLineArr+=($FilesDirNum)
	done

	tmpSizeArray=($(echo ${FilesLineArr[*]} | tr ' ' '\n' | $2))
}

getArrItemIdx() {
	arr=$1
	item=$2
	index=0

	for i in ${arr[*]}; do
		[[ $item == $i ]] && {
			echo $index >>/dev/null 2>&1
			return
		}
		index=$(($index + 1))
	done
}

splitDirAndFile() {
	FileName=$(echo $1 | awk -F/ '{print $NF}')
	FileDirection=$(echo $1 | sed "s/$FileName//g")
}

getLargestOrSmallestFile() {
	for Count in "$1"; do
		sortFileSize "$Count" "$2"
		getArrItemIdx "${FilesLineArr[*]}" "${tmpSizeArray[0]}"
		fullFilePath="${FilesDirArr[$index]}"
		[[ "$fullFilePath" != "" ]] && {
			splitDirAndFile "$fullFilePath"
			break
		}
	done
}

parseYaml() {
	prefix=$2
	s='[[:space:]]*' w='[a-zA-Z0-9_]*'
	fs=$(echo @ | tr @ '\034')
	sed -ne "s|,$s\]$s\$|]|" \
		-e ":1;s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: [\3]\n\1  - \4|;t1" \
		-e "s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s\]|\1\2:\n\1  - \3|;p" $1 |
		sed -ne "s|,$s}$s\$|}|" \
			-e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1  \3: \4|;t1" \
			-e "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1  \2|;p" |
		sed -ne "s|^\($s\):|\1|" \
			-e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p" \
			-e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|p" \
			-e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
			-e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
		awk -F$fs '{
	indent=length($1)/2
	vname[indent]=$2
	for (i in vname) {if (i>indent) {delete vname[i]; idx[i]=0}}
	if (length($2)==0) {vname[indent]= ++idx[indent]}
	if (length($3)>0) {
	  vn=""
	  for (i=0;i<indent;i++) {vn=(vn)(vname[i])("_")}
	  printf("%s%s%s=\"%s\"\n","'$prefix'",vn,vname[indent],$3)
	}
  }'
}

getInterface() {
	interface=""
	Interfaces=()
	allInterfaces=$(cat /proc/net/dev | grep ':' | cut -d':' -f1 | sed 's/\s//g' | grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn\|^warp\|^wgcf\|^wg\|^docker' | sort -n)
	for interfaceItem in $allInterfaces; do
		Interfaces[${#Interfaces[@]}]=$interfaceItem
	done
	interfacesNum="${#Interfaces[*]}"
	default4Route=$(ip -4 route show default | grep -A 3 "^default")
	default6Route=$(ip -6 route show default | grep -A 3 "^default")
	for item in ${Interfaces[*]}; do
		[ -n "$item" ] || continue
		echo "$default4Route" | grep -q "$item"
		[ $? -eq 0 ] && interface4="$item" && break
	done
	for item in ${Interfaces[*]}; do
		[ -n "$item" ] || continue
		echo "$default6Route" | grep -q "$item"
		[ $? -eq 0 ] && interface6="$item" && break
	done
	interface="$interface4 $interface6"
	[[ "$interface4" == "$interface6" ]] && interface=$(echo "$interface" | cut -d' ' -f 1)
	[[ -z "$interface4" || -z "$interface6" ]] && {
		interface=$(echo "$interface" | sed 's/[[:space:]]//g')
		[[ -z "$interface4" ]] && interface4="$interface"
		[[ -z "$interface6" ]] && interface6="$interface"
	}
	echo "$interface" >/dev/null
	getArrItemIdx "${Interfaces[*]}" "$interface4"
	interface4DeviceOrder="$index"
	getArrItemIdx "${Interfaces[*]}" "$interface6"
	interface6DeviceOrder="$index"
	GrubCmdLine=$(grep "GRUB_CMDLINE_LINUX" /etc/default/grub | grep -v "#" | grep "net.ifnames=0\|biosdevname=0")
	[[ -n "$interfaceSelect" ]] && {
		interface="$interfaceSelect"
		interface4="$interface"
		interface6="$interface"
	}
	if [[ -n "$GrubCmdLine" && -z "$interfaceSelect" ]] || [[ "$interface4" =~ "eth" ]] || [[ "$interface6" =~ "eth" ]] || [[ "$linux_release" == 'kali' ]] || [[ "$linux_release" == 'alpinelinux' ]]; then
		setInterfaceName='1'
	fi
	[[ -z "$tmpDHCP" ]] && {
		if [[ "$1" == 'CentOS' || "$1" == 'AlmaLinux' || "$1" == 'RockyLinux' || "$1" == 'Fedora' || "$1" == 'Vzlinux' || "$1" == 'OracleLinux' || "$1" == 'OpenCloudOS' || "$1" == 'AlibabaCloudLinux' || "$1" == 'ScientificLinux' || "$1" == 'AmazonLinux' || "$1" == 'RedHatEnterpriseLinux' || "$1" == 'OpenAnolis' || "$1" == 'CloudLinux' ]]; then
			[[ ! $(find / -maxdepth 5 -path /*network-scripts -type d -print -or -path /*system-connections -type d -print) ]] && {
				error "Invalid network configuration!\n"
				exit 1
			}
			NetCfgWhole=()
			tmpNetCfgFiles=""
			for Count in $(find / -maxdepth 5 -path /*network-scripts -type d -print -or -path /*system-connections -type d -print); do
				NetCfgDir="$Count""/"
				NetCfgFiles=$(ls -Sl $NetCfgDir 2>/dev/null | awk -F' ' '{print $NF}' | grep -iv 'readme-\|ifcfg-lo\|ifcfg-bond\|ifup\|ifdown\|vpn\|init.ipv6-global\|network-functions\|lo.' | grep -s "ifcfg\|nmconnection")
				for Files in $NetCfgFiles; do
					if [[ $(grep -w "$interface4\|$interface6" "$NetCfgDir$Files") != "" ]]; then
						tmpNetCfgFiles+=$(echo -e "\n""$NetCfgDir$Files")
					fi
				done
				getLargestOrSmallestFile "$tmpNetCfgFiles" "sort -hr"
				NetCfgFile="$FileName"
				if [[ ! -z "$NetCfgFile" && ! -f "$NetCfgDir$NetCfgFile" ]]; then
					tmpNetcfgDir="/root/tmp/installNetcfgCollections/"
					[[ ! -d "$tmpNetcfgDir" ]] && mkdir -p "$tmpNetcfgDir"
					if [[ "$NetCfgFile" =~ "nmconnection" ]]; then
						NetCfgFile="$interface.nmconnection"
						grep -wr "$interface\|\[ipv4\]\|\[ipv6\]\|\[connection\]\|\[ethernet\]\|id=*\|interface-name=*\|type=*\|method=*" "$NetCfgDir" | cut -d ':' -f 2 | tee -a "$tmpNetcfgDir$NetCfgFile"
						NetCfgDir="$tmpNetcfgDir"
					elif [[ "$NetCfgFile" =~ "ifcfg" ]]; then
						NetCfgFile="$ifcfg-$interface"
						grep -wr "$interface\|BOOTPROTO=*\|DEVICE=*\|ONBOOT=*\|TYPE=*\|HWADDR=*\|IPV6_AUTOCONF=*\|DHCPV6C=*" "$NetCfgDir" | cut -d ':' -f 2 | tee -a "$tmpNetcfgDir$NetCfgFile"
						NetCfgDir="$tmpNetcfgDir"
					fi
				fi
				[[ $(grep -wcs "$interface4\|$interface6\|BOOTPROTO=*\|DEVICE=*\|ONBOOT=*\|TYPE=*\|HWADDR=*\|id=*\|\[connection\]\|interface-name=*\|type=*\|method=*" $NetCfgDir$NetCfgFile) -ge "3" ]] && {
					NetCfgWhole+=("$NetCfgDir$NetCfgFile")
				}
			done
			if [[ "${NetCfgWhole[1]}" != "" ]]; then
				for c in "${NetCfgWhole[@]}"; do
					[[ $(sed -e "4"p "$c" | grep " by " | grep -c "#") -ge "1" ]] && {
						NetCfgWhole="$c"
						break
					}
				done
				[[ $(declare -p NetCfgWhole 2>/dev/null | grep -iw '^declare -a') ]] && {
					NetCfgWhole="${NetCfgWhole[0]}"
				}
			fi
			splitDirAndFile "$NetCfgWhole"
			NetCfgFile="$FileName"
			NetCfgDir="$FileDirection"
		else
			readNetplan=$(find $(echo $(find / -maxdepth 4 -path /*netplan)) -maxdepth 1 -name "*.yaml" -print)
			readIfupdown=$(find / -maxdepth 5 -path /*network -type d -print | grep -v "lib\|systemd")
			if [[ ! -z "$readNetplan" ]]; then
				networkManagerType="netplan"
				tmpNetCfgFiles=""
				for Count in $readNetplan; do
					tmpNetCfgFiles+=$(echo -e "\n"$(grep -wrl "network" | grep -wrl "ethernets" | grep -wrl "$interface4\|$interface6" "$Count" 2>/dev/null))
				done
				getLargestOrSmallestFile "$tmpNetCfgFiles" "sort -hr"
				NetCfgFile="$FileName"
				NetCfgDir="$FileDirection"
				NetCfgWhole="$NetCfgDir$NetCfgFile"
			elif [[ ! -z "$readIfupdown" ]]; then
				networkManagerType="ifupdown"
				tmpNetCfgFiles=""
				for Count in $readIfupdown; do
					if [[ "$IPStackType" == "IPv4Stack" ]]; then
						NetCfgFiles=$(timeout 4s grep -wrl 'iface' | grep -wrl "auto\|dhcp\|static\|manual" | grep -wrl 'inet\|ip addr\|ip route' "$Count""/" 2>/dev/null | grep -v "if-*" | grep -v "state" | grep -v "helper" | grep -v "template")
					elif [[ "$IPStackType" == "BiStack" ]] || [[ "$IPStackType" == "IPv6Stack" ]]; then
						NetCfgFiles=$(timeout 4s grep -wrl 'iface' | grep -wrl "auto\|dhcp\|static\|manual" | grep -wrl 'inet\|ip addr\|ip route\|inet6\|ip -6' "$Count""/" 2>/dev/null | grep -v "if-*" | grep -v "state" | grep -v "helper" | grep -v "template")
					fi
					for Files in $NetCfgFiles; do
						if [[ $(timeout 4s grep -w "$interface4\|$interface6" "$Files") != "" ]]; then
							tmpNetCfgFiles+=$(echo -e "\n""$Files")
						fi
					done
				done
				getLargestOrSmallestFile "$tmpNetCfgFiles" "sort -hr"
				NetCfgFile="$FileName"
				NetCfgDir="$FileDirection"
				NetCfgWhole="$NetCfgDir$NetCfgFile"
			else
				error "Invalid network configuration!\n"
				exit 1
			fi
		fi
	}
}

acceptIPv4AndIPv6SubnetValue() {
	[[ -n "$1" ]] && {
		if [[ $(echo "$1" | grep '^[[:digit:]]*$') && "$1" -ge "1" && "$1" -le "32" ]]; then
			ipPrefix="$1"
			actualIp4Prefix="$ipPrefix"
			ipMask=$(netmask "$1")
			actualIp4Subnet=$(netmask "$1")
		else
			echo -e "\n${CLR1}[Warning]${CLR0} Only accept prefix format of IPv4 address, length from 1 to 32."
			echo -e "\nIPv4 CIDR Calculator: https://www.vultr.com/resources/subnet-calculator"
			exit 1
		fi
	}
	[[ -n "$2" ]] && {
		if [[ $(echo "$2" | grep '^[[:digit:]]*$') && "$2" -ge "1" && "$2" -le "128" ]]; then
			actualIp6Prefix="$2"
			ipv6SubnetCalc "$2"
		else
			echo -ne "\n${CLR1}[Warning]${CLR0} Only accept prefix format of IPv6 address, length from 1 to 128."
			echo -e "\nIPv6 CIDR Calculator: https://en.rakko.tools/tools/27"
			exit 1
		fi
	}
}

checkIpv4OrIpv6ConfigForRedhat9Later() {
	IpTypeLine="$(awk '/\['$3'\]/{print NR}' $1/$2 | head -n 2 | tail -n 1)"
	ConnectTypeArray=()
	CtaSpace=()
	for tmpConnectType in $(awk '/'$4'/{print NR}' $1/$2); do
		ConnectTypeArray+=("$tmpConnectType" "$ConnectTypeArray")
		[[ $(expr $tmpConnectType - $IpTypeLine) -gt "0" ]] && CtaSpace+=($(expr "$tmpConnectType" - "$IpTypeLine") "$CtaSpace")
	done
	minArray=${CtaSpace[0]}
	for ((i = 1; i <= $(grep -io "$4" $1/$2 | wc -l); i++)); do
		for j in ${CtaSpace[@]}; do
			[[ "$minArray" -gt "$j" ]] && minArray=$j
		done
	done
	NetCfgLineNum=$(expr $minArray + $IpTypeLine)
}

ipv6ForRedhatGrub() {
	if [[ "$IPStackType" == "IPv6Stack" ]]; then
		ipv6NameserverForKsGrub="nameserver=$ip6DNS1 nameserver=$ip6DNS2"
		if [[ "$Network6Config" == "isStatic" ]]; then
			ipv6StaticConfForKsGrub="noipv4 ip=[$ip6Addr]::[$ip6Gate]:$actualIp6Prefix::$interface:none $ipv6NameserverForKsGrub"
		else
			ipv6StaticConfForKsGrub="noipv4 $ipv6NameserverForKsGrub"
		fi
	fi
}

checkDHCP() {
	getInterface "$1"
	[[ -z "$tmpDHCP" ]] && {
		if [[ "$1" == 'CentOS' || "$1" == 'AlmaLinux' || "$1" == 'RockyLinux' || "$1" == 'Fedora' || "$1" == 'Vzlinux' || "$1" == 'OracleLinux' || "$1" == 'OpenCloudOS' || "$1" == 'AlibabaCloudLinux' || "$1" == 'ScientificLinux' || "$1" == 'AmazonLinux' || "$1" == 'RedHatEnterpriseLinux' || "$1" == 'OpenAnolis' || "$1" == 'CloudLinux' ]]; then
			if [[ "$NetCfgFile" =~ "ifcfg" ]]; then
				if [[ "$3" == "IPv4Stack" ]]; then
					Network6Config="isDHCP"
					[[ -n $(timeout 4s grep -Ewirn "BOOTPROTO=none|BOOTPROTO=\"none\"|BOOTPROTO=\'none\'|BOOTPROTO=NONE|BOOTPROTO=\"NONE\"|BOOTPROTO=\'NONE\'|BOOTPROTO=static|BOOTPROTO=\"static\"|BOOTPROTO=\'static\'|BOOTPROTO=STATIC|BOOTPROTO=\"STATIC\"|BOOTPROTO=\'STATIC\'" $NetCfgWhole) ]] && Network4Config="isStatic" || Network4Config="isDHCP"
				elif [[ "$3" == "BiStack" ]]; then
					[[ -n $(timeout 4s grep -Ewirn "BOOTPROTO=none|BOOTPROTO=\"none\"|BOOTPROTO=\'none\'|BOOTPROTO=NONE|BOOTPROTO=\"NONE\"|BOOTPROTO=\'NONE\'|BOOTPROTO=static|BOOTPROTO=\"static\"|BOOTPROTO=\'static\'|BOOTPROTO=STATIC|BOOTPROTO=\"STATIC\"|BOOTPROTO=\'STATIC\'" $NetCfgWhole) ]] && Network4Config="isStatic" || Network4Config="isDHCP"
					[[ -n $(timeout 4s grep -Ewirn "IPV6_AUTOCONF=yes|IPV6_AUTOCONF=\"yes\"|IPV6_AUTOCONF=YES|IPV6_AUTOCONF=\"YES\"|DHCPV6C=yes|DHCPV6C=\"yes\"" $NetCfgWhole) ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				elif [[ "$3" == "IPv6Stack" ]]; then
					Network4Config="isDHCP"
					[[ -n $(timeout 4s grep -Ewirn "IPV6_AUTOCONF=yes|IPV6_AUTOCONF=\"yes\"|IPV6_AUTOCONF=YES|IPV6_AUTOCONF=\"YES\"|DHCPV6C=yes|DHCPV6C=\"yes\"" $NetCfgWhole) ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				fi
			elif [[ "$NetCfgFile" =~ "nmconnection" ]]; then
				checkIpv4OrIpv6ConfigForRedhat9Later "$NetCfgDir" "$NetCfgFile" "ipv4" "method="
				NetCfg4LineNum="$NetCfgLineNum"
				checkIpv4OrIpv6ConfigForRedhat9Later "$NetCfgDir" "$NetCfgFile" "ipv6" "method="
				NetCfg6LineNum="$NetCfgLineNum"
				if [[ "$3" == "IPv4Stack" ]]; then
					Network6Config="isDHCP"
					[[ $(timeout 4s sed -n "$NetCfg4LineNum"p $NetCfgWhole) == "method=auto" ]] && Network4Config="isDHCP" || Network4Config="isStatic"
				elif [[ "$3" == "BiStack" ]]; then
					[[ $(timeout 4s sed -n "$NetCfg4LineNum"p $NetCfgWhole) == "method=auto" ]] && Network4Config="isDHCP" || Network4Config="isStatic"
					[[ $(timeout 4s sed -n "$NetCfg6LineNum"p $NetCfgWhole) == "method=auto" ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				elif [[ "$3" == "IPv6Stack" ]]; then
					Network4Config="isDHCP"
					[[ $(timeout 4s sed -n "$NetCfg6LineNum"p $NetCfgWhole) == "method=auto" ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				fi
			fi
		elif [[ "$1" == 'Debian' ]] || [[ "$1" == 'Kali' ]] || [[ "$1" == 'Ubuntu' ]] || [[ "$1" == 'AlpineLinux' ]]; then
			if [[ "$networkManagerType" == "ifupdown" ]]; then
				if [[ "$3" == "IPv4Stack" ]]; then
					Network6Config="isDHCP"
					[[ $(timeout 4s grep -iw "iface" $NetCfgWhole | grep -iw "$interface4" | grep -iw "inet" | grep -ic "auto\|dhcp") -ge "1" ]] && Network4Config="isDHCP" || Network4Config="isStatic"
				elif [[ "$3" == "BiStack" ]]; then
					[[ $(timeout 4s grep -iw "iface" $NetCfgWhole | grep -iw "$interface4" | grep -iw "inet" | grep -ic "auto\|dhcp") -ge "1" ]] && Network4Config="isDHCP" || Network4Config="isStatic"
					[[ $(timeout 4s grep -iw "iface" $NetCfgWhole | grep -iw "$interface6" | grep -iw "inet6" | grep -ic "auto\|dhcp") -ge "1" ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				elif [[ "$3" == "IPv6Stack" ]]; then
					Network4Config="isDHCP"
					[[ $(timeout 4s grep -iw "iface" $NetCfgWhole | grep -iw "$interface6" | grep -iw "inet6" | grep -ic "auto\|dhcp") -ge "1" ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				fi
				[[ -n $(timeout 4s grep "accept_ra" $NetCfgWhole) ]] && {
					Network4Config="isStatic"
					Network6Config="isStatic"
				}
			elif [[ "$networkManagerType" == "netplan" ]]; then
				[[ ! -z "$NetCfgWhole" ]] && {
					dhcp4Status=$(parseYaml "$NetCfgWhole" | grep "$interface4" | grep "dhcp")
					dhcp6Status=$(parseYaml "$NetCfgWhole" | grep "$interface6" | grep "dhcp")
				}
				if [[ "$3" == "IPv4Stack" ]]; then
					Network6Config="isDHCP"
					[[ "$dhcp4Status" =~ "dhcp4=\"true\"" || "$dhcp4Status" =~ "dhcp4=\"yes\"" ]] && Network4Config="isDHCP" || Network4Config="isStatic"
				elif [[ "$3" == "BiStack" ]]; then
					[[ "$dhcp4Status" =~ "dhcp4=\"true\"" || "$dhcp4Status" =~ "dhcp4=\"yes\"" ]] && Network4Config="isDHCP" || Network4Config="isStatic"
					[[ "$dhcp6Status" =~ "dhcp6=\"true\"" || "$dhcp6Status" =~ "dhcp6=\"yes\"" ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				elif [[ "$3" == "IPv6Stack" ]]; then
					Network4Config="isDHCP"
					[[ "$dhcp6Status" =~ "dhcp6=\"true\"" || "$dhcp6Status" =~ "dhcp6=\"yes\"" ]] && Network6Config="isDHCP" || Network6Config="isStatic"
				fi
			fi
		fi
		rm -rf "$tmpNetcfgDir"
	}
	[[ "$Network4Config" == "" ]] && Network4Config="isStatic"
	[[ "$Network6Config" == "" ]] && Network6Config="isStatic"
}

setDhcpOrStatic() {
	[[ "$1" == "dhcp" || "$1" == "auto" || "$1" == "automatic" || "$1" == "true" || "$1" == "yes" || "$1" == "1" ]] && {
		Network4Config="isDHCP"
		Network6Config="isDHCP"
	}
	[[ "$1" == "static" || "$1" == "manual" || "$1" == "none" || "$1" == "false" || "$1" == "no" || "$1" == "0" || -n $(echo $2 $3 | grep -io 'google') ]] && {
		Network4Config="isStatic"
		Network6Config="isStatic"
	}
}

DebianModifiedPreseed() {
	if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]]; then
		debianConfFileDir="https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Debian"
		debianConfFileDirCn="https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Debian"
		if [[ "$DebianDistNum" -ge "9" && "$DebianDistNum" -le "11" ]]; then
			DebianVimVer="vim"$(expr ${DebianDistNum} + 71)
		elif [[ "$DebianDistNum" -ge "12" ]]; then
			DebianVimVer="vim"$(expr ${DebianDistNum} + 78)
		elif [[ "$DIST" =~ "kali-" ]]; then
			DebianVimVer="vim90"
		else
			DebianVimVer=""
		fi
		VimSupportCopy="$1 sed -i 's/set mouse=a/set mouse-=a/g' /usr/share/vim/${DebianVimVer}/defaults.vim;"
		VimIndentEolStart="$1 sed -i 's/set compatible/set nocompatible/g' /etc/vim/vimrc.tiny; $1 sed -i '/set nocompatible/a\set backspace=2' /etc/vim/vimrc.tiny;"
		[[ "$DebianVimVer" == "" ]] && {
			VimSupportCopy=""
			VimIndentEolStart=""
		}
		[[ "$setFail2banStatus" == "1" ]] && {
			EnableFail2ban="$1 sed -i '/^\[Definition\]/a allowipv6 = auto' /etc/fail2ban/fail2ban.conf; $1 sed -ri 's/^backend = auto/backend = systemd/g' /etc/fail2ban/jail.conf; $1 update-rc.d fail2ban enable; $1 /etc/init.d/fail2ban restart;"
			fail2banComponent="fail2ban"
		}
		AptUpdating="$1 apt update -y;"
		InstallComponents="$1 apt install apt-transport-https bc ca-certificates cron curl dnsutils dpkg ${fail2banComponent} file jq lrzsz lsb-release nano net-tools sudo vim wget -y;"
		DisableCertExpiredCheck="$1 sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf; $1 update-ca-certificates -f;"
		if [[ "$IsCN" == "1" ]]; then
			ChangeBashrc="$1 rm -rf /root/.bashrc; $1 curl -ksLo /root/.bashrc '${debianConfFileDirCn}/.bashrc';"
			[[ "$setDns" == "1" ]] && SetDNS="CNResolvHead" DnsChangePermanently="$1 mkdir -p /etc/resolvconf/resolv.conf.d/; $1 curl -ksLo /etc/resolvconf/resolv.conf.d/head '${debianConfFileDirCn}/network/${SetDNS}';" || DnsChangePermanently=""
			[[ "$setMotd" == "1" ]] && ModifyMOTD="$1 rm -rf /etc/update-motd.d/ /etc/motd /run/motd.dynamic; $1 mkdir -p /etc/update-motd.d/; $1 curl -ksLo /etc/update-motd.d/00-header '${debianConfFileDirCn}/updatemotd/00-header'; $1 curl -ksLo /etc/update-motd.d/10-sysinfo '${debianConfFileDirCn}/updatemotd/10-sysinfo'; $1 curl -ksLo /etc/update-motd.d/90-footer '${debianConfFileDirCn}/updatemotd/90-footer'; $1 chmod +x /etc/update-motd.d/00-header; $1 chmod +x /etc/update-motd.d/10-sysinfo; $1 chmod +x /etc/update-motd.d/90-footer;" || ModifyMOTD=""
		else
			ChangeBashrc="$1 rm -rf /root/.bashrc; $1 curl -ksLo /root/.bashrc '${debianConfFileDir}/.bashrc';"
			[[ "$setDns" == "1" ]] && SetDNS="NomalResolvHead" DnsChangePermanently="$1 mkdir -p /etc/resolvconf/resolv.conf.d/; $1 curl -ksLo /etc/resolvconf/resolv.conf.d/head '${debianConfFileDir}/network/${SetDNS}';" || DnsChangePermanently=""
			[[ "$setMotd" == "1" ]] && ModifyMOTD="$1 rm -rf /etc/update-motd.d/ /etc/motd /run/motd.dynamic; $1 mkdir -p /etc/update-motd.d/; $1 curl -ksLo /etc/update-motd.d/00-header '${debianConfFileDir}/updatemotd/00-header'; $1 curl -ksLo /etc/update-motd.d/10-sysinfo '${debianConfFileDir}/updatemotd/10-sysinfo'; $1 curl -ksLo /etc/update-motd.d/90-footer '${debianConfFileDir}/updatemotd/90-footer'; $1 chmod +x /etc/update-motd.d/00-header; $1 chmod +x /etc/update-motd.d/10-sysinfo; $1 chmod +x /etc/update-motd.d/90-footer;" || ModifyMOTD=""
		fi
		[[ "$autoPlugAdapter" == "1" ]] && AutoPlugInterfaces="$1 sed -ri \"s/allow-hotplug $interface4/auto $interface4/g\" $2; $1 sed -ri \"s/allow-hotplug $interface6/auto $interface6/g\" $2;" || AutoPlugInterfaces=""
		SupportIPv6orIPv4=""
		ReplaceActualIpPrefix=""
		if [[ "$IPStackType" == "IPv4Stack" ]]; then
			[[ "$BurnIrregularIpv4Status" == "1" ]] && BurnIrregularIpv4Gate="$1 sed -i '\$a\\\tgateway $actualIp4Gate' $2;"
			SupportIPv6orIPv4="$1 sed -i '\$aprecedence ::ffff:0:0/96' /etc/gai.conf;"
			ReplaceActualIpPrefix="$1 sed -ri \"s/address $ipAddr\/$ipPrefix/address $ipAddr\/$actualIp4Prefix/g\" $2;"
			[[ "$iAddrNum" -ge "2" ]] && {
				writeMultipleIpv4Addresses "$iAddrNum" "$1" ''$2''
				SupportIPv6orIPv4="$SupportMultipleIPv4"
			}
		elif [[ "$IPStackType" == "BiStack" ]]; then
			if [[ "$BiStackPreferIpv6Status" == "1" ]]; then
				if [[ "$Network4Config" == "isDHCP" ]]; then
					SupportIPv6orIPv4="$1 sed -i '\$aiface $interface inet dhcp' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					[[ -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]] && SupportIPv6orIPv4="$1 sed -i '\$a\ ' $2; $1 sed -i '\$aallow-hotplug $interface4' $2; $1 sed -i '\$aiface $interface4 inet dhcp' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					ReplaceActualIpPrefix="$1 sed -ri \"s/address $ip6Addr\/$ip6Mask/address $ip6Addr\/$actualIp6Prefix/g\" $2;"
				elif [[ "$Network4Config" == "isStatic" ]]; then
					SupportIPv6orIPv4="$1 sed -i '\$aiface $interface inet static' $2; $1 sed -i '\$a\\\taddress $ipAddr' $2; $1 sed -i '\$a\\\tnetmask $MASK' $2; $1 sed -i '\$a\\\tgateway $GATE' $2; $1 sed -i '\$a\\\tdns-nameservers $ipDNS' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					[[ -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]] && SupportIPv6orIPv4="$1 sed -i '\$a\ ' $2; $1 sed -i '\$aallow-hotplug $interface4' $2; $1 sed -i '\$aiface $interface4 inet static' $2; $1 sed -i '\$a\\\taddress $ipAddr' $2; $1 sed -i '\$a\\\tnetmask $MASK' $2; $1 sed -i '\$a\\\tgateway $GATE' $2; $1 sed -i '\$a\\\tdns-nameservers $ipDNS' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					ReplaceActualIpPrefix="$1 sed -ri \"s/address $ip6Addr\/$ip6Mask/address $ip6Addr\/$actualIp6Prefix/g\" $2; $1 sed -ri \"s/netmask $MASK/netmask $actualIp4Subnet/g\" $2;"
				fi
			else
				[[ "$BurnIrregularIpv4Status" == "1" ]] && BurnIrregularIpv4Gate="$1 sed -i '\$a\\\tgateway $actualIp4Gate' $2;"
				if [[ "$Network6Config" == "isDHCP" ]]; then
					SupportIPv6orIPv4="$1 sed -i '\$aiface $interface inet6 dhcp' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					[[ -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]] && SupportIPv6orIPv4="$1 sed -i '\$a\ ' $2; $1 sed -i '\$aallow-hotplug $interface6' $2; $1 sed -i '\$aiface $interface6 inet6 dhcp' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					ReplaceActualIpPrefix="$1 sed -ri \"s/address $ipAddr\/$ipPrefix/address $ipAddr\/$actualIp4Prefix/g\" $2;"
				elif [[ "$Network6Config" == "isStatic" ]]; then
					SupportIPv6orIPv4="$1 sed -i '\$aiface $interface inet6 static' $2; $1 sed -i '\$a\\\taddress $ip6Addr' $2; $1 sed -i '\$a\\\tnetmask $ip6Mask' $2; $1 sed -i '\$a\\\tgateway $ip6Gate' $2; $1 sed -i '\$a\\\tdns-nameservers $ip6DNS' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					[[ -n "$interface4" && -n "$interface6" && "$interface4" != "$interface6" ]] && SupportIPv6orIPv4="$1 sed -i '\$a\ ' $2; $1 sed -i '\$aallow-hotplug $interface6' $2; $1 sed -i '\$aiface $interface6 inet6 static' $2; $1 sed -i '\$a\\\taddress $ip6Addr' $2; $1 sed -i '\$a\\\tnetmask $ip6Mask' $2; $1 sed -i '\$a\\\tgateway $ip6Gate' $2; $1 sed -i '\$a\\\tdns-nameservers $ip6DNS' $2; $1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
					ReplaceActualIpPrefix="$1 sed -ri \"s/address $ipAddr\/$ipPrefix/address $ipAddr\/$actualIp4Prefix/g\" $2; $1 sed -ri \"s/netmask $ip6Mask/netmask $actualIp6Prefix/g\" $2;"
				fi
			fi
			[[ "$iAddrNum" -ge "2" || "$i6AddrNum" -ge "2" ]] && {
				writeMultipleIpv4Addresses "$iAddrNum" "$1" ''$2''
				writeMultipleIpv6Addresses "$i6AddrNum" "$1" ''$2''
				if [[ "$iAddrNum" == "1" || "$i6AddrNum" == "1" ]]; then
					SupportIPv6orIPv4="$SupportMultipleIPv4 $SupportMultipleIPv6 $SupportIPv6orIPv4"
				else
					SupportIPv6orIPv4="$SupportMultipleIPv4 $SupportMultipleIPv6"
				fi
			}
		elif [[ "$IPStackType" == "IPv6Stack" ]]; then
			[[ "$BurnIrregularIpv6Status" == "1" ]] && BurnIrregularIpv6Gate="$1 sed -i '\$a\\\tgateway $ip6Gate' $2;"
			SupportIPv6orIPv4="$1 sed -i '\$alabel 2002::/16' /etc/gai.conf; $1 sed -i '\$alabel 2001:0::/32' /etc/gai.conf;"
			ReplaceActualIpPrefix="$1 sed -ri \"s/address $ip6Addr\/$ip6Mask/address $ip6Addr\/$actualIp6Prefix/g\" $2;"
			[[ "$i6AddrNum" -ge "2" ]] && {
				writeMultipleIpv6Addresses "$i6AddrNum" "$1" ''$2''
				SupportIPv6orIPv4="$SupportMultipleIPv6"
			}
		fi
		[[ "$linux_release" == 'kali' ]] && {
			ChangeBashrc=""
			EnableSSH="$1 update-rc.d ssh enable; $1 /etc/init.d/ssh restart;"
			ReviseMOTD="$1 sed -ri 's/Debian/Kali/g' /etc/update-motd.d/00-header;"
			SupportZSH="$1 apt install zsh -y; $1 chsh -s /bin/zsh; $1 rm -rf /root/.bashrc.original;"
		}
		[[ "$enableBBR" == "1" ]] && [[ "$DebianDistNum" -ge "11" || "$linux_release" == "kali" ]] && {
			EnableBBR="$1 sed -i '\$anet.core.default_qdisc = fq' $3;
$1 sed -i '\$anet.ipv4.tcp_congestion_control = bbr' $3;
$1 sed -i '\$anet.ipv4.tcp_rmem = 8192 262144 536870912' $3;
$1 sed -i '\$anet.ipv4.tcp_wmem = 4096 16384 536870912' $3;
$1 sed -i '\$anet.ipv4.tcp_adv_win_scale = -2' $3;
$1 sed -i '\$anet.ipv4.tcp_collapse_max_bytes = 6291456' $3;
$1 sed -i '\$anet.ipv4.tcp_notsent_lowat = 131072' $3;
$1 sed -i '\$anet.ipv4.ip_local_port_range = 1024 65535' $3;
$1 sed -i '\$anet.core.rmem_max = 536870912' $3;
$1 sed -i '\$anet.core.wmem_max = 536870912' $3;
$1 sed -i '\$anet.core.somaxconn = 32768' $3;
$1 sed -i '\$anet.core.netdev_max_backlog = 32768' $3;
$1 sed -i '\$anet.ipv4.tcp_max_tw_buckets = 65536' $3;
$1 sed -i '\$anet.ipv4.tcp_abort_on_overflow = 1' $3;
$1 sed -i '\$anet.ipv4.tcp_slow_start_after_idle = 0' $3;
$1 sed -i '\$anet.ipv4.tcp_timestamps = 1' $3;
$1 sed -i '\$anet.ipv4.tcp_syncookies = 0' $3;
$1 sed -i '\$anet.ipv4.tcp_syn_retries = 3' $3;
$1 sed -i '\$anet.ipv4.tcp_synack_retries = 3' $3;
$1 sed -i '\$anet.ipv4.tcp_max_syn_backlog = 32768' $3;
$1 sed -i '\$anet.ipv4.tcp_fin_timeout = 15' $3;
$1 sed -i '\$anet.ipv4.tcp_keepalive_intvl = 3' $3;
$1 sed -i '\$anet.ipv4.tcp_keepalive_probes = 5' $3;
$1 sed -i '\$anet.ipv4.tcp_keepalive_time = 600' $3;
$1 sed -i '\$anet.ipv4.tcp_retries1 = 3' $3;
$1 sed -i '\$anet.ipv4.tcp_retries2 = 5' $3;
$1 sed -i '\$anet.ipv4.tcp_no_metrics_save = 1' $3;
$1 sed -i '\$anet.ipv4.ip_forward = 1' $3;
$1 sed -i '\$afs.file-max = 104857600' $3;
$1 sed -i '\$afs.inotify.max_user_instances = 8192' $3;
$1 sed -i '\$afs.nr_open = 1048576' $3;
$1 systemctl restart systemd-sysctl;"
		} || {
			EnableBBR=""
		}
		CreateSoftLinkToGrub2FromGrub1="$1 ln -s /boot/grub/ /boot/grub2;"
		[[ "$EfiSupport" == "enabled" ]] && SetGrubTimeout="$1 sed -ri 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/g' /etc/default/grub; $1 sed -ri 's/set timeout=5/set timeout=3/g' /boot/grub/grub.cfg;" || SetGrubTimeout=""
		#SetOGOSfunction="curl -sL ${cf_proxy}https://raw.githubusercontent.com/OG-Open-Source/raw/refs/heads/main/shell/update-function.sh -o /target/tmp/update-function.sh; chmod +x /target/tmp/update-function.sh; chroot /target bash /target/tmp/update-function.sh -r;"
		SetOGOSfunction="$1 bash -c 'curl -sL ${cf_proxy}https://raw.githubusercontent.com/OG-Open-Source/raw/refs/heads/main/shell/update-function.sh | bash'; $1 rm -f /function.sh"
		DebianModifiedProcession="${AptUpdating} ${InstallComponents} ${DisableCertExpiredCheck} ${ChangeBashrc} ${VimSupportCopy} ${VimIndentEolStart} ${DnsChangePermanently} ${ModifyMOTD} ${BurnIrregularIpv4Gate} ${BurnIrregularIpv6Gate} ${SupportIPv6orIPv4} ${ReplaceActualIpPrefix} ${AutoPlugInterfaces} ${EnableSSH} ${ReviseMOTD} ${SupportZSH} ${EnableFail2ban} ${EnableBBR} ${CreateSoftLinkToGrub2FromGrub1} ${SetGrubTimeout} ${SetOGOSfunction}"
	fi
}

DebianPreseedProcess() {
	if [[ "$setAutoConfig" == "1" ]]; then
		if [[ "$linux_release" == 'debian' ]]; then
			[[ "$IsCN" == "1" ]] && debianSecurityMirror="mirrors.tuna.tsinghua.edu.cn" || debianSecurityMirror="security.debian.org"
		fi
		addCloudKernelCmd="d-i base-installer/kernel/image string"
		if [[ "$setCloudKernel" == "" ]]; then
			[[ -n "$virtWhat" ]] && {
				[[ "$linux_release" == 'debian' && "$DebianDistNum" -ge "11" || "$linux_release" == 'kali' ]] && AddCloudKernel="$addCloudKernelCmd linux-image-cloud-$VER" || AddCloudKernel=""
			}
		elif [[ "$setCloudKernel" == "1" ]]; then
			[[ "$linux_release" == 'debian' && "$DebianDistNum" -ge "11" || "$linux_release" == 'kali' ]] && AddCloudKernel="$addCloudKernelCmd linux-image-cloud-$VER" || AddCloudKernel=""
		fi
		[[ -n "$setRaid" || "$ddMode" == '1' || -n $(echo $virtWhat | grep -io 'vmware\|virtualbox') ]] && AddCloudKernel=""
		ddWindowsEarlyCommandsOfAnna='anna-install libfuse2-udeb fuse-udeb ntfs-3g-udeb libcrypto3-udeb libpcre2-8-0-udeb libssl3-udeb libuuid1-udeb zlib1g-udeb wget-udeb'
		tmpDdWinsEarlyCommandsOfAnna="$ddWindowsEarlyCommandsOfAnna"
		setNormalRecipe "$linux_release" "$disksNum" "$setSwap" "$setDisk" "$partitionTable" "$setFileSystem" "$EfiSupport" "$diskCapacity" "$IncDisk" "$AllDisks"
		setRaidRecipe "$setRaid" "$disksNum" "$AllDisks" "$linux_release"
		if [[ "$BiStackPreferIpv6Status" == "1" ]]; then
			if [[ "$interfacesNum" -ge "2" ]] || [[ "$linux_release" == 'debian' && "$DebianDistNum" -le "11" ]] || [[ "$ddMode" == '1' ]]; then
				BiStackPreferIpv6Status=""
				BurnIrregularIpv6Status=""
				BurnIrregularIpv4Status='1'
				interfaceSelect="$interface4"
			fi
		fi
		[[ Network4Config == "isDHCP" ]] && BurnIrregularIpv4Status='0'
		[[ "$BurnIrregularIpv4Status" == "1" ]] && {
			actualIp4Gate="$GATE"
			GATE="none"
			if [[ "$IPStackType" == "IPv4Stack" ]]; then
				writeDnsByForce='echo '\''nameserver '$ipDNS1''\'' > /etc/resolv.conf && echo '\''nameserver '$ipDNS2''\'' >> /etc/resolv.conf'
			elif [[ "$IPStackType" == "BiStack" ]]; then
				writeDnsByForce='echo '\''nameserver '$ipDNS1''\'' > /etc/resolv.conf && echo '\''nameserver '$ip6DNS1''\'' >> /etc/resolv.conf && echo '\''nameserver '$ipDNS2''\'' >> /etc/resolv.conf && echo '\''nameserver '$ip6DNS2''\'' >> /etc/resolv.conf'
			fi
			[[ "$ddMode" == '0' ]] && tmpDdWinsEarlyCommandsOfAnna=''
			BurnIrregularIpv4ByForce=$(echo -e 'd-i preseed/early_command string ip link set dev '$interface4' up; ip addr add '$IPv4'/'$ipPrefix' dev '$interface4'; echo "(ip route add '$actualIp4Gate' dev '$interface4' || true) && (ip route add default via '$actualIp4Gate' dev '$interface4' onlink || true) && '$writeDnsByForce'" > /bin/ethdetect; echo "(test -x /bin/ethdetect && /bin/ethdetect) || true" >> /usr/share/debconf/confmodule; '$tmpDdWinsEarlyCommandsOfAnna'')
		}
		if [[ "$IPStackType" == "IPv4Stack" ]] || [[ "$IPStackType" == "BiStack" && "$BiStackPreferIpv6Status" != "1" ]]; then
			[[ "$Network4Config" == "isStatic" ]] && NetConfigManually=$(echo -e "d-i netcfg/disable_autoconfig boolean true\nd-i netcfg/dhcp_failed note\nd-i netcfg/dhcp_options select Configure network manually\nd-i netcfg/get_ipaddress string $IPv4\nd-i netcfg/get_netmask string $MASK\nd-i netcfg/get_gateway string $GATE\nd-i netcfg/get_nameservers string $ipDNS\nd-i netcfg/no_default_route boolean true\nd-i netcfg/confirm_static boolean true") || NetConfigManually=""
		elif [[ "$IPStackType" == "IPv6Stack" ]] || [[ "$IPStackType" == "BiStack" && "$BiStackPreferIpv6Status" == "1" ]]; then
			[[ "$Network6Config" == "isStatic" ]] && NetConfigManually=$(echo -e "d-i netcfg/disable_autoconfig boolean true\nd-i netcfg/dhcp_failed note\nd-i netcfg/dhcp_options select Configure network manually\nd-i netcfg/get_ipaddress string $ip6Addr\nd-i netcfg/get_netmask string $ip6Subnet\nd-i netcfg/get_gateway string $ip6Gate\nd-i netcfg/get_nameservers string $ip6DNS\nd-i netcfg/no_default_route boolean true\nd-i netcfg/confirm_static boolean true") || NetConfigManually=""
		fi
		[[ "$BurnIrregularIpv6Status" == "1" ]] && {
			writeDnsByForce='echo '\''nameserver '$ip6DNS1''\'' > /etc/resolv.conf && echo '\''nameserver '$ip6DNS2''\'' >> /etc/resolv.conf'
			BurnIrregularIpv6ByForce=$(echo -e 'd-i preseed/early_command string ip link set dev '$interface6' up; ip -6 addr add '$ip6Addr'/'$actualIp6Prefix' dev '$interface6'; echo "(ip -6 route add '$ip6Gate' dev '$interface6' || true) && (ip -6 route add default via '$ip6Gate' dev '$interface6' onlink || true) && '$writeDnsByForce'" > /bin/ethdetect; echo "(test -x /bin/ethdetect && /bin/ethdetect) || true" >> /usr/share/debconf/confmodule;')
			NetConfigManually=$(echo -e "d-i netcfg/disable_autoconfig boolean true\nd-i netcfg/dhcp_failed note\nd-i netcfg/dhcp_options select Configure network manually\nd-i netcfg/get_ipaddress string $ip6Addr\nd-i netcfg/get_netmask string $ip6Subnet\nd-i netcfg/get_gateway string none\nd-i netcfg/get_nameservers string $ip6DNS\nd-i netcfg/no_default_route boolean true\nd-i netcfg/confirm_static boolean true")
		}
		DebianModifiedPreseed "in-target" "/etc/network/interfaces" "/etc/sysctl.d/99-sysctl.conf"
		cat >/tmp/boot/preseed.cfg <<EOF
### Unattended Installation
d-i auto-install/enable boolean true
d-i debconf/priority select critical

### Localization
d-i debian-installer/locale string en_US.UTF-8
d-i debian-installer/country string US
d-i debian-installer/language string en
d-i debian-installer/allow_unauthenticated boolean true
d-i console-setup/layoutcode string us
d-i keyboard-configuration/xkb-keymap string us

### Low memory mode
d-i lowmem/low note

### Select security, updates and backports
d-i apt-setup/services-select multiselect security, updates

### Configure source repositories
d-i apt-setup/enable-source-repositories boolean true

### Security setup
d-i apt-setup/security_host string ${debianSecurityMirror}

### Config contrib, non-free and non-free firmware
d-i apt-setup/contrib boolean true
d-i apt-setup/non-free boolean true
d-i apt-setup/non-free-firmware boolean true

### Disable CD-rom automatic scan
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/cdrom/set-next boolean false
d-i apt-setup/cdrom/set-failed boolean false

### Configure cloud kernel
${AddCloudKernel}

### Network configuration
d-i netcfg/choose_interface select $interfaceSelect
${NetConfigManually}
d-i hw-detect/load_firmware boolean true
${BurnIrregularIpv4ByForce}
${BurnIrregularIpv6ByForce}

### Mirror settings
d-i mirror/country string manual
d-i mirror/http/hostname string $MirrorHost
d-i mirror/http/directory string $MirrorFolder

### Account setup
d-i passwd/root-login boolean ture
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password ${myPASSWORD}
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

### Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string ${TimeZone}
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string ntp.nict.jp

### Get harddisk name and Windows DD installation set up
d-i preseed/early_command string ${ddWindowsEarlyCommandsOfAnna}
d-i partman/early_command string \
	lvremove --select all -ff -y; \
	vgremove --select all -ff -y; \
	pvremove /dev/* -ff -y; \
	[[ -n "\$(blkid -t TYPE='vfat' -o device)" ]] && umount "\$(blkid -t TYPE='vfat' -o device)"; \
	${PartmanEarlyCommand} \
	wget -qO- '$DDURL' | $DEC_CMD | /bin/dd of=\$(list-devices disk | grep ${IncDisk} | head -n 1); \
	/bin/ntfs-3g \$(list-devices partition | grep ${IncDisk} | head -n 1) /mnt; \
	cd '/mnt/ProgramData/Microsoft/Windows/Start Menu/Programs'; \
	cd Start* || cd start*; \
	cp -f '/net.bat' './net.bat'; \
	/sbin/reboot; \
	umount /media || true; \

### Partitioning
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/device_remove_lvm_span boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
${defaultFileSystem}
d-i partman/mount_style select uuid
d-i partman-md/device_remove_md boolean true
${FormatDisk}

### Package selection
tasksel tasksel/first multiselect minimal
d-i pkgsel/include string openssh-server

# Automatic updates are not applied, everything is updated manually.
d-i pkgsel/update-policy select none
d-i pkgsel/upgrade select none

### Disable to upload developer statistics anonymously
popularity-contest popularity-contest/participate boolean false

### Grub
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string ${IncDisk}
d-i grub-installer/force-efi-extra-removable boolean true
d-i debian-installer/add-kernel-opts string net.ifnames=0 biosdevname=0 ipv6.disable=1 ${serialConsolePropertiesForGrub}
grub-pc grub-pc/hidden_timeout boolean false
grub-pc grub-pc/timeout string 3

### Shutdown machine
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/reboot boolean true

### Write preseed
d-i preseed/late_command string	\
	sed -ri 's/^#?Port.*/Port ${sshPORT}/g' /target/etc/ssh/sshd_config; \
	sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config; \
	sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config; \
	echo '@reboot root cat /etc/run.sh 2>/dev/null |base64 -d >/tmp/run.sh; rm -rf /etc/run.sh; sed -i /^@reboot/d /etc/crontab; bash /tmp/run.sh' >>/target/etc/crontab; \
	echo '' >>/target/etc/crontab; \
	echo '${setCMD}' >/target/etc/run.sh; \
	${DebianModifiedProcession}; \
	${DebianEnableKejilion}
EOF
	fi
}

alpineInstallOrDdAdditionalFiles() {
	AlpineInitFile="$1"
	AlpineDnsFile="$2"
	AlpineMotd="$3"
	AlpineInitFileName="alpineConf.start"
	if [[ "$targetRelese" == 'Ubuntu' ]]; then
		if [[ "$ubuntuArchitecture" == "amd64" ]]; then
			targetLinuxMirror="$4"
			targetLinuxSecurityMirror="${10}"
		elif [[ "$ubuntuArchitecture" == "arm64" ]]; then
			targetLinuxMirror="$5"
			targetLinuxSecurityMirror="$5"
		fi
		AlpineInitFile="$6"
		AlpineInitFileName="ubuntuConf.start"
		[[ "$setIPv6" == "0" ]] && setIPv6="0" || setIPv6="1"
	elif [[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]]; then
		AlpineInitFile="$9"
		AlpineInitFileName="rhelConf.start"
		[[ "$setIPv6" == "0" ]] && setIPv6="0" || setIPv6="1"
	elif [[ "$targetRelese" == 'Windows' ]]; then
		AlpineInitFile="$7"
		AlpineInitFileName="windowsConf.start"
		windowsStaticConfigCmd="$8"
	fi
}

verifyUrlValidationOfDdImages() {
	echo "$1" | grep -q '^http://\|^ftp://\|^https://'
	[[ $? -ne '0' ]] && error "Please input a vaild URL, only support http://, ftp:// and https:// !\n" && exit 1
	tmpURLCheck=$(echo $(curl -s -I -X GET $1) | grep -wi "http/[0-9]*" | awk '{print $2}')
	[[ -z "$tmpURLCheck" || ! "$tmpURLCheck" =~ ^[0-9]+$ ]] && {
		error "The mirror of DD images is temporarily unavailable!\n"
		exit 1
	}
	DDURL="$1"
	if [[ "$setFileType" == "gz" ]]; then
		DEC_CMD="gunzip -dc"
		[[ $(echo "$DDURL" | grep -o ...$) == ".xz" ]] && DEC_CMD="xzcat"
	elif [[ "$setFileType" == "xz" ]]; then
		DEC_CMD="xzcat"
		[[ $(echo "$DDURL" | grep -o ...$) == ".gz" ]] && DEC_CMD="gunzip -dc"
	else
		[[ $(echo "$DDURL" | grep -o ...$) == ".xz" ]] && DEC_CMD="xzcat"
		[[ $(echo "$DDURL" | grep -o ...$) == ".gz" ]] && DEC_CMD="gunzip -dc"
	fi
}

checkSys

checkIpv4OrIpv6 "$ipAddr" "$ip6Addr" "208.67.220.220" "9.9.9.9" "64.6.65.6" "101.102.103.104" "2620:0:ccc::2" "2620:fe::9" "2620:74:1b::1:1" "2001:de4::101"

checkEfi "/sys/firmware/efi/efivars/" "/sys/firmware/efi/vars/" "/sys/firmware/efi/runtime-map/" "/sys/firmware/efi/mok-variables/"

checkVirt

if [[ "$sshPORT" ]]; then
	if [[ ! ${sshPORT} -ge "1" ]] || [[ ! ${sshPORT} -le "65535" ]] || [[ $(grep '^[[:digit:]]*$' <<<'${sshPORT}') ]]; then
		sshPORT='22'
	fi
else
	sshPORT=$(grep -Ei "^port|^#port" /etc/ssh/sshd_config | head -n 1 | awk -F' ' '{print $2}')
	[[ "$sshPORT" == "" ]] && sshPORT=$(netstat -anp | grep -i 'sshd: root' | grep -iw 'tcp' | awk '{print $4}' | head -n 1 | cut -d':' -f'2')
	[[ "$sshPORT" == "" ]] && sshPORT=$(netstat -anp | grep -i 'sshd: root' | grep -iw 'tcp6' | awk '{print $4}' | head -n 1 | awk -F':' '{print $NF}')
	if [[ "$sshPORT" == "" ]] || [[ ! ${sshPORT} -ge "1" ]] || [[ ! ${sshPORT} -le "65535" ]] || [[ $(grep '^[[:digit:]]*$' <<<'${sshPORT}') ]]; then
		sshPORT='22'
	fi
fi

[[ -n "$Relese" ]] || Relese='Debian'
linux_release=$(echo "$Relese" | sed 's/\ //g' | sed -r 's/(.*)/\L\1/')

[[ -z "$tmpDIST" ]] && {
	[ "$Relese" == 'Debian' ] && tmpDIST='12'
	[ "$Relese" == 'Kali' ] && tmpDIST='rolling'
	[ "$Relese" == 'AlpineLinux' ] && tmpDIST='edge'
	[ "$Relese" == 'CentOS' ] && tmpDIST='9'
	[ "$Relese" == 'RockyLinux' ] && tmpDIST='9'
	[ "$Relese" == 'AlmaLinux' ] && tmpDIST='9'
	[ "$Relese" == 'Fedora' ] && tmpDIST='40'
}
[[ -z "$finalDIST" ]] && {
	[ "$targetRelese" == 'Ubuntu' ] && finalDIST='24.04'
	[ "$targetRelese" == 'Windows' ] && finalDIST='11'
}

checkVER
if [[ -n "$tmpDIST" ]]; then
	checkDIST
fi

if [[ "$loaderMode" == "0" ]]; then
	checkGrub "/boot/grub/" "/boot/grub2/" "/etc/" "grub.cfg" "grub.conf" "/boot/efi/EFI/"
	if [[ -z "$GRUBTYPE" ]]; then
		error "Not found grub!\n"
		exit 1
	fi
	checkConsole "$VER"
fi

CLEAN

[[ ! -d "/tmp/" ]] && mkdir /tmp

[[ -n "$aliyundunProcess" ]] && {
	echo -e "\n${CLR1}[Warning]${CLR0} ${CLR6}AliYunDun${CLR0} is detected on your server, the components will be removed compeletely because they may obstruct the following flow."
}

[[ -f /etc/selinux/config ]] && {
	SELinuxStatus=$(sestatus -v | grep -i "selinux status:" | grep "enabled")
	[[ "$SELinuxStatus" != "" ]] && {
		echo -e "\n${CLR8}# Disabling SELinux${CLR0}"
		setenforce 0 2>/dev/null
		echo -e "\nSuccess"
	}
}

[[ "$setNetbootXyz" == "0" ]] && {
	checkMem "$linux_release" "$RedHatSeries" "$targetRelese"
	Add_OPTION="$Add_OPTION $lowmemLevel"
	checkDIST
}

[[ "$lowMemMode" == '1' || "$useCloudImage" == "1" ]] && {
	detectCloudinit
	if [[ "$linux_release" == 'rockylinux' || "$linux_release" == 'almalinux' || "$linux_release" == 'centos' ]]; then
		if [[ "$RedHatSeries" == "7" ]]; then
			error "There were not suitable Cloud Images for ${CLR3}$Relese $RedHatSeries${CLR0}!\n"
			exit 1
		fi
		if [[ "$RedHatSeries" == "8" ]]; then
			targetRelese='Rocky'
			[[ "$IPStackType" != "IPv4Stack" || "$internalCloudinitStatus" == "1" ]] && {
				if [[ "$IPStackType" != "IPv4Stack" ]]; then
					error "Cloud Image of ${CLR3}$targetRelese $RedHatSeries${CLR0} doesn't support ${CLR6}$IPStackType${CLR0} network!\n"
				elif [[ "$internalCloudinitStatus" == "1" ]]; then
					error "Due to internal Cloud Init configurations existed on ${underLine}$cloudinitCdDrive${CLR0}, installation of $targetRelese $RedHatSeries will meet a fatal!\n"
				fi
				RedHatSeries="$(($RedHatSeries + 1))"
				echo -e "\nTry to install ${CLR3}AlmaLinux $RedHatSeries${CLR0} or ${CLR3}Rocky $RedHatSeries${CLR0} instead."
				exit 1
			}
		fi
		if [[ "$linux_release" == 'centos' && "$RedHatSeries" -ge "9" ]]; then
			targetRelese='AlmaLinux'
		elif [[ "$RedHatSeries" -ge "9" ]]; then
			if [[ "$linux_release" == 'almalinux' ]]; then
				targetRelese='AlmaLinux'
			elif [[ "$linux_release" == 'rockylinux' ]]; then
				targetRelese='Rocky'
			fi
		fi
		ddMode='1'
	fi
}

[[ "$ddMode" == '1' ]] && {
	if [[ "$targetRelese" == 'Ubuntu' ]] || [[ "$targetRelese" == 'Windows' ]] || [[ "$targetRelese" == 'AlmaLinux' ]] || [[ "$targetRelese" == 'Rocky' ]]; then
		Relese='AlpineLinux'
		tmpDIST='edge'
		if [[ "$targetRelese" == 'Windows' ]]; then
			[[ "$VER" == "aarch64" || "$VER" == "arm64" ]] && {
				error "${targetRelese} doesn't support ${VER} architecture.\n"
				exit 1
			}
		fi
	else
		Relese='Debian'
		tmpDIST='12'
	fi
	linux_release=$(echo "$Relese" | sed 's/\ //g' | sed -r 's/(.*)/\L\1/')
	checkVER
	checkDIST
}

[[ -z "$LinuxMirror" ]] && {
	error "Invaild mirror!\n"
	[ "$Relese" == 'Debian' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://www.debian.org/mirror/list\n"
	[ "$Relese" == 'Ubuntu' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://launchpad.net/ubuntu/+archivemirrors\n"
	[ "$Relese" == 'Kali' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://http.kali.org/README.mirrorlist\n"
	[ "$Relese" == 'AlpineLinux' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://mirrors.alpinelinux.org/\n"
	[ "$Relese" == 'CentOS' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://www.centos.org/download/mirrors/\n"
	[ "$Relese" == 'RockyLinux' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://mirrors.rockylinux.org/mirrormanager/mirrors\n"
	[ "$Relese" == 'AlmaLinux' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://mirrors.almalinux.org/\n"
	[ "$Relese" == 'Fedora' ] && echo -e "${CLR3}Please check mirror lists:${CLR0} https://mirrors.fedoraproject.org/\n"
	exit 1
}

echo -e "\n${CLR3}# System Reinstall${CLR0}"

echo -e "\n${CLR8}## Check Dependence${CLR0}"
echo -e "${CLR8}$(LINE - "32")${CLR0}"
dependencies=("awk" "basename" "cat" "cpio" "curl" "cut" "dirname" "file" "find" "grep" "gzip" "iconv" "ip" "lsblk" "openssl" "sed" "wget")
for dep in "${dependencies[@]}"; do
	status="${CLR2}[OK]${CLR0}"
	command -v $dep &> /dev/null || status="${CLR1}[Missing]${CLR0}"
	echo -e "$status\t$dep"
done

echo -e "\n${CLR8}## System Information${CLR0}"
echo -e "${CLR8}$(LINE - "32")${CLR0}"
echo -e "Hostname:\t\t${CLR2}$(uname -n)${CLR0}"
echo -e "Operating System:\t${CLR2}$(CHECK_OS)${CLR0}"
echo -e "Kernel Version:\t\t${CLR2}$(uname -r)${CLR0}"
echo -e "System Language:\t${CLR2}$LANG${CLR0}"

echo -e "\nArchitecture:\t\t${CLR2}$(uname -m)${CLR0}"
echo -e "CPU Model:\t\t${CLR2}$(CPU_MODEL)${CLR0}"
echo -e "CPU Cores:\t\t${CLR2}$(nproc)${CLR0}"
setDisk=$(echo "$setDisk" | sed 's/[A-Z]/\l&/g')
getDisk "$setDisk" "$linux_release"
if [[ "$targetRelese" == 'AlmaLinux' ]] || [[ "$targetRelese" == 'Rocky' ]]; then
	[[ "$diskCapacity" -lt "10737418240" ]] && {
		error "Minimum system hard drive requirement is 10 GiB!\n"
		exit 1
	}
elif [[ "$targetRelese" == 'Windows' ]]; then
	[[ "$diskCapacity" -lt "16106127360" ]] && {
		error "Minimum system hard drive requirement is 15 GiB!\n"
		exit 1
	}
fi
echo -ne "Drives:\t\t\t" && [[ "$setDisk" == "all" || -n "$setRaid" ]] && echo -e "${CLR2}$AllDisks${CLR0}" || echo -e "${CLR2}$IncDisk${CLR0}"
echo -ne "Firmware:\t\t" && [[ "$EfiSupport" == "enabled" ]] && echo -e "${CLR2}UEFI${CLR0}" || echo -e "${CLR2}BIOS${CLR0}"
[[ "$setNetbootXyz" == "1" ]] && SpikCheckDIST="1"
if [[ "$SpikCheckDIST" == '0' ]]; then
	echo -ne "DIST Status:\t\t"
	[[ "$linux_release" == 'debian' ]] && DistsList="$(curl -ksL "$LinuxMirror/dists/" | grep -o 'href=.*/"' | cut -d'"' -f2 | sed '/-\|old\|README\|Debian\|experimental\|stable\|test\|sid\|devel/d' | grep '^[^/]' | sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')"
	[[ "$linux_release" == 'kali' ]] && DistsList="$(curl -ksL "$LinuxMirror/dists/" | grep -o 'href=.*/"' | cut -d'"' -f2 | sed '/debian\|only\|last\|edge/d' | grep '^[^/]' | sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')"
	[[ "$linux_release" == 'alpinelinux' ]] && DistsList="$(curl -ksL "$LinuxMirror/" | grep -o 'href=.*/"' | cut -d'"' -f2 | sed '/-/d' | grep '^[^/]' | sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')"
	for CheckDEB in $(echo "$DistsList" | sed 's/;/\n/g'); do
		[[ "$CheckDEB" =~ "$DIST" ]] && FindDists='1' && break
	done
	[[ "$FindDists" == '0' ]] && {
		error "The dists version not found, Please check it!\n"
		exit 1
	}
	echo -e "${CLR2}Success${CLR0}"
fi


echo -e "\nMemory Usage:\t\t${CLR2}$(MEM_USAGE)${CLR0}"
echo -e "Swap Usage:\t\t${CLR2}$(SWAP_USAGE)${CLR0}"
echo -e "Disk Usage:\t\t${CLR2}$(DISK_USAGE)${CLR0}"

echo -e "\nPackages Installed:\t${CLR2}$(PKG_COUNT)${CLR0}"
echo -e "Process Count:\t\t${CLR2}$(ps aux | wc -l)${CLR0}"
echo -e "Virtualization:\t\t${CLR2}$(CHECK_VIRT)${CLR0}"

ipDNS1=$(echo $ipDNS | cut -d ' ' -f 1)
ipDNS2=$(echo $ipDNS | cut -d ' ' -f 2)
ip6DNS1=$(echo $ip6DNS | cut -d ' ' -f 1)
ip6DNS2=$(echo $ip6DNS | cut -d ' ' -f 2)
ipDNS=$(checkDNS "$ipDNS")
ip6DNS=$(checkDNS "$ip6DNS")

if [[ -n "$ipAddr" && -n "$ipMask" && -n "$ipGate" ]] && [[ -z "$ip6Addr" && -z "$ip6Mask" && -z "$ip6Gate" ]]; then
	setNet='1'
	checkDHCP "$CurrentOS" "$CurrentOSVer" "$IPStackType"
	setDhcpOrStatic "$tmpDHCP" "$virtWhat" "$virtType"
	Network4Config="isStatic"
	acceptIPv4AndIPv6SubnetValue "$ipMask" ""
	[[ "$IPStackType" != "IPv4Stack" ]] && getIPv6Address
elif [[ -n "$ipAddr" && -n "$ipMask" && -n "$ipGate" ]] && [[ -n "$ip6Addr" && -n "$ip6Mask" && -n "$ip6Gate" ]]; then
	setNet='1'
	[[ -z "$interfaceSelect" ]] && getInterface "$CurrentOS"
	Network4Config="isStatic"
	Network6Config="isStatic"
	acceptIPv4AndIPv6SubnetValue "$ipMask" "$ip6Mask"
elif [[ -z "$ipAddr" && -z "$ipMask" && -z "$ipGate" ]] && [[ -n "$ip6Addr" && -n "$ip6Mask" && -n "$ip6Gate" ]]; then
	setNet='1'
	checkDHCP "$CurrentOS" "$CurrentOSVer" "$IPStackType"
	setDhcpOrStatic "$tmpDHCP" "$virtWhat" "$virtType"
	Network6Config="isStatic"
	acceptIPv4AndIPv6SubnetValue "" "$ip6Mask"
	getIPv4Address
fi

if [[ "$setNet" == "0" ]]; then
	checkDHCP "$CurrentOS" "$CurrentOSVer" "$IPStackType"
	setDhcpOrStatic "$tmpDHCP" "$virtWhat" "$virtType"
	getIPv4Address
	[[ "$IPStackType" != "IPv4Stack" ]] && getIPv6Address
	if [[ "$IPStackType" == "BiStack" && "$iAddrNum" -ge "2" || "$i6AddrNum" -ge "2" ]]; then
		if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]] || [[ "$linux_release" == 'alpinelinux' ]]; then
			Network4Config="isStatic"
		fi
		[[ "$BiStackPreferIpv6Status" == "1" ]] && {
			BiStackPreferIpv6Status=""
			BurnIrregularIpv6Status=""
			BurnIrregularIpv4Status='1'
		}
	fi
fi

checkWarp "warp*.conf" "wgcf*.conf" "wg[0-9].conf" "warp*" "wgcf*" "wg[0-9]" "privatekey" "publickey"

IPv4="$ipAddr"
MASK="$ipMask"
GATE="$ipGate"
if [[ -z "$IPv4" && -z "$MASK" && -z "$GATE" ]] && [[ -z "$ip6Addr" && -z "$ip6Mask" && -z "$ip6Gate" ]]; then
	error "The network of your machine may not be available!\n"
	bash $0 error
	exit 1
fi

echo -e "\n${CLR8}## Network Details${CLR0}"
echo -e "${CLR8}$(LINE - "32")${CLR0}"
[[ -n "$interfaceSelect" ]] && echo -ne "/nAdapter Name:\t${CLR2}$interfaceSelect${CLR0}" || echo -ne "\nAdapter Name:\t${CLR2}$interface${CLR0}"
[[ -n "$NetCfgWhole" ]] && echo -ne "\nNetwork File:\t${CLR2}$NetCfgWhole${CLR0}" || echo -ne "\nNetwork File:\t${CLR1}N/A${CLR0}"
echo -ne "\nServer Stack:\t${CLR2}$IPStackType\n${CLR0}"
[[ "$IPStackType" != "IPv6Stack" ]] && echo -e "\nIPv4 Method:\t${CLR2}$Network4Config${CLR0}" || echo -e "\nIPv4 Method:\t${CLR1}N/A${CLR0}"
[[ "$IPv4" && "$IPStackType" != "IPv6Stack" ]] && echo -e "IPv4 Address:\t${CLR2}$IPv4${CLR0}" || echo -e "IPv4 Address:\t${CLR1}N/A${CLR0}"
[[ "$IPv4" && "$IPStackType" != "IPv6Stack" ]] && echo -e "IPv4 Subnet:\t${CLR2}$actualIp4Subnet${CLR0}" || echo -e "IPv4 Subnet:\t${CLR1}N/A${CLR0}"
[[ "$IPv4" && "$IPStackType" != "IPv6Stack" ]] && echo -e "IPv4 Gateway:\t${CLR2}$GATE${CLR0}" || echo -e "IPv4 Gateway:\t${CLR1}N/A${CLR0}"
[[ "$IPv4" && "$IPStackType" != "IPv6Stack" ]] && echo -e "IPv4 DNS:\t${CLR2}$ipDNS${CLR0}" || echo -e "IPv4 DNS:\t${CLR1}N/A${CLR0}"
[[ "$IPv4" && "$IPStackType" != "IPv6Stack" ]] && echo -e "IPv4 Amount:\t${CLR2}$iAddrNum${CLR0}" || echo -e "IPv4 Amount:\t${CLR1}N/A${CLR0}"
[[ "$IPStackType" != "IPv4Stack" ]] && echo -e "\nIPv6 Method:\t${CLR2}$Network6Config${CLR0}" || echo -e "\nIPv6 Method:\t${CLR1}N/A${CLR0}"
[[ "$ip6Addr" && "$IPStackType" != "IPv4Stack" ]] && echo -e "IPv6 Address:\t${CLR2}$ip6Addr${CLR0}" || echo -e "IPv6 Address:\t${CLR1}N/A${CLR0}"
[[ "$ip6Addr" && "$IPStackType" != "IPv4Stack" ]] && echo -e "IPv6 Subnet:\t${CLR2}$actualIp6Prefix${CLR0}" || echo -e "IPv6 Subnet:\t${CLR1}N/A${CLR0}"
[[ "$ip6Addr" && "$IPStackType" != "IPv4Stack" ]] && echo -e "IPv6 Gateway:\t${CLR2}$ip6Gate${CLR0}" || echo -e "IPv6 Gateway:\t${CLR1}N/A${CLR0}"
[[ "$ip6Addr" && "$IPStackType" != "IPv4Stack" ]] && echo -e "IPv6 DNS:\t${CLR2}$ip6DNS${CLR0}" || echo -e "IPv6 DNS:\t${CLR1}N/A${CLR0}"
[[ "$ip6Addr" && "$IPStackType" != "IPv4Stack" ]] && echo -e "IPv6 Amount:\t${CLR2}$i6AddrNum${CLR0}" || echo -e "IPv6 Amount:\t${CLR1}N/A${CLR0}"

getUserTimeZone "/root/timezonelists" "https://api.ip.sb/geoip/" "http://ifconfig.co/json?ip=" "http://ip-api.com/json/" "https://ipapi.co/" "YjNhNjAxNjY5YTFiNDI2MmFmOGYxYjJjZDk3ZjNiN2YK" "MmUxMjBhYmM0Y2Q4NDM1ZDhhMmQ5YzQzYzk4ZTZiZTEK" "NjBiMThjZWJlMWU1NGQ5NDg2YWY0MTgyMWM0ZTZiZDgK"
[[ -z "$TimeZone" ]] && TimeZone="Asia/Tokyo"

[[ -n "$tmpHostName" ]] && HostName="$tmpHostName" || HostName=$(hostname)
[[ -z "$HostName" || "$HostName" =~ "localhost" || "$HostName" =~ "localdomain" || "$HostName" == "random" ]] && HostName="instance-$(date "+%Y%m%d")-$(date "+%H%M")"

if [[ -z "$tmpWORD" || "$linux_release" == 'alpinelinux' ]]; then
	tmpWORD='OGOSpass'
	myPASSWORD='$6$.b85THM2Y2vc9tmr$Jy0yB5ZZNAO0DA5OppAd6fJQWFPtCnUKyGW0sIllzKLZ0a/1f3y4gKT80Jpw521GtHSsEo.pEmR3517p5S.YE0'
else
	myPASSWORD=$(openssl passwd -6 ''$tmpWORD'' 2>/dev/null)
	[[ -z "$myPASSWORD" || "$myPASSWORD" =~ "NULL" ]] && myPASSWORD=$(openssl passwd -1 ''$tmpWORD'')
fi

echo -e "\n${CLR8}## New System Login Information${CLR0}"
echo -e "${CLR8}$(LINE - "32")${CLR0}"
if [[ "$targetRelese" == 'Windows' && "$tmpURL" == "" || "$tmpURL" =~ "dl.lamp.sh" ]]; then
	echo -e "Hostname:\t${CLR3}$HostName${CLR0}"
	echo -e "Port:\t\t${CLR3}3389${CLR0}"
	echo -e "Username:\t${CLR3}Administrator${CLR0}"
	echo -e "Password:\t${CLR3}Teddysun.com${CLR0}"
elif [[ -z "$targetRelese" && "$ddMode" == '1' ]]; then
	echo -e "Hostname:\t${CLR1}N/A${CLR0}"
	echo -e "Port:\t\t${CLR1}N/A${CLR0}"
	echo -e "Username:\t${CLR1}N/A${CLR0}"
	echo -e "Password:\t${CLR1}N/A${CLR0}"
else
	echo -e "Hostname:\t${CLR3}$HostName${CLR0}"
	echo -e "Port:\t\t${CLR3}$sshPORT${CLR0}"
	echo -e "Username:\t${CLR3}root${CLR0}"
	echo -e "Password:\t${CLR3}$tmpWORD${CLR0}"
fi

if [[ "$ddMode" == '1' ]]; then
	if [[ "$targetRelese" == 'Ubuntu' ]]; then
		ubuntuDIST="$(echo "$finalDIST" | sed -r 's/(.*)/\L\1/')"
		UbuntuDistNum=$(echo "$ubuntuDIST" | cut -d'.' -f1)
		echo "$ubuntuDIST" | grep -q '[0-9]'
		[[ $? -eq '0' ]] && {
			ubuntuDigital="$(echo "$ubuntuDIST" | grep -o '[\.0-9]\{1,\}' | sed -n '1h;1!H;$g;s/\n//g;$p')"
			ubuntuDigital1=$(echo "$ubuntuDigital" | cut -d'.' -f1)
			ubuntuDigital2=$(echo "$ubuntuDigital" | cut -d'.' -f2)
			if [[ "$ubuntuDigital1" -le "19" || "$ubuntuDigital1" -ge "25" || $((${ubuntuDigital1} % 2)) = 1 ]] || [[ "$ubuntuDigital2" != "04" ]]; then
				error "The dists version not found, Please check it!\n"
				exit 1
			fi
			[[ -n $ubuntuDigital ]] && {
				[[ "$ubuntuDigital" == '20.04' ]] && finalDIST='focal'
				[[ "$ubuntuDigital" == '22.04' ]] && finalDIST='jammy'
				[[ "$ubuntuDigital" == '24.04' ]] && finalDIST='noble'
			}
		}
		if [[ "$VER" == "x86_64" ]] || [[ "$VER" == "x86-64" ]]; then
			ubuntuArchitecture="amd64"
		elif [[ "$VER" == "aarch64" ]]; then
			ubuntuArchitecture="arm64"
		fi
		if [[ "$tmpURL" == "" ]]; then
			tmpURL="https://cloud-images.a.disk.re/$targetRelese/"
			setFileType="xz"
			packageName="$finalDIST-server-cloudimg-$ubuntuArchitecture"
			verifyUrlValidationOfDdImages "$tmpURL$packageName.$setFileType"
		else
			verifyUrlValidationOfDdImages "$tmpURL"
		fi
		ReleaseName="$targetRelese $finalDIST $ubuntuArchitecture"
	elif [[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]]; then
		rhelArchitecture="$VER"
		if [[ "$tmpURL" == "" ]]; then
			tmpURL="https://cloud-images.a.disk.re/$targetRelese/"
			setFileType="xz"
			if [[ "$targetRelese" == 'AlmaLinux' ]]; then
				packageName="$targetRelese-$RedHatSeries-GenericCloud-latest.$rhelArchitecture"
			elif [[ "$targetRelese" == 'Rocky' ]]; then
				packageName="$targetRelese-$RedHatSeries-GenericCloud.latest.$rhelArchitecture"
			fi
			verifyUrlValidationOfDdImages "$tmpURL$packageName.$setFileType"
		else
			verifyUrlValidationOfDdImages "$tmpURL"
		fi
		ReleaseName="$targetRelese $RedHatSeries $rhelArchitecture"
	elif [[ "$targetRelese" == 'Windows' ]]; then
		[[ "$actualIp4Prefix" -gt "24" ]] && {
			actualIp4Prefix="24"
			actualIp4Subnet=$(netmask "$actualIp4Prefix")
		}
		if [[ -z "$tmpURL" ]]; then
			tmpURL="https://dl.lamp.sh/vhd"
			[[ $(echo "$finalDIST" | grep -i "server") ]] && tmpFinalDIST=$(echo $finalDIST | awk -F ' |-|_' '{print $2}')
			[[ $(echo "$finalDIST" | grep -i "pro") || $(echo "$finalDIST" | grep -i "ltsc") ]] && tmpFinalDIST=$(echo $finalDIST | awk -F ' |-|_' '{print $1}')
			[[ "$finalDIST" =~ ^[0-9]+$ ]] && tmpFinalDIST="$finalDIST"
			[[ "$targetLang" == 'jp' ]] && targetLang='ja'
			[[ "$targetLang" == 'zh' ]] && targetLang='cn'
			if [[ "$tmpFinalDIST" -ge "2012" && "$tmpFinalDIST" -le "2019" ]]; then
				tmpTargetLang="$targetLang"
			else
				[[ "$targetLang" == 'cn' ]] && tmpTargetLang="zh-""$targetLang"
				[[ "$targetLang" == 'en' ]] && tmpTargetLang="$targetLang""-us"
				[[ "$targetLang" == 'ja' ]] && tmpTargetLang="$targetLang""-jp"
			fi
			if [[ "$tmpFinalDIST" == "2012" ]]; then
				tmpURL="$tmpURL/"${tmpTargetLang}"_win"${tmpFinalDIST}"r2.xz"
				showFinalDIST="Server $tmpFinalDIST R2"
			elif [[ "$tmpFinalDIST" -ge "2016" && "$tmpFinalDIST" -le "2022" ]]; then
				tmpURL="$tmpURL/"${tmpTargetLang}"_win"${tmpFinalDIST}".xz"
				showFinalDIST="Server $tmpFinalDIST"
			elif [[ "$tmpFinalDIST" -ge "10" && "$tmpFinalDIST" -le "11" ]]; then
				[[ "$tmpFinalDIST" == "10" ]] && {
					[[ "$targetLang" == 'en' ]] && tmpURL="$tmpURL/tiny"${tmpFinalDIST}"_23h2.xz" || tmpURL="$tmpURL/"${tmpTargetLang}"_windows"${tmpFinalDIST}"_ltsc.xz"
					showFinalDIST="$tmpFinalDIST Enterprise LTSC"
				}
				[[ "$tmpFinalDIST" == "11" ]] && {
					[[ "$targetLang" == 'en' ]] && tmpURL="$tmpURL/tiny"${tmpFinalDIST}"_23h2.xz" || tmpURL="$tmpURL/"${tmpTargetLang}"_windows"${tmpFinalDIST}"_22h2.xz"
					showFinalDIST="$tmpFinalDIST Pro for Workstations"
				}
			fi
			if [[ "$EfiSupport" == "enabled" ]]; then
				[[ "$tmpFinalDIST" == "10" ]] && tmpURL=$(echo $tmpURL | sed 's/windows/win/g')
				tmpURL=$(echo $tmpURL | sed 's/...$/_uefi.xz/g')
			fi
			ReleaseName="$targetRelese $showFinalDIST"
		else
			showFinalDIST=""
			ReleaseName="$targetRelese"
		fi
		verifyUrlValidationOfDdImages "$tmpURL"
	elif [[ -z "$targetRelese" && "$tmpURL" != "" ]]; then
		verifyUrlValidationOfDdImages "$tmpURL"
		ReleaseName="Self-Modified OS"
	else
		echo -e "\n${CLR1}[Warning]${CLR0} Please input a vaild image URL!"
		exit 1
	fi
fi

if [[ "$setInterfaceName" == "1" ]] && [[ ! "$interface4" =~ "eth" || ! "$interface6" =~ "eth" ]]; then
	interface4="eth""$interface4DeviceOrder"
	interface6="eth""$interface6DeviceOrder"
	interface="$interface4"
	[[ "$IPStackType" == "IPv6Stack" ]] && interface="$interface6"
fi

if [ -z "$interfaceSelect" ]; then
	if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'ubuntu' ]] || [[ "$linux_release" == 'kali' ]]; then
		interfaceSelect="auto"
	elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
		interfaceSelect="link"
	fi
	[[ "$interfacesNum" -ge "2" ]] && {
		if [[ "$IPStackType" == "IPv6Stack" ]]; then
			[[ "$interface6" =~ "eth" && $(echo "$interface6" | grep -o '[0-9]') != "0" ]] || [[ "$interface6DeviceOrder" != "0" ]] && {
				interfaceSelect="$interface6"
			}
		elif [[ "$IPStackType" == "BiStack" || "$IPStackType" == "IPv4Stack" ]]; then
			[[ "$interface4" =~ "eth" && $(echo "$interface4" | grep -o '[0-9]') != "0" ]] || [[ "$interface4DeviceOrder" != "0" ]] && {
				interfaceSelect="$interface4"
			}
		fi
	}
else
	interface4=$(echo "$interfaceSelect" | cut -d' ' -f 1)
	interface6=$(echo "$interfaceSelect" | cut -d' ' -f 2)
	interface="$interface4"
	[[ -z "$interface6" ]] && {
		interface=$(echo "$interfaceSelect" | sed 's/[[:space:]]//g')
		interface6="$interface"
	}
fi

echo -e "\n${CLR8}## Installation Starting${CLR0}"
echo -e "${CLR8}$(LINE - "32")${CLR0}"
[[ "$ddMode" == '1' ]] && echo -e "${CLR4}Overwriting Packaged Image Mode${CLR0} Target System ${CLR3}[$ReleaseName]${CLR0}\n${CLR2}$DDURL${CLR0}\n"

if [[ "$linux_release" == 'centos' ]]; then
	if [[ "$DIST" != "$UNVER" ]]; then
		awk 'BEGIN{print '${UNVER}'-'${DIST}'}' | grep -q '^-'
		if [ $? != '0' ]; then
			UNKNOWHW='1'
			echo -e "\nThe version lower than ${CLR1}$UNVER${CLR0} may not support in auto mode!"
		fi
	fi
fi
if [[ "$setNetbootXyz" == "0" ]]; then
	echo -e "System:\t\t${CLR2}[$Relese]${CLR0}"
	echo -e "Version:\t${CLR2}[$DIST]${CLR0}"
	echo -e "Architecture:\t${CLR2}[$VER]${CLR0}"
else
	echo -e "\nFrom:\t${CLR2}[netboot.xyz]${CLR0}"
fi

if [[ "$setNetbootXyz" == "1" ]]; then
	[[ "$VER" == "x86_64" || "$VER" == "amd64" ]] && apt install grub-imageboot -y
	if [[ "$EfiSupport" == "enabled" ]] || [[ "$VER" == "aarch64" || "$VER" == "arm64" ]]; then
		error "Netbootxyz doesn't support $VER architecture!\n"
		bash $0 error
		exit 1
	fi
	if [[ "$IsCN" == "1" ]]; then
		NetbootXyzUrl="https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/RedHat/NetbootXyz/netboot.xyz.iso"
		NetbootXyzGrub="https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/RedHat/NetbootXyz/60_grub-imageboot"
	else
		NetbootXyzUrl="https://boot.netboot.xyz/ipxe/netboot.xyz.iso"
		NetbootXyzGrub="https://raw.githubusercontent.com/formorer/grub-imageboot/master/bin/60_grub-imageboot"
	fi
	[[ ! -d "/boot/images/" ]] && mkdir /boot/images/
	rm -rf /boot/images/netboot.xyz.iso
	echo -e "\n- $NetbootXyzUrl"
	curl -ksLo '/boot/images/netboot.xyz.iso' "$NetbootXyzUrl"
	[[ ! -f "/etc/grub.d/60_grub-imageboot" ]] && curl -ksLo '/etc/grub.d/60_grub-imageboot' "$NetbootXyzGrub"
	chmod 755 /etc/grub.d/60_grub-imageboot
	[[ ! -z "$GRUBTYPE" && "$GRUBTYPE" == "isGrub2" ]] && {
		rm -rf /boot/memdisk
		cp /usr/share/syslinux/memdisk /boot/memdisk
		ln -s /usr/share/grub/grub-mkconfig_lib /usr/lib/grub/grub-mkconfig_lib
	}
elif [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'ubuntu' ]] || [[ "$linux_release" == 'kali' ]]; then
	[ "$DIST" == "focal" ] && legacy="legacy-" || legacy=""
	InitrdUrl="${LinuxMirror}/dists/${DIST}/main/installer-${VER}/current/${legacy}images/netboot/${linux_release}-installer/${VER}/initrd.gz"
	VmLinuzUrl="${LinuxMirror}/dists/${DIST}${inUpdate}/main/installer-${VER}/current/${legacy}images/netboot/${linux_release}-installer/${VER}/linux"
	[[ "$linux_release" == 'kali' ]] && {
		InitrdUrl="${LinuxMirror}/dists/${DIST}/main/installer-${VER}/current/images/netboot/debian-installer/${VER}/initrd.gz"
		VmLinuzUrl="${LinuxMirror}/dists/${DIST}/main/installer-${VER}/current/images/netboot/debian-installer/${VER}/linux"
	}
	echo -e "\n- initrd.gz:\t${CLR2}$InitrdUrl${CLR0}\n- linux:\t${CLR2}$VmLinuzUrl${CLR0}"
	curl -ksLo '/tmp/initrd.img' "$InitrdUrl"
	[[ $? -ne '0' ]] && error "Download 'initrd.img' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
	curl -ksLo '/tmp/vmlinuz' "$VmLinuzUrl"
	[[ $? -ne '0' ]] && error "Download 'vmlinuz' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
	MirrorHost="$(echo "$LinuxMirror" | awk -F'://|/' '{print $2}')"
	MirrorFolder="$(echo "$LinuxMirror" | awk -F''${MirrorHost}'' '{print $2}')/"
	[ -n "$MirrorFolder" ] || MirrorFolder="/"
elif [[ "$linux_release" == 'alpinelinux' ]]; then
	InitrdUrl="${LinuxMirror}/${DIST}/releases/${VER}/netboot/${InitrdName}"
	VmLinuzUrl="${LinuxMirror}/${DIST}/releases/${VER}/netboot/${VmLinuzName}"
	ModLoopUrl="${LinuxMirror}/${DIST}/releases/${VER}/netboot/${ModLoopName}"
	echo -e "\n- initrd.gz:\t${CLR2}$InitrdUrl${CLR0}\n- linux:\t${CLR2}$VmLinuzUrl${CLR0}"
	curl -ksLo '/tmp/initrd.img' "$InitrdUrl"
	[[ $? -ne '0' ]] && error "Download '$InitrdName' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
	curl -ksLo '/tmp/vmlinuz' "$VmLinuzUrl"
	[[ $? -ne '0' ]] && error "Download '$VmLinuzName' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
elif [[ "$linux_release" == 'centos' ]] && [[ "$RedHatSeries" -le "7" ]]; then
	InitrdUrl="${LinuxMirror}/${DIST}/os/${VER}/images/pxeboot/initrd.img"
	VmLinuzUrl="${LinuxMirror}/${DIST}/os/${VER}/images/pxeboot/vmlinuz"
	echo -e "\n- initrd.gz:\t${CLR2}$InitrdUrl${CLR0}\n- linux:\t${CLR2}$VmLinuzUrl${CLR0}"
	curl -ksLo '/tmp/initrd.img' "$InitrdUrl"
	[[ $? -ne '0' ]] && error "Download 'initrd.img' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
	curl -ksLo '/tmp/vmlinuz' "$VmLinuzUrl"
	[[ $? -ne '0' ]] && error "Download 'vmlinuz' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
elif [[ "$linux_release" == 'centos' && "$RedHatSeries" -ge "8" ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]]; then
	InitrdUrl="${LinuxMirror}/${DIST}/BaseOS/${VER}/os/images/pxeboot/initrd.img"
	VmLinuzUrl="${LinuxMirror}/${DIST}/BaseOS/${VER}/os/images/pxeboot/vmlinuz"
	echo -e "\n- initrd.gz:\t${CLR2}$InitrdUrl${CLR0}\n- linux:\t${CLR2}$VmLinuzUrl${CLR0}"
	curl -ksLo '/tmp/initrd.img' "$InitrdUrl"
	[[ $? -ne '0' ]] && error "Download 'initrd.img' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
	curl -ksLo '/tmp/vmlinuz' "$VmLinuzUrl"
	[[ $? -ne '0' ]] && error "Download 'vmlinuz' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
elif [[ "$linux_release" == 'fedora' ]]; then
	InitrdUrl="${LinuxMirror}/releases/${DIST}/Server/${VER}/os/images/pxeboot/initrd.img"
	VmLinuzUrl="${LinuxMirror}/releases/${DIST}/Server/${VER}/os/images/pxeboot/vmlinuz"
	echo -e "\n- initrd.gz:\t${CLR2}$InitrdUrl${CLR0}\n- linux:\t${CLR2}$VmLinuzUrl${CLR0}"
	curl -ksLo '/tmp/initrd.img' "$InitrdUrl"
	[[ $? -ne '0' ]] && error "Download 'initrd.img' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
	curl -ksLo '/tmp/vmlinuz' "$VmLinuzUrl"
	[[ $? -ne '0' ]] && error "Download 'vmlinuz' for ${CLR3}$linux_release${CLR0} failed!\n" && exit 1
else
	bash $0 error
	exit 1
fi

if [[ "$IncFirmware" == '1' ]]; then
	if [[ "$linux_release" == 'debian' ]]; then
		if [[ "$IsCN" == "1" ]]; then
			curl -ksLo '/tmp/firmware.cpio.gz' "https://mirrors.ustc.edu.cn/debian-cdimage/unofficial/non-free/firmware/${DIST}/current/firmware.cpio.gz"
			[[ $? -ne '0' ]] && error "Download firmware for ${CLR1}$linux_release${CLR0} failed!\n" && exit 1
		else
			curl -ksLo '/tmp/firmware.cpio.gz' "http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/${DIST}/current/firmware.cpio.gz"
			[[ $? -ne '0' ]] && error "Download firmware for ${CLR1}$linux_release${CLR0} failed!\n" && exit 1
		fi
		if [[ "$ddMode" == '1' ]]; then
			vKernel_udeb=$(curl -ksL "http://$LinuxMirror/dists/$DIST/main/installer-$VER/current/images/udeb.list" | grep '^acpi-modules' | head -n1 | grep -o '[0-9]\{1,2\}.[0-9]\{1,2\}.[0-9]\{1,2\}-[0-9]\{1,2\}' | head -n1)
			[[ -z "vKernel_udeb" ]] && vKernel_udeb="6.1.0-11"
		fi
	elif [[ "$linux_release" == 'kali' ]]; then
		if [[ "$IsCN" == "1" ]]; then
			curl -ksLo /root/kaliFirmwareCheck 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/non-free/f/firmware-nonfree/?C=S&O=D'
			kaliFirmwareName=$(grep "href=\"firmware-nonfree" /root/kaliFirmwareCheck | head -n 1 | awk -F'\">' '/tar.xz/{print $3}' | cut -d'<' -f1 | cut -d'/' -f2)
			curl -ksLo '/tmp/kali_firmware.tar.xz' "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/non-free/f/firmware-nonfree/$kaliFirmwareName"
			[[ $? -ne '0' ]] && error "Download firmware for ${CLR1}$linux_release${CLR0} failed!\n" && exit 1
			rm -rf /root/kaliFirmwareCheck
		else
			curl -ksLo /root/kaliFirmwareCheck 'https://mirrors.ocf.berkeley.edu/kali/pool/non-free/f/firmware-nonfree/?C=S&O=D'
			kaliFirmwareName=$(grep "href=\"firmware-nonfree" /root/kaliFirmwareCheck | head -n 1 | awk -F'\">' '/tar.xz/{print $3}' | cut -d'<' -f1 | cut -d'/' -f2)
			curl -ksLo '/tmp/kali_firmware.tar.xz' "https://mirrors.ocf.berkeley.edu/kali/pool/non-free/f/firmware-nonfree/$kaliFirmwareName"
			[[ $? -ne '0' ]] && error "Download firmware for ${CLR1}$linux_release${CLR0} failed!\n" && exit 1
			rm -rf /root/kaliFirmwareCheck
		fi
		decompressedKaliFirmwareDir=$(echo $kaliFirmwareName | cut -d'.' -f 1 | sed 's/_/-/g')
	fi
fi

tmpDirAvail=$(df -TBM | grep "/tmp\|/dev/shm" | head -n 1 | awk '{print $5}' | tr -cd "[0-9]")
[[ "$tmpDirAvail" -lt "1024" ]] && mount -o remount,size=1G,noexec,nosuid,nodev,noatime tmpfs /tmp 2>/dev/null

[[ -d /tmp/boot ]] && rm -rf /tmp/boot
mkdir -p /tmp/boot
cd /tmp/boot

if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'ubuntu' ]] || [[ "$linux_release" == 'kali' ]] || [[ "$linux_release" == 'alpinelinux' ]]; then
	COMPTYPE="gzip"
elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
	COMPTYPE="$(file ../initrd.img | grep -o ':.*compressed data' | cut -d' ' -f2 | sed -r 's/(.*)/\L\1/' | head -n1)"
	[[ -z "$COMPTYPE" ]] && echo "Detect compressed type fail." && exit 1
fi
CompDected='0'
for COMP in $(echo -en 'gzip\nlzma\nxz'); do
	if [[ "$COMPTYPE" == "$COMP" ]]; then
		CompDected='1'
		if [[ "$COMPTYPE" == 'gzip' ]]; then
			NewIMG="initrd.img.gz"
		else
			NewIMG="initrd.img.$COMPTYPE"
		fi
		mv -f "/tmp/initrd.img" "/tmp/$NewIMG"
		break
	fi
done
[[ "$CompDected" != '1' ]] && echo "Detect compressed type not support." && exit 1
[[ "$COMPTYPE" == 'lzma' ]] && UNCOMP='xz --format=lzma --decompress'
[[ "$COMPTYPE" == 'xz' ]] && UNCOMP='xz --decompress'
[[ "$COMPTYPE" == 'gzip' ]] && UNCOMP='gzip -d'
$UNCOMP </tmp/$NewIMG | cpio --extract --make-directories --preserve-modification-time >>/dev/null 2>&1

if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]] || [[ "$linux_release" == 'ubuntu' ]]; then
	DebianPreseedProcess
	if [[ "$loaderMode" != "0" ]] && [[ "$setNet" == '0' ]]; then
		sed -i '/netcfg\/disable_autoconfig/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/dhcp_options/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/get_.*/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/confirm_static/d' /tmp/boot/preseed.cfg
	fi
	if [[ "$disksNum" -le "1" || "$setDisk" != "all" || -n "$setRaid" ]]; then
		sed -i 's/lvremove --select all -ff -y;//g' /tmp/boot/preseed.cfg
		sed -i 's/vgremove --select all -ff -y;//g' /tmp/boot/preseed.cfg
		sed -i 's/pvremove \/dev\/\* -ff -y;//g' /tmp/boot/preseed.cfg
	elif [[ "$disksNum" -ge "2" && "$setDisk" == "all" ]]; then
		[[ -z "$virtWhat" ]] || sed -i 's/pvremove \/dev\/\* -ff -y;//g' /tmp/boot/preseed.cfg
	fi
	if [[ "$disksNum" -ge "2" ]] && [[ -n "$setRaid" ]]; then
		sed -i 's/d-i partman\/early_command.*//g' /tmp/boot/preseed.cfg
		sed -ri "/d-i grub-installer\/bootdev.*/c\d-i grub-installer\/bootdev string $AllDisks" /tmp/boot/preseed.cfg
	fi
	[[ "$DebianDistNum" -le "8" || -n "$setRaid" ]] && sed -i '/d-i\ partman\/default_filesystem string xfs/d' /tmp/boot/preseed.cfg
	if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]]; then
		sed -i '/user-setup\/allow-password-weak/d' /tmp/boot/preseed.cfg
		sed -i '/user-setup\/encrypt-home/d' /tmp/boot/preseed.cfg
		sed -i '/pkgsel\/update-policy/d' /tmp/boot/preseed.cfg
		sed -i 's/umount\ \/media.*true\;\ //g' /tmp/boot/preseed.cfg
		[[ -f '/tmp/firmware.cpio.gz' ]] && gzip -d </tmp/firmware.cpio.gz | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
		[[ -f '/tmp/kali_firmware.tar.xz' ]] && {
			tar -Jxvf '/tmp/kali_firmware.tar.xz' -C /tmp/
			mv /tmp/$decompressedKaliFirmwareDir/* '/tmp/boot/lib/firmware/'
		}
	fi
	if [[ "$linux_release" == 'ubuntu' ]]; then
		sed -i '/d-i\ partman\/default_filesystem string xfs/d' /tmp/boot/preseed.cfg
		sed -i '/d-i\ grub-installer\/force-efi-extra-removable/d' /tmp/boot/preseed.cfg
		sed -i '/d-i\ lowmem\/low note/d' /tmp/boot/preseed.cfg
	fi
	if [[ "$linux_release" == 'kali' ]]; then
		sed -i 's/first multiselect minimal/first multiselect standard/g' /tmp/boot/preseed.cfg
		sed -i 's/upgrade select none/upgrade select full-upgrade/g' /tmp/boot/preseed.cfg
		sed -i 's/include string openssh-server/include string kali-linux-core openssh-server/g' /tmp/boot/preseed.cfg
		sed -i 's/d-i grub-installer\/with_other_os boolean true//g' /tmp/boot/preseed.cfg
	fi
	if [[ "$linux_release" == 'kali' ]]; then
		sed -ri 's/services-select multiselect security, updates/services-select multiselect updates/g' /tmp/boot/preseed.cfg
		sed -i '/d-i\ apt-setup\/security_host string/d' /tmp/boot/preseed.cfg
	elif [[ "$linux_release" == 'debian' && "$DebianDistNum" -le "9" ]]; then
		sed -ri 's/services-select multiselect security, updates/services-select multiselect/g' /tmp/boot/preseed.cfg
		sed -ri 's/enable-source-repositories boolean true/enable-source-repositories boolean false/g' /tmp/boot/preseed.cfg
		sed -i '/d-i\ apt-setup\/security_host string/d' /tmp/boot/preseed.cfg
	fi
	if [[ "$Network4Config" == "isStatic" ]] || [[ "$Network6Config" == "isStatic" ]]; then
		sed -i 's/ntp boolean true/ntp boolean false/g' /tmp/boot/preseed.cfg
		sed -i '/d-i\ clock-setup\/ntp-server string ntp.nict.jp/d' /tmp/boot/preseed.cfg
	fi
	[[ "$setInterfaceName" == "0" ]] && sed -i 's/net.ifnames=0 biosdevname=0//g' /tmp/boot/preseed.cfg
	[[ "$setIPv6" == "1" ]] && sed -i 's/ipv6.disable=1//g' /tmp/boot/preseed.cfg

	[[ "$ddMode" == '1' ]] && {
		WinNoDHCP() {
			echo -ne "for\0040\0057f\0040\0042tokens\00753\0052\0042\0040\0045\0045i\0040in\0040\0050\0047netsh\0040interface\0040show\0040interface\0040\0136\0174more\0040\00533\0040\0136\0174findstr\0040\0057I\0040\0057R\0040\0042本地\0056\0052\0040以太\0056\0052\0040Local\0056\0052\0040Ethernet\0042\0047\0051\0040do\0040\0050set\0040EthName\0075\0045\0045j\0051\r\nnetsh\0040\0055c\0040interface\0040ip\0040set\0040address\0040name\0075\0042\0045EthName\0045\0042\0040source\0075static\0040address\0075$IPv4\0040mask\0075$MASK\0040gateway\0075$GATE\r\nnetsh\0040\0055c\0040interface\0040ip\0040add\0040dnsservers\0040name\0075\0042\0045EthName\0045\0042\0040address\00758\00568\00568\00568\0040index\00751\0040validate\0075no\r\n\r\n" >>'/tmp/boot/net.tmp'
		}
		WinRDP() {
			echo -ne "netsh\0040firewall\0040set\0040portopening\0040protocol\0075ALL\0040port\0075$WinRemote\0040name\0075RDP\0040mode\0075ENABLE\0040scope\0075ALL\0040profile\0075ALL\r\nnetsh\0040firewall\0040set\0040portopening\0040protocol\0075ALL\0040port\0075$WinRemote\0040name\0075RDP\0040mode\0075ENABLE\0040scope\0075ALL\0040profile\0075CURRENT\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Network\0134NewNetworkWindowOff\0042\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0042\0040\0057v\0040fDenyTSConnections\0040\0057t\0040reg\0137dword\0040\0057d\00400\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0134Wds\0134rdpwd\0134Tds\0134tcp\0042\0040\0057v\0040PortNumber\0040\0057t\0040reg\0137dword\0040\0057d\0040$WinRemote\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0134WinStations\0134RDP\0055Tcp\0042\0040\0057v\0040PortNumber\0040\0057t\0040reg\0137dword\0040\0057d\0040$WinRemote\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0134WinStations\0134RDP\0055Tcp\0042\0040\0057v\0040UserAuthentication\0040\0057t\0040reg\0137dword\0040\0057d\00400\0040\0057f\r\nFOR\0040\0057F\0040\0042tokens\00752\0040delims\0075\0072\0042\0040\0045\0045i\0040in\0040\0050\0047SC\0040QUERYEX\0040TermService\0040\0136\0174FINDSTR\0040\0057I\0040\0042PID\0042\0047\0051\0040do\0040TASKKILL\0040\0057F\0040\0057PID\0040\0045\0045i\r\nFOR\0040\0057F\0040\0042tokens\00752\0040delims\0075\0072\0042\0040\0045\0045i\0040in\0040\0050\0047SC\0040QUERYEX\0040UmRdpService\0040\0136\0174FINDSTR\0040\0057I\0040\0042PID\0042\0047\0051\0040do\0040TASKKILL\0040\0057F\0040\0057PID\0040\0045\0045i\r\nSC\0040START\0040TermService\r\n\r\n" >>'/tmp/boot/net.tmp'
		}
		echo -ne "\0100ECHO\0040OFF\r\n\r\ncd\0056\0076\0045WINDIR\0045\0134GetAdmin\r\nif\0040exist\0040\0045WINDIR\0045\0134GetAdmin\0040\0050del\0040\0057f\0040\0057q\0040\0042\0045WINDIR\0045\0134GetAdmin\0042\0051\0040else\0040\0050\r\necho\0040CreateObject\0136\0050\0042Shell\0056Application\0042\0136\0051\0056ShellExecute\0040\0042\0045\0176s0\0042\0054\0040\0042\0045\0052\0042\0054\0040\0042\0042\0054\0040\0042runas\0042\0054\00401\0040\0076\0076\0040\0042\0045temp\0045\0134Admin\0056vbs\0042\r\n\0042\0045temp\0045\0134Admin\0056vbs\0042\r\ndel\0040\0057f\0040\0057q\0040\0042\0045temp\0045\0134Admin\0056vbs\0042\r\nexit\0040\0057b\00402\0051\r\n\r\n" >'/tmp/boot/net.tmp'
		[[ "$setNet" == '1' ]] && WinNoDHCP
		[[ "$setNet" == '0' ]] && [[ "$AutoNet" == '0' ]] && WinNoDHCP
		[[ "$setRDP" == '1' ]] && [[ -n "$WinRemote" ]] && WinRDP
		echo -ne "ECHO\0040SELECT\0040VOLUME\0075\0045\0045SystemDrive\0045\0045\0040\0076\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\nECHO\0040EXTEND\0040\0076\0076\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\nSTART\0040/WAIT\0040DISKPART\0040\0057S\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\nDEL\0040\0057f\0040\0057q\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\n\r\n" >>'/tmp/boot/net.tmp'
		echo -ne "cd\0040\0057d\0040\0042\0045ProgramData\0045\0057Microsoft\0057Windows\0057Start\0040Menu\0057Programs\0057Startup\0042\r\ndel\0040\0057f\0040\0057q\0040net\0056bat\r\n\r\n\r\n" >>'/tmp/boot/net.tmp'
		iconv -f 'UTF-8' -t 'GBK' '/tmp/boot/net.tmp' -o '/tmp/boot/net.bat'
		rm -rf '/tmp/boot/net.tmp'
	}
	[[ "$ddMode" == '0' ]] && {
		sed -i '/anna-install/d' /tmp/boot/preseed.cfg
		sed -i 's/wget.*\/sbin\/reboot\;\ //g' /tmp/boot/preseed.cfg
	}
	[[ "$BurnIrregularIpv4Status" == "1" ]] && {
		sed -i '/early_command string anna-install/d' /tmp/boot/preseed.cfg
	}
elif [[ "$linux_release" == 'alpinelinux' ]]; then
	alpineArchitecture="$VER"
	echo "ipv6" >>/tmp/boot/etc/modules
	if [[ "$setAutoConfig" == "1" ]]; then
		AlpineInitLineNum=$(grep -E -n '^exec (/bin/busybox )?switch_root' /tmp/boot/init | cut -d: -f1)
		AlpineInitLineNum=$((AlpineInitLineNum - 1))
		if [[ "$IsCN" == "1" ]]; then
			alpineInstallOrDdAdditionalFiles "https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Alpine/alpineInit.sh" "https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Alpine/network/resolv_cn.conf" "https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Alpine/motd.sh" "mirrors.ustc.edu.cn" "mirrors.tuna.tsinghua.edu.cn" "https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Ubuntu/ubuntuInit.sh" "https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Windows/windowsInit.sh" "https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Windows/SetupComplete.bat" "https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/RedHat/RHELinit.sh" "mirrors.ustc.edu.cn"
		else
			alpineInstallOrDdAdditionalFiles "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Alpine/alpineInit.sh" "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Alpine/network/resolv.conf" "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Alpine/motd.sh" "archive.ubuntu.com" "ports.ubuntu.com" "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Ubuntu/ubuntuInit.sh" "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Windows/windowsInit.sh" "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Windows/SetupComplete.bat" "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/RedHat/RHELinit.sh" "security.ubuntu.com"
		fi
		alpineNetcfgMirrorCn="https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Alpine/network/"
		alpineNetcfgMirror="https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Alpine/network/"
		[[ "$targetRelese" == 'Ubuntu' ]] && {
			ubuntuCloudinitMirrorCn="https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/Ubuntu/CloudInit/"
			ubuntuCloudinitMirror="https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/Ubuntu/CloudInit/"
		}
		[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && {
			rhelCloudinitMirrorCn="https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/RedHat/CloudInit/"
			rhelCloudinitMirror="https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/RedHat/CloudInit/"
		}
		if [[ "$IPStackType" == "IPv4Stack" ]]; then
			if [[ "$Network4Config" == "isDHCP" ]]; then
				if [[ "$IsCN" == "1" ]]; then
					AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv4_dhcp_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""dhcp_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirrorCn""dhcp_interfaces.cfg"
				else
					AlpineNetworkConf="$alpineNetcfgMirror""ipv4_dhcp_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirror""dhcp_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirror""dhcp_interfaces.cfg"
				fi
			elif [[ "$Network4Config" == "isStatic" ]]; then
				if [[ "$IsCN" == "1" ]]; then
					AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv4_static_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""ipv4_static_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirrorCn""ipv4_static_interfaces.cfg"
				else
					AlpineNetworkConf="$alpineNetcfgMirror""ipv4_static_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirror""ipv4_static_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirror""ipv4_static_interfaces.cfg"
				fi
			fi
			networkAdapter="$interface4"
		elif [[ "$IPStackType" == "BiStack" ]]; then
			if [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
				[[ "$IsCN" == "1" ]] && AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv4_ipv6_dhcp_interfaces" || AlpineNetworkConf="$alpineNetcfgMirror""ipv4_ipv6_dhcp_interfaces"
			elif [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isStatic" ]]; then
				[[ "$IsCN" == "1" ]] && AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv4_dhcp_ipv6_static_interfaces" || AlpineNetworkConf="$alpineNetcfgMirror""ipv4_dhcp_ipv6_static_interfaces"
			elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
				[[ "$IsCN" == "1" ]] && AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv4_static_ipv6_dhcp_interfaces" || AlpineNetworkConf="$alpineNetcfgMirror""ipv4_static_ipv6_dhcp_interfaces"
			elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isStatic" ]]; then
				[[ "$IsCN" == "1" ]] && AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv4_ipv6_static_interfaces" || AlpineNetworkConf="$alpineNetcfgMirror""ipv4_ipv6_static_interfaces"
			fi
			[[ "$iAddrNum" -ge "2" || "$i6AddrNum" -ge "2" ]] && {
				[[ "$IsCN" == "1" ]] && AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv4_static_interfaces" || AlpineNetworkConf="$alpineNetcfgMirror""ipv4_static_interfaces"
			}
			[[ "$targetRelese" == 'Ubuntu' ]] && {
				if [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""dhcp_interfaces.cfg" || cloudInitUrl="$ubuntuCloudinitMirror""dhcp_interfaces.cfg"
				elif [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isStatic" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""ipv4_dhcp_ipv6_static_interfaces.cfg" || cloudInitUrl="$ubuntuCloudinitMirror""ipv4_dhcp_ipv6_static_interfaces.cfg"
				elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""ipv4_static_ipv6_dhcp_interfaces.cfg" || cloudInitUrl="$ubuntuCloudinitMirror""ipv4_static_ipv6_dhcp_interfaces.cfg"
				elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isStatic" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""ipv4_static_ipv6_static_interfaces.cfg" || cloudInitUrl="$ubuntuCloudinitMirror""ipv4_static_ipv6_static_interfaces.cfg"
				fi
			}
			[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && {
				if [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$rhelCloudinitMirrorCn""dhcp_interfaces.cfg" || cloudInitUrl="$rhelCloudinitMirror""dhcp_interfaces.cfg"
				elif [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isStatic" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$rhelCloudinitMirrorCn""ipv4_dhcp_ipv6_static_interfaces.cfg" || cloudInitUrl="$rhelCloudinitMirror""ipv4_dhcp_ipv6_static_interfaces.cfg"
				elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$rhelCloudinitMirrorCn""ipv4_static_ipv6_dhcp_interfaces.cfg" || cloudInitUrl="$rhelCloudinitMirror""ipv4_static_ipv6_dhcp_interfaces.cfg"
				elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isStatic" ]]; then
					[[ "$IsCN" == "1" ]] && cloudInitUrl="$rhelCloudinitMirrorCn""ipv4_static_ipv6_static_interfaces.cfg" || cloudInitUrl="$rhelCloudinitMirror""ipv4_static_ipv6_static_interfaces.cfg"
				fi
			}
			networkAdapter="$interface4"
		elif [[ "$IPStackType" == "IPv6Stack" ]]; then
			if [[ "$Network6Config" == "isDHCP" ]]; then
				if [[ "$IsCN" == "1" ]]; then
					AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv6_dhcp_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""dhcp_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirrorCn""dhcp_interfaces.cfg"
				else
					AlpineNetworkConf="$alpineNetcfgMirror""ipv6_dhcp_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirror""dhcp_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirror""dhcp_interfaces.cfg"
				fi
			elif [[ "$Network6Config" == "isStatic" ]]; then
				if [[ "$IsCN" == "1" ]]; then
					AlpineNetworkConf="$alpineNetcfgMirrorCn""ipv6_static_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirrorCn""ipv6_static_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirrorCn""ipv6_static_interfaces.cfg"
				else
					AlpineNetworkConf="$alpineNetcfgMirror""ipv6_static_interfaces"
					[[ "$targetRelese" == 'Ubuntu' ]] && cloudInitUrl="$ubuntuCloudinitMirror""ipv6_static_interfaces.cfg"
					[[ "$targetRelese" == 'AlmaLinux' || "$targetRelese" == 'Rocky' ]] && cloudInitUrl="$rhelCloudinitMirror""ipv6_static_interfaces.cfg"
				fi
			fi
			networkAdapter="$interface6"
		fi
		if [[ "$IPStackType" == "BiStack" || "$IPStackType" == "IPv4Stack" ]]; then
			[[ "$BurnIrregularIpv4Status" == "1" ]] && {
				actualIp4Gate="$GATE"
				sed -i '/manual configuration/a\\t\tip link set dev '$interface4' up\n\t\tip addr add '$IPv4'/'$ipPrefix' dev '$interface4'\n\t\tip route add '$actualIp4Gate' dev '$interface4'\n\t\tip route add default via '$actualIp4Gate' dev '$interface4' onlink\n\t\techo '\''nameserver '$ipDNS1''\'' > /etc/resolv.conf\n\t\techo '\''nameserver '$ipDNS2''\'' >> /etc/resolv.conf' /tmp/boot/init
			}
		elif [[ "$IPStackType" == "IPv6Stack" ]]; then
			if [[ "$Network6Config" == "isStatic" ]]; then
				fakeIpv4="172.25.255.72"
				fakeIpMask="255.255.255.0"
				hackIpv6Context="manual configuration"
			elif [[ "$Network6Config" == "isDHCP" ]]; then
				hackIpv6Context="automatic configuration"
			fi
			sed -i '/'"$hackIpv6Context"'/a\\t\tdepmod\n\t\tmodprobe ipv6\n\t\tip link set dev '$interface6' up\n\t\tip -6 addr add '$ip6Addr'/'$actualIp6Prefix' dev '$interface6'\n\t\tip -6 route add '$ip6Gate' dev '$interface6'\n\t\tip -6 route add default via '$ip6Gate' dev '$interface6' onlink\n\t\techo '\''nameserver '$ip6DNS1''\'' > /etc/resolv.conf\n\t\techo '\''nameserver '$ip6DNS2''\'' >> /etc/resolv.conf' /tmp/boot/init
		fi
		writeMultipleIpv4Addresses "$iAddrNum"
		writeMultipleIpv6Addresses "$i6AddrNum"
		if [[ "$setMotd" == "1" ]]; then
			ModifyMOTD=$(echo -e "rm -rf \$sysroot/etc/motd
wget --no-check-certificate -O \$sysroot/etc/profile.d/motd.sh ${AlpineMotd}
chmod a+x \$sysroot/etc/profile.d/motd.sh")
		else
			ModifyMOTD=""
		fi
		if [[ -z "$targetRelese" ]]; then
			NetcfgTemplate=$(echo -e "wget --no-check-certificate -O \$sysroot/etc/network/tmp_interfaces ${AlpineNetworkConf}")
		else
			NetcfgTemplate=""
		fi
		cat <<EOF | sed -i "${AlpineInitLineNum}r /dev/stdin" /tmp/boot/init
# Download an apposite network configure template and is used for replacing IP details in late stages, only for Alpine Linux.
${NetcfgTemplate}

# Configure temporary nameservers.
rm -rf \$sysroot/etc/resolv.conf
wget --no-check-certificate -O \$sysroot/etc/resolv.conf ${AlpineDnsFile}
chmod a+x \$sysroot/etc/resolv.conf

# Creat a file to storage various prerequisite initial configs.
echo '' > \$sysroot/root/alpine.config

# To determine CPU architecture.
echo "alpineArchitecture  "${alpineArchitecture} >> \$sysroot/root/alpine.config
echo "ubuntuArchitecture  "${ubuntuArchitecture} >> \$sysroot/root/alpine.config
echo "rhelArchitecture  "${rhelArchitecture} >> \$sysroot/root/alpine.config

# To determine main hard drive.
echo "IncDisk  "${IncDisk} >> \$sysroot/root/alpine.config

# To determine mirror, only for Alpine Linux.
echo "LinuxMirror  "${LinuxMirror} >> \$sysroot/root/alpine.config

# To determine the release of Alpine Linux.
echo "alpineVer  "${DIST} >> \$sysroot/root/alpine.config

# To determine the distribution and release of Redhat series or Ubuntu for target system.
echo "ubuntuDigital  "${ubuntuDigital} >> \$sysroot/root/alpine.config
echo "targetRelese  "${targetRelese} >> \$sysroot/root/alpine.config
echo "RedHatSeries  "${RedHatSeries} >> \$sysroot/root/alpine.config

# To determine the mirror of software for target system.
echo "targetLinuxMirror  "${targetLinuxMirror} >> \$sysroot/root/alpine.config

# To determine the mirror of security for target system.
echo "targetLinuxSecurityMirror  "${targetLinuxSecurityMirror} >> \$sysroot/root/alpine.config

# To determine timezone.
echo "TimeZone  "${TimeZone} >> \$sysroot/root/alpine.config

# To determine root password.
echo 'tmpWORD  '$tmpWORD'' >> \$sysroot/root/alpine.config

# To determine ssh port.
echo "sshPORT  "${sshPORT} >> \$sysroot/root/alpine.config

# To determine the name of network adapter.
echo "networkAdapter  "${networkAdapter} >> \$sysroot/root/alpine.config

# To determine the configuration method of IPv4 network is static or dhcp.
echo "Network4Config  "${Network4Config} >> \$sysroot/root/alpine.config

# To determine the details of IPv4 static.
echo "IPv4  "${IPv4} >> \$sysroot/root/alpine.config
echo "MASK  "${MASK} >> \$sysroot/root/alpine.config
echo "ipPrefix  "${ipPrefix} >> \$sysroot/root/alpine.config
echo "actualIp4Prefix  "${actualIp4Prefix} >> \$sysroot/root/alpine.config
echo "actualIp4Subnet  "${actualIp4Subnet} >> \$sysroot/root/alpine.config
echo "GATE  "${GATE} >> \$sysroot/root/alpine.config
echo "actualIp4Gate  "${actualIp4Gate} >> \$sysroot/root/alpine.config
echo "BurnIrregularIpv4Status  "${BurnIrregularIpv4Status} >> \$sysroot/root/alpine.config
echo "ipDNS1  "${ipDNS1} >> \$sysroot/root/alpine.config
echo "ipDNS2  "${ipDNS2} >> \$sysroot/root/alpine.config
echo "iAddrNum  "${iAddrNum} >> \$sysroot/root/alpine.config
echo "writeIpsCmd  "'''${writeIpsCmd}''' >> \$sysroot/root/alpine.config

# To determine the configuration method of IPv6 network is static or dhcp.
echo "Network6Config  "${Network6Config} >> \$sysroot/root/alpine.config

# To determine the details of IPv6 static.
echo "ip6Addr  "${ip6Addr} >> \$sysroot/root/alpine.config
echo "ip6Mask  "${ip6Mask} >> \$sysroot/root/alpine.config
echo "actualIp6Prefix  "${actualIp6Prefix} >> \$sysroot/root/alpine.config
echo "ip6Gate  "${ip6Gate} >> \$sysroot/root/alpine.config
echo "ip6DNS1  "${ip6DNS1} >> \$sysroot/root/alpine.config
echo "ip6DNS2  "${ip6DNS2} >> \$sysroot/root/alpine.config
echo "i6AddrNum  "${i6AddrNum} >> \$sysroot/root/alpine.config
echo "writeIp6sCmd  "'''${writeIp6sCmd}''' >> \$sysroot/root/alpine.config

# To determine whether to disable IPv6 modules.
echo "setIPv6  "${setIPv6} >> \$sysroot/root/alpine.config

# To determine hostname.
echo "HostName  "${HostName} >> \$sysroot/root/alpine.config

# To determine whether in a virtual or physical hardware.
echo "virtualizationStatus  "${virtualizationStatus} >> \$sysroot/root/alpine.config

# To determine console display for Linux kernel.
echo "serialConsolePropertiesForGrub  "${serialConsolePropertiesForGrub} >> \$sysroot/root/alpine.config

# To determine whether to configure fail2ban.
echo "setFail2banStatus  "${setFail2banStatus} >> \$sysroot/root/alpine.config

# Add customized motd.
${ModifyMOTD}

# To determine whether to delete motd for target system.
echo "setMotd  "${setMotd} >> \$sysroot/root/alpine.config

# To determine whether to enable low memory mode so that reduce preconditioning components to make sure installation succeed on 768MB and lower.
echo "lowMemMode  "${lowMemMode} >> \$sysroot/root/alpine.config

# To determine the url of dd image.
echo "DDURL  "${DDURL} >> \$sysroot/root/alpine.config

# To determine decompress method for dd package.
echo "DEC_CMD  "${DEC_CMD} >> \$sysroot/root/alpine.config

# To determine the url of Linux Cloud-init file.
echo "cloudInitUrl  "${cloudInitUrl} >> \$sysroot/root/alpine.config

# To determine the url of Windows cmd init file.
echo "windowsStaticConfigCmd  "${windowsStaticConfigCmd} >> \$sysroot/root/alpine.config

# Download initial program.
wget --no-check-certificate -O \$sysroot/etc/local.d/${AlpineInitFileName} ${AlpineInitFile}

# Set initial program to execute automatically.
chmod a+x \$sysroot/etc/local.d/${AlpineInitFileName}
ln -s /etc/init.d/local \$sysroot/etc/runlevels/default/
EOF
	fi
elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
	AuthMethod="authselect --useshadow --passalgo sha512"
	SetTimeZone="timezone --utc ${TimeZone}"
	if [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]]; then
		if [[ "$RedHatSeries" -ge "8" ]]; then
			RedHatUrl="url --url=${LinuxMirror}/${DIST}/BaseOS/${VER}/os/"
			RepoAppStream="repo --name=\"AppStream\" --baseurl=${LinuxMirror}/${DIST}/AppStream/${VER}/os/"
			[[ "$linux_release" != 'centos' ]] && RepoExtras="repo --name=\"extras\" --baseurl=${LinuxMirror}/${DIST}/extras/${VER}/os/"
		elif [[ "$linux_release" == 'centos' ]] && [[ "$RedHatSeries" -le "7" ]]; then
			RedHatUrl="url --url=${LinuxMirror}/${DIST}/os/${VER}/"
			RepoUpdates="repo --name=\"updates\" --baseurl=${LinuxMirror}/${DIST}/updates/${VER}/"
			AuthMethod="auth --useshadow --passalgo=sha512"
			SetTimeZone="timezone --isUtc ${TimeZone}"
		fi
		InstallEpel="dnf install epel-release -y"
	elif [[ "$linux_release" == 'fedora' ]]; then
		RedHatUrl="url --url=${LinuxMirror}/releases/${DIST}/Server/${VER}/os/"
		if [[ "$IsCN" == "1" ]]; then
			RepoUpdates="repo --name=\"updates\" --baseurl=https://mirrors.bfsu.edu.cn/fedora/updates/${DIST}/Everything/${VER}/"
			RepoEverything="repo --name=\"Everything\" --baseurl=https://mirrors.ustc.edu.cn/fedora/releases/${DIST}/Everything/${VER}/os/"
		else
			RepoUpdates="repo --name=\"updates\" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f${DIST}&arch=${VER}"
			RepoEverything="repo --name=\"Everything\" --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-${DIST}&arch=${VER}"
		fi
	fi
	[[ "$IsCN" == "1" ]] && {
		if [[ "$linux_release" == 'rockylinux' ]]; then
			BaseUrl="dl.rockylinux.org/\$contentdir"
			TargetCnUrl="mirrors.ustc.edu.cn/rocky"
			[[ "$RedHatSeries" -le "8" ]] && ReposProperties="Rocky" || ReposProperties="rocky"
		elif [[ "$linux_release" == 'fedora' ]]; then
			BaseUrl="download.example/pub/fedora/linux"
			TargetCnUrl="mirrors.tuna.tsinghua.edu.cn/fedora"
			ReposProperties="fedora"
		fi
		ReplaceReposToCn="sed -e 's|^metalink=|#metalink=|g' \
-e 's|^mirrorlist=|#mirrorlist=|g' \
-e 's|^#baseurl=http://$BaseUrl|baseurl=https://$TargetCnUrl|g' \
-i.bak \
/etc/yum.repos.d/$ReposProperties*.repo"
		ReplaceEpelToCn="sed -e 's|^metalink=|#metalink=|g' \
-e 's|^#baseurl=https\?://download.fedoraproject.org/pub/epel/|baseurl=http://mirror.nju.edu.cn/epel/|g' \
-e 's|^#baseurl=https\?://download.example/pub/epel/|baseurl=http://mirror.nju.edu.cn/epel/|g' \
-i.bak \
/etc/yum.repos.d/epel*.repo"
		[[ "$linux_release" == 'centos' || "$linux_release" == 'almalinux' ]] && ReplaceReposToCn=""
		RestoreRepoCiscoOpenH26x="sed -ri 's|^#metalink=|metalink=|g' /etc/yum.repos.d/epel-cisco*.repo"
		[[ "$linux_release" == 'fedora' ]] && {
			ReplaceEpelToCn=""
			RestoreRepoCiscoOpenH26x="sed -ri 's|^#metalink=|metalink=|g' /etc/yum.repos.d/$ReposProperties-cisco*.repo"
		}
	}
	writeMultipleIpv4Addresses "$iAddrNum" "" '/etc/NetworkManager/system-connections/'$interface'.nmconnection'
	writeMultipleIpv6Addresses "$i6AddrNum" "" '/etc/NetworkManager/system-connections/'$interface'.nmconnection'
	if [[ "$IPStackType" == "IPv4Stack" ]]; then
		if [[ "$Network4Config" == "isDHCP" ]]; then
			NetConfigManually="network --device=$interface --bootproto=dhcp --ipv6=auto --nameserver=$ipDNS,$ip6DNS --hostname=$HostName --onboot=on"
		elif [[ "$Network4Config" == "isStatic" ]]; then
			NetConfigManually="network --device=$interface --bootproto=static --ip=$IPv4 --netmask=$actualIp4Subnet --gateway=$GATE --ipv6=auto --nameserver=$ipDNS,$ip6DNS --hostname=$HostName --onboot=on"
		fi
	elif [[ "$IPStackType" == "BiStack" ]]; then
		if [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
			NetConfigManually="network --device=$interface --bootproto=dhcp --ipv6=auto --nameserver=$ipDNS,$ip6DNS --hostname=$HostName --onboot=on"
		elif [[ "$Network4Config" == "isDHCP" ]] && [[ "$Network6Config" == "isStatic" ]]; then
			NetConfigManually="network --device=$interface --bootproto=dhcp --ipv6=$ip6Addr/$actualIp6Prefix --ipv6gateway=$ip6Gate --nameserver=$ipDNS,$ip6DNS --hostname=$HostName --onboot=on"
			[[ "$i6AddrNum" -ge "2" ]] && NetConfigManually="network --device=$interface --bootproto=dhcp --nameserver=$ipDNS --hostname=$HostName --onboot=on"
		elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isDHCP" ]]; then
			NetConfigManually="network --device=$interface --bootproto=static --ip=$IPv4 --netmask=$actualIp4Subnet --gateway=$GATE --ipv6=auto --nameserver=$ipDNS,$ip6DNS --hostname=$HostName --onboot=on"
		elif [[ "$Network4Config" == "isStatic" ]] && [[ "$Network6Config" == "isStatic" ]]; then
			NetConfigManually="network --device=$interface --bootproto=static --ip=$IPv4 --netmask=$actualIp4Subnet --gateway=$GATE --ipv6=$ip6Addr/$actualIp6Prefix --ipv6gateway=$ip6Gate --nameserver=$ipDNS,$ip6DNS --hostname=$HostName --onboot=on"
			[[ "$i6AddrNum" -ge "2" ]] && NetConfigManually="network --device=$interface --bootproto=static --ip=$IPv4 --netmask=$actualIp4Subnet --gateway=$GATE --nameserver=$ipDNS --hostname=$HostName --onboot=on"
		fi
	elif [[ "$IPStackType" == "IPv6Stack" ]]; then
		if [[ "$Network6Config" == "isDHCP" ]]; then
			NetConfigManually="network --device=$interface --bootproto=dhcp --ipv6=auto --nameserver=$ip6DNS --hostname=$HostName --onboot=on --activate --noipv4"
		elif [[ "$Network6Config" == "isStatic" ]]; then
			NetConfigManually="network --device=$interface --bootproto=dhcp --ipv6=$ip6Addr/$actualIp6Prefix --ipv6gateway=$ip6Gate --nameserver=$ip6DNS --hostname=$HostName --onboot=on --activate --noipv4"
		fi
	fi
	setNormalRecipe "$linux_release" "$disksNum" "$setSwap" "$setDisk" "$partitionTable" "$setFileSystem" "$EfiSupport" "$diskCapacity" "$IncDisk" "$AllDisks"
	setRaidRecipe "$setRaid" "$disksNum" "$AllDisks" "$linux_release"
	cat >/tmp/boot/ks.cfg <<EOF
# platform x86, AMD64, or Intel EM64T, or ARM aarch64

# Firewall configuration
firewall --enabled --ssh

# Use network installation and configure temporary mirrors
${RedHatUrl}
${RepoAppStream}
${RepoExtras}
${RepoUpdates}
${RepoEverything}

# Root password
rootpw --iscrypted ${myPASSWORD}

# System authorization information
${AuthMethod}

# Disable system configuration
firstboot --disable

# System language
lang en_US

# Keyboard layouts
keyboard us

# SELinux configuration
selinux --disabled

# Kdump configuration
%addon com_redhat_kdump --disable
%end

# Use text install
text

# unsupported_hardware
# vnc
# dont't config display manager
skipx

# System Timezone
${SetTimeZone}

# Network Configuration
${NetConfigManually}

# System bootloader configuration
bootloader --location=mbr --boot-drive=${ksIncDisk} --append="rhgb quiet crashkernel=0 net.ifnames=0 biosdevname=0 ipv6.disable=1 ${serialConsolePropertiesForGrub}"

# Clear the Master Boot Record
zerombr
${clearPart}

# Disk partitioning information
${FormatDisk}

# Reboot after installation
reboot

%packages --ignoremissing
@^minimal-environment
%end

# Enable services
# services --enabled=

# All modified command should only be executed between %post and %end location!
%post --interpreter=/bin/bash

# Config mirrors for servers in mainland of China to avoid of executing yum/dnf too slow
${ReplaceReposToCn}

# Install and config dnf and epel
yum install dnf -y
${InstallEpel}
${ReplaceEpelToCn}
${RestoreRepoCiscoOpenH26x}
dnf install fail2ban -y
dnf install bc bind-utils curl file jq lrzsz nano net-tools vim wget xz -y

# Disable selinux
sed -ri "/^#?SELINUX=.*/c\SELINUX=disabled" /etc/selinux/config

# Allow password login
sed -ri "/^#?PermitRootLogin.*/c\PermitRootLogin yes" /etc/ssh/sshd_config
sed -ri "/^#?PasswordAuthentication.*/c\PasswordAuthentication yes" /etc/ssh/sshd_config
# Change ssh port
sed -ri "/^#?Port.*/c\Port ${sshPORT}" /etc/ssh/sshd_config
# Enable ssh service
systemctl enable sshd
systemctl restart sshd

# Add new ssh port for firewalld
sed -i '6i \ \ <port port="${sshPORT}" protocol="tcp"/>' /etc/firewalld/zones/public.xml
sed -i '7i \ \ <port port="${sshPORT}" protocol="udp"/>' /etc/firewalld/zones/public.xml
# Allowance of IPv4 and IPv6 access
echo -e "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<direct>\n  <rule ipv=\"ipv4\" table=\"filter\" chain=\"INPUT\" priority=\"0\">-p icmp --icmp-type 32 -j DROP</rule>\n  <rule ipv=\"ipv4\" table=\"filter\" chain=\"INPUT\" priority=\"1\">-p icmp -j ACCEPT</rule>\n  <rule ipv=\"ipv6\" table=\"filter\" chain=\"INPUT\" priority=\"0\">-p icmpv6 --icmpv6-type 128 -j DROP</rule>\n  <rule ipv=\"ipv6\" table=\"filter\" chain=\"INPUT\" priority=\"1\">-p icmpv6 -j ACCEPT</rule>\n</direct>" > /etc/firewalld/direct.xml
# Reload firewalld service
firewall-cmd --reload

# Generate Fail2Ban config
touch /etc/fail2ban/jail.d/local.conf
echo -ne "[DEFAULT]\nbanaction = firewallcmd-ipset\nbackend = systemd\n\n[sshd]\nenabled = true" > /etc/fail2ban/jail.d/local.conf
# Allow Fail2Ban to access logs
touch /var/log/fail2ban.log
sed -i -E 's/^(logtarget =).*/\1 \/var\/log\/fail2ban.log/' /etc/fail2ban/fail2ban.conf
# Enable Fail2Ban service
systemctl enable fail2ban
systemctl restart fail2ban

# Add multiple IPv4 addresses
${deleteOriginalIpv4Coning}
${addIpv4AddrsForRedhat}

# Add multiple IPv6 addresses
${deleteOriginalIpv6Coning}
${setIpv6ConfigMethodForRedhat}
${addIpv6AddrsForRedhat}

# Clean logs and kickstart files
rm -rf /root/original-ks.cfg
rm -rf /root/anaconda-ks.cfg
rm -rf /root/install.*log

# Set OGOS function.sh
(echo "0 0 * * * curl -sL ${cf_proxy}https://raw.githubusercontent.com/OG-Open-Source/raw/refs/heads/main/shell/update-function.sh | bash") | crontab -
curl -ksLo /root/function.sh ${cf_proxy}https://raw.githubusercontent.com/OG-Open-Source/raw/refs/heads/main/shell/function.sh &>/dev/null && source function.sh
echo "source ~/function.sh" >> /root/.bashrc

${CentosEnableKejilion}
%end

EOF
	[[ "$setInterfaceName" == "0" ]] && sed -i 's/ net.ifnames=0 biosdevname=0//g' /tmp/boot/ks.cfg
	[[ "$setIPv6" == "1" ]] && sed -i 's/ipv6.disable=1//g' /tmp/boot/ks.cfg
	[[ "$setFail2banStatus" == "0" ]] && sed -i "/fail2ban/d" /tmp/boot/ks.cfg

	[[ "$UNKNOWHW" == '1' ]] && sed -i 's/^unsupported_hardware/#unsupported_hardware/g' /tmp/boot/ks.cfg
	[[ "$(echo "$DIST" | grep -o '^[0-9]\{1\}')" == '5' ]] && sed -i '0,/^%end/s//#%end/' /tmp/boot/ks.cfg
fi

rm -rf /boot/initrd.img
rm -rf /boot/vmlinuz
find . | cpio -o -H newc | gzip -1 >/tmp/initrd.img

if [[ ! -z "$GRUBTYPE" && "$GRUBTYPE" == "isGrub1" ]]; then
	if [[ "$setNetbootXyz" == "0" ]]; then
		[[ ! $(grep -iE '/etc/grub.d|begin|end|savedefault|load_video|gfxmode' $GRUBDIR/$GRUBFILE) ]] && {
			grub-mkconfig -o $GRUBDIR/$GRUBFILE >>/dev/null 2>&1
		}
		READGRUB='/tmp/grub.read'
		[[ -f $READGRUB ]] && rm -rf $READGRUB
		touch $READGRUB
		cp $GRUBDIR/$GRUBFILE "$GRUBDIR/$GRUBFILE_$(date "+%Y%m%d%H%M").bak"
		cat $GRUBDIR/$GRUBFILE | sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' | grep -aom 1 'menuentry\ [^{].*{.[^}].*}%%%%%%%' | sed 's/%%%%%%%/\n/g' | grep -v '^#' | sed '/^[[:space:]]*$/d' >$READGRUB
		LoadNum="$(cat $READGRUB | grep -c 'menuentry ')"
		if [[ "$LoadNum" -eq '1' ]]; then
			cat $READGRUB | sed '/^$/d' >/tmp/grub.new
		elif [[ "$LoadNum" -gt '1' ]]; then
			CFG0="$(awk '/menuentry /{print NR}' $READGRUB | head -n 1)"
			CFG2="$(awk '/menuentry /{print NR}' $READGRUB | head -n 2 | tail -n 1)"
			CFG1=""
			for tmpCFG in $(awk '/}/{print NR}' $READGRUB); do
				[ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG"
			done
			[[ -z "$CFG1" ]] && {
				error "Read $GRUBFILE !\n"
				exit 1
			}
			sed -n "$CFG0,$CFG1"p $READGRUB >/tmp/grub.new
			[[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
				error "Not configure $GRUBFILE !\n"
				exit 1
			}
		fi
		[ ! -f /tmp/grub.new ] && error "$GRUBFILE ! " && exit 1
		sed -i "/menuentry.*/c\menuentry\ \'Install OS \[$Relese\ $DIST\ $VER\]\'\ --class $linux_release\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
		sed -i "/echo.*Loading/d" /tmp/grub.new
		INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE | head -n 1)"

		[[ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new | awk '{print $2}' | tail -n 1 | grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot'

		LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new | awk '{print $1}' | head -n 1)"
		[[ -z "$LinuxKernel" ]] && echo -ne "\n${CLR1}Error${CLR0} read grub config!\n" && exit 1
		LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new | awk '{print $1}' | tail -n 1)"
		[ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new && LinuxIMG='initrd'
		[[ "$setInterfaceName" == "1" ]] && Add_OPTION="$Add_OPTION net.ifnames=0 biosdevname=0" || Add_OPTION="$Add_OPTION"
		[[ "$setIPv6" == "0" ]] && Add_OPTION="$Add_OPTION ipv6.disable=1" || Add_OPTION="$Add_OPTION"

		if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'ubuntu' ]] || [[ "$linux_release" == 'kali' ]]; then
			BOOT_OPTION="auto=true $Add_OPTION hostname=$HostName domain=$linux_release quiet"
		elif [[ "$linux_release" == 'alpinelinux' ]]; then
			if [[ "$IPStackType" == "BiStack" || "$IPStackType" == "IPv4Stack" ]]; then
				[[ "$Network4Config" == "isStatic" ]] && Add_OPTION="ip=$IPv4::$GATE:$MASK::$interface4::$ipDNS:" || Add_OPTION="ip=dhcp"
				[[ "$BurnIrregularIpv4Status" == "1" ]] && Add_OPTION="ip=$IPv4:::$ipMask::$interface4::$ipDNS:"
			elif [[ "$IPStackType" == "IPv6Stack" ]]; then
				[[ "$Network6Config" == "isStatic" ]] && Add_OPTION="ip=$fakeIpv4:::$fakeIpMask::$interface6:::" || Add_OPTION="ip=dhcp"
			fi
			BOOT_OPTION="alpine_repo=$LinuxMirror/$DIST/main/ modloop=$ModLoopUrl $Add_OPTION"
		elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
			ipv6ForRedhatGrub
			BOOT_OPTION="inst.ks=file://ks.cfg $Add_OPTION inst.nomemcheck quiet $ipv6StaticConfForKsGrub"
		fi
		[[ "$setAutoConfig" == "0" ]] && sed -i 's/inst.ks=file:\/\/ks.cfg//' $GRUBDIR/$GRUBFILE

		[[ -n "$ttyConsole" ]] && BOOT_OPTION="$BOOT_OPTION $ttyConsole"
		[ -n "$setConsole" ] && BOOT_OPTION="$BOOT_OPTION --- console=$setConsole"

		[[ "$Type" == 'InBoot' ]] && {
			sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" /tmp/grub.new
			sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.img" /tmp/grub.new
		}
		[[ "$Type" == 'NoBoot' ]] && {
			sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" /tmp/grub.new
			sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new
		}

		sed -i '$a\\n' /tmp/grub.new

		[[ -n $(grep "initrdfail" /tmp/grub.new) ]] && {
			sed -ri 's/\"\$\{initrdfail\}\".*/\"\$\{initrdfail\}\" = \"\" ]; then/g' /tmp/grub.new
			sed -ri 's/initrdfail/initrdfial/g' /tmp/grub.new
		}

		sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE
		sed -i ''${INSERTGRUB}'r /tmp/grub.new' $GRUBDIR/$GRUBFILE
		[[ -f $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv

		[[ $(grep "set default=\"[0-9]" $GRUBDIR/$GRUBFILE | tr -cd "[0-9]") != "0" ]] && {
			sed -ri 's/set default=\"[0-9].*/set default=\"0\"/g' $GRUBDIR/$GRUBFILE
		}

	elif [[ "$setNetbootXyz" == "1" ]]; then
		grub-mkconfig -o $GRUBDIR/$GRUBFILE >>/dev/null 2>&1
		grub-set-default "Bootable ISO Image: netboot.xyz" >>/dev/null 2>&1
		grub-reboot "Bootable ISO Image: netboot.xyz" >>/dev/null 2>&1
	fi
elif [[ ! -z "$GRUBTYPE" && "$GRUBTYPE" == "isGrub2" ]]; then
	if [[ "$setNetbootXyz" == "0" ]]; then
		if [[ -f $GRUBDIR/grubenv ]] && [[ -d /boot/loader/entries ]] && [[ "$(ls /boot/loader/entries | wc -l)" != "0" ]]; then
			LoaderPath=$(cat $GRUBDIR/grubenv | grep 'saved_entry=' | awk -F '=' '{print $2}')
			LpLength=$(echo ${#LoaderPath})
			LpFile="/boot/loader/entries/$LoaderPath.conf"
			if [[ "$LpLength" -le "1" ]] || [[ ! -f "$LpFile" ]]; then
				LpFile=$(ls -Sl /boot/loader/entries/ | grep -wv "*rescue*" | awk -F' ' '{print $NF}' | sed -n '2p')
				[[ "$(cat /boot/loader/entries/$LpFile | grep '^linux /boot/')" ]] && BootDIR='/boot' || BootDIR=''
			else
				[[ "$(cat $LpFile | grep '^linux /boot/')" ]] && BootDIR='/boot' || BootDIR=''
			fi
		else
			[[ -n "$(grep 'linux.*/\|kernel.*/' $GRUBDIR/$GRUBFILE | awk '{print $2}' | tail -n 1 | grep '^/boot/')" ]] && BootDIR='/boot' || BootDIR=''
		fi
		if [[ "$VER" == "x86_64" || "$VER" == "amd64" ]]; then
			[[ "$EfiSupport" == "enabled" ]] && BootHex="efi" || BootHex="16"
		elif [[ "$VER" == "aarch64" || "$VER" == "arm64" ]]; then
			BootHex=""
		fi
		CFG0="$(awk '/insmod part_/{print NR}' $GRUBDIR/$GRUBFILE | head -n 1)"
		CFG2tmp="$(awk '/--fs-uuid --set=root/{print NR}' $GRUBDIR/$GRUBFILE | head -n 2 | tail -n 1)"
		CFG2=$(expr $CFG2tmp + 1)
		CFG1=""
		for tmpCFG in $(awk '/fi/{print NR}' $GRUBDIR/$GRUBFILE); do
			[ "$tmpCFG" -ge "$CFG0" -a "$tmpCFG" -le "$CFG2" ] && CFG1="$tmpCFG"
		done
		if [[ -z "$CFG1" ]]; then
			SetRootCfg="$(awk '/--fs-uuid --set=root/{print NR}' $GRUBDIR/$GRUBFILE | head -n 2 | tail -n 1)"
			[[ "$SetRootCfg" == "" ]] && SetRootCfg="$(awk '/set root='\''hd[0-9]/{print NR}' /boot/grub2/grub.cfg | head -n 2 | tail -n 1)"
			InsmodPartArray=()
			IpaSpace=()
			for tmpCFG in $(awk '/insmod part_/{print NR}' $GRUBDIR/$GRUBFILE); do
				InsmodPartArray+=("$tmpCFG" "$InsmodPartArray")
				[[ $(expr $SetRootCfg - $tmpCFG) -gt "0" ]] && IpaSpace+=($(expr "$SetRootCfg" - "$tmpCFG") "$IpaSpace")
			done
			minArray=${IpaSpace[0]}
			for ((i = 1; i <= $(grep -io "insmod part_*" $GRUBDIR/$GRUBFILE | wc -l); i++)); do
				for j in ${IpaSpace[@]}; do
					[[ $minArray -gt $j ]] && minArray=$j
				done
			done
			CFG0=$(expr $SetRootCfg - $minArray)
			CFG1="$SetRootCfg"
		fi
		[[ -z "$CFG0" || -z "$CFG1" ]] && {
			error "Read $GRUBFILE !\n"
			exit 1
		}
		sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
		sed -i -e 's/^/  /' /tmp/grub.new
		[[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
			error "Not configure $GRUBFILE !\n"
			exit 1
		}
		[ ! -f /tmp/grub.new ] && error "$GRUBFILE !\n" && exit 1
		[[ "$setInterfaceName" == "1" ]] && Add_OPTION="$Add_OPTION net.ifnames=0 biosdevname=0" || Add_OPTION="$Add_OPTION"
		[[ "$setIPv6" == "0" ]] && Add_OPTION="$Add_OPTION ipv6.disable=1" || Add_OPTION="$Add_OPTION"
		grub2Order=$(find /boot/loader/entries/ -maxdepth 1 -name "*.conf" 2>/dev/null | wc -l)
		[[ "$grub2Order" == "0" ]] && grub2Order=$(grep -ic "menuentry '*'" $GRUBDIR/$GRUBFILE)
		[[ "$grub2Order" == "0" ]] && grub2Order=$(grub2-mkconfig -o $GRUBDIR/$GRUBFILE 2>&1 | grep -ic "linux image:")
		[[ "$grub2Order" == "0" ]] && grub2Order="saved"
		sed -ri 's/GRUB_DEFAULT=.*/GRUB_DEFAULT='$grub2Order'/g' /etc/default/grub
		if [[ "$linux_release" == 'ubuntu' || "$linux_release" == 'debian' || "$linux_release" == 'kali' ]]; then
			BOOT_OPTION="auto=true $Add_OPTION hostname=$HostName domain=$linux_release quiet"
		elif [[ "$linux_release" == 'alpinelinux' ]]; then
			if [[ "$IPStackType" == "BiStack" || "$IPStackType" == "IPv4Stack" ]]; then
				[[ "$Network4Config" == "isStatic" ]] && Add_OPTION="ip=$IPv4::$GATE:$MASK::$interface4::$ipDNS:" || Add_OPTION="ip=dhcp"
				[[ "$BurnIrregularIpv4Status" == "1" ]] && Add_OPTION="ip=$IPv4:::$ipMask::$interface4::$ipDNS:"
			elif [[ "$IPStackType" == "IPv6Stack" ]]; then
				[[ "$Network6Config" == "isStatic" ]] && Add_OPTION="ip=$fakeIpv4:::$fakeIpMask::$interface6:::" || Add_OPTION="ip=dhcp"
			fi
			BOOT_OPTION="alpine_repo=$LinuxMirror/$DIST/main/ modloop=$ModLoopUrl $Add_OPTION"
		elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
			ipv6ForRedhatGrub
			BOOT_OPTION="inst.ks=file://ks.cfg $Add_OPTION inst.nomemcheck quiet $ipv6StaticConfForKsGrub"
		fi
		[[ -n "$ttyConsole" ]] && BOOT_OPTION="$BOOT_OPTION $ttyConsole"
		[[ "$setAutoConfig" == "0" ]] && sed -i 's/inst.ks=file:\/\/ks.cfg//' $GRUBDIR/$GRUBFILE
		cat >>/etc/grub.d/40_custom <<EOF
menuentry 'Install $Relese $DIST $VER' --class $linux_release --class gnu-linux --class gnu --class os {
  load_video
  set gfxpayload=text
  insmod gzio
$(cat /tmp/grub.new)
  linux$BootHex $BootDIR/vmlinuz $BOOT_OPTION
  initrd$BootHex $BootDIR/initrd.img
}
EOF
		grub2-mkconfig -o $GRUBDIR/$GRUBFILE >>/dev/null 2>&1
		grub2-set-default "Install $Relese $DIST $VER" >>/dev/null 2>&1
		grub2-reboot "Install $Relese $DIST $VER" >>/dev/null 2>&1
	elif [[ "$setNetbootXyz" == "1" ]]; then
		grub2-mkconfig -o $GRUBDIR/$GRUBFILE >>/dev/null 2>&1
		grub2-set-default "Bootable ISO Image: netboot.xyz" >>/dev/null 2>&1
		grub2-reboot "Bootable ISO Image: netboot.xyz" >>/dev/null 2>&1
	fi
fi

checkAndReplaceEfiGrub

if [[ "$loaderMode" == "0" ]]; then
	cp -f /tmp/initrd.img /boot/initrd.img || sudo cp -f /tmp/initrd.img /boot/initrd.img
	cp -f /tmp/vmlinuz /boot/vmlinuz || sudo cp -f /tmp/vmlinuz /boot/vmlinuz
	chown root:root $GRUBDIR/$GRUBFILE
	chmod 444 $GRUBDIR/$GRUBFILE
else
	rm -rf "$HOME/loader"
	mkdir -p "$HOME/loader"
	cp -rf "/tmp/initrd.img" "$HOME/loader/initrd.img"
	cp -rf "/tmp/vmlinuz" "$HOME/loader/vmlinuz"
	[[ -f "/tmp/initrd.img" ]] && rm -rf "/tmp/initrd.img"
	[[ -f "/tmp/vmlinuz" ]] && rm -rf "/tmp/vmlinuz"
	echo && ls -AR1 "$HOME/loader"
fi

[[ "$setAutoConfig" != "0" || "$setNetbootXyz" != "1" || "$loaderMode" == "0" ]] && {
	echo -e "\n${CLR8}## Grub and Config Files${CLR0}"
	echo -e "${CLR8}$(LINE - "32")${CLR0}"
	echo "$GRUBDIR/$GRUBFILE"
	if [[ "$linux_release" == 'debian' ]] || [[ "$linux_release" == 'kali' ]]; then
		echo "/tmp/boot/preseed.cfg"
	elif [[ "$linux_release" == 'centos' ]] || [[ "$linux_release" == 'rockylinux' ]] || [[ "$linux_release" == 'almalinux' ]] || [[ "$linux_release" == 'fedora' ]]; then
		echo "/tmp/boot/ks.cfg"
	elif [[ "$linux_release" == 'alpinelinux' ]]; then
		echo "/tmp/boot/init"
	fi
}

if [[ "$setAutoReboot" == "1" ]]; then
	echo
	for i in {5..1}; do
		echo -ne "\r${CLR3}System will reboot in $i seconds...${CLR0}"
		sleep 1
	done
	reboot || sudo reboot
else
	echo
	SYS_REBOOT
fi

exit 1
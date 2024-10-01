#!/bin/bash

## License: GPL
## It can reinstall Debian, Ubuntu, CentOS system with network.
## Default root password: 1917159
## Blog: https://moeclub.org
## Written By MoeClub.org

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

tmpVER=''
tmpDIST=''
tmpURL=''
tmpWORD=''
tmpMirror=''
ipAddr=''
ipMask=''
ipGate=''
ipDNS='1.1.1.1'
IncDisk='default'
interface=''
interfaceSelect=''
Relese=''
sshPORT='22'
ddMode='0'
setNet='0'
setRDP='0'
setIPv6='0'
isMirror='0'
FindDists='0'
loaderMode='0'
IncFirmware='0'
SpikCheckDIST='0'
setInterfaceName='0'
UNKNOWHW='0'
UNVER='6.4'
GRUBDIR=''
GRUBFILE=''
GRUBVER=''
VER=''
setCMD=''
setConsole=''

while [[ $# -ge 1 ]]; do
	case $1 in
		-v)
			shift
			tmpVER="$1"
			shift
			;;
		-d)
			shift
			Relese='Debian'
			tmpDIST="$1"
			shift
			;;
		-u)
			shift
			Relese='Ubuntu'
			tmpDIST="$1"
			shift
			;;
		-c)
			shift
			Relese='CentOS'
			tmpDIST="$1"
			shift
			;;
		-dd)
			shift
			ddMode='1'
			tmpURL="$1"
			shift
			;;
		-p)
			shift
			tmpWORD="$1"
			shift
			;;
		-i)
			shift
			interfaceSelect="$1"
			shift
			;;
		--ip-addr)
			shift
			ipAddr="$1"
			shift
			;;
		--ip-mask)
			shift
			ipMask="$1"
			shift
			;;
		--ip-gate)
			shift
			ipGate="$1"
			shift
			;;
		--ip-dns)
			shift
			ipDNS="$1"
			shift
			;;
		--dev-net)
			shift
			setInterfaceName='1'
			;;
		--loader)
			shift
			loaderMode='1'
			;;
		-apt|-yum)
			shift
			isMirror='1'
			tmpMirror="$1"
			shift
			;;
		-rdp)
			shift
			setRDP='1'
			WinRemote="$1"
			shift
			;;
		-cmd)
			shift
			setCMD="$1"
			shift
			;;
		-console)
			shift
			setConsole="$1"
			shift
			;;
		-firmware)
			shift
			IncFirmware="1"
			;;
		-port)
			shift
			sshPORT="$1"
			shift
			;;
		--noipv6)
			shift
			setIPv6='1'
			;;
		-a|-m|-ssl)
			shift
			;;
		*)
			if [[ "$1" != 'error' ]]; then echo -ne "${CLR1}Invaild option: '$1'${CLR0}\n\n"; fi
			echo -ne " Usage:\n\tbash $(basename $0)\t-d/--debian [${CLR3}${CLR4}dists-name${CLR0}]\n\t\t\t\t-u/--ubuntu [${CLR4}dists-name${CLR0}]\n\t\t\t\t-c/--centos [${CLR4}dists-name${CLR0}]\n\t\t\t\t-v/--ver [32/i386|64/${CLR3}${CLR4}amd64${CLR0}] [${CLR3}${CLR4}dists-verison${CLR0}]\n\t\t\t\t--ip-addr/--ip-gate/--ip-mask\n\t\t\t\t-apt/-yum/--mirror\n\t\t\t\t-dd/--image\n\t\t\t\t-p [linux password]\n\t\t\t\t-port [linux ssh port]\n"
			exit 1;
			;;
	esac
done

[ "$(id -u)" -ne 0 ] && { echo -e "${CLR1}Please run this script as root user.${CLR0}"; exit 1; }

dependence(){
	Full='0';
	for BIN_DEP in `echo "$1" |sed 's/,/\n/g'`; do
		if [[ -n "$BIN_DEP" ]]; then
			Found='0';
			for BIN_PATH in `echo "$PATH" |sed 's/:/\n/g'`; do
				ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
				if [ $? == '0' ]; then
					Found='1';
					break;
				fi
			done
			if [ "$Found" == '1' ]; then
				echo -en "[${CLR2}OK${CLR0}]\t";
			else
				Full='1';
				echo -en "[${CLR1}Not Install${CLR0}]";
			fi
			echo -en "\t$BIN_DEP\n";
		fi
	done
	if [ "$Full" == '1' ]; then
		echo -ne "\n${CLR1}Error! ${CLR0}Please use '${CLR3}apt${CLR0}' or '${CLR3}yum${CLR0}' install it.\n\n\n"
		exit 1;
	fi
}

selectMirror(){
	[ $# -ge 3 ] || exit 1
	Relese=$(echo "$1" |sed -r 's/(.*)/\L\1/')
	DIST=$(echo "$2" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
	VER=$(echo "$3" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
	New=$(echo "$4" |sed 's/\ //g')
	[ -n "$Relese" ] && [ -n "$DIST" ] && [ -n "$VER" ] || exit 1
	if [ "$Relese" == "debian" ] || [ "$Relese" == "ubuntu" ]; then
		[ "$DIST" == "focal" ] && legacy="legacy-" || legacy=""
		TEMP="SUB_MIRROR/dists/${DIST}/main/installer-${VER}/current/${legacy}images/netboot/${Relese}-installer/${VER}/initrd.gz"
	elif [ "$Relese" == "centos" ]; then
		TEMP="SUB_MIRROR/${DIST}/os/${VER}/isolinux/initrd.img"
	fi
	[ -n "$TEMP" ] || exit 1
	mirrorStatus=0
	declare -A MirrorBackup
	MirrorBackup=(["debian0"]="" ["debian1"]="http://deb.debian.org/debian" ["debian2"]="http://archive.debian.org/debian" ["ubuntu0"]="" ["ubuntu1"]="http://archive.ubuntu.com/ubuntu" ["ubuntu2"]="http://ports.ubuntu.com" ["centos0"]="" ["centos1"]="http://mirror.centos.org/centos" ["centos2"]="http://vault.centos.org")
	echo "$New" |grep -q '^http://\|^https://\|^ftp://' && MirrorBackup[${Relese}0]="$New"
	for mirror in $(echo "${!MirrorBackup[@]}" |sed 's/\ /\n/g' |sort -n |grep "^$Relese"); do
		Current="${MirrorBackup[$mirror]}"
		[ -n "$Current" ] || continue
		MirrorURL=`echo "$TEMP" |sed "s#SUB_MIRROR#${Current}#g"`
		wget --no-check-certificate --spider --timeout=3 -o /dev/null "$MirrorURL"
		[ $? -eq 0 ] && mirrorStatus=1 && break
	done
	[ $mirrorStatus -eq 1 ] && echo "$Current" || exit 1
}

netmask() {
    local cidr=$1
    local mask=""
    local full_octets=$((cidr/8))
    local partial_octet=$((cidr%8))

    for ((i=0; i<4; i++)); do
        if [ $i -lt $full_octets ]; then
            mask="${mask}255"
        elif [ $i -eq $full_octets ]; then
            mask="${mask}$((256 - 2**(8-partial_octet)))"
        else
            mask="${mask}0"
        fi
        [ $i -lt 3 ] && mask="${mask}."
    done

    echo "$mask"
	echo "CIDR 24 netmask: $(netmask 24)"
	echo "CIDR 16 netmask: $(netmask 16)"
	echo "CIDR 8 netmask: $(netmask 8)"
	echo "CIDR 22 netmask: $(netmask 22)"
	sleep 3
}

getInterface(){
    echo "Debug: Entering getInterface function"
    interface=""
    Interfaces=$(ip -o addr show | awk '$2 !~ /^(lo|sit|stf|gif|dummy|vmnet|vir|gre|ipip|ppp|bond|tun|tap|ip6gre|ip6tnl|teql|ocserv|vpn)/ && $3 == "inet" {print $2}' | sort -u)
    echo "Debug: Available interfaces: $Interfaces"
    
    for iface in $Interfaces; do
        if ip addr show $iface | grep -q 'inet '; then
            interface="$iface"
            echo "Debug: Selected interface: $interface"
            break
        fi
    done
    
    if [ -z "$interface" ]; then
        interface=$(ip -o link show | awk '$2 !~ /^(lo|sit|stf|gif|dummy|vmnet|vir|gre|ipip|ppp|bond|tun|tap|ip6gre|ip6tnl|teql|ocserv|vpn)/ {gsub(/:/, "", $2); print $2; exit}')
        echo "Debug: Fallback interface: $interface"
    fi
    
    echo "$interface"
}

getDisk(){
	disks=`lsblk | sed 's/[[:space:]]*$//g' |grep "disk$" |cut -d' ' -f1 |grep -v "fd[0-9]*\|sr[0-9]*" |head -n1`
	[ -n "$disks" ] || echo ""
	echo "$disks" |grep -q "/dev"
	[ $? -eq 0 ] && echo "$disks" || echo "/dev/$disks"
}

getGrub(){
	Boot="${1:-/boot}"
	folder=`find "$Boot" -type d -name "grub*" 2>/dev/null |head -n1`
	[ -n "$folder" ] || return
	fileName=`ls -1 "$folder" 2>/dev/null |grep '^grub.conf$\|^grub.cfg$'`
	if [ -z "$fileName" ]; then
		ls -1 "$folder" 2>/dev/null |grep -q '^grubenv$'
		[ $? -eq 0 ] || return
		folder=`find "$Boot" -type f -name "grubenv" 2>/dev/null |xargs dirname |grep -v "^$folder" |head -n1`
		[ -n "$folder" ] || return
		fileName=`ls -1 "$folder" 2>/dev/null |grep '^grub.conf$\|^grub.cfg$'`
	fi
	[ -n "$fileName" ] || return
	[ "$fileName" == "grub.cfg" ] && ver="0" || ver="1"
	echo "${folder}:${fileName}:${ver}"
}

lowMem(){
	mem=`grep "^MemTotal:" /proc/meminfo 2>/dev/null |grep -o "[0-9]*"`
	[ -n "$mem" ] || return 0
	[ "$mem" -le "524288" ] && return 1 || return 0
}

if [[ "$loaderMode" == "0" ]]; then
	Grub=`getGrub "/boot"`
	[ -z "$Grub" ] && echo -ne "${CLR1}Error! Not Found grub.${CLR0}\n" && exit 1;
	GRUBDIR=`echo "$Grub" |cut -d':' -f1`
	GRUBFILE=`echo "$Grub" |cut -d':' -f2`
	GRUBVER=`echo "$Grub" |cut -d':' -f3`
fi

[ -n "$Relese" ] || Relese='Debian'
linux_relese=$(echo "$Relese" |sed 's/\ //g' |sed -r 's/(.*)/\L\1/')
clear && echo -e "\n${CLR8}# Check Dependence${CLR0}\n"

if [[ "$ddMode" == '1' ]]; then
	dependence iconv;
	linux_relese='debian';
	tmpDIST='bullseye';
	tmpVER='amd64';
fi

[ -n "$ipAddr" ] && [ -n "$ipMask" ] && [ -n "$ipGate" ] && setNet='1';
if [ "$setNet" == "0" ]; then
	dependence ip
	[ -n "$interface" ] || interface=$(getInterface)
	echo "Debug: Selected interface after getInterface: $interface"

	if [ -n "$interface" ]; then
		iAddr=$(ip addr show dev $interface | grep "inet " | head -n1 | awk '{print $2}')
		echo "Debug: iAddr=$iAddr"
		
		if [ -n "$iAddr" ]; then
			ipAddr=$(echo $iAddr | cut -d'/' -f1)
			ipMask=$(netmask $(echo $iAddr | cut -d'/' -f2))
		else
			echo "Debug: No IPv4 address found for interface $interface"
		fi
		
		ipGate=$(ip route show dev $interface | grep default | awk '{print $3}')
	else
		echo "Debug: No valid interface found"
	fi

	echo "Debug: interface=$interface, ipAddr=$ipAddr, ipMask=$ipMask, ipGate=$ipGate"
	sleep 3
fi
if [ -z "$interface" ]; then
	dependence ip
	[ -n "$interface" ] || interface=`getInterface`
fi
IPv4="$ipAddr"; MASK="$ipMask"; GATE="$ipGate";
echo "Debug: IPv4=$IPv4, MASK=$MASK, GATE=$GATE, ipDNS=$ipDNS"
sleep 3

[ -n "$IPv4" ] && [ -n "$MASK" ] && [ -n "$GATE" ] && [ -n "$ipDNS" ] || {
	echo -ne "\n${CLR1}Error: Invalid network config${CLR0}\n\n"
	echo "Debug: Selected interface is $(getInterface)"
	bash $0 error;
	exit 1;
}

if [[ "$Relese" == 'Debian' ]] || [[ "$Relese" == 'Ubuntu' ]]; then
	dependence wget,awk,grep,sed,cut,cat,lsblk,cpio,gzip,find,dirname,basename;
elif [[ "$Relese" == 'CentOS' ]]; then
	dependence wget,awk,grep,sed,cut,cat,lsblk,cpio,gzip,find,dirname,basename,file,xz;
fi
[ -n "$tmpWORD" ] && dependence openssl
[[ -n "$tmpWORD" ]] && myPASSWORD=`openssl passwd -1 "$tmpWORD"`;
[[ -z "$myPASSWORD" ]] && myPASSWORD='$1$if0wm8m4$ThLGSg.au7/k8UF/Iq0BB/';

tempDisk=`getDisk`; [ -n "$tempDisk" ] && IncDisk="$tempDisk"

case `uname -m` in aarch64|arm64) VER="arm64";; x86|i386|i686) VER="i386";; x86_64|amd64) VER="amd64";; *) VER="";; esac
tmpVER="$(echo "$tmpVER" |sed -r 's/(.*)/\L\1/')";
if [[ "$VER" != "arm64" ]] && [[ -n "$tmpVER" ]]; then
	case "$tmpVER" in i386|i686|x86|32) VER="i386";; amd64|x86_64|x64|64) [[ "$Relese" == 'CentOS' ]] && VER='x86_64' || VER='amd64';; *) VER='';; esac
fi

if [[ ! -n "$VER" ]]; then
	echo "${CLR1}Error! Not Architecture.${CLR0}"
	bash $0 error;
	exit 1;
fi

if [[ -z "$tmpDIST" ]]; then
	return;
fi

if [[ -n "$tmpDIST" ]]; then
	if [[ "$Relese" == 'Debian' ]]; then
		SpikCheckDIST='0'
		DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
		echo "$DIST" |grep -q '[0-9]';
		[[ $? -eq '0' ]] && {
			isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p' |cut -d'.' -f1)";
			[[ -n $isDigital ]] && {
				[[ "$isDigital" == '7' ]] && DIST='wheezy';
				[[ "$isDigital" == '8' ]] && DIST='jessie';
				[[ "$isDigital" == '9' ]] && DIST='stretch';
				[[ "$isDigital" == '10' ]] && DIST='buster';
				[[ "$isDigital" == '11' ]] && DIST='bullseye';
				[[ "$isDigital" == '12' ]] && DIST='bookworm';
			}
		}
		LinuxMirror=$(selectMirror "$Relese" "$DIST" "$VER" "$tmpMirror")
	fi
	if [[ "$Relese" == 'Ubuntu' ]]; then
		SpikCheckDIST='0'
		DIST="$(echo "$tmpDIST" |sed -r 's/(.*)/\L\1/')";
		echo "$DIST" |grep -q '[0-9]';
		[[ $? -eq '0' ]] && {
			isDigital="$(echo "$DIST" |grep -o '[\.0-9]\{1,\}' |sed -n '1h;1!H;$g;s/\n//g;$p')";
			[[ -n $isDigital ]] && {
				[[ "$isDigital" == '12.04' ]] && DIST='precise';
				[[ "$isDigital" == '14.04' ]] && DIST='trusty';
				[[ "$isDigital" == '16.04' ]] && DIST='xenial';
				[[ "$isDigital" == '18.04' ]] && DIST='bionic';
				[[ "$isDigital" == '20.04' ]] && DIST='focal';
				# [[ "$isDigital" == '22.04' ]] && DIST='jammy';
				# [[ "$isDigital" == '24.04' ]] && DIST='noble';
			}
		}
		LinuxMirror=$(selectMirror "$Relese" "$DIST" "$VER" "$tmpMirror")
	fi
	if [[ "$Relese" == 'CentOS' ]]; then
		SpikCheckDIST='1'
		DISTCheck="$(echo "$tmpDIST" |grep -o '[\.0-9]\{1,\}' |head -n1)";
		LinuxMirror=$(selectMirror "$Relese" "$DISTCheck" "$VER" "$tmpMirror")
		ListDIST="$(wget --no-check-certificate -qO- "$LinuxMirror/dir_sizes" |cut -f2 |grep '^[0-9]')"
		DIST="$(echo "$ListDIST" |grep "^$DISTCheck" |head -n1)"
		[[ -z "$DIST" ]] && {
			echo -ne "\n${CLR1}The dists version not found in this mirror, Please check it! ${CLR0}\n\n"
			bash $0 error;
			exit 1;
		}
		wget --no-check-certificate -qO- "$LinuxMirror/$DIST/os/$VER/.treeinfo" |grep -q 'general';
		[[ $? != '0' ]] && {
			echo -ne "\n${CLR1}The version not found in this mirror, Please change mirror try again! ${CLR0}\n\n";
			exit 1;
		}
	fi
fi

if [[ -z "$LinuxMirror" ]]; then
	echo -ne "${CLR1}Error! ${CLR0}Invalid mirror! \n"
	[ "$Relese" == 'Debian' ] && echo -en "${CLR2}example:${CLR0} http://deb.debian.org/debian\n\n";
	[ "$Relese" == 'Ubuntu' ] && echo -en "${CLR2}example:${CLR0} http://archive.ubuntu.com/ubuntu\n\n";
	[ "$Relese" == 'CentOS' ] && echo -en "${CLR2}example:${CLR0} http://mirror.centos.org/centos\n\n";
	bash $0 error;
	exit 1;
fi

if [[ "$SpikCheckDIST" == '0' ]]; then
	DistsList="$(wget --no-check-certificate -qO- "$LinuxMirror/dists/" |grep -o 'href=.*/"' |cut -d'"' -f2 |sed '/-\|old\|Debian\|experimental\|stable\|test\|sid\|devel/d' |grep '^[^/]' |sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')";
	for CheckDEB in `echo "$DistsList" |sed 's/;/\n/g'`; do
		[[ "$CheckDEB" == "$DIST" ]] && FindDists='1' && break;
	done
	[[ "$FindDists" == '0' ]] && {
		echo -ne "\nThe dists version not found, Please check it! \n\n"
		bash $0 error;
		exit 1;
	}
fi

if [[ "$ddMode" == '1' ]]; then
	if [[ -n "$tmpURL" ]]; then
		DDURL="$tmpURL"
		echo "$DDURL" |grep -q '^http://\|^ftp://\|^https://';
		[[ $? -ne '0' ]] && echo "Please input valid URL, Only support http://, ftp:// and https:// !" && exit 1;
	else
		echo "Please input valid image URL!";
		exit 1;
	fi
fi

clear && echo -e "\n${CLR8}# Install${CLR0}\n"

[[ "$ddMode" == '1' ]] && echo -ne "${CLR4}Auto Mode${CLR0} install ${CLR2}Windows${CLR0}\n[${CLR2}$DDURL${CLR0}]\n"

if [ -z "$interfaceSelect" ]; then
	if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
		interfaceSelect="auto"
	elif [[ "$linux_relese" == 'centos' ]]; then
		interfaceSelect="link"
	fi
fi

if [[ "$linux_relese" == 'centos' ]]; then
	if [[ "$DIST" != "$UNVER" ]]; then
		awk 'BEGIN{print '${UNVER}'-'${DIST}'}' |grep -q '^-'
		if [ $? != '0' ]; then
			UNKNOWHW='1';
			echo -en "${CLR2}The version lower then ${CLR1}$UNVER${CLR2} may not support in auto mode! ${CLR0}\n";
		fi
		awk 'BEGIN{print '${UNVER}'-'${DIST}'+0.59}' |grep -q '^-'
		if [ $? == '0' ]; then
			echo -en "\n${CLR1}The version higher then ${CLR2}6.10 ${CLR1}is not support in current! ${CLR0}\n\n"
			exit 1;
		fi
	fi
fi

echo -e "\n[${CLR2}$Relese${CLR0}] [${CLR2}$DIST${CLR0}] [${CLR2}$VER${CLR0}] Downloading..."

if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
	[ "$DIST" == "focal" ] && legacy="legacy-" || legacy=""
	wget --no-check-certificate -qO '/tmp/initrd.img' "${LinuxMirror}/dists/${DIST}/main/installer-${VER}/current/${legacy}images/netboot/${linux_relese}-installer/${VER}/initrd.gz"
	[[ $? -ne '0' ]] && echo -ne "${CLR1}Error! ${CLR0}Download 'initrd.img' for ${CLR2}$linux_relese${CLR0} failed! \n" && exit 1
	wget --no-check-certificate -qO '/tmp/vmlinuz' "${LinuxMirror}/dists/${DIST}${inUpdate}/main/installer-${VER}/current/${legacy}images/netboot/${linux_relese}-installer/${VER}/linux"
	[[ $? -ne '0' ]] && echo -ne "${CLR1}Error! ${CLR0}Download 'vmlinuz' for ${CLR2}$linux_relese${CLR0} failed! \n" && exit 1
	MirrorHost="$(echo "$LinuxMirror" |awk -F'://|/' '{print $2}')";
	MirrorFolder="$(echo "$LinuxMirror" |awk -F''${MirrorHost}'' '{print $2}')";
	[ -n "$MirrorFolder" ] || MirrorFolder="/"
elif [[ "$linux_relese" == 'centos' ]]; then
	wget --no-check-certificate -qO '/tmp/initrd.img' "${LinuxMirror}/${DIST}/os/${VER}/isolinux/initrd.img"
	[[ $? -ne '0' ]] && echo -ne "${CLR1}Error! ${CLR0}Download 'initrd.img' for ${CLR2}$linux_relese${CLR0} failed! \n" && exit 1
	wget --no-check-certificate -qO '/tmp/vmlinuz' "${LinuxMirror}/${DIST}/os/${VER}/isolinux/vmlinuz"
	[[ $? -ne '0' ]] && echo -ne "${CLR1}Error! ${CLR0}Download 'vmlinuz' for ${CLR2}$linux_relese${CLR0} failed! \n" && exit 1
else
	bash $0 error;
	exit 1;
fi
if [[ "$linux_relese" == 'debian' ]]; then
	if [[ "$IncFirmware" == '1' ]]; then
		wget --no-check-certificate -qO '/tmp/firmware.cpio.gz' "http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/${DIST}/current/firmware.cpio.gz"
		[[ $? -ne '0' ]] && echo -ne "${CLR1}Error! ${CLR0}Download 'firmware' for ${CLR2}$linux_relese${CLR0} failed! \n" && exit 1
	fi
	if [[ "$ddMode" == '1' ]]; then
		vKernel_udeb=$(wget --no-check-certificate -qO- "http://$DISTMirror/dists/$DIST/main/installer-$VER/current/images/udeb.list" |grep '^acpi-modules' |head -n1 |grep -o '[0-9]\{1,2\}.[0-9]\{1,2\}.[0-9]\{1,2\}-[0-9]\{1,2\}' |head -n1)
		[[ -z "vKernel_udeb" ]] && vKernel_udeb="4.19.0-17"
	fi
fi

if [[ "$loaderMode" == "0" ]]; then
	[[ ! -f "${GRUBDIR}/${GRUBFILE}" ]] && echo "Error! Not Found ${GRUBFILE}. " && exit 1;

	[[ ! -f "${GRUBDIR}/${GRUBFILE}.old" ]] && [[ -f "${GRUBDIR}/${GRUBFILE}.bak" ]] && mv -f "${GRUBDIR}/${GRUBFILE}.bak" "${GRUBDIR}/${GRUBFILE}.old";
	mv -f "${GRUBDIR}/${GRUBFILE}" "${GRUBDIR}/${GRUBFILE}.bak";
	[[ -f "${GRUBDIR}/${GRUBFILE}.old" ]] && cat "${GRUBDIR}/${GRUBFILE}.old" >"${GRUBDIR}/${GRUBFILE}" || cat "${GRUBDIR}/${GRUBFILE}.bak" >"${GRUBDIR}/${GRUBFILE}";
else
	GRUBVER='-1'
fi

[[ "$GRUBVER" == '0' ]] && {
	READGRUB='/tmp/grub.read'
	cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' |grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' |sed 's/%%%%%%%/\n/g' >$READGRUB
	LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
	if [[ "$LoadNum" -eq '1' ]]; then
		cat $READGRUB |sed '/^$/d' >/tmp/grub.new;
	elif [[ "$LoadNum" -gt '1' ]]; then
		CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
		CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
		CFG1="";
		for tmpCFG in `awk '/}/{print NR}' $READGRUB`; do
			[ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
		done
		[[ -z "$CFG1" ]] && {
			echo "Error! read $GRUBFILE. ";
			exit 1;
		}

		sed -n "$CFG0,$CFG1"p $READGRUB >/tmp/grub.new;
		[[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
			echo -ne "${CLR1}Error! ${CLR0}Not configure $GRUBFILE. \n";
			exit 1;
		}
	fi
	[ ! -f /tmp/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
	sed -i "/menuentry.*/c\menuentry\ \'Install OS \[$DIST\ $VER\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
	sed -i "/echo.*Loading/d" /tmp/grub.new;
	INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

[[ "$GRUBVER" == '1' ]] && {
	CFG0="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
	CFG1="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
	[[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
	[[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$[$CFG1-1]"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
	[[ ! -f /tmp/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
	sed -i "/title.*/c\title\ \'Install OS \[$DIST\ $VER\]\'" /tmp/grub.new;
	sed -i '/^#/d' /tmp/grub.new;
	INSERTGRUB="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

if [[ "$loaderMode" == "0" ]]; then
	[[ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

	LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)";
	[[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
	LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new |awk '{print $1}' |tail -n 1)";
	[ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new && LinuxIMG='initrd';

	[[ "$setInterfaceName" == "1" ]] && Add_OPTION="net.ifnames=0 biosdevname=0" || Add_OPTION=""
	[[ "$setIPv6" == "1" ]] && Add_OPTION="$Add_OPTION ipv6.disable=1"

	lowMem || Add_OPTION="$Add_OPTION lowmem=+2"

	if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
		BOOT_OPTION="auto=true $Add_OPTION hostname=$linux_relese domain=$linux_relese quiet"
	elif [[ "$linux_relese" == 'centos' ]]; then
		BOOT_OPTION="ks=file://ks.cfg $Add_OPTION ksdevice=$interfaceSelect"
	fi

	[ -n "$setConsole" ] && BOOT_OPTION="$BOOT_OPTION --- console=$setConsole"

	[[ "$Type" == 'InBoot' ]] && {
		sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
		sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.img" /tmp/grub.new;
	}

	[[ "$Type" == 'NoBoot' ]] && {
		sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" /tmp/grub.new;
		sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new;
	}

	sed -i '$a\\n' /tmp/grub.new;

	sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
	sed -i ''${INSERTGRUB}'r /tmp/grub.new' $GRUBDIR/$GRUBFILE;
	[[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;
fi

[[ -d /tmp/boot ]] && rm -rf /tmp/boot;
mkdir -p /tmp/boot;
cd /tmp/boot;

if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
	COMPTYPE="gzip";
elif [[ "$linux_relese" == 'centos' ]]; then
	COMPTYPE="$(file ../initrd.img |grep -o ':.*compressed data' |cut -d' ' -f2 |sed -r 's/(.*)/\L\1/' |head -n1)"
	[[ -z "$COMPTYPE" ]] && echo "Detect compressed type fail." && exit 1;
fi
CompDected='0'
for COMP in `echo -en 'gzip\nlzma\nxz'`; do
	if [[ "$COMPTYPE" == "$COMP" ]]; then
		CompDected='1'
		if [[ "$COMPTYPE" == 'gzip' ]]; then
			NewIMG="initrd.img.gz"
		else
			NewIMG="initrd.img.$COMPTYPE"
		fi
		mv -f "/tmp/initrd.img" "/tmp/$NewIMG"
		break;
	fi
done
[[ "$CompDected" != '1' ]] && echo "Detect compressed type not support." && exit 1;
[[ "$COMPTYPE" == 'lzma' ]] && UNCOMP='xz --format=lzma --decompress';
[[ "$COMPTYPE" == 'xz' ]] && UNCOMP='xz --decompress';
[[ "$COMPTYPE" == 'gzip' ]] && UNCOMP='gzip -d';

$UNCOMP < /tmp/$NewIMG | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1

if [[ "$linux_relese" == 'debian' ]] || [[ "$linux_relese" == 'ubuntu' ]]; then
	CurrentKernelVersion=`ls -1 ./lib/modules 2>/dev/null |head -n1`
	[ -n "$CurrentKernelVersion" ] && SelectLowmem="di-utils-exit-installer,driver-injection-disk-detect,fdisk-udeb,netcfg-static,parted-udeb,partman-auto,partman-ext3,ata-modules-${CurrentKernelVersion}-di,efi-modules-${CurrentKernelVersion}-di,sata-modules-${CurrentKernelVersion}-di,scsi-modules-${CurrentKernelVersion}-di,scsi-nic-modules-${CurrentKernelVersion}-di" || SelectLowmem=""
	echo "d-i debian-installer/locale string en_US.UTF-8" > /tmp/boot/preseed.cfg
	echo "d-i debian-installer/country string US" >> /tmp/boot/preseed.cfg
	echo "d-i debian-installer/language string en" >> /tmp/boot/preseed.cfg

	echo "d-i console-setup/layoutcode string us" >> /tmp/boot/preseed.cfg

	echo "d-i keyboard-configuration/xkb-keymap string us" >> /tmp/boot/preseed.cfg
	echo "d-i lowmem/low note" >> /tmp/boot/preseed.cfg
	echo "d-i anna/choose_modules_lowmem multiselect $SelectLowmem" >> /tmp/boot/preseed.cfg

	echo "d-i netcfg/choose_interface select $interfaceSelect" >> /tmp/boot/preseed.cfg

	echo "d-i netcfg/disable_autoconfig boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/dhcp_failed note" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/dhcp_options select Configure network manually" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/get_ipaddress string $IPv4" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/get_netmask string $MASK" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/get_gateway string $GATE" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/get_nameservers string $ipDNS" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/no_default_route boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i netcfg/confirm_static boolean true" >> /tmp/boot/preseed.cfg

	echo "d-i hw-detect/load_firmware boolean true" >> /tmp/boot/preseed.cfg

	echo "d-i mirror/country string manual" >> /tmp/boot/preseed.cfg
	echo "d-i mirror/http/hostname string $MirrorHost" >> /tmp/boot/preseed.cfg
	echo "d-i mirror/http/directory string $MirrorFolder" >> /tmp/boot/preseed.cfg
	echo "d-i mirror/http/proxy string" >> /tmp/boot/preseed.cfg

	echo "d-i passwd/root-login boolean ture" >> /tmp/boot/preseed.cfg
	echo "d-i passwd/make-user boolean false" >> /tmp/boot/preseed.cfg
	echo "d-i passwd/root-password-crypted password $myPASSWORD" >> /tmp/boot/preseed.cfg
	echo "d-i user-setup/allow-password-weak boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i user-setup/encrypt-home boolean false" >> /tmp/boot/preseed.cfg

	echo "d-i clock-setup/utc boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i time/zone string US/Eastern" >> /tmp/boot/preseed.cfg
	echo "d-i clock-setup/ntp boolean false" >> /tmp/boot/preseed.cfg

	echo "d-i preseed/early_command string anna-install libfuse2-udeb fuse-udeb ntfs-3g-udeb libcrypto1.1-udeb libpcre2-8-0-udeb libssl1.1-udeb libuuid1-udeb zlib1g-udeb wget-udeb" >> /tmp/boot/preseed.cfg
	echo "d-i partman/early_command string [[ -n \"\$(blkid -t TYPE='vfat' -o device)\" ]] && umount \"\$(blkid -t TYPE='vfat' -o device)\"; \\" >> /tmp/boot/preseed.cfg
	echo "debconf-set partman-auto/disk \"\$(list-devices disk |head -n1)\"; \\" >> /tmp/boot/preseed.cfg
	echo "wget -qO- '$DDURL' |gunzip -dc |/bin/dd of=\$(list-devices disk |head -n1); \\" >> /tmp/boot/preseed.cfg
	echo "mount.ntfs-3g \$(list-devices partition |head -n1) /mnt; \\" >> /tmp/boot/preseed.cfg
	echo "cd '/mnt/ProgramData/Microsoft/Windows/Start Menu/Programs'; \\" >> /tmp/boot/preseed.cfg
	echo "cd Start* || cd start*; \\" >> /tmp/boot/preseed.cfg
	echo "cp -f '/net.bat' './net.bat'; \\" >> /tmp/boot/preseed.cfg
	echo "/sbin/reboot; \\" >> /tmp/boot/preseed.cfg
	echo "umount /media || true; \\" >> /tmp/boot/preseed.cfg

	echo "d-i partman-partitioning/confirm_write_new_label boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i partman/mount_style select uuid" >> /tmp/boot/preseed.cfg
	echo "d-i partman/choose_partition select finish" >> /tmp/boot/preseed.cfg
	echo "d-i partman-auto/method string regular" >> /tmp/boot/preseed.cfg
	echo "d-i partman-auto/init_automatically_partition select Guided - use entire disk" >> /tmp/boot/preseed.cfg
	echo "d-i partman-auto/choose_recipe select All files in one partition (recommended for new users)" >> /tmp/boot/preseed.cfg
	echo "d-i partman-md/device_remove_md boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i partman-lvm/device_remove_lvm boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i partman-lvm/confirm boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i partman-lvm/confirm_nooverwrite boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i partman/confirm boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i partman/confirm_nooverwrite boolean true" >> /tmp/boot/preseed.cfg

	echo "d-i debian-installer/allow_unauthenticated boolean true" >> /tmp/boot/preseed.cfg

	echo "tasksel tasksel/first multiselect minimal" >> /tmp/boot/preseed.cfg
	echo "d-i pkgsel/update-policy select none" >> /tmp/boot/preseed.cfg
	echo "d-i pkgsel/include string openssh-server" >> /tmp/boot/preseed.cfg
	echo "d-i pkgsel/upgrade select none" >> /tmp/boot/preseed.cfg
	echo "d-i apt-setup/services-select multiselect" >> /tmp/boot/preseed.cfg

	echo "popularity-contest popularity-contest/participate boolean false" >> /tmp/boot/preseed.cfg

	echo "d-i grub-installer/only_debian boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i grub-installer/bootdev string $IncDisk" >> /tmp/boot/preseed.cfg
	echo "d-i grub-installer/force-efi-extra-removable boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i finish-install/reboot_in_progress note" >> /tmp/boot/preseed.cfg
	echo "d-i debian-installer/exit/reboot boolean true" >> /tmp/boot/preseed.cfg
	echo "d-i preseed/late_command string	\\" >> /tmp/boot/preseed.cfg
	echo "sed -ri 's/^#?Port.*/Port ${sshPORT}/g' /target/etc/ssh/sshd_config; \\" >> /tmp/boot/preseed.cfg
	echo "sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config; \\" >> /tmp/boot/preseed.cfg
	echo "sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config; \\" >> /tmp/boot/preseed.cfg
	echo "echo '@reboot root cat /etc/run.sh 2>/dev/null |base64 -d >/tmp/run.sh; rm -rf /etc/run.sh; sed -i /^@reboot/d /etc/crontab; bash /tmp/run.sh' >>/target/etc/crontab; \\" >> /tmp/boot/preseed.cfg
	echo "echo '' >>/target/etc/crontab; \\" >> /tmp/boot/preseed.cfg
	echo "echo '${setCMD}' >/target/etc/run.sh; \\" >> /tmp/boot/preseed.cfg
	echo "in-target apt update; \\" >> /tmp/boot/preseed.cfg
	echo "in-target apt install -y curl file gawk jq openssl sudo tar unzip wget xz-utils; \\" >> /tmp/boot/preseed.cfg
	echo "in-target curl -sS -o /usr/local/bin/k https://kejilion.pro/kejilion.sh; \\" >> /tmp/boot/preseed.cfg
	echo "in-target chmod +x /usr/local/bin/k" >> /tmp/boot/preseed.cfg

	if [[ "$loaderMode" != "0" ]] && [[ "$setNet" == '0' ]]; then
		sed -i '/netcfg\/disable_autoconfig/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/dhcp_options/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/get_.*/d' /tmp/boot/preseed.cfg
		sed -i '/netcfg\/confirm_static/d' /tmp/boot/preseed.cfg
	fi

	if [[ "$linux_relese" == 'debian' ]]; then
		sed -i '/user-setup\/allow-password-weak/d' /tmp/boot/preseed.cfg
		sed -i '/user-setup\/encrypt-home/d' /tmp/boot/preseed.cfg
		sed -i '/pkgsel\/update-policy/d' /tmp/boot/preseed.cfg
		sed -i 's/umount\ \/media.*true\;\ //g' /tmp/boot/preseed.cfg
		[[ -f '/tmp/firmware.cpio.gz' ]] && gzip -d < /tmp/firmware.cpio.gz | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
	else
		sed -i '/d-i\ grub-installer\/force-efi-extra-removable/d' /tmp/boot/preseed.cfg
	fi

	[[ "$ddMode" == '1' ]] && {
		WinNoDHCP(){
			echo -ne "for\0040\0057f\0040\0042tokens\00753\0052\0042\0040\0045\0045i\0040in\0040\0050\0047netsh\0040interface\0040show\0040interface\0040\0136\0174more\0040\00533\0040\0136\0174findstr\0040\0057I\0040\0057R\0040\0042本地\0056\0052\0040以太\0056\0052\0040Local\0056\0052\0040Ethernet\0042\0047\0051\0040do\0040\0050set\0040EthName\0075\0045\0045j\0051\r\nnetsh\0040\0055c\0040interface\0040ip\0040set\0040address\0040name\0075\0042\0045EthName\0045\0042\0040source\0075static\0040address\0075$IPv4\0040mask\0075$MASK\0040gateway\0075$GATE\r\nnetsh\0040\0055c\0040interface\0040ip\0040add\0040dnsservers\0040name\0075\0042\0045EthName\0045\0042\0040address\00758\00568\00568\00568\0040index\00751\0040validate\0075no\r\n\r\n" >>'/tmp/boot/net.tmp';
		}
		WinRDP(){
			echo -ne "netsh\0040firewall\0040set\0040portopening\0040protocol\0075ALL\0040port\0075$WinRemote\0040name\0075RDP\0040mode\0075ENABLE\0040scope\0075ALL\0040profile\0075ALL\r\nnetsh\0040firewall\0040set\0040portopening\0040protocol\0075ALL\0040port\0075$WinRemote\0040name\0075RDP\0040mode\0075ENABLE\0040scope\0075ALL\0040profile\0075CURRENT\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Network\0134NewNetworkWindowOff\0042\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0042\0040\0057v\0040fDenyTSConnections\0040\0057t\0040reg\0137dword\0040\0057d\00400\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0134Wds\0134rdpwd\0134Tds\0134tcp\0042\0040\0057v\0040PortNumber\0040\0057t\0040reg\0137dword\0040\0057d\0040$WinRemote\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0134WinStations\0134RDP\0055Tcp\0042\0040\0057v\0040PortNumber\0040\0057t\0040reg\0137dword\0040\0057d\0040$WinRemote\0040\0057f\r\nreg\0040add\0040\0042HKLM\0134SYSTEM\0134CurrentControlSet\0134Control\0134Terminal\0040Server\0134WinStations\0134RDP\0055Tcp\0042\0040\0057v\0040UserAuthentication\0040\0057t\0040reg\0137dword\0040\0057d\00400\0040\0057f\r\nFOR\0040\0057F\0040\0042tokens\00752\0040delims\0075\0072\0042\0040\0045\0045i\0040in\0040\0050\0047SC\0040QUERYEX\0040TermService\0040\0136\0174FINDSTR\0040\0057I\0040\0042PID\0042\0047\0051\0040do\0040TASKKILL\0040\0057F\0040\0057PID\0040\0045\0045i\r\nFOR\0040\0057F\0040\0042tokens\00752\0040delims\0075\0072\0042\0040\0045\0045i\0040in\0040\0050\0047SC\0040QUERYEX\0040UmRdpService\0040\0136\0174FINDSTR\0040\0057I\0040\0042PID\0042\0047\0051\0040do\0040TASKKILL\0040\0057F\0040\0057PID\0040\0045\0045i\r\nSC\0040START\0040TermService\r\n\r\n" >>'/tmp/boot/net.tmp';
		}
		echo -ne "\0100ECHO\0040OFF\r\n\r\ncd\0056\0076\0045WINDIR\0045\0134GetAdmin\r\nif\0040exist\0040\0045WINDIR\0045\0134GetAdmin\0040\0050del\0040\0057f\0040\0057q\0040\0042\0045WINDIR\0045\0134GetAdmin\0042\0051\0040else\0040\0050\r\necho\0040CreateObject\0136\0050\0042Shell\0056Application\0042\0136\0051\0056ShellExecute\0040\0042\0045\0176s0\0042\0054\0040\0042\0045\0052\0042\0054\0040\0042\0042\0054\0040\0042runas\0042\0054\00401\0040\0076\0076\0040\0042\0045temp\0045\0134Admin\0056vbs\0042\r\n\0042\0045temp\0045\0134Admin\0056vbs\0042\r\ndel\0040\0057f\0040\0057q\0040\0042\0045temp\0045\0134Admin\0056vbs\0042\r\nexit\0040\0057b\00402\0051\r\n\r\n" >'/tmp/boot/net.tmp';
		[[ "$setNet" == '1' ]] && WinNoDHCP;
		[[ "$setNet" == '0' ]] && [[ "$AutoNet" == '0' ]] && WinNoDHCP;
		[[ "$setRDP" == '1' ]] && [[ -n "$WinRemote" ]] && WinRDP
		echo -ne "ECHO\0040SELECT\0040VOLUME\0075\0045\0045SystemDrive\0045\0045\0040\0076\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\nECHO\0040EXTEND\0040\0076\0076\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\nSTART\0040/WAIT\0040DISKPART\0040\0057S\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\nDEL\0040\0057f\0040\0057q\0040\0042\0045SystemDrive\0045\0134diskpart\0056extend\0042\r\n\r\n" >>'/tmp/boot/net.tmp';
		echo -ne "cd\0040\0057d\0040\0042\0045ProgramData\0045\0057Microsoft\0057Windows\0057Start\0040Menu\0057Programs\0057Startup\0042\r\ndel\0040\0057f\0040\0057q\0040net\0056bat\r\n\r\n\r\n" >>'/tmp/boot/net.tmp';
		iconv -f 'UTF-8' -t 'GBK' '/tmp/boot/net.tmp' -o '/tmp/boot/net.bat'
		rm -rf '/tmp/boot/net.tmp'
	}

	[[ "$ddMode" == '0' ]] && {
		sed -i '/anna-install/d' /tmp/boot/preseed.cfg
		sed -i 's/wget.*\/sbin\/reboot\;\ //g' /tmp/boot/preseed.cfg
	}

elif [[ "$linux_relese" == 'centos' ]]; then
	echo "#platform=x86, AMD64, or Intel EM64T" > /tmp/boot/ks.cfg
	echo "firewall --enabled --ssh" >> /tmp/boot/ks.cfg
	echo "install" >> /tmp/boot/ks.cfg
	echo "url --url=\"$LinuxMirror/$DIST/os/$VER/\"" >> /tmp/boot/ks.cfg
	echo "rootpw --iscrypted $myPASSWORD" >> /tmp/boot/ks.cfg
	echo "auth --useshadow --passalgo=sha512" >> /tmp/boot/ks.cfg
	echo "firstboot --disable" >> /tmp/boot/ks.cfg
	echo "lang en_US" >> /tmp/boot/ks.cfg
	echo "keyboard us" >> /tmp/boot/ks.cfg
	echo "selinux --disabled" >> /tmp/boot/ks.cfg
	echo "logging --level=info" >> /tmp/boot/ks.cfg
	echo "reboot" >> /tmp/boot/ks.cfg
	echo "text" >> /tmp/boot/ks.cfg
	echo "unsupported_hardware" >> /tmp/boot/ks.cfg
	echo "vnc" >> /tmp/boot/ks.cfg
	echo "skipx" >> /tmp/boot/ks.cfg
	echo "timezone --isUtc Asia/Hong_Kong" >> /tmp/boot/ks.cfg
	echo "#ONDHCP network --bootproto=dhcp --onboot=on" >> /tmp/boot/ks.cfg
	echo "network --bootproto=static --ip=$IPv4 --netmask=$MASK --gateway=$GATE --nameserver=$ipDNS --onboot=on" >> /tmp/boot/ks.cfg
	echo "bootloader --location=mbr --append=\"rhgb quiet crashkernel=auto\"" >> /tmp/boot/ks.cfg
	echo "zerombr" >> /tmp/boot/ks.cfg
	echo "clearpart --all --initlabel" >> /tmp/boot/ks.cfg
	echo "autopart" >> /tmp/boot/ks.cfg

	echo "%packages" >> /tmp/boot/ks.cfg
	echo "@base" >> /tmp/boot/ks.cfg
	echo "%end" >> /tmp/boot/ks.cfg

	echo "%post --interpreter=/bin/bash" >> /tmp/boot/ks.cfg
	echo "rm -rf /root/anaconda-ks.cfg" >> /tmp/boot/ks.cfg
	echo "rm -rf /root/install.*log" >> /tmp/boot/ks.cfg

	echo "yum update -y" >> /tmp/boot/ks.cfg
	echo "yum install -y curl file gawk jq openssl sudo tar unzip wget xz" >> /tmp/boot/ks.cfg

	echo "curl -sS -o /usr/local/bin/k https://kejilion.pro/kejilion.sh" >> /tmp/boot/ks.cfg
	echo "chmod +x /usr/local/bin/k" >> /tmp/boot/ks.cfg

	echo "%end" >> /tmp/boot/ks.cfg

	[[ "$UNKNOWHW" == '1' ]] && sed -i 's/^unsupported_hardware/#unsupported_hardware/g' /tmp/boot/ks.cfg
	[[ "$(echo "$DIST" |grep -o '^[0-9]\{1\}')" == '5' ]] && sed -i '0,/^%end/s//#%end/' /tmp/boot/ks.cfg
fi

find . | cpio -H newc --create --verbose | gzip -9 > /tmp/initrd.img;

if [[ "$loaderMode" == "0" ]]; then
	cp -f /tmp/initrd.img /boot/initrd.img || sudo cp -f /tmp/initrd.img /boot/initrd.img
	cp -f /tmp/vmlinuz /boot/vmlinuz || sudo cp -f /tmp/vmlinuz /boot/vmlinuz

	chown root:root $GRUBDIR/$GRUBFILE
	chmod 444 $GRUBDIR/$GRUBFILE

	sleep 3 && reboot || sudo reboot >/dev/null 2>&1
else
	rm -rf "$HOME/loader"
	mkdir -p "$HOME/loader"
	cp -rf "/tmp/initrd.img" "$HOME/loader/initrd.img"
	cp -rf "/tmp/vmlinuz" "$HOME/loader/vmlinuz"
	rm -rf "/tmp/initrd.img"
	rm -rf "/tmp/vmlinuz"
	echo && ls -AR1 "$HOME/loader"
fi
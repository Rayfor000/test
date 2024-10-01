#!/bin/bash

# DD重裝腳本
# 支持Debian/Ubuntu/CentOS等主流Linux發行版
# 默認root密碼:password

# 顏色定義
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

# 全局變量
DIST=''
VER=''
IP=''
NETMASK=''
GATEWAY=''
DNS1='8.8.8.8'
DNS2='8.8.4.4'
MIRROR=''
DD_URL=''
NIC=''
BOOT_OPTION=''
LANG='en'  # 默認語言為英語
ROOT_PASSWORD='password'  # 默認root密碼

# 語言設置
declare -A MESSAGES
MESSAGES["help_en"]="Usage: $0 [-d|--debian] [-u|--ubuntu] [-c|--centos] [--ip-addr IP] [--ip-gate GATEWAY] [--ip-mask NETMASK] [-l|--lang LANG]
Options:
  -d, --debian        Install Debian
  -u, --ubuntu        Install Ubuntu
  -c, --centos        Install CentOS
  --ip-addr IP        Set IP address
  --ip-gate GATEWAY   Set gateway
  --ip-mask NETMASK   Set netmask
  -l, --lang LANG     Set language (en/zh)
  -h, --help          Show this help message"

MESSAGES["help_zh"]="使用方法: $0 [-d|--debian] [-u|--ubuntu] [-c|--centos] [--ip-addr IP] [--ip-gate GATEWAY] [--ip-mask NETMASK] [-l|--lang LANG]
選項:
  -d, --debian        安裝 Debian
  -u, --ubuntu        安裝 Ubuntu
  -c, --centos        安裝 CentOS
  --ip-addr IP        設置 IP 地址
  --ip-gate GATEWAY   設置網關
  --ip-mask NETMASK   設置子網掩碼
  -l, --lang LANG     設置語言 (en/zh)
  -h, --help          顯示此幫助信息"

# 顯示幫助信息
show_help() {
    echo -e "${MESSAGES["help_$LANG"]}"
}

# 解析命令行參數
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--debian)
            DIST="debian"
            shift
            ;;
        -u|--ubuntu)
            DIST="ubuntu"
            shift
            ;;
        -c|--centos)
            DIST="centos"
            shift
            ;;
        --ip-addr)
            IP="$2"
            shift 2
            ;;
        --ip-gate)
            GATEWAY="$2"
            shift 2
            ;;
        --ip-mask)
            NETMASK="$2"
            shift 2
            ;;
        -l|--lang)
            LANG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# 檢測root權限
[ "$(id -u)" -ne 0 ] && { echo -e "${CLR1}Please run this script as root user.${CLR0}"; exit 1; }

# 檢測系統架構
[[ $(uname -m) != x86_64 ]] && echo -e "${CLR1}錯誤:${CLR0} 不支持32位系統!" && exit 1

# 主要功能函數
get_system_info() {
    # 獲取當前系統信息
    DIST=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    VER=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
}

set_mirror() {
    case $DIST in
        debian)
            MIRROR="http://ftp.debian.org/debian"
            ;;
        ubuntu)
            MIRROR="http://archive.ubuntu.com/ubuntu"
            ;;
        centos)
            MIRROR="http://mirror.centos.org/centos"
            ;;
        *)
            echo -e "${CLR1}錯誤:${CLR0} 不支持的發行版!"
            exit 1
            ;;
    esac
}

set_network() {
    # 自動獲取網絡配置
    NIC=$(ip -o -4 route show to default | awk '{print $5}')
    IP=$(ip -4 addr show $NIC | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    NETMASK=$(ip -4 addr show $NIC | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | cut -d'/' -f2)
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    
    echo -e "${CLR3}當前網絡配置:${CLR0}"
    echo -e "網絡接口: $NIC"
    echo -e "IP: $IP"
    echo -e "子網掩碼: $NETMASK"
    echo -e "網關: $GATEWAY"
    echo -e "DNS1: $DNS1"
    echo -e "DNS2: $DNS2"
}

download_image() {
    echo -e "${CLR3}開始下載系統鏡像...${CLR0}"
    mkdir -p /tmp/root
    case $DIST in
        debian)
            VER=$(curl -s https://www.debian.org/releases/ | grep -oP 'The current stable distribution of Debian is version \K[0-9]+' | head -n1)
            wget -O /tmp/initrd.gz http://ftp.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz
            wget -O /tmp/vmlinuz http://ftp.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
            ;;
        ubuntu)
            VER=$(curl -s https://releases.ubuntu.com/ | grep -oP 'Ubuntu \K[0-9.]+(?= LTS)' | head -n1)
            wget -O /tmp/initrd.gz http://archive.ubuntu.com/ubuntu/dists/${VER}/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/initrd.gz
            wget -O /tmp/vmlinuz http://archive.ubuntu.com/ubuntu/dists/${VER}/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/linux
            ;;
        centos)
            VER=$(curl -s http://mirror.centos.org/centos/ | grep -oP '8\.[0-9]+\.[0-9]+' | sort -V | tail -n1)
            wget -O /tmp/initrd.img http://mirror.centos.org/centos/${VER}/BaseOS/x86_64/os/images/pxeboot/initrd.img
            wget -O /tmp/vmlinuz http://mirror.centos.org/centos/${VER}/BaseOS/x86_64/os/images/pxeboot/vmlinuz
            ;;
        *)
            echo -e "${CLR1}錯誤:${CLR0} 不支持的發行版!"
            exit 1
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo -e "${CLR1}錯誤:${CLR0} 下載系統鏡像失敗!"
        exit 1
    fi
}

make_image() {
    echo -e "${CLR3}開始製作���定義鏡像...${CLR0}"
    # 解壓並修改 initrd
    cd /tmp
    mkdir initrd
    cd initrd
    gzip -dc ../initrd.gz | cpio -id
    
    # 修改 preseed 或 kickstart 文件
    if [[ "$DIST" == 'debian' ]] || [[ "$DIST" == 'ubuntu' ]]; then
        cat > preseed.cfg <<EOF
# 基本設置
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string $DIST
d-i netcfg/get_domain string localdomain
d-i mirror/country string manual
d-i mirror/http/hostname string $MIRROR
d-i mirror/http/directory string /$DIST
d-i mirror/http/proxy string
d-i passwd/root-password password $ROOT_PASSWORD
d-i passwd/root-password-again password $ROOT_PASSWORD
d-i clock-setup/utc boolean true
d-i time/zone string UTC
d-i partman-auto/method string regular
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select full-upgrade
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i finish-install/reboot_in_progress note

# 安裝完成後執行的命令
d-i preseed/late_command string in-target apt-get update; in-target apt-get install -y curl jq sudo tar unzip wget
EOF
    elif [[ "$DIST" == 'centos' ]]; then
        cat > ks.cfg <<EOF
# 基本設置
install
url --url="$MIRROR/$VER/os/x86_64"
lang en_US.UTF-8
keyboard us
network --bootproto=dhcp --device=$NIC
rootpw $ROOT_PASSWORD
firewall --disabled
selinux --permissive
timezone UTC
bootloader --location=mbr
text
skipx
zerombr
clearpart --all --initlabel
autopart
auth --enableshadow --passalgo=sha512
firstboot --disabled
reboot

# 安裝包
%packages
@core
%end

# 安裝完成後執行的命令
%post
yum update -y
yum install -y curl jq sudo tar unzip wget
%end
EOF
    fi
    
    # 重新打包 initrd
    find . | cpio -H newc -o | gzip -9 > ../initrd.gz
    cd ..
    rm -rf initrd
}

install_os() {
    echo -e "${CLR3}開始安裝操作系統...${CLR0}"
    
    # 準備 GRUB 配置
    cat > /tmp/grub.cfg <<EOF
menuentry 'Install OS' {
    linux /vmlinuz $BOOT_OPTION
    initrd /initrd.gz
}
EOF

    # 複製文件到 /boot
    cp /tmp/vmlinuz /boot/vmlinuz
    cp /tmp/initrd.gz /boot/initrd.gz
    cp /tmp/grub.cfg /boot/grub/grub.cfg

    # 安裝 GRUB
    if [ -d /sys/firmware/efi ]; then
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=$DIST
    else
        grub-install /dev/sda
    fi

    echo -e "${CLR2}操作系統安裝準備完成。請重啟系統以開始安裝過程。${CLR0}"
    echo -e "${CLR3}安裝完成後，基本工具（curl、jq、sudo、tar、unzip、wget）將自動安裝。${CLR0}"
    echo -e "${CLR3}請記得修改默認root密碼！${CLR0}"
}

# 主程序
main() {
    get_system_info
    set_mirror  
    set_network
    download_image
    make_image
    install_os
}

main
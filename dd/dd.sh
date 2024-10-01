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

# 檢測root權限
[[ $EUID -ne 0 ]] && echo -e "${CLR1}錯誤:${CLR0} 必須使用root用戶運行此腳本!" && exit 1

# 檢測系統架構
[[ $(uname -m) != x86_64 ]] && echo -e "${CLR1}錯誤:${CLR0} 不支持32位系統!" && exit 1

# 主要功能函數
get_system_info() {
  # 獲取當前系統信息
  DIST=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  VER=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
}

set_mirror() {
  # 設置安裝源鏡像
  case $DIST in
    debian)
      MIRROR="http://deb.debian.org/debian"
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
  IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
  NETMASK=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | cut -d'/' -f2 | head -n 1)
  GATEWAY=$(ip route | grep default | awk '{print $3}')
  
  echo -e "${YELLOW}當前網絡配置:${PLAIN}"
  echo -e "IP: $IP"
  echo -e "子網掩碼: $NETMASK"
  echo -e "網關: $GATEWAY"
  echo -e "DNS1: $DNS1"
  echo -e "DNS2: $DNS2"
}

download_image() {
  # 下載系統鏡像
  echo -e "${CLR3}開始下載系統鏡像...${CLR0}"
  ADD wget
  case $DIST in
    debian)
      wget -O /tmp/initrd.img $MIRROR/dists/$VER/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz
      wget -O /tmp/vmlinuz $MIRROR/dists/$VER/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux
      ;;
    ubuntu)
      wget -O /tmp/initrd.img $MIRROR/dists/$VER/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/initrd.gz
      wget -O /tmp/vmlinuz $MIRROR/dists/$VER/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/linux
      ;;
    centos)
      wget -O /tmp/initrd.img $MIRROR/$VER/os/x86_64/isolinux/initrd.img
      wget -O /tmp/vmlinuz $MIRROR/$VER/os/x86_64/isolinux/vmlinuz
      ;;
  esac
}

make_image() {
  # 製作自定義鏡像
  echo -e "${YELLOW}開始製作自定義鏡像...${PLAIN}"
  # 這裡可以添加自定義鏡像的製作過程
}

install_os() {
  # 安裝操作系統
  echo -e "${GREEN}開始安裝操作系統...${PLAIN}"
  # 這裡可以添加具體的安裝步驟
  
  # 安裝基本工具
  ADD curl jq sudo tar unzip
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

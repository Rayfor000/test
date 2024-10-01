#!/bin/bash

# DD重裝腳本
# 支持Debian/Ubuntu/CentOS等主流Linux發行版
# 默認root密碼:password

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

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
[[ $EUID -ne 0 ]] && echo -e "${RED}錯誤:${PLAIN} 必須使用root用戶運行此腳本!" && exit 1

# 檢測系統架構
[[ $(uname -m) != x86_64 ]] && echo -e "${RED}錯誤:${PLAIN} 不支持32位系統!" && exit 1

# 主要功能函數
get_system_info() {
  # 獲取當前系統信息
  DIST=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  VER=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
}

set_mirror() {
  # 設置安裝源鏡像
  case $DIST in
    debian|ubuntu)
      MIRROR="http://deb.debian.org/debian"
      ;;
    centos)
      MIRROR="http://mirror.centos.org/centos"
      ;;
    *)
      echo -e "${RED}錯誤:${PLAIN} 不支持的發行版!"
      exit 1
      ;;
  esac
}

set_network() {
  # 配置網絡
  IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
  NETMASK=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | cut -d'/' -f2 | head -n 1)
  GATEWAY=$(ip route | grep default | awk '{print $3}')
  
  echo -e "${YELLOW}當前網絡配置:${PLAIN}"
  echo -e "IP: $IP"
  echo -e "子網掩碼: $NETMASK"
  echo -e "網關: $GATEWAY"
  echo -e "DNS1: $DNS1"
  echo -e "DNS2: $DNS2"
  
  read -p "是否需要修改網絡配置? [y/N]: " answer
  case $answer in
    [Yy]* )
      read -p "輸入IP地址: " IP
      read -p "輸入子網掩碼: " NETMASK
      read -p "輸入網關: " GATEWAY
      read -p "輸入DNS1: " DNS1
      read -p "輸入DNS2: " DNS2
      ;;
    * )
      echo "保持當前網絡配置"
      ;;
  esac
}

download_image() {
  # 下載系統鏡像
  echo -e "${YELLOW}開始下載系統鏡像...${PLAIN}"
  case $DIST in
    debian|ubuntu)
      wget -O /tmp/initrd.img $MIRROR/dists/$VER/main/installer-amd64/current/images/netboot/$DIST-installer/amd64/initrd.gz
      wget -O /tmp/vmlinuz $MIRROR/dists/$VER/main/installer-amd64/current/images/netboot/$DIST-installer/amd64/linux
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

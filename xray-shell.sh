#!/bin/bash

if [ ! -f "./xray-shell.sh~" ]; then
  gzexe $0
  rm "$0~"
  touch "$0~"
fi

curl -sSL https://raw.ogtt.tk/shell/function.sh -o function.sh
source function.sh

CHECK_ROOT

CD() ( CLEAN; )
IN() { INPUT "請輸入：" "sel"; }
R() { FONT RED "$1"; }
G() { FONT GREEN "$1"; }
Y() { FONT YELLOW "$1"; }
C() { FONT CYAN "$1"; }
CR() { FONT CRAY "$1"; }
LI() { C $(LINE "24"); }
OC() { G "FINISHED"; read -n 1 -s -r -p "按任意鍵繼續..."; CD; }

ADD sudo curl jq tar unzip &>/dev/null

Display_TEXTS() {
  for text in "${TEXTS[@]}"; do
    case "$text" in
      "LI")
        LI
        ;;
      *)
        C "$text"
        ;;
    esac
  done
}

Display_OPTIONS() {
  local count=1
  local max_cols=1
  local col_options=()

  print_row() {
    for option in "$@"; do
      printf "$(C "%3d.") %-16s" "$count" "$option"
      ((count++))
    done
    echo
  }

  for option in "${OPTIONS[@]}"; do
    case "$option" in
      "LI")
        LI
        col_options=()
        ;;
      "-"*)
        max_cols=${option//[-]/}
        [ ${#col_options[@]} -gt 0 ] && print_row "${col_options[@]}"
        col_options=()
        ;;
      *)
        col_options+=("$option")
        [ ${#col_options[@]} -eq $max_cols ] && { print_row "${col_options[@]}"; col_options=(); }
        ;;
    esac
  done
  [ ${#col_options[@]} -gt 0 ] && print_row "${col_options[@]}"
}

Run_ACTIONS() {
  local count=1
  for action in "${ACTIONS[@]}"; do
    case $sel in
      $count)
        CD
        IFS=';' read -ra steps <<< "$action"
        for step in "${steps[@]}"; do
          eval "$step"
        done
        OC
        ;;
    esac
    ((count++))
  done
  
  if [ $count -gt ${#ACTIONS[@]} ]; then
    case $sel in
      0) Menu_OPTIONS; Menu ;;
      *) CD ;;
    esac
  fi
}

Menu_OPTIONS() {
  OPTIONS=(
    系統資訊
    更新軟體包
    清理系統
    安裝工具
    LI
    腳本設定
  )
}

Install_Tools() {
  TEXTS=(
    "$(Y "安裝工具")"
    LI
    這裡您可以安裝各種常用的系統工具和軟體
    包括網絡工具、系統監控、文本編輯器等
  )
  OPTIONS=(
    -3-
    curl wget sudo
    socat htop iftop
    -2-
    unzip tar
    tmux ffmpeg
    LI
    btop ncdu
    ranger fzf
    vim nano
    -1-
    git
    LI
    安裝以上所有工具
    移除以上所有工具
    LI
    安裝指定工具
    移除指定工具
  )
  Install_Tool() {
    INPUT 請輸入欲安裝工具： Tools && ADD $Tools
  }
  Remove_Tool() {
    INPUT 請輸入欲移除工具： Tools && DEL $Tools
  }
  ACTIONS=(
    "ADD curl; CD; curl --help"
    "ADD wget; CD; wget --help"
    "ADD sudo; CD; sudo --help"
    "ADD socat; CD; socat -help"
    "ADD htop; CD; htop"
    "ADD iftop; CD; iftop"
    "ADD unzip; CD; unzip"
    "ADD tar; CD; tar --help"
    "ADD tmux; CD; tmux --help"
    "ADD ffmpeg; CD; ffmpeg --help"
    "ADD btop; CD; btop"
    "ADD ncdu; cd /; CD; ncdu"
    "ADD ranger; cd /; CD; ranger"
    "ADD fzf; cd /; CD; fzf"
    "ADD vim; cd /; CD; vim -h"
    "ADD nano; cd /; CD; nano -h"
    "ADD git; cd /; CD; git --help"
    "ADD curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ncdu ranger fzf vim nano git"
    "DEL curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ncdu ranger fzf vim nano git"
    "Install_Tool"
    "Remove_Tool"
  )
}

Sub_Menu() {
  while true; do
    CD
    Display_TEXTS
    LI
    Display_OPTIONS
    LI
    G "  0. 返回"
    LI
    IN
    Run_ACTIONS
  done
}

Menu() {
  while true; do
    CD
    Y " _    _                         ______ _           _ _"
    Y "\ \  / /                       / _____| |         | | |"
    Y " \ \/ /  ____ _____ _   _ ____( (____ | |__  _____| | |"
    Y "  )  (  / ___(____ | | | (_____\____ \|  _ \| ___ | | |"
    Y " / /\ \| |   / ___ | |_| |     _____) | | | | ____| | |"
    Y "/_/  \_|_|   \_____|\__  |    (______/|_| |_|_____)\_\_)"
    Y "                    (____/"
    LI
    Display_OPTIONS
    LI
    G "  0. 退出"
    LI
    IN
    case $sel in
      1) CD; SYS_INFO; OC; Menu;;
      2) CD; SYS_UPDATE; OC; Menu;;
      3) CD; SYS_CLEAN; OC; Menu;;
      4) Install_Tools; Sub_Menu;;
      0) CD; exit;;
      *) CD;;
    esac
  done
}
Menu_OPTIONS
Menu

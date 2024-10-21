# Memory management
sysctl -w vm.swappiness=1                # 最小化交换空间使用
sysctl -w vm.overcommit_memory=2         # 严格分配内存，防止过度分配
sysctl -w vm.overcommit_ratio=100        # 允许使用100%的物理内存
sysctl -w vm.dirty_ratio=60               # 增加脏页的最大比例，允许更多脏页在内存中
sysctl -w vm.dirty_background_ratio=30     # 增加脏页背景写入比例
sysctl -w vm.dirty_expire_centisecs=100   # 缩短脏页保持时间，快速写入
sysctl -w vm.dirty_writeback_centisecs=2000 # 快速写回脏页
sysctl -w vm.vfs_cache_pressure=10        # 增加缓存压力，保持更多文件系统缓存
sysctl -w vm.min_free_kbytes=131072      # 提高最小可用内存，防止内存不足
sysctl -w vm.zone_reclaim_mode=0         # 关闭区域回收模式

# Network settings
sysctl -w net.core.somaxconn=65535       # 提高最大连接数
sysctl -w net.core.rmem_max=16777216     # 增加最大接收缓冲区
sysctl -w net.core.wmem_max=16777216     # 增加最大发送缓冲区
sysctl -w net.core.optmem_max=25165824   # 增加网络优化内存最大值
sysctl -w net.core.netdev_max_backlog=500000 # 提高最大排队长度
sysctl -w net.ipv4.tcp_rmem="4096 16777216 16777216" # 增加TCP接收缓冲区
sysctl -w net.ipv4.tcp_wmem="4096 16777216 16777216" # 增加TCP发送缓冲区
sysctl -w net.ipv4.tcp_tw_reuse=1        # 允许重用TIME_WAIT socket
sysctl -w net.ipv4.tcp_tw_recycle=1      # 启用TIME_WAIT socket回收
sysctl -w net.ipv4.tcp_timestamps=1      # 启用TCP时间戳
sysctl -w net.ipv4.tcp_fastopen=3        # 启用TCP快速开放
sysctl -w net.ipv4.tcp_sack=1            # 启用选择性确认
sysctl -w net.ipv4.tcp_fack=1            # 启用快速确认
sysctl -w net.ipv4.tcp_syncookies=1      # 启用SYN cookies
sysctl -w net.ipv4.tcp_max_syn_backlog=32768 # 增加最大SYN队列长度
sysctl -w net.ipv4.tcp_synack_retries=2  # 减少SYN-ACK重试次数
sysctl -w net.ipv4.tcp_fin_timeout=5     # 缩短FIN超时时间
sysctl -w net.ipv4.tcp_max_tw_buckets=500000 # 增加最大TIME_WAIT桶数
sysctl -w net.ipv4.tcp_low_latency=1     # 优化TCP低延迟传输
sysctl -w net.ipv4.tcp_syn_retries=1     # 减少SYN重试次数
sysctl -w net.ipv4.tcp_congestion_control=bbr # 使用BBR算法
sysctl -w net.ipv4.ip_local_port_range="1024 65535" # 增加可用本地端口范围

# Security settings
sysctl -w net.ipv4.conf.all.rp_filter=1  # 启用反向路径过滤
sysctl -w net.ipv4.conf.default.rp_filter=1 # 对所有接口启用反向路径过滤
sysctl -w net.ipv4.conf.all.accept_redirects=0 # 禁用ICMP重定向
sysctl -w net.ipv4.conf.default.accept_redirects=0 # 禁用ICMP重定向
sysctl -w net.ipv4.conf.all.accept_source_route=0 # 禁用源路由
sysctl -w net.ipv4.conf.default.accept_source_route=0 # 禁用源路由

# Kernel settings
sysctl -w kernel.pid_max=65536           # 提高最大进程数
sysctl -w kernel.sched_autogroup_enabled=0 # 关闭调度自动分组
sysctl -w kernel.numa_balancing=0        # 关闭NUMA平衡
sysctl -w kernel.sched_migration_cost_ns=1000000 # 减少调度迁移开销

# File system settings
sysctl -w fs.file-max=2097152            # 提高最大文件句柄数量
sysctl -w fs.suid_dumpable=0              # 禁止SUID程序的core dump

# Set maximum number of open file descriptors
ulimit -n 1048576                         # 提高最大打开文件描述符数量

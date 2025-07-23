#!/bin/bash

# VPS 极简自动维护 v1.4.3-safe - 支持空目录和容器兼容

# Modify by GitHub@DuolaD
# Copyright (C) 2025 DuolaD

set -e

# 定义颜色
green='\033[0;32m'
yellow='\033[1;33m'
cyan='\033[1;36m'
plain='\033[0m'

echo -e "${cyan}================ VPS-Lite v1.4.3-safe 极简自动维护 =================${plain}"

# 自动卸载 unzip（忽略未安装的情况）
echo -e "${yellow}[临时依赖清理] 正在卸载 unzip ...${plain}"
apt purge -y unzip >/dev/null 2>&1 || true
apt autoremove -y >/dev/null 2>&1 || true
apt clean || true

# 安装 bc（用于计算）
echo -e "${yellow}[依赖检测] 安装必要组件...${plain}"
apt install -y bc >/dev/null 2>&1 || true

# 定义目标目录（仅添加存在的）
all_targets=(/usr/share/doc /usr/share/man /usr/share/info /usr/share/lintian /usr/share/locale /lib/modules)
targets=()
for dir in "${all_targets[@]}"; do
    [ -d "$dir" ] && targets+=("$dir")
done

# 计算清理前空间
cleared_size_kb=0
if [ ${#targets[@]} -gt 0 ]; then
    cleared_size_kb=$(du -sk "${targets[@]}" 2>/dev/null | awk '{sum+=$1} END {print sum}')
fi

# 防止空值
cleared_size_kb=${cleared_size_kb:-0}
cleared_mb=$(echo "scale=2; $cleared_size_kb/1024" | bc)

echo ""
echo -e "${yellow}[本轮预清理空间]${plain} 预计可释放: ${green}${cleared_mb} MB${plain}"

# 执行清理
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/log/*
journalctl --vacuum-time=1d >/dev/null 2>&1 || true

for dir in "${targets[@]}"; do
    rm -rf "$dir"
done

# 显示磁盘状态
echo ""
echo -e "${yellow}[磁盘使用]${plain}"
df -h /

# 写入日志
logfile="/var/log/vps-lite-daily-clean.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') 本轮清理释放: ${cleared_mb} MB" >> "$logfile"

# 自动每日定时任务
echo ""
echo -e "${yellow}[定时任务]${plain} 写入每日自动清理任务..."

cat <<'EOF' > /usr/local/bin/vps-lite-daily-clean.sh
#!/bin/bash
set -e
all_targets=(/usr/share/doc /usr/share/man /usr/share/info /usr/share/lintian /usr/share/locale /lib/modules)
targets=()
for dir in "${all_targets[@]}"; do
    [ -d "$dir" ] && targets+=("$dir")
done
cleared_size_kb=0
if [ ${#targets[@]} -gt 0 ]; then
    cleared_size_kb=$(du -sk "${targets[@]}" 2>/dev/null | awk '{sum+=$1} END {print sum}')
fi
cleared_size_kb=${cleared_size_kb:-0}
cleared_mb=$(echo "scale=2; $cleared_size_kb/1024" | bc)
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/log/*
journalctl --vacuum-time=1d >/dev/null 2>&1 || true
for dir in "${targets[@]}"; do
    rm -rf "$dir"
done
echo "$(date '+%Y-%m-%d %H:%M:%S') 本轮清理释放: ${cleared_mb} MB" >> /var/log/vps-lite-daily-clean.log
EOF

chmod +x /usr/local/bin/vps-lite-daily-clean.sh

# 加入定时任务（去重）
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/vps-lite-daily-clean.sh >/dev/null 2>&1") | sort -u | crontab -

echo ""
echo -e "${green}✅ 自动定时任务配置完成 (每天凌晨3点自动清理)${plain}"
echo -e "${yellow}[日志位置]${plain} /var/log/vps-lite-daily-clean.log"
echo -e "${cyan}================ 部署完成 =================${plain}"

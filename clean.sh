#!/bin/bash

# VPS 极简自动维护 v1.4.2-unzip - 精确释放统计版 - 自动清理 unzip

set -e

# 定义颜色
green='\033[0;32m'
yellow='\033[1;33m'
cyan='\033[1;36m'
plain='\033[0m'

echo -e "${cyan}================ VPS-Lite v1.4.2-unzip 极简自动维护 =================${plain}"

# 先自动卸载 XrayR 安装完后的 unzip 临时依赖
echo -e "${yellow}[临时依赖清理] 正在卸载 unzip ...${plain}"
apt purge -y unzip || true
apt autoremove -y || true
apt clean || true

# 依赖检测（不做系统源更新，纯极简）
echo -e "${yellow}[依赖检测] 安装必要组件...${plain}"
apt install bc -y || true

# 定义要清理的目标目录
targets="/usr/share/doc /usr/share/man /usr/share/info /usr/share/lintian /usr/share/locale /lib/modules"

# 精确统计清理前可释放空间
cleared_size=$(du -sk $targets 2>/dev/null | awk '{sum+=$1} END {print sum}')
cleared_mb=$(echo "scale=2; $cleared_size/1024" | bc)

echo ""
echo -e "${yellow}[本轮预清理空间]${plain} 预计可释放: ${green}${cleared_mb} MB${plain}"

# 开始清理
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/log/*
journalctl --vacuum-time=1d || true
rm -rf $targets

# 清理完毕后显示磁盘状态
echo ""
echo -e "${yellow}[磁盘使用]${plain}"
df -h /

# 写入日志
echo "$(date '+%Y-%m-%d %H:%M:%S') 本轮清理释放: ${cleared_mb} MB" >> /var/log/vps-lite-daily-clean.log

# 自动配置每日定时任务
echo ""
echo -e "${yellow}[定时任务]${plain} 写入每日自动清理任务..."

# 生成每日执行文件
cat <<EOF > /usr/local/bin/vps-lite-daily-clean.sh
#!/bin/bash
targets="/usr/share/doc /usr/share/man /usr/share/info /usr/share/lintian /usr/share/locale /lib/modules"
cleared_size=\$(du -sk \$targets 2>/dev/null | awk '{sum+=\$1} END {print sum}')
cleared_mb=\$(echo "scale=2; \$cleared_size/1024" | bc)
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/log/*
journalctl --vacuum-time=1d || true
rm -rf \$targets
echo "\$(date '+%Y-%m-%d %H:%M:%S') 本轮清理释放: \${cleared_mb} MB" >> /var/log/vps-lite-daily-clean.log
EOF

chmod +x /usr/local/bin/vps-lite-daily-clean.sh

(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/vps-lite-daily-clean.sh >/dev/null 2>&1") | sort -u | crontab -

echo ""
echo -e "${green}✅ 自动定时任务配置完成 (每天凌晨3点自动清理)${plain}"
echo -e "${yellow}[日志位置]${plain} /var/log/vps-lite-daily-clean.log"
echo -e "${cyan}================ 部署完成 =================${plain}"

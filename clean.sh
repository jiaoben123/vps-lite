#!/bin/bash

# VPS 极简自动维护总控脚本 (不安装XrayR，仅做瘦身 + 自动定时维护)
# v1.3 美化版

set -e

# 定义颜色
green='\033[0;32m'
yellow='\033[1;33m'
cyan='\033[1;36m'
red='\033[0;31m'
plain='\033[0m'

echo -e "${cyan}================ VPS-Lite 极简自动维护 =================${plain}"

# 自动补齐依赖
echo -e "${yellow}[依赖检测]${plain} 安装必要组件..."
apt update -y && apt install wget curl bc -y

echo -e "${yellow}[初始化]${plain} 执行首次系统瘦身..."

# 磁盘使用前
before=$(df / | awk 'NR==2 {print $3}')

# 瘦身清理动作
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/log/*
journalctl --vacuum-time=1d || true
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/lintian/* /usr/share/locale/*
rm -rf /lib/modules/*

# 磁盘使用后
after=$(df / | awk 'NR==2 {print $3}')
saved=$(($before - $after))
saved_mb=$(echo "scale=2; $saved/1024" | bc)

echo ""
echo -e "${green}✅ 瘦身完成：共释放 ${saved_mb} MB 空间${plain}"
echo -e "${yellow}[磁盘使用]${plain}"
df -h /

# 记录日志
echo "$(date '+%Y-%m-%d %H:%M:%S') 清理完成, 释放 ${saved_mb} MB" >> /var/log/vps-lite-daily-clean.log

# 定时任务部分
echo ""
echo -e "${yellow}[定时任务]${plain} 写入每日自动清理任务..."

cat <<EOF > /usr/local/bin/vps-lite-daily-clean.sh
#!/bin/bash
before=\$(df / | awk 'NR==2 {print \$3}')
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/log/*
journalctl --vacuum-time=1d || true
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/lintian/* /usr/share/locale/* /lib/modules/*
after=\$(df / | awk 'NR==2 {print \$3}')
saved=\$((\$before - \$after))
saved_mb=\$(echo "scale=2; \$saved/1024" | bc)
echo "\$(date '+%Y-%m-%d %H:%M:%S') 清理完成, 释放 \${saved_mb} MB" >> /var/log/vps-lite-daily-clean.log
EOF

chmod +x /usr/local/bin/vps-lite-daily-clean.sh

(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/vps-lite-daily-clean.sh >/dev/null 2>&1") | sort -u | crontab -

echo ""
echo -e "${green}✅ 每日定时任务设置完成 (每日凌晨3点自动清理)${plain}"
echo -e "${yellow}[日志位置]${plain} /var/log/vps-lite-daily-clean.log"
echo -e "${cyan}================ 部署完成 =================${plain}"

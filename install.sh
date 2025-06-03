#!/bin/bash

# VPS 极简自动维护总控脚本 (不安装XrayR，仅做瘦身 + 自动定时维护)
# by ChatGPT专属定制版 v1.2

set -e

# ✅ 自动补齐必要依赖
apt update -y && apt install wget curl bc -y

# 1. 先执行一次完整瘦身
echo "🚀 正在执行第一次系统瘦身..."

# 记录清理前磁盘使用
before=$(df / | awk 'NR==2 {print $3}')

# 清理APT缓存
apt clean
rm -rf /var/lib/apt/lists/*

# 清理日志文件
rm -rf /var/log/*
journalctl --vacuum-time=1d || true

# 清理无用文档与语言包
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*
rm -rf /usr/share/info/*
rm -rf /usr/share/lintian/*
rm -rf /usr/share/locale/*

# 再次清理可能残留的内核模块（LXC安全）
rm -rf /lib/modules/*

# 记录清理后磁盘使用
after=$(df / | awk 'NR==2 {print $3}')

# 计算节省空间（单位：KB）
saved=$(($before - $after))
saved_mb=$(echo "scale=2; $saved/1024" | bc)

echo ""
echo "✅ 首次瘦身完成，共释放空间: ${saved_mb} MB"
echo "📊 当前磁盘使用情况："
df -h /

# 记录日志供后续追溯
echo "$(date '+%Y-%m-%d %H:%M:%S') 清理完成, 释放 ${saved_mb} MB" >> /var/log/vps-lite-daily-clean.log

# 2. 创建每日定时任务
echo ""
echo "🛠 正在配置每日自动定时任务..."

# 写入每日执行脚本
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

# 赋予执行权限
chmod +x /usr/local/bin/vps-lite-daily-clean.sh

# 写入 crontab
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/vps-lite-daily-clean.sh >/dev/null 2>&1") | sort -u | crontab -

echo ""
echo "✅ 自动定时任务配置完成，每天凌晨3点将自动清理瘦身。"
echo "📄 可随时查看日志：cat /var/log/vps-lite-daily-clean.log"

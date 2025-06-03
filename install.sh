#!/bin/bash

# VPS每日自动瘦身脚本（含前后空间对比）
# 适配LXC极简 XrayR小盘 VPS

set -e

echo "🚀 开始每日自动极简清理..."

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
echo "✅ 瘦身完成，今日共释放空间: ${saved_mb} MB"
echo "📊 当前磁盘使用情况："
df -h /

# 记录日志供后续追溯
echo "$(date '+%Y-%m-%d %H:%M:%S') 清理完成, 释放 ${saved_mb} MB" >> /var/log/vps-lite-daily-clean.log

#!/bin/bash

# XrayR 极简纯净版安装脚本

set -e

# 1. 更新系统 & 安装必要组件
apt update -y && apt install wget curl tar unzip -y

# 2. 创建安装目录
mkdir -p /usr/local/XrayR
cd /usr/local/XrayR

# 3. 检测架构
arch=$(uname -m)
if [[ $arch == "x86_64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" ]]; then
    arch="arm64-v8a"
else
    arch="64"
fi

# 4. 下载最新版 XrayR
latest=$(curl -s https://api.github.com/repos/XrayR-project/XrayR/releases/latest | grep tag_name | cut -d '"' -f 4)
wget -O XrayR-linux.zip https://github.com/XrayR-project/XrayR/releases/download/${latest}/XrayR-linux-${arch}.zip

unzip XrayR-linux.zip && rm XrayR-linux.zip
chmod +x XrayR

# 5. 配置 systemd
mkdir -p /etc/XrayR
wget -O /etc/systemd/system/XrayR.service https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/XrayR.service
systemctl daemon-reload
systemctl enable XrayR

# 6. 下载管理脚本
curl -o /usr/bin/XrayR -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/XrayR.sh
chmod +x /usr/bin/XrayR
ln -s /usr/bin/XrayR /usr/bin/xrayr

# 7. 清理系统文件
apt clean
rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/lintian/* /usr/share/locale/* /var/log/* /lib/modules/*

# 8. 设置纯英文环境避免locale错误
echo "export LANG=C" >> /etc/profile
source /etc/profile

echo ""
echo "✅ XrayR极简版安装完成"
echo "👉 请前往 /etc/XrayR/config.yml 配置你的节点参数"
echo "👉 启动命令：systemctl start XrayR"

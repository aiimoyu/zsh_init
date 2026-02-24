#!/bin/bash

# Ghostty 安装脚本
# 支持 Linux (Ubuntu) 和 macOS

set -e

echo "🚀 开始安装 Ghostty..."

# 检测操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	echo "📦 检测到 Linux 系统，使用 Ubuntu 安装脚本..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	echo "📦 检测到 macOS 系统，使用 Homebrew 安装..."
	brew install --cask ghostty
else
	echo "❌ 不支持的操作系统：$OSTYPE"
	exit 1
fi

echo "✅ Ghostty 安装完成"

# 配置 Ghostty
echo "⚙️  配置 Ghostty..."

CONFIG_DIR="$HOME/.config/ghostty"
CONFIG_FILE="$CONFIG_DIR/config"

# 创建配置目录
mkdir -p "$CONFIG_DIR"

# 追加配置到 config 文件
cat >>"$CONFIG_FILE" <<'EOF'

# Theme
theme = Gruvbox Material

# Font settings
# font-family = JetBrains Mono
adjust-cell-height = 0%
font-feature = calt,cv01,cv03,ss01,ss02,ss03
font-thicken = true

# Cursor settings
cursor-style = block
cursor-style-blink = true

# Window settings
background-opacity = 0.95
scrollback-limit = 200000000
mouse-hide-while-typing = true

# Shell integration
shell-integration = zsh
shell-integration-features = no-cursor,title
EOF

echo "✅ 配置已追加到 $CONFIG_FILE"
echo "🎉 Ghostty 安装和配置全部完成！"

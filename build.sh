#!/bin/bash
# Dozer M 系列原生版一键构建 —— clone 仓库后，在仓库根目录执行：bash build.sh
set -euo pipefail
cd "$(dirname "$0")"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "错误：请在 macOS 上运行（当前是 $(uname -s)）。"
  exit 1
fi
if [ ! -f project.yml ] || [ ! -f Makefile ]; then
  echo "错误：请在仓库根目录运行本脚本（需要 project.yml 和 Makefile）。"
  exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
  echo "错误：未检测到 Xcode。请先从 App Store 安装，再执行："
  echo "  sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "错误：未检测到 Homebrew，请先安装：https://brew.sh"
  exit 1
fi

os_major=$(sw_vers -productVersion | cut -d. -f1)
branch=$(git branch --show-current 2>/dev/null || true)
xcode_major=$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}' | cut -d. -f1 || true)

echo "系统：macOS $os_major | 分支：${branch:-未知}"
if [ "$os_major" -ge 27 ] && [ "$branch" = "main" ]; then
  echo "警告：macOS 27+ 的新菜单栏会让隐藏功能失效，建议先切分支：git checkout macos27"
fi
if [ "$os_major" -lt 27 ] && [ "$branch" = "macos27" ]; then
  echo "提示：当前系统不需要 macOS 27 补丁，可用 git checkout main 使用通用版。"
fi
if [ -n "$xcode_major" ] && [ "$xcode_major" -lt 26 ]; then
  echo "警告：检测到 Xcode $xcode_major，工程按 Xcode 26 配置，建议升级后再构建。"
fi

echo "--- 1/3 安装构建工具（首次需联网）---"
brew bundle --no-upgrade
echo "--- 2/3 生成工程并编译 Release ---"
make app
echo "--- 3/3 验证二进制架构 ---"
make verify

built_app="$(pwd)/build/Build/Products/Release/Dozer.app"
echo ""
echo "构建完成：$built_app"
echo "安装到应用程序："
echo "  cp -R \"$built_app\" /Applications/ && open -a Dozer"
echo ""
echo "首次打开若被拦截：系统设置 → 隐私与安全性 → 仍要打开；"
echo "macos27 分支还需在 系统设置 → 隐私与安全性 → 辅助功能 中勾选 Dozer，且必须装在 /Applications。"

#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

carthage bootstrap --no-build
# 当前 SwiftLint 会对这个固定版本依赖的示例代码报风格错误。
# 将这些诊断降级为警告，不修改依赖源码。
sed -i '' 's/    swiftlint\\n/    swiftlint --lenient\\n/g' \
    Carthage/Checkouts/Preferences/Preferences.xcodeproj/project.pbxproj
XCODE_XCCONFIG_FILE="$PWD/Configs/Dependencies.xcconfig" \
    carthage build Defaults Preferences LaunchAtLogin MASShortcut \
    --platform macOS --no-use-binaries --cache-builds

# Sparkle 1.27.3 同时提供 arm64 与 x86_64，并保留 SUUpdater API。
# 其已签名的辅助工具直接取自上游发布包，而非本地
# Carthage 归档（后者无法用 Developer ID 签名）。
mkdir -p .build Carthage/Build/Mac
curl --fail --location --silent --show-error \
    https://github.com/sparkle-project/Sparkle/releases/download/1.27.3/Sparkle-1.27.3.tar.xz \
    --output .build/Sparkle-1.27.3.tar.xz
printf '%s\n' 'b4c70198aba86a65dc04550fbd0a97243a9ba3b98d73d138c877347f27920952  .build/Sparkle-1.27.3.tar.xz' | shasum -a 256 --check
tar -xJf .build/Sparkle-1.27.3.tar.xz -C Carthage/Build/Mac Sparkle.framework Sparkle.framework.dSYM

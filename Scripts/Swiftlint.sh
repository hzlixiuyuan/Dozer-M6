export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if command -v swiftlint >/dev/null; then
  swiftlint --lenient
else
  echo "警告：未安装 SwiftLint，请从 https://github.com/realm/SwiftLint 下载"
fi

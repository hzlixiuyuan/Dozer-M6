if which swiftlint >/dev/null; then
  swiftlint
else
  echo "警告：未安装 SwiftLint，请从 https://github.com/realm/SwiftLint 下载"
fi

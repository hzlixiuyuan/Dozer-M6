# Apple Silicon 的 Homebrew 位于 /opt/homebrew/bin，Intel 版位于 /usr/local/bin。
export PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)

build:
	@brew bundle --no-upgrade
	@$(MAKE) prepare
	@xed "."

prepare:
	@sh Scripts/Bootstrap.sh
	@mkdir -p Dozer/Other/Generated
	@swiftgen
	@xcodegen

# 从命令行构建 Release 版 .app，使用 ad-hoc 临时签名。
app: prepare
	@xcodebuild -project Dozer.xcodeproj -scheme Dozer -configuration Release \
		-derivedDataPath build CODE_SIGN_IDENTITY=- ENABLE_HARDENED_RUNTIME=NO \
		ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build

# 确认二进制为原生 arm64（而非需要 Rosetta 转译的 Intel 版本）。
verify:
	@lipo -info build/Build/Products/Release/Dozer.app/Contents/MacOS/Dozer
	@echo "预期包含 arm64 x86_64 —— 即可在 M 系列 Mac 上原生运行"

test:
	@xcodegen
	@xcodebuild -project Dozer.xcodeproj -scheme Dozer -configuration Debug \
		-derivedDataPath build CODE_SIGN_IDENTITY=- test

release:
	@echo "正在执行 Fastlane 发布"
	@bundle exec fastlane release

.PHONY: build prepare app verify test release

# Apple Silicon Homebrew lives in /opt/homebrew/bin, Intel Homebrew in /usr/local/bin.
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

# Build a release .app from the command line with an ad-hoc signature.
app: prepare
	@xcodebuild -project Dozer.xcodeproj -scheme Dozer -configuration Release \
		-derivedDataPath build CODE_SIGN_IDENTITY=- ENABLE_HARDENED_RUNTIME=NO \
		ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build

# Confirm the binary is native arm64 (not an Intel binary needing Rosetta).
verify:
	@lipo -info build/Build/Products/Release/Dozer.app/Contents/MacOS/Dozer
	@echo "Expected: arm64 x86_64 -> runs natively on M-series Macs"

test:
	@xcodegen
	@xcodebuild -project Dozer.xcodeproj -scheme Dozer -configuration Debug \
		-derivedDataPath build CODE_SIGN_IDENTITY=- test

release:
	@echo "Running Fastlane deploy"
	@bundle exec fastlane release

.PHONY: build prepare app verify test release

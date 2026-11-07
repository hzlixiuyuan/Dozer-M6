<p align="center">
	<img width="200" height="200" margin-right="100%" src="https://raw.githubusercontent.com/Mortennn/Dozer/master/Stuff/AppIcon.png">
</p>
<p align="center">Hide menu bar icons to give your Mac a cleaner look.</p>
<p align="center">
	<a href="https://github.com/Mortennn/Dozer/releases/latest">
 		<img src="https://img.shields.io/badge/download-latest-brightgreen.svg" alt="download">
	<a href="https://img.shields.io/badge/platform-macOS-lightgrey.svg">
 		<img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="platform">
	</a>
	<a href="https://img.shields.io/badge/requirements-macOS Big Sur+-ff69b4.svg">
 		<img src="https://img.shields.io/badge/requirements-macOS Big Sur+-lightgrey.svg" alt="systemrequirements">
	</a>
	<a href="https://github.com/sindresorhus/swiftlint-sindre">
 		<img src="https://img.shields.io/badge/SwiftLint-Sindre-hotpink.svg" alt="swiftlint">
	</a>
	<a href="https://opensource.org/licenses/MPL-2.0">
 		<img src="https://img.shields.io/badge/License-MPL%202.0-orange.svg" alt="license">
	</a>
</p>
<p align="center">
	<img height="100" min-width="100" src="https://github.com/Mortennn/Dozer/raw/master/Stuff/demo.gif" alt="demo">
</p>

<p align="center"></p>
<a href="https://www.buymeacoffee.com/mortennn" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

## ⚙️ Build from source (Apple Silicon / universal)

> The original Homebrew cask `dozer` was disabled in Dec 2024 and removed in Dec 2025,
> and the published DMG (v4.0.0, 2019) is an **Intel-only x86_64** binary that only runs
> under Rosetta 2. This fork builds a native **arm64 + x86_64 universal** app instead,
> so it runs natively on every M-series Mac (M1 ... M6) without Rosetta.

Requirements: macOS 11+ (Big Sur), Xcode 26, Homebrew.

Quick start after cloning — run in the repository root:

```shell
bash build.sh   # installs tools, builds Dozer.app, verifies arm64 + x86_64
```

Branches: `main` (this branch) targets macOS 11–26; `macos27` adds the macOS 27
menu-bar compatibility fix — switch with `git checkout macos27`.

Or build manually:

```shell
make app      # builds Dozer.app into build/Build/Products/Release/ (ad-hoc signed)
make verify   # prints architectures; must show "arm64 x86_64"
open build/Build/Products/Release/Dozer.app
```

`make build` generates `Dozer.xcodeproj` and opens it in Xcode instead.
`make prepare` only installs the tooling (SwiftGen, XcodeGen, SwiftLint) and generates the project.

For distribution outside your own Mac, re-sign with a Developer ID certificate and notarize;
`make app` uses an ad-hoc signature intended for local use.

## ⚫️ Dozer Icons

There are 2 or 3, numbered from right to left:

1. this can be positioned anywhere you prefer, it is only a point of interaction
2. this and everything to its left will be hidden/shown by clicking any Dozer icon
3. (Optional) the "remove" icon and everything to its left will be hidden/shown by option-clicking any Dozer icon

## 👨‍💻 Usage

* Move the icons you want to hide until clicked to the left of the second Dozer icon
* Move the icons you want to hide until option-clicked to the left of the third Dozer icon

**N.B. hold command (`⌘`) then drag to move the menu bar icons.**

## 👇 Interactions
* Left-click one of the Dozer icons to hide/show the first group of menu bar icons
* Option-Left-click one of the Dozer icons to show the second group of menu bar icons (optional)
* Right-click one of the Dozer icons to open the settings

<!-- GIF is commented out until it is redone -->
<!-- **Checkout [this GIF](https://raw.githubusercontent.com/Mortennn/Dozer/master/Stuff/demo.gif) to watch Dozer in action.** -->

## 📄 Requirements
macOS 11+ (Big Sur), Apple Silicon (arm64) or Intel (x86_64) — universal binary.

Note: the menu-bar hiding technique used here relies on legacy status-item behaviour.
On macOS 27 and newer, use the `Dozer-M6-macOS27` variant instead, which reads icon
positions through Accessibility.

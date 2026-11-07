<div align="center">
  <img src="https://raw.githubusercontent.com/Mortennn/Dozer/master/Stuff/AppIcon.png" width="200" height="200" alt="Dozer 图标">
  <p><strong>隐藏 macOS 菜单栏图标，让屏幕更清爽。</strong></p>
  <p>Apple Silicon 原生版 · arm64 + x86_64 通用二进制 · 无需 Rosetta 2</p>
  <img src="https://github.com/Mortennn/Dozer/raw/master/Stuff/demo.gif" height="100" alt="使用演示">
</div>

## 这是什么

本项目基于上游 [Mortennn/Dozer](https://github.com/Mortennn/Dozer) 改造，目标是让 Dozer 在 M 系列 Mac 上**原生运行**。

> 原版正式发布包 v4.0.0（2019 年）是纯 Intel `x86_64` 二进制，在 Apple Silicon 上只能靠 Rosetta 2 转译；Homebrew 的 `dozer` cask 已于 2024 年 12 月禁用、2025 年 12 月下架。本仓库改为从源码构建 `arm64 + x86_64` 通用二进制，M1 到 M6 全部原生运行，不再依赖 Rosetta。

## 系统要求

- macOS 11（Big Sur）或更高，**推荐 macOS 11 ~ 26**
- Xcode 26、Homebrew
- Apple Silicon（arm64）或 Intel（x86_64）均可

> 本工程使用的隐藏方式依赖旧版状态栏图标机制。macOS 27 及更高版本请改用 [`macos27` 分支](#分支怎么选)。

## 📦 直接下载（不用装 Xcode）

到 [Releases](https://github.com/hzlixiuyuan/Dozer-M6/releases) 下载最新的
`Dozer-universal.zip`（或 `.dmg`），解压后把 `Dozer.app` 拖进「应用程序」即可。

> 安装包由 GitHub Actions 在 macOS arm64 云端编译，含 `arm64 + x86_64` 通用二进制。
> 使用 **ad-hoc 签名、未做 Developer ID 签名与公证**，首次打开若提示「无法验证开发者」，
> 请右键 App →「打开」，或在终端执行
> `xattr -d com.apple.quarantine /Applications/Dozer.app`。
> `SHA256SUMS.txt` 可校验下载完整性；`macos27` 对应的版本标记为预发布。

想自己改代码或重新构建，再看下面的源码构建。

## 快速开始

```bash
git clone https://github.com/hzlixiuyuan/Dozer-M6.git
cd Dozer-M6
bash build.sh
```

脚本会自动检查 macOS / Xcode / Homebrew → 安装 SwiftGen、XcodeGen、SwiftLint → 编译 Release → 用 `lipo -info` 验证架构。看到 `arm64 x86_64` 就说明是原生二进制。

产物位于 `build/Build/Products/Release/Dozer.app`：

```bash
cp -R build/Build/Products/Release/Dozer.app /Applications/
open -a Dozer
```

首次打开若被系统拦截：系统设置 → 隐私与安全性 → 「仍要打开」。

## 分支怎么选

| 分支 | 适用系统 | 说明 |
|---|---|---|
| `main`（默认） | macOS 11 ~ 26 | 通用版，日常使用选这个 |
| `macos27` | macOS 27 及以上 | 修复新版菜单栏导致隐藏失效的问题；需要辅助功能权限，且必须安装到 `/Applications` |

切换分支：`git checkout macos27`

## 手动构建

```bash
make prepare   # 仅安装工具并生成 Xcode 工程
make build     # 生成 Dozer.xcodeproj 并在 Xcode 中打开
make app       # 命令行编译 Release 版（ad-hoc 临时签名）
make verify    # 验证二进制架构
```

`make app` 使用 ad-hoc 临时签名，**仅供本机使用**。若要分发给他人，需要 Developer ID 签名与公证，并重新配置 `appcast.xml` 自动更新的签名密钥。

## Dozer 的三个图标

从右往左数，共 2 或 3 个：

1. 第一个：可放在任意位置，仅作为点击交互点
2. 第二个：点击 Dozer 图标时，它及其左侧所有图标一起隐藏 / 显示
3. 第三个（可选）：「移除」图标，按住 Option 点击时可控制它及其左侧图标

## 使用方法

- 把想「点击后隐藏」的图标拖到第二个 Dozer 图标左边
- 把想「Option 点击后隐藏」的图标拖到第三个 Dozer 图标左边
- **按住 ⌘ 拖动**才能移动菜单栏图标
- 左键点击 Dozer 图标：隐藏 / 显示第一组图标
- Option + 左键：显示第二组图标（可选）
- 右键点击：打开设置

> 设置窗口、菜单项和构建脚本提示均已汉化。

## 文档说明

- `README.en.md`：本页的英文原文备份
- `CHANGELOG.md`、`CONTRIBUTING.md`、`THIRD_PARTY_NOTICES.md`：沿用上游英文原文。它们分别是版本历史、贡献指南与第三方许可声明，翻译可能引入歧义，故保留原样
- 代码中的标识符、`UserDefaults` 键与日志文本保持英文——修改这些会导致已保存的设置丢失或逻辑异常

## 许可

MPL 2.0，与上游一致。原作者 Mortennn。

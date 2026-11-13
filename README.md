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

- macOS 11（Big Sur）或更高，**同一个安装包自动适配 macOS 11 ~ 27+**
- Xcode 26、Homebrew（仅在源码构建时需要）
- Apple Silicon（arm64）或 Intel（x86_64）均可

> **v2 起不再需要按系统版本挑分支**：程序运行时自动选择隐藏机制。macOS 26 及更早用传统的「撑宽分隔项」；macOS 27 及更新改用系统自带的菜单栏可见性限制。原生方式需要「辅助功能」权限，且建议把 App 放在 `/Applications`。

## 📦 直接下载（不用装 Xcode）

到 [Releases](https://github.com/hzlixiuyuan/Dozer-M6/releases) 下载最新的
`Dozer-universal.zip`（或 `.dmg`），解压后把 `Dozer.app` 拖进「应用程序」即可。

> 安装包由 GitHub Actions 在 macOS arm64 云端编译，含 `arm64 + x86_64` 通用二进制。
> 使用 **ad-hoc 签名、未做 Developer ID 签名与公证**，首次打开若提示「无法验证开发者」，
> 请右键 App →「打开」，或在终端执行
> `xattr -d com.apple.quarantine /Applications/Dozer.app`。
> `SHA256SUMS.txt` 可校验下载完整性。带 `macos27` 字样的旧版本是历史预发布包，**请下载最新的 `build-*-main` 稳定版**，它已包含全部适配。

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

## 隐藏机制（v2 起）

上游 Dozer 从 2019 年起只用一招：把一个分隔圆点撑到 10,000pt，把它左侧的图标挤出菜单栏。macOS 27 重构了菜单栏，会把过宽的状态项**直接移出布局**（参考 [Hidden Bar issue #360](https://github.com/dwarvesf/hidden)），于是点击后什么也不会发生。

本版本参考 Hidden Bar 的做法做了这些补齐：

| 改进 | 说明 |
|---|---|
| 运行时双引擎 | macOS 27+ 且系统服务可用时自动改用 `MenuBarClientCore` 可见性限制；旧系统继续用长度挤压。同一个包通吃，不用选分支 |
| 折叠长度按屏幕计算 | 改为「最宽屏幕 × 2、上限 10,000pt」，多显示器时不会在宽屏上漏出图标；屏幕参数变化后自动重算 |
| 辅助功能权限处理 | 原生方式未授权时明确提示，失败自动恢复全部图标（不会把图标藏丢） |
| 系统自带项也能隐藏 | 新增「系统图标」设置面板，可勾选电池、时钟、Wi-Fi、控制中心，随折叠一起收起（仅 macOS 27+ 原生方式） |
| 退出时恢复 | 释放系统可见性限制，避免退出后图标仍不显示 |
| 诊断面板 | **Shift + 右键** Dozer 圆点，查看系统版本、当前机制、权限、可隐藏图标数，并可临时切换机制排障 |

> `macos27` 分支保留为历史快照，功能已合并进 `main`。日常请直接使用 `main` / 最新的 `build-*-main` Release。

## 隐藏系统自带的菜单栏图标

电池、时钟、Wi-Fi、控制中心这些图标由系统进程自己绘制：它们不属于任何应用、没有 bundle identifier，辅助功能接口也读不到它们的位置，所以既不能像其他图标那样「拖到圆点左边」，也无法用撑宽分隔项把它们挤出屏幕。

v4.2.1 起，设置窗口多了一个「系统图标」面板：

1. 右键点击 Dozer 圆点 →「偏好设置」，切到「系统图标」
2. 勾选想让 Dozer 一并收起的系统项（电池 / 时钟 / Wi-Fi / 控制中心）
3. 回到菜单栏点击圆点：这些系统项和其他图标一起收起，再点一次恢复

实现上是把这几个系统项从菜单栏可见性允许表里去掉（`MBAssessmentModeConfiguration` 的 `allowedSystemItems`）。编号来自实测：在 macOS 27.0 上逐个尝试 0~127，只有 0 电池、2 时钟、6 Wi-Fi、8 控制中心会画出图标，其余编号给不给出都不影响画面，因此同一份清单可以跨机型使用。允许表的项数上限保持与旧实现一致的 64 个（超出时系统会拒绝整份配置，反而连普通图标都隐藏不了）。

需要注意：

- 只有 macOS 27 及更新系统 + 原生方式才能隐藏系统项；更早的系统上「系统图标」面板会置灰说明
- 隐藏范围限于实测出的四项，其他系统项（如第三方输入法指示、屏幕镜像）仍由系统自己决定显示与否
- 与普通图标一样，这些项只在折叠时收起，展开时一定回来，不会出现「到处找不到时钟」

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

## 点击后图标没有隐藏？

**先确认排列**：Dozer 只隐藏位于「左侧圆点左边」的图标。如果所有应用图标都在圆点右边，点击后自然看不到任何变化。**按住 ⌘ 拖动**，把想隐藏的图标拖到圆点左边，再点击试试。这是最常见的原因。

如果排列没问题，按 **Shift + 右键** 任一 Dozer 圆点打开诊断面板，里面会直接写出原因：

| 诊断显示 | 处理方式 |
|---|---|
| 「位于左侧圆点左边 0 个」 | 按 ⌘ 把图标拖到圆点左边 |
| macOS 27+ / 当前为传统方式 | 点「试用原生方式」切换 |
| 「辅助功能权限：未授权」 | 系统设置 → 隐私与安全性 → 辅助功能 → 允许 Dozer，然后**彻底退出并重新打开** App |
| 「原生可见性服务：不可用」 | 当前系统不提供该私有服务，改用「传统方式」；若仍无效说明该系统已不再支持这类隐藏 |
| 其他错误 | 诊断内容同时写入系统日志，可复制后反馈 |

诊断面板的「试用传统方式 / 试用原生方式 / 恢复自动选择」是**临时覆盖**，重启 App 后回到自动选择，可放心试。

> 原生方式依赖系统私有框架 `MenuBarClientCore`，系统大版本更新可能导致其失效；任何失败都会自动恢复所有图标，不会把图标藏丢。

## 文档说明

- `README.en.md`：本页的英文原文备份
- `CHANGELOG.md`、`CONTRIBUTING.md`：沿用上游英文原文（版本历史与贡献指南），翻译可能引入歧义，故保留原样
- `THIRD_PARTY_NOTICES.md`：第三方许可声明，含本项目参考的 [Hidden Bar](https://github.com/dwarvesf/hidden)（MIT）代码声明，法律文本保留英文原文
- 代码中的标识符、`UserDefaults` 键与日志文本保持英文——修改这些会导致已保存的设置丢失或逻辑异常

## 许可

MPL 2.0，与上游一致。原作者 Mortennn。

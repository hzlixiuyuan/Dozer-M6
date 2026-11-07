<div align="center">
  <img src="https://raw.githubusercontent.com/Mortennn/Dozer/master/Stuff/AppIcon.png" width="200" height="200" alt="Dozer 图标">
  <p><strong>隐藏 macOS 菜单栏图标，让屏幕更清爽。</strong></p>
  <p>Apple Silicon 原生版 · arm64 + x86_64 通用二进制 · macOS 27 兼容分支</p>
  <img src="https://github.com/Mortennn/Dozer/raw/master/Stuff/demo.gif" height="100" alt="使用演示">
</div>

## 这是什么

本项目基于上游 [Mortennn/Dozer](https://github.com/Mortennn/Dozer) 改造，目标是让 Dozer 在 M 系列 Mac 上**原生运行**，并修复 macOS 27 新菜单栏带来的兼容问题。

> 原版正式发布包 v4.0.0（2019 年）是纯 Intel `x86_64` 二进制，在 Apple Silicon 上只能靠 Rosetta 2 转译；Homebrew 的 `dozer` cask 已于 2024 年 12 月禁用、2025 年 12 月下架。本仓库改为从源码构建 `arm64 + x86_64` 通用二进制，M1 到 M6 全部原生运行。

## 系统要求

- macOS 27 及以上（工程编译目标仍为 macOS 10.13，兼容路径在 27+ 才启用）
- Xcode 26、Homebrew
- Apple Silicon（arm64）或 Intel（x86_64）均可
- **必须安装到 `/Applications`**，并授予辅助功能权限

## 📦 直接下载（不用装 Xcode）

到 [Releases](https://github.com/hzlixiuyuan/Dozer-M6/releases) 找到标记为
**Pre-release（预发布）**、tag 名含 `macos27` 的版本，下载 `Dozer-universal.zip`
（或 `.dmg`），解压后把 `Dozer.app` 拖进 `/Applications`。

> 两个分支的产物文件名相同，请按 Release 的 tag 区分：`build-1-main` 是通用稳定版，
> tag 含 `macos27` 的才是本分支的 macOS 27 兼容版。
> 安装包由 GitHub Actions 云端编译，含 `arm64 + x86_64`；使用 **ad-hoc 签名、未公证**，
> 首次打开若被拦截，右键 App →「打开」或执行
> `xattr -d com.apple.quarantine /Applications/Dozer.app`。
> 首次隐藏图标时还需在「系统设置 → 隐私与安全性 → 辅助功能」中勾选 Dozer。

想自己改代码或重新构建，再看下面的源码构建。

## 快速开始

```bash
git clone https://github.com/hzlixiuyuan/Dozer-M6.git
cd Dozer-M6
git checkout macos27
bash build.sh
```

脚本会自动检查 macOS / Xcode / Homebrew → 安装依赖 → 编译 Release → 用 `lipo -info` 验证架构。看到 `arm64 x86_64` 就说明是原生二进制。

```bash
cp -R build/Build/Products/Release/Dozer.app /Applications/
open -a Dozer
```

首次隐藏时，请在 **系统设置 → 隐私与安全性 → 辅助功能** 中勾选 Dozer，然后再点一次图标。图标排列方式见下方「使用方法」。

## 分支怎么选

| 分支 | 适用系统 | 说明 |
|---|---|---|
| `main`（默认） | macOS 11 ~ 26 | 通用版，日常使用选这个 |
| `macos27`（本分支） | macOS 27 及以上 | 修复新版菜单栏导致隐藏失效的问题 |

切回通用版：`git checkout main`

## 手动构建

```bash
make app       # 命令行编译 Release 版（ad-hoc 临时签名）
make verify    # 验证二进制架构
make test      # 运行分类、取消、权限错误与恢复的单元测试
```

`make app` 使用 ad-hoc 临时签名，**仅供本机使用**。要分发给他人需要 Developer ID 签名与公证；重新构建后可能要再次授予辅助功能权限。

## macOS 27 兼容说明

Apple 在 macOS 27 中重做了菜单栏：它会直接丢弃 Dozer 用来占位的超宽分隔项，而不是把它左侧的图标一起隐藏，因此原版的隐藏逻辑失效。本分支在 macOS 27 上改用系统的菜单栏可见性服务来控制图标，在更早的系统上仍保留原有机制。

已知限制：

- 可见性按**应用**控制。若某个应用的图标分布在分隔线两侧，以最可见的一侧为准，且该应用的图标会保持在一起
- 系统核心控件（控制中心、Wi-Fi、时钟等）始终保持可见，无法隐藏
- 该方案使用私有框架 `MenuBarClientCore`，参考了 [Hidden Bar 的 macOS 27 实现](https://github.com/dwarvesf/hidden/releases/tag/v1.11.1)。系统更新可能导致其失效；若服务不可用或请求失败，Dozer 会恢复所有图标并给出提示
- 必须放在 `/Applications`，系统需要能解析 Dozer 的 bundle identifier 才能保持切换按钮可见
- 布局在**所有分区都可见时**读取。若启用了可选的「移除」分区，调整图标后请先 Option 点击展开全部，再重新收起；在收起状态下启动的应用，可能要等下一次展开才会出现
- 相关许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

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

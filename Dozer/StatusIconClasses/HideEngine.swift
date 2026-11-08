/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// 隐藏机制选择，思路参考 Hidden Bar 的 MenuBarEngineFactory。
//
// macOS 27 重构了菜单栏：一个被撑得过宽的 NSStatusItem 会被系统直接移出
// 布局，因此「把分隔圆点撑宽、把左侧图标挤出屏幕」这套 2019 年的做法会
// 静默失效（Hidden Bar issue #360）。27+ 改用系统自带的菜单栏可见性限制
// （MenuBarClientCore，运行时 dlopen），旧系统继续用长度挤压。
//
// 所有判断都在运行时完成，不依赖编译时 SDK 版本，所以同一个通用二进制
// 可以覆盖 macOS 11 ~ 27+，用户不需要再按系统版本挑选分支。

import Cocoa

enum HideEngine: String {
    /// 传统方式：撑宽分隔项，把左侧图标挤出可见区域（macOS 26 及更早）
    case legacy
    /// 原生方式：通过系统可见性限制按应用隐藏（macOS 27 及更新）
    case native

    /// 诊断面板可临时覆盖自动选择，用于排障；nil = 自动。
    /// 不用 `override` 作名字，避免与 Swift 声明修饰符产生歧义。
    static var manualEngine: HideEngine?

    static var macOSMajor: Int {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }

    /// 私有框架是否真的可用。用 dlopen 运行时探测，旧系统会直接返回 false。
    static var nativeServiceAvailable: Bool {
        DozerNativeVisibilityIsAvailable()
    }

    static var current: HideEngine {
        if let manualEngine = manualEngine { return manualEngine }
        return macOSMajor >= 27 && nativeServiceAvailable ? .native : .legacy
    }

    /// Hidden Bar 的 LegacyLengthEngine 结论：菜单栏会复制到每一块外接屏幕，
    /// 折叠长度必须覆盖「最宽」的那块，不能只看 NSScreen.main；同时 macOS 对
    /// NSStatusItem.length 有 10,000pt 硬上限。原版 Dozer 硬编码 10,000，
    /// 在多显示器或新版菜单栏上容易被系统丢弃。
    static var collapsedLength: CGFloat {
        let widest = NSScreen.screens.map { $0.frame.width }.max() ?? 1728
        return max(500, min(widest * 2, 10_000))
    }

    static var displayName: String {
        switch current {
        case .legacy: return "传统方式（撑宽分隔项）"
        case .native: return "原生方式（系统可见性限制）"
        }
    }
}

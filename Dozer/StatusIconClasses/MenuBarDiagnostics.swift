/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// 「点了没反应」最常见的原因其实不是兼容性，而是：
//   1) 没有把要隐藏的图标拖到 Dozer 左侧圆点的左边；
//   2) macOS 27+ 上老的长度挤压已经失效；
//   3) 原生方式需要辅助功能权限但未授权。
// 这三类问题以前都是静默失败。这里把状态一次性摊开，并允许临时切换机制。

import Cocoa
import ApplicationServices

final class MenuBarDiagnostics {

    /// 统计菜单栏上的状态项窗口，以及位于分隔圆点左侧的数量。
    /// 只作为排障参考：AX 拿不到的系统项可能不计入。
    private static func statusWindows(leftOf separatorX: CGFloat?) -> (total: Int, left: Int) {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
                as? [[String: Any]] else { return (0, 0) }
        var total = 0
        var left = 0
        for info in list {
            guard let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue,
                  layer == 25,
                  let owner = info[kCGWindowOwnerName as String] as? String,
                  owner != "Dozer",
                  let bounds = info[kCGWindowBounds as String] as? [String: Any],
                  let x = (bounds["X"] as? NSNumber)?.doubleValue,
                  let height = (bounds["Height"] as? NSNumber)?.doubleValue,
                  height > 0, height <= 40 else { continue }
            total += 1
            if let separatorX = separatorX, x < separatorX { left += 1 }
        }
        return (total, left)
    }

    private static var architecture: String {
        #if arch(arm64)
        return "arm64（Apple Silicon 原生）"
        #else
        return "x86_64"
        #endif
    }

    static func report(separatorX: CGFloat?, lastError: String?) -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let windows = statusWindows(leftOf: separatorX)
        // macOS 27 起 CGWindowList 不再逐个暴露状态项窗口，计数不能当作判据。
        let windowCountReliable = HideEngine.macOSMajor < 27
        let widest = NSScreen.screens.map { $0.frame.width }.max() ?? 0
        let native = HideEngine.nativeServiceAvailable
        let accessibility = AXIsProcessTrusted()
        let mode = HideEngine.manualEngine == nil ? "自动选择" : "手动指定"
        let hiddenSystemItems = DozerIcons.shared.hiddenSystemItems
        let systemItemsText = hiddenSystemItems.isEmpty
            ? "全部保持可见（可在「系统图标」设置里勾选）"
            : "折叠时隐藏 " + SystemMenuItem.titles(of: hiddenSystemItems).joined(separator: "、")

        var lines = [
            "系统：macOS \(osString)（主版本 \(HideEngine.macOSMajor)）· \(architecture)",
            "当前隐藏机制：\(HideEngine.displayName)（\(mode)）",
            "原生可见性服务：\(native ? "可用" : "不可用")",
            "辅助功能权限：\(accessibility ? "已授权" : "未授权")",
            "系统自带项：\(systemItemsText)",
            "最近一次原生参数：\(NativeMenuBarVisibility.lastSummary)",
            "折叠长度：\(Int(HideEngine.collapsedLength)) pt（最宽屏幕 \(Int(widest)) pt）",
            "菜单栏状态项：检测到 \(windows.total) 个" + (separatorX == nil
                ? "，圆点当前不可见，无法测量左侧数量（请先展开）"
                : !windowCountReliable
                    ? "，macOS 27+ 不再逐项暴露窗口，此计数仅供参考"
                    : "，位于左侧圆点左边 \(windows.left) 个"),
            "最近一次错误：\(lastError ?? "无")"
        ]

        lines.append("")
        if separatorX != nil && windowCountReliable && windows.left == 0 {
            lines.append("⚠️ 左侧没有检测到其他应用的图标。Dozer 只会隐藏位于「左侧圆点左边」的图标：")
            lines.append("   请按住 ⌘ 拖动菜单栏图标，把想隐藏的拖到圆点左边，再点击圆点。")
        }
        if !windowCountReliable {
            lines.append("提示：请确认已按住 ⌘ 把要隐藏的图标拖到圆点左边，并已授予辅助功能权限。")
        }
        if HideEngine.current == .legacy && HideEngine.macOSMajor >= 27 {
            lines.append("⚠️ 当前系统为 macOS 27+，传统长度挤压通常已被系统忽略；")
            lines.append("   若原生服务可用，请改用「原生方式」。")
        }
        if HideEngine.current == .native && !accessibility {
            lines.append("⚠️ 原生方式需要辅助功能权限：系统设置 → 隐私与安全性 → 辅助功能 → 允许 Dozer。")
        }
        if HideEngine.current == .native && !native {
            lines.append("⚠️ 原生服务在此系统不可用，请改用「传统方式」。")
        }
        if !hiddenSystemItems.isEmpty && HideEngine.current == .legacy {
            lines.append("⚠️ 电池、时钟、Wi-Fi、控制中心这些系统自带项只有在 macOS 27+ 的原生方式下才能隐藏；")
            lines.append("   当前为传统方式，它们会一直留在菜单栏上。")
        }
        lines.append("")
        lines.append("切换后请重新点击圆点验证。诊断内容也已写入系统日志，可复制后反馈。")
        return lines.joined(separator: "\n")
    }

    /// 显示诊断面板，并允许临时切换隐藏机制。
    static func show(separatorX: CGFloat?, lastError: String?, onChange: @escaping () -> Void) {
        let text = report(separatorX: separatorX, lastError: lastError)
        NSLog("Dozer 诊断\n%@", text)

        let alert = NSAlert()
        alert.messageText = "Dozer 隐藏机制诊断"
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")
        alert.addButton(withTitle: HideEngine.manualEngine == nil ? "试用传统方式" : "恢复自动选择")
        alert.addButton(withTitle: "试用原生方式")
        // 原生服务不可用时，避免用户点进一个必然失败的分支。
        if alert.buttons.count > 2 {
            alert.buttons[2].isEnabled = HideEngine.nativeServiceAvailable
        }

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        switch response {
        case .alertSecondButtonReturn:
            if HideEngine.manualEngine == nil {
                HideEngine.manualEngine = .legacy
            } else {
                HideEngine.manualEngine = nil
            }
            onChange()
        case .alertThirdButtonReturn:
            HideEngine.manualEngine = .native
            onChange()
        default:
            break
        }
    }
}

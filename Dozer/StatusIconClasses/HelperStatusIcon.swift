/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import Defaults

private struct StatusIconLength {
    static var show: CGFloat {
        Defaults[.buttonPadding]
    }
    // 参考 Hidden Bar：折叠长度按最宽屏幕计算，而不是硬编码 10,000。
    static var hide: CGFloat {
        HideEngine.collapsedLength
    }
    // 展开态最多几十 pt，折叠态至少 500 pt，用阈值判断比精确相等更稳健
    // （屏幕变化后折叠长度会被重算）。
    static let collapsedThreshold: CGFloat = 400
}

class HelperstatusIcon {
    var type: StatusIconType

    let statusIcon: NSStatusItem = NSStatusBar.system.statusItem(withLength: StatusIconLength.show)

    init() {
        type = .normal
        statusIcon.length = StatusIconLength.show
        statusIcon.highlightMode = false

        guard let statusIconButton = statusIcon.button else {
            fatalError("helper status item button failed")
        }

        statusIconButton.target = self
        statusIconButton.action = #selector(statusIconClicked(_:))
        setIcon()
        statusIconButton.sendAction(on: [.leftMouseDown, .rightMouseDown])
    }

    deinit {
        NSStatusBar.system.removeStatusItem(statusIcon)
    }

    func show() {
        statusIcon.length = StatusIconLength.show
        if #available(macOS 27, *) {
            statusIcon.isVisible = true
        }
    }

    func hide() {
        if #available(macOS 27, *) {
            if HideEngine.current == .native {
                // 其他应用的图标由 NativeMenuBarVisibility 通过系统可见性
                // 限制隐藏；这里只需把 Dozer 自己的这个点移出菜单栏。
                // macOS 27 会把过宽的 NSStatusItem 直接踢出布局，不能撑宽。
                statusIcon.isVisible = false
                return
            }
        }
        statusIcon.length = StatusIconLength.hide
    }

    func toggle() {
        if isShown {
            hide()
        } else {
            show()
        }
    }

    func setIcon() {
        guard let statusIconButton = statusIcon.button else {
            fatalError("helper status item button failed")
        }
        statusIconButton.image = Icons().helperstatusIcon
        statusIconButton.image!.isTemplate = true
    }

    func setSize() {
        // 处于折叠状态时不要覆盖折叠长度。
        if isShown {
            statusIcon.length = StatusIconLength.show
        }
        guard let statusIconButton = statusIcon.button else {
            fatalError("helper status item button failed")
        }
        let image = statusIconButton.image
        var size = DozerIcons.shared.iconFontSize
        if self.type == .remove {
            size /= 2
        }
        image?.size = NSSize(width: size, height: size)
        statusIconButton.image = image
    }

    /// 屏幕参数变化（外接显示器、分辨率调整）后重新应用折叠长度。
    func reapplyIfCollapsed() {
        guard !isShown else { return }
        if #available(macOS 27, *) {
            if HideEngine.current == .native { return }
        }
        statusIcon.length = StatusIconLength.hide
    }

    func showRemoveIcons() {}

    @objc
    func statusIconClicked(_ sender: AnyObject?) {}

    var isShown: Bool {
        if #available(macOS 27, *) {
            if HideEngine.current == .native {
                return statusIcon.isVisible
            }
        }
        return statusIcon.length < StatusIconLength.collapsedThreshold
    }

    var isHidden: Bool {
        !isShown
    }

    var xPositionOnScreen: CGFloat {
        guard let dozerIconFrame = statusIcon.button?.window?.frame else {
            return 0
        }
        let dozerIconXPosition = dozerIconFrame.origin.x
        return dozerIconXPosition
    }
}

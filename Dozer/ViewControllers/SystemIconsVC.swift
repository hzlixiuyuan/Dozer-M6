/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import Settings

/// 系统自带菜单栏项（电池、时钟、Wi-Fi、控制中心）的设置面板。
///
/// 这些项由系统进程自己绘制，既不是应用、Accessibility 也读不到它们的位置，
/// 传统方式「撑宽分隔项」同样推不动它们，所以只能通过 macOS 27 的菜单栏可见性
/// 限制按编号隐藏，单独给一个面板让用户点名勾选。
final class SystemIcons: NSViewController, SettingsPane {
    let paneIdentifier = Settings.PaneIdentifier.systemIcons
    let paneTitle: String = "系统图标"
    let toolbarItemIcon: NSImage = NSImage(systemSymbolName: "switch.2", accessibilityDescription: nil)
        ?? NSImage(named: NSImage.preferencesGeneralName)!

    private var checkboxes: [SystemMenuItem: NSButton] = [:]

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 360))
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(paragraph("隐藏系统自带的菜单栏图标", font: .boldSystemFont(ofSize: 13),
                                           color: .labelColor))
        stack.addArrangedSubview(paragraph(
            "电池、时钟、Wi-Fi 和控制中心由系统自己绘制，不受「把图标拖到圆点左边」影响。"
                + "勾选后它们会跟随 Dozer 圆点一起收起，再点一次圆点恢复显示。",
            font: .systemFont(ofSize: 11),
            color: .secondaryLabelColor
        ))

        for item in SystemMenuItem.allCases {
            let checkbox = NSButton(checkboxWithTitle: item.title, target: self,
                                    action: #selector(systemItemToggled(_:)))
            checkbox.state = DozerIcons.shared.hiddenSystemItems.contains(item) ? .on : .off
            checkboxes[item] = checkbox
            stack.addArrangedSubview(checkbox)
        }

        let hint: String
        if HideEngine.nativeServiceAvailable {
            hint = "当前机制：\(HideEngine.displayName)。这些项只有在该机制下才会真正收起。"
        } else {
            hint = "当前系统（macOS \(HideEngine.macOSMajor)）没有提供菜单栏可见性服务，"
                + "需要 macOS 27 或更新版本才能隐藏系统自带项。"
            for checkbox in checkboxes.values {
                checkbox.isEnabled = false
            }
        }
        stack.addArrangedSubview(paragraph(hint, font: .systemFont(ofSize: 11),
                                           color: .secondaryLabelColor))

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -24)
        ])
        view = container
    }

    @objc private func systemItemToggled(_: NSButton) {
        let hidden = Set(checkboxes.compactMap { item, checkbox in
            checkbox.state == .on ? item : nil
        })
        DozerIcons.shared.setHiddenSystemItems(hidden)
    }

    /// 自动换行的说明文字。`preferredMaxLayoutWidth` 与约束同宽，避免文字被截断。
    private func paragraph(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = font
        field.textColor = color
        field.lineBreakMode = .byWordWrapping
        field.maximumNumberOfLines = 0
        field.preferredMaxLayoutWidth = 472
        return field
    }
}

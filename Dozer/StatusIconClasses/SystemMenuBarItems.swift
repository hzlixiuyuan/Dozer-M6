/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa

/// macOS 27 菜单栏里由系统自己绘制的常驻项（电池、时钟、Wi-Fi、控制中心）。
///
/// 这些项不属于任何应用、没有 bundle identifier，Accessibility 也读不到它们在
/// 菜单栏上的位置，所以无法像其他图标那样按「左侧圆点左边」自动判断，只能由
/// 用户显式指定要隐藏哪几个。
///
/// 编号是 MenuBarAgent 的内部编号：在 macOS 27.0 上逐个实测，只有 0 电池、
/// 2 时钟、6 Wi-Fi、8 控制中心会真正画出图标；给出其他编号不会让图标凭空
/// 出现，也不会让任何图标消失。
enum SystemMenuItem: String, CaseIterable {
    case battery
    case clock
    case wifi
    case controlCentre

    /// MenuBarAgent 的编号。
    var number: Int {
        switch self {
        case .battery:
            return 0
        case .clock:
            return 2
        case .wifi:
            return 6
        case .controlCentre:
            return 8
        }
    }

    /// 设置面板与诊断信息里显示的名字。
    var title: String {
        switch self {
        case .battery:
            return "电池"
        case .clock:
            return "时钟"
        case .wifi:
            return "Wi-Fi"
        case .controlCentre:
            return "控制中心"
        }
    }

    /// 交给系统的完整编号范围。上限取实测过的 127：多给的编号不会变出图标，
    /// 却能让将来系统新增编号的系统项默认保持可见。
    static let allNumbers: ClosedRange<Int> = 0...127

    /// 仍然保留在菜单栏上的编号：完整范围减去用户选择隐藏的那几项。
    static func allowedNumbers(concealing hidden: Set<SystemMenuItem>) -> [Int] {
        let hiddenNumbers = Set(hidden.map { $0.number })
        return allNumbers.filter { !hiddenNumbers.contains($0) }
    }

    /// 存进 `UserDefaults` 的名字。只存字符串而不是编号，改写编号也不会让设置错位。
    static func storedNames(of items: Set<SystemMenuItem>) -> [String] {
        items.sorted { $0.number < $1.number }.map { $0.rawValue }
    }

    /// 从 `UserDefaults` 读回的名字；无法识别的值忽略，重复值自动合并。
    static func hidden(fromStored names: [String]) -> Set<SystemMenuItem> {
        Set(names.compactMap { SystemMenuItem(rawValue: $0) })
    }

    /// 按菜单栏从左到右的顺序，列出这些项的中文名，用于日志与诊断。
    static func titles(of items: Set<SystemMenuItem>) -> [String] {
        items.sorted { $0.number < $1.number }.map { $0.title }
    }
}

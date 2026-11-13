/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa

struct MenuBarVisibilityState: Equatable {
    var hideNormal = false
    var hideRemove = false
    /// 折叠时一并收起的系统自带项（电池、时钟、Wi-Fi、控制中心）。
    /// 系统项不跟随位置判断，只能由用户在设置里指定。
    var hiddenSystemItems: Set<SystemMenuItem> = []

    /// 展开态：两个分区都不隐藏，届时系统项也必须全部可见，
    /// 否则会出现「点了显示，时钟却没回来」这种半截状态。
    var isExpanded: Bool {
        !hideNormal && !hideRemove
    }

    static let expanded = MenuBarVisibilityState()
}

protocol MenuBarVisibilityAssertion: AnyObject {
    func invalidate()
}

protocol MenuBarVisibilityProviding {
    var isAvailable: Bool { get }
    func activate(allowing bundles: [String],
                  systemItems: [Int],
                  completion: @escaping (Result<MenuBarVisibilityAssertion, Error>) -> Void)
}

private final class NativeVisibilityAssertion: MenuBarVisibilityAssertion {
    private var value: AnyObject?

    init(_ value: AnyObject) { self.value = value }

    func invalidate() {
        guard let value = value else { return }
        DozerNativeVisibilityInvalidate(value)
        self.value = nil
    }

    deinit { invalidate() }
}

struct NativeVisibilityService: MenuBarVisibilityProviding {
    var isAvailable: Bool { DozerNativeVisibilityIsAvailable() }

    func activate(allowing bundles: [String],
                  systemItems: [Int],
                  completion: @escaping (Result<MenuBarVisibilityAssertion, Error>) -> Void) {
        let numbers = systemItems.map { NSNumber(value: $0) }
        DozerNativeVisibilityActivate(numbers, bundles) { assertion, error in
            if let assertion = assertion {
                completion(.success(NativeVisibilityAssertion(assertion as AnyObject)))
            } else {
                completion(.failure(error ?? NSError(domain: "DozerNativeVisibility", code: 1)))
            }
        }
    }
}

final class NativeMenuBarVisibility {
    enum Section: Int {
        case remove, normal, visible
    }

    private let inventory: MenuBarInventoryProviding
    private let service: MenuBarVisibilityProviding
    private let ownBundle: String
    private let runningBundles: () -> [String]
    private var assertion: MenuBarVisibilityAssertion?
    private var sections: [String: Section]?
    private var generation = 0
    private var isApplying = false
    private(set) var requestedState = MenuBarVisibilityState.expanded

    init(inventory: MenuBarInventoryProviding = MenuBarInventory(),
         service: MenuBarVisibilityProviding = NativeVisibilityService(),
         ownBundle: String = Bundle.main.bundleIdentifier ?? "com.mortennn.Dozer",
         runningBundles: @escaping () -> [String] = {
             NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
         }) {
        self.inventory = inventory
        self.service = service
        self.ownBundle = ownBundle
        self.runningBundles = runningBundles
    }

    // Frames passed here use Accessibility's top-left screen coordinates.
    static func classify(_ items: [MenuBarInventoryItem], normal: CGRect, remove: CGRect?) -> [String: Section] {
        var result: [String: Section] = [:]
        for item in items {
            var section = Section.visible
            // Other displays and unreadable/offscreen positions stay visible.
            if abs(item.frame.midY - normal.midY) < max(normal.height, item.frame.height),
               item.frame.midX < normal.midX {
                section = .normal
                if let remove = remove, item.frame.midX < remove.midX {
                    section = .remove
                }
            }
            // macOS hides by bundle: an app spanning sections keeps its most
            // visible placement, so an icon to the right is never lost.
            if let previous = result[item.bundleIdentifier], previous.rawValue > section.rawValue {
                continue
            }
            result[item.bundleIdentifier] = section
        }
        return result
    }

    func apply(_ state: MenuBarVisibilityState, normal: CGRect?, remove: CGRect?, completion: @escaping (Error?) -> Void) {
        generation += 1
        let request = generation
        requestedState = state
        if state.isExpanded {
            restore()
            completion(nil)
            return
        }

        func fail(_ message: String) {
            restore()
            completion(NSError(domain: "DozerNativeVisibility", code: 1,
                               userInfo: [NSLocalizedDescriptionKey: message]))
        }
        guard service.isAvailable else {
            fail("当前系统没有提供原生菜单栏隐藏服务，已恢复所有图标。可执行「Shift + 右键 Dozer 圆点」切换为传统方式。")
            return
        }
        guard inventory.isAuthorized else {
            inventory.requestAuthorization()
            fail("请在「系统设置 → 隐私与安全性 → 辅助功能」中允许 Dozer，然后再次点击圆点。已恢复所有图标。")
            return
        }
        isApplying = true
        // An unresponsive private service must not leave a half-completed hide.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self, self.generation == request, self.isApplying else { return }
            self.restore()
            completion(NSError(domain: "DozerNativeVisibility", code: 2,
                               userInfo: [NSLocalizedDescriptionKey: "菜单栏没有响应，已恢复所有图标。可执行「Shift + 右键圆点」查看诊断信息。"]))
        }

        let activate: ([String: Section]) -> Void = { [weak self] sections in
            guard let self = self, self.generation == request else { return }
            self.sections = sections
            let hidden = Set(sections.compactMap { bundle, section -> String? in
                if section == .remove && state.hideRemove || section == .normal && state.hideNormal {
                    return bundle
                }
                return nil
            })
            // Preserve apps whose Accessibility data could not be read, along
            // with Dozer itself and every application in the visible section.
            let allowed = Set(self.runningBundles()).union(sections.keys).subtracting(hidden).union([self.ownBundle])
            // 系统自带项不在 Accessibility 的清单里，它的可见性完全由这张编号
            // 允许表决定：用户没勾选的项保持可见，勾选的项从表里去掉。
            let allowedSystemItems = SystemMenuItem.allowedNumbers(concealing: state.hiddenSystemItems)
            // 系统可能拒收带「隐藏系统项」的允许表（实测编号范围超出上限时整份
            // 配置都会被拒绝）。这时退一步只隐藏普通图标，别让整次点击变成
            // 「什么都没隐藏」，系统项的问题留给诊断面板与设置面板说明。
            let hideSystemItems = !state.hiddenSystemItems.isEmpty
            func accept(_ result: Result<MenuBarVisibilityAssertion, Error>, isFallback: Bool) {
                guard self.generation == request else {
                    if case .success(let stale) = result { stale.invalidate() }
                    return
                }
                self.isApplying = false
                switch result {
                case .success(let replacement):
                    let previous = self.assertion
                    self.assertion = replacement
                    previous?.invalidate()
                    if isFallback {
                        NSLog("Dozer 隐藏系统自带项的配置被系统拒绝，本次仅隐藏了普通图标。")
                    }
                    completion(nil)
                case .failure(let error):
                    if hideSystemItems && !isFallback {
                        self.service.activate(allowing: allowed.sorted(),
                                              systemItems: SystemMenuItem.allowedNumbers(concealing: [])) { retry in
                            accept(retry, isFallback: true)
                        }
                        return
                    }
                    self.restore()
                    completion(error)
                }
            }
            self.service.activate(allowing: allowed.sorted(), systemItems: allowedSystemItems) { result in
                accept(result, isFallback: false)
            }
        }

        // Positions reported for restricted items are stale. Reuse the last
        // unrestricted snapshot until all sections have been shown again.
        if let sections = sections {
            activate(sections)
        } else if let normal = normal, normal.width > 0, normal.minX.isFinite {
            inventory.snapshot { [weak self] items in
                guard let self = self, self.generation == request else { return }
                activate(Self.classify(items, normal: normal, remove: remove))
            }
        } else {
            fail("无法读取 Dozer 圆点的位置。请在菜单栏中保留两个圆点后重试，并确认已授予辅助功能权限。")
        }
    }

    func restore() {
        generation += 1
        isApplying = false
        requestedState = .expanded
        assertion?.invalidate()
        assertion = nil
        sections = nil
    }

    deinit { assertion?.invalidate() }
}

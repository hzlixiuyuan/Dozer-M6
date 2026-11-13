# Changelog

## Version 4.2.2

修复：

* 4.2.1 把交给系统的编号允许表扩大到了 `0...127`，超出原有 64 项上限时系统会拒绝整份配置，导致连普通图标都隐藏不了。现恢复与 4.2.0 一致的 `0..<64`，只减去用户勾选的系统项，四个系统项编号（0/2/6/8）都在范围内，功能不受影响
* 勾选系统项后如果配置仍被系统拒绝，自动回退为「只隐藏普通图标」，不再出现点一下就什么都不隐藏的情况

## Version 4.2.1

新增：

* 「系统图标」设置面板：可以勾选电池、时钟、Wi-Fi、控制中心，让它们跟随 Dozer 圆点一起收起（仅 macOS 27+ 原生方式；旧系统上面板会置灰说明）

修复：

* 系统自带的菜单栏图标此前永远可见：原生可见性配置把 `allowedSystemItems` 固定写成全部编号，等于明确要求系统「这些都别隐藏」。现在按用户在设置里勾选的项从允许表里剔除，只有实测出的四个编号（0 电池 / 2 时钟 / 6 Wi-Fi / 8 控制中心）会被隐藏，其余编号照旧保留，跨机型安全
* 诊断面板补充系统自带项的当前状态，并说明传统方式下系统项无法隐藏的原因

## Version 4.2.0
New features:
* Configure amount of seconds to hide the icons after #104. @blakedgordon
* Resize icons and padding capability added #101. @blakedgordon

Fixed:
* Fix both dozer icons from being hidden #105. @blakedgordon

Thank you @blakedgordon for the contributions🙌

## Version 4.1.0
New features:
* Hide status bar icons at launch #78. @aonez

Fixed:
* Reduce CPU usage when "Hide status bar icons after 10 seconds" is checked #78. @aonez

Thank you @aonez for the contributions🙌

## Version 4
New features:
* ”Remove”-icon. Additional icon to hide/show icons with `option+click`
* Auto-hide status bar icons #22
* ”No Icon”-mode. Hide/show only using keyboard shortcut

Other:
* Improved UI in preferences

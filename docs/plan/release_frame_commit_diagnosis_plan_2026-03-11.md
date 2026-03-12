# Release Frame Commit 诊断方案

- 日期：2026-03-11
- 目标：把 `vsync_lab` 的重点从“推导式 VSync/jank 压测”转向“release 包下状态已推进但视觉提交漏帧”的专项诊断

## 1. 背景

当前 `vsync_lab` 已经具备以下能力：

- 动画压测
- 滚动压测
- `FrameTiming` 指标展示
- 统一 frame log 导出
- `gfxinfo` / Perfetto / atrace 采集脚本

这些能力对于观察 frame pacing、jank 和抖动是有价值的，但它们并不能直接回答下面这个更关键的问题：

> 为什么在 Android 10 的硬件相框上，release 包里业务逻辑已经推进了，但屏幕还停留在旧画面，直到手动调用 `scheduleFrame()` 才恢复？

这说明当前仓库的“VSync miss 推导指标”并不是这次问题的主轴。

## 2. 当前真实问题定义

当前需要诊断的问题不是“平均 FPS 低”或“jank 多”，而是：

> Dart / 业务逻辑已经运行到下一状态，但下一帧视觉提交偶发没有发生，导致屏幕仍显示旧内容；手动 `scheduleFrame()` 后，画面立即恢复。

已确认至少存在两类场景：

### 场景 1：同页状态切换丢视觉提交

- 页面 A 存在两种状态
- 第二种状态的逻辑已经开始运行
- 但屏幕上仍显示第一种状态
- 必须手动调用 `scheduleFrame()`，才会进入下一帧并更新 UI

### 场景 2：路由切换后仍停留旧页面

- 页面 A 路由到页面 B
- 页面 B 的逻辑已经在运行
- 但屏幕仍显示页面 A
- 手动触发下一帧后，画面才切到页面 B

## 3. 关键判断

这件事当前不应优先命名为“VSync 问题”，而应优先命名为：

- `frame scheduling loss`
- `visual commit loss`
- `next-frame request missing`
- `release-only frame delivery anomaly`

原因是当前最强的证据链是：

- 逻辑推进了
- 手动 `scheduleFrame()` 能补救

这更像“下一帧请求没有正常完成”或“帧请求到视觉提交之间某处偶发断掉”，而不是单纯的低帧率问题。

## 4. 为什么当前 VSync Lab 不够

当前仓库里的 `VSync misses` 指标是根据以下逻辑推导出来的：

- 通过相邻帧 `frameEndUs` 计算实际帧间隔
- 用目标刷新率计算理论帧预算
- 当实际间隔明显大于预算时，推导为一次 miss

这类指标能回答：

- 帧节奏是否异常
- 是否疑似存在丢节拍或长间隔

但不能直接回答：

- `setState()` 后有没有真正触发 build
- build 之后有没有发生 paint
- 路由切换是否已经逻辑成功但没完成视觉提交
- `scheduleFrame()`、`handleBeginFrame()`、`handleDrawFrame()` 链路哪一段偶发断掉

所以需要新增一套完全独立的诊断入口和代码块。

## 5. 本轮方案的总目标

新增一个独立于当前 stress 场景的专项诊断模块，用来回答：

1. 逻辑状态变更是否真的发生了
2. 对应的 `build` 是否发生了
3. 对应的 `paint` 是否发生了
4. 对应的 `postFrameCallback` 是否到达
5. `scheduleFrame()` 是否被请求
6. `handleBeginFrame()` / `handleDrawFrame()` 是否真的发生
7. 路由逻辑是否已经进入 B，但最后一次 painted route 仍然是 A

## 6. 验收口径必须强调 release

这次专项诊断必须以 **release 包 + Android 10 实机** 为主口径。

### 必须强调的原因

- 当前异常明确表现为：`debug` 包不明显，`release` 包会出现
- `debug` 模式的调度、断言、性能特征、编译产物都与 `release` 不同
- 如果只在 `debug` 下验证，结论的参考价值很低

### 本轮默认验收环境

- 平台：Android only
- 基线系统：Android 10 / API 29
- 设备：问题硬件相框实机
- 运行模式：`release`

### 运行建议

优先使用下面的方式验证：

```bash
flutter run --release -t lib/main_frame_diagnosis.dart -d <android_device_id>
```

或在需要固化 APK 时使用：

```bash
flutter build apk --release -t lib/main_frame_diagnosis.dart
```

## 7. 新模块定位

本轮新增模块建议命名为：

- `Frame Diagnosis`
- 或 `Frame Commit Diagnosis`

推荐使用后者，因为它更明确地指向“视觉提交是否完成”。

这个模块与现有 animation/scroll stress 的关系应该是：

- 现有 stress 场景保留，作为 legacy/辅助工具
- 新模块成为当前仓库的主诊断入口

## 8. 目录与入口建议

### 8.1 新的代码块独立目录

建议新增：

```text
frame_diagnosis/
```

该目录下承载本轮专项诊断逻辑，避免和现有 stress 代码混在一起。

### 8.2 新入口要求

至少需要两个启动方式：

1. 默认启动入口
   - `main.dart` 默认启动 diagnosis app
   - `flutter run -d <android_device_id>` 直接进入 diagnosis workspace

2. legacy 辅助入口
   - `main_legacy.dart` 保留 animation/scroll stress lab
   - 便于继续复用已有 frame log / gfxinfo / Perfetto 工作流

3. 显式 diagnosis 别名入口（可选）
   - `main_frame_diagnosis.dart`
   - 便于脚本或固定 release 构建目标复用

### 8.3 现有代码保留

现有代码保留，不直接删除：

- `Animation stress`
- `Scroll stress`
- 现有 `FrameTimingMonitor`
- 现有脚本与文档

但它们不再是当前问题的第一主入口。

## 9. 新诊断模块建议观测点

### 9.1 Binding 级观测

需要在专项入口中增加 binding 级埋点，优先记录：

- `scheduleFrame()`
- `handleBeginFrame()`
- `handleDrawFrame()`
- `drawFrame()`
- `FrameTiming` callback 批次

目标是确认：

- 是不是根本没有请求下一帧
- 还是请求了，但 begin frame 没到
- 还是 draw frame 执行了，但最后视觉提交依然没更新

### 9.2 页面级观测

需要记录：

- `intent`，例如用户点击、定时切换、逻辑状态翻转
- `setState` 调用点
- `build`
- `paint`
- `postFrameCallback`

目标是把“逻辑状态”和“最后一次真正被 build/paint 的状态”并排展示出来。

### 9.3 路由级观测

需要记录：

- `didPush`
- `didPop`
- `didReplace`
- 当前逻辑路由
- 最后一次 build 的 route
- 最后一次 paint 的 route

目标是确认下面这种情况：

> 逻辑栈顶已经是 B，但最后一次 painted route 还是 A

### 9.4 人工补帧能力

需要在诊断页提供一个显式控制：

- `Force scheduleFrame`

因为当前已知这是最关键的人工恢复动作，也是最直接的验证手段。

### 9.5 连续帧保活能力

还应提供一个测试开关：

- `Keep frames pumping`

实现方式可以是隐藏 `Ticker` / `AnimationController.repeat()`

这个开关的价值在于验证：

- 如果持续主动要帧时问题明显消失，说明更像是按需调度链路偶发漏帧
- 如果持续要帧依然会卡在旧画面，则可能更偏向合成/显示链路

## 10. 新模块中的两个核心实验场景

### 10.1 State Commit Scenario

用于复现“同页状态已切换，但视觉仍是旧状态”。

建议最小行为：

- 页面上有非常明显的 A/B 状态显示
- 状态切换后，逻辑计数器继续运行
- 逻辑事件被记录到时间线
- 页面上同时显示：
  - 逻辑状态
  - 最后一次 build 的状态
  - 最后一次 paint 的状态
  - 最后一次 post-frame 的状态

目标是确认：

- 是逻辑没切
- 还是逻辑切了但视觉没提交

### 10.2 Route Commit Scenario

用于复现“逻辑已进入 B，但屏幕仍是 A”。

建议最小行为：

- A 页明确可 push 到 B
- B 页进入后立即开始逻辑计数
- 外部观测面板持续显示：
  - 逻辑 route
  - 最后一次 build route
  - 最后一次 paint route

目标是确认：

- `Navigator` 是否已逻辑进入 B
- 最后视觉提交是不是还停留在 A

## 11. UI 结构建议

推荐不要把这个模块做成普通单页，而要做成“实验区 + 观测区”并排。

推荐结构：

- 左侧 / 上方：实验视口
  - 展示 State Scenario 或 Route Scenario
- 右侧 / 下方：观测面板
  - 当前状态快照
  - Binding 级计数
  - 最近事件时间线
  - `Force scheduleFrame`
  - `Keep frames pumping`
  - 清空日志

这样即使实验视口逻辑已经切到下一状态，观测面板也能帮助你对比“逻辑状态”和“最后一次真正画出来的状态”。

## 12. 事件时间线建议格式

建议统一为事件流，而不是只看当前快照。

每条事件至少包含：

- `seq`
- `elapsedMs`
- `source`
- `action`
- `details`

推荐来源包括：

- `binding`
- `state_scenario`
- `route_scenario`
- `navigator`
- `lab_controls`

推荐动作包括：

- `scheduleFrame`
- `handleBeginFrame`
- `handleDrawFrame`
- `drawFrame`
- `intentSwitchToB`
- `setState`
- `build`
- `paint`
- `postFrame`
- `didPush`
- `didPop`
- `manualScheduleFrame`

## 13. 实施顺序建议

### Phase A：先把诊断入口落起来

目标：

- 新增 `frame_diagnosis` feature
- `main.dart` 默认启动 diagnosis app
- 保留 `main_legacy.dart` 作为 legacy stress 入口
- 新增 `main_frame_diagnosis.dart`
- 新增独立实验页骨架

### Phase B：补齐 Binding / 页面 / 路由埋点

目标：

- 有统一事件时间线
- 有状态快照面板
- 可以人工 `Force scheduleFrame`
- 可以切换 `Keep frames pumping`

### Phase C：先做最小 release 验证

目标：

- 在 Android 10 实机 release 包上运行
- 至少验证两类场景都能被同一套诊断面板观察
- 当异常出现时，能够明确看到“逻辑已推进，但 paint/post-frame 未跟上”

### Phase D：必要时再补导出和脚本

如果纯 UI + 控制台日志还不够，再补：

- timeline JSON 导出
- 专项 pull/analyze 脚本
- release 轮次实验模板

这一步不应先于基础诊断入口。

## 14. 非目标

本轮不是为了：

- 做新的 FPS 压测页面
- 继续优化 1% low / jank 算法
- 先证明系统底层一定“没发 VSync”
- 直接下结论是 Flutter engine bug、Android bug、还是硬件 bug

本轮首先要做的是：

> 把“逻辑推进”和“视觉提交”之间到底断在什么位置，观测清楚。

## 15. 初步验收标准

当新增诊断模块后，至少应满足：

1. 可以在 release 包中直接进入诊断入口
2. 可以独立测试状态切换场景和路由切换场景
3. Phase B 完成后，可以手动执行 `Force scheduleFrame`
4. Phase B 完成后，可以打开 `Keep frames pumping`
5. 可以看到 Binding 级时间线事件
6. 可以看到“逻辑状态 vs build/paint/postFrame 状态”的并排信息
7. 当异常发生时，可以留下足够证据判断问题更偏：
   - 没请求到下一帧
   - 请求到了但 begin/draw 没走通
   - build 发生了但 paint 没发生
   - route 已切但最后 painted route 仍停在旧页面

## 16. 一句话总结

本轮要做的不是“再做一个 VSync 压测页”，而是：

> 新增一个以 release 包为主口径的 Frame Commit Diagnosis 入口，把 `setState / route push -> build -> paint -> postFrame -> frame delivery` 链路系统性打点出来。

只有这一步做完，后面的归因才不会漂。

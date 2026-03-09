# Package 化复用评估

- 日期：2026-03-09
- 目标：评估当前 `vsync_lab` 代码是否适合演进为一个方便复用、方便测试的 Flutter package

## 结论

- 当前代码已经具备明显的“包化雏形”。
- 如果目标是仓库内复用、或通过 `path` / `git` 依赖在其他 App 中接入，当前完成度约为 **7/10**。
- 如果目标是一个独立、稳定、便于外部团队直接集成和测试的 package，当前完成度约为 **4.5/10**。
- 当前最重要的不是继续堆功能，而是把 **测试、文档、依赖边界** 真正收口到 `packages/vsync_lab_toolkit`。

## 当日已完成更新

- `packages/vsync_lab_toolkit` 已补齐独立 `README.md`、`CHANGELOG.md`、`example/` 与包内测试。
- 子包目录 `flutter analyze` 与 `flutter test` 现已可以独立通过。
- `FrameLogSaveResult.buildAdbPullCommand()` 已从 toolkit 移除；仓库特定的 `adb` 命令拼装已迁回主应用。

## 当前做得好的地方

### 1. 核心能力已经被抽离到独立子包

核心监控与导出能力已经进入 `packages/vsync_lab_toolkit`：

- `FrameTimingMonitor`
- `FrameMetricsAggregator`
- `FrameObservabilityLog`
- `FrameLogFileExporter`
- `FrameMetricsSnapshot`

说明：主应用已经基本是实验壳子，核心价值已开始沉淀为可复用能力。

### 2. App 壳与实验场景仍留在业务层

以下内容依然保留在主应用侧，这是合理的：

- 首页与路由
- 动画压力场景
- 滚动压力场景
- 指标展示面板
- 刷新率输入解析

说明：这意味着当前边界大致是正确的——“实验 UI” 与 “监控核心” 没有混在一起。

### 3. Toolkit 本身没有依赖 `common`

`common` 目前只用于主应用的 UI 与路由层，没有渗透到 toolkit 核心中。

说明：这对后续独立复用非常关键，避免了 package 被业务基础设施反向污染。

### 4. 已经有初步复用说明

根目录 `README.md` 已经开始描述如何在其他 App 中引入 `vsync_lab_toolkit`。

说明：方向是对的，只是还没有沉淀为“子包自己的独立文档体系”。

## 当前不足与风险点

### 1. 测试闭环问题已基本解决

此前核心测试主要停留在主应用侧，package 化闭环不完整；当前已迁移并补齐到：

- `packages/vsync_lab_toolkit/test/frame_timing_monitor_test.dart`
- `packages/vsync_lab_toolkit/test/frame_observability_log_test.dart`
- `packages/vsync_lab_toolkit/test/frame_log_file_exporter_test.dart`

当前收益：

- 子包可以独立证明自己可测试
- 测试直接依赖 `package:vsync_lab_toolkit/vsync_lab_toolkit.dart`
- 主应用不再承担对子包核心能力的“中转测试”职责

### 2. 子包已具备基础独立消费形态，但仍偏工作区内部模块

`packages/vsync_lab_toolkit` 当前已经具备：

- 独立 `README.md`
- 独立 `CHANGELOG.md`
- `example/`
- 子包测试目录下的实际测试文件

不过，`pubspec.yaml` 里仍然是：

- `publish_to: 'none'`

说明：它已经不像“只有源码抽离”的半成品，但当前定位仍更接近“工作区内部复用模块”，而不是准备直接发布到 `pub.dev` 的公共 package。

### 3. API 去业务化已完成一项关键整改

此前 `FrameLogSaveResult.buildAdbPullCommand()` 默认写死了：

- 包名 `com.harrypet.vsync_lab`
- 输出目录 `artifacts/...`

这部分现已移回主应用侧 helper；toolkit 只保留文件名、相对路径、绝对路径等通用结果数据。

这次整改带来的收益：

- package 不再默认带有当前仓库包名与目录结构假设
- 跨项目复用时不必覆写仓库特定默认值
- `FrameLogSaveResult` 的 API 语义更聚焦、更稳定

### 4. Core 纯度已有改善，但仍保留 Flutter 集成层

当前聚合器与日志记录器已经收口为纯数据输入：

- `FrameMetricsAggregator.addSample(...)`
- `FrameObservabilityLog.addSample(...)`

`FrameTiming` 到样本数据的转换被收敛到更薄的 Flutter glue code，主要留在监控器的监听与适配层。

当前剩余影响：

- `FrameTimingMonitor` 仍承担 `WidgetsBinding` 监听职责
- 未来若要拆出纯 Dart 包，仍需要继续评估 `core + flutter` 双层边界

### 5. 参数边界还没有完全硬化

典型问题：

- `targetRefreshRate` 缺少构造期断言或显式校验
- 聚合器内部存在 `1000 / _targetRefreshRate` 这类计算
- `FrameMetricsSnapshot.empty()` 的 `frameBudgetMs` 当前为 `0`

风险：

- 非法输入可能产生不符合预期的快照结果
- 初始态指标展示不够准确
- package API 稳定性偏弱

### 6. 公共导出面偏大

当前 `packages/vsync_lab_toolkit/lib/vsync_lab_toolkit.dart` 直接导出了全部核心类型。

风险：

- 将来很难收缩 API
- 语义上“内部实现”容易被外部依赖
- `semver` 成本会上升

### 7. 日志结构还是弱类型 Map

当前统一日志主要通过 `Map<String, dynamic>` 传递和导出。

影响：

- schema 演进时更容易破坏兼容
- IDE 与测试对结构的帮助较弱
- 后续如果加版本迁移会更麻烦

## 验证结果

本次检查结果如下：

- 根目录 `flutter analyze`：通过
- 根目录 `flutter test`：通过
- 子包目录 `flutter analyze`：通过
- 子包目录 `flutter test`：通过

说明：`packages/vsync_lab_toolkit` 现已具备独立分析、独立测试与独立示例运行所需的基础形态。

## 当前阶段建议

### 第一阶段：先把“像 package”这件事做实

优先级最高，建议先做：

1. （已完成）把核心测试迁移到 `packages/vsync_lab_toolkit/test/`
2. （已完成）测试直接使用 `package:vsync_lab_toolkit/vsync_lab_toolkit.dart`
3. 主应用逐步直接 import 子包，减少对 `lib/metrics/*.dart` 中转层的依赖
4. （已完成）给子包补齐独立 `README.md`
5. （已完成）给子包补齐 `CHANGELOG.md`
6. （已完成）增加最小可运行 `example/`

完成这一阶段后，子包才算真正具备“独立存在能力”。

### 第二阶段：做 API 去业务化

建议项：

1. （已完成）将 `buildAdbPullCommand()` 移回主应用或 `scripts/`
2. 为 `targetRefreshRate` 等关键参数增加 assert / 校验
3. 让 `FrameMetricsSnapshot.empty()` 返回合理的 `frameBudgetMs`
4. 收窄 `vsync_lab_toolkit.dart` 的公共导出面

完成这一阶段后，子包会更像“通用监控工具包”，而不是“实验项目里抽出来的一块代码”。

### 第三阶段：如果目标是真正长期复用，建议继续拆层

可以考虑拆成两层：

- `vsync_lab_core`
- `vsync_lab_flutter`

建议边界：

- `vsync_lab_core`：纯 Dart 聚合、日志模型、序列化、回放分析
- `vsync_lab_flutter`：`FrameTiming` 适配、`WidgetsBinding` 监听、文件导出、Flutter 集成

这样会显著提升：

- 可测试性
- 可移植性
- API 稳定性
- 后续工具链扩展能力

## 一句话判断

当前方向是正确的，而且已经走了一半。

最应该优先推进的不是继续增加实验功能，而是把 **测试、文档、依赖边界** 真正迁移并固定到 `packages/vsync_lab_toolkit`，让它先成为一个能独立分析、独立测试、独立说明的 package。

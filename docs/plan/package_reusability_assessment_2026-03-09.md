# Package 化复用评估

- 日期：2026-03-09
- 目标：评估当前 `vsync_lab` 代码是否适合演进为一个方便复用、方便测试的 Flutter package

## 结论

- 当前代码已经具备明显的“包化雏形”。
- 如果目标是仓库内复用、或通过 `path` / `git` 依赖在其他 App 中接入，当前完成度约为 **7/10**。
- 如果目标是一个独立、稳定、便于外部团队直接集成和测试的 package，当前完成度约为 **4.5/10**。
- 当前最重要的不是继续堆功能，而是把 **测试、文档、依赖边界** 真正收口到 `packages/vsync_lab_toolkit`。

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

### 1. 测试还没有真正跟着 package 走

当前核心测试还放在主应用根目录：

- `test/metrics/frame_timing_monitor_test.dart`
- `test/metrics/frame_observability_log_test.dart`
- `test/metrics/frame_log_file_exporter_test.dart`

而且测试导入路径仍然是主应用的：

- `package:vsync_lab/metrics/...`

这带来的问题是：

- 子包无法单独证明自己可测试
- 主应用只是通过 re-export 间接测试了 toolkit
- 将来如果主应用删掉中转层，测试会一起失效

### 2. 子包还不具备独立分发形态

`packages/vsync_lab_toolkit` 当前缺少：

- 独立 `README.md`
- 独立 `CHANGELOG.md`
- `example/`
- 子包测试目录下的实际测试文件

此外，`pubspec.yaml` 里仍然是：

- `publish_to: 'none'`

说明：这更像“工作区内部模块”，还不像一个真正对外可消费的 package。

### 3. API 中仍混有 App / Android 实验语义

`FrameLogSaveResult.buildAdbPullCommand()` 里默认写死了：

- 包名 `com.harrypet.vsync_lab`
- 输出目录 `artifacts/...`

这类逻辑更适合保留在主应用或 `scripts/`，不应成为通用 package API 的一部分。

风险：

- 让 package 默认带有特定业务仓库假设
- 降低跨项目复用的通用性
- 增加未来 API 兼容负担

### 4. Core 还不够“纯”，影响测试与扩展

当前聚合器与日志记录器仍直接处理 `FrameTiming` / `dart:ui`：

- `FrameMetricsAggregator.addTiming(FrameTiming timing)`
- `FrameObservabilityLog.addTiming(FrameTiming timing)`

虽然也提供了 `addSample(...)`，但整体模型仍偏 Flutter 运行时绑定。

影响：

- 不利于做纯 Dart 单元测试
- 不利于做离线日志回放分析
- 不利于未来拆出 CLI / desktop 分析工具

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
- 子包目录 `flutter test`：失败

子包测试失败的原因不是实现错误，而是 **`packages/vsync_lab_toolkit/test` 下没有测试文件**。

这恰好也说明了当前 package 化还没有闭环。

## 当前阶段建议

### 第一阶段：先把“像 package”这件事做实

优先级最高，建议先做：

1. 把核心测试迁移到 `packages/vsync_lab_toolkit/test/`
2. 测试直接使用 `package:vsync_lab_toolkit/vsync_lab_toolkit.dart`
3. 主应用逐步直接 import 子包，减少对 `lib/metrics/*.dart` 中转 re-export 的依赖
4. 给子包补齐独立 `README.md`
5. 给子包补齐 `CHANGELOG.md`
6. 增加最小可运行 `example/`

完成这一阶段后，子包才算真正具备“独立存在能力”。

### 第二阶段：做 API 去业务化

建议项：

1. 将 `buildAdbPullCommand()` 移回主应用或 `scripts/`
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


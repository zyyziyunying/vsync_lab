# Package 化迁移 TODO

- 日期：2026-03-09
- 目标：将 `vsync_lab` 当前的监控核心收敛为一个可独立复用、可独立测试、可持续演进的 Flutter package
- 当前核心子包：`packages/vsync_lab_toolkit`

## 总体目标

- 让 `vsync_lab_toolkit` 可以独立分析
- 让 `vsync_lab_toolkit` 可以独立测试
- 让主应用变成 toolkit 的示例与实验壳
- 降低 toolkit 中的业务耦合与仓库特定假设

## Phase 1：先让子包真正独立

### 1.1 迁移核心测试到子包

- [x] 将 `test/metrics/frame_timing_monitor_test.dart` 迁移到 `packages/vsync_lab_toolkit/test/`
- [x] 将 `test/metrics/frame_observability_log_test.dart` 迁移到 `packages/vsync_lab_toolkit/test/`
- [x] 将 `test/metrics/frame_log_file_exporter_test.dart` 迁移到 `packages/vsync_lab_toolkit/test/`
- [x] 将测试导入改为 `package:vsync_lab_toolkit/vsync_lab_toolkit.dart`
- [x] 确保在 `packages/vsync_lab_toolkit/` 下执行 `flutter test` 通过

验收标准：

- `packages/vsync_lab_toolkit/test/` 下存在真实测试文件
- 在子包目录单独运行 `flutter test` 通过
- 根目录不再依赖主应用 re-export 来测试 toolkit

### 1.2 让主应用直接依赖子包 API

- [x] 检查 `lib/features/` 与 `lib/widgets/` 中所有 toolkit 相关 import
- [x] 将主应用中对 `lib/metrics/*.dart` 的引用逐步替换为 `package:vsync_lab_toolkit/vsync_lab_toolkit.dart`
- [x] 评估是否保留 `lib/metrics/*.dart` 作为短期兼容层
- [ ] 若不再需要兼容层，删除 `lib/metrics/*.dart` re-export 文件

验收标准：

- 主应用直接 import 子包
- toolkit 不再通过主应用中转暴露 API

### 1.3 补齐子包基础文档

- [x] 新增 `packages/vsync_lab_toolkit/README.md`
- [x] 新增 `packages/vsync_lab_toolkit/CHANGELOG.md`
- [x] 在子包 README 中补齐安装方式、最小接入示例、导出能力说明
- [x] 在子包 README 中明确 Android / Flutter 依赖前提

验收标准：

- 打开子包目录即可理解用途、接入方式和验证方式

### 1.4 添加最小示例工程或示例代码

- [x] 新增 `packages/vsync_lab_toolkit/example/`
- [x] 示例至少展示 `FrameTimingMonitor` 的初始化与启动
- [x] 示例展示手动保存 frame log 的最小调用方式
- [x] 示例避免依赖主应用中的 `common` 和实验页面

验收标准：

- 新用户不需要进入主应用代码，也能理解子包如何使用

## Phase 2：做 API 去业务化

### 2.1 移除 package 中的仓库特定逻辑

- [ ] 审查 `FrameLogSaveResult.buildAdbPullCommand()` 的职责
- [ ] 评估将 adb pull 命令拼装逻辑迁回主应用或 `scripts/`
- [ ] 移除默认 `com.harrypet.vsync_lab` 这类仓库特定值
- [ ] 移除默认 `artifacts/...` 这类实验目录假设

验收标准：

- toolkit API 不再默认绑定当前仓库包名与目录结构

### 2.2 硬化关键参数与边界条件

- [ ] 为 `targetRefreshRate` 增加 assert 或显式参数校验
- [ ] 审查 `maxSamples` 与 `maxLogRecords` 的边界值处理
- [ ] 修正 `FrameMetricsSnapshot.empty()` 中的 `frameBudgetMs`
- [ ] 为非法输入补充对应测试

验收标准：

- 非法或极端输入下的行为清晰可预期
- 所有边界条件都有测试覆盖

### 2.3 收窄公共 API 导出面

- [ ] 审查 `packages/vsync_lab_toolkit/lib/vsync_lab_toolkit.dart`
- [ ] 区分“真正公共 API”与“内部实现类型”
- [ ] 仅导出稳定且希望长期维护的类型
- [ ] 记录暂不公开的内部能力

验收标准：

- 外部用户只接触稳定、明确的入口 API
- 降低未来 `semver` 维护成本

## Phase 3：提升可测试性与长期扩展性

### 3.1 降低对 Flutter 运行时的耦合

- [ ] 盘点 `dart:ui` / `FrameTiming` 直接依赖点
- [ ] 评估让核心聚合逻辑以纯数据输入为主
- [ ] 保留 `addSample(...)` 作为核心数据输入接口
- [ ] 将 `FrameTiming` 适配留在更薄的一层 Flutter glue code

验收标准：

- 主要聚合逻辑可在不依赖真实 Flutter 帧回调的情况下完成测试

### 3.2 为日志模型增加类型约束

- [ ] 评估是否引入显式 log model 替代部分 `Map<String, dynamic>`
- [ ] 识别稳定字段、可选字段与 schema version 责任边界
- [ ] 为序列化结果补充结构测试

验收标准：

- 日志 schema 的演进成本降低
- 日志输出更容易做版本兼容管理

### 3.3 评估二次拆包

- [ ] 评估是否拆分为 `vsync_lab_core` 与 `vsync_lab_flutter`
- [ ] 若拆分，定义纯 Dart 层与 Flutter 集成层的职责边界
- [ ] 评估迁移成本、收益与兼容策略

验收标准：

- 形成明确结论：继续单包，或进入双层拆分

## 推荐执行顺序

建议按以下顺序推进：

1. 先迁测试
2. 再补子包 README / CHANGELOG / example
3. 再让主应用直接 import 子包
4. 再去掉 API 中的业务假设
5. 最后评估是否拆成 core + flutter 双层结构

## 每阶段完成后的验证命令

在仓库根目录：

```bash
flutter analyze
flutter test
```

在子包目录：

```bash
cd packages/vsync_lab_toolkit
flutter analyze
flutter test
```

## 最小里程碑定义

### M1：子包可独立测试

满足以下条件即可认为达到 M1：

- 子包拥有自己的测试文件
- 子包目录单独 `flutter test` 通过
- 子包拥有独立 README

### M2：子包可独立接入

满足以下条件即可认为达到 M2：

- 子包拥有 `example/`
- 主应用直接依赖子包 API
- 主应用不再承担 toolkit 中转层角色

### M3：子包 API 基本稳定

满足以下条件即可认为达到 M3：

- 业务特定逻辑已迁出 toolkit
- 参数边界已硬化
- 公共导出面已收敛
- 关键日志与聚合逻辑测试完备

## 当前优先级判断

如果只做一件事，优先做这个：

- [ ] 先把 toolkit 的核心测试迁入 `packages/vsync_lab_toolkit/test/`

原因：

- 这是 package 化闭环的起点
- 也是后续敢于重构 API 的基础
- 还能立即验证子包是否真的可以独立存在

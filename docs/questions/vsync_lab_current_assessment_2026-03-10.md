# `vsync_lab` 现状评估与问题清单

- 日期：2026-03-10
- 评估范围：
  - 根应用 `vsync_lab`
  - 内嵌子包 `packages/vsync_lab_toolkit`
- 评估方式：
  - 静态检查：`flutter analyze`
  - 自动化测试：`flutter test`
  - 关键源码、测试、文档与仓库结构审查

## 总体结论

当前工程的基础健康度是好的：

- 根应用和子包的 `flutter analyze` 都通过
- 根应用和子包的 `flutter test` 都通过
- `vsync_lab_toolkit` 已经具备相对清晰的职责边界，核心监控与导出能力基本独立

但这还不等于“可以放心长期复用”。

当前最突出的风险不在语法或类型层，而在：

1. 运行中切换刷新率后的数据口径一致性
2. frame log 导出归档的可靠性
3. UI 保存动作的重入处理
4. 文档与仓库状态脱节
5. 仓库清洁度与独立消费能力仍不够收口

一句话判断：这个工程已经是一个可运行、可测试、方向正确的实验工程，但还没有到“可稳定复用、可对外说明、可长期沉淀”的完成度。

## 已验证现状

2026-03-10 本地检查结果：

- 根目录 `flutter analyze`：通过
- 根目录 `flutter test`：通过
- `packages/vsync_lab_toolkit/flutter analyze`：通过
- `packages/vsync_lab_toolkit/flutter test`：通过

说明：

- 当前没有明显的静态错误、空安全错误或基础测试回归
- 问题主要集中在行为语义、边界条件、文档正确性和工程卫生上

## 主要问题

### 1. 高优先级：切换目标刷新率会污染统计和日志语义

相关位置：

- `packages/vsync_lab_toolkit/lib/src/frame_timing_monitor.dart:123`
- `packages/vsync_lab_toolkit/lib/src/frame_observability_log.dart:24`
- `lib/features/stress/animation_stress_page.dart:143`
- `lib/features/stress/scroll_stress_page.dart:198`

现状：

- 页面允许用户在监控运行过程中直接修改 target refresh rate
- `FrameTimingMonitor.applyTargetRefreshRate()` 只更新 target refresh rate
- 现有样本和现有 observability records 不会被清空

结果：

- 旧样本会按“新刷新率”重新计算 snapshot
- 文档头部 `targetRefreshRateHz` / `frameBudgetMs` 使用新值
- 已记录的旧 records 仍然保留采样时的 `expectedIntervalUs` 与 `targetRefreshRateHz`

这会导致同一份导出日志内部出现语义不一致：

- header 是新的
- snapshot 也是新的口径
- records 里却混着旧口径数据

影响：

- `jankRatio`、`vsyncMissCount`、`maxConsecutiveVsyncMiss` 可能被错误解释
- 同一轮实验数据不再可靠
- 后续脚本分析和人工比对都容易得出错误结论

建议：

- 最稳妥的做法是切换刷新率时强制 `reset()`
- 或明确拆成“更新配置但不保留历史数据”的语义
- 至少需要补测试覆盖“中途切换 refresh rate”的行为

### 2. 中优先级：归档文件名只有秒级精度，连续保存会覆盖 archive 文件

相关位置：

- `packages/vsync_lab_toolkit/lib/src/frame_log_file_exporter.dart:35`
- `packages/vsync_lab_toolkit/lib/src/frame_log_file_exporter.dart:62`

现状：

- archived 文件名基于 `yyyyMMdd_HHmmss`
- 同一秒内多次保存会生成相同文件名

触发场景：

- 用户连续点击 `Save frame log`
- 自动保存与手动保存碰巧发生在同一秒

影响：

- 所谓 archive 文件并不真正可靠
- 同一秒内的早先结果会被后一次写入覆盖
- 对实验留痕和回归比对非常不利

建议：

- 文件名加入毫秒或递增序号
- 或在写入前检测冲突并追加去重后缀

### 3. 中优先级：保存动作没有按“正在保存”状态禁用，存在 UI 重入

相关位置：

- `lib/widgets/frame_metrics_panel.dart:96`
- `packages/vsync_lab_toolkit/lib/src/frame_timing_monitor.dart:161`

现状：

- monitor 内部会复用同一个 pending save future
- 但面板按钮没有基于 saving 状态做禁用

结果：

- 用户连续点击时，不会重复写文件多次
- 但会有多个调用同时等待同一个 future 完成
- 保存完成后，可能连续弹出多个相同的成功对话框

影响：

- 交互体验差
- 用户容易误认为保存逻辑异常
- 也会增加后续维护时对“是否真正只保存了一次”的误判成本

建议：

- 将 `isSavingObservabilityLog` 传到面板层
- 保存中禁用按钮，或改为显示 loading 状态

### 4. 中优先级：根应用还不具备真正独立消费形态

相关位置：

- `pubspec.yaml:24`
- `pubspec.yaml:36`
- `README.md:194`

现状：

- 根应用依赖 `resolution: workspace`
- 直接依赖工作区内的 `common`
- README 同时又把它描述成独立仓库 / submodule 形态

这说明两件事：

- `packages/vsync_lab_toolkit` 的复用边界已经初步建立
- 但根应用 `vsync_lab` 自身仍然强依赖上层工作区环境

影响：

- 仓库迁出或独立初始化时并不自洽
- 文档会让读者误判当前工程的独立性
- 这会增加后续 package 化和 submodule 化的摩擦

建议：

- 明确区分“根应用实验壳”和“可复用 toolkit”
- 如果根应用要独立存在，就移除对 workspace `common` 的强依赖
- 如果短期不做，就在 README 里明确说明当前仍依赖 workspace 环境

### 5. 低优先级：子包 `build/` 产物被提交，仓库清洁度较差

相关位置：

- `.gitignore:33`
- `packages/vsync_lab_toolkit/build/...`

现状：

- 当前 `.gitignore` 只忽略根级 `/build/`
- 子包目录下的 `build/` 没有被忽略
- 因此已有生成物进入版本控制

影响：

- review 噪音增加
- 跨平台差异文件容易被误提交
- 仓库可读性和可维护性下降

建议：

- 将规则改成 `**/build/` 或补充对子包 `build/` 的忽略
- 清理已提交的生成文件

### 6. 低优先级：README 与实际实现、文档目录不一致

相关位置：

- `README.md:53`
- `README.md:189`
- `docs/README.md:138`
- `lib/widgets/frame_metrics_panel.dart:96`

现状：

- 根 README 仍描述 `Copy JSON` / `Copy frame log`
- 当前实际 UI 只有 `Save frame log`
- README 与 docs 还引用了仓库中不存在的 `docs/device_matrix.md`、`docs/experiment_log_template.md`

影响：

- 新接手的人会被误导
- 实验流程文档无法闭环
- 会削弱这个项目作为“学习仓库”的可信度

建议：

- 统一 README、docs 和当前 UI 行为
- 删除失效引用，或把缺失文档补回

## 当前做得好的地方

### 1. toolkit 职责边界已经开始清晰

`packages/vsync_lab_toolkit` 当前已经把这些核心能力收进去：

- `FrameTimingMonitor`
- `FrameMetricsSnapshot`
- `FrameLogExporter`
- `FrameLogFileExporter`
- `FrameLogSaveResult`

这说明核心方向是对的：主应用负责实验场景和展示，toolkit 负责观测与导出核心。

### 2. 核心逻辑已具备不错的可测试性

当前聚合器、日志构建器和 monitor 已经有独立测试覆盖，说明：

- 不是只能靠手工跑 UI 才能验证
- 关键聚合逻辑已经具备重构基础

### 3. 子包 API 面已经比早期更收敛

当前 barrel export 有意识地只暴露稳定 API，而把内部实现留在 `lib/src/`，这是正确方向。

## 测试与覆盖缺口

虽然现有测试都通过，但还缺少几类关键场景：

1. 缺少“监控中途切换 refresh rate”后的行为测试
2. 缺少“同一秒连续保存”是否覆盖 archive 文件的测试
3. 缺少 UI 层“重复点击保存按钮”的行为测试
4. 缺少 README / docs 所描述流程与当前实现之间的一致性检查

这类缺口的共同点是：

- 单元测试不容易直接暴露
- 但真实使用和实验数据会直接受影响

## 建议优先级

建议按下面顺序处理：

1. 先修复 refresh rate 切换后的数据一致性
2. 再修复 frame log archive 命名冲突
3. 给保存按钮加 saving 态，消除 UI 重入
4. 清理子包 `build/` 产物与 `.gitignore`
5. 修正文档，使 README、docs、UI、脚本描述一致
6. 再考虑根应用是否真的要脱离 workspace 成为独立仓库

## 最终判断

`vsync_lab` 当前不是一个“有明显质量问题”的工程，相反，它的基础结构、测试意识和拆包方向都不错。

真正的问题是：

- 数据语义的一致性还不够稳
- 工程边界和文档边界没有完全收口
- 一些会影响实验可信度的细节还没打磨完

如果继续推进，这个项目最需要的不是加更多实验页面，而是先把“数据可信、导出可靠、文档准确、仓库干净”这四件事做实。

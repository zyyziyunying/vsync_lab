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

当前工程的基础健康度是好的，而且比前一版评估时更收敛：

1. 根应用和子包的 `flutter analyze` 都通过
2. 根应用和子包的 `flutter test` 都通过
3. 之前最影响实验可信度的几个问题已经收口：
   - refresh rate 切换后的历史数据污染
   - frame log archive 命名冲突
   - 保存按钮重入导致的重复交互
   - README / docs / UI 行为漂移
   - 子包 `build/` 忽略规则缺失

一句话判断：

`vsync_lab` 现在已经是一个“可运行、可测试、实验闭环基本成立”的学习工程；当前最主要的剩余问题，不再是导出与监控语义本身，而是“根应用是否真的能独立迁出 workspace”以及“脚本/实验证据链是否继续制度化”。

## 已验证现状

2026-03-10 本地检查结果：

- 根目录 `flutter analyze`：通过
- 根目录 `flutter test`：通过，共 8 个测试
- `packages/vsync_lab_toolkit/flutter analyze`：通过
- `packages/vsync_lab_toolkit/flutter test`：通过，共 20 个测试

说明：

- 当前没有明显的静态错误、空安全错误或基础测试回归
- 现在的问题主要集中在工程边界、实验流程维护成本，以及“独立仓库”目标尚未真正完成

## 本轮核对后已关闭的问题

### 1. refresh rate 切换后的数据语义污染：已关闭

相关位置：

- `packages/vsync_lab_toolkit/lib/src/frame_timing_monitor.dart`
- `packages/vsync_lab_toolkit/test/frame_timing_monitor_test.dart`

当前状态：

- `FrameTimingMonitor.applyTargetRefreshRate()` 在更新 target refresh rate 后，会清空聚合样本与 observability records
- 对同 refresh rate 的重复应用仍保持幂等，不会无意义清空窗口
- 已有测试覆盖：
  - `changing refresh rate clears captured samples and records`
  - `reapplying the same refresh rate keeps the current capture window`

结论：

- 旧评估中“切换 refresh rate 会混入旧口径数据”的判断已经不成立
- 这项问题不再是当前主风险

### 2. frame log archive 命名冲突：已关闭

相关位置：

- `packages/vsync_lab_toolkit/lib/src/frame_log_file_exporter.dart`
- `packages/vsync_lab_toolkit/test/frame_log_file_exporter_test.dart`

当前状态：

- archived 文件名已包含毫秒和微秒
- 如果同一时间戳下仍发生冲突，会追加递增后缀
- 已有测试覆盖同一时间戳连续保存时的唯一性

结论：

- 旧评估中“archive 文件只有秒级精度、同一秒会覆盖”的判断已经不成立
- 当前导出归档可靠性达到可接受水平

### 3. UI 保存动作重入：已关闭

相关位置：

- `lib/widgets/frame_metrics_panel.dart`
- `test/widgets/frame_metrics_panel_test.dart`

当前状态：

- 面板按钮已根据保存状态显示 `Saving frame log...`
- 保存中按钮会被禁用
- 已补充“重复点击保存按钮仅触发一次保存”的 widget test

结论：

- 旧评估中“按钮未按 saving 状态禁用、可能弹出多个成功对话框”的判断已经不再适用
- UI 层与 monitor 层的 pending save 语义现在是一致的

### 4. README / docs / UI 行为不一致：已关闭

相关位置：

- `README.md`
- `docs/README.md`
- `docs/device_matrix.md`
- `docs/experiment_log_template.md`
- `test/docs/documentation_consistency_test.dart`

当前状态：

- 根 README 已改为真实面板行为：`Start/Pause monitor`、`Reset metrics`、`Save frame log`
- 缺失文档 `docs/device_matrix.md` 与 `docs/experiment_log_template.md` 已补回
- 新增文档一致性测试，至少能阻止常见文案漂移再次发生

结论：

- 旧评估中“README 与 docs 引用失效、UI 描述过期”的判断已经不成立
- 实验流程文档已具备最小闭环

### 5. 子包 `build/` 忽略规则缺失：已关闭

相关位置：

- `.gitignore`

当前状态：

- 当前 `.gitignore` 已使用 `**/build/`
- `git ls-files "packages/*/build/*"` 结果为空，说明子包生成物未被版本控制

结论：

- 旧评估中“子包 build 产物被提交”的判断与当前仓库状态不符
- 仓库清洁度问题在这一项上已经收口

## 当前仍需关注的问题

### 1. 中优先级：根应用仍依赖 workspace 环境，尚未真正具备独立仓库形态

相关位置：

- `pubspec.yaml`
- `README.md`
- `lib/widgets/frame_metrics_panel.dart`

现状：

- 根应用仍使用 `resolution: workspace`
- 仍直接依赖工作区内的 `common`
- README 虽然已经比之前更诚实，但仍保留“独立仓库 / submodule”方向的表述

影响：

- `vsync_lab` 作为根应用，当前仍不能脱离上层 workspace 直接迁出
- 读者容易把“toolkit 已可复用”误解成“整个 app 已完全独立”
- 如果后续真的要做 submodule 或单仓迁移，这部分仍然会成为摩擦点

建议：

1. 明确区分“实验壳 app”和“可复用 toolkit”
2. 如果根应用要独立存在，就移除对 workspace `common` 的强依赖
3. 如果短期不做迁移，就继续在 README 中明确当前需要 workspace 环境

### 2. 中优先级：脚本流程仍缺少自动化验证，实验采集链条主要靠人工回归

相关位置：

- `scripts/analyze_frame_log.ps1`
- `scripts/pull_and_analyze_frame_log.ps1`
- `scripts/collect_gfxinfo.ps1`
- `scripts/collect_perfetto.ps1`

现状：

- Dart 侧核心监控、导出、UI 交互已有较完整测试
- PowerShell 采集与分析脚本仍没有自动化测试或基于样例工件的 smoke check

影响：

- 一旦 `adb` 输出、文件路径或脚本参数约定变化，回归风险更依赖人工发现
- 这类问题不会被 `flutter test` 捕获，但会直接影响真实实验流程

建议：

1. 至少为 `analyze_frame_log.ps1` 增加基于固定样例 JSON 的 smoke check
2. 为 `pull_and_analyze_frame_log.ps1` 补一层命令拼接或参数分支测试
3. 设备采集脚本可以先从“命令构造正确性”做最小验证，不必一步到位做真机自动化

### 3. 低优先级：实验文档模板已补齐，但真实设备基线与样例证据仍待填充

相关位置：

- `docs/device_matrix.md`
- `docs/experiment_log_template.md`
- `artifacts/`

现状：

- 文档模板已经补回，流程上不再断链
- 但 `device_matrix.md` 里的设备信息仍以 `TBD` 为主
- 仓库中也还没有一套被明确引用的示例实验记录

影响：

- 方法论框架已经具备，但“真实设备证据库”还没有形成
- 对后续 A/B 对比、知识沉淀和新成员接手帮助有限

建议：

1. 下一轮真机实验后，优先把至少 1 台 RK3566 或 A133 设备信息补完整
2. 产出 1 份完整实验记录，作为模板实例
3. 只在确有必要时提交 `artifacts/` 原始证据，避免仓库噪音

## 当前做得好的地方

### 1. toolkit 职责边界已经比较清晰

`packages/vsync_lab_toolkit` 当前已经收口了核心监控与导出能力：

- `FrameMetricsRecorder`
- `FrameSample`
- `FrameTimingMonitor`
- `FrameMetricsSnapshot`
- `FrameLogExporter`
- `FrameLogFileExporter`
- `FrameLogSaveResult`

这说明主应用负责实验场景和展示，toolkit 负责观测与导出核心的方向是对的；其中 `FrameMetricsRecorder` 进一步把 plain-sample 驱动的核心能力提到了稳定公共入口，`FrameTimingMonitor` 则更明确地回到 Flutter 集成层角色。

### 2. 核心逻辑具备不错的可测试性

当前聚合器、日志构建器、monitor、文件导出器和关键 UI 交互都已有独立测试覆盖，说明：

- 不是只能靠手工跑 UI 才能验证
- 核心逻辑已经具备持续重构的基础
- 现在新增回归守卫的成本是可控的

### 3. 文档闭环比前一版明显更完整

当前已经具备：

- 根 README
- `docs/README.md`
- `docs/device_matrix.md`
- `docs/experiment_log_template.md`
- 文档一致性测试

这让项目作为“学习仓库”的说明性和可交接性明显好于前一版状态。

## 测试与覆盖状态

当前已覆盖的关键场景：

1. refresh rate 切换后清空旧样本与旧 records
2. 同 refresh rate 重复应用不清空当前窗口
3. frame log 自动保存与 reset 后重新 arm
4. 同一时间戳连续保存时 archive 文件名唯一
5. 保存按钮 saving 态禁用
6. 重复点击保存按钮仅触发一次保存
7. README / docs / 当前 UI 文案一致性检查

仍未自动化覆盖的区域：

1. PowerShell 脚本的端到端采集链条
2. 真机 `adb` / Perfetto 环境差异带来的行为分歧
3. 真实设备实验记录的长期积累与回归对比

## 建议优先级

建议按下面顺序继续推进：

1. 先明确根应用是否真的要脱离 workspace 成为独立仓库
2. 再为 PowerShell 脚本补最小 smoke check，降低实验流程回归风险
3. 把设备矩阵和至少 1 份真实实验记录补完整，形成证据样板
4. 之后再考虑依赖升级、更多实验页面或更复杂的观测能力

## 最终判断

`vsync_lab` 当前不是一个“问题很多、质量不稳”的工程，相反，它的主干质量已经达到了一个比较可信的阶段。

和旧评估相比，最大的变化是：

- 数据语义一致性问题已修复
- 导出归档可靠性已修复
- UI 保存重入已修复
- 文档目录与实现已对齐
- 基础测试覆盖已经比之前更完整

当前真正剩下的，不是核心逻辑 correctness，而是两个更工程化的问题：

1. 根应用边界是否要继续依赖 workspace
2. 实验脚本与设备证据链如何长期维护

如果继续推进，这个项目下一阶段最需要的不是再加很多实验页面，而是把“独立边界”和“实验证据链”这两件事做实。

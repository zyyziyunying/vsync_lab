# VSync 学习子项目讨论（Android Only）

## 1. 背景

我计划在当前工作区根目录新增一个**独立 Git 仓库**的 Flutter 子项目，并通过 **Git Submodule** 管理。  
该项目只支持 Android，目标是系统学习 Flutter 引擎层（尤其 Embedder）的 VSync 机制与优化方法。

触发点：在部分 Android 10 老硬件上，观察到 VSync 丢失/不稳定，导致帧率抖动、掉帧和动画不连续。

---

## 2. 目标（Goals）

1. 搭建一个最小但可复现实验环境，稳定复现 VSync 丢失现象。  
2. 打通 Flutter 从 Android VSync 信号到 Engine 调度的关键链路认知。  
3. 建立可量化指标（掉帧率、jank、帧间隔抖动）来验证优化是否有效。  
4. 输出可复用的方法论：如何定位、度量、验证、回归。

---

## 3. 非目标（Non-Goals）

1. 不追求业务功能完整性（这是学习/实验工程，不是产品工程）。  
2. 不在第一阶段改动主仓库业务代码。  
3. 不在早期追求“通用万能优化”，先聚焦 Android 10 老设备场景。

---

## 4. 技术关注点（Embedder / VSync）

- Android 侧 VSync 来源与分发（Choreographer / Display pipeline）。
- Flutter Engine 接收 VSync 后的调度链路（UI 线程、Raster 线程节奏）。
- 帧预算与 deadline miss（16.6ms 或更高刷新率预算下的抖动）。
- 线程竞争、CPU 降频、Binder/GC 抖动对 VSync 稳定性的影响。
- 设备刷新率信息与实际调度节奏不一致的问题（老硬件常见）。

---

## 5. 验证指标（先定口径）

- 平均 FPS、1% low FPS
- Jank 比例（慢帧占比）
- 帧间隔标准差（Frame interval jitter）
- VSync 丢失次数 / 连续丢失长度
- UI 线程与 Raster 线程耗时分布

---

## 6. 计划分期（建议）

### Phase 0：基线
- 最小 Flutter 场景（可稳定触发动画与滚动）。
- 建立基础采样：`adb shell dumpsys gfxinfo` + Flutter timings。

### Phase 1：可观测性
- 记录每帧时间戳、期望 VSync 间隔、实际间隔偏差。
- 输出统一日志格式，便于对比不同设备/不同策略。

### Phase 2：策略实验
- 在不破坏主流程前提下做可开关实验策略（A/B）：
  - 调度时序调整
  - fallback 机制（仅实验）
  - 线程负载隔离/优先级观察

### Phase 3：结论沉淀
- 形成“问题画像 -> 证据 -> 方案 -> 回归结果”的文档模板。
- 归纳可迁移到主项目的建议。

---

## 7. 子项目仓库建议（先讨论，不执行）

- 目录位置：根目录下独立子目录（后续作为 submodule）。
- 分支策略：`main` + `experiment/*`。
- 文档优先：每次实验必须附带“前后对比数据”。

---

## 8. 待确认问题

1. 目标最低 Android API（是否固定 API 29 / Android 10）？  
回答：是，第一阶段固定 Android 10（API 29）作为主目标与验收基线；其他版本仅做兼容观察，不作为当前阶段结论依据。
2. 主要测试机型清单（至少 2~3 台老设备）？  
回答：是硬件实机，优先覆盖市面少见老平台；当前重点芯片包括 RK3566、全志 A133（后续补充具体机型、系统版本、刷新率）。
3. 第一阶段是否允许引入 Perfetto trace 作为标准诊断？  
回答：允许，作为标准诊断工具之一。作用是对齐 VSync/Choreographer/SurfaceFlinger 与 Flutter UI/Raster 时间线，用于判断“VSync 丢失”与“线程处理超时”的边界。
4. 该项目最终是“学习仓库”还是“可回灌主仓库的预研仓库”？
回答：定位为学习仓库；后续基于该仓库沉淀的方法与数据，再新建可回灌主仓库的预研仓库。

---

## 9. Perfetto 最小使用流程（5 步）

### Step 1：准备与连接设备
- 使用 Android 10（API 29）目标设备，打开开发者选项与 USB 调试。
- 连接后先确认设备在线：`adb devices`。

### Step 2：启动可复现场景
- 启动本实验 app，进入可稳定触发卡顿/掉帧的动画或滚动页面。
- 先预热 10~20 秒，避免冷启动噪声。

### Step 3：抓取 10~20 秒 trace
- 先试图用文本配置采集（建议先从 10 秒开始）：

```bash
adb shell perfetto -o /data/misc/perfetto-traces/vsync_trace.pftrace -t 10s -c - <<EOF
buffers: { size_kb: 16384 fill_policy: RING_BUFFER }
data_sources: { config { name: "linux.ftrace" ftrace_config { ftrace_events: "sched/sched_switch" ftrace_events: "sched/sched_wakeup" ftrace_events: "gfx/frame_timeline" ftrace_events: "view/view_vsync" } } }
data_sources: { config { name: "android.surfaceflinger.frametimeline" } }
data_sources: { config { name: "track_event" } }
EOF
```

### Step 4：导出并查看
- 导出 trace 到本地：`adb pull /data/misc/perfetto-traces/vsync_trace.pftrace .`
- 在 Perfetto UI 打开（`https://ui.perfetto.dev`），重点看：
  - `Choreographer`/`view_vsync` 节奏是否连续；
  - `SurfaceFlinger FrameTimeline` 是否出现长间隔；
  - Flutter UI/Raster 线程是否在同一时段超预算。

### Step 5：记录结论与归档
- 每次实验至少记录：设备信息、场景、trace 时长、异常时间点、初步判断。
- 将原始 trace 与实验日志一起归档，便于后续 A/B 对比和回归复查。

---

## 10. 当前落地状态（2026-03-05）

- 已在工作区根目录落地 `vsync_lab/`（Android only，最小可运行实验工程）。
- `vsync_lab` 已初始化为独立 Git 仓库（后续可补远端并纳入 submodule 流程）。
- Phase 0 基线能力已就位：
  - 动画压测场景（可调粒子数/负载）
  - 滚动压测场景（可调列表规模/自动滚动/模糊）
  - `FrameTiming` 实时指标面板（FPS、1% low、jank、抖动、VSync miss）
- 已补充采样脚本与模板：
  - `scripts/collect_gfxinfo.ps1`
  - `scripts/collect_perfetto.ps1`
  - `docs/experiment_log_template.md`
  - `docs/device_matrix.md`
- Phase 1 可观测性能力已落地：
  - 新增统一日志导出（`schemaVersion: 1`，`logType: vsync_lab.frame_observability`）
  - 支持记录每帧关键字段：`frameEndUs`、`expectedIntervalUs`、`actualIntervalUs`、`intervalDeltaUs`、`intervalDeltaRatio`、`isVsyncMiss`
  - 面板新增 `Save frame log` 按钮，保存内容包含 `scenario`、`scenarioSettings`、`snapshot`、`records`
  - 默认环形缓冲区容量为 1200 帧，便于 10~20 秒窗口对比

---

## 11. Phase 1 使用建议（最小流程）

1. 进入 `Animation stress` 或 `Scroll stress`，运行 15~30 秒并完成预热。
2. 点击 `Save frame log`，然后优先执行 `./scripts/pull_and_analyze_frame_log.ps1 -Scenario <scenario>`；如果手动拉取，先用 `adb shell run-as com.harrypet.vsync_lab pwd` 获取应用数据目录，再拼接绝对路径 `<app_data_dir>/cache/frame_log_<scenario>_latest.json` 进行 `adb exec-out run-as ... cat ...`。
3. 继续采集 `gfxinfo` 与 Perfetto，按同一轮实验归档到 `artifacts/`。

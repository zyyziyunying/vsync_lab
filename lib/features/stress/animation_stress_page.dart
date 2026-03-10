import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

import '../../routes/app_routes.dart';
import '../../widgets/frame_metrics_panel.dart';
import 'refresh_rate_parser.dart';
import 'widgets/animation_stress_scene.dart';

class AnimationStressPage extends StatefulWidget {
  const AnimationStressPage({super.key});

  @override
  State<AnimationStressPage> createState() => _AnimationStressPageState();
}

class _AnimationStressPageState extends State<AnimationStressPage> {
  final _refreshController = TextEditingController(text: '60');
  final _refreshRateParser = const RefreshRateParser();
  late final FrameTimingMonitor _monitor;

  double _particleCount = 360;
  double _workloadLevel = 2;
  bool _colorShift = true;

  @override
  void initState() {
    super.initState();
    _monitor = FrameTimingMonitor(
      targetRefreshRate: 60,
      scenario: 'animation',
      scenarioSettingsBuilder: () => <String, Object?>{
        'particleCount': _particleCount.round(),
        'workloadLevel': _workloadLevel.round(),
        'colorShift': _colorShift,
      },
    );
    _monitor.start();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _monitor,
      builder: (context, child) {
        final metricsPanel = FrameMetricsPanel(
          snapshot: _monitor.snapshot,
          isRunning: _monitor.isRunning,
          onToggle: () {
            if (_monitor.isRunning) {
              _monitor.stop();
              return;
            }
            _monitor.start();
          },
          onReset: _monitor.reset,
          observabilityRecordCount: _monitor.observabilityRecordCount,
          onSaveObservabilityLog: () => _monitor.saveObservabilityLog(),
        );

        final controls = _ControlsCard(
          refreshController: _refreshController,
          particleCount: _particleCount,
          workloadLevel: _workloadLevel,
          colorShift: _colorShift,
          onParticleChanged: (value) => setState(() => _particleCount = value),
          onWorkloadChanged: (value) => setState(() => _workloadLevel = value),
          onColorShiftChanged: (value) => setState(() => _colorShift = value),
          onApplyRefreshRate: () => _applyRefreshRate(context),
        );

        final scene = CommonSectionCard(
          title: 'Animation scene',
          child: SizedBox(
            height: 360,
            child: AnimationStressScene(
              particleCount: _particleCount.round(),
              workloadLevel: _workloadLevel.round(),
              colorShift: _colorShift,
            ),
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Animation stress'),
            actions: [
              IconButton(
                tooltip: 'Back to dashboard',
                onPressed: () => NavigatorManager.goNamed(AppRouteName.home),
                icon: const Icon(Icons.home),
              ),
            ],
          ),
          body: CommonAdaptiveLayout(
            compact: (context) {
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  metricsPanel,
                  const SizedBox(height: 12),
                  controls,
                  const SizedBox(height: 12),
                  scene,
                ],
              );
            },
            expanded: (context) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: ListView(
                        children: [
                          metricsPanel,
                          const SizedBox(height: 12),
                          controls,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: scene),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _applyRefreshRate(BuildContext context) {
    final parsed = _refreshRateParser.parse(_refreshController.text);
    if (parsed.isFailure) {
      final message = parsed.failure?.message ?? 'Invalid refresh rate';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    _monitor.applyTargetRefreshRate(parsed.data!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Target refresh rate set to ${parsed.data} Hz')),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.refreshController,
    required this.particleCount,
    required this.workloadLevel,
    required this.colorShift,
    required this.onParticleChanged,
    required this.onWorkloadChanged,
    required this.onColorShiftChanged,
    required this.onApplyRefreshRate,
  });

  final TextEditingController refreshController;
  final double particleCount;
  final double workloadLevel;
  final bool colorShift;
  final ValueChanged<double> onParticleChanged;
  final ValueChanged<double> onWorkloadChanged;
  final ValueChanged<bool> onColorShiftChanged;
  final VoidCallback onApplyRefreshRate;

  @override
  Widget build(BuildContext context) {
    return CommonSectionCard(
      title: 'Scenario controls',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Particle count: ${particleCount.round()}'),
          Slider(
            value: particleCount,
            min: 100,
            max: 1200,
            divisions: 22,
            label: '${particleCount.round()}',
            onChanged: onParticleChanged,
          ),
          const SizedBox(height: 4),
          Text('Workload level: ${workloadLevel.round()}x'),
          Slider(
            value: workloadLevel,
            min: 1,
            max: 6,
            divisions: 5,
            label: '${workloadLevel.round()}x',
            onChanged: onWorkloadChanged,
          ),
          SwitchListTile(
            value: colorShift,
            onChanged: onColorShiftChanged,
            title: const Text('Enable color shift'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: refreshController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target refresh rate (Hz)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onApplyRefreshRate,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  runApp(const ToolkitExampleApp());
}

class ToolkitExampleApp extends StatelessWidget {
  const ToolkitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vsync_lab_toolkit example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ToolkitExampleHomePage(),
    );
  }
}

class ToolkitExampleHomePage extends StatefulWidget {
  const ToolkitExampleHomePage({super.key});

  @override
  State<ToolkitExampleHomePage> createState() => _ToolkitExampleHomePageState();
}

class _ToolkitExampleHomePageState extends State<ToolkitExampleHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final FrameTimingMonitor _monitor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _monitor = FrameTimingMonitor(
      targetRefreshRate: 60,
      scenario: 'toolkit_example',
      scenarioSettingsBuilder: () => <String, dynamic>{
        'screen': 'example',
        'animationActive': _animationController.isAnimating,
      },
    )..start();
  }

  @override
  void dispose() {
    _monitor
      ..stop()
      ..dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveFrameLog() async {
    try {
      final result = await _monitor.saveObservabilityLog();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${result.latestAbsolutePath}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    }
  }

  void _toggleMonitor() {
    if (_monitor.isRunning) {
      _monitor.stop();
      return;
    }
    _monitor.start();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _monitor,
      builder: (context, _) {
        final snapshot = _monitor.snapshot;
        final lastSave = _monitor.lastFrameLogSaveResult;

        return Scaffold(
          appBar: AppBar(title: const Text('vsync_lab_toolkit example')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FrameTimingMonitor initialized in initState() and started immediately.',
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: RotationTransition(
                          turns: _animationController,
                          child: const Icon(Icons.refresh, size: 72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricChip(
                            label: 'Running',
                            value: _monitor.isRunning ? 'Yes' : 'No',
                          ),
                          _MetricChip(
                            label: 'Samples',
                            value: '${snapshot.sampleCount}',
                          ),
                          _MetricChip(
                            label: 'Avg FPS',
                            value: snapshot.averageFps.toStringAsFixed(1),
                          ),
                          _MetricChip(
                            label: '1% Low',
                            value: snapshot.low1PercentFps.toStringAsFixed(1),
                          ),
                          _MetricChip(
                            label: 'Jank',
                            value:
                                '${(snapshot.jankRatio * 100).toStringAsFixed(1)}%',
                          ),
                          _MetricChip(
                            label: 'Frame log records',
                            value: '${_monitor.observabilityRecordCount}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _toggleMonitor,
                    icon: Icon(
                      _monitor.isRunning ? Icons.pause : Icons.play_arrow,
                    ),
                    label: Text(
                      _monitor.isRunning ? 'Pause monitor' : 'Start monitor',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _monitor.reset,
                    icon: const Icon(Icons.replay),
                    label: const Text('Reset metrics'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saveFrameLog,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save frame log'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Latest save result'),
                      const SizedBox(height: 8),
                      Text(lastSave?.latestAbsolutePath ??
                          'No frame log saved yet.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

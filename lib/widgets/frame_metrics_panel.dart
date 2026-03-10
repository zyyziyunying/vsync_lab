import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

import '../metrics/frame_log_pull_command.dart';

class FrameMetricsPanel extends StatefulWidget {
  const FrameMetricsPanel({
    required this.snapshot,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
    this.onSaveObservabilityLog,
    this.observabilityRecordCount = 0,
    this.isSavingObservabilityLog = false,
    super.key,
  });

  final FrameMetricsSnapshot snapshot;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final Future<FrameLogSaveResult> Function()? onSaveObservabilityLog;
  final int observabilityRecordCount;
  final bool isSavingObservabilityLog;

  @override
  State<FrameMetricsPanel> createState() => _FrameMetricsPanelState();
}

class _FrameMetricsPanelState extends State<FrameMetricsPanel> {
  bool _isSaveActionInFlight = false;

  bool get _isSaveBusy =>
      widget.isSavingObservabilityLog || _isSaveActionInFlight;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final generatedAt = snapshot.generatedAt;
    final generatedAtText =
        '${generatedAt.toYmd()} ${_twoDigits(generatedAt.hour)}:${_twoDigits(generatedAt.minute)}:${_twoDigits(generatedAt.second)}';

    return CommonSectionCard(
      title: 'Live frame metrics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: 'Samples', value: '${snapshot.sampleCount}'),
              _MetricChip(
                  label: 'Avg FPS', value: _format(snapshot.averageFps)),
              _MetricChip(
                  label: '1% Low FPS', value: _format(snapshot.low1PercentFps)),
              _MetricChip(
                label: 'Jank ratio',
                value: '${(snapshot.jankRatio * 100).toStringAsFixed(1)}%',
              ),
              _MetricChip(
                label: 'Interval stddev',
                value:
                    '${snapshot.frameIntervalStdDevMs.toStringAsFixed(2)} ms',
              ),
              _MetricChip(
                  label: 'VSync misses', value: '${snapshot.vsyncMissCount}'),
              _MetricChip(
                label: 'Max miss streak',
                value: '${snapshot.maxConsecutiveVsyncMiss}',
              ),
              _MetricChip(
                label: 'UI avg',
                value: '${snapshot.averageUiThreadMs.toStringAsFixed(2)} ms',
              ),
              _MetricChip(
                label: 'Raster avg',
                value:
                    '${snapshot.averageRasterThreadMs.toStringAsFixed(2)} ms',
              ),
              _MetricChip(
                label: 'Frame budget',
                value: '${snapshot.frameBudgetMs.toStringAsFixed(2)} ms',
              ),
              _MetricChip(
                label: 'Target rate',
                value: '${snapshot.targetRefreshRate.toStringAsFixed(1)} Hz',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Last update: $generatedAtText'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: widget.onToggle,
                icon: Icon(widget.isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  widget.isRunning ? 'Pause monitor' : 'Start monitor',
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.replay),
                label: const Text('Reset metrics'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onSaveObservabilityLog == null || _isSaveBusy
                    ? null
                    : () => _saveObservabilityLog(context),
                icon: _isSaveBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(
                  _isSaveBusy
                      ? 'Saving frame log...'
                      : 'Save frame log (${widget.observabilityRecordCount})',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveObservabilityLog(BuildContext context) async {
    final saver = widget.onSaveObservabilityLog;
    if (saver == null || _isSaveBusy) {
      return;
    }

    setState(() {
      _isSaveActionInFlight = true;
    });

    try {
      final result = await saver();
      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final analysisCommand = buildFrameLogAnalysisCommand(result);
          final pullCommand = buildFrameLogPullCommand(result);

          return AlertDialog(
            title: const Text('Frame log saved'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest file: ${result.latestAbsolutePath}'),
                  const SizedBox(height: 8),
                  Text('Archive file: ${result.archivedAbsolutePath}'),
                  const SizedBox(height: 16),
                  const Text('Recommended analysis command:'),
                  const SizedBox(height: 8),
                  SelectableText(analysisCommand),
                  const SizedBox(height: 16),
                  const Text('Manual adb pull command:'),
                  const SizedBox(height: 8),
                  SelectableText(pullCommand),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save frame log: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaveActionInFlight = false;
        });
      }
    }
  }

  static String _format(double value) {
    if (value == 0) {
      return '0';
    }
    return value.toStringAsFixed(1);
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.speed, size: 16),
      label: Text('$label: $value'),
    );
  }
}

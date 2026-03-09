import 'package:common/common.dart';
import 'package:flutter/material.dart';

import '../metrics/frame_log_file_exporter.dart';
import '../metrics/frame_metrics_snapshot.dart';

class FrameMetricsPanel extends StatelessWidget {
  const FrameMetricsPanel({
    required this.snapshot,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
    this.onSaveObservabilityLog,
    this.observabilityRecordCount = 0,
    super.key,
  });

  final FrameMetricsSnapshot snapshot;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final Future<FrameLogSaveResult> Function()? onSaveObservabilityLog;
  final int observabilityRecordCount;

  @override
  Widget build(BuildContext context) {
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
                onPressed: onToggle,
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(isRunning ? 'Pause monitor' : 'Start monitor'),
              ),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.replay),
                label: const Text('Reset metrics'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveObservabilityLog == null
                    ? null
                    : () => _saveObservabilityLog(context),
                icon: const Icon(Icons.save_alt),
                label: Text('Save frame log ($observabilityRecordCount)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveObservabilityLog(BuildContext context) async {
    final saver = onSaveObservabilityLog;
    if (saver == null) {
      return;
    }

    try {
      final result = await saver();
      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
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
                  const Text('Pull the latest file to your computer with:'),
                  const SizedBox(height: 8),
                  SelectableText(result.buildAdbPullCommand()),
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

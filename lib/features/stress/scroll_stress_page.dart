import 'dart:async';

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

import '../../routes/app_routes.dart';
import '../../widgets/frame_metrics_panel.dart';
import 'refresh_rate_parser.dart';
import 'widgets/scroll_stress_scene.dart';

class ScrollStressPage extends StatefulWidget {
  const ScrollStressPage({super.key});

  @override
  State<ScrollStressPage> createState() => _ScrollStressPageState();
}

class _ScrollStressPageState extends State<ScrollStressPage> {
  final _scrollController = ScrollController();
  final _refreshController = TextEditingController(text: '60');
  final _refreshRateParser = const RefreshRateParser();

  late final FrameTimingMonitor _monitor;
  Timer? _autoScrollTimer;

  double _itemCount = 1400;
  bool _autoScroll = true;
  bool _enableBlur = false;
  bool _scrollToBottom = true;

  @override
  void initState() {
    super.initState();
    _monitor = FrameTimingMonitor(
      targetRefreshRate: 60,
      scenario: 'scroll',
      scenarioSettingsBuilder: () => <String, Object?>{
        'itemCount': _itemCount.round(),
        'autoScroll': _autoScroll,
        'enableBlur': _enableBlur,
      },
    );
    _monitor.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureAutoScroll();
    });
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
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
          isSavingObservabilityLog: _monitor.isSavingObservabilityLog,
          observabilityRecordCount: _monitor.observabilityRecordCount,
          onSaveObservabilityLog: () => _monitor.saveObservabilityLog(),
        );

        final controls = _ControlsCard(
          itemCount: _itemCount,
          autoScroll: _autoScroll,
          enableBlur: _enableBlur,
          refreshController: _refreshController,
          onItemCountChanged: (value) {
            setState(() {
              _itemCount = value;
            });
          },
          onAutoScrollChanged: (value) {
            setState(() {
              _autoScroll = value;
            });
            _configureAutoScroll();
          },
          onBlurChanged: (value) {
            setState(() {
              _enableBlur = value;
            });
          },
          onApplyRefreshRate: () => _applyRefreshRate(context),
        );

        final scene = CommonSectionCard(
          title: 'Scroll scene',
          child: SizedBox(
            height: 420,
            child: ScrollStressScene(
              controller: _scrollController,
              itemCount: _itemCount.round(),
              enableBlur: _enableBlur,
            ),
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Scroll stress'),
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

  void _configureAutoScroll() {
    if (_autoScroll) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final targetOffset = _scrollToBottom ? position.maxScrollExtent : 0.0;
      _scrollToBottom = !_scrollToBottom;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 2200),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
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
      SnackBar(
        content: Text(
          'Target refresh rate set to ${parsed.data} Hz. Metrics reset.',
        ),
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.itemCount,
    required this.autoScroll,
    required this.enableBlur,
    required this.refreshController,
    required this.onItemCountChanged,
    required this.onAutoScrollChanged,
    required this.onBlurChanged,
    required this.onApplyRefreshRate,
  });

  final double itemCount;
  final bool autoScroll;
  final bool enableBlur;
  final TextEditingController refreshController;
  final ValueChanged<double> onItemCountChanged;
  final ValueChanged<bool> onAutoScrollChanged;
  final ValueChanged<bool> onBlurChanged;
  final VoidCallback onApplyRefreshRate;

  @override
  Widget build(BuildContext context) {
    return CommonSectionCard(
      title: 'Scenario controls',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('List item count: ${itemCount.round()}'),
          Slider(
            value: itemCount,
            min: 200,
            max: 5000,
            divisions: 24,
            label: '${itemCount.round()}',
            onChanged: onItemCountChanged,
          ),
          SwitchListTile(
            value: autoScroll,
            onChanged: onAutoScrollChanged,
            title: const Text('Enable auto-scroll loop'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: enableBlur,
            onChanged: onBlurChanged,
            title: const Text('Enable blur on half of rows'),
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

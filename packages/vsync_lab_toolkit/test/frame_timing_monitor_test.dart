import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  test('auto-saves once when frame log buffer becomes full', () async {
    final exporter = _FakeFrameLogExporter(resultScenario: 'animation');
    final monitor = FrameTimingMonitor(
      targetRefreshRate: 60,
      maxLogRecords: 2,
      scenario: 'animation',
      exporter: exporter,
    );

    monitor.addSample(
      frameEndUs: 1000000,
      buildUs: 3000,
      rasterUs: 2000,
      totalUs: 7000,
    );
    monitor.addSample(
      frameEndUs: 1016667,
      buildUs: 4000,
      rasterUs: 2500,
      totalUs: 17000,
    );

    await Future<void>.delayed(Duration.zero);

    expect(exporter.savedLogs.length, 1);
    expect(monitor.hasAutoSavedCurrentBuffer, isTrue);
    expect(monitor.lastFrameLogSaveResult?.scenario, 'animation');

    monitor.addSample(
      frameEndUs: 1033334,
      buildUs: 4200,
      rasterUs: 2600,
      totalUs: 18000,
    );
    await Future<void>.delayed(Duration.zero);

    expect(exporter.savedLogs.length, 1);
  });

  test('re-arms auto-save after reset', () async {
    final exporter = _FakeFrameLogExporter(resultScenario: 'scroll');
    final monitor = FrameTimingMonitor(
      targetRefreshRate: 60,
      maxLogRecords: 2,
      scenario: 'scroll',
      exporter: exporter,
    );

    monitor.addSample(
      frameEndUs: 1000000,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );
    monitor.addSample(
      frameEndUs: 1016667,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );
    await Future<void>.delayed(Duration.zero);

    monitor.reset();

    monitor.addSample(
      frameEndUs: 2000000,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );
    monitor.addSample(
      frameEndUs: 2016667,
      buildUs: 2000,
      rasterUs: 2000,
      totalUs: 5000,
    );
    await Future<void>.delayed(Duration.zero);

    expect(exporter.savedLogs.length, 2);
    expect(monitor.lastFrameLogSaveResult?.scenario, 'scroll');
  });
}

class _FakeFrameLogExporter implements FrameLogExporter {
  _FakeFrameLogExporter({required this.resultScenario});

  final String resultScenario;
  final List<Map<String, dynamic>> savedLogs = <Map<String, dynamic>>[];

  @override
  Future<FrameLogSaveResult> save(Map<String, dynamic> log) async {
    savedLogs.add(log);
    return FrameLogSaveResult(
      scenario: resultScenario,
      latestFileName: 'frame_log_${resultScenario}_latest.json',
      archivedFileName: 'frame_log_${resultScenario}_20260309_120000.json',
      cacheDirectoryPath: '/tmp',
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab/metrics/frame_log_pull_command.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  const result = FrameLogSaveResult(
    scenario: 'animation',
    latestFileName: 'frame_log_animation_latest.json',
    archivedFileName: 'frame_log_animation_20260309_120000.json',
    cacheDirectoryPath: '/data/user/0/com.harrypet.vsync_lab/cache',
  );

  test('builds repository adb pull command in app layer', () {
    expect(
      buildFrameLogPullCommand(result),
      'adb exec-out run-as com.harrypet.vsync_lab cat '
      '/data/user/0/com.harrypet.vsync_lab/cache/frame_log_animation_latest.json > '
      'artifacts/frame_log_animation_latest.json',
    );
  });

  test('builds recommended analysis script command', () {
    expect(
      buildFrameLogAnalysisCommand(result),
      './scripts/pull_and_analyze_frame_log.ps1 -Scenario animation',
    );
  });
}

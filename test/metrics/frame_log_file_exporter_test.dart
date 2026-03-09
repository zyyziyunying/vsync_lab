import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab/metrics/frame_log_file_exporter.dart';

void main() {
  test('builds adb pull command with absolute cache path', () {
    const result = FrameLogSaveResult(
      scenario: 'animation',
      latestFileName: 'frame_log_animation_latest.json',
      archivedFileName: 'frame_log_animation_20260309_120000.json',
      cacheDirectoryPath: '/data/user/0/com.harrypet.vsync_lab/cache',
    );

    expect(
      result.latestAbsolutePath,
      '/data/user/0/com.harrypet.vsync_lab/cache/frame_log_animation_latest.json',
    );
    expect(
      result.archivedAbsolutePath,
      '/data/user/0/com.harrypet.vsync_lab/cache/frame_log_animation_20260309_120000.json',
    );
    expect(
      result.buildAdbPullCommand(),
      'adb exec-out run-as com.harrypet.vsync_lab cat '
      '/data/user/0/com.harrypet.vsync_lab/cache/frame_log_animation_latest.json > '
      'artifacts/frame_log_animation_latest.json',
    );
  });
}

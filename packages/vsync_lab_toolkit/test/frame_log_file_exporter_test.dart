import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  test('exposes frame log paths without repo-specific pull command logic', () {
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
  });
}

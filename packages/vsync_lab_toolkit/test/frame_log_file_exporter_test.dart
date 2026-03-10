import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

void main() {
  late PathProviderPlatform originalPathProviderPlatform;
  late Directory temporaryDirectory;

  setUp(() {
    originalPathProviderPlatform = PathProviderPlatform.instance;
    temporaryDirectory =
        Directory.systemTemp.createTempSync('vsync_lab_toolkit_test_');
    PathProviderPlatform.instance =
        _FakePathProviderPlatform(temporaryDirectory.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProviderPlatform;
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

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

  test('uses a unique archived file name when saves share the same timestamp',
      () async {
    final exporter = FrameLogFileExporter(
      now: () => DateTime.utc(2026, 3, 10, 12, 0, 0),
    );
    final log = <String, Object?>{
      'scenario': 'Animation',
      'snapshot': <String, Object?>{},
      'records': <Object?>[],
    };

    final first = await exporter.save(log);
    final second = await exporter.save(log);

    expect(first.latestFileName, 'frame_log_animation_latest.json');
    expect(
      first.archivedFileName,
      'frame_log_animation_20260310_120000_000000.json',
    );
    expect(
      second.archivedFileName,
      'frame_log_animation_20260310_120000_000000_1.json',
    );
    expect(first.archivedFileName, isNot(second.archivedFileName));
    expect(
      File('${temporaryDirectory.path}/${first.archivedFileName}').existsSync(),
      isTrue,
    );
    expect(
      File('${temporaryDirectory.path}/${second.archivedFileName}')
          .existsSync(),
      isTrue,
    );

    final latestFile =
        File('${temporaryDirectory.path}/${first.latestFileName}');
    final latestData = jsonDecode(await latestFile.readAsString());
    expect(latestData['scenario'], 'Animation');
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.temporaryPath);

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

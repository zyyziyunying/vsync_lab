import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class FrameLogExporter {
  Future<FrameLogSaveResult> save(Map<String, Object?> log);
}

class FrameLogSaveResult {
  const FrameLogSaveResult({
    required this.scenario,
    required this.latestFileName,
    required this.archivedFileName,
    required this.cacheDirectoryPath,
  });

  final String scenario;
  final String latestFileName;
  final String archivedFileName;
  final String cacheDirectoryPath;

  String get latestRelativePath => 'cache/$latestFileName';
  String get archivedRelativePath => 'cache/$archivedFileName';
  String get latestAbsolutePath => '$cacheDirectoryPath/$latestFileName';
  String get archivedAbsolutePath => '$cacheDirectoryPath/$archivedFileName';
}

class FrameLogFileExporter implements FrameLogExporter {
  const FrameLogFileExporter({
    DateTime Function() now = _systemNow,
  }) : _now = now;

  final DateTime Function() _now;

  @override
  Future<FrameLogSaveResult> save(Map<String, Object?> log) async {
    final scenario = _sanitizeScenario(log['scenario'] as String?);
    final now = _now();
    final timestamp = _buildTimestamp(now);
    final latestFileName = 'frame_log_${scenario}_latest.json';
    final cacheDirectory = await getTemporaryDirectory();
    final archivedFileName = await _buildUniqueArchivedFileName(
      cacheDirectoryPath: cacheDirectory.path,
      scenario: scenario,
      timestamp: timestamp,
    );
    final payload = '${const JsonEncoder.withIndent('  ').convert(log)}\n';

    await File('${cacheDirectory.path}/$latestFileName').writeAsString(payload);
    await File('${cacheDirectory.path}/$archivedFileName')
        .writeAsString(payload);

    return FrameLogSaveResult(
      scenario: scenario,
      latestFileName: latestFileName,
      archivedFileName: archivedFileName,
      cacheDirectoryPath: cacheDirectory.path,
    );
  }

  static String _sanitizeScenario(String? value) {
    final normalized = (value ?? 'unknown').trim().toLowerCase();
    final replaced = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return replaced.replaceAll(RegExp(r'^_+|_+$'), '').isEmpty
        ? 'unknown'
        : replaced.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static DateTime _systemNow() => DateTime.now();

  static String _buildTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    String threeDigits(int number) => number.toString().padLeft(3, '0');

    return '${value.year}'
        '${twoDigits(value.month)}'
        '${twoDigits(value.day)}_'
        '${twoDigits(value.hour)}'
        '${twoDigits(value.minute)}'
        '${twoDigits(value.second)}_'
        '${threeDigits(value.millisecond)}'
        '${threeDigits(value.microsecond)}';
  }

  static Future<String> _buildUniqueArchivedFileName({
    required String cacheDirectoryPath,
    required String scenario,
    required String timestamp,
  }) async {
    final baseName = 'frame_log_${scenario}_$timestamp';
    var suffix = 0;

    while (true) {
      final candidate =
          suffix == 0 ? '$baseName.json' : '${baseName}_$suffix.json';
      final candidatePath = '$cacheDirectoryPath/$candidate';
      if (!await File(candidatePath).exists()) {
        return candidate;
      }
      suffix++;
    }
  }
}

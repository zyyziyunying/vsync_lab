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
  const FrameLogFileExporter();

  @override
  Future<FrameLogSaveResult> save(Map<String, Object?> log) async {
    final scenario = _sanitizeScenario(log['scenario'] as String?);
    final now = DateTime.now();
    final timestamp = _buildTimestamp(now);
    final latestFileName = 'frame_log_${scenario}_latest.json';
    final archivedFileName = 'frame_log_${scenario}_$timestamp.json';
    final cacheDirectory = await getTemporaryDirectory();
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

  static String _buildTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${value.year}'
        '${twoDigits(value.month)}'
        '${twoDigits(value.day)}_'
        '${twoDigits(value.hour)}'
        '${twoDigits(value.minute)}'
        '${twoDigits(value.second)}';
  }
}

import 'package:vsync_lab_toolkit/vsync_lab_toolkit.dart';

const String vsyncLabPackageName = 'com.harrypet.vsync_lab';
const String frameLogArtifactsDirectory = 'artifacts';
const String frameLogAnalysisScriptPath =
    './scripts/pull_and_analyze_frame_log.ps1';

String buildFrameLogPullCommand(
  FrameLogSaveResult result, {
  String packageName = vsyncLabPackageName,
  String? outputPath,
}) {
  final resolvedOutputPath =
      outputPath ?? '$frameLogArtifactsDirectory/${result.latestFileName}';
  return 'adb exec-out run-as $packageName cat ${result.latestAbsolutePath} > '
      '$resolvedOutputPath';
}

String buildFrameLogAnalysisCommand(
  FrameLogSaveResult result, {
  String scriptPath = frameLogAnalysisScriptPath,
}) {
  return '$scriptPath -Scenario ${result.scenario}';
}

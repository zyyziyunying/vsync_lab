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

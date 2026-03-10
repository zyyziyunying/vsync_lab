import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('README and docs stay aligned with the current save flow', () async {
    final readme = await File('README.md').readAsString();
    final docsReadme = await File('docs/README.md').readAsString();
    final panelSource =
        await File('lib/widgets/frame_metrics_panel.dart').readAsString();

    expect(readme, contains('Save frame log'));
    expect(readme, isNot(contains('Copy JSON')));
    expect(readme, isNot(contains('Copy frame log')));

    expect(docsReadme, contains('Save frame log'));
    expect(panelSource, contains('Save frame log'));
    expect(panelSource, isNot(contains('Copy frame log')));

    for (final path in <String>[
      'docs/device_matrix.md',
      'docs/experiment_log_template.md',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path should exist.');
      expect(readme, contains(path));
      expect(docsReadme, contains(path));
    }
  });
}

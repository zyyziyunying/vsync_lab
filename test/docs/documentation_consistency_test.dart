import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('README and docs stay aligned with the current save flow', () async {
    final readme = await File('README.md').readAsString();
    final docsReadme = await File('docs/README.md').readAsString();
    final experimentTemplate = await File(
      'docs/experiment_log_template.md',
    ).readAsString();
    final deviceMatrix = await File('docs/device_matrix.md').readAsString();
    final panelSource = await File(
      'lib/widgets/frame_metrics_panel.dart',
    ).readAsString();

    expect(readme, contains('Save frame log'));
    expect(readme, isNot(contains('Copy JSON')));
    expect(readme, isNot(contains('Copy frame log')));

    expect(docsReadme, contains('Save frame log'));
    expect(panelSource, contains('Save frame log'));
    expect(panelSource, isNot(contains('Copy frame log')));

    for (final fileName in <String>[
      'device_matrix.md',
      'experiment_log_template.md',
    ]) {
      expect(
        File('docs/$fileName').existsSync(),
        isTrue,
        reason: '$fileName should exist under docs.',
      );
      expect(readme, contains(fileName));
      expect(docsReadme, contains(fileName));
    }

    for (final pathStyleReference in <String>[
      'docs/device_matrix.md',
      'docs/experiment_log_template.md',
    ]) {
      expect(readme, isNot(contains(pathStyleReference)));
      expect(docsReadme, isNot(contains(pathStyleReference)));
    }

    expect(
      experimentTemplate,
      contains('[device_matrix.md](device_matrix.md)'),
    );
    expect(
      deviceMatrix,
      contains('[experiment_log_template.md](experiment_log_template.md)'),
    );
  });
}

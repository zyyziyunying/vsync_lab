import 'package:flutter/material.dart';

import 'widgets/diagnosis_page_scaffold.dart';

class StateCommitScenarioPage extends StatefulWidget {
  const StateCommitScenarioPage({super.key});

  @override
  State<StateCommitScenarioPage> createState() =>
      _StateCommitScenarioPageState();
}

class _StateCommitScenarioPageState extends State<StateCommitScenarioPage> {
  String _logicalState = 'A';
  int _intentCount = 0;

  @override
  Widget build(BuildContext context) {
    final accentColor = _logicalState == 'A'
        ? const Color(0xFF2A9D8F)
        : const Color(0xFFE76F51);

    return DiagnosisPageScaffold(
      title: 'State Commit Scenario',
      subtitle:
          'Phase A keeps this page intentionally simple: a visible A/B state surface with the observability slots reserved for binding, build, paint, and post-frame probes.',
      experiment: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual state $_logicalState',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This viewport becomes the release-only repro surface for same-page state transitions.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _logicalState = _logicalState == 'A' ? 'B' : 'A';
                    _intentCount += 1;
                  });
                },
                icon: const Icon(Icons.sync_alt),
                label: const Text('Toggle logical state'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _logicalState = 'A';
                    _intentCount = 0;
                  });
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset scenario'),
              ),
            ],
          ),
        ],
      ),
      observability: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiagnosisValueRow(label: 'Logical state', value: _logicalState),
          DiagnosisValueRow(label: 'Intent count', value: '$_intentCount'),
          const DiagnosisValueRow(
            label: 'Last build state',
            value: 'Phase B hook pending',
          ),
          const DiagnosisValueRow(
            label: 'Last paint state',
            value: 'Phase B hook pending',
          ),
          const DiagnosisValueRow(
            label: 'Last post-frame state',
            value: 'Phase B hook pending',
          ),
          const SizedBox(height: 12),
          const Text(
            'Next step: wire this page into the unified event timeline so each toggle records intent, setState, build, paint, and post-frame delivery.',
          ),
        ],
      ),
      controls: const DiagnosisPlannedControls(
        note:
            'Manual frame requests and continuous pumping stay disabled until the Phase B binding probes are wired in.',
      ),
    );
  }
}

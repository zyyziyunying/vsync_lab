import 'package:flutter/material.dart';

import '../../frame_diagnosis/frame_diagnosis_routes.dart';
import 'widgets/diagnosis_page_scaffold.dart';

class FrameDiagnosisHomePage extends StatelessWidget {
  const FrameDiagnosisHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frame Commit Diagnosis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DiagnosisSectionCard(
            title: 'Release-first startup',
            subtitle:
                'This app boots directly into the diagnosis workspace and keeps the legacy stress lab outside the default startup path.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusPill(
                  icon: Icons.android,
                  label: 'Baseline: Android 10 / API 29',
                ),
                const SizedBox(height: 10),
                _StatusPill(
                  icon: Icons.rocket_launch,
                  label: 'Validation mode: release on device',
                ),
                const SizedBox(height: 10),
                _StatusPill(
                  icon: Icons.alt_route,
                  label:
                      'Phase A: independent app shell and scenario skeletons',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;
              final cards = [
                _ScenarioCard(
                  title: 'State Commit Scenario',
                  description:
                      'Prepare the same-page A/B state transition lab where logic can advance ahead of visual commit.',
                  buttonLabel: 'Open state commit scenario',
                  icon: Icons.flip,
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamed(FrameDiagnosisRoutePath.stateCommit);
                  },
                ),
                _ScenarioCard(
                  title: 'Route Commit Scenario',
                  description:
                      'Prepare the route A -> B transition lab where Navigator state can move before the painted route catches up.',
                  buttonLabel: 'Open route commit scenario',
                  icon: Icons.route,
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamed(FrameDiagnosisRoutePath.routeCommit);
                  },
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 16),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards.first),
                  const SizedBox(width: 16),
                  Expanded(child: cards.last),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const DiagnosisSectionCard(
            title: 'Phase A boundaries',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This phase only lands the standalone diagnosis shell.'),
                SizedBox(height: 8),
                Text(
                  'Binding timeline hooks and force-frame controls arrive in Phase B.',
                ),
                SizedBox(height: 8),
                Text(
                  'Legacy stress pages remain in the repository but are intentionally decoupled from this app.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DiagnosisSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(description),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

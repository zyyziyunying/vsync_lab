import 'package:flutter/material.dart';

class DiagnosisPageScaffold extends StatelessWidget {
  const DiagnosisPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.experiment,
    required this.observability,
    required this.controls,
  });

  final String title;
  final String subtitle;
  final Widget experiment;
  final Widget observability;
  final Widget controls;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final header = Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          );

          if (constraints.maxWidth < 960) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                header,
                DiagnosisSectionCard(
                  title: 'Experiment viewport',
                  child: experiment,
                ),
                const SizedBox(height: 16),
                DiagnosisSectionCard(
                  title: 'Observability panel',
                  child: observability,
                ),
                const SizedBox(height: 16),
                DiagnosisSectionCard(title: 'Controls', child: controls),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: DiagnosisSectionCard(
                          title: 'Experiment viewport',
                          child: experiment,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Expanded(
                              child: DiagnosisSectionCard(
                                title: 'Observability panel',
                                child: observability,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DiagnosisSectionCard(
                              title: 'Controls',
                              child: controls,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DiagnosisSectionCard extends StatelessWidget {
  const DiagnosisSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class DiagnosisValueRow extends StatelessWidget {
  const DiagnosisValueRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosisPlannedControls extends StatelessWidget {
  const DiagnosisPlannedControls({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Force scheduleFrame (Phase B)'),
        ),
        const SizedBox(height: 12),
        const SwitchListTile(
          value: false,
          onChanged: null,
          contentPadding: EdgeInsets.zero,
          title: Text('Keep frames pumping (Phase B)'),
          subtitle: Text('Pending binding integration.'),
        ),
        Text(
          note,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

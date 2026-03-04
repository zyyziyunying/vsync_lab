import 'package:common/common.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VSync Lab (Android only)'),
      ),
      body: CommonAdaptiveLayout(
        compact: (context) => _buildCompact(context, now),
        expanded: (context) => _buildExpanded(context, now),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, DateTime now) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewCard(now: now),
        const SizedBox(height: 12),
        _QuickActionsCard(compact: true),
        const SizedBox(height: 12),
        const _PhaseGuideCard(),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context, DateTime now) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 5,
            child: _QuickActionsCard(compact: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _OverviewCard(now: now),
                const SizedBox(height: 12),
                const _PhaseGuideCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CommonSectionCard(
      title: 'Stress scenarios',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () {
              NavigatorManager.pushNamed(AppRouteName.animation);
            },
            icon: const Icon(Icons.animation),
            label: const Text('Open animation stress'),
          ),
          FilledButton.icon(
            onPressed: () {
              NavigatorManager.pushNamed(AppRouteName.scroll);
            },
            icon: const Icon(Icons.list_alt),
            label: const Text('Open scroll stress'),
          ),
          if (!compact)
            OutlinedButton.icon(
              onPressed: () {
                NavigatorManager.goNamed(AppRouteName.home);
              },
              icon: const Icon(Icons.home),
              label: const Text('Stay on dashboard'),
            ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return CommonSectionCard(
      title: 'Experiment baseline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date: ${now.toYmd()}'),
          const SizedBox(height: 6),
          const Text('Target Android baseline: API 29 (Android 10).'),
          const SizedBox(height: 6),
          const Text(
            'Goal: make VSync miss and jank observable before strategy tuning.',
          ),
        ],
      ),
    );
  }
}

class _PhaseGuideCard extends StatelessWidget {
  const _PhaseGuideCard();

  @override
  Widget build(BuildContext context) {
    return const CommonSectionCard(
      title: 'Phase 0 checklist',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '1) Run animation stress for 20-30 seconds and capture metrics JSON.'),
          SizedBox(height: 6),
          Text(
              '2) Run scroll stress with auto-scroll enabled for 20-30 seconds.'),
          SizedBox(height: 6),
          Text(
              '3) Pull gfxinfo and Perfetto traces, then fill the experiment template.'),
        ],
      ),
    );
  }
}

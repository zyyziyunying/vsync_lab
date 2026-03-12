import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/diagnosis_page_scaffold.dart';

class RouteCommitScenarioPage extends StatefulWidget {
  const RouteCommitScenarioPage({super.key});

  @override
  State<RouteCommitScenarioPage> createState() =>
      _RouteCommitScenarioPageState();
}

class _RouteCommitScenarioPageState extends State<RouteCommitScenarioPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<int> _routeBLogicTicks = ValueNotifier<int>(0);

  String _logicalRoute = 'Route A';
  String _navigatorTopRoute = 'Route A';
  int _transitionCount = 0;
  Timer? _routeBTimer;

  @override
  void dispose() {
    _routeBTimer?.cancel();
    _routeBLogicTicks.dispose();
    super.dispose();
  }

  void _pushRouteB() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || _logicalRoute == 'Route B') {
      return;
    }

    setState(() {
      _logicalRoute = 'Route B';
      _transitionCount += 1;
    });
    navigator.pushNamed(_RouteViewportPath.routeB);
  }

  void _popToRouteA() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || _logicalRoute == 'Route A') {
      return;
    }

    setState(() {
      _logicalRoute = 'Route A';
      _transitionCount += 1;
    });
    navigator.pop();
  }

  void _resetScenario() {
    _routeBTimer?.cancel();
    _routeBTimer = null;
    _routeBLogicTicks.value = 0;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _logicalRoute = 'Route A';
      _navigatorTopRoute = 'Route A';
      _transitionCount = 0;
    });
  }

  void _handleViewportRouteChanged(String routeLabel) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _navigatorTopRoute = routeLabel;
      });

      if (routeLabel == 'Route B') {
        _routeBTimer ??= Timer.periodic(
          const Duration(milliseconds: 400),
          (_) => _routeBLogicTicks.value += 1,
        );
        return;
      }

      _routeBTimer?.cancel();
      _routeBTimer = null;
    });
  }

  Route<dynamic> _buildViewportRoute(RouteSettings settings) {
    switch (settings.name) {
      case _RouteViewportPath.routeB:
        return MaterialPageRoute<void>(
          builder: (context) => _RouteViewportB(
            logicTicks: _routeBLogicTicks,
            onPopToRouteA: _popToRouteA,
          ),
          settings: settings,
        );
      case _RouteViewportPath.routeA:
      default:
        return MaterialPageRoute<void>(
          builder: (context) => _RouteViewportA(onPushRouteB: _pushRouteB),
          settings: const RouteSettings(name: _RouteViewportPath.routeA),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DiagnosisPageScaffold(
      title: 'Route Commit Scenario',
      subtitle:
          'Phase A keeps the route repro independent from the legacy stress app and reserves space for navigator, build, paint, and last-painted-route probes.',
      experiment: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 280,
              child: Navigator(
                key: _navigatorKey,
                initialRoute: _RouteViewportPath.routeA,
                observers: <NavigatorObserver>[
                  _RouteViewportObserver(
                    onRouteChanged: _handleViewportRouteChanged,
                  ),
                ],
                onGenerateRoute: _buildViewportRoute,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _pushRouteB,
                icon: const Icon(Icons.route),
                label: const Text('Intent push Route B'),
              ),
              OutlinedButton.icon(
                onPressed: _resetScenario,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset route scenario'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This Phase A skeleton now performs a real nested Navigator transition so route intent and actual top route can diverge in the panel.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      observability: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiagnosisValueRow(label: 'Logical route', value: _logicalRoute),
          DiagnosisValueRow(
            label: 'Navigator top route',
            value: _navigatorTopRoute,
          ),
          DiagnosisValueRow(
            label: 'Transition count',
            value: '$_transitionCount',
          ),
          ValueListenableBuilder<int>(
            valueListenable: _routeBLogicTicks,
            builder: (context, value, child) {
              return DiagnosisValueRow(
                label: 'Route B logic ticks',
                value: '$value',
              );
            },
          ),
          const DiagnosisValueRow(
            label: 'Last build route',
            value: 'Phase B hook pending',
          ),
          const DiagnosisValueRow(
            label: 'Last painted route',
            value: 'Phase B hook pending',
          ),
          const SizedBox(height: 12),
          const Text(
            'Next step: add build and paint probes so the real route transition can be compared against the last committed frame.',
          ),
        ],
      ),
      controls: const DiagnosisPlannedControls(
        note:
            'Binding-level frame forcing stays disabled in Phase A, but the route viewport already exercises a real Route A -> Route B transition.',
      ),
    );
  }
}

class _RouteViewportPath {
  const _RouteViewportPath._();

  static const routeA = '/viewport-route-a';
  static const routeB = '/viewport-route-b';
}

class _RouteViewportObserver extends NavigatorObserver {
  _RouteViewportObserver({required this.onRouteChanged});

  final ValueChanged<String> onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onRouteChanged(_routeLabelFor(route));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onRouteChanged(_routeLabelFor(previousRoute));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    onRouteChanged(_routeLabelFor(newRoute));
  }

  String _routeLabelFor(Route<dynamic>? route) {
    return switch (route?.settings.name) {
      _RouteViewportPath.routeB => 'Route B',
      _ => 'Route A',
    };
  }
}

class _RouteViewportA extends StatelessWidget {
  const _RouteViewportA({required this.onPushRouteB});

  final VoidCallback onPushRouteB;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route A viewport',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is the visible Route A surface before the nested Navigator pushes Route B.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onPushRouteB,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Push Route B'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteViewportB extends StatelessWidget {
  const _RouteViewportB({
    required this.logicTicks,
    required this.onPopToRouteA,
  });

  final ValueNotifier<int> logicTicks;
  final VoidCallback onPopToRouteA;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route B viewport',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Route B starts its own logic ticker immediately after the push completes.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: logicTicks,
              builder: (context, value, child) {
                return Text(
                  'Route B logic ticks: $value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onPopToRouteA,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Pop to Route A'),
            ),
          ],
        ),
      ),
    );
  }
}

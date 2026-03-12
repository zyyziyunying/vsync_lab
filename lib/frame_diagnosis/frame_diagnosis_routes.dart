import 'package:flutter/material.dart';

import '../features/frame_diagnosis/frame_diagnosis_home_page.dart';
import '../features/frame_diagnosis/route_commit_scenario_page.dart';
import '../features/frame_diagnosis/state_commit_scenario_page.dart';

class FrameDiagnosisRoutePath {
  const FrameDiagnosisRoutePath._();

  static const home = '/';
  static const stateCommit = '/state-commit';
  static const routeCommit = '/route-commit';
}

Route<dynamic> buildFrameDiagnosisRoute(RouteSettings settings) {
  switch (settings.name) {
    case FrameDiagnosisRoutePath.home:
      return MaterialPageRoute<void>(
        builder: (context) => const FrameDiagnosisHomePage(),
        settings: settings,
      );
    case FrameDiagnosisRoutePath.stateCommit:
      return MaterialPageRoute<void>(
        builder: (context) => const StateCommitScenarioPage(),
        settings: settings,
      );
    case FrameDiagnosisRoutePath.routeCommit:
      return MaterialPageRoute<void>(
        builder: (context) => const RouteCommitScenarioPage(),
        settings: settings,
      );
    default:
      return MaterialPageRoute<void>(
        builder: (context) => const FrameDiagnosisHomePage(),
        settings: const RouteSettings(name: FrameDiagnosisRoutePath.home),
      );
  }
}

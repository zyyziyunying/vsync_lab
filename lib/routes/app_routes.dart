import 'package:common/common.dart';

import '../features/home/home_page.dart';
import '../features/stress/animation_stress_page.dart';
import '../features/stress/scroll_stress_page.dart';

class AppRouteName {
  const AppRouteName._();

  static const home = 'home';
  static const animation = 'animation';
  static const scroll = 'scroll';
}

class AppRoutePath {
  const AppRoutePath._();

  static const home = '/';
  static const animation = '/animation';
  static const scroll = '/scroll';
}

List<RouteBase> buildAppRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRouteName.home,
      path: AppRoutePath.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      name: AppRouteName.animation,
      path: AppRoutePath.animation,
      builder: (context, state) => const AnimationStressPage(),
    ),
    GoRoute(
      name: AppRouteName.scroll,
      path: AppRoutePath.scroll,
      builder: (context, state) => const ScrollStressPage(),
    ),
  ];
}

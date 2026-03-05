import 'package:common/common.dart';
import 'package:flutter/material.dart' hide RouterConfig;

import 'routes/app_routes.dart';

class VsyncLabApp extends StatelessWidget {
  const VsyncLabApp({super.key});

  static final GoRouter _router = RouterFactory.create(
    RouterConfiger(
      initialLocation: AppRoutePath.home,
      routes: buildAppRoutes(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VSync Lab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

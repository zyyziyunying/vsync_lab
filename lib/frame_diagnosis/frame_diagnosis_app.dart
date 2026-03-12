import 'package:flutter/material.dart';

import 'frame_diagnosis_routes.dart';

class FrameDiagnosisApp extends StatelessWidget {
  const FrameDiagnosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF15616D),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Frame Commit Diagnosis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      initialRoute: FrameDiagnosisRoutePath.home,
      onGenerateRoute: buildFrameDiagnosisRoute,
    );
  }
}

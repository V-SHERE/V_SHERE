import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VShereApp());
}

class VShereApp extends StatelessWidget {
  const VShereApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const accent = Color(0xFF00D9FF);
    final bg = isDark ? const Color(0xFF060A12) : const Color(0xFF0F172A);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(days: 365),
        showDuration: Duration.zero,
        decoration: BoxDecoration(color: Colors.transparent),
        textStyle: TextStyle(fontSize: 0, color: Colors.transparent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'V-Shere',
          themeMode: mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const MainShell(),
        );
      },
    );
  }
}
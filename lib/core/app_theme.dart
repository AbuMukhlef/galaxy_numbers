import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color bgDark     = Color(0xFF020818);
  static const Color neonCyan   = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFBB86FC);
  static const Color neonGreen  = Color(0xFF00E676);
  static const Color neonPink   = Color(0xFFFF4081);
  static const Color neonGold   = Color(0xFFFFD740);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    fontFamily: "Cairo",
    colorScheme: const ColorScheme.dark(
      primary: neonCyan, secondary: neonPurple,
      surface: Color(0xFF060E20), error: neonPink),
  );

  static void setSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: bgDark,
      systemNavigationBarIconBrightness: Brightness.light));
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
}

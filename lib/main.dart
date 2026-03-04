import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'core/app_providers.dart';
import 'services/hive_service.dart';

// TODO: استبدل هذه القيم من Supabase → Settings → API
const _supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const _supabaseKey = 'YOUR_ANON_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.setSystemUI();
  await HiveService.init();
  try {
    await Supabase.initialize(
      url: _supabaseUrl, anonKey: _supabaseKey, debug: false);
  } catch (_) {
    // وضع offline — Hive يتولى كل شيء محلياً
  }
  runApp(const GalaxyApp());
}

class GalaxyApp extends StatelessWidget {
  const GalaxyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: 'مجرة الأرقام',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,

        // دعم اللغتين العربية والإنجليزية
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // RTL عالمياً
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!),

        home: const AppRouter()));
  }
}

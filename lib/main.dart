import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/database_init.dart';
import 'screens/login_screen.dart';

void main() async {
  // Platform kontrolü ile databaseFactory'yi başlat
  // Web'de hiçbir şey yapmaz, desktop'ta sqflite_common_ffi başlatır
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  initDatabase();
  runApp(const KutuphaneApp());
}

class KutuphaneApp extends StatelessWidget {
  const KutuphaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kütüphane Masaüstü',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B4513),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF8B4513),
              secondary: const Color(0xFFD2691E),
              surface: const Color(0xFFFAF8F5),
              onSurface: const Color(0xFF2C1810),
            ),
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        fontFamily: 'Segoe UI',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4513),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.brown.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: const Color(0xFF3E2723),
          selectedIconTheme: const IconThemeData(
            color: Color(0xFFFFD54F),
            size: 28,
          ),
          unselectedIconTheme: IconThemeData(
            color: Colors.white.withValues(alpha: 0.7),
            size: 24,
          ),
          selectedLabelTextStyle: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          indicatorColor: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      home: const LoginScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
    );
  }
}

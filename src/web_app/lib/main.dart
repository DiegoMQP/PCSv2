import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/language_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/qr_share_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const PcsWebApp(),
    ),
  );
}

class PcsWebApp extends StatelessWidget {
  const PcsWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return MaterialApp(
      title: 'PCS Web - Control de Acceso',
      debugShowCheckedModeBanner: false,
      locale: lang.locale,
      themeMode: ThemeMode.dark,
      // ── Dark Theme (mirrors mobile_app) ────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          surface: Color(0xFF2C2C2E),
          secondary: Color(0xFF32D74B),
          onSurface: Colors.white,
          onPrimary: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF2C2C2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Color(0xFF0A84FF)),
        ),
        dividerColor: Colors.white10,
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3A3A3C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A84FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0A84FF)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF2C2C2E),
          selectedItemColor: Color(0xFF0A84FF),
          unselectedItemColor: Colors.white38,
          elevation: 0,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF3A3A3C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2C2C2E),
          contentTextStyle:
              const TextStyle(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        listTileTheme: const ListTileThemeData(textColor: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white70),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF2C2C2E),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      // Light fallback (won't be used)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A84FF), brightness: Brightness.light),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
      onGenerateRoute: (settings) {
        // /qr/183155?name=Dileo&loc=Atemajac+2172&type=PERMANENTE
        final uri = Uri.parse(settings.name ?? '');
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'qr') {
          final code = uri.pathSegments[1];
          final q = uri.queryParameters;
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => QrShareScreen(
              code: code,
              name: q['name'] ?? '',
              location: q['loc'] ?? '',
              type: q['type'] ?? 'PERMANENTE',
            ),
          );
        }
        return null;
      },
    );
  }
}

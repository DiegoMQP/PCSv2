import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const VerifierApp(),
    ),
  );
}

class VerifierApp extends StatelessWidget {
  const VerifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'PCS Verificador',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          // ── Dark Theme (gris PCS) ──────────────────────────
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF1C1C1E),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0A84FF),
              surface: Color(0xFF2C2C2E),
              secondary: Color(0xFF32D74B),
            ),
            cardTheme: const CardThemeData(
              color: Color(0xFF2C2C2E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
            dividerColor: Colors.white12,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1C1C1E),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              iconTheme: IconThemeData(color: Color(0xFF0A84FF)),
            ),
          ),
          // ── Light Theme ────────────────────────────────────
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF2F2F7),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007AFF),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF007AFF),
              surface: Colors.white,
              secondary: const Color(0xFF34C759),
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
            dividerColor: Colors.black12,
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF2F2F7),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              iconTheme: IconThemeData(color: Color(0xFF007AFF)),
            ),
          ),
          home: const ScannerScreen(),
        );
      },
    );
  }
}

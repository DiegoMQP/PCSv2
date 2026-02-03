import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/codes_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCS Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS Background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // iOS Blue
          primary: const Color(0xFF007AFF),
          secondary: const Color(0xFF34C759), // iOS Green
          error: const Color(0xFFFF3B30), // iOS Red
          background: const Color(0xFFF2F2F7),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F2F7),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: Color(0xFF007AFF)),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: EdgeInsets.zero,
        ).data,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/guest': (context) => const GuestScreen(),
        '/logs': (context) => const LogsScreen(),
        '/codes': (context) => const CodesScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

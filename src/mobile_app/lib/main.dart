import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/register_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/codes_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_users_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PCS Mobile',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          darkTheme: ThemeData(
             brightness: Brightness.dark,
             useMaterial3: true,
             scaffoldBackgroundColor: const Color(0xFF1C1C1E),
             colorScheme: const ColorScheme.dark(
                primary: Color(0xFF0A84FF),
                surface: Color(0xFF2C2C2E),
                secondary: Color(0xFF32D74B),
             ),
             cardTheme: CardTheme(
                color: const Color(0xFF2C2C2E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                margin: EdgeInsets.zero,
             ).data, // Convert to data if needed by older flutter versions or just fix passing
             textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
             appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1C1C1E),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                iconTheme: IconThemeData(color: Color(0xFF0A84FF)),
             ), 
          ),
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF2F2F7),
            primaryColor: const Color(0xFF007AFF),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF), brightness: Brightness.light),
            cardTheme: CardTheme(
               color: Colors.white,
               elevation: 0,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ).data,
             appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF2F2F7),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                iconTheme: IconThemeData(color: Color(0xFF007AFF)),
             ),
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
            '/admin_users': (context) => const AdminUsersScreen(),
          },
        );
      }
    );
  }
}

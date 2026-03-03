import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';
  String get langCode => _locale.languageCode;

  void toggle() {
    _locale = isEnglish ? const Locale('es') : const Locale('en');
    notifyListeners();
  }
}

// ───── Translation helper ──────────────────────────────────
class L {
  static const _es = <String, String>{
    // Login
    'loginTitle': 'PCS Access',
    'loginSubtitle': 'Panel de Control Residencial',
    'username': 'Usuario',
    'password': 'Contraseña',
    'loginBtn': 'Iniciar Sesión',
    'fillAll': 'Completa todos los campos',
    'serverError': 'El servidor tuvo un problema, intenta de nuevo',
    'retry': 'Reintentar',
    'invalidCreds': 'Credenciales inválidas',
    'footer': 'PCS Security © 2025',
    // Dashboard nav
    'home': 'Inicio',
    'codes': 'Mis Códigos',
    'guests': 'Invitados',
    'logs': 'Registros',
    'manageUsers': 'Gestionar Usuarios',
    'alerts': 'Alertas',
    'profile': 'Perfil',
    'logout': 'Cerrar sesión',
    // Sidebar
    'sidebarSub': 'Control Residencial',
    // Home overview
    'greeting': 'Hola,',
    'welcomeText': 'Bienvenido al panel de control de acceso.',
    'serverOnline': 'Servidor en línea',
    'serverOffline': 'Servidor desconectado',
    'checking': 'Verificando...',
    'activeCodes': 'Códigos Activos',
    'myHome': 'Mi Casa',
    'myRole': 'Mi Rol',
    'quickActions': 'Acciones Rápidas',
    'newCode': 'Nuevo Código',
    'inviteGuest': 'Invitar Visita',
    'viewLogs': 'Ver Registros',
  };

  static const _en = <String, String>{
    // Login
    'loginTitle': 'PCS Access',
    'loginSubtitle': 'Residential Access Control',
    'username': 'Username',
    'password': 'Password',
    'loginBtn': 'Sign In',
    'fillAll': 'Please fill in all fields',
    'serverError': 'Server error, please try again',
    'retry': 'Retry',
    'invalidCreds': 'Invalid credentials',
    'footer': 'PCS Security © 2025',
    // Dashboard nav
    'home': 'Home',
    'codes': 'My Codes',
    'guests': 'Guests',
    'logs': 'Logs',
    'manageUsers': 'Manage Users',
    'alerts': 'Alerts',
    'profile': 'Profile',
    'logout': 'Log out',
    // Sidebar
    'sidebarSub': 'Residential Control',
    // Home overview
    'greeting': 'Hello,',
    'welcomeText': 'Welcome to the access control panel.',
    'serverOnline': 'Server online',
    'serverOffline': 'Server disconnected',
    'checking': 'Checking...',
    'activeCodes': 'Active Codes',
    'myHome': 'My Home',
    'myRole': 'My Role',
    'quickActions': 'Quick Actions',
    'newCode': 'New Code',
    'inviteGuest': 'Invite Guest',
    'viewLogs': 'View Logs',
  };

  static String of(LanguageProvider lang, String key) {
    return (lang.isEnglish ? _en[key] : _es[key]) ?? key;
  }
}

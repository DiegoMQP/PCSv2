import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  String _name = '';
  String _location = '';
  String _role = 'user';

  String get username => _username;
  String get name => _name.isNotEmpty ? _name : _username;
  String get location => _location;
  String get role => _role;
  bool get isLoggedIn => _username.isNotEmpty;
  bool get isAdmin => _role == 'admin';
  bool get isMainAdmin => _username == 'admin@admin.com';

  void setUser(String username, {String? name, String? location, String? role}) {
    _username = username;
    if (name != null) _name = name;
    if (location != null) _location = location;
    if (role != null) _role = role;
    notifyListeners();
  }

  void clearUser() {
    _username = '';
    _name = '';
    _location = '';
    _role = 'user';
    notifyListeners();
  }
}

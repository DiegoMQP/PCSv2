import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  String _name = '';
  
  String get username => _username;
  String get name => _name.isNotEmpty ? _name : _username;

  void setUser(String username, {String? name}) {
    _username = username;
    if (name != null) _name = name;
    notifyListeners();
  }

  void clearUser() {
    _username = '';
    _name = '';
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGuard {
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  static Future<void> checkAuth(BuildContext context) async {
    if (!await isAuthenticated()) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

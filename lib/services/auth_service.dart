import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoggedIn = false;
  String? _username;
  int? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  int? get userId => _userId;
  ApiService get api => _api;

  // Check if token exists on app startup
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      try {
        final me = await _api.getMe();
        _username = me['username'];
        _userId = me['user_id'];
        _isLoggedIn = true;
      } catch (_) {
        await _clearToken();
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    final token = result['access_token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _username = result['username'];
    _userId = result['user_id'];
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    await _api.register(username, password);
  }

  Future<void> logout() async {
    await _clearToken();
    _isLoggedIn = false;
    _username = null;
    _userId = null;
    notifyListeners();
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}

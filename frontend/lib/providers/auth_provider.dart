import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    loadUserFromStorage();
  }

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final savedUserStr = prefs.getString('user_data');

    if (savedToken != null && savedUserStr != null) {
      _token = savedToken;
      _currentUser = User.fromJson(jsonDecode(savedUserStr));
      ApiClient().setToken(_token);
      notifyListeners();
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.post(
        '/auth/login',
        data: {
          'username_or_email': usernameOrEmail.trim(),
          'password': password,
        },
      );

      _token = response.data['access_token'];
      _currentUser = User.fromJson(response.data['user']);
      ApiClient().setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String fullName, String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.post(
        '/auth/register',
        data: {
          'full_name': fullName.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      _token = response.data['access_token'];
      _currentUser = User.fromJson(response.data['user']);
      ApiClient().setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    ApiClient().setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}

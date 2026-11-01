import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  UserRole get currentRole => _currentUser?.role ?? UserRole.citizen;
  bool get isAdmin => _currentUser?.role.isAdmin ?? false;
  bool get isCitizen => _currentUser?.role.isCitizen ?? true;

  AuthProvider() {
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      _currentUser = await _authService.restoreSession();
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(username, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Authentication failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _authService.updateProfile(fullName: fullName, phone: phone);
      _currentUser = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Profile update failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}

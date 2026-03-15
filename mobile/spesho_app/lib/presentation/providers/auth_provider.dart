import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

class AuthProvider extends ChangeNotifier {
  final AuthUseCases _useCases;

  UserEntity? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._useCases);

  UserEntity? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;
  bool get isManager => _user?.isManager ?? false;
  bool get isSeller => _user?.isSeller ?? false;

  Future<void> init() async {
    _user = await _useCases.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _useCases.login(username, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _useCases.logout();
    _user = null;
    notifyListeners();
  }
}

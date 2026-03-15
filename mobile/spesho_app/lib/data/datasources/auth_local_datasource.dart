import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthLocalDatasource {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> getToken() =>
      _storage.read(key: AppConstants.tokenKey);

  Future<void> saveUser(UserModel user) =>
      _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));

  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  Future<void> clear() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }
}

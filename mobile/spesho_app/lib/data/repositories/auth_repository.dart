import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final ApiClient _api;
  final AuthLocalDatasource _local;

  AuthRepository(this._api, this._local);

  @override
  Future<UserModel> login(String username, String password) async {
    final res = await _api.post('/auth/login', {
      'username': username,
      'password': password,
    }, auth: false);
    final user = UserModel.fromJson(res['user']);
    await _local.saveToken(res['access_token']);
    await _local.saveUser(user);
    return user;
  }

  @override
  Future<UserModel?> getCurrentUser() => _local.getUser();

  @override
  Future<void> logout() => _local.clear();

  @override
  Future<UserModel> refreshMe() async {
    final res = await _api.get('/auth/me');
    final user = UserModel.fromJson(res['user']);
    await _local.saveUser(user);
    return user;
  }
}

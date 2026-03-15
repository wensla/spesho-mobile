import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository _repo;
  LoginUseCase(this._repo);
  Future<UserEntity> call(String username, String password) =>
      _repo.login(username, password);
}

class LogoutUseCase {
  final IAuthRepository _repo;
  LogoutUseCase(this._repo);
  Future<void> call() => _repo.logout();
}

class GetCurrentUserUseCase {
  final IAuthRepository _repo;
  GetCurrentUserUseCase(this._repo);
  Future<UserEntity?> call() => _repo.getCurrentUser();
}

class RefreshMeUseCase {
  final IAuthRepository _repo;
  RefreshMeUseCase(this._repo);
  Future<UserEntity> call() => _repo.refreshMe();
}

class AuthUseCases {
  final LoginUseCase login;
  final LogoutUseCase logout;
  final GetCurrentUserUseCase getCurrentUser;
  final RefreshMeUseCase refreshMe;

  AuthUseCases(IAuthRepository repo)
      : login = LoginUseCase(repo),
        logout = LogoutUseCase(repo),
        getCurrentUser = GetCurrentUserUseCase(repo),
        refreshMe = RefreshMeUseCase(repo);
}

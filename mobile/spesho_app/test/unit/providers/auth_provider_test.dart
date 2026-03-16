import 'package:flutter_test/flutter_test.dart';
import 'package:spesho_app/domain/entities/user_entity.dart';
import 'package:spesho_app/domain/repositories/i_auth_repository.dart';
import 'package:spesho_app/domain/usecases/auth_usecases.dart';
import 'package:spesho_app/presentation/providers/auth_provider.dart';

class _MockAuthRepository implements IAuthRepository {
  UserEntity? loginResult;
  Exception? loginError;
  UserEntity? cachedUser;

  @override
  Future<UserEntity> login(String username, String password) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<UserEntity?> getCurrentUser() async => cachedUser;

  @override
  Future<void> logout() async => cachedUser = null;

  @override
  Future<UserEntity> refreshMe() async => cachedUser!;
}

void main() {
  late _MockAuthRepository mockRepo;
  late AuthProvider provider;

  const tUser = UserEntity(
    id: 1,
    username: 'admin',
    role: 'manager',
    isActive: true,
  );

  setUp(() {
    mockRepo = _MockAuthRepository();
    provider = AuthProvider(AuthUseCases(mockRepo));
  });

  tearDown(() {
    provider.dispose();
  });

  group('init', () {
    test('loads user from local storage on init', () async {
      mockRepo.cachedUser = tUser;

      await provider.init();

      expect(provider.user, isNotNull);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.user!.username, 'admin');
    });

    test('stays logged out when no cached user', () async {
      mockRepo.cachedUser = null;

      await provider.init();

      expect(provider.user, isNull);
      expect(provider.isLoggedIn, isFalse);
    });
  });

  group('login', () {
    test('sets user and returns true on success', () async {
      mockRepo.loginResult = tUser;

      final result = await provider.login('admin', 'pass123');

      expect(result, isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.error, isNull);
      expect(provider.loading, isFalse);
    });

    test('sets error and returns false on failure', () async {
      mockRepo.loginError = Exception('Invalid credentials');

      final result = await provider.login('bad', 'wrong');

      expect(result, isFalse);
      expect(provider.user, isNull);
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });
  });

  group('logout', () {
    test('clears user on logout', () async {
      mockRepo.loginResult = tUser;
      await provider.login('admin', 'pass');

      await provider.logout();

      expect(provider.user, isNull);
      expect(provider.isLoggedIn, isFalse);
    });
  });

  group('isManager', () {
    test('returns true for manager role', () async {
      mockRepo.loginResult = tUser;
      await provider.login('admin', 'pass');

      expect(provider.isManager, isTrue);
    });

    test('returns false when not logged in', () {
      expect(provider.isManager, isFalse);
    });
  });
}

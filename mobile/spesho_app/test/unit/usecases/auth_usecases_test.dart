import 'package:flutter_test/flutter_test.dart';
import 'package:spesho_app/domain/entities/user_entity.dart';
import 'package:spesho_app/domain/repositories/i_auth_repository.dart';
import 'package:spesho_app/domain/usecases/auth_usecases.dart';

class _MockAuthRepository implements IAuthRepository {
  UserEntity? loginResult;
  Exception? loginError;
  UserEntity? cachedUser;
  bool logoutCalled = false;

  @override
  Future<UserEntity> login(String username, String password) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<UserEntity?> getCurrentUser() async => cachedUser;

  @override
  Future<void> logout() async => logoutCalled = true;

  @override
  Future<UserEntity> refreshMe() async => cachedUser!;
}

void main() {
  late _MockAuthRepository mockRepo;
  late AuthUseCases useCases;

  const tUser = UserEntity(
    id: 1,
    username: 'admin',
    role: 'manager',
    fullName: 'Admin User',
    isActive: true,
  );

  setUp(() {
    mockRepo = _MockAuthRepository();
    useCases = AuthUseCases(mockRepo);
  });

  group('LoginUseCase', () {
    test('returns UserEntity on successful login', () async {
      mockRepo.loginResult = tUser;

      final result = await useCases.login('admin', 'admin123');

      expect(result.id, 1);
      expect(result.username, 'admin');
      expect(result.isManager, isTrue);
    });

    test('propagates exception on login failure', () async {
      mockRepo.loginError = Exception('Invalid credentials');

      expect(
        () => useCases.login('bad', 'wrong'),
        throwsException,
      );
    });
  });

  group('GetCurrentUserUseCase', () {
    test('returns cached user when logged in', () async {
      mockRepo.cachedUser = tUser;

      final result = await useCases.getCurrentUser();

      expect(result, isNotNull);
      expect(result!.username, 'admin');
    });

    test('returns null when not logged in', () async {
      mockRepo.cachedUser = null;

      final result = await useCases.getCurrentUser();

      expect(result, isNull);
    });
  });

  group('LogoutUseCase', () {
    test('calls repository logout', () async {
      await useCases.logout();

      expect(mockRepo.logoutCalled, isTrue);
    });
  });

  group('UserEntity', () {
    test('isManager returns true for manager role', () {
      const manager = UserEntity(id: 1, username: 'mgr', role: 'manager');
      expect(manager.isManager, isTrue);
    });

    test('isManager returns false for salesperson role', () {
      const sales = UserEntity(id: 2, username: 'sales', role: 'salesperson');
      expect(sales.isManager, isFalse);
    });

    test('displayName uses fullName when set', () {
      const user = UserEntity(
        id: 1,
        username: 'john',
        role: 'salesperson',
        fullName: 'John Doe',
      );
      expect(user.displayName, 'John Doe');
    });

    test('displayName falls back to username when fullName is null', () {
      const user = UserEntity(id: 1, username: 'john', role: 'salesperson');
      expect(user.displayName, 'john');
    });
  });
}

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.role,
    super.fullName,
    super.isActive = true,
    super.shopIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as int,
        username: j['username'] as String,
        role: j['role'] as String,
        fullName: j['full_name'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        shopIds: (j['shop_ids'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
        'full_name': fullName,
        'is_active': isActive,
        'shop_ids': shopIds,
      };
}

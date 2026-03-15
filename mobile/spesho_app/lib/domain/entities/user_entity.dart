class UserEntity {
  final int id;
  final String username;
  final String role;
  final String? fullName;
  final String? gender; // 'male' | 'female' | null
  final bool isActive;
  final List<int> shopIds;
  final String? shopName;
  final String? shopLocation;

  const UserEntity({
    required this.id,
    required this.username,
    required this.role,
    this.fullName,
    this.gender,
    this.isActive = true,
    this.shopIds = const [],
    this.shopName,
    this.shopLocation,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isManager => role == 'manager';
  bool get isSeller => role == 'seller' || role == 'salesperson';
  bool get isFemale => gender == 'female';
  bool get isMale => gender == 'male';

  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : username;

  String get roleLabel {
    if (isSuperAdmin) return 'Super Admin';
    if (isManager) return 'Manager';
    return 'Seller';
  }
}

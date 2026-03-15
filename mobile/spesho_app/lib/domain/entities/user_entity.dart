class UserEntity {
  final int id;
  final String username;
  final String role;
  final String? fullName;
  final bool isActive;
  final List<int> shopIds;

  const UserEntity({
    required this.id,
    required this.username,
    required this.role,
    this.fullName,
    this.isActive = true,
    this.shopIds = const [],
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isManager => role == 'manager';
  bool get isSeller => role == 'seller' || role == 'salesperson';

  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : username;

  String get roleLabel {
    if (isSuperAdmin) return 'Super Admin';
    if (isManager) return 'Manager';
    return 'Seller';
  }
}

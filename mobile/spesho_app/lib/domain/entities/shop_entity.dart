class ShopEntity {
  final int id;
  final String name;
  final String? location;
  final String? address;
  final bool isActive;

  const ShopEntity({
    required this.id,
    required this.name,
    this.location,
    this.address,
    this.isActive = true,
  });
}

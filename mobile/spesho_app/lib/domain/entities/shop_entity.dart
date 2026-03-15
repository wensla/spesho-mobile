class ShopEntity {
  final int id;
  final String name;
  final String? location;
  final String? address;
  final bool isActive;
  final int? ownerId;
  final String? ownerName;

  const ShopEntity({
    required this.id,
    required this.name,
    this.location,
    this.address,
    this.isActive = true,
    this.ownerId,
    this.ownerName,
  });
}

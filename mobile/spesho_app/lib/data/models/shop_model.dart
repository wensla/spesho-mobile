import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  const ShopModel({
    required super.id,
    required super.name,
    super.location,
    super.address,
    super.isActive,
    super.ownerId,
    super.ownerName,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        id: json['id'] as int,
        name: json['name'] as String,
        location: json['location'] as String?,
        address: json['address'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        ownerId: json['owner_id'] as int?,
        ownerName: json['owner_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'address': address,
        'is_active': isActive,
        'owner_id': ownerId,
        'owner_name': ownerName,
      };
}

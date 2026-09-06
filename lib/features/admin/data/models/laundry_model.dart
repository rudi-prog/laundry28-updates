
/// Model untuk data laundry (tenant)
class LaundryModel {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? logoUrl;
  final int? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LaundryModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.logoUrl,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory LaundryModel.fromJson(Map<String, dynamic> json) {
    return LaundryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      ownerId: json['owner_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'logo_url': logoUrl,
      'owner_id': ownerId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  LaundryModel copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? logoUrl,
    int? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LaundryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LaundryModel &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.logoUrl == logoUrl &&
        other.ownerId == ownerId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      address,
      phone,
      logoUrl,
      ownerId,
      createdAt,
      updatedAt,
    );
  }
}

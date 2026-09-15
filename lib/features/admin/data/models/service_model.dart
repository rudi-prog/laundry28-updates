/// Model untuk data layanan laundry per branch
class ServiceModel {
  final int id;
  final int laundryId;
  final String name;
  final double price;
  final int durationHours;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceModel({
    required this.id,
    required this.laundryId,
    required this.name,
    required this.price,
    this.durationHours = 1,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int? ?? 0,
      laundryId: json['laundry_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationHours: json['duration_hours'] as int? ?? 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
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
      'laundry_id': laundryId,
      'name': name,
      'price': price,
      'duration_hours': durationHours,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    int? id,
    int? laundryId,
    String? name,
    double? price,
    int? durationHours,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      laundryId: laundryId ?? this.laundryId,
      name: name ?? this.name,
      price: price ?? this.price,
      durationHours: durationHours ?? this.durationHours,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel &&
        other.id == id &&
        other.laundryId == laundryId &&
        other.name == name &&
        other.price == price;
  }

  @override
  int get hashCode {
    return Object.hash(id, laundryId, name, price);
  }
}

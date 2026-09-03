/// Model data pesanan
class OrderModel {
  final int? id;
  final String trackingCode;
  final String customerName;
  final String customerPhone;
  final String serviceType;
  final String status;
  final DateTime? estimatedTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? weight;
  final double? totalPrice;

  OrderModel({
    this.id,
    required this.trackingCode,
    required this.customerName,
    required this.customerPhone,
    required this.serviceType,
    required this.status,
    this.estimatedTime,
    required this.createdAt,
    this.updatedAt,
    this.weight,
    this.totalPrice,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Support both snake_case (Supabase) and camelCase (JSON storage)
    return OrderModel(
      id: json['id'] as int?,
      trackingCode: (json['tracking_code'] ?? json['trackingCode']) as String? ?? '',
      customerName: (json['customer_name'] ?? json['customerName']) as String? ?? '',
      customerPhone: (json['customer_phone'] ?? json['customerPhone']) as String? ?? '',
      serviceType: (json['service_type'] ?? json['serviceType']) as String? ?? '',
      status: (json['status'] ?? 'Diterima') as String,
      estimatedTime: json['estimated_time'] != null
          ? DateTime.parse(json['estimated_time'] as String)
          : (json['estimatedTime'] != null ? DateTime.parse(json['estimatedTime'] as String) : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null),
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      totalPrice: json['total_price'] != null ? (json['total_price'] as num).toDouble() : (json['totalPrice'] != null ? (json['totalPrice'] as num).toDouble() : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_code': trackingCode,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_type': serviceType,
      'status': status,
      'estimated_time': estimatedTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'weight': weight,
      'total_price': totalPrice,
    };
  }

  OrderModel copyWith({
    int? id,
    String? trackingCode,
    String? customerName,
    String? customerPhone,
    String? serviceType,
    String? status,
    DateTime? estimatedTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? weight,
    double? totalPrice,
  }) {
    return OrderModel(
      id: id ?? this.id,
      trackingCode: trackingCode ?? this.trackingCode,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      weight: weight ?? this.weight,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

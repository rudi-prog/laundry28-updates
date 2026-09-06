/// Model data karyawan/staff
class StaffModel {
  final int? id;
  final String email;           // Email (untuk owner)
  final String? username;       // Username (untuk employee login)
  final String? pin;            // PIN 4-6 digit (untuk employee login)
  final String fullName;
  final String role;            // 'owner' atau 'employee'
  final int? laundryId;         // Laundry/tenant ID
  final String? laundryName;    // Nama laundry (jika ada)
  final DateTime createdAt;

  StaffModel({
    this.id,
    required this.email,
    this.username,
    this.pin,
    required this.fullName,
    this.role = 'employee',
    this.laundryId,
    this.laundryName,
    required this.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as int?,
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      pin: json['pin'] as String?,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      laundryId: json['laundry_id'] as int?,
      laundryName: json['laundry_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'pin': pin,
      'full_name': fullName,
      'role': role,
      'laundry_id': laundryId,
      'laundry_name': laundryName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  StaffModel copyWith({
    int? id,
    String? email,
    String? username,
    String? pin,
    String? fullName,
    String? role,
    int? laundryId,
    String? laundryName,
    DateTime? createdAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      laundryId: laundryId ?? this.laundryId,
      laundryName: laundryName ?? this.laundryName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Cek apakah user adalah owner
  bool get isOwner => role == 'owner';

  /// Cek apakah user adalah employee
  bool get isEmployee => role == 'employee';

  /// Cek apakah PIN valid (4-6 digit)
  bool get hasPin => pin != null && pin!.length >= 4 && pin!.length <= 6;
}

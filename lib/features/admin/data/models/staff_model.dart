/// Model data karyawan/staff
class StaffModel {
  final int? id;
  final String email;           // Email (untuk owner)
  final String? username;       // Username (untuk employee login)
  final String? pinHash;        // Hashed PIN (bcrypt - sudah termasuk salt)
  final String fullName;
  final String role;            // 'owner' atau 'employee'
  final int? laundryId;         // Laundry/tenant ID
  final String? laundryName;    // Nama laundry (jika ada)
  final String? authUserId;     // Supabase auth user ID (for RLS policies)
  final DateTime createdAt;
  // Rate limiting fields
  final int? failedPinAttempts;
  final DateTime? lockedUntil;

  StaffModel({
    this.id,
    required this.email,
    this.username,
    this.pinHash,
    required this.fullName,
    this.role = 'employee',
    this.laundryId,
    this.laundryName,
    this.authUserId,
    required this.createdAt,
    this.failedPinAttempts,
    this.lockedUntil,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as int?,
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      pinHash: json['pin_hash'] as String?,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      laundryId: json['laundry_id'] as int?,
      laundryName: json['laundry_name'] as String?,
      authUserId: json['auth_user_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      failedPinAttempts: json['failed_pin_attempts'] as int?,
      lockedUntil: json['locked_until'] != null
          ? DateTime.parse(json['locked_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'pin_hash': pinHash,
      'full_name': fullName,
      'role': role,
      'laundry_id': laundryId,
      'laundry_name': laundryName,
      'auth_user_id': authUserId,
      'created_at': createdAt.toIso8601String(),
      'failed_pin_attempts': failedPinAttempts,
      'locked_until': lockedUntil?.toIso8601String(),
    };
  }

  StaffModel copyWith({
    int? id,
    String? email,
    String? username,
    String? pinHash,
    String? fullName,
    String? role,
    int? laundryId,
    String? laundryName,
    String? authUserId,
    DateTime? createdAt,
    int? failedPinAttempts,
    DateTime? lockedUntil,
  }) {
    return StaffModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      pinHash: pinHash ?? this.pinHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      laundryId: laundryId ?? this.laundryId,
      laundryName: laundryName ?? this.laundryName,
      authUserId: authUserId ?? this.authUserId,
      createdAt: createdAt ?? this.createdAt,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  /// Cek apakah user adalah owner
  bool get isOwner => role == 'owner';

  /// Cek apakah user adalah employee
  bool get isEmployee => role == 'employee';

  /// Cek apakah PIN hash sudah diset
  bool get hasPinHash => pinHash != null && pinHash!.isNotEmpty;

  /// Cek apakah akun terkunci
  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  /// Hitung waktu tersisa sebelum akun bisa diakses lagi
  Duration? get lockRemainingTime {
    if (lockedUntil == null) return null;
    final remaining = lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}

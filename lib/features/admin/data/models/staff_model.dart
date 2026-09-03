/// Model data karyawan/staff
class StaffModel {
  final int? id;
  final String email;
  final String fullName;
  final DateTime createdAt;

  StaffModel({
    this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as int?,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

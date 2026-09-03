class UserModel {
  final String id;
  final String name;
  final String? phone;
  final String bloodGroup;
  final String emergencyContact;
  final DateTime registeredAt;

  UserModel({
    required this.id,
    required this.name,
    this.phone,
    required this.bloodGroup,
    required this.emergencyContact,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone ?? '',
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: (map['phone'] != null && map['phone'].toString().isNotEmpty)
          ? map['phone'].toString()
          : null,
      bloodGroup: map['bloodGroup'] ?? 'Unknown',
      emergencyContact: map['emergencyContact'] ?? '',
      registeredAt: map['registeredAt'] != null
          ? DateTime.parse(map['registeredAt'])
          : DateTime.now(),
    );
  }
}

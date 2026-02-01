class User {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String phoneNumber;
  final String? profileImage;
  final String? gender;
  final DateTime? birthDate;
  final String role;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
    this.gender,
    this.birthDate,
    required this.role,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImage: json['profileImage'],
      gender: json['gender'],
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
      role: json['role'] ?? 'customer',
      isVerified: json['isVerified'] ?? false,
    );
  }

  String get fullName => '$name $surname';
}

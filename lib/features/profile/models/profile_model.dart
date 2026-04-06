class ProfileModel {
  final String role;
  final String name;
  final String email;
  final String phone;
  final String? className;
  final String? section;
  final String? programName;
  final String? imagePath;

  const ProfileModel({
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    this.className,
    this.section,
    this.programName,
    this.imagePath,
  });

  ProfileModel copyWith({
    String? role,
    String? name,
    String? email,
    String? phone,
    String? className,
    String? section,
    String? programName,
    String? imagePath,
  }) {
    return ProfileModel(
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      className: className ?? this.className,
      section: section ?? this.section,
      programName: programName ?? this.programName,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'email': email,
      'phone': phone,
      'className': className,
      'section': section,
      'programName': programName,
      'imagePath': imagePath,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      role: map['role'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      className: map['className'] as String?,
      section: map['section'] as String?,
      programName: map['programName'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }
}

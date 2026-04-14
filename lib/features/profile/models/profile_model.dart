class ProfileModel {
  static const Object _unset = Object();

  final String role;
  final String name;
  final String email;
  final String phone;
  final String? className;
  final String? section;
  final String? programName;
  final String? admissionNo;
  final String? rollNumber;
  final String? linkedStudentProfileId;
  final String? imagePath;

  const ProfileModel({
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    this.className,
    this.section,
    this.programName,
    this.admissionNo,
    this.rollNumber,
    this.linkedStudentProfileId,
    this.imagePath,
  });

  ProfileModel copyWith({
    String? role,
    String? name,
    String? email,
    String? phone,
    Object? className = _unset,
    Object? section = _unset,
    Object? programName = _unset,
    Object? admissionNo = _unset,
    Object? rollNumber = _unset,
    Object? linkedStudentProfileId = _unset,
    Object? imagePath = _unset,
  }) {
    return ProfileModel(
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      className: identical(className, _unset)
          ? this.className
          : className as String?,
      section: identical(section, _unset) ? this.section : section as String?,
      programName: identical(programName, _unset)
          ? this.programName
          : programName as String?,
      admissionNo: identical(admissionNo, _unset)
          ? this.admissionNo
          : admissionNo as String?,
      rollNumber: identical(rollNumber, _unset)
          ? this.rollNumber
          : rollNumber as String?,
      linkedStudentProfileId: identical(linkedStudentProfileId, _unset)
          ? this.linkedStudentProfileId
          : linkedStudentProfileId as String?,
      imagePath: identical(imagePath, _unset)
          ? this.imagePath
          : imagePath as String?,
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
      'admissionNo': admissionNo,
      'rollNumber': rollNumber,
      'linkedStudentProfileId': linkedStudentProfileId,
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
      admissionNo: map['admissionNo'] as String?,
      rollNumber: map['rollNumber'] as String?,
      linkedStudentProfileId: map['linkedStudentProfileId'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }
}

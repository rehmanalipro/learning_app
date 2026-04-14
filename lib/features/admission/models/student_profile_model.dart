class StudentProfileModel {
  final String id;
  final String admissionNo;
  final String fullName;
  final String fatherName;
  final String dateOfBirth;
  final String gender;
  final String studentEmail;
  final String phone;
  final String className;
  final String section;
  final String rollNumber;
  final String programName;
  final String status;
  final String generatedUserId;
  final String linkedUserUid;
  final String linkedUserEmail;
  final String credentialsIssuedAt;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const StudentProfileModel({
    required this.id,
    required this.admissionNo,
    required this.fullName,
    required this.fatherName,
    required this.dateOfBirth,
    required this.gender,
    required this.studentEmail,
    required this.phone,
    required this.className,
    required this.section,
    required this.rollNumber,
    required this.programName,
    required this.status,
    required this.generatedUserId,
    required this.linkedUserUid,
    required this.linkedUserEmail,
    required this.credentialsIssuedAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLinked => linkedUserUid.trim().isNotEmpty;

  String get classSectionLabel => '$className-$section';

  String get sortKey {
    final classPart = className.padLeft(2, '0');
    final sectionPart = section.trim().toUpperCase();
    final rollPart = rollNumber.trim().padLeft(4, '0');
    return '${classPart}_${sectionPart}_$rollPart';
  }

  StudentProfileModel copyWith({
    String? id,
    String? admissionNo,
    String? fullName,
    String? fatherName,
    String? dateOfBirth,
    String? gender,
    String? studentEmail,
    String? phone,
    String? className,
    String? section,
    String? rollNumber,
    String? programName,
    String? status,
    String? generatedUserId,
    String? linkedUserUid,
    String? linkedUserEmail,
    String? credentialsIssuedAt,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return StudentProfileModel(
      id: id ?? this.id,
      admissionNo: admissionNo ?? this.admissionNo,
      fullName: fullName ?? this.fullName,
      fatherName: fatherName ?? this.fatherName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      studentEmail: studentEmail ?? this.studentEmail,
      phone: phone ?? this.phone,
      className: className ?? this.className,
      section: section ?? this.section,
      rollNumber: rollNumber ?? this.rollNumber,
      programName: programName ?? this.programName,
      status: status ?? this.status,
      generatedUserId: generatedUserId ?? this.generatedUserId,
      linkedUserUid: linkedUserUid ?? this.linkedUserUid,
      linkedUserEmail: linkedUserEmail ?? this.linkedUserEmail,
      credentialsIssuedAt: credentialsIssuedAt ?? this.credentialsIssuedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admissionNo': admissionNo,
      'fullName': fullName,
      'fatherName': fatherName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'studentEmail': studentEmail,
      'phone': phone,
      'className': className,
      'section': section,
      'rollNumber': rollNumber,
      'programName': programName,
      'classSectionLabel': classSectionLabel,
      'sortKey': sortKey,
      'status': status,
      'generatedUserId': generatedUserId,
      'linkedUserUid': linkedUserUid,
      'linkedUserEmail': linkedUserEmail,
      'credentialsIssuedAt': credentialsIssuedAt,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toLinkedUserMap({
    required String uid,
    required String email,
  }) {
    return {
      'uid': uid,
      'email': email,
      'userId': generatedUserId,
      'userIdSearchKey': generatedUserId.toLowerCase(),
      'name': fullName,
      'role': 'Student',
      'gender': gender,
      'phone': phone,
      'rollNumber': rollNumber,
      'className': className,
      'section': section,
      'programName': programName,
      'classSectionLabel': classSectionLabel,
      'sortKey': sortKey,
      'admissionNo': admissionNo,
      'linkedStudentProfileId': id,
      'updatedAt': updatedAt,
    };
  }

  factory StudentProfileModel.fromMap(String id, Map<String, dynamic> map) {
    return StudentProfileModel(
      id: id,
      admissionNo: map['admissionNo'] as String? ?? '',
      fullName: map['fullName'] as String? ?? map['name'] as String? ?? '',
      fatherName: map['fatherName'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      studentEmail:
          map['studentEmail'] as String? ??
          map['email'] as String? ??
          map['linkedUserEmail'] as String? ??
          '',
      phone: map['phone'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      programName: map['programName'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      generatedUserId:
          map['generatedUserId'] as String? ?? map['userId'] as String? ?? '',
      linkedUserUid: map['linkedUserUid'] as String? ?? '',
      linkedUserEmail: map['linkedUserEmail'] as String? ?? '',
      credentialsIssuedAt: map['credentialsIssuedAt'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }
}

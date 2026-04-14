class TeacherProfileModel {
  final String id;
  final String fullName;
  final String teacherEmail;
  final String phone;
  final String employeeId;
  final String department;
  final String className;
  final String section;
  final String subject;
  final String status;
  final bool isClassTeacher;
  final String generatedUserId;
  final String linkedUserUid;
  final String linkedUserEmail;
  final String credentialsIssuedAt;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const TeacherProfileModel({
    required this.id,
    required this.fullName,
    required this.teacherEmail,
    required this.phone,
    required this.employeeId,
    required this.department,
    required this.className,
    required this.section,
    required this.subject,
    required this.status,
    required this.isClassTeacher,
    required this.generatedUserId,
    required this.linkedUserUid,
    required this.linkedUserEmail,
    required this.credentialsIssuedAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLinked => linkedUserUid.trim().isNotEmpty;

  TeacherProfileModel copyWith({
    String? id,
    String? fullName,
    String? teacherEmail,
    String? phone,
    String? employeeId,
    String? department,
    String? className,
    String? section,
    String? subject,
    String? status,
    bool? isClassTeacher,
    String? generatedUserId,
    String? linkedUserUid,
    String? linkedUserEmail,
    String? credentialsIssuedAt,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return TeacherProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      teacherEmail: teacherEmail ?? this.teacherEmail,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      className: className ?? this.className,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      isClassTeacher: isClassTeacher ?? this.isClassTeacher,
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
      'fullName': fullName,
      'teacherEmail': teacherEmail,
      'phone': phone,
      'employeeId': employeeId,
      'department': department,
      'className': className,
      'section': section,
      'subject': subject,
      'status': status,
      'isClassTeacher': isClassTeacher,
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
      'authUid': uid,
      'email': email,
      'userId': generatedUserId,
      'userIdSearchKey': generatedUserId.toLowerCase(),
      'name': fullName,
      'role': 'Teacher',
      'phone': phone,
      'className': className,
      'section': section,
      'subject': subject,
      'department': department,
      'employeeId': employeeId,
      'teacherProfileId': id,
      'linkedTeacherProfileId': id,
      'status': status,
      'isClassTeacher': isClassTeacher,
      'imagePath': '',
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  factory TeacherProfileModel.fromMap(String id, Map<String, dynamic> map) {
    return TeacherProfileModel(
      id: id,
      fullName: map['fullName'] as String? ?? map['name'] as String? ?? '',
      teacherEmail: map['teacherEmail'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      department: map['department'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      isClassTeacher: map['isClassTeacher'] as bool? ?? false,
      generatedUserId: map['generatedUserId'] as String? ?? '',
      linkedUserUid: map['linkedUserUid'] as String? ?? '',
      linkedUserEmail: map['linkedUserEmail'] as String? ?? '',
      credentialsIssuedAt: map['credentialsIssuedAt'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }
}

class TeacherAssignmentModel {
  final String id;
  final String teacherUid;
  final String teacherProfileId;
  final String teacherName;
  final String className;
  final String section;
  final String subject;
  final String session;
  final bool isClassTeacher;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const TeacherAssignmentModel({
    required this.id,
    required this.teacherUid,
    required this.teacherProfileId,
    required this.teacherName,
    required this.className,
    required this.section,
    required this.subject,
    required this.session,
    required this.isClassTeacher,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  TeacherAssignmentModel copyWith({
    String? id,
    String? teacherUid,
    String? teacherProfileId,
    String? teacherName,
    String? className,
    String? section,
    String? subject,
    String? session,
    bool? isClassTeacher,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return TeacherAssignmentModel(
      id: id ?? this.id,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherProfileId: teacherProfileId ?? this.teacherProfileId,
      teacherName: teacherName ?? this.teacherName,
      className: className ?? this.className,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      session: session ?? this.session,
      isClassTeacher: isClassTeacher ?? this.isClassTeacher,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherUid': teacherUid,
      'teacherProfileId': teacherProfileId,
      'teacherName': teacherName,
      'className': className,
      'section': section,
      'subject': subject,
      'session': session,
      'isClassTeacher': isClassTeacher,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TeacherAssignmentModel.fromMap(String id, Map<String, dynamic> map) {
    return TeacherAssignmentModel(
      id: id,
      teacherUid: map['teacherUid'] as String? ?? '',
      teacherProfileId: map['teacherProfileId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      session: map['session'] as String? ?? '',
      isClassTeacher: map['isClassTeacher'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }
}

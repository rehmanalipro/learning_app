class TeacherModel {
  final String id;
  final String name;
  final String email;
  final String userId;
  final String className;
  final String section;
  final String subject;
  final String employeeId;
  final String status;

  TeacherModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userId,
    required this.className,
    required this.section,
    required this.subject,
    required this.employeeId,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'userId': userId,
      'className': className,
      'section': section,
      'subject': subject,
      'employeeId': employeeId,
      'status': status,
    };
  }

  factory TeacherModel.fromMap(String id, Map<String, dynamic> map) {
    return TeacherModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
    );
  }
}

class TeacherModel {
  final String id;
  final String name;
  final String subject;

  TeacherModel({required this.id, required this.name, required this.subject});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
    };
  }

  factory TeacherModel.fromMap(String id, Map<String, dynamic> map) {
    return TeacherModel(
      id: id,
      name: map['name'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
    );
  }
}

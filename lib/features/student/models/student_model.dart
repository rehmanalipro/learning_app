class StudentModel {
  final String id;
  final String name;
  final String className;
  final String section;
  final String rollNumber;
  final String programName;
  final String userId;

  StudentModel({
    required this.id,
    required this.name,
    required this.className,
    this.section = '',
    this.rollNumber = '',
    this.programName = '',
    this.userId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'className': className,
      'section': section,
      'rollNumber': rollNumber,
      'programName': programName,
      'userId': userId,
    };
  }

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    return StudentModel(
      id: id,
      name: map['name'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      programName: map['programName'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
    );
  }
}

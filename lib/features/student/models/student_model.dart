class StudentModel {
  final String id;
  final String name;
  final String className;

  StudentModel({required this.id, required this.name, required this.className});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'className': className,
    };
  }

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    return StudentModel(
      id: id,
      name: map['name'] as String? ?? '',
      className: map['className'] as String? ?? '',
    );
  }
}

// User Model
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImage;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.profileImage,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      profileImage: map['profileImage'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }
}

// Student Model
class StudentModel {
  final String uid;
  final String name;
  final String email;
  final String schoolId;
  final String rollNumber;
  final String className;
  final DateTime enrollmentDate;

  StudentModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.rollNumber,
    required this.className,
    required this.enrollmentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'schoolId': schoolId,
      'rollNumber': rollNumber,
      'className': className,
      'enrollmentDate': enrollmentDate.toIso8601String(),
    };
  }

  factory StudentModel.fromMap(String uid, Map<String, dynamic> map) {
    return StudentModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      className: map['className'] as String? ?? '',
      enrollmentDate: map['enrollmentDate'] != null
          ? DateTime.parse(map['enrollmentDate'])
          : DateTime.now(),
    );
  }
}

// Teacher Model
class TeacherModel {
  final String uid;
  final String name;
  final String email;
  final String schoolId;
  final String department;
  final List<String> classesHandled;
  final DateTime hireDate;

  TeacherModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.department,
    required this.classesHandled,
    required this.hireDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'schoolId': schoolId,
      'department': department,
      'classesHandled': classesHandled,
      'hireDate': hireDate.toIso8601String(),
    };
  }

  factory TeacherModel.fromMap(String uid, Map<String, dynamic> map) {
    return TeacherModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      department: map['department'] as String? ?? '',
      classesHandled: List<String>.from(map['classesHandled'] as List? ?? []),
      hireDate: map['hireDate'] != null
          ? DateTime.parse(map['hireDate'])
          : DateTime.now(),
    );
  }
}

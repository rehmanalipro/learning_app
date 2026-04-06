enum AttendanceStatus { pending, present, absent }

class AttendanceEntryModel {
  final String id;
  final String studentName;
  final String rollNumber;
  final String className;
  final String section;
  final String email;
  final DateTime submittedAt;
  final DateTime? markedAt;
  final String? photoPath;
  final AttendanceStatus status;

  const AttendanceEntryModel({
    required this.id,
    required this.studentName,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.email,
    required this.submittedAt,
    this.markedAt,
    required this.status,
    this.photoPath,
  });

  AttendanceEntryModel copyWith({
    String? id,
    String? studentName,
    String? rollNumber,
    String? className,
    String? section,
    String? email,
    DateTime? submittedAt,
    DateTime? markedAt,
    String? photoPath,
    AttendanceStatus? status,
  }) {
    return AttendanceEntryModel(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      className: className ?? this.className,
      section: section ?? this.section,
      email: email ?? this.email,
      submittedAt: submittedAt ?? this.submittedAt,
      markedAt: markedAt ?? this.markedAt,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentName': studentName,
      'rollNumber': rollNumber,
      'className': className,
      'section': section,
      'email': email,
      'submittedAt': submittedAt.toIso8601String(),
      'markedAt': markedAt?.toIso8601String(),
      'photoPath': photoPath,
      'status': status.name,
    };
  }

  factory AttendanceEntryModel.fromMap(String id, Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? AttendanceStatus.pending.name;
    return AttendanceEntryModel(
      id: id,
      studentName: map['studentName'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      email: map['email'] as String? ?? '',
      submittedAt:
          DateTime.tryParse(map['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      markedAt: DateTime.tryParse(map['markedAt'] as String? ?? ''),
      photoPath: map['photoPath'] as String?,
      status: AttendanceStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => AttendanceStatus.pending,
      ),
    );
  }
}

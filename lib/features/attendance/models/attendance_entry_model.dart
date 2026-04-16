enum AttendanceStatus { pending, present, absent }

class AttendanceEntryModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String rollNumber;
  final String className;
  final String section;
  final String email;
  final String dateKey;
  final DateTime submittedAt;
  final DateTime? markedAt;
  final String? photoPath;
  final String? notes;
  final AttendanceStatus status;

  const AttendanceEntryModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.email,
    required this.dateKey,
    required this.submittedAt,
    this.markedAt,
    required this.status,
    this.photoPath,
    this.notes,
  });

  AttendanceEntryModel copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? rollNumber,
    String? className,
    String? section,
    String? email,
    String? dateKey,
    DateTime? submittedAt,
    DateTime? markedAt,
    String? photoPath,
    String? notes,
    AttendanceStatus? status,
  }) {
    return AttendanceEntryModel(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      className: className ?? this.className,
      section: section ?? this.section,
      email: email ?? this.email,
      dateKey: dateKey ?? this.dateKey,
      submittedAt: submittedAt ?? this.submittedAt,
      markedAt: markedAt ?? this.markedAt,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'className': className,
      'section': section,
      'email': email,
      'dateKey': dateKey,
      'submittedAt': submittedAt.toIso8601String(),
      'markedAt': markedAt?.toIso8601String(),
      'photoPath': photoPath,
      'notes': notes,
      'status': status.name,
    };
  }

  factory AttendanceEntryModel.fromMap(String id, Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? AttendanceStatus.pending.name;
    final submittedAt =
        DateTime.tryParse(map['submittedAt'] as String? ?? '') ??
        DateTime.now();
    return AttendanceEntryModel(
      id: id,
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      email: map['email'] as String? ?? '',
      dateKey:
          map['dateKey'] as String? ??
          '${submittedAt.year}-${submittedAt.month.toString().padLeft(2, '0')}-${submittedAt.day.toString().padLeft(2, '0')}',
      submittedAt: submittedAt,
      markedAt: DateTime.tryParse(map['markedAt'] as String? ?? ''),
      photoPath: map['photoPath'] as String?,
      notes: map['notes'] as String?,
      status: AttendanceStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => AttendanceStatus.pending,
      ),
    );
  }
}

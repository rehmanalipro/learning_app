class HomeworkAssignmentModel {
  final String id;
  final String className;
  final String section;
  final String subject;
  final String teacherName;
  final String title;
  final String details;
  final String pdfName;
  final String? pdfPath;
  final DateTime createdAt;
  final DateTime dueDate;
  final String? solutionTitle;
  final String? solutionDescription;
  final String? solutionPdfName;
  final String? solutionPdfPath;
  final bool sendSolutionToWholeClass;
  final List<String> solutionTargetStudentNames;
  final DateTime? solutionCreatedAt;

  const HomeworkAssignmentModel({
    required this.id,
    required this.className,
    required this.section,
    required this.subject,
    required this.teacherName,
    required this.title,
    required this.details,
    required this.pdfName,
    required this.createdAt,
    required this.dueDate,
    this.pdfPath,
    this.solutionTitle,
    this.solutionDescription,
    this.solutionPdfName,
    this.solutionPdfPath,
    this.sendSolutionToWholeClass = true,
    this.solutionTargetStudentNames = const [],
    this.solutionCreatedAt,
  });

  HomeworkAssignmentModel copyWith({
    String? className,
    String? section,
    String? subject,
    String? teacherName,
    String? title,
    String? details,
    String? pdfName,
    String? pdfPath,
    DateTime? createdAt,
    DateTime? dueDate,
    String? solutionTitle,
    String? solutionDescription,
    String? solutionPdfName,
    String? solutionPdfPath,
    bool? sendSolutionToWholeClass,
    List<String>? solutionTargetStudentNames,
    DateTime? solutionCreatedAt,
  }) {
    return HomeworkAssignmentModel(
      id: id,
      className: className ?? this.className,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      details: details ?? this.details,
      pdfName: pdfName ?? this.pdfName,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      solutionTitle: solutionTitle ?? this.solutionTitle,
      solutionDescription: solutionDescription ?? this.solutionDescription,
      solutionPdfName: solutionPdfName ?? this.solutionPdfName,
      solutionPdfPath: solutionPdfPath ?? this.solutionPdfPath,
      sendSolutionToWholeClass:
          sendSolutionToWholeClass ?? this.sendSolutionToWholeClass,
      solutionTargetStudentNames:
          solutionTargetStudentNames ?? this.solutionTargetStudentNames,
      solutionCreatedAt: solutionCreatedAt ?? this.solutionCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'section': section,
      'subject': subject,
      'teacherName': teacherName,
      'title': title,
      'details': details,
      'pdfName': pdfName,
      'pdfPath': pdfPath,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'solutionTitle': solutionTitle,
      'solutionDescription': solutionDescription,
      'solutionPdfName': solutionPdfName,
      'solutionPdfPath': solutionPdfPath,
      'sendSolutionToWholeClass': sendSolutionToWholeClass,
      'solutionTargetStudentNames': solutionTargetStudentNames,
      'solutionCreatedAt': solutionCreatedAt?.toIso8601String(),
    };
  }

  factory HomeworkAssignmentModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return HomeworkAssignmentModel(
      id: id,
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      details: map['details'] as String? ?? '',
      pdfName: map['pdfName'] as String? ?? '',
      pdfPath: map['pdfPath'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      dueDate:
          DateTime.tryParse(map['dueDate'] as String? ?? '') ??
          DateTime.now(),
      solutionTitle: map['solutionTitle'] as String?,
      solutionDescription: map['solutionDescription'] as String?,
      solutionPdfName: map['solutionPdfName'] as String?,
      solutionPdfPath: map['solutionPdfPath'] as String?,
      sendSolutionToWholeClass:
          map['sendSolutionToWholeClass'] as bool? ?? true,
      solutionTargetStudentNames:
          (map['solutionTargetStudentNames'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(growable: false),
      solutionCreatedAt: DateTime.tryParse(
        map['solutionCreatedAt'] as String? ?? '',
      ),
    );
  }
}

class HomeworkSolutionModel {
  final String id;
  final String assignmentId;
  final String className;
  final String section;
  final String subject;
  final String teacherName;
  final String title;
  final String description;
  final String pdfName;
  final String? pdfPath;
  final bool sendToWholeClass;
  final List<String> targetStudentNames;
  final DateTime createdAt;

  const HomeworkSolutionModel({
    required this.id,
    required this.assignmentId,
    required this.className,
    required this.section,
    required this.subject,
    required this.teacherName,
    required this.title,
    required this.description,
    required this.pdfName,
    required this.sendToWholeClass,
    required this.targetStudentNames,
    required this.createdAt,
    this.pdfPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'className': className,
      'section': section,
      'subject': subject,
      'teacherName': teacherName,
      'title': title,
      'description': description,
      'pdfName': pdfName,
      'pdfPath': pdfPath,
      'sendToWholeClass': sendToWholeClass,
      'targetStudentNames': targetStudentNames,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HomeworkSolutionModel.fromMap(String id, Map<String, dynamic> map) {
    return HomeworkSolutionModel(
      id: id,
      assignmentId: map['assignmentId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      pdfName: map['pdfName'] as String? ?? '',
      pdfPath: map['pdfPath'] as String?,
      sendToWholeClass: map['sendToWholeClass'] as bool? ?? false,
      targetStudentNames:
          (map['targetStudentNames'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(growable: false),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

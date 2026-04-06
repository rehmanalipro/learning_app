enum HomeworkSubmissionStatus { submitted, reviewed }

class HomeworkSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentName;
  final String className;
  final String section;
  final String subject;
  final String teacherName;
  final String answerText;
  final String pdfName;
  final String? pdfPath;
  final DateTime submittedAt;
  final HomeworkSubmissionStatus status;
  final String teacherRemarks;

  const HomeworkSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentName,
    required this.className,
    required this.section,
    required this.subject,
    required this.teacherName,
    required this.answerText,
    required this.pdfName,
    required this.submittedAt,
    required this.status,
    required this.teacherRemarks,
    this.pdfPath,
  });

  HomeworkSubmissionModel copyWith({
    HomeworkSubmissionStatus? status,
    String? teacherRemarks,
  }) {
    return HomeworkSubmissionModel(
      id: id,
      assignmentId: assignmentId,
      studentName: studentName,
      className: className,
      section: section,
      subject: subject,
      teacherName: teacherName,
      answerText: answerText,
      pdfName: pdfName,
      pdfPath: pdfPath,
      submittedAt: submittedAt,
      status: status ?? this.status,
      teacherRemarks: teacherRemarks ?? this.teacherRemarks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentName': studentName,
      'className': className,
      'section': section,
      'subject': subject,
      'teacherName': teacherName,
      'answerText': answerText,
      'pdfName': pdfName,
      'pdfPath': pdfPath,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status.name,
      'teacherRemarks': teacherRemarks,
    };
  }

  factory HomeworkSubmissionModel.fromMap(String id, Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? HomeworkSubmissionStatus.submitted.name;
    return HomeworkSubmissionModel(
      id: id,
      assignmentId: map['assignmentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      answerText: map['answerText'] as String? ?? '',
      pdfName: map['pdfName'] as String? ?? '',
      pdfPath: map['pdfPath'] as String?,
      submittedAt:
          DateTime.tryParse(map['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      status: HomeworkSubmissionStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => HomeworkSubmissionStatus.submitted,
      ),
      teacherRemarks: map['teacherRemarks'] as String? ?? '',
    );
  }
}

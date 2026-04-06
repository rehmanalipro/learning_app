class ResultModel {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String section;
  final String courseCode;
  final String subject;
  final double creditHours;
  final double score;
  final double maxScore;
  final String term;
  final String examType; // midterm/final
  final String teacherId;
  final String teacherName;

  ResultModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
    required this.courseCode,
    required this.subject,
    required this.creditHours,
    required this.score,
    required this.maxScore,
    required this.term,
    required this.examType,
    required this.teacherId,
    required this.teacherName,
  });

  ResultModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? className,
    String? section,
    String? courseCode,
    String? subject,
    double? creditHours,
    double? score,
    double? maxScore,
    String? term,
    String? examType,
    String? teacherId,
    String? teacherName,
  }) {
    return ResultModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      section: section ?? this.section,
      courseCode: courseCode ?? this.courseCode,
      subject: subject ?? this.subject,
      creditHours: creditHours ?? this.creditHours,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      term: term ?? this.term,
      examType: examType ?? this.examType,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'section': section,
      'courseCode': courseCode,
      'subject': subject,
      'creditHours': creditHours,
      'score': score,
      'maxScore': maxScore,
      'term': term,
      'examType': examType,
      'teacherId': teacherId,
      'teacherName': teacherName,
    };
  }

  factory ResultModel.fromMap(String id, Map<String, dynamic> map) {
    return ResultModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      creditHours: (map['creditHours'] as num?)?.toDouble() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      maxScore: (map['maxScore'] as num?)?.toDouble() ?? 100,
      term: map['term'] as String? ?? '',
      examType: map['examType'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
    );
  }
}

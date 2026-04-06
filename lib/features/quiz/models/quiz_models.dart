class QuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  const QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
    };
  }

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      question: map['question'] as String? ?? '',
      options: (map['options'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      correctOptionIndex: map['correctOptionIndex'] as int? ?? 0,
    );
  }
}

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String section;
  final String teacherName;
  final DateTime createdAt;
  final List<QuizQuestionModel> questions;

  const QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.section,
    required this.teacherName,
    required this.createdAt,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'className': className,
      'section': section,
      'teacherName': teacherName,
      'createdAt': createdAt.toIso8601String(),
      'questions': questions.map((item) => item.toMap()).toList(growable: false),
    };
  }

  factory QuizModel.fromMap(String id, Map<String, dynamic> map) {
    return QuizModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      questions: (map['questions'] as List<dynamic>? ?? const [])
          .map((item) => QuizQuestionModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String quizTitle;
  final String studentName;
  final String studentEmail;
  final String className;
  final String section;
  final DateTime submittedAt;
  final List<int> selectedOptionIndexes;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalQuestions;

  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.studentName,
    required this.studentEmail,
    required this.className,
    required this.section,
    required this.submittedAt,
    required this.selectedOptionIndexes,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalQuestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'className': className,
      'section': section,
      'submittedAt': submittedAt.toIso8601String(),
      'selectedOptionIndexes': selectedOptionIndexes,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'totalQuestions': totalQuestions,
    };
  }

  factory QuizAttemptModel.fromMap(String id, Map<String, dynamic> map) {
    return QuizAttemptModel(
      id: id,
      quizId: map['quizId'] as String? ?? '',
      quizTitle: map['quizTitle'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentEmail: map['studentEmail'] as String? ?? '',
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      submittedAt:
          DateTime.tryParse(map['submittedAt'] as String? ?? '') ?? DateTime.now(),
      selectedOptionIndexes:
          (map['selectedOptionIndexes'] as List<dynamic>? ?? const [])
              .map((item) => (item as num).toInt())
              .toList(growable: false),
      correctAnswers: map['correctAnswers'] as int? ?? 0,
      wrongAnswers: map['wrongAnswers'] as int? ?? 0,
      totalQuestions: map['totalQuestions'] as int? ?? 0,
    );
  }
}

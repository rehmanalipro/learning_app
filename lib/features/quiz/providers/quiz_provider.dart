import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../models/quiz_models.dart';

class QuizProvider extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  static const _quizCollection = 'quizzes';
  static const _attemptCollection = 'quiz_attempts';

  final RxList<QuizModel> quizzes = <QuizModel>[].obs;
  final RxList<QuizAttemptModel> attempts = <QuizAttemptModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _firebaseService.initialize();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([loadQuizzes(), loadAttempts()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadQuizzes() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_quizCollection)
          .get();
      if (snapshot.docs.isNotEmpty) {
        quizzes.value = snapshot.docs
            .map((doc) => QuizModel.fromMap(doc.id, doc.data()))
            .toList(growable: false);
      } else if (quizzes.isEmpty) {
        final seed = _demoQuiz();
        quizzes.value = [seed];
        await _firebaseService.firestore
            .collection(_quizCollection)
            .doc(seed.id)
            .set(seed.toMap());
      }
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      if (quizzes.isEmpty) {
        quizzes.value = [_demoQuiz()];
      }
    }
  }

  Future<void> loadAttempts() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection(_attemptCollection)
          .get();
      if (snapshot.docs.isNotEmpty) {
        attempts.value = snapshot.docs
            .map((doc) => QuizAttemptModel.fromMap(doc.id, doc.data()))
            .toList(growable: false);
        attempts.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      }
    } catch (_) {}
  }

  QuizModel _demoQuiz() {
    return QuizModel(
      id: 'quiz-1',
      title: 'English Revision Quiz',
      description: 'Class 3 ke liye small revision test.',
      subject: 'English',
      className: '3',
      section: 'A',
      teacherName: 'Teacher User',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      questions: const [
        QuizQuestionModel(
          question: 'Which word is a noun?',
          options: ['Run', 'Book', 'Quickly', 'Blue'],
          correctOptionIndex: 1,
        ),
        QuizQuestionModel(
          question: 'Choose the correct spelling.',
          options: ['Beautifull', 'Beautiful', 'Beatiful', 'Beautifal'],
          correctOptionIndex: 1,
        ),
      ],
    );
  }

  Future<void> addQuiz({
    required String title,
    required String description,
    required String subject,
    required String className,
    required String section,
    required String teacherName,
    required List<QuizQuestionModel> questions,
  }) async {
    final now = DateTime.now();
    final quiz = QuizModel(
      id: 'quiz-${now.microsecondsSinceEpoch}',
      title: title,
      description: description,
      subject: subject,
      className: className,
      section: section,
      teacherName: teacherName,
      createdAt: now,
      questions: questions,
    );

    quizzes.insert(0, quiz);
    try {
      await _firebaseService.firestore
          .collection(_quizCollection)
          .doc(quiz.id)
          .set(quiz.toMap());
    } catch (_) {}
  }

  Future<QuizAttemptModel> submitAttempt({
    required QuizModel quiz,
    required String studentName,
    required String studentEmail,
    required String className,
    required String section,
    required List<int> selectedOptionIndexes,
  }) async {
    var correct = 0;
    for (var i = 0; i < quiz.questions.length; i++) {
      if (i < selectedOptionIndexes.length &&
          selectedOptionIndexes[i] == quiz.questions[i].correctOptionIndex) {
        correct++;
      }
    }

    final total = quiz.questions.length;
    final now = DateTime.now();
    final attempt = QuizAttemptModel(
      id: 'attempt-${now.microsecondsSinceEpoch}',
      quizId: quiz.id,
      quizTitle: quiz.title,
      studentName: studentName,
      studentEmail: studentEmail,
      className: className,
      section: section,
      submittedAt: now,
      selectedOptionIndexes: selectedOptionIndexes,
      correctAnswers: correct,
      wrongAnswers: total - correct,
      totalQuestions: total,
    );

    attempts.insert(0, attempt);
    try {
      await _firebaseService.firestore
          .collection(_attemptCollection)
          .doc(attempt.id)
          .set(attempt.toMap());
    } catch (_) {}
    return attempt;
  }

  List<QuizModel> quizzesForClass({
    required String className,
    required String section,
  }) {
    return quizzes
        .where(
          (item) =>
              item.className.trim() == className.trim() &&
              item.section.trim().toUpperCase() == section.trim().toUpperCase(),
        )
        .toList(growable: false);
  }

  List<QuizAttemptModel> attemptsForQuiz(String quizId) {
    return attempts
        .where((item) => item.quizId == quizId)
        .toList(growable: false);
  }
}

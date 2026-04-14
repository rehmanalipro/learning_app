import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/quiz_models.dart';

class QuizService extends GetxService {
  static const _quizzesCollection = 'quizzes';
  static const _attemptsCollection = 'quiz_attempts';

  final FirestoreCollectionService _store = FirestoreCollectionService();

  final RxList<QuizModel> quizzes = <QuizModel>[].obs;
  final RxList<QuizAttemptModel> attempts = <QuizAttemptModel>[].obs;
  final RxBool isLoading = false.obs;
  Future<void>? _loadAllFuture;

  Future<void> loadAll() async {
    final inFlight = _loadAllFuture;
    if (inFlight != null) return inFlight;

    final future = _loadAllInternal();
    _loadAllFuture = future;
    return future;
  }

  Future<void> _loadAllInternal() async {
    isLoading.value = true;
    try {
      await Future.wait([_loadQuizzes(), _loadAttempts()]);
    } finally {
      isLoading.value = false;
      _loadAllFuture = null;
    }
  }

  Future<void> _loadQuizzes() async {
    final fetched = await _store.getCollection<QuizModel>(
      path: _quizzesCollection,
      fromMap: QuizModel.fromMap,
    );
    quizzes.value = fetched..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _loadAttempts() async {
    final fetched = await _store.getCollection<QuizAttemptModel>(
      path: _attemptsCollection,
      fromMap: QuizAttemptModel.fromMap,
    );
    attempts.value = fetched
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
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

    await _store.setCollectionDocument(
      collectionPath: _quizzesCollection,
      id: quiz.id,
      data: quiz.toMap(),
    );
    quizzes.insert(0, quiz);
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

    await _store.setCollectionDocument(
      collectionPath: _attemptsCollection,
      id: attempt.id,
      data: attempt.toMap(),
    );
    attempts.insert(0, attempt);
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

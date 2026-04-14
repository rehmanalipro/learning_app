import 'package:get/get.dart';

import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

class QuizProvider extends GetxController {
  late final QuizService _quizService;

  RxList<QuizModel> get quizzes => _quizService.quizzes;
  RxList<QuizAttemptModel> get attempts => _quizService.attempts;
  RxBool get isLoading => _quizService.isLoading;

  @override
  void onInit() {
    super.onInit();
    _quizService = Get.find<QuizService>();
    loadAll();
  }

  Future<void> loadAll() => _quizService.loadAll();

  Future<void> addQuiz({
    required String title,
    required String description,
    required String subject,
    required String className,
    required String section,
    required String teacherName,
    required List<QuizQuestionModel> questions,
  }) => _quizService.addQuiz(
    title: title,
    description: description,
    subject: subject,
    className: className,
    section: section,
    teacherName: teacherName,
    questions: questions,
  );

  Future<QuizAttemptModel> submitAttempt({
    required QuizModel quiz,
    required String studentName,
    required String studentEmail,
    required String className,
    required String section,
    required List<int> selectedOptionIndexes,
  }) => _quizService.submitAttempt(
    quiz: quiz,
    studentName: studentName,
    studentEmail: studentEmail,
    className: className,
    section: section,
    selectedOptionIndexes: selectedOptionIndexes,
  );

  List<QuizModel> quizzesForClass({
    required String className,
    required String section,
  }) => _quizService.quizzesForClass(className: className, section: section);

  List<QuizAttemptModel> attemptsForQuiz(String quizId) =>
      _quizService.attemptsForQuiz(quizId);
}

//

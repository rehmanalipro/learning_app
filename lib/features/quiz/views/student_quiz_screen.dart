import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_provider.dart';

class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({super.key});

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  final QuizProvider _quizProvider = Get.find<QuizProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  final ClassBindingService _classBinding = Get.find<ClassBindingService>();

  QuizModel? _activeQuiz;
  int _currentQuestionIndex = 0;
  List<int> _selectedAnswers = <int>[];
  QuizAttemptModel? _latestResult;

  Future<void> _refreshScreen() async {
    await Future.wait([
      _quizProvider.loadAll(),
      _profileProvider.loadProfiles(),
    ]);
  }

  void _startQuiz(QuizModel quiz) {
    setState(() {
      _activeQuiz = quiz;
      _currentQuestionIndex = 0;
      _selectedAnswers = List<int>.filled(quiz.questions.length, -1);
      _latestResult = null;
    });
  }

  Future<void> _goNext() async {
    final quiz = _activeQuiz;
    if (quiz == null) return;
    if (_selectedAnswers[_currentQuestionIndex] < 0) {
      Get.snackbar(
        'Select answer',
        'Please select an option before proceeding.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_currentQuestionIndex < quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      return;
    }

    final profile = _profileProvider.profileFor('Student');
    final result = await _quizProvider.submitAttempt(
      quiz: quiz,
      studentName: profile.name,
      studentEmail: profile.email,
      className: profile.className ?? quiz.className,
      section: profile.section ?? quiz.section,
      selectedOptionIndexes: _selectedAnswers,
    );

    setState(() {
      _latestResult = result;
      _activeQuiz = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final className = _classBinding.className.value.trim();
    final section = _classBinding.section.value.trim().toUpperCase();
    final quizzes = _quizProvider.quizzesForClass(
      className: className,
      section: section,
    );

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: const AppScreenHeader(
        title: 'Quiz',
        subtitle: 'Attempt class quiz and see result instantly',
      ),
      body: AppRefreshScope(
        onRefresh: _refreshScreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ResponsiveContent(
            maxWidth: 980,
            child: _activeQuiz != null
                ? _buildAttemptView(context, _activeQuiz!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.announcementCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'You will get an instant result right after submitting the quiz.',
                          style: TextStyle(
                            color: palette.inverseText.withValues(alpha: 0.92),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_latestResult != null)
                        _buildResultCard(context, _latestResult!),
                      if (_latestResult != null) const SizedBox(height: 18),
                      if (className.isEmpty || section.isEmpty)
                        const _EmptyStateCard(
                          title: 'Class information not found',
                          message:
                              'Class information not found. Please contact your teacher.',
                        )
                      else if (quizzes.isEmpty)
                        _EmptyStateCard(
                          title: 'No quiz available',
                          message:
                              'Teacher jab Class $className Section $section ke liye quiz post karega to yahan show hoga.',
                        )
                      else
                        ...quizzes.map((quiz) => _buildQuizCard(context, quiz)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz) {
    final palette = context.appPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quiz.title,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              _Chip(label: '${quiz.questions.length} questions'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${quiz.subject} | Class ${quiz.className}-${quiz.section}',
            style: TextStyle(color: palette.subtext),
          ),
          const SizedBox(height: 4),
          Text(
            'Teacher: ${quiz.teacherName}',
            style: TextStyle(color: palette.subtext),
          ),
          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              quiz.description,
              style: TextStyle(color: palette.text, height: 1.5),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startQuiz(quiz),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.inverseText,
              ),
              child: const Text('Start Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptView(BuildContext context, QuizModel quiz) {
    final palette = context.appPalette;
    final question = quiz.questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == quiz.questions.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  quiz.title,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              _Chip(
                label:
                    'Question ${_currentQuestionIndex + 1}/${quiz.questions.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.question,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(question.options.length, (index) {
                final selected = _selectedAnswers[_currentQuestionIndex] == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAnswers[_currentQuestionIndex] = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected ? palette.softCard : palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? palette.primary : palette.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected ? palette.primary : palette.subtext,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: TextStyle(color: palette.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.inverseText,
                  ),
                  child: Text(isLast ? 'Finish Quiz' : 'Next Question'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, QuizAttemptModel result) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryBox(label: 'Right', value: '${result.correctAnswers}'),
        _SummaryBox(label: 'Wrong', value: '${result.wrongAnswers}'),
        _SummaryBox(label: 'Total', value: '${result.totalQuestions}'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.subtext)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 36, color: palette.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.subtext, height: 1.5),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_provider.dart';

class TeacherQuizScreen extends StatefulWidget {
  final String roleLabel;

  const TeacherQuizScreen({
    super.key,
    this.roleLabel = 'Teacher',
  });

  @override
  State<TeacherQuizScreen> createState() => _TeacherQuizScreenState();
}

class _TeacherQuizScreenState extends State<TeacherQuizScreen> {
  final QuizProvider _quizProvider = Get.find<QuizProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();

  final List<String> _classes = const ['1', '2', '3', '4', '5'];
  final List<String> _sections = const ['A', 'B', 'C'];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController(
    text: 'English',
  );
  final TextEditingController _teacherNameController = TextEditingController();

  String _selectedClass = '3';
  String _selectedSection = 'A';
  final List<_QuestionDraft> _questionDrafts = [];

  bool get _isPrincipalView => widget.roleLabel.toLowerCase() == 'principal';

  @override
  void initState() {
    super.initState();
    final profile = _profileProvider.profileFor(widget.roleLabel);
    _teacherNameController.text = profile.name.trim().isEmpty
        ? '${widget.roleLabel} User'
        : profile.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _teacherNameController.dispose();
    for (final item in _questionDrafts) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshScreen() => _quizProvider.loadAll();

  void _openCreateQuizSheet() {
    final palette = context.appPalette;
    if (_questionDrafts.isEmpty) {
      _questionDrafts.add(_QuestionDraft());
    }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Quiz',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TextField(controller: _titleController, label: 'Quiz Title'),
                    const SizedBox(height: 12),
                    _TextField(controller: _subjectController, label: 'Subject'),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _teacherNameController,
                      label: 'Teacher Name',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField(
                            label: 'Class',
                            value: _selectedClass,
                            items: _classes,
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() {
                                _selectedClass = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DropdownField(
                            label: 'Section',
                            value: _selectedSection,
                            items: _sections,
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() {
                                _selectedSection = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _descriptionController,
                      label: 'Quiz Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Questions',
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._questionDrafts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _QuestionDraftCard(
                        index: index,
                        draft: item,
                        onRemove: _questionDrafts.length == 1
                            ? null
                            : () {
                                setModalState(() {
                                  item.dispose();
                                  _questionDrafts.removeAt(index);
                                });
                              },
                        onChanged: () => setModalState(() {}),
                      );
                    }),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            _questionDrafts.add(_QuestionDraft());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: palette.inverseText,
                        ),
                        child: const Text('Post Quiz'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _saveQuiz() async {
    final validQuestions = <QuizQuestionModel>[];
    for (final draft in _questionDrafts) {
      final questionText = draft.questionController.text.trim();
      final options = draft.optionControllers
          .map((controller) => controller.text.trim())
          .toList(growable: false);
      if (questionText.isEmpty || options.any((item) => item.isEmpty)) {
        Get.snackbar(
          'Incomplete question',
          'Har question aur us ke 4 options fill karein.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      validQuestions.add(
        QuizQuestionModel(
          question: questionText,
          options: options,
          correctOptionIndex: draft.correctOptionIndex,
        ),
      );
    }

    if (_titleController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _teacherNameController.text.trim().isEmpty ||
        validQuestions.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Quiz title, subject, teacher aur questions required hain.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _quizProvider.addQuiz(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      subject: _subjectController.text.trim(),
      className: _selectedClass,
      section: _selectedSection,
      teacherName: _teacherNameController.text.trim(),
      questions: validQuestions,
    );

    _titleController.clear();
    _descriptionController.clear();
    _subjectController.text = 'English';
    for (final item in _questionDrafts) {
      item.dispose();
    }
    _questionDrafts
      ..clear()
      ..add(_QuestionDraft());
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppScreenHeader(
        title: '${widget.roleLabel} Quiz',
        subtitle: _isPrincipalView
            ? 'View all quiz performance'
            : 'Create quizzes and review attempts',
      ),
      floatingActionButton: _isPrincipalView
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateQuizSheet,
              backgroundColor: palette.primary,
              foregroundColor: palette.inverseText,
              icon: const Icon(Icons.add),
              label: const Text('Create Quiz'),
            ),
      body: AppRefreshScope(
        onRefresh: _refreshScreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ResponsiveContent(
            maxWidth: 1040,
            child: Column(
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
                    _isPrincipalView
                        ? 'Principal yahan har quiz ki student performance dekh sakta hai.'
                        : 'Teacher quiz post karega, 4 options aur correct answer set karega, aur yahin par student results bhi dekh sakega.',
                    style: TextStyle(
                      color: palette.inverseText.withValues(alpha: 0.92),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_quizProvider.quizzes.isEmpty)
                  _EmptyStateCard(
                    title: 'No quiz posted yet',
                    message: _isPrincipalView
                        ? 'Teacher jab quiz create karega to yahan results ke sath show hoga.'
                        : 'Create Quiz button se pehla quiz post karein.',
                  )
                else
                  ..._quizProvider.quizzes.map((quiz) {
                    final attempts = _quizProvider.attemptsForQuiz(quiz.id);
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
                          Text(
                            quiz.title,
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${quiz.subject} | Class ${quiz.className}-${quiz.section}',
                            style: TextStyle(color: palette.subtext),
                          ),
                          const SizedBox(height: 10),
                          if (attempts.isEmpty)
                            Text(
                              'Abhi kisi student ne attempt nahi kiya.',
                              style: TextStyle(color: palette.subtext),
                            )
                          else
                            ...attempts.map((attempt) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: palette.surfaceAlt,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attempt.studentName,
                                      style: TextStyle(
                                        color: palette.text,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Right: ${attempt.correctAnswers} | Wrong: ${attempt.wrongAnswers} | Total: ${attempt.totalQuestions}',
                                      style: TextStyle(color: palette.subtext),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionDraft {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int correctOptionIndex = 0;

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }
}

class _QuestionDraftCard extends StatelessWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _QuestionDraftCard({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          _TextField(controller: draft.questionController, label: 'Question'),
          const SizedBox(height: 10),
          ...List.generate(4, (optionIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Radio<int>(
                    value: optionIndex,
                    groupValue: draft.correctOptionIndex,
                    onChanged: (value) {
                      if (value == null) return;
                      draft.correctOptionIndex = value;
                      onChanged();
                    },
                  ),
                  Expanded(
                    child: _TextField(
                      controller: draft.optionControllers[optionIndex],
                      label: 'Option ${optionIndex + 1}',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: onChanged,
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

import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/homework_assignment_model.dart';
import '../models/homework_submission_model.dart';

class HomeworkService extends GetxService {
  static const _assignmentsCollection = 'homework_assignments';
  static const _submissionsCollection = 'homework_submissions';

  final FirestoreCollectionService _store = FirestoreCollectionService();

  final RxList<HomeworkAssignmentModel> assignments =
      <HomeworkAssignmentModel>[].obs;
  final RxList<HomeworkSolutionModel> solutions = <HomeworkSolutionModel>[].obs;
  final RxList<HomeworkSubmissionModel> submissions =
      <HomeworkSubmissionModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadAssignments(),
        _loadSubmissions(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAssignments() async {
    final fetched = await _store.getCollection<HomeworkAssignmentModel>(
      path: _assignmentsCollection,
      fromMap: HomeworkAssignmentModel.fromMap,
    );

    if (fetched.isEmpty && assignments.isEmpty) {
      final seed = _seedAssignment();
      await _store.setCollectionDocument(
        collectionPath: _assignmentsCollection,
        id: seed.id,
        data: seed.toMap(),
      );
      assignments.value = [seed];
      solutions.clear();
    } else {
      assignments.value = fetched..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _syncSolutionsFromAssignments();
    }
  }

  Future<void> _loadSubmissions() async {
    final fetched = await _store.getCollection<HomeworkSubmissionModel>(
      path: _submissionsCollection,
      fromMap: HomeworkSubmissionModel.fromMap,
    );
    submissions.value = fetched
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  HomeworkAssignmentModel _seedAssignment() {
    return HomeworkAssignmentModel(
      id: 'hw-1',
      className: '3',
      section: 'A',
      subject: 'English',
      teacherName: 'Sara Ahmed',
      title: 'Reading Summary',
      details: 'Read chapter 2 and upload a short summary in PDF format.',
      pdfName: 'reading_summary_task.pdf',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );
  }

  void _syncSolutionsFromAssignments() {
    final mapped = assignments
        .where((item) => (item.solutionTitle ?? '').trim().isNotEmpty)
        .map(
          (item) => HomeworkSolutionModel(
            id: 'sol-${item.id}',
            assignmentId: item.id,
            className: item.className,
            section: item.section,
            subject: item.subject,
            teacherName: item.teacherName,
            title: item.solutionTitle ?? '',
            description: item.solutionDescription ?? '',
            pdfName: item.solutionPdfName ?? '',
            pdfPath: item.solutionPdfPath,
            sendToWholeClass: item.sendSolutionToWholeClass,
            targetStudentNames: item.solutionTargetStudentNames,
            createdAt: item.solutionCreatedAt ?? item.createdAt,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    solutions.value = mapped;
  }

  Future<void> addAssignment({
    required String className,
    required String section,
    required String subject,
    required String teacherName,
    required String title,
    required String details,
    required String pdfName,
    required DateTime dueDate,
    String? pdfPath,
  }) async {
    final now = DateTime.now();
    final item = HomeworkAssignmentModel(
      id: 'hw-${now.microsecondsSinceEpoch}',
      className: className,
      section: section,
      subject: subject,
      teacherName: teacherName,
      title: title,
      details: details,
      pdfName: pdfName,
      pdfPath: pdfPath,
      createdAt: now,
      dueDate: dueDate,
    );

    await _store.setCollectionDocument(
      collectionPath: _assignmentsCollection,
      id: item.id,
      data: item.toMap(),
    );
    assignments.insert(0, item);
    _syncSolutionsFromAssignments();
  }

  Future<void> addSolution({
    required String assignmentId,
    required String className,
    required String section,
    required String subject,
    required String teacherName,
    required String title,
    required String description,
    required String pdfName,
    required bool sendToWholeClass,
    required List<String> targetStudentNames,
    String? pdfPath,
  }) async {
    final index = assignments.indexWhere((item) => item.id == assignmentId);
    if (index == -1) return;

    final updated = assignments[index].copyWith(
      className: className,
      section: section,
      subject: subject,
      teacherName: teacherName,
      solutionTitle: title,
      solutionDescription: description,
      solutionPdfName: pdfName,
      solutionPdfPath: pdfPath,
      sendSolutionToWholeClass: sendToWholeClass,
      solutionTargetStudentNames: targetStudentNames,
      solutionCreatedAt: DateTime.now(),
    );

    await _store.setCollectionDocument(
      collectionPath: _assignmentsCollection,
      id: updated.id,
      data: updated.toMap(),
      merge: true,
    );
    assignments[index] = updated;
    _syncSolutionsFromAssignments();
  }

  List<HomeworkSolutionModel> solutionsForAssignment(String assignmentId) {
    return solutions
        .where((item) => item.assignmentId == assignmentId)
        .toList(growable: false);
  }

  Future<void> submitHomework({
    required String assignmentId,
    required String studentName,
    required String className,
    required String section,
    required String subject,
    required String teacherName,
    required String answerText,
    required String pdfName,
    String? pdfPath,
  }) async {
    final now = DateTime.now();
    final item = HomeworkSubmissionModel(
      id: 'sub-${now.microsecondsSinceEpoch}',
      assignmentId: assignmentId,
      studentName: studentName,
      className: className,
      section: section,
      subject: subject,
      teacherName: teacherName,
      answerText: answerText,
      pdfName: pdfName,
      pdfPath: pdfPath,
      submittedAt: now,
      status: HomeworkSubmissionStatus.submitted,
      teacherRemarks: '',
    );

    await _store.setCollectionDocument(
      collectionPath: _submissionsCollection,
      id: item.id,
      data: item.toMap(),
    );
    submissions.insert(0, item);
  }

  Future<void> reviewSubmission({
    required String submissionId,
    required String teacherRemarks,
  }) async {
    final index = submissions.indexWhere((item) => item.id == submissionId);
    if (index == -1) return;

    final updated = submissions[index].copyWith(
      status: HomeworkSubmissionStatus.reviewed,
      teacherRemarks: teacherRemarks,
    );
    await _store.setCollectionDocument(
      collectionPath: _submissionsCollection,
      id: updated.id,
      data: updated.toMap(),
      merge: true,
    );
    submissions[index] = updated;
  }

  List<HomeworkSubmissionModel> submissionsForAssignment(String assignmentId) {
    return submissions
        .where((item) => item.assignmentId == assignmentId)
        .toList(growable: false);
  }
}

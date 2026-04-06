import 'package:get/get.dart';

import '../models/homework_assignment_model.dart';
import '../models/homework_submission_model.dart';
import '../services/homework_service.dart';

class HomeworkController extends GetxController {
  final HomeworkService _service = Get.find<HomeworkService>();

  RxList<HomeworkAssignmentModel> get assignments => _service.assignments;
  RxList<HomeworkSolutionModel> get solutions => _service.solutions;
  RxList<HomeworkSubmissionModel> get submissions => _service.submissions;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() => _service.loadAll();

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
  }) {
    return _service.addAssignment(
      className: className,
      section: section,
      subject: subject,
      teacherName: teacherName,
      title: title,
      details: details,
      pdfName: pdfName,
      dueDate: dueDate,
      pdfPath: pdfPath,
    );
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
  }) {
    return _service.addSolution(
      assignmentId: assignmentId,
      className: className,
      section: section,
      subject: subject,
      teacherName: teacherName,
      title: title,
      description: description,
      pdfName: pdfName,
      sendToWholeClass: sendToWholeClass,
      targetStudentNames: targetStudentNames,
      pdfPath: pdfPath,
    );
  }

  List<HomeworkSolutionModel> solutionsForAssignment(String assignmentId) {
    return _service.solutionsForAssignment(assignmentId);
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
  }) {
    return _service.submitHomework(
      assignmentId: assignmentId,
      studentName: studentName,
      className: className,
      section: section,
      subject: subject,
      teacherName: teacherName,
      answerText: answerText,
      pdfName: pdfName,
      pdfPath: pdfPath,
    );
  }

  Future<void> reviewSubmission({
    required String submissionId,
    required String teacherRemarks,
  }) {
    return _service.reviewSubmission(
      submissionId: submissionId,
      teacherRemarks: teacherRemarks,
    );
  }

  List<HomeworkSubmissionModel> submissionsForAssignment(String assignmentId) {
    return _service.submissionsForAssignment(assignmentId);
  }
}

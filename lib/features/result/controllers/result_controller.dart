import 'package:get/get.dart';

import '../models/result_model.dart';
import '../services/result_service.dart';

class ResultController extends GetxController {
  final ResultService _service = Get.find<ResultService>();

  RxList<ResultModel> get results => _service.results;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() => _service.getAll();

  Future<void> loadStudent(String studentId) async {
    results.value = await _service.getByStudent(studentId);
  }

  Future<void> loadStudentTerm({
    required String studentId,
    required String term,
  }) async {
    results.value = await _service.getByStudentTerm(
      studentId: studentId,
      term: term,
    );
  }

  Future<void> updateResult({
    required String resultId,
    required double score,
    required double maxScore,
  }) async {
    await _service.updateScore(
      resultId: resultId,
      score: score,
      maxScore: maxScore,
    );
  }

  Future<void> upsertResult(ResultModel result) async {
    await _service.upsertResult(result);
  }

  Future<void> loadClassTermExam({
    required String className,
    required String section,
    required String term,
    required String examType,
  }) async {
    results.value = await _service.getByClassTermExam(
      className: className,
      section: section,
      term: term,
      examType: examType,
    );
  }
}

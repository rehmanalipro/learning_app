import 'package:get/get.dart';
import '../models/result_model.dart';
import '../services/result_service.dart';

class ResultProvider extends GetxController {
  late final ResultService _resultService;
  RxList<ResultModel> get results => _resultService.results;
  RxBool get isLoading => _resultService.isLoading;

  @override
  void onInit() {
    super.onInit();
    _resultService = Get.find<ResultService>();
  }

  Future<void> loadAll() => _resultService.getAll();

  Future<void> loadStudent(String studentId) async {
    results.value = await _resultService.getByStudent(studentId);
  }

  Future<void> loadStudentTerm({
    required String studentId,
    required String term,
  }) async {
    results.value = await _resultService.getByStudentTerm(
      studentId: studentId,
      term: term,
    );
  }

  Future<void> loadClassResults({
    required String className,
    String section = 'A',
  }) async {
    results.value = await _resultService.getByClass(
      className: className,
      section: section,
    );
  }

  Future<void> updateResult({
    required String resultId,
    required double score,
    required double maxScore,
  }) async {
    await _resultService.updateScore(
      resultId: resultId,
      score: score,
      maxScore: maxScore,
    );
  }

  Future<void> upsertResult(ResultModel result) async {
    await _resultService.upsertResult(result);
  }

  Future<void> loadClassTermExam({
    required String className,
    required String section,
    required String term,
    required String examType,
  }) async {
    results.value = await _resultService.getByClassTermExam(
      className: className,
      section: section,
      term: term,
      examType: examType,
    );
  }
}

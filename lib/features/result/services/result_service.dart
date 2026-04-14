import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/result_model.dart';

class ResultService extends GetxService {
  static const _collection = 'results';
  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<ResultModel> results = <ResultModel>[].obs;
  final RxBool isLoading = false.obs;
  Future<List<ResultModel>>? _resultsLoadFuture;

  Future<List<ResultModel>> getAll() async {
    final inFlight = _resultsLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _getAllInternal();
    _resultsLoadFuture = future;
    return future;
  }

  Future<List<ResultModel>> _getAllInternal() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<ResultModel>(
        path: _collection,
        fromMap: ResultModel.fromMap,
      );
      results.value = fetched;
      return fetched;
    } finally {
      isLoading.value = false;
      _resultsLoadFuture = null;
    }
  }

  Future<List<ResultModel>> getByStudent(String studentId) async {
    return (await getAll()).where((e) => e.studentId == studentId).toList();
  }

  Future<List<ResultModel>> getByClass({
    required String className,
    required String section,
  }) async {
    return (await getAll())
        .where((e) => e.className == className && e.section == section)
        .toList();
  }

  Future<List<ResultModel>> getByClassTermExam({
    required String className,
    required String section,
    required String term,
    required String examType,
  }) async {
    return (await getAll())
        .where(
          (e) =>
              e.className == className &&
              e.section == section &&
              e.term == term &&
              e.examType == examType,
        )
        .toList();
  }

  Future<List<ResultModel>> getByStudentTerm({
    required String studentId,
    required String term,
  }) async {
    return (await getByStudent(
      studentId,
    )).where((e) => e.term == term).toList();
  }

  Future<void> updateScore({
    required String resultId,
    required double score,
    required double maxScore,
  }) async {
    final all = await getAll();
    final existing = all.firstWhereOrNull((item) => item.id == resultId);
    if (existing == null) throw Exception('Result not found');

    final updated = existing.copyWith(score: score, maxScore: maxScore);
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: resultId,
      data: updated.toMap(),
      merge: true,
    );
    final index = results.indexWhere((item) => item.id == resultId);
    if (index != -1) results[index] = updated;
  }

  Future<void> upsertResult(ResultModel result) async {
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: result.id,
      data: result.toMap(),
      merge: true,
    );
    final index = results.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      results.add(result);
    } else {
      results[index] = result;
    }
  }

  Future<void> deleteResult(String resultId) async {
    await _store.deleteCollectionDocument(
      collectionPath: _collection,
      id: resultId,
    );
    results.removeWhere((item) => item.id == resultId);
  }

  String buildResultId({
    required String studentKey,
    required String subject,
    required String term,
    required String examType,
  }) {
    final sanitizedTerm = term.replaceAll(' ', '_');
    final sanitizedExamType = examType.replaceAll(' ', '_');
    final sanitizedSubject = subject.replaceAll(' ', '_');
    return 'result_${studentKey}_${sanitizedSubject}_${sanitizedTerm}_$sanitizedExamType';
  }

  /// Upserts one result document per student in [roster].
  ///
  /// Document ID pattern:
  /// `result_<studentProfileId>_<subject>_<term>_<examType>`
  /// (spaces in subject/term/examType are replaced with underscores).
  Future<void> bulkUpsertResults({
    required List<Map<String, dynamic>> roster,
    required String className,
    required String section,
    required String subject,
    required String term,
    required String examType,
    required String teacherId,
    required String teacherName,
    required Map<String, ({double score, double maxScore})> scores,
  }) async {
    for (final student in roster) {
      final studentKey =
          student['studentProfileId'] as String? ??
          student['uid'] as String? ??
          '';
      if (studentKey.isEmpty) continue;

      final entry = scores[studentKey];
      final score = entry?.score ?? 0.0;
      final maxScore = entry?.maxScore ?? 0.0;

      final docId = buildResultId(
        studentKey: studentKey,
        subject: subject,
        term: term,
        examType: examType,
      );

      final result = ResultModel(
        id: docId,
        studentId: studentKey,
        studentUid: student['linkedUserUid'] as String? ?? '',
        studentName: student['name'] as String? ?? '',
        studentEmail: student['email'] as String? ?? '',
        admissionNo: student['admissionNo'] as String? ?? '',
        rollNumber: student['rollNumber'] as String? ?? '',
        className: className,
        section: section,
        courseCode: '',
        subject: subject,
        creditHours: 1,
        score: score,
        maxScore: maxScore,
        term: term,
        examType: examType,
        teacherId: teacherId,
        teacherName: teacherName,
        remarks: '',
      );

      await upsertResult(result);
    }
  }

  /// Returns results where [studentId] matches the master student profile id.
  Future<List<ResultModel>> getByStudentId(String studentProfileId) async {
    return (await getAll())
        .where((e) => e.studentId == studentProfileId)
        .toList();
  }
}

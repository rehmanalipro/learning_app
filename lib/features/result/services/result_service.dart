import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/result_model.dart';

class ResultService extends GetxService {
  static const _collection = 'results';
  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxList<ResultModel> results = <ResultModel>[].obs;
  final RxBool isLoading = false.obs;

  static List<ResultModel> _buildDemoResults() {
    const subjectMap = <String, List<Map<String, Object>>>{
      '1': [
        {'code': 'ENG-101', 'subject': 'English', 'ch': 1.0, 'score': 84.0},
        {'code': 'MTH-101', 'subject': 'Mathematics', 'ch': 1.0, 'score': 91.0},
      ],
      '2': [
        {'code': 'ENG-201', 'subject': 'English Grammar', 'ch': 1.0, 'score': 80.0},
        {'code': 'SCI-201', 'subject': 'General Science', 'ch': 1.0, 'score': 86.0},
      ],
      '3': [
        {'code': 'URD-301', 'subject': 'Urdu', 'ch': 1.0, 'score': 78.0},
        {'code': 'MTH-301', 'subject': 'Mathematics', 'ch': 1.0, 'score': 88.0},
      ],
      '4': [
        {'code': 'SCI-401', 'subject': 'Science', 'ch': 1.0, 'score': 83.0},
        {'code': 'SST-401', 'subject': 'Social Studies', 'ch': 1.0, 'score': 76.0},
      ],
      '5': [
        {'code': 'ENG-501', 'subject': 'Advanced English', 'ch': 1.0, 'score': 82.0},
        {'code': 'CMP-501', 'subject': 'Computer Basics', 'ch': 1.0, 'score': 89.0},
      ],
    };

    final items = <ResultModel>[];
    subjectMap.forEach((className, entries) {
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        items.add(
          ResultModel(
            id: 'r-$className-$i',
            studentId: 's-001',
            studentName: 'Student User',
            className: className,
            section: 'A',
            courseCode: entry['code']! as String,
            subject: entry['subject']! as String,
            creditHours: entry['ch']! as double,
            score: entry['score']! as double,
            maxScore: 100,
            term: 'Annual',
            examType: 'Final',
            teacherId: 't-00$className',
            teacherName: 'Teacher $className',
          ),
        );
      }
    });
    return items;
  }

  Future<void> _seedIfEmpty() async {
    final existing = await _store.getCollection<ResultModel>(
      path: _collection,
      fromMap: ResultModel.fromMap,
    );
    if (existing.isNotEmpty) return;
    for (final item in _buildDemoResults()) {
      await _store.setCollectionDocument(
        collectionPath: _collection,
        id: item.id,
        data: item.toMap(),
      );
    }
  }

  Future<List<ResultModel>> getAll() async {
    isLoading.value = true;
    try {
      await _seedIfEmpty();
      final fetched = await _store.getCollection<ResultModel>(
        path: _collection,
        fromMap: ResultModel.fromMap,
      );
      results.value = fetched;
      return fetched;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ResultModel>> getByStudent(String studentId) async {
    return (await getAll()).where((e) => e.studentId == studentId).toList();
  }

  Future<List<ResultModel>> getBySubject({required String subject}) async {
    return (await getAll())
        .where((e) => e.subject.toLowerCase() == subject.toLowerCase())
        .toList();
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
    ResultModel? existing;
    for (final item in all) {
      if (item.id == resultId) {
        existing = item;
        break;
      }
    }
    if (existing == null) {
      throw Exception('Result not found');
    }
    final updated = existing.copyWith(score: score, maxScore: maxScore);
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: resultId,
      data: updated.toMap(),
      merge: true,
    );
    final index = results.indexWhere((item) => item.id == resultId);
    if (index != -1) {
      results[index] = updated;
    }
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
}

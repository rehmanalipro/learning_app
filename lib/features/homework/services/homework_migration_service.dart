import '../../../core/services/firestore_collection_service.dart';
import '../models/homework_assignment_model.dart';

class HomeworkMigrationSummary {
  final int scannedSolutions;
  final int migratedSolutions;
  final int skippedSolutions;
  final int deletedSolutions;

  const HomeworkMigrationSummary({
    required this.scannedSolutions,
    required this.migratedSolutions,
    required this.skippedSolutions,
    required this.deletedSolutions,
  });
}

class HomeworkMigrationService {
  static const _assignmentsCollection = 'homework_assignments';
  static const _legacySolutionsCollection = 'homework_solutions';

  final FirestoreCollectionService _store = FirestoreCollectionService();

  Future<HomeworkMigrationSummary> migrateLegacySolutions({
    bool deleteSource = false,
  }) async {
    final assignments = await _store.getCollection<HomeworkAssignmentModel>(
      path: _assignmentsCollection,
      fromMap: HomeworkAssignmentModel.fromMap,
    );
    final solutions = await _store.getCollection<HomeworkSolutionModel>(
      path: _legacySolutionsCollection,
      fromMap: HomeworkSolutionModel.fromMap,
    );

    final assignmentById = {
      for (final assignment in assignments) assignment.id: assignment,
    };

    var migrated = 0;
    var skipped = 0;
    var deleted = 0;

    for (final solution in solutions) {
      final assignment = assignmentById[solution.assignmentId];
      if (assignment == null) {
        skipped++;
        continue;
      }

      final alreadyMigrated =
          (assignment.solutionTitle ?? '').trim().isNotEmpty &&
          (assignment.solutionPdfName ?? '').trim().isNotEmpty;

      if (!alreadyMigrated) {
        final updated = assignment.copyWith(
          solutionTitle: solution.title,
          solutionDescription: solution.description,
          solutionPdfName: solution.pdfName,
          solutionPdfPath: solution.pdfPath,
          sendSolutionToWholeClass: solution.sendToWholeClass,
          solutionTargetStudentNames: solution.targetStudentNames,
          solutionCreatedAt: solution.createdAt,
        );

        await _store.setCollectionDocument(
          collectionPath: _assignmentsCollection,
          id: updated.id,
          data: updated.toMap(),
          merge: true,
        );

        assignmentById[updated.id] = updated;
        migrated++;
      } else {
        skipped++;
      }

      if (deleteSource) {
        await _store.deleteCollectionDocument(
          collectionPath: _legacySolutionsCollection,
          id: solution.id,
        );
        deleted++;
      }
    }

    return HomeworkMigrationSummary(
      scannedSolutions: solutions.length,
      migratedSolutions: migrated,
      skippedSolutions: skipped,
      deletedSolutions: deleted,
    );
  }
}

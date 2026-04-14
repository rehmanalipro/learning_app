// ignore_for_file: avoid_print
import 'package:firebase_core/firebase_core.dart';

import 'package:learning_app/features/homework/services/homework_migration_service.dart';
import 'package:learning_app/firebase_options.dart';

Future<void> main(List<String> args) async {
  final deleteSource = args.contains('--delete-source');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final migration = HomeworkMigrationService();
  final summary = await migration.migrateLegacySolutions(
    deleteSource: deleteSource,
  );

  print('Homework solution migration completed.');
  print('Scanned: ${summary.scannedSolutions}');
  print('Migrated: ${summary.migratedSolutions}');
  print('Skipped: ${summary.skippedSolutions}');
  print('Deleted source docs: ${summary.deletedSolutions}');
}

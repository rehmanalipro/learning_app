import 'package:firebase_core/firebase_core.dart';

import '../lib/features/homework/services/homework_migration_service.dart';
import '../lib/firebase_options.dart';

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

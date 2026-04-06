import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile({
    required String localPath,
    required String folder,
    String? fileName,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final resolvedName =
          fileName ?? '${DateTime.now().microsecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final ref = _storage.ref().child(folder).child(resolvedName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}

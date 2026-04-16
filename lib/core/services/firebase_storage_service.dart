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
      // ignore: avoid_print
      print('[Storage] Starting upload from: $localPath');

      final file = File(localPath);

      // Read file as bytes (works with both file paths and content URIs)
      final bytes = await file.readAsBytes();

      // ignore: avoid_print
      print('[Storage] File read successfully, size: ${bytes.length} bytes');

      final resolvedName =
          fileName ??
          '${DateTime.now().microsecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final ref = _storage.ref().child(folder).child(resolvedName);

      // ignore: avoid_print
      print('[Storage] Uploading to: $folder/$resolvedName');

      // Upload bytes with metadata
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: _getContentType(localPath)),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // ignore: avoid_print
      print('[Storage] Upload complete, getting download URL...');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // ignore: avoid_print
      print('[Storage] Download URL obtained: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('[Storage Error] Firebase: ${e.code} - ${e.message}');
      // ignore: avoid_print
      print('[Storage Error] Stack trace: ${e.stackTrace}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[Storage Error] General error: $e');
      // ignore: avoid_print
      print('[Storage Error] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  String _getContentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/app_exception.dart';
import 'firebase_service.dart';

class FirestoreCollectionService {
  final FirebaseService _firebaseService = FirebaseService();

  FirestoreCollectionService() {
    _firebaseService.initialize();
  }

  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(String id, Map<String, dynamic> data) fromMap,
  }) async {
    return _guard(() async {
      final snapshot = await _firebaseService.firestore.collection(path).get();
      return snapshot.docs
          .map((doc) => fromMap(doc.id, doc.data()))
          .toList(growable: false);
    }, 'Unable to load data from $path');
  }

  Future<T?> getDocument<T>({
    required String path,
    required T Function(String id, Map<String, dynamic> data) fromMap,
  }) async {
    return _guard(() async {
      final snapshot = await _firebaseService.firestore.doc(path).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return fromMap(snapshot.id, snapshot.data()!);
    }, 'Unable to load document $path');
  }

  Future<Map<String, dynamic>?> getRawDocument(String path) async {
    return _guard(() async {
      final snapshot = await _firebaseService.firestore.doc(path).get();
      return snapshot.data();
    }, 'Unable to load document $path');
  }

  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    return _guard(() async {
      await _firebaseService.firestore.doc(path).set(
            data,
            SetOptions(merge: merge),
          );
    }, 'Unable to save document $path');
  }

  Future<void> setCollectionDocument({
    required String collectionPath,
    required String id,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    return _guard(() async {
      await _firebaseService.firestore
          .collection(collectionPath)
          .doc(id)
          .set(data, SetOptions(merge: merge));
    }, 'Unable to save document $collectionPath/$id');
  }

  Future<void> deleteCollectionDocument({
    required String collectionPath,
    required String id,
  }) async {
    return _guard(() async {
      await _firebaseService.firestore.collection(collectionPath).doc(id).delete();
    }, 'Unable to delete document $collectionPath/$id');
  }

  Future<R> _guard<R>(
    Future<R> Function() action,
    String fallbackMessage,
  ) async {
    try {
      return await action();
    } on FirebaseException catch (e, stackTrace) {
      throw AppException(
        e.message ?? fallbackMessage,
        cause: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw AppException(
        fallbackMessage,
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}

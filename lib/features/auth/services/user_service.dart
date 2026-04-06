import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';

class UserService extends GetxService {
  static const _collection = 'users';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxMap<String, Map<String, dynamic>> users = <String, Map<String, dynamic>>{}.obs;

  Future<void> saveUser({
    required String uid,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: uid,
      data: data,
      merge: merge,
    );
    users[uid] = {
      ...(merge ? (users[uid] ?? const <String, dynamic>{}) : const <String, dynamic>{}),
      ...data,
    };
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final existing = users[uid];
    if (existing != null) return existing;
    final data = await _store.getRawDocument('$_collection/$uid');
    if (data != null) {
      users[uid] = data;
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final fetched = await _store.getCollection<Map<String, dynamic>>(
      path: _collection,
      fromMap: (id, data) => {'id': id, ...data},
    );
    users.value = {
      for (final item in fetched)
        item['id'] as String: Map<String, dynamic>.from(item)..remove('id'),
    };
    return fetched;
  }

  Future<void> deleteUser(String uid) async {
    await _store.deleteCollectionDocument(collectionPath: _collection, id: uid);
    users.remove(uid);
  }
}

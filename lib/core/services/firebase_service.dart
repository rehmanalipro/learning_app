import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static const _legacyUsersCollection = 'users';
  static const _studentsCollection = 'students';
  static const _teachersCollection = 'teachers';
  static const _principalsCollection = 'principals';
  static const _authIndexCollection = 'auth_index';

  FirebaseAuth? _firebaseAuth;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  void initialize() {
    if (_isInitialized) return;
    try {
      _firebaseAuth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
    } catch (_) {
      _firebaseAuth = null;
      _firestore = null;
      _isInitialized = false;
    }
  }

  bool get isAvailable => _isInitialized;

  FirebaseAuth get auth {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError(
        'Firebase Auth is not available on this platform. Configure '
        'Firebase for the current platform first.',
      );
    }
    return auth;
  }
  //

  FirebaseFirestore get firestore {
    final firestore = _firestore;
    if (firestore == null) {
      throw StateError(
        'Cloud Firestore is not available on this platform. Configure '
        'Firebase for the current platform first.',
      );
    }
    return firestore;
  }

  // Auth Methods
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signUpWithEmailAsManagedUser(
    String email,
    String password,
  ) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'managed-user-${DateTime.now().microsecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await secondaryAuth.signOut();
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Firestore Methods
  Future<void> createUser(
    String uid,
    Map<String, dynamic> userData, {
    String? documentId,
  }) async {
    try {
      final collection = _collectionForRole(userData['role'] as String?);
      final resolvedDocumentId = (documentId ?? '').trim().isEmpty
          ? uid
          : documentId!.trim();
      final payload = {
        ...userData,
        'authUid': uid,
        'accountDocId': resolvedDocumentId,
      };
      await firestore.collection(collection).doc(resolvedDocumentId).set(payload);
      await _upsertAuthIndex(
        uid: uid,
        collection: collection,
        documentId: resolvedDocumentId,
        role: userData['role'] as String? ?? '',
      );
    } catch (e) {
      throw _handleFirestoreException(e);
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    try {
      return await firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw _handleFirestoreException(e);
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      final documentRef = await _findUserDocumentRef(
        uid,
        roleHint: data['role'] as String?,
      );
      await firestore
          .collection(documentRef.collection)
          .doc(documentRef.documentId)
          .update(data);
    } catch (e) {
      throw _handleFirestoreException(e);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final documentRef = await _tryFindUserDocumentRef(uid);
    if (documentRef == null) return null;
    final snapshot = await firestore
        .collection(documentRef.collection)
        .doc(documentRef.documentId)
        .get();
    return snapshot.data();
  }

  Future<String?> findUserCollection(String uid, {String? roleHint}) {
    return _tryFindUserDocumentRef(uid, roleHint: roleHint).then(
      (ref) => ref?.collection,
    );
  }

  Future<bool> isTrustedPrincipalUid(String uid) async {
    final snapshot = await firestore.collection(_principalsCollection).doc(uid).get();
    return snapshot.exists;
  }

  String collectionForRole(String role) => _collectionForRole(role);

  String _collectionForRole(String? role) {
    switch ((role ?? '').trim().toLowerCase()) {
      case 'student':
        return _studentsCollection;
      case 'teacher':
        return _teachersCollection;
      case 'principal':
        return _principalsCollection;
      default:
        return _legacyUsersCollection;
    }
  }

  Future<_UserDocumentRef> _findUserDocumentRef(
    String uid, {
    String? roleHint,
  }) async {
    final resolved = await _tryFindUserDocumentRef(uid, roleHint: roleHint);
    if (resolved == null) {
      throw StateError('User document not found for uid: $uid');
    }
    return resolved;
  }

  Future<_UserDocumentRef?> _tryFindUserDocumentRef(
    String uid, {
    String? roleHint,
  }) async {
    final indexedRef = await _tryGetIndexedUserDocumentRef(uid);
    if (indexedRef != null) {
      return indexedRef;
    }

    final candidates = <String>[
      if ((roleHint ?? '').trim().isNotEmpty) _collectionForRole(roleHint),
      _studentsCollection,
      _teachersCollection,
      _principalsCollection,
      _legacyUsersCollection,
    ];

    final seen = <String>{};
    for (final collection in candidates) {
      if (!seen.add(collection)) continue;
      final snapshot = await firestore.collection(collection).doc(uid).get();
      if (snapshot.exists) {
        return _UserDocumentRef(collection: collection, documentId: uid);
      }

      final querySnapshot = await firestore
          .collection(collection)
          .where('authUid', isEqualTo: uid)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return _UserDocumentRef(
          collection: collection,
          documentId: querySnapshot.docs.first.id,
        );
      }
    }
    return null;
  }

  Future<_UserDocumentRef?> _tryGetIndexedUserDocumentRef(String uid) async {
    final snapshot = await firestore.collection(_authIndexCollection).doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    final collection = (data['collection'] as String? ?? '').trim();
    final documentId = (data['documentId'] as String? ?? '').trim();
    if (collection.isEmpty || documentId.isEmpty) return null;

    return _UserDocumentRef(collection: collection, documentId: documentId);
  }

  Future<void> _upsertAuthIndex({
    required String uid,
    required String collection,
    required String documentId,
    required String role,
  }) async {
    await firestore.collection(_authIndexCollection).doc(uid).set({
      'uid': uid,
      'authUid': uid,
      'role': role,
      'collection': collection,
      'documentId': documentId,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // Error Handling
  String _handleAuthException(Object e) {
    if (e is FirebaseAuthException) {
      return e.message ?? 'Auth error occurred';
    }
    return 'Unknown error occurred';
  }

  String _handleFirestoreException(Object e) {
    if (e is FirebaseException) {
      return e.message ?? 'Firestore error occurred';
    }
    return 'Unknown error occurred';
  }

  // Current User
  User? get currentUser => _firebaseAuth?.currentUser;
  bool get isAuthenticated => _firebaseAuth?.currentUser != null;
}

class _UserDocumentRef {
  final String collection;
  final String documentId;

  const _UserDocumentRef({
    required this.collection,
    required this.documentId,
  });
}

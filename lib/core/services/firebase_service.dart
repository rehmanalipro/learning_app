import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

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
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    try {
      await firestore.collection('users').doc(uid).set(userData);
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
      await firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw _handleFirestoreException(e);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snapshot = await getUser(uid);
    return snapshot.data();
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

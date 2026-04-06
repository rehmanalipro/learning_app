import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';

class FirebaseAuthProvider extends GetxController {
  late final FirebaseService _firebaseService;

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = RxBool(false);
  final RxString errorMessage = RxString('');

  @override
  void onInit() {
    super.onInit();
    _firebaseService = FirebaseService();
    _firebaseService.initialize();
    try {
      currentUser.bindStream(_firebaseService.auth.authStateChanges());
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? className,
    String? section,
    String? programName,
    String? imagePath,
  }) async {
    try {
      isLoading(true);
      errorMessage('');

      final userCredential = await _firebaseService.signUpWithEmail(
        email,
        password,
      );

      if (userCredential != null) {
        // Save user data to Firestore
        await _firebaseService.createUser(userCredential.user!.uid, {
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'role': role,
          'phone': phone,
          'className': className,
          'section': section,
          'programName': programName,
          'imagePath': imagePath,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        currentUser.value = userCredential.user;
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      isLoading(true);
      errorMessage('');

      final userCredential = await _firebaseService.signInWithEmail(
        email,
        password,
      );

      if (userCredential != null) {
        currentUser.value = userCredential.user;
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>?> loadCurrentUserData() async {
    final user = currentUser.value ?? _firebaseService.currentUser;
    if (user == null) return null;
    return _firebaseService.getUserData(user.uid);
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
      currentUser.value = null;
      errorMessage('');
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      isLoading(true);
      errorMessage('');
      await _firebaseService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading(false);
    }
  }

  bool get isAuthenticated => currentUser.value != null;
}

import 'package:get/get.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_collection_service.dart';
import '../models/profile_model.dart';

class ProfileService extends GetxService {
  final FirestoreCollectionService _store = FirestoreCollectionService();
  final FirebaseService _firebaseService = FirebaseService();
  final RxMap<String, ProfileModel> profiles = <String, ProfileModel>{}.obs;
  final RxBool isLoading = false.obs;
  Future<void>? _loadProfilesFuture;

  ProfileModel profileFor(String role) {
    final key = role.toLowerCase();
    return profiles[key] ?? _defaultProfile(role);
  }

  /// Loads the logged-in user's data from `users` collection first,
  /// then falls back to `profiles` collection for other roles.
  Future<void> loadProfiles() async {
    final inFlight = _loadProfilesFuture;
    if (inFlight != null) return inFlight;

    final future = _loadProfilesInternal();
    _loadProfilesFuture = future;
    return future;
  }

  Future<void> _loadProfilesInternal() async {
    isLoading.value = true;
    try {
      _firebaseService.initialize();
      final uid = _firebaseService.currentUser?.uid;

      // Load logged-in user from users collection
      if (uid != null) {
        final userData = await _firebaseService.getUserData(uid);
        if (userData != null) {
          final role = (userData['role'] as String? ?? '').toLowerCase();
          if (role.isNotEmpty) {
            profiles[role] = ProfileModel.fromMap(userData);
          }
        }
      }

      // Legacy profiles collection is optional. Ignore if rules don't allow it.
      try {
        final fetched = await _store.getCollection<ProfileModel>(
          path: 'profiles',
          fromMap: (id, data) => ProfileModel.fromMap(data),
        );

        for (final profile in fetched) {
          final key = profile.role.toLowerCase();
          if (!profiles.containsKey(key) || profile.name.isNotEmpty) {
            profiles[key] = profile;
          }
        }
      } catch (_) {}
    } finally {
      isLoading.value = false;
      _loadProfilesFuture = null;
    }
  }

  ProfileModel _defaultProfile(String role) {
    return ProfileModel(
      role: role,
      name: '',
      email: '',
      phone: '',
      className: null,
      section: null,
      programName: null,
      admissionNo: null,
      rollNumber: null,
      linkedStudentProfileId: null,
    );
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final key = profile.role.toLowerCase();

    // Update users collection if user is logged in with this role
    final uid = _firebaseService.currentUser?.uid;
    if (uid != null) {
      final userData = await _firebaseService.getUserData(uid);
      final userRole = (userData?['role'] as String? ?? '').toLowerCase();
      if (userRole == key) {
        await _firebaseService.updateUser(uid, {
          'name': profile.name,
          'email': profile.email,
          'phone': profile.phone,
          'className': profile.className,
          'section': profile.section,
          'programName': profile.programName,
          'admissionNo': profile.admissionNo,
          'rollNumber': profile.rollNumber,
          'linkedStudentProfileId': profile.linkedStudentProfileId,
          'imagePath': profile.imagePath,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Also update role-specific collection
        try {
          String collection = '';
          if (key == 'student') {
            collection = 'students';
          } else if (key == 'teacher') {
            collection = 'teachers';
          } else if (key == 'principal') {
            collection = 'principals';
          }

          if (collection.isNotEmpty) {
            await _store.setCollectionDocument(
              collectionPath: collection,
              id: uid,
              data: {
                'name': profile.name,
                'email': profile.email,
                'phone': profile.phone,
                'imagePath': profile.imagePath,
                'updatedAt': DateTime.now().toIso8601String(),
              },
              merge: true,
            );
          }
        } catch (e) {
          // ignore: avoid_print
          print('[Profile Service] Role collection update error: $e');
        }
      }
    }

    // Legacy profiles collection is best-effort only.
    try {
      await _store.setCollectionDocument(
        collectionPath: 'profiles',
        id: key,
        data: profile.toMap(),
        merge: true,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[Profile Service] Legacy profiles update error: $e');
    }

    profiles[key] = profile;
  }

  void ensureProfile(String role) {
    final key = role.toLowerCase();
    profiles.putIfAbsent(key, () => _defaultProfile(role));
  }

  Future<void> saveSignupProfile({
    required String role,
    required String name,
    required String email,
    required String phone,
    String? className,
    String? section,
    String? programName,
    String? admissionNo,
    String? rollNumber,
    String? linkedStudentProfileId,
    String? imagePath,
  }) {
    return saveProfile(
      ProfileModel(
        role: role,
        name: name,
        email: email,
        phone: phone,
        className: className,
        section: section,
        programName: programName,
        admissionNo: admissionNo,
        rollNumber: rollNumber,
        linkedStudentProfileId: linkedStudentProfileId,
        imagePath: imagePath,
      ),
    );
  }

  Future<void> updateProfile({
    required String role,
    required String name,
    required String email,
    required String phone,
    String? className,
    String? section,
    String? programName,
    String? admissionNo,
    String? rollNumber,
    String? linkedStudentProfileId,
    String? imagePath,
  }) {
    final current = profileFor(role);
    return saveProfile(
      current.copyWith(
        name: name,
        email: email,
        phone: phone,
        className: className,
        section: section,
        programName: programName,
        admissionNo: admissionNo,
        rollNumber: rollNumber,
        linkedStudentProfileId: linkedStudentProfileId,
        imagePath: imagePath,
      ),
    );
  }
}

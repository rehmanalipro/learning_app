import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/profile_model.dart';

class ProfileService extends GetxService {
  static const _collection = 'profiles';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final RxMap<String, ProfileModel> profiles = <String, ProfileModel>{}.obs;
  final RxBool isLoading = false.obs;

  ProfileModel profileFor(String role) {
    final key = role.toLowerCase();
    return profiles[key] ?? _defaultProfile(role);
  }

  Future<void> loadProfiles() async {
    isLoading.value = true;
    try {
      final fetched = await _store.getCollection<ProfileModel>(
        path: _collection,
        fromMap: (id, data) => ProfileModel.fromMap(data),
      );

      if (fetched.isEmpty && profiles.isEmpty) {
        final seed = {
          'student': _defaultProfile('Student'),
          'teacher': _defaultProfile('Teacher'),
          'principal': _defaultProfile('Principal'),
        };
        for (final entry in seed.entries) {
          await _store.setCollectionDocument(
            collectionPath: _collection,
            id: entry.key,
            data: entry.value.toMap(),
          );
        }
        profiles.value = seed;
        return;
      }

      profiles.value = {
        for (final profile in fetched) profile.role.toLowerCase(): profile,
      };
    } finally {
      isLoading.value = false;
    }
  }

  ProfileModel _defaultProfile(String role) {
    final key = role.toLowerCase();
    return ProfileModel(
      role: role,
      name: key == 'teacher'
          ? 'Teacher User'
          : key == 'principal'
              ? 'Principal User'
              : 'Student User',
      email: key == 'teacher'
          ? 'teacher@example.com'
          : key == 'principal'
              ? 'principal@example.com'
              : 'student@example.com',
      phone: '+92 300 0000000',
      className: key == 'student' ? '3' : null,
      section: key == 'student' ? 'A' : null,
      programName: key == 'student' ? 'BSc (Hons) Agriculture' : null,
    );
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final key = profile.role.toLowerCase();
    await _store.setCollectionDocument(
      collectionPath: _collection,
      id: key,
      data: profile.toMap(),
      merge: true,
    );
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
        imagePath: imagePath,
      ),
    );
  }
}

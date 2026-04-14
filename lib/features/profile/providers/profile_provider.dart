import 'package:get/get.dart';

import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends GetxController {
  late final ProfileService _service;
  RxMap<String, ProfileModel> get profiles => _service.profiles;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<ProfileService>();
    loadProfiles();
  }

  ProfileModel profileFor(String role) => _service.profileFor(role);

  Future<void> loadProfiles() => _service.loadProfiles();

  void ensureProfile(String role) => _service.ensureProfile(role);

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
  }) => _service.saveSignupProfile(
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
  );

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
  }) => _service.updateProfile(
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
  );
}

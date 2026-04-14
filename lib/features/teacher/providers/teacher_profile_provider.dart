import 'package:get/get.dart';

import '../models/teacher_profile_model.dart';
import '../services/teacher_profile_service.dart';

class TeacherProfileProvider extends GetxController {
  late final TeacherProfileService _service;

  RxList<TeacherProfileModel> get teacherProfiles => _service.teacherProfiles;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<TeacherProfileService>();
  }

  Future<void> loadAll() => _service.loadAll();

  Future<void> upsertTeacherProfile(TeacherProfileModel profile) {
    return _service.upsertTeacherProfile(profile);
  }

  String createProfileId() => _service.createProfileId();

  String normalizeEmployeeId(String value) => _service.normalizeEmployeeId(value);

  String normalizeUserId(String value) => _service.normalizeUserId(value);
}

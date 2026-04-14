import 'package:get/get.dart';

import '../models/student_profile_model.dart';
import '../services/student_profile_service.dart';

class StudentProfileProvider extends GetxController {
  late final StudentProfileService _service;

  RxList<StudentProfileModel> get studentProfiles => _service.studentProfiles;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<StudentProfileService>();
  }

  Future<void> loadAll() => _service.loadAll();

  Future<List<StudentProfileModel>> loadByClassSection({
    String? className,
    String? section,
  }) => _service.loadByClassSection(className: className, section: section);

  Future<void> upsertStudentProfile(StudentProfileModel profile) {
    return _service.upsertStudentProfile(profile);
  }

  String createProfileId() => _service.createProfileId();

  String normalizeDate(String value) => _service.normalizeDate(value);

  String normalizeAdmissionNo(String value) =>
      _service.normalizeAdmissionNo(value);

  String normalizeUserId(String value) => _service.normalizeUserId(value);
}

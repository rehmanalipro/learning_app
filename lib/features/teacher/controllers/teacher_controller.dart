import 'package:get/get.dart';

import '../models/teacher_model.dart';
import '../services/teacher_service.dart';

class TeacherController extends GetxController {
  final TeacherService _service = Get.find<TeacherService>();

  RxList<TeacherModel> get teachers => _service.teachers;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    loadTeachers();
  }

  Future<void> loadTeachers() => _service.loadTeachers();

  Future<void> addTeacher(TeacherModel teacher) => _service.addTeacher(teacher);

  Future<void> updateTeacher(TeacherModel teacher) =>
      _service.updateTeacher(teacher);

  Future<void> removeTeacher(String id) => _service.removeTeacher(id);
}

import 'package:get/get.dart';
import '../models/teacher_model.dart';
import '../services/teacher_service.dart';

class TeacherProvider extends GetxController {
  final TeacherService _teacherService = TeacherService();
  RxList<TeacherModel> teachers = RxList<TeacherModel>();
  RxBool isLoading = false.obs;

  Future<void> loadTeachers() async {
    try {
      isLoading.value = true;
      teachers.value = await _teacherService.getTeachers();
    } finally {
      isLoading.value = false;
    }
  }
}

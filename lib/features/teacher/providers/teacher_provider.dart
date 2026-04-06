import 'package:get/get.dart';
import '../models/teacher_model.dart';
import '../services/teacher_service.dart';

class TeacherProvider extends GetxController {
  late final TeacherService _teacherService;
  RxList<TeacherModel> get teachers => _teacherService.teachers;
  RxBool get isLoading => _teacherService.isLoading;

  @override
  void onInit() {
    super.onInit();
    _teacherService = Get.find<TeacherService>();
    loadTeachers();
  }

  Future<void> loadTeachers() => _teacherService.loadTeachers();

  Future<void> addTeacher(TeacherModel teacher) =>
      _teacherService.addTeacher(teacher);

  Future<void> updateTeacher(TeacherModel teacher) =>
      _teacherService.updateTeacher(teacher);

  Future<void> removeTeacher(String id) => _teacherService.removeTeacher(id);
}

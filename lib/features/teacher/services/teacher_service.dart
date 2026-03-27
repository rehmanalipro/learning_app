import '../models/teacher_model.dart';

class TeacherService {
  Future<List<TeacherModel>> getTeachers() async {
    await Future.delayed(const Duration(seconds: 1));
    return [TeacherModel(id: '1', name: 'Teacher A', subject: 'Science')];
  }
}

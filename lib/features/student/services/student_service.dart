import '../models/student_model.dart';

class StudentService {
  Future<List<StudentModel>> getStudents() async {
    await Future.delayed(const Duration(seconds: 1));
    return [StudentModel(id: '1', name: 'Student A', className: '10')];
  }
}

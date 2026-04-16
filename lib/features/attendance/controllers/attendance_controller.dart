import 'package:get/get.dart';

import '../models/attendance_entry_model.dart';
import '../services/attendance_service.dart';

class AttendanceController extends GetxController {
  final AttendanceService _service = Get.find<AttendanceService>();

  RxList<AttendanceEntryModel> get entries => _service.attendanceEntries;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    _service.loadEntries();
  }

  Future<void> submitAttendance({
    required String studentName,
    required String rollNumber,
    required String className,
    required String section,
    required String email,
    String? photoPath,
    String? notes,
  }) {
    return _service.submitAttendance(
      studentName: studentName,
      rollNumber: rollNumber,
      className: className,
      section: section,
      email: email,
      photoPath: photoPath,
      notes: notes,
    );
  }

  Future<void> updateAttendanceStatus(String id, AttendanceStatus status) =>
      _service.updateAttendanceStatus(id, status);

  List<AttendanceEntryModel> attendanceForStudent(String email) {
    return _service.attendanceEntries
        .where(
          (entry) =>
              entry.email.trim().toLowerCase() == email.trim().toLowerCase(),
        )
        .toList(growable: false);
  }
}

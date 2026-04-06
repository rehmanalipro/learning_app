import 'package:get/get.dart';

import '../models/attendance_entry_model.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends GetxController {
  late final AttendanceService _service;
  RxList<AttendanceEntryModel> get attendanceEntries => _service.attendanceEntries;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<AttendanceService>();
    loadEntries();
  }

  Future<void> loadEntries() => _service.loadEntries();

  Future<void> submitAttendance({
    required String studentName,
    required String rollNumber,
    required String className,
    required String section,
    required String email,
    String? photoPath,
  }) => _service.submitAttendance(
    studentName: studentName,
    rollNumber: rollNumber,
    className: className,
    section: section,
    email: email,
    photoPath: photoPath,
  );

  Future<void> updateAttendanceStatus(String id, AttendanceStatus status) =>
      _service.updateAttendanceStatus(id, status);
}

import 'package:get/get.dart';

import '../models/exam_schedule_model.dart';
import '../services/exam_schedule_service.dart';

class ExamScheduleProvider extends GetxController {
  late final ExamScheduleService _service;
  RxList<ExamScheduleModel> get schedules => _service.schedules;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<ExamScheduleService>();
    loadSchedules();
  }

  List<String> subjectsForClass(String className) =>
      _service.subjectsForClass(className);
  Future<void> loadSchedules() => _service.loadSchedules();

  Future<String?> addSchedule({
    required String className,
    required String section,
    required String subject,
    required String uploadedByName,
    required String uploadedByRole,
    required DateTime examDate,
    required int startMinutes,
    required int endMinutes,
    required String shiftLabel,
    required String place,
    required String blockName,
    required String roomNumber,
    required String seatLabel,
    required String description,
    String? dateSheetName,
    String? dateSheetPath,
  }) => _service.addSchedule(
    className: className,
    section: section,
    subject: subject,
    uploadedByName: uploadedByName,
    uploadedByRole: uploadedByRole,
    examDate: examDate,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
    shiftLabel: shiftLabel,
    place: place,
    blockName: blockName,
    roomNumber: roomNumber,
    seatLabel: seatLabel,
    description: description,
    dateSheetName: dateSheetName,
    dateSheetPath: dateSheetPath,
  );

  List<ExamScheduleModel> schedulesForClass({
    required String className,
    required String section,
  }) => _service.schedulesForClass(className: className, section: section);
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/attendance/providers/attendance_provider.dart';
import '../../features/exam/providers/exam_schedule_provider.dart';
import '../../features/homework/providers/homework_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/quiz/providers/quiz_provider.dart';
import '../../features/result/providers/result_provider.dart';
import '../../features/school/providers/school_data_provider.dart';
import '../../features/student/providers/student_provider.dart';
import '../../features/teacher/providers/teacher_provider.dart';

class AppRefreshScope extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const AppRefreshScope({
    super.key,
    required this.child,
    this.onRefresh,
  });

  static Future<void> refreshAppData() async {
    final tasks = <Future<void>>[];

    if (Get.isRegistered<SchoolDataProvider>()) {
      tasks.add(Get.find<SchoolDataProvider>().loadSchoolData());
    }
    if (Get.isRegistered<AttendanceProvider>()) {
      tasks.add(Get.find<AttendanceProvider>().loadEntries());
    }
    if (Get.isRegistered<ExamScheduleProvider>()) {
      tasks.add(Get.find<ExamScheduleProvider>().loadSchedules());
    }
    if (Get.isRegistered<HomeworkProvider>()) {
      tasks.add(Get.find<HomeworkProvider>().loadAll());
    }
    if (Get.isRegistered<ProfileProvider>()) {
      tasks.add(Get.find<ProfileProvider>().loadProfiles());
    }
    if (Get.isRegistered<QuizProvider>()) {
      tasks.add(Get.find<QuizProvider>().loadAll());
    }
    if (Get.isRegistered<StudentProvider>()) {
      tasks.add(Get.find<StudentProvider>().loadStudents());
    }
    if (Get.isRegistered<TeacherProvider>()) {
      tasks.add(Get.find<TeacherProvider>().loadTeachers());
    }
    if (Get.isRegistered<ResultProvider>()) {
      tasks.add(Get.find<ResultProvider>().loadAll());
    }

    if (tasks.isEmpty) return;
    await Future.wait(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? refreshAppData,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.vertical,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../shared/layouts/role_home_screen.dart';

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleHomeScreen(
      title: 'Student Home',
      roleLabel: 'Student',
      onAttendanceTap: () => Get.toNamed(AppRoutes.attendanceForm),
      onExamRoutineTap: () => Get.toNamed(AppRoutes.studentExamRoutine),
      onHomeworkTap: () => Get.toNamed(AppRoutes.studentHomework),
      onResultTap: () => Get.toNamed(AppRoutes.studentResult),
      onSolutionTap: () => Get.toNamed(AppRoutes.studentSolution),
      onQuizTap: () => Get.toNamed(AppRoutes.studentQuiz),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../shared/layouts/role_home_screen.dart';

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleHomeScreen(
      title: 'Teacher Home',
      roleLabel: 'Teacher',
      onAttendanceTap: () => Get.toNamed(AppRoutes.teacherAttendance),
      onExamRoutineTap: () => Get.toNamed(AppRoutes.teacherExamRoutine),
      onHomeworkTap: () => Get.toNamed(AppRoutes.teacherHomework),
      onResultTap: () => Get.toNamed(AppRoutes.teacherResult, arguments: 'Teacher'),
      onSolutionTap: () => Get.toNamed(AppRoutes.teacherSolution),
      onQuizTap: () => Get.toNamed(AppRoutes.teacherQuiz),
    );
  }
}

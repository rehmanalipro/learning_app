import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../shared/layouts/role_home_screen.dart';

class PrincipalScreen extends StatelessWidget {
  const PrincipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleHomeScreen(
      title: 'Principal Home',
      roleLabel: 'Principal',
      onAttendanceTap: () => Get.toNamed(AppRoutes.principalAttendance),
      onExamRoutineTap: () => Get.toNamed(AppRoutes.principalExamRoutine),
      onHomeworkTap: () => Get.toNamed(AppRoutes.principalHomework),
      onResultTap: () => Get.toNamed(AppRoutes.teacherResult, arguments: 'Principal'),
      onSolutionTap: () => Get.toNamed(AppRoutes.principalSolution),
      onQuizTap: () => Get.toNamed(AppRoutes.principalQuiz),
    );
  }
}

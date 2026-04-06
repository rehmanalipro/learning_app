import 'package:get/get.dart';

import '../features/attendance/views/attendance_form_screen.dart';
import '../features/attendance/views/teacher_attendance_screen.dart';
import '../features/auth/views/choose_option_screen.dart';
import '../features/auth/views/forgot_password_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/otp_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/splash_screen.dart';
import '../features/exam/views/student_exam_routine_screen.dart';
import '../features/exam/views/teacher_exam_routine_screen.dart';
import '../features/homework/views/student_homework_screen.dart';
import '../features/homework/views/student_solution_screen.dart';
import '../features/homework/views/submit_homework_screen.dart';
import '../features/homework/views/teacher_homework_screen.dart';
import '../features/homework/views/teacher_solution_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/quiz/views/student_quiz_screen.dart';
import '../features/quiz/views/teacher_quiz_screen.dart';
import '../features/result/views/student_result_screen.dart';
import '../features/result/views/teacher_result_screen.dart';
import '../features/school/views/principal_screen.dart';
import '../features/school/views/school_info_screen.dart';
import '../features/student/views/student_screen.dart';
import '../features/teacher/views/teacher_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.choose, page: () => const ChooseOptionScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(name: AppRoutes.otp, page: () => const OtpScreen()),
    GetPage(name: AppRoutes.student, page: () => const StudentScreen()),
    GetPage(name: AppRoutes.teacher, page: () => const TeacherScreen()),
    GetPage(
      name: AppRoutes.teacherAttendance,
      page: () => const TeacherAttendanceScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherExamRoutine,
      page: () => const TeacherExamRoutineScreen(),
    ),
    GetPage(
      name: AppRoutes.studentExamRoutine,
      page: () => const StudentExamRoutineScreen(),
    ),
    GetPage(
      name: AppRoutes.principalExamRoutine,
      page: () => const TeacherExamRoutineScreen(roleLabel: 'Principal'),
    ),
    GetPage(
      name: AppRoutes.teacherHomework,
      //
      page: () => const TeacherHomeworkScreen(),
    ),
    GetPage(
      name: AppRoutes.studentHomework,
      page: () => const StudentHomeworkScreen(),
    ),
    GetPage(
      name: AppRoutes.studentHomeworkSubmit,
      page: () => const SubmitHomeworkScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherSolution,
      page: () => const TeacherSolutionScreen(),
    ),
    GetPage(
      name: AppRoutes.studentSolution,
      page: () => const StudentSolutionScreen(),
    ),
    GetPage(
      name: AppRoutes.principalSolution,
      page: () => const TeacherSolutionScreen(roleLabel: 'Principal'),
    ),
    GetPage(
      name: AppRoutes.principalHomework,
      page: () => const TeacherHomeworkScreen(),
    ),
    GetPage(name: AppRoutes.principal, page: () => const PrincipalScreen()),
    GetPage(
      name: AppRoutes.profile,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final role = args != null && args['role'] != null
            ? args['role'] as String
            : 'Student';
        return ProfileScreen(role: role);
      },
    ),
    GetPage(
      name: AppRoutes.attendanceForm,
      page: () => const AttendanceFormScreen(),
    ),
    GetPage(
      name: AppRoutes.schoolInfo,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return SchoolInfoScreen(
          role: args['role'] as String,
          type: args['type'] as SchoolInfoType,
        );
      },
    ),
    GetPage(
      name: AppRoutes.studentResult,
      page: () => const StudentResultScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherResult,
      page: () => const TeacherResultScreen(),
    ),
    GetPage(
      name: AppRoutes.studentQuiz,
      page: () => const StudentQuizScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherQuiz,
      page: () => const TeacherQuizScreen(),
    ),
    GetPage(
      name: AppRoutes.principalQuiz,
      page: () => const TeacherQuizScreen(roleLabel: 'Principal'),
    ),
  ];
}

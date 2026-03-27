import 'package:get/get.dart';
import '../pages/splash_screen.dart';
import '../pages/choose_option_screen.dart';
import '../pages/student_screen.dart';
import '../pages/teacher_screen.dart';
import '../pages/guest_screen.dart';
import '../pages/login_screen.dart';
import '../pages/register_screen.dart';
import '../pages/otp_screen.dart';
import '../pages/attendance_form_screen.dart';

abstract class AppRoutes {
  static const splash = '/splash';
  static const choose = '/choose';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const student = '/student';
  static const teacher = '/teacher';
  static const guest = '/guest';
  static const attendanceForm = '/attendance-form';
}

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.choose, page: () => const ChooseOptionScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
    GetPage(name: AppRoutes.otp, page: () => const OtpScreen()),
    GetPage(name: AppRoutes.student, page: () => const StudentScreen()),
    GetPage(name: AppRoutes.teacher, page: () => const TeacherScreen()),
    GetPage(name: AppRoutes.guest, page: () => const GuestScreen()),
    GetPage(
      name: AppRoutes.attendanceForm,
      page: () => const AttendanceFormScreen(),
    ),
  ];
}

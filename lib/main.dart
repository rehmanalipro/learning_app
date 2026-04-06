import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'features/attendance/controllers/attendance_controller.dart';
import 'features/attendance/providers/attendance_provider.dart';
import 'features/attendance/services/attendance_service.dart';
import 'features/exam/controllers/exam_schedule_controller.dart';
import 'features/exam/providers/exam_schedule_provider.dart';
import 'features/exam/services/exam_schedule_service.dart';
import 'features/homework/providers/homework_provider.dart';
import 'features/homework/controllers/homework_controller.dart';
import 'features/homework/services/homework_service.dart';
import 'features/auth/providers/firebase_auth_provider.dart';
import 'features/auth/services/user_service.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/quiz/providers/quiz_provider.dart';
import 'features/profile/controllers/profile_controller.dart';
import 'features/profile/services/profile_service.dart';
import 'features/result/controllers/result_controller.dart';
import 'features/result/providers/result_provider.dart';
import 'features/result/services/result_service.dart';
import 'features/student/providers/student_provider.dart';
import 'features/student/controllers/student_controller.dart';
import 'features/student/services/student_service.dart';
import 'features/teacher/providers/teacher_provider.dart';
import 'features/teacher/controllers/teacher_controller.dart';
import 'features/teacher/services/teacher_service.dart';
import 'features/school/providers/school_data_provider.dart';
import 'features/school/controllers/school_controller.dart';
import 'features/school/services/school_data_service.dart';
import 'features/theme/providers/app_theme_provider.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapApp();
  runApp(const MyApp());
}

Future<void> bootstrapApp({
  bool initializeFirebase = true,
  bool initializeTheme = true,
}) async {
  if (initializeFirebase && !Get.isRegistered<FirebaseApp>()) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Allow the app to boot with local/demo data when Firebase is not
      // configured for the current platform.
    }
  }

  if (!Get.isRegistered<AttendanceService>()) {
    Get.put(AttendanceService(), permanent: true);
  }
  if (!Get.isRegistered<AttendanceProvider>()) {
    Get.put(AttendanceProvider(), permanent: true);
  }
  if (!Get.isRegistered<AttendanceController>()) {
    Get.put(AttendanceController(), permanent: true);
  }
  if (!Get.isRegistered<ExamScheduleService>()) {
    Get.put(ExamScheduleService(), permanent: true);
  }
  if (!Get.isRegistered<ExamScheduleProvider>()) {
    Get.put(ExamScheduleProvider(), permanent: true);
  }
  if (!Get.isRegistered<ExamScheduleController>()) {
    Get.put(ExamScheduleController(), permanent: true);
  }
  if (!Get.isRegistered<HomeworkService>()) {
    Get.put(HomeworkService(), permanent: true);
  }
  if (!Get.isRegistered<HomeworkProvider>()) {
    Get.put(HomeworkProvider(), permanent: true);
  }
  if (!Get.isRegistered<HomeworkController>()) {
    Get.put(HomeworkController(), permanent: true);
  }
  if (!Get.isRegistered<UserService>()) {
    Get.put(UserService(), permanent: true);
  }
  if (!Get.isRegistered<FirebaseAuthProvider>()) {
    Get.put(FirebaseAuthProvider(), permanent: true);
  }
  if (!Get.isRegistered<ProfileService>()) {
    Get.put(ProfileService(), permanent: true);
  }
  if (!Get.isRegistered<ProfileProvider>()) {
    Get.put(ProfileProvider(), permanent: true);
  }
  if (!Get.isRegistered<ProfileController>()) {
    Get.put(ProfileController(), permanent: true);
  }
  if (!Get.isRegistered<QuizProvider>()) {
    Get.put(QuizProvider(), permanent: true);
  }
  if (!Get.isRegistered<ResultService>()) {
    Get.put(ResultService(), permanent: true);
  }
  if (!Get.isRegistered<ResultProvider>()) {
    Get.put(ResultProvider(), permanent: true);
  }
  if (!Get.isRegistered<ResultController>()) {
    Get.put(ResultController(), permanent: true);
  }
  if (!Get.isRegistered<StudentService>()) {
    Get.put(StudentService(), permanent: true);
  }
  if (!Get.isRegistered<StudentProvider>()) {
    Get.put(StudentProvider(), permanent: true);
  }
  if (!Get.isRegistered<StudentController>()) {
    Get.put(StudentController(), permanent: true);
  }
  if (!Get.isRegistered<TeacherService>()) {
    Get.put(TeacherService(), permanent: true);
  }
  if (!Get.isRegistered<TeacherProvider>()) {
    Get.put(TeacherProvider(), permanent: true);
  }
  if (!Get.isRegistered<TeacherController>()) {
    Get.put(TeacherController(), permanent: true);
  }
  if (!Get.isRegistered<SchoolDataService>()) {
    Get.put(SchoolDataService(), permanent: true);
  }
  if (!Get.isRegistered<SchoolDataProvider>()) {
    Get.put(SchoolDataProvider(), permanent: true);
  }
  if (!Get.isRegistered<SchoolController>()) {
    Get.put(SchoolController(), permanent: true);
  }
  if (!Get.isRegistered<AppThemeProvider>()) {
    final appThemeProvider = AppThemeProvider();
    if (initializeTheme) {
      await appThemeProvider.init();
    }
    Get.put(appThemeProvider, permanent: true);
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final AppThemeProvider? appThemeProvider;

  const MyApp({
    super.key,
    this.initialRoute = AppRoutes.splash,
    this.appThemeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeProvider resolvedThemeProvider =
        appThemeProvider ??
        (Get.isRegistered<AppThemeProvider>()
            ? Get.find<AppThemeProvider>()
            : Get.put(AppThemeProvider(), permanent: true));
    return Obx(
      () => GetMaterialApp(
        title: 'School Management System',
        debugShowCheckedModeBanner: false,
        themeMode: resolvedThemeProvider.modeFor(
          resolvedThemeProvider.currentRole.value,
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E56CF),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E56CF),
            foregroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E56CF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111827),
            foregroundColor: Colors.white,
          ),
          cardColor: const Color(0xFF1F2937),
        ),
        initialRoute: initialRoute,
        getPages: AppPages.routes,
      ),
    );
  }
}

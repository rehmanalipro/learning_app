import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/chatbot_service.dart';
import 'core/services/class_binding_service.dart';
import 'core/services/class_roster_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/otp_service.dart';
import 'firebase_options.dart';
import 'features/attendance/controllers/attendance_controller.dart';
import 'features/attendance/providers/attendance_provider.dart';
import 'features/attendance/services/attendance_service.dart';
import 'features/admission/providers/student_profile_provider.dart';
import 'features/admission/services/student_profile_service.dart';
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
import 'features/quiz/services/quiz_service.dart';
import 'features/profile/controllers/profile_controller.dart';
import 'features/profile/services/profile_service.dart';
import 'features/result/providers/result_provider.dart';
import 'features/result/services/result_service.dart';
import 'features/student/providers/student_provider.dart';
import 'features/student/controllers/student_controller.dart';
import 'features/student/services/student_service.dart';
import 'features/teacher/providers/teacher_provider.dart';
import 'features/teacher/controllers/teacher_controller.dart';
import 'features/teacher/providers/teacher_profile_provider.dart';
import 'features/teacher/services/teacher_assignment_service.dart';
import 'features/teacher/services/teacher_profile_service.dart';
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
    } on UnsupportedError catch (e) {
      // Platform not configured yet (iOS/Web/macOS placeholders).
      // App will run in demo/local mode without Firebase.
      // ignore: avoid_print
      print('[Firebase] Skipped: ${e.message}');
    } catch (e) {
      // Firebase init failed for another reason (e.g. bad credentials).
      // ignore: avoid_print
      print('[Firebase] Init error: $e');
    }
  }

  if (!Get.isRegistered<FcmService>()) {
    Get.lazyPut<FcmService>(() => FcmService(), fenix: true);
  }

  if (!Get.isRegistered<OtpService>()) {
    Get.lazyPut<OtpService>(() => OtpService(), fenix: true);
  }
  if (!Get.isRegistered<ChatbotService>()) {
    Get.lazyPut<ChatbotService>(() => ChatbotService(), fenix: true);
  }

  if (!Get.isRegistered<ClassBindingService>()) {
    Get.put(ClassBindingService(), permanent: true);
  }
  if (!Get.isRegistered<ClassRosterService>()) {
    Get.put(ClassRosterService(), permanent: true);
  }

  if (!Get.isRegistered<AttendanceService>()) {
    Get.put(AttendanceService(), permanent: true);
  }
  if (!Get.isRegistered<StudentProfileService>()) {
    Get.put(StudentProfileService(), permanent: true);
  }
  if (!Get.isRegistered<StudentProfileProvider>()) {
    Get.lazyPut<StudentProfileProvider>(
      () => StudentProfileProvider(),
      fenix: true,
    );
  }
  if (!Get.isRegistered<AttendanceProvider>()) {
    Get.lazyPut<AttendanceProvider>(() => AttendanceProvider(), fenix: true);
  }
  if (!Get.isRegistered<AttendanceController>()) {
    Get.lazyPut<AttendanceController>(
      () => AttendanceController(),
      fenix: true,
    );
  }
  if (!Get.isRegistered<ExamScheduleService>()) {
    Get.put(ExamScheduleService(), permanent: true);
  }
  if (!Get.isRegistered<ExamScheduleProvider>()) {
    Get.lazyPut<ExamScheduleProvider>(
      () => ExamScheduleProvider(),
      fenix: true,
    );
  }
  if (!Get.isRegistered<ExamScheduleController>()) {
    Get.lazyPut<ExamScheduleController>(
      () => ExamScheduleController(),
      fenix: true,
    );
  }
  if (!Get.isRegistered<HomeworkService>()) {
    Get.put(HomeworkService(), permanent: true);
  }
  if (!Get.isRegistered<HomeworkProvider>()) {
    Get.lazyPut<HomeworkProvider>(() => HomeworkProvider(), fenix: true);
  }
  if (!Get.isRegistered<HomeworkController>()) {
    Get.lazyPut<HomeworkController>(() => HomeworkController(), fenix: true);
  }
  if (!Get.isRegistered<UserService>()) {
    Get.put(UserService(), permanent: true);
  }
  if (!Get.isRegistered<TeacherAssignmentService>()) {
    Get.put(TeacherAssignmentService(), permanent: true);
  }
  if (!Get.isRegistered<TeacherProfileService>()) {
    Get.put(TeacherProfileService(), permanent: true);
  }
  if (!Get.isRegistered<FirebaseAuthProvider>()) {
    Get.put(FirebaseAuthProvider(), permanent: true);
  }
  if (!Get.isRegistered<ProfileService>()) {
    Get.put(ProfileService(), permanent: true);
  }
  if (!Get.isRegistered<ProfileProvider>()) {
    Get.lazyPut<ProfileProvider>(() => ProfileProvider(), fenix: true);
  }
  if (!Get.isRegistered<ProfileController>()) {
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
  if (!Get.isRegistered<QuizService>()) {
    Get.put(QuizService(), permanent: true);
  }
  if (!Get.isRegistered<QuizProvider>()) {
    Get.lazyPut<QuizProvider>(() => QuizProvider(), fenix: true);
  }
  if (!Get.isRegistered<ResultService>()) {
    Get.put(ResultService(), permanent: true);
  }
  if (!Get.isRegistered<ResultProvider>()) {
    Get.lazyPut<ResultProvider>(() => ResultProvider(), fenix: true);
  }
  if (!Get.isRegistered<StudentService>()) {
    Get.put(StudentService(), permanent: true);
  }
  if (!Get.isRegistered<StudentProvider>()) {
    Get.lazyPut<StudentProvider>(() => StudentProvider(), fenix: true);
  }
  if (!Get.isRegistered<StudentController>()) {
    Get.lazyPut<StudentController>(() => StudentController(), fenix: true);
  }
  if (!Get.isRegistered<TeacherService>()) {
    Get.put(TeacherService(), permanent: true);
  }
  if (!Get.isRegistered<TeacherProfileProvider>()) {
    Get.lazyPut<TeacherProfileProvider>(
      () => TeacherProfileProvider(),
      fenix: true,
    );
  }
  if (!Get.isRegistered<TeacherProvider>()) {
    Get.lazyPut<TeacherProvider>(() => TeacherProvider(), fenix: true);
  }
  if (!Get.isRegistered<TeacherController>()) {
    Get.lazyPut<TeacherController>(() => TeacherController(), fenix: true);
  }
  if (!Get.isRegistered<SchoolDataService>()) {
    Get.put(SchoolDataService(), permanent: true);
  }
  if (!Get.isRegistered<SchoolDataProvider>()) {
    Get.lazyPut<SchoolDataProvider>(() => SchoolDataProvider(), fenix: true);
  }
  if (!Get.isRegistered<SchoolController>()) {
    Get.lazyPut<SchoolController>(() => SchoolController(), fenix: true);
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
        themeMode: resolvedThemeProvider.currentMode.value,
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
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }
}

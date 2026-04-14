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

/// Wraps content with pull-to-refresh AND a fade+slide entrance animation.
/// Used as the body wrapper for all main screens.
class AppRefreshScope extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const AppRefreshScope({super.key, required this.child, this.onRefresh});

  static Future<void> refreshAppData() async {
    final tasks = <Future<void>>[];

    Future<void> safe(Future<void> future) async {
      try {
        await future;
      } catch (_) {}
    }

    if (Get.isRegistered<SchoolDataProvider>()) {
      tasks.add(safe(Get.find<SchoolDataProvider>().loadSchoolData()));
    }
    if (Get.isRegistered<AttendanceProvider>()) {
      tasks.add(safe(Get.find<AttendanceProvider>().loadEntries()));
    }
    if (Get.isRegistered<ExamScheduleProvider>()) {
      tasks.add(safe(Get.find<ExamScheduleProvider>().loadSchedules()));
    }
    if (Get.isRegistered<HomeworkProvider>()) {
      tasks.add(safe(Get.find<HomeworkProvider>().loadAll()));
    }
    if (Get.isRegistered<ProfileProvider>()) {
      tasks.add(safe(Get.find<ProfileProvider>().loadProfiles()));
    }
    if (Get.isRegistered<QuizProvider>()) {
      tasks.add(safe(Get.find<QuizProvider>().loadAll()));
    }
    if (Get.isRegistered<StudentProvider>()) {
      tasks.add(safe(Get.find<StudentProvider>().loadStudents()));
    }
    if (Get.isRegistered<TeacherProvider>()) {
      tasks.add(safe(Get.find<TeacherProvider>().loadTeachers()));
    }
    if (Get.isRegistered<ResultProvider>()) {
      tasks.add(safe(Get.find<ResultProvider>().loadAll()));
    }

    if (tasks.isEmpty) return;
    await Future.wait(tasks);
  }

  @override
  State<AppRefreshScope> createState() => _AppRefreshScopeState();
}

class _AppRefreshScopeState extends State<AppRefreshScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    ).drive(Tween(begin: const Offset(0, 0.05), end: Offset.zero));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: RefreshIndicator(
          onRefresh: widget.onRefresh ?? AppRefreshScope.refreshAppData,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.vertical,
          child: widget.child,
        ),
      ),
    );
  }
}

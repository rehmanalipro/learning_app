import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/class_binding_service.dart';
import '../../core/services/class_roster_service.dart';
import '../../core/theme/app_theme_helper.dart';
import '../../features/attendance/services/attendance_service.dart';
import '../../features/auth/providers/firebase_auth_provider.dart';
import '../../features/school/providers/school_data_provider.dart';
import '../../features/school/views/school_info_screen.dart';
import '../../features/theme/providers/app_theme_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_refresh_scope.dart';
import '../widgets/responsive_content.dart';
import 'main_drawer.dart';

class RoleHomeScreen extends StatefulWidget {
  final String title;
  final String roleLabel;
  final VoidCallback onAttendanceTap;
  final VoidCallback onExamRoutineTap;
  final VoidCallback onHomeworkTap;
  final VoidCallback onResultTap;
  final VoidCallback onSolutionTap;
  final VoidCallback onQuizTap;

  const RoleHomeScreen({
    super.key,
    required this.title,
    required this.roleLabel,
    required this.onAttendanceTap,
    required this.onExamRoutineTap,
    required this.onHomeworkTap,
    required this.onResultTap,
    required this.onSolutionTap,
    required this.onQuizTap,
  });

  @override
  State<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends State<RoleHomeScreen> {
  final SchoolDataProvider _schoolDataProvider = Get.find<SchoolDataProvider>();
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final AppThemeProvider _appThemeProvider = Get.find<AppThemeProvider>();
  final ClassBindingService _classBindingService =
      Get.find<ClassBindingService>();
  final ClassRosterService _classRosterService = Get.find<ClassRosterService>();
  final AttendanceService _attendanceService = Get.find<AttendanceService>();

  int _lastPopupUnreadCount = -1;

  bool get _isStudent => widget.roleLabel.toLowerCase() == 'student';
  bool get _isTeacher => widget.roleLabel.toLowerCase() == 'teacher';
  bool get _isPrincipal => widget.roleLabel.toLowerCase() == 'principal';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStudentNotificationPopupIfNeeded();
    });
    if (_isTeacher) {
      final cn = _classBindingService.className.value;
      final sec = _classBindingService.section.value;
      if (cn.isNotEmpty && sec.isNotEmpty) {
        _classRosterService.loadRoster(className: cn, section: sec);
      }
      _attendanceService.loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      drawer: MainDrawer(role: widget.roleLabel),
      backgroundColor: palette.scaffold,
      appBar: AppScreenHeader(
        title: widget.title,
        subtitle: widget.roleLabel,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              Get.find<ClassBindingService>().clear();
              await _authProvider.signOut();
              Get.offAllNamed(AppRoutes.choose);
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
        centerTitle: true,
        height: 88,
      ),
      body: Obx(() {
        final _ = _schoolDataProvider.feedRevision;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStudentNotificationPopupIfNeeded();
        });

        final schoolData = _schoolDataProvider.schoolData.value;
        final unreadCount = _appThemeProvider.notificationsEnabled.value
            ? _schoolDataProvider.unreadNoticeCountForRole(widget.roleLabel)
            : 0;
        final latestPosts = _schoolDataProvider.sortedNoticePosts;
        final latestPost = latestPosts.isEmpty ? null : latestPosts.first;

        final items = <_HomeItem>[
          if (_isPrincipal)
            _HomeItem(
              label: 'Admissions',
              icon: Icons.how_to_reg_outlined,
              onTap: () => Get.toNamed(AppRoutes.studentAdmissions),
            ),
          if (_isPrincipal)
            _HomeItem(
              label: 'Teachers',
              icon: Icons.badge_outlined,
              onTap: () => Get.toNamed(AppRoutes.teacherAccounts),
            ),
          _HomeItem(
            label: 'Attendance',
            icon: Icons.fact_check_outlined,
            onTap: widget.onAttendanceTap,
          ),
          _HomeItem(
            label: 'Homework',
            icon: Icons.corporate_fare_outlined,
            onTap: widget.onHomeworkTap,
          ),
          _HomeItem(
            label: 'Result',
            icon: Icons.note_alt_outlined,
            onTap: widget.onResultTap,
          ),
          _HomeItem(
            label: 'Exam Routine',
            icon: Icons.format_list_bulleted,
            onTap: widget.onExamRoutineTap,
          ),
          _HomeItem(
            label: 'Solution',
            icon: Icons.menu_book_outlined,
            onTap: widget.onSolutionTap,
          ),
          _HomeItem(
            label: 'Quiz',
            icon: Icons.quiz_outlined,
            onTap: widget.onQuizTap,
          ),
          _HomeItem(
            label: 'Notice & Events',
            icon: Icons.campaign_outlined,
            badgeCount: _isStudent ? unreadCount : 0,
            onTap: () => Get.toNamed(
              AppRoutes.schoolInfo,
              arguments: {
                'role': widget.roleLabel,
                'type': SchoolInfoType.notice,
              },
            ),
          ),
        ];

        return AppRefreshScope(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: palette.announcementCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Latest Update',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (latestPost != null)
                              _statusPill(
                                text: latestPost.category,
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            const Spacer(),
                            Text(
                              widget.roleLabel,
                              style: TextStyle(
                                color: palette.inverseText.withValues(
                                  alpha: 0.78,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          latestPost?.title ?? schoolData.announcement,
                          style: TextStyle(
                            color: palette.inverseText,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          latestPost?.body ?? schoolData.announcement,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.inverseText.withValues(alpha: 0.86),
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                        if (latestPost != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.account_circle_outlined,
                                size: 15,
                                color: palette.inverseText.withValues(
                                  alpha: 0.86,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${latestPost.authorName} | ${latestPost.authorRole}',
                                  style: TextStyle(
                                    color: palette.inverseText.withValues(
                                      alpha: 0.86,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_isStudent && unreadCount > 0)
                                _statusPill(
                                  text: '$unreadCount new',
                                  color: const Color(0x33FFFFFF),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isPrincipal) _buildPrincipalAdmissionsBanner(palette),
                  if (_isTeacher) _buildTeacherClassBanner(palette),
                  Wrap(
                    spacing: 10,
                    runSpacing: 16,
                    children: items
                        .asMap()
                        .entries
                        .map(
                          (e) => AnimatedListItem(
                            index: e.key,
                            baseDelay: const Duration(milliseconds: 55),
                            child: _HomeTile(item: e.value),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTeacherClassBanner(dynamic palette) {
    return Obx(() {
      final cn = _classBindingService.className.value;
      final sec = _classBindingService.section.value;
      final sub = _classBindingService.subject.value;
      final studentCount = _classRosterService.roster.length;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayEntries = _attendanceService.attendanceEntries.where((e) {
        // match by date field or submittedAt date
        final entryDate = e.submittedAt;
        final entryDateStr =
            '${entryDate.year}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}';
        return entryDateStr == todayStr;
      }).toList();
      final hasAttendanceToday = todayEntries.isNotEmpty;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class ${cn.isNotEmpty ? cn : '—'} | Section ${sec.isNotEmpty ? sec : '—'} | Subject ${sub.isNotEmpty ? sub : '—'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Total Students: $studentCount',
              style: TextStyle(fontSize: 13, color: palette.subtext),
            ),
            const SizedBox(height: 4),
            Text(
              hasAttendanceToday
                  ? 'Attendance marked for today.'
                  : 'Attendance not marked yet for today.',
              style: TextStyle(
                fontSize: 13,
                color: hasAttendanceToday
                    ? const Color(0xFF129C63)
                    : const Color(0xFFD64545),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPrincipalAdmissionsBanner(AppThemePalette palette) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.softCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.how_to_reg_outlined,
                  color: palette.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Admissions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add and manage principal-controlled student identity records before signup and results.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: palette.subtext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.studentAdmissions),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open Admission Form'),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentNotificationPopupIfNeeded() {
    if (!_isStudent || !mounted) return;

    final notificationsEnabled = _appThemeProvider.notificationsEnabled.value;
    final unreadPosts = _schoolDataProvider.unreadPostsForRole(
      widget.roleLabel,
    );
    final unreadCount = notificationsEnabled ? unreadPosts.length : 0;

    if (unreadCount <= 0 || unreadCount == _lastPopupUnreadCount) return;
    _lastPopupUnreadCount = unreadCount;

    final latest = unreadPosts.first;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF1E56CF),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'New Notification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latest.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Posted by ${latest.authorName} (${latest.authorRole})',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              latest.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.45),
            ),
            if (unreadCount > 1) ...[
              const SizedBox(height: 12),
              Text(
                'You also have ${unreadCount - 1} more unread updates.',
                style: const TextStyle(
                  color: Color(0xFF1E56CF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Later')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed(
                AppRoutes.schoolInfo,
                arguments: {
                  'role': widget.roleLabel,
                  'type': SchoolInfoType.notice,
                },
              );
            },
            child: const Text('Open'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _statusPill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final _HomeItem item;

  const _HomeTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width > 1240 ? 1180 : width - 32;
    final columns = contentWidth >= 900
        ? 4
        : contentWidth >= 640
        ? 3
        : 2;
    final tileWidth = (contentWidth - ((columns - 1) * 10)) / columns;

    return SizedBox(
      width: tileWidth.clamp(120.0, 220.0),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: palette.softCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, size: 34, color: palette.primary),
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64545),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(fontSize: 12, color: palette.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeItem {
  final String label;
  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  const _HomeItem({
    required this.label,
    required this.icon,
    this.badgeCount = 0,
    this.onTap,
  });
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme_helper.dart';
import '../../features/auth/providers/firebase_auth_provider.dart';
import '../../features/school/controllers/school_controller.dart';
import '../../features/school/providers/school_data_provider.dart';
import '../../features/school/views/school_info_screen.dart';
import '../../routes/app_routes.dart';
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
  final SchoolController _schoolController = Get.find<SchoolController>();
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();

  int _lastPopupUnreadCount = -1;

  bool get _isStudent => widget.roleLabel.toLowerCase() == 'student';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStudentNotificationPopupIfNeeded();
    });
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
        final _ = _schoolController.feedRevision;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStudentNotificationPopupIfNeeded();
        });

        final schoolData = _schoolDataProvider.schoolData.value;
        final unreadCount =
            _schoolController.unreadNoticeCountForRole(widget.roleLabel);
        final latestPost = _schoolController.noticePosts.isEmpty
            ? null
            : _schoolController.noticePosts.first;

        final items = <_HomeItem>[
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
                  Wrap(
                    spacing: 10,
                    runSpacing: 16,
                    children: items
                        .map((item) => _HomeTile(item: item))
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

  void _showStudentNotificationPopupIfNeeded() {
    if (!_isStudent || !mounted) return;

    final notificationsEnabled =
        _schoolDataProvider.schoolData.value.notificationsEnabled;
    final unreadPosts = _schoolController.unreadPostsForRole(widget.roleLabel);
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
          TextButton(
            onPressed: Get.back,
            child: const Text('Later'),
          ),
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

  Widget _statusPill({
    required String text,
    required Color color,
  }) {
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
    final columns = contentWidth >= 900 ? 4 : contentWidth >= 640 ? 3 : 2;
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/class_binding_service.dart';
import '../../../core/theme/app_theme_helper.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/app_refresh_scope.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../theme/providers/app_theme_provider.dart';
import '../controllers/school_controller.dart';
import '../models/school_data_model.dart';
import '../providers/school_data_provider.dart';

enum SchoolInfoType {
  notice,
  schoolProfile,
  publicationProfile,
  emergencyContacts,
  settings,
}

class SchoolInfoScreen extends StatefulWidget {
  final String role;
  final SchoolInfoType type;

  const SchoolInfoScreen({super.key, required this.role, required this.type});

  @override
  State<SchoolInfoScreen> createState() => _SchoolInfoScreenState();
}

class _SchoolInfoScreenState extends State<SchoolInfoScreen> {
  final SchoolDataProvider _schoolDataProvider = Get.find<SchoolDataProvider>();
  final SchoolController _schoolController = Get.find<SchoolController>();
  final AppThemeProvider _appThemeProvider = Get.find<AppThemeProvider>();
  final FirebaseAuthProvider _authProvider = Get.find<FirebaseAuthProvider>();
  final ProfileProvider _profileProvider = Get.find<ProfileProvider>();
  late final ClassBindingService _classBindingService;

  late final TextEditingController _mainController;
  late final TextEditingController _secondaryController;
  late final TextEditingController _tertiaryController;
  late final TextEditingController _noticeTitleController;
  late final TextEditingController _noticeBodyController;
  late final TextEditingController _noticeAuthorController;
  late bool _notificationsEnabled;
  late bool _darkModeEnabled;
  String _noticeCategory = 'Notice';
  List<_EmergencyContactInput> _emergencyContacts = [];
  bool _isSaving = false;

  bool get _isPrincipal => widget.role.toLowerCase() == 'principal';
  bool get _isTeacher => widget.role.toLowerCase() == 'teacher';
  bool get _isStudent => widget.role.toLowerCase() == 'student';
  bool get _canEdit => _isPrincipal;
  bool get _canEditNotice => _isPrincipal || _isTeacher;

  @override
  void initState() {
    super.initState();
    _classBindingService = Get.find<ClassBindingService>();
    _mainController = TextEditingController();
    _secondaryController = TextEditingController();
    _tertiaryController = TextEditingController();
    _noticeTitleController = TextEditingController();
    _noticeBodyController = TextEditingController();
    _noticeAuthorController = TextEditingController();
    _notificationsEnabled = false;
    _darkModeEnabled = false;
    _loadData();
    _loadNoticeAuthor();
  }

  Future<void> _loadNoticeAuthor() async {
    final userData = await _authProvider.loadCurrentUserData();
    if (!mounted) return;

    final fallbackProfile = _profileProvider.profileFor(widget.role);
    final resolvedName =
        (userData?['name'] as String?)?.trim().isNotEmpty == true
        ? (userData!['name'] as String).trim()
        : fallbackProfile.name.trim().isNotEmpty
        ? fallbackProfile.name.trim()
        : widget.role;

    _noticeAuthorController.text = resolvedName;
    if (mounted) {
      setState(() {});
    }
  }

  void _loadData() {
    final data = _schoolDataProvider.schoolData.value;
    switch (widget.type) {
      case SchoolInfoType.notice:
        _mainController.text = data.announcement;
        break;
      case SchoolInfoType.schoolProfile:
        _mainController.text = data.schoolName;
        _secondaryController.text = data.schoolLocation;
        _tertiaryController.text = data.schoolFounded;
        break;
      case SchoolInfoType.publicationProfile:
        _mainController.text = data.publicationProfile;
        break;
      case SchoolInfoType.emergencyContacts:
        _emergencyContacts = data.emergencyContacts
            .map(
              (c) => _EmergencyContactInput(
                nameController: TextEditingController(text: c.name),
                phoneController: TextEditingController(text: c.phone),
              ),
            )
            .toList(growable: true);
        break;
      case SchoolInfoType.settings:
        _notificationsEnabled = _appThemeProvider.notificationsEnabled.value;
        _darkModeEnabled = _appThemeProvider.isDarkModeForCurrentUser;
        break;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _secondaryController.dispose();
    _tertiaryController.dispose();
    _noticeTitleController.dispose();
    _noticeBodyController.dispose();
    _noticeAuthorController.dispose();
    for (final item in _emergencyContacts) {
      item.dispose();
    }
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case SchoolInfoType.notice:
        return 'Notice & Events';
      case SchoolInfoType.schoolProfile:
        return 'Profile of School';
      case SchoolInfoType.publicationProfile:
        return 'Profile of Publication';
      case SchoolInfoType.emergencyContacts:
        return 'Emergency Contacts';
      case SchoolInfoType.settings:
        return 'Settings';
    }
  }

  Future<void> _saveGeneral() async {
    setState(() => _isSaving = true);
    try {
      switch (widget.type) {
        case SchoolInfoType.schoolProfile:
          await _schoolDataProvider.updateSchoolProfile(
            name: _mainController.text.trim(),
            location: _secondaryController.text.trim(),
            founded: _tertiaryController.text.trim(),
          );
          break;
        case SchoolInfoType.publicationProfile:
          await _schoolDataProvider.updatePublicationProfile(
            _mainController.text.trim(),
          );
          break;
        case SchoolInfoType.emergencyContacts:
          await _schoolDataProvider.updateEmergencyContacts(
            _emergencyContacts
                .map(
                  (item) => EmergencyContactModel(
                    name: item.nameController.text.trim(),
                    phone: item.phoneController.text.trim(),
                  ),
                )
                .where((item) => item.name.isNotEmpty || item.phone.isNotEmpty)
                .toList(growable: false),
          );
          break;
        case SchoolInfoType.settings:
          _appThemeProvider.setNotificationsForCurrentUser(
            _notificationsEnabled,
          );
          _appThemeProvider.setModeForCurrentUser(
            _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
          );
          break;
        case SchoolInfoType.notice:
          return;
      }
      Get.snackbar(
        'Saved',
        'Changes updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save changes. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishNotice() async {
    final title = _noticeTitleController.text.trim();
    final body = _noticeBodyController.text.trim();
    final author = _noticeAuthorController.text.trim();
    if (title.isEmpty || body.isEmpty || author.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Title, details, and author name are required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final String scope;
      final String? noticeClassName;
      final String? noticeSection;
      if (_isTeacher) {
        scope = 'class';
        noticeClassName = _classBindingService.className.value;
        noticeSection = _classBindingService.section.value;
      } else {
        scope = 'school';
        noticeClassName = null;
        noticeSection = null;
      }
      await _schoolController.publishNotice(
        title: title,
        body: body,
        authorName: author,
        authorRole: widget.role,
        category: _noticeCategory,
        scope: scope,
        className: noticeClassName,
        section: noticeSection,
      );
      _noticeTitleController.clear();
      _noticeBodyController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      Get.snackbar(
        'Posted',
        'New $_noticeCategory has been published successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to post notice. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addEmergencyContact() {
    setState(() {
      _emergencyContacts.add(
        _EmergencyContactInput(
          nameController: TextEditingController(),
          phoneController: TextEditingController(),
        ),
      );
    });
  }

  void _removeEmergencyContact(int index) {
    setState(() {
      _emergencyContacts[index].dispose();
      _emergencyContacts.removeAt(index);
    });
  }

  Future<void> _refreshScreen() async {
    await _schoolDataProvider.loadSchoolData();
    if (!mounted) return;
    setState(_loadData);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    Get.snackbar(
      'Call unavailable',
      'Phone app could not be opened.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _launchSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    Get.snackbar(
      'Message unavailable',
      'Messaging app could not be opened.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year} • $hour:$minute $period';
  }

  String _preview(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    return normalized.length <= 90
        ? normalized
        : '${normalized.substring(0, 90)}...';
  }

  void _openNoticeDetail(NoticePostModel post) {
    _schoolController.markNoticeAsRead(role: widget.role, noticeId: post.id);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    icon: Icons.campaign_outlined,
                    label: post.category,
                    color: const Color(0xFFEAF2FF),
                    textColor: const Color(0xFF1E56CF),
                  ),
                  _pill(
                    icon: Icons.person_outline,
                    label: post.authorRole,
                    color: const Color(0xFFEAF7F3),
                    textColor: const Color(0xFF129C63),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Posted by ${post.authorName} • ${_formatTime(post.createdAt)}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    post.body,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      appBar: AppScreenHeader(title: _title, subtitle: widget.role),
      backgroundColor: palette.scaffold,
      body: Obx(() {
        final _ = _schoolController.feedRevision;
        final unreadCount = _appThemeProvider.notificationsEnabled.value
            ? _schoolController.unreadNoticeCountForRole(widget.role)
            : 0;
        return AppRefreshScope(
          onRefresh: _refreshScreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContent(
              maxWidth: 980,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.type == SchoolInfoType.settings
                              ? 'Each role can manage its own app theme here.'
                              : widget.type == SchoolInfoType.notice
                              ? _isStudent
                                    ? 'Stay updated with the latest school announcements. Tap any heading to read the full details.'
                                    : 'Both Principal and Teacher can post notices and events here.'
                              : _canEdit
                              ? 'Principal can edit this section.'
                              : 'View only. Principal can update this section.',
                          style: TextStyle(
                            color: palette.subtext,
                            height: 1.45,
                          ),
                        ),
                        if (widget.type == SchoolInfoType.notice &&
                            _isStudent) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _pill(
                                icon: Icons.notifications_active_outlined,
                                label: unreadCount > 0
                                    ? '$unreadCount unread'
                                    : 'All caught up',
                                color: unreadCount > 0
                                    ? const Color(0xFFEAF2FF)
                                    : const Color(0xFFEAF7F3),
                                textColor: unreadCount > 0
                                    ? const Color(0xFF1E56CF)
                                    : const Color(0xFF129C63),
                              ),
                              const Spacer(),
                              if (unreadCount > 0)
                                TextButton(
                                  onPressed: () => _schoolController
                                      .markAllNoticesAsRead(widget.role),
                                  child: const Text('Mark all read'),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._buildContent(),
                  if (widget.type != SchoolInfoType.notice &&
                      (_canEdit || widget.type == SchoolInfoType.settings)) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveGeneral,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: palette.inverseText,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildContent() {
    switch (widget.type) {
      case SchoolInfoType.notice:
        return _buildNoticeContent();
      case SchoolInfoType.schoolProfile:
        return _buildSchoolProfileContent();
      case SchoolInfoType.publicationProfile:
        return [
          _InfoField(
            controller: _mainController,
            label: 'Publication Profile',
            maxLines: 7,
            enabled: _canEdit,
          ),
        ];
      case SchoolInfoType.emergencyContacts:
        return _buildEmergencyContent();
      case SchoolInfoType.settings:
        return _buildSettingsContent();
    }
  }

  List<Widget> _buildNoticeContent() {
    final palette = context.appPalette;
    final posts = _schoolController.noticePosts;
    return [
      if (_canEditNotice) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Post new update',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Students ko heading, author, aur full detail ke sath notification style update milega.',
                style: TextStyle(color: palette.subtext),
              ),
              const SizedBox(height: 14),
              _InfoField(
                controller: _noticeTitleController,
                label: 'Heading / Title',
              ),
              const SizedBox(height: 12),
              _InfoField(
                controller: _noticeAuthorController,
                label: 'Posted By',
                enabled: false,
              ),
              const SizedBox(height: 12),
              if (_isTeacher) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.softCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    'Class ${_classBindingService.className.value} | Section ${_classBindingService.section.value}',
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.subtext,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: _noticeCategory,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Notice', child: Text('Notice')),
                  DropdownMenuItem(value: 'Event', child: Text('Event')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _noticeCategory = value);
                },
              ),
              const SizedBox(height: 12),
              _InfoField(
                controller: _noticeBodyController,
                label: 'Full Detail',
                maxLines: 6,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _publishNotice,
                  icon: const Icon(Icons.send_outlined),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.inverseText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  label: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post Update'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
      Text(
        _isStudent ? 'Latest Updates' : 'Posted Updates',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: palette.text,
        ),
      ),
      const SizedBox(height: 12),
      if (posts.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            'No notices or events have been posted yet.',
            style: TextStyle(color: palette.subtext),
          ),
        )
      else
        ...posts.map((post) {
          final isRead = _schoolController.isNoticeRead(widget.role, post.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _openNoticeDetail(post),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isRead
                        ? palette.border
                        : palette.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: post.category == 'Event'
                            ? const Color(0xFFEAF7F3)
                            : const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        post.category == 'Event'
                            ? Icons.event_available_outlined
                            : Icons.notifications_none_outlined,
                        color: post.category == 'Event'
                            ? const Color(0xFF129C63)
                            : const Color(0xFF1E56CF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: palette.text,
                                  ),
                                ),
                              ),
                              if (!isRead && _isStudent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E56CF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'New',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _preview(post.body),
                            style: TextStyle(
                              color: palette.subtext,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _pill(
                                icon: Icons.campaign_outlined,
                                label: post.category,
                                color: palette.softCard,
                                textColor: palette.primary,
                              ),
                              _pill(
                                icon: Icons.person_outline,
                                label:
                                    '${post.authorName} (${post.authorRole})',
                                color: palette.surfaceAlt,
                                textColor: palette.text,
                              ),
                              _pill(
                                icon: Icons.schedule_outlined,
                                label: _formatTime(post.createdAt),
                                color: palette.surfaceAlt,
                                textColor: palette.subtext,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
    ];
  }

  List<Widget> _buildSchoolProfileContent() {
    return [
      _InfoField(
        controller: _mainController,
        label: 'School Name',
        enabled: _canEdit,
      ),
      const SizedBox(height: 14),
      _InfoField(
        controller: _secondaryController,
        label: 'Location',
        enabled: _canEdit,
      ),
      const SizedBox(height: 14),
      _InfoField(
        controller: _tertiaryController,
        label: 'Founded',
        enabled: _canEdit,
      ),
    ];
  }

  List<Widget> _buildEmergencyContent() {
    final palette = context.appPalette;
    return [
      ..._emergencyContacts.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: palette.softCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.call_outlined, color: palette.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.nameController.text.trim().isEmpty
                            ? 'Contact ${index + 1}'
                            : item.nameController.text.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: palette.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: item.phoneController.text.trim().isEmpty
                          ? null
                          : () =>
                                _launchPhone(item.phoneController.text.trim()),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF7F3),
                      ),
                      icon: const Icon(
                        Icons.call,
                        color: Color(0xFF129C63),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: item.phoneController.text.trim().isEmpty
                          ? null
                          : () => _launchSms(item.phoneController.text.trim()),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF2FF),
                      ),
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Color(0xFF1E56CF),
                        size: 20,
                      ),
                    ),
                    if (_canEdit) const SizedBox(width: 6),
                    if (_canEdit)
                      IconButton(
                        onPressed: () => _removeEmergencyContact(index),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF1F1),
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFD64545),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoField(
                  controller: item.nameController,
                  label: 'Name',
                  enabled: _canEdit,
                ),
                const SizedBox(height: 12),
                _InfoField(
                  controller: item.phoneController,
                  label: 'Phone Number',
                  enabled: _canEdit,
                ),
              ],
            ),
          ),
        );
      }),
      if (_canEdit)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addEmergencyContact,
            icon: const Icon(Icons.add),
            label: const Text('Add Contact'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: palette.primary,
              side: BorderSide(color: palette.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildSettingsContent() {
    final palette = context.appPalette;
    final profile = _profileProvider.profileFor(widget.role);
    final displayName = profile.name.trim().isEmpty
        ? widget.role
        : profile.name.trim();
    final displayEmail = profile.email.trim().isEmpty
        ? (_authProvider.currentUser.value?.email ?? 'Email not available')
        : profile.email.trim();
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.softCard,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.person_outline, color: palette.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: TextStyle(color: palette.subtext, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signed in as ${widget.role}',
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.softCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.role} ke liye app notifications on ya off karein.',
                        style: TextStyle(color: palette.subtext, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                  activeThumbColor: palette.primary,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.softCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.palette_outlined, color: palette.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Theme',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apni pasand ka light ya dark mode select karein.',
                        style: TextStyle(color: palette.subtext, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ThemeChoiceTile(
              title: 'Light Mode',
              subtitle: '${widget.role} app theme setting',
              icon: Icons.light_mode_outlined,
              selected: !_darkModeEnabled,
              onTap: () => setState(() => _darkModeEnabled = false),
            ),
            const SizedBox(height: 10),
            _ThemeChoiceTile(
              title: 'Dark Mode',
              subtitle: '${widget.role} app theme setting',
              icon: Icons.dark_mode_outlined,
              selected: _darkModeEnabled,
              onTap: () => setState(() => _darkModeEnabled = true),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.softCard,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.security_outlined, color: palette.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Privacy controls are enabled',
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.softCard,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.sync_outlined, color: palette.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Auto sync is active',
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? palette.softCard : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.primary : palette.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? palette.primary.withValues(alpha: 0.12)
                    : palette.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: selected ? palette.primary : palette.subtext,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: palette.subtext, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off_outlined,
              color: selected ? palette.primary : palette.subtext,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool enabled;

  const _InfoField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(color: enabled ? palette.text : palette.subtext),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        filled: !enabled,
        fillColor: !enabled ? palette.surfaceAlt : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _EmergencyContactInput {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  _EmergencyContactInput({
    required this.nameController,
    required this.phoneController,
  });

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}

Widget _pill({
  required IconData icon,
  required String label,
  required Color color,
  required Color textColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

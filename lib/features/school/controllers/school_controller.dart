import 'package:get/get.dart';

import '../models/school_data_model.dart';
import '../services/school_data_service.dart';

class SchoolController extends GetxController {
  final SchoolDataService _service = Get.find<SchoolDataService>();

  SchoolDataModel get schoolData => _service.schoolData.value;
  Rx<SchoolDataModel> get data => _service.schoolData;
  List<NoticePostModel> get noticePosts => _service.sortedNoticePosts;

  @override
  void onInit() {
    super.onInit();
    loadSchoolData();
  }

  Future<void> updateAnnouncement(String value) =>
      _service.updateAnnouncement(value);

  Future<void> publishNotice({
    required String title,
    required String body,
    required String authorName,
    required String authorRole,
    required String category,
    String scope = 'school',
    String? className,
    String? section,
  }) => _service.publishNotice(
    title: title,
    body: body,
    authorName: authorName,
    authorRole: authorRole,
    category: category,
    scope: scope,
    className: className,
    section: section,
  );

  List<NoticePostModel> noticesForRole({
    required String role,
    String? className,
    String? section,
  }) => _service.noticesForRole(role: role, className: className, section: section);

  int unreadNoticeCountForRole(
    String role, {
    String? className,
    String? section,
  }) => _service.unreadNoticeCountForRole(role, className: className, section: section);

  List<NoticePostModel> unreadPostsForRole(
    String role, {
    String? className,
    String? section,
  }) => _service.unreadPostsForRole(role, className: className, section: section);

  bool isNoticeRead(String role, String noticeId) =>
      _service.isNoticeRead(role, noticeId);

  Future<void> markNoticeAsRead({
    required String role,
    required String noticeId,
  }) => _service.markNoticeAsRead(role: role, noticeId: noticeId);

  Future<void> markAllNoticesAsRead(String role) =>
      _service.markAllNoticesAsRead(role);

  int get feedRevision => _service.feedRevision.value;

  Future<void> updateSchoolProfile({
    required String name,
    required String location,
    required String founded,
  }) => _service.updateSchoolProfile(
    name: name,
    location: location,
    founded: founded,
  );

  Future<void> updatePublicationProfile(String value) =>
      _service.updatePublicationProfile(value);

  Future<void> updateEmergencyContacts(List<EmergencyContactModel> contacts) =>
      _service.updateEmergencyContacts(contacts);

  Future<void> updateSettings({
    required bool notificationsEnabled,
    required bool darkModeEnabled,
  }) => _service.updateSettings(
    notificationsEnabled: notificationsEnabled,
    darkModeEnabled: darkModeEnabled,
  );

  Future<void> updateSchoolImage(String? path) => _service.updateSchoolImage(path);

  Future<void> loadSchoolData() => _service.loadSchoolData();
}
